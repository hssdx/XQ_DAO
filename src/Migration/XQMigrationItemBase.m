//
//  MigrationItemBase.m
//  Lighting
//
//  Created by Xiongxunquan on 11/2/15.
//  Copyright © 2015 xunquan inc.. All rights reserved.
//

#import "XQMigrationItemBase+Protect.h"

@implementation FPMigrationOperationItem

@end

@implementation XQMigrationItemBase

- (instancetype)init {
    if (self = [super init]) {
        [self loadOperationItem];
    }
    return self;
}

- (void)loadOperationItem {
    NSAssert(false, @"子类需要实现");
}

- (NSUInteger)version {
    NSAssert(false, @"子类需要实现");
    return 0;
}

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
