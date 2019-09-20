//
//  JSApiHandler.m
//  ExampleApp-iOS
//
//  Created by apple on 2019/9/19.
//  Copyright © 2019 Marcus Westin. All rights reserved.
//

#import "JSApiSetTitleHandler.h"

@implementation JSApiSetTitleHandler

- (void)handler:(NSString *)name data:(NSDictionary *)data callback:(JSApiCallbackBlock)callback{
    if (!name||[name isEqualToString:@""]) {
        return;
    }
    if ([name isEqualToString: @"setTitle"]) {
        [self handleSetTitle:data callback:callback];
    }else if ([name isEqualToString: @"setTitle2"]){
        [self handleSetTitle2:data callback:callback];
    }
}

- (void)handleSetTitle:(NSDictionary *)data callback:(JSApiCallbackBlock)callback{
    NSLog(@"JSApiSetTitleHandler receive data:%@",data);
    callback(@"哈哈");
}

- (void)handleSetTitle2:(NSDictionary *)data callback:(JSApiCallbackBlock)callback{
    NSLog(@"JSApiSetTitleHandler2 receive data:%@",data);
    callback(@"哈哈2");
}

@end
