//
//  MigrationItemBase+Protect.h
//  Lighting
//
//  Created by Xiongxunquan on 11/2/15.
//  Copyright © 2015 xunquan inc.. All rights reserved.
//

#import "XQMigrationItemBase.h"

@interface XQMigrationItemBase()

- (void)addOperationWithType:(MigrationOperationType)optType
                       table:(NSString *)table
                    oldField:(NSString *)fieldOld
                    newField:(NSString *)fieldNew
                   fieldType:(FieldType)fieldTypeNew;

- (void)addField:(NSString *)field forTable:(NSString *)table fieldType:(FieldType)fieldType;
- (void)addBlock:(dispatch_block_t)block;
- (void)deleteTable:(NSString *)tableName;
@end
