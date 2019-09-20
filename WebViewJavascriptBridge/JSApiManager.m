//
//  JSApiManager.m
//  ExampleApp-iOS
//
//  Created by apple on 2019/9/19.
//  Copyright © 2019 Marcus Westin. All rights reserved.
//

#import "JSApiManager.h"

@interface JSApiManager()

@property(nonatomic, strong) NSMutableDictionary *jsApiDic;// List<apiName:handlerName>

@end

@implementation JSApiManager

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static JSApiManager *instance = nil;
    dispatch_once(&onceToken,^{
        instance = [[super allocWithZone:NULL] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self loadJsApiList];
    }
    return self;
}

- (BOOL)isApiNameValid:(NSString *)name{
    if (!name|| [name isEqualToString:@""]) {
        return NO;
    }
    return [[self.jsApiDic allKeys] containsObject:name];
}

- (nullable NSString *)handlerNameForApiName:(NSString *)name{
    if (![self isApiNameValid:name]) {
        return NULL;
    }
    return [self.jsApiDic objectForKey:name];
}

#pragma mark - private

- (void)loadJsApiList {
    //TODO:待优化，从plist里边读取
    [self.jsApiDic setObject:@"JSApiSetTitleHandler" forKey:@"setTitle"];
    [self.jsApiDic setObject:@"JSApiSetTitleHandler" forKey:@"setTitle2"];
    [self.jsApiDic setObject:@"JSApiHandler" forKey:@"jtSetTitle"];
}

#pragma mark - lazy load

- (NSMutableDictionary *)jsApiDic{
    if (!_jsApiDic) {
        _jsApiDic = [[NSMutableDictionary alloc]init];
    }
    return _jsApiDic;
}

@end
