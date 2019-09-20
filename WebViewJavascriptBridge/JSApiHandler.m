//
//  JSApiHandler.m
//  ExampleApp-iOS
//
//  Created by apple on 2019/9/20.
//  Copyright © 2019 Marcus Westin. All rights reserved.
//

#import "JSApiHandler.h"

@implementation JSApiHandler


- (void)handler:(nonnull NSString *)name data:(nonnull NSDictionary *)data callback:(nonnull JSApiCallbackBlock)callback {
    if (!name||[name isEqualToString:@""]) {
        return;
    }
    if ([name isEqualToString: @"jtSetTitle"]) {
        [self handlerJTSetTitle:data callback:callback];
    }
}

- (void)handlerJTSetTitle:(NSDictionary *)data callback:(JSApiCallbackBlock)callback{
    //do nothing
    NSLog(@"handlerJTSetTitle receive data:%@",data);
    callback(@"哈哈，jt处理的");
}
@end
