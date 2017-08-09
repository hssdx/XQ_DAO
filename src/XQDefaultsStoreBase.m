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
