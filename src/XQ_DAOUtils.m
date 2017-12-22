/* 
MIT License

Copyright (c) 2017 Xiong

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */
//
//  XQ_DAOUtils.m
//  XQ_DAO
//
//  Created by quanxiong on 2017/12/22.
//  Copyright © 2017年 com.hssdx. All rights reserved.
//

#import "XQ_DAOUtils.h"

#import <objc/runtime.h>

extern xq_dao_force_inline id xq_dao_obj_for_class(id _id, Class cls) {
    if (nil == _id) {
        return nil;
    }
    XQDAOAssert([_id isKindOfClass:cls]);
    if ([_id isKindOfClass:cls]) {
        return _id;
    }
    return nil;
}

extern xq_dao_force_inline NSArray *xq_dao_compact(NSArray *array, id (^block)(id obj)) {
    XQDAOAssert(block != nil);
    
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:array.count];
    [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        id value = block(obj);
        if (value) {
            [result addObject:value];
        }
    }];
    return result;
}

extern xq_dao_force_inline void xq_dao_log(NSString *fmt, ...) {
    va_list args;
    va_start (args, fmt);
    NSString *content = [[NSString alloc] initWithFormat:fmt arguments:args];
    va_end (args);
    NSLog(@"[XQ_DAO_LOG]%@", content);
}


@implementation NSObject (XQ_DAO_HELPER)
+ (BOOL)xq_dao_swizzleInstanceMethod:(SEL)originalSel with:(SEL)newSel {
    Method originalMethod = class_getInstanceMethod(self, originalSel);
    Method newMethod = class_getInstanceMethod(self, newSel);
    if (!originalMethod || !newMethod) return NO;
    
    class_addMethod(self,
                    originalSel,
                    class_getMethodImplementation(self, originalSel),
                    method_getTypeEncoding(originalMethod));
    class_addMethod(self,
                    newSel,
                    class_getMethodImplementation(self, newSel),
                    method_getTypeEncoding(newMethod));
    
    method_exchangeImplementations(class_getInstanceMethod(self, originalSel),
                                   class_getInstanceMethod(self, newSel));
    return YES;
}

+ (BOOL)xq_dao_swizzleClassMethod:(SEL)originalSel with:(SEL)newSel {
    Class class = object_getClass(self);
    Method originalMethod = class_getInstanceMethod(class, originalSel);
    Method newMethod = class_getInstanceMethod(class, newSel);
    if (!originalMethod || !newMethod) return NO;
    method_exchangeImplementations(originalMethod, newMethod);
    return YES;
}
@end
