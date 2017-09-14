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
//  XQDefaultsStoreBase.h
//  xunquan
//
//  Created by quanxiong on 16/6/12.
//  Copyright © 2016年 xunquan inc.. All rights reserved.
//

#import <Foundation/Foundation.h>


#define UD_PROP_TO_STRING(PROP_NAME) [NSString stringWithFormat:@"FPUserDefault_%@", PROP_TO_STRING(PROP_NAME)]

#define IMP_GETTER_SETTER(GETTER, SETTER) IMP_GETTER_SETTER_SETTER_EXTENSION(GETTER, SETTER, ;)

#define IMP_GETTER_SETTER_SETTER_EXTENSION(GETTER, SETTER, SETTER_EXTENSION) \
@synthesize GETTER = _##GETTER; \
- (void)SETTER:(id)GETTER { \
    @synchronized (self) { \
        _##GETTER = GETTER; \
        [self.userDefaults setObject:_##GETTER forKey:UD_PROP_TO_STRING(GETTER)]; \
        SETTER_EXTENSION \
        [self synchronize]; \
    }; \
} \
\
- (id)GETTER { \
    @synchronized (self) { \
        if (!_##GETTER) { \
            _##GETTER = [self.userDefaults objectForKey:UD_PROP_TO_STRING(GETTER)]; \
        } \
    }; \
    return _##GETTER; \
}

@interface XQDefaultsStoreBase : NSObject

- (NSUserDefaults *)userDefaults;
- (BOOL)synchronize;
/**
 *  archive
 */
+ (BOOL)archiveObject:(id)object withKey:(NSString *)key;
+ (id)unarchiveObjectWithKey:(NSString *)key;
@end
