//
//  WebViewJavascriptBridgeBase.m
//
//  Created by @LokiMeyburg on 10/15/14.
//  Copyright (c) 2014 @LokiMeyburg. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WebViewJavascriptBridgeBase.h"
#import "WebViewJavascriptBridge_JS2.h"
#import "JSApiSetTitleHandler.h"
#import "JSApiManager.h"

@implementation WebViewJavascriptBridgeBase {
    __weak id _webViewDelegate;
    long _uniqueId;
}

#pragma mark - init release

static bool logging = false;
static int logMaxLength = 500;

+ (void)enableLogging { logging = true; }
+ (void)setLogMaxLength:(int)length { logMaxLength = length;}

- (id)init {
    if (self = [super init]) {
        self.messageHandlers = [NSMutableDictionary dictionary];
        self.startupMessageQueue = [NSMutableArray array];
        self.responseCallbacks = [NSMutableDictionary dictionary];
        _uniqueId = 0;
    }
    return self;
}

- (void)dealloc {
    self.startupMessageQueue = nil;
    self.responseCallbacks = nil;
    self.messageHandlers = nil;
}

#pragma mark -

- (void)reset {
    self.startupMessageQueue = [NSMutableArray array];
    self.responseCallbacks = [NSMutableDictionary dictionary];
    _uniqueId = 0;
}
#pragma mark - 调用js
- (void)sendData:(id)data responseCallback:(WVJBResponseCallback)responseCallback handlerName:(NSString*)handlerName {
    NSMutableDictionary* message = [NSMutableDictionary dictionary];
    
    if (data) {
        message[@"data"] = data;
    }
    
    if (responseCallback) {
        NSString* callbackId = [NSString stringWithFormat:@"objc_cb_%ld", ++_uniqueId];
        self.responseCallbacks[callbackId] = [responseCallback copy];
        message[@"callbackId"] = callbackId;
    }
    
    if (handlerName) {
        message[@"handlerName"] = handlerName;
    }
    [self _queueMessage:message];
}


- (void)_queueMessage:(WVJBMessage*)message {
    if (self.startupMessageQueue) {
        [self.startupMessageQueue addObject:message];
    } else {
        [self _dispatchMessage:message];
    }
}

- (void)_dispatchMessage:(WVJBMessage*)message {
    NSString *messageJSON = [self _serializeMessage:message pretty:NO];
    [self _log:@"SEND" json:messageJSON];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\'" withString:@"\\\'"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\r" withString:@"\\r"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\f" withString:@"\\f"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\u2028" withString:@"\\u2028"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\u2029" withString:@"\\u2029"];
    
    NSString* javascriptCommand = [NSString stringWithFormat:@"WebViewJavascriptBridge._handleMessageFromObjC('%@');", messageJSON];
    if ([[NSThread currentThread] isMainThread]) {
        [self _evaluateJavascript:javascriptCommand];
        
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self _evaluateJavascript:javascriptCommand];
        });
    }
}

- (void) _evaluateJavascript:(NSString *)javascriptCommand {
    [self.delegate _evaluateJavascript:javascriptCommand];
}

