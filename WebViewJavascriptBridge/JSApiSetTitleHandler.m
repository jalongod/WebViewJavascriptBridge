//
//  JSApiHandler.m
//  ExampleApp-iOS
//
//  Created by apple on 2019/9/19.
//  Copyright © 2019 Marcus Westin. All rights reserved.
//

#import "JSApiSetTitleHandler.h"

@implementation JSApiSetTitleHandler

- (void)handler:(NSDictionary *)data callback:(JSApiCallbackBlock)callback{
    NSLog(@"JSApiSetTitleHandler receive data:%@",data);
    callback(@"哈哈");
}

@end
