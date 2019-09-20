//
//  JSApiManager.h
//  ExampleApp-iOS
//
//  Created by apple on 2019/9/19.
//  Copyright © 2019 Marcus Westin. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface JSApiManager : NSObject

- (BOOL)isApiNameValid:(NSString *)name;
- (nullable NSString *)handlerNameForApiName:(NSString *)name;

+ (instancetype)sharedInstance;


@end

NS_ASSUME_NONNULL_END
