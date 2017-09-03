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
//  MigrationItemBase.m
//  Xunquan
//
//  Created by Xiongxunquan on 11/2/15.
//  Copyright © 2015 xunquan inc.. All rights reserved.
//

#import "XQMigrationItemBase.h"

@implementation FPMigrationOperationItem

@end

@implementation XQMigrationItemBase

- (NSMutableArray *)optArray {
    if (_optArray == nil) {
        _optArray = [NSMutableArray array];
    }
    return _optArray;
}

- (void)addOperationWithType:(MigrationOperationType)optType
                       table:(NSString *)table
                    oldField:(NSString *)fieldOld
                    newField:(NSString *)fieldNew
                   fieldType:(FieldType)fieldTypeNew {
    FPMigrationOperationItem *item = [FPMigrationOperationItem new];
    item.optType = optType;
    item.table  = table;
    item.fieldOld = fieldOld;
    item.fieldNew = fieldNew;
    item.fieldTypeNew = fieldTypeNew;
    [self.optArray addObject:item];
}

- (void)addField:(NSString *)field forTable:(NSString *)table fieldType:(FieldType)fieldType {
    [self addOperationWithType:MOTAddField table:table oldField:nil newField:field fieldType:fieldType];
}

- (void)addBlock:(dispatch_block_t)block {
    FPMigrationOperationItem *item = [FPMigrationOperationItem new];
    item.optType = MOTDoBlock;
    item.block = block;
    [self.optArray addObject:item];
}

- (void)deleteTable:(NSString *)tableName {
    //删除表，只有table参数有意义，其他参数无意义
    [self addOperationWithType:MOTDeleteTable table:tableName oldField:nil newField:nil fieldType:FieldTypeString];
}
@end