#pragma mark - 处理从js传递过来的事件(jsCall/ocCallback)
- (void)flushMessageQueue:(NSString *)messageQueueString{
    if (messageQueueString == nil || messageQueueString.length == 0) {
        NSLog(@"WebViewJavascriptBridge: WARNING: ObjC got nil while fetching the message queue JSON from webview. This can happen if the WebViewJavascriptBridge JS is not currently present in the webview, e.g if the webview just loaded a new page.");
        return;
    }

    id messages = [self _deserializeMessageJSON:messageQueueString];
    for (WVJBMessage* message in messages) {
        if (![message isKindOfClass:[WVJBMessage class]]) {
            NSLog(@"WebViewJavascriptBridge: WARNING: Invalid %@ received: %@", [message class], message);
            continue;
        }
        [self _log:@"RCVD" json:message];
        NSString* responseId = message[@"responseId"];
        if (responseId) {// ocCallback
            WVJBResponseCallback responseCallback = _responseCallbacks[responseId];
            responseCallback(message[@"responseData"]);
            [self.responseCallbacks removeObjectForKey:responseId];
        } else {// jsCall
            ////zcr
            JSApiCallbackBlock callback = nil;
            NSString * callbackId = message[@"callbackId"];
            if (callbackId) {
                callback = ^(id responseData){
                    if (responseData == nil) {
                        responseData = [NSNull null];
                    }
                    
                    WVJBMessage* msg = @{ @"responseId":callbackId, @"responseData":responseData };
                    [self _queueMessage:msg];
                };
            } else {
                callback = ^(id ignoredResponseData){
                    //do nothing
                };
            }
            JSApiManager *manager = [JSApiManager sharedInstance];
            if (!message[@"handlerName"]) {
                continue;
            }
            //TODO:待优化，生成的对象太多了
            NSString *clsname = [manager handlerNameForApiName:message[@"handlerName"]];
            Class handlerCls = NSClassFromString(clsname);
            id<JSApiHandlerProtocol> handler = [[handlerCls alloc]init];
            [handler handler:message[@"handlerName"] data:message[@"data"] callback:callback];
        }
    }
}

//注入bridge
- (void)injectJavascriptFile {
    NSString *js = WebViewJavascriptBridge_js2();
    [self _evaluateJavascript:js];
    if (self.startupMessageQueue) {
        NSArray* queue = self.startupMessageQueue;
        self.startupMessageQueue = nil;
        for (id queuedMessage in queue) {
            [self _dispatchMessage:queuedMessage];
        }
    }
}

#pragma mark - private
- (BOOL)isWebViewJavascriptBridgeURL:(NSURL*)url {
    if (![self isSchemeMatch:url]) {
        return NO;
    }
    return [self isBridgeLoadedURL:url] || [self isQueueMessageURL:url];
}

- (BOOL)isSchemeMatch:(NSURL*)url {
    NSString* scheme = url.scheme.lowercaseString;
    return [scheme isEqualToString:kNewProtocolScheme] || [scheme isEqualToString:kOldProtocolScheme];
}

- (BOOL)isQueueMessageURL:(NSURL*)url {
    NSString* host = url.host.lowercaseString;
    return [self isSchemeMatch:url] && [host isEqualToString:kQueueHasMessage];
}

- (BOOL)isBridgeLoadedURL:(NSURL*)url {
    NSString* host = url.host.lowercaseString;
    return [self isSchemeMatch:url] && [host isEqualToString:kBridgeLoaded];
}

- (void)logUnkownMessage:(NSURL*)url {
    NSLog(@"WebViewJavascriptBridge: WARNING: Received unknown WebViewJavascriptBridge command %@", [url absoluteString]);
}

- (NSString *)webViewJavascriptCheckCommand {
    return @"typeof WebViewJavascriptBridge == \'object\';";
}

- (NSString *)webViewJavascriptFetchQueyCommand {
    return @"WebViewJavascriptBridge._fetchQueue();";
}

- (void)disableJavscriptAlertBoxSafetyTimeout {
    [self sendData:nil responseCallback:nil handlerName:@"_disableJavascriptAlertBoxSafetyTimeout"];
}


- (NSString *)_serializeMessage:(id)message pretty:(BOOL)pretty{
    return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:message options:(NSJSONWritingOptions)(pretty ? NSJSONWritingPrettyPrinted : 0) error:nil] encoding:NSUTF8StringEncoding];
}

- (NSArray*)_deserializeMessageJSON:(NSString *)messageJSON {
    return [NSJSONSerialization JSONObjectWithData:[messageJSON dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:nil];
}

- (void)_log:(NSString *)action json:(id)json {
    if (!logging) { return; }
    if (![json isKindOfClass:[NSString class]]) {
        json = [self _serializeMessage:json pretty:YES];
    }
    if ([json length] > logMaxLength) {
        NSLog(@"WVJB %@: %@ [...]", action, [json substringToIndex:logMaxLength]);
    } else {
        NSLog(@"WVJB %@: %@", action, json);
    }
}

@end
