//
//  XQFMDBManager.h
//  XQ_DAO
//
//  Created by quanxiong on 2017/8/8.
//  Copyright © 2017年 com.hssdx. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FMDatabase;

typedef BOOL (^XQDBBlock)(FMDatabase *db);

@interface XQFMDBManager : NSObject

@property (assign, nonatomic, readonly) int32_t version;

+ (instancetype)managerWithKey:(NSString *)key useGroup:(BOOL)useGroup;

+ (instancetype)defaultManager;

- (BOOL)isDBFileExist;
- (BOOL)removeDatabase;

- (void)executeBlock:(XQDBBlock)block;

- (void)executeBlocksInTransaction:(NSArray<XQDBBlock> *)blocks;

- (void)setupDatabaseWithClasses:(NSArray<NSString *> *)classes version:(uint32_t)version;

@end
