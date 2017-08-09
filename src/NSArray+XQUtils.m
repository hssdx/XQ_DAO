//
//  NSArray+XQUtils.m
//  xunquan
//
//  Created by xiongxunquan on 2016/12/5.
//  Copyright © 2016年 xunquan inc.. All rights reserved.
//

#import "NSArray+XQUtils.h"

@implementation NSArray (XQUtils)

- (NSDictionary *)xq_dictionaryForKeypath:(NSString *)keypath {
    return [self xq_mutableDictionaryForKeypath:keypath];
}

- (NSMutableDictionary *)xq_mutableDictionaryForKeypath:(NSString *)keypath {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    for (id item in self) {
        id keyValue = [item valueForKey:keypath];
        if (keyValue) {
            dictionary[keyValue] = item;
        }
    }
    return dictionary;
}

- (NSArray *)xq_compact:(id (^)(id obj))block {
    NSParameterAssert(block != nil);
    
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:self.count];
    
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        id value = block(obj);
        if (value) {
            [result addObject:value];
        }
    }];
    
    return result;
}

@end
