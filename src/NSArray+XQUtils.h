//
//  NSArray+XQUtils.h
//  xunquan
//
//  Created by xiongxunquan on 2016/12/5.
//  Copyright © 2016年 xunquan inc.. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (XQUtils)

- (NSDictionary *)xq_dictionaryForKeypath:(NSString *)keypath;
- (NSMutableDictionary *)xq_mutableDictionaryForKeypath:(NSString *)keypath;
- (NSArray *)xq_compact:(id (^)(id obj))block;

@end
