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
//  XQDefaultsStoreBase.m
//  xunquan
//
//  Created by quanxiong on 16/6/12.
//  Copyright © 2016年 xunquan inc.. All rights reserved.
//

#import "XQDefaultsStoreBase.h"

@implementation XQDefaultsStoreBase

+ (instancetype)sharedStore {
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (NSUserDefaults *)userDefaults {
    return [NSUserDefaults standardUserDefaults];
}

- (BOOL)synchronize {
    return [[self userDefaults] synchronize];
}
#pragma mark - archive
+ (BOOL)archiveObject:(id)object withKey:(NSString *)key {
    NSString *documentPath = [self documentPathWithKey:key];
    return [NSKeyedArchiver archiveRootObject:object toFile:documentPath];
}

+ (id)unarchiveObjectWithKey:(NSString *)key {
    NSString *documentPath = [self documentPathWithKey:key];
    id obj = [NSKeyedUnarchiver unarchiveObjectWithFile:documentPath];
    return obj;
}

/* 获取Documents文件夹路径 */
+ (NSString *)documentPathWithKey:(NSString *)key {
    NSArray *documents = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath = documents[0];
    NSString *filePath = [documentPath stringByAppendingPathComponent:key];
    return filePath;
}

@end
