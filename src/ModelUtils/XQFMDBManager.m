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
//  XQFMDBManager.m
//  XQ_DAO
//
//  Created by quanxiong on 2017/8/8.
//  Copyright © 2017年 com.hssdx. All rights reserved.
//

#import "XQFMDBManager.h"
#import "XQDatabaseQueue.h"
#import "XQMigrationService.h"
#import "XQMigrationItemBase.h"
#import "NSObject+XQ_DAO.h"
#import "XQ_DAOUtils.h"

#import <UIKit/UIKit.h>
#import <FMDB/FMDB.h>
#import <objc/runtime.h>
#import <objc/message.h>

@interface XQFMDBManager ()

@property (strong, nonatomic) XQDatabaseQueue *dbQueue;
@property (strong, nonatomic) FMDatabase *db;
@property (copy, nonatomic) NSString *path;
@property (assign, nonatomic, readwrite) int32_t version;

@end

@implementation XQFMDBManager

+ (NSString *)appGroupID {
    NSString *appGroupID = [NSString stringWithFormat:@"group.%@",
                            [NSBundle mainBundle].bundleIdentifier];
    return appGroupID;
}

+ (NSString *)pathForKey:(NSString *)key useGroup:(BOOL)useGroup {
    NSURL *groupURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:[self appGroupID]];
    NSString *path;
    if (useGroup && groupURL) {
        path = [[groupURL URLByAppendingPathComponent:key] path];
    } else {
        NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        path = [docPath stringByAppendingPathComponent:key];
    }
    return path;
}

+ (NSMutableDictionary *)managersDict {
    static NSMutableDictionary *s_managersDict;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_managersDict = [NSMutableDictionary dictionary];
    });
    return s_managersDict;
}

+ (instancetype)_managerWithPath:(NSString *)path {
    XQFMDBManager *manager = [self.managersDict objectForKey:path];
    if (manager) {
        return manager;
    }
    manager = [[XQFMDBManager alloc] initWithPath:path];
    return manager;
}

+ (instancetype)managerWithKey:(NSString *)key useGroup:(BOOL)useGroup {
    NSString *path = [self pathForKey:key useGroup:useGroup];
    XQFMDBManager *manager = [self _managerWithPath:path];
    return manager;
}

+ (instancetype)defaultManager {
    return [self managerWithKey:@"default_xq_db" useGroup:NO];
}

- (instancetype)initWithPath:(NSString *)path {
    if (self = [super init]) {
        [self setupWithPath:path];
    }
    return self;
}

- (void)setupWithPath:(NSString *)path {
    _path = path;
    _dbQueue = [XQDatabaseQueue databaseQueueWithPath:path];
    [_dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
        self.db = db;
        self.version = db.userVersion;
    }];
    [_dbQueue close];
}

- (BOOL)isDBFileExist {
    return [[NSFileManager defaultManager] fileExistsAtPath:self.path];
}

- (BOOL)removeDatabase {
    if ([self isDBFileExist]) {
        NSError *fileErr;
        [[NSFileManager defaultManager] removeItemAtPath:self.path error:&fileErr];
        //setup
        assert(![self isDBFileExist]);
        [self setupWithPath:self.path];
    }
    return [self isDBFileExist];
}

- (void)executeBlock:(XQDBBlock)block {
    if (!block) {
        return;
    }
    if ([self.dbQueue isNestedQueue]){
        if ([self.db open])
            block(self.db);
        else
            XQDAOLog(@"[xq_dao]can't open");
    }
    else{
        [self.dbQueue inDatabase:^(FMDatabase *db){
            block(db);
        }];
        [self.dbQueue close];
    }
}

- (void)executeBlocksInTransaction:(NSArray<XQDBBlock> *)blocks {
    if (blocks.count == 0) {
        return;
    }
    if ([self.dbQueue isNestedQueue]) {
        XQDAOLog(@"[xq_dao]在一个自身的 db queue 里未退出，无法启动事务操作模式");
        if ([self.db open]) {
            [blocks enumerateObjectsUsingBlock:^(XQDBBlock  _Nonnull block, NSUInteger idx, BOOL * _Nonnull stop) {
                block(self.db);
            }];
        }
        else {
            XQDAOLog(@"[xq_dao]can't open");
        }
    }
    else {
        [self.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            [blocks enumerateObjectsUsingBlock:^(XQDBBlock  _Nonnull block, NSUInteger idx, BOOL * _Nonnull stop) {
                BOOL res = block(db);
                if (!res) {
                    *rollback = YES;
                    *stop = YES;
                }
            }];
        }];
        [self.dbQueue close];
    }
}

- (XQMigrationService *)setupMigrationService:(XQMigrationService *)service {
    if (service == nil) {
        service = [XQMigrationService new];
    }
    XQMigrationItemBase *migrationItem = [XQMigrationItemBase new];
    [service addMigrationItem:migrationItem version:2];
    return service;
}

- (void)setupForClasses:(NSArray<NSString *> *)classes migrationService:(XQMigrationService *)migrationService {
    [self executeBlock:^BOOL(FMDatabase *db) {
        uint32_t toVersion = (uint32_t)migrationService.version;
        if (toVersion == 0) {
            toVersion = 1;
        }
        __block BOOL res = NO;
        uint32_t fromVersion = [db userVersion];
        if (0 == fromVersion) { // 版本应该大于 0 开始
            db.userVersion = toVersion;
            self.version = toVersion;
            fromVersion = toVersion;
        }
        if (fromVersion != toVersion) {
            //TODO: 目前仅支持增加字段和删除表，不支持删除字段和修改字段
            [migrationService startMigrationFromVersion:fromVersion toVersion:toVersion];
            db.userVersion = toVersion;
            self.version = toVersion;
            XQDAOLog(@"[xq_dao]database migration!");
        } else {
            XQDAOLog(@"[xq_dao]database version:%d", fromVersion);
        }
        [classes enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            Class cls = NSClassFromString(obj);
            SEL createSQLSel = @selector(xq_createSQL);
            NSString *statement =((NSString * (*)(id, SEL))(void *)objc_msgSend)(cls, createSQLSel);
            res = [db executeStatements:statement];
            if (res == NO) {
                XQDAOLog(@"[xq_dao][dberr]%@", db.lastError);
            }
        }];
        return res;
    }];
}

- (void)setupDatabaseWithClasses:(NSArray<NSString *> *)classes
                migrationService:(XQMigrationService *)migrationService {
    XQDAOLog(@"[xq_dao]>>>>>安装数据库");
    [self setupForClasses:classes migrationService:migrationService];
    XQDAOLog(@"[xq_dao]数据库文件是否存在:%@", @([self isDBFileExist]));
#if DEBUG
    if (![self isDBFileExist]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIWindow *window = [UIApplication sharedApplication].keyWindow;
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"发生严重错误" message:@"数据库创建失败！！！" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *ok = [UIAlertAction actionWithTitle:@"立马检查代码" style:UIAlertActionStyleDestructive handler:nil];
            [alert addAction:ok];
            [window.rootViewController presentViewController:alert animated:YES completion:nil];
        });
    }
#endif
}

@end
