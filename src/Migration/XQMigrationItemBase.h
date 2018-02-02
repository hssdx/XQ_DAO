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
//  MigrationItemBase.h
//  Xunquan
//
//  Created by Xiongxunquan on 11/2/15.
//  Copyright © 2015 xunquan inc.. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, MigrationOperationType) {
    MOTDeleteTable,
    MOTDeleteField,
    MOTModifyField,
    MOTAddField,
    MOTDoBlock,
};

typedef NS_ENUM(NSInteger, FieldType) {
    FieldTypeNumber,
    FieldTypeString,
    FieldTypeInt,
    FieldTypeFloat,
};

@interface FPMigrationOperationItem : NSObject

@property(assign, nonatomic) MigrationOperationType optType;
@property(assign, nonatomic) FieldType fieldTypeNew;
@property(copy, nonatomic) NSString *table;
@property(copy, nonatomic) NSString *fieldOld;
@property(copy, nonatomic) NSString *fieldNew;
@property(copy, nonatomic) dispatch_block_t block;

@end

@interface XQMigrationItemBase : NSObject

/**
 *  迁移版本
 *
 *  @return 迁移版本号,对应db中databaseVersion字段.
 *  @如果返回17,表示当前迁移是版本16迁往版本17,每次只允许迁移一个版本编号,即不允许跨版本迁移.
 */
@property (assign, nonatomic) NSInteger version;
@property (strong, nonatomic) NSMutableArray *optArray;


- (void)addOperationWithType:(MigrationOperationType)optType
                       table:(NSString *)table
                    oldField:(NSString *)fieldOld
                    newField:(NSString *)fieldNew
                   fieldType:(FieldType)fieldTypeNew;

- (void)addField:(NSString *)field forTable:(NSString *)table fieldType:(FieldType)fieldType;
- (void)addBlock:(dispatch_block_t)block;
- (void)deleteTable:(NSString *)tableName;

@end
