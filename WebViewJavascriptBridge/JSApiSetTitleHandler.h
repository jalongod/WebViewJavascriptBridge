//
//  JSApiHandler.h
//  ExampleApp-iOS
//
//  Created by apple on 2019/9/19.
//  Copyright © 2019 Marcus Westin. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^JSApiCallbackBlock)(id);

@protocol JSApiHandler <NSObject>

- (void)handler:(NSDictionary *)data callback:(JSApiCallbackBlock)callback;

@end

@interface JSApiSetTitleHandler : NSObject

@end

NS_ASSUME_NONNULL_END
