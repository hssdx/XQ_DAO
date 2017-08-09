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

#import <FMDB/FMDB.h>
#import <YYKit/YYKit.h>
#import <XQKit/XQKit.h>
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

+ (YYThreadSafeDictionary *)managersDict {
    static YYThreadSafeDictionary *s_managersDict;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_managersDict = [YYThreadSafeDictionary dictionary];
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
    if ([self.dbQueue isNestedQueue]){
        if ([self.db open])
            block(self.db);
        else
            XQLog(@"can't open");
    }
    else{
        [self.dbQueue inDatabase:^(FMDatabase *db){
            block(db);
        }];
        [self.dbQueue close];
    }
}

- (void)executeBlocksInTransaction:(NSArray<XQDBBlock> *)blocks {
    if ([self.dbQueue isNestedQueue]) {
        XQLog(@"在一个自身的 db queue 里未退出，无法启动事务操作模式");
        if ([self.db open]) {
            [blocks enumerateObjectsUsingBlock:^(XQDBBlock  _Nonnull block, NSUInteger idx, BOOL * _Nonnull stop) {
                block(self.db);
            }];
        }
        else {
            XQLog(@"can't open");
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

- (void)setupForClasses:(NSArray<NSString *> *)classes version:(uint32_t)version {
    [self executeBlock:^BOOL(FMDatabase *db) {
        __block BOOL res = NO;
        uint32_t userVersion = [db userVersion];
        if (0 == userVersion) { // 版本应该大于 0 开始
            db.userVersion = version;
            self.version = version;
        }
        if (userVersion != version) {
            //TODO: 目前仅支持增加字段和删除表，不支持删除字段和修改字段
            XQMigrationService *migration = [XQMigrationService new];
            [migration startMigrationFromVersion:userVersion toVersion:version];
            db.userVersion = version;
            self.version = version;
            XQLog(@"database migration!");
        } else {
            XQLog(@"database version:%d", userVersion);
        }
        [classes enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            Class cls = NSClassFromString(obj);
            SEL createSQLSel = NSSelectorFromString(@"createSQL");
            NSString *statement =((NSString * (*)(id, SEL))(void *)objc_msgSend)(cls, createSQLSel);
            res = [db executeStatements:statement];
            if (res == NO) {
                XQLog(@"[dberr]%@", db.lastError);
            }
        }];
        return res;
    }];
}

- (void)setupDatabaseWithClasses:(NSArray<NSString *> *)classes version:(uint32_t)version {
    XQLog(@">>>>>安装数据库");
    [self setupForClasses:classes version:version];
    XQLog(@"数据库文件是否存在:%@", @([self isDBFileExist]));
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
