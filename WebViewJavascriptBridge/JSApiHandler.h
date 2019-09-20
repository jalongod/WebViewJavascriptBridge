//
//  JSApiHandler.h
//  ExampleApp-iOS
//
//  Created by apple on 2019/9/20.
//  Copyright © 2019 Marcus Westin. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^JSApiCallbackBlock)(id);

//处理单个jsapi
@protocol JSApiHandlerProtocol <NSObject>
- (void)handler:(NSString *)name data:(NSDictionary *)data callback:(JSApiCallbackBlock)callback;
@end

//webview自带的jsapi
@interface JSApiHandler : NSObject<JSApiHandlerProtocol>

@end

NS_ASSUME_NONNULL_END
