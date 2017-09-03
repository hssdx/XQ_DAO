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
//  XQFMDBManager.h
//  XQ_DAO
//
//  Created by quanxiong on 2017/8/8.
//  Copyright © 2017年 com.hssdx. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FMDatabase;
@class XQMigrationService;

typedef BOOL (^XQDBBlock)(FMDatabase *db);

@interface XQFMDBManager : NSObject

@property (assign, nonatomic, readonly) int32_t version;

+ (instancetype)managerWithKey:(NSString *)key useGroup:(BOOL)useGroup;

+ (instancetype)defaultManager;

- (BOOL)isDBFileExist;
- (BOOL)removeDatabase;

- (void)executeBlock:(XQDBBlock)block;

- (void)executeBlocksInTransaction:(NSArray<XQDBBlock> *)blocks;

/*创建模型对象 与 sql 表，模型对象需要实现 <XQDBModel> 协议*/
- (void)setupDatabaseWithClasses:(NSArray<NSString *> *)classes
                migrationService:(XQMigrationService *)migrationService;

@end
