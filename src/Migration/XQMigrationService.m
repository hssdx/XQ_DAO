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
//  MigrationService.m
//  Lighting
//
//  Created by Xiongxunquan on 11/2/15.
//  Copyright © 2015 xunquan inc.. All rights reserved.
//

#import "XQMigrationService.h"
#import "XQMigrationItemBase+Protect.h"
#import "XQFMDBManager.h"
#import <FMDB/FMDB.h>
#import <XQKit/XQKit.h>

@interface XQMigrationService()

@property (strong, nonatomic) NSDictionary *migrationOptDict;

@end

@implementation XQMigrationService

- (instancetype)init {
    if (self = [super init]) {
        self.migrationOptDict = @{};
    }
    return self;
}

- (NSString *)showTable:(NSString *)tableName {
    __block NSString *result;
    XQDBBlock block = ^BOOL(FMDatabase *db){
        NSString *sql = [NSString stringWithFormat:@"SELECT `sql` FROM `sqlite_master` WHERE `tbl_name` = `%@`", tableName];
        /*
         TODO: DB Error: 1 "no such column: User"
         */
        FMResultSet *result = [db executeQuery:sql];
        while ([result next]) {
            result = [result objectForColumn:@"sql"];
            XQLog(@"[%@]", result);
        }
        if (result) {
            [result close];
        }
        return result != nil;
    };
    [[XQFMDBManager defaultManager] executeBlock:block];
    return result;
}

- (void)startMigrationFromVersion:(int32_t)fromVersion toVersion:(int32_t)toVersion {
    /*
     sqllite 只支持删除表，重命名表，添加额外的列，除此之外，不支持其他alter命令
     */
    NSDictionary *fieldTypeMap = @{@(FieldTypeNumber):@"INTEGER",
                                   @(FieldTypeString):@"TEXT"};
    
    NSInteger currentDBVersion = fromVersion;
    NSInteger targetDBVersion = toVersion;
    while (currentDBVersion < targetDBVersion) {
        ++currentDBVersion;
        XQMigrationItemBase *item = [self.migrationOptDict objectForKey:@(currentDBVersion)];
        for (FPMigrationOperationItem *optItem in item.optArray) {
            NSString *optSql;
            switch (optItem.optType) {
                case MOTDeleteTable:
                    optSql = [NSString stringWithFormat:@"DROP TABLE %@", optItem.table];
                    break;
                case MOTDeleteField:
                    //TODO: delete field
                    XQAssert(false);
                    break;
                case MOTModifyField:
                    //TODO: modeify field
                    XQAssert(false);
                    break;
                case MOTAddField:
                {
                    //Default value
                    NSString *fieldType = fieldTypeMap[@(optItem.fieldTypeNew)];
                    optSql = [NSString stringWithFormat:@"ALTER TABLE %@ ADD %@ %@", optItem.table, optItem.fieldNew, fieldType];
                }
                    break;
                case MOTDoBlock:
                    if (optItem.block) {
                        optItem.block();
                    }
                    break;
            }
            XQLog(@"opt sql:(%@)", optSql);
            XQDBBlock block = ^BOOL(FMDatabase *db){
                NSError *error;
                BOOL res = [db executeUpdate:optSql withErrorAndBindings:&error];
                if (!res) {
                    XQLog(@"db update error:(%@)[%@]", error, optSql);
                }
                return res;
            };
            [[XQFMDBManager defaultManager] executeBlock:block];
#if DEBUG
            //[self showTable:optItem.table];
#endif
        }
        XQLog(@"DB migration (%d)to(%d) success!", (int)currentDBVersion-1, (int)currentDBVersion);
    }
}

@end
