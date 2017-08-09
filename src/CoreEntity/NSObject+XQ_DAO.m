//
//  ModelBase.m
//  Lighting
//
//  Created by Xiongxunquan on 9/12/15.
//  Copyright © 2015 xunquan inc.. All rights reserved.
//

#import "NSObject+XQ_DAO.h"
#import "XQSQLCondition.h"
#import "XQFMDBManager.h"
#import "NSArray+XQUtils.h"

#import <objc/runtime.h>
#import <FMDB/FMDB.h>
#import <XQKit/XQKit.h>
#import <YYKit/YYKit.h>

/**
 *  model表信息，包括字段名集合，字段类型集合，表名
 *  @{@"fieldNames": NSArray, @"fieldTypes":NSArray, @"tableName":NSString}
 */
typedef NSArray<NSString *> WCModelDescribtion;
typedef NSDictionary<NSString *, id> WCModelTableDescribtion;
typedef NSCache<NSString *, WCModelTableDescribtion *> WCModelCacheType;

NSString *const kFieldNames = @"fieldNames";
NSString *const kFieldTypes = @"fieldTypes";
NSString *const kTableName = @"tableName";


@implementation NSObject (XQ_DAO)

//- (void)setLocalID:(NSNumber *)localID {
//    if (localID == _localID) {
//        return;
//    }
//    _localID = [self.class safeNumberValue:localID];
//    XQAssert(!!localID == !!_localID);
//}

+ (NSString*)rawUUID {
    NSString *uuid = nil;
    CFUUIDRef puuid = CFUUIDCreate(nil);
    CFStringRef uuidString = CFUUIDCreateString(nil, puuid);
    uuid = (NSString *)CFBridgingRelease(CFStringCreateCopy(NULL, uuidString));
    XQCFRelease(puuid);
    XQCFRelease(uuidString);
    return uuid;
}

+ (NSArray *)idsGroupByIds:(NSArray *)ids limitCount:(NSInteger)limitCount {
    NSMutableArray<NSArray *> *idsGroup = [NSMutableArray array];
    for (NSUInteger idx = 0; idx < ids.count; idx += limitCount) {
        NSUInteger length = limitCount;
        if (idx + limitCount > ids.count) {
            length = ids.count - idx;
        }
        [idsGroup addObject:[ids subarrayWithRange:NSMakeRange(idx, length)]];
    }
    return idsGroup;
}

#pragma mark - override func
+ (NSDictionary *)fieldDescribeDict {
    NSMutableSet *fieldsSet = [NSMutableSet set];
    NSMutableDictionary *fieldDescribes = [NSMutableDictionary dictionary];
    fieldDescribes[PROP_TO_STRING(deleted)] = @"DEFAULT 0";
    fieldDescribes[self.primaryKey] = @"PRIMARY KEY AUTOINCREMENT NOT NULL";
    [fieldsSet addObject:self.primaryKey];
    NSArray<NSString *> *fields  = [self uniquesNotNull];
    for (NSString *field in fields) {
        if ([fieldsSet containsObject:field]) {
            continue;
        }
        [fieldsSet addObject:field];
        fieldDescribes[field] = @"NOT NULL UNIQUE";
    }
    NSMutableSet<NSString *> *notNullfields = [NSMutableSet set];
    [notNullfields addObjectsFromArray:[self notNullFields]];
    for (NSString *field in notNullfields) {
        if ([fieldsSet containsObject:field]) {
            continue;
        }
        [fieldsSet addObject:field];
        fieldDescribes[field] = @"NOT NULL";
    }
    return fieldDescribes;
}

+ (NSString *)fieldDescribe:(NSString *)fieldName {
    NSDictionary *mapping = [self fieldDescribeDict];
    NSString *result = mapping[fieldName];
    if ([result length] > 0) {
        return result;
    } else {
        return @"";
    }
}

+ (NSArray<NSDictionary<NSString *, NSNumber *> *> *)orderSQLsArray {
    return @[@{PROP_TO_STRING(localID):@(OrderTypeDESC)}];
}

+ (NSDictionary<NSString *, NSNumber *> *)startValueForAutoIncrement {
    return @{PROP_TO_STRING(localID):@100};
}

+ (NSString *)primaryKey {
    return PROP_TO_STRING(localID);
}

+ (NSArray<NSString *> *)uniquesAbleNull {
    return [self uniquesNotNull];
}

+ (NSArray<NSString *> *)uniquesNotNull {
    return @[PROP_TO_STRING(localID),
             PROP_TO_STRING(UUID)];
}

+ (NSArray<NSString *> *)notNullFields {
    return [self uniquesNotNull];
}

- (XQSQLCondition *)defaultExistCondition {
    return [self defaultExistConditionWithDbModel:nil];
}

- (XQSQLCondition *)defaultExistConditionWithDbModel:(__kindof NSObject *)dbModel {
    XQSQLCondition *condition = [XQSQLCondition new];
    NSArray<NSString *> *fields  = [self.class uniquesAbleNull];
    for (NSString *field in fields) {
        if ([self respondsToSelector:NSSelectorFromString(field)]) {
            id value = [self valueForKey:field];
            if (!value) {
                continue;
            }
            if (dbModel && ![dbModel valueForKey:field]) {
                //数据库该 dbModel 记录没有该值，跳过此条件
                continue;
            }
            [condition addWhereField:field
                             compare:SQLCompareEqual
                               value:value
                           logicCode:LogicCodeOr];
        }
    }
    return condition;
}
/**
 * 要插入数据前的检查
 * 返回 YES 则允许插入，否则返回 NO
 */
- (BOOL)willInsert {
    NSArray *fields = [self.class notNullFields];
    for (NSString *field in fields) {
        if ([field isEqualToString:[self.class primaryKey]]) {
            id value = [self valueForKey:field];
            if (value) {
                [self setValue:nil forKey:field];
#if 0
                XQLogWarn(@"[主键不需要设定]%@, %@", value, [self class]);
#endif
            }
            continue;//主键不需要设定
        }
        if (nil == [self valueForKey:field]) {
            XQLogWarn(@"[%@](%@)field error so can't insert this object", [self.class tableName], field);
            return NO;
        }
    }
    return YES;
}

/**
 * 如果是需要更新的字段，或数据库中不存在，则需要更新
 * 返回 YES 则更新当前值，否则返回 NO
 */
- (BOOL)willUpdatedbModel:(NSObject *)dbModel withFieldName:(NSString *)fieldName {
    id value = [self valueForKey:fieldName];
    if (!value) {
        return NO;
    }
    id dbValue = [dbModel valueForKey:fieldName];
    if (!dbValue) {
        return YES;
    }
    if ([self.class isUnchangeableField:fieldName]) {
        return NO;
    }
    if (![value isKindOfClass:[dbValue class]]) {
        if ([value isKindOfClass:[NSNumber class]] &&
            [dbValue isKindOfClass:[NSNumber class]]) {
            if ([value isEqualToNumber:dbValue]) {
                return NO;
            }
        }
        if ([value isKindOfClass:[NSString class]] &&
            [dbValue isKindOfClass:[NSString class]]) {
            if ([value isEqualToString:dbValue]) {
                return NO;
            }
        }
        if ([value respondsToSelector:@selector(stringValue)] &&
            [dbValue respondsToSelector:@selector(stringValue)]) {
            value = [value stringValue];
            dbValue = [dbValue stringValue];
            if ([value isEqualToString:dbValue]) {
                XQLog(@">%@< >%@<", OBJ_CLASS_NAME([self valueForKey:fieldName]), OBJ_CLASS_NAME([dbModel valueForKey:fieldName]));
                XQLog(@"这里有一个隐患，需要注意 NSNumber 类型和 NSString 类型之间的兼容性，这应该在你定义 EntityModel 时需要注意。可以参见 serverID 和 localID 字段重写的 setter.");
                return NO;
            }
        }
        return YES;
    }
    return YES;
}

+ (BOOL)isPrimaryKey:(NSString *)field {
    if (!field) {
        return NO;
    }
    if ([field isEqualToString:[self primaryKey]]) {
        return YES;
    }
    return NO;
}

+ (BOOL)isUnchangeableField:(NSString *)field {
    if (!field) {
        return NO;
    }
    if ([[self uniquesAbleNull] containsObject:field]) {
        return YES;
    }
    return NO;
}

+ (BOOL)isUnableNullField:(NSString *)field {
    if (!field) {
        return NO;
    }
    if ([[self notNullFields] containsObject:field]) {
        return YES;
    }
    return NO;
}

#pragma mark - public func
+ (NSObject *)existObject:(NSObject *)modelObj {
    if (!modelObj) {
        return nil;
    }
    XQSQLCondition *condition = [modelObj defaultExistCondition];
    if ([condition.condition count] == 0) {
        return nil;
    }
    NSObject *result = [self queryModelsWithCondition:condition].firstObject;
    return result;
}

+ (void)copyFromObject:(NSObject *)fromObject toObject:(NSObject *)toObject {
    WCModelTableDescribtion *tableDescribtion = [self tableDescribtion];
    WCModelDescribtion *fieldNames = tableDescribtion[kFieldNames];
    [fieldNames enumerateObjectsUsingBlock:^(NSString * _Nonnull fieldName, NSUInteger idx, BOOL * _Nonnull stop) {
        id value = [fromObject valueForKey:fieldName];
        if (value) {
            [toObject setValue:value forKey:fieldName];
        }
    }];
}

+ (void)saveObjectsInTransaction:(NSArray<__kindof NSObject *> *)objects updateIfExist:(BOOL)updateIfExist {
    if (objects.count == 0) {
        return;
    }
    NSMutableArray<NSObject *> *deleteModels = [NSMutableArray array];
    NSMutableArray<NSObject *> *saveModels = [NSMutableArray array];
    NSMutableDictionary *rejectDuplicateFieldDict = [NSMutableDictionary new]; //判重 field -> valuesSet
    NSArray *fields = [self uniquesAbleNull];
    [objects enumerateObjectsUsingBlock:^(__kindof NSObject * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        for (NSString *field in fields) {
            id value = [obj valueForKey:field];
            if (value) {
                NSMutableSet *rejectDuplicateSet = rejectDuplicateFieldDict[field];
                if (!rejectDuplicateSet) {
                    rejectDuplicateSet = [NSMutableSet set];
                    rejectDuplicateFieldDict[field] = rejectDuplicateSet;
                    [rejectDuplicateSet addObject:value];
                } else {
                    BOOL duplicate = [rejectDuplicateSet containsObject:value];
                    if (duplicate) {
                        return ;
                    }
                    [rejectDuplicateSet addObject:value];
                }
            }
        }
        id<XQDBModel> model = obj;
        if (model.deleted.boolValue) {
            [deleteModels addObject:obj];
        } else {
            [saveModels addObject:obj];
        }
    }];
    [self deleteObjectsInTransaction:deleteModels];
    [self _saveObjectsInTransaction:saveModels updateIfExist:updateIfExist];
    if (deleteModels.count > 0) {
        [self xqNotifyAction:@"DeleteModels" withObject:deleteModels];
//        [[NSNotificationCenter defaultCenter] notifyModelDelete:deleteModels];
    }
    if (saveModels.count > 0) {
        [self xqNotifyAction:@"AddModels" withObject:saveModels];
//        [[NSNotificationCenter defaultCenter] notifyModelAdd:saveModels];
    }
}

+ (void)saveObjectsInTransaction:(NSArray<__kindof NSObject *> *)objects {
    [self saveObjectsInTransaction:objects updateIfExist:YES];
}

+ (void)_saveObjectsInTransaction:(NSArray<__kindof NSObject *> *)objects updateIfExist:(BOOL)updateIfExist {
    if (objects.count == 0) {
        return;
    }
    NSArray<XQDBBlock> *blocks = [objects xq_compact:^id _Nonnull(__kindof NSObject * _Nonnull object) {
        XQDBBlock block = [self dbBlockForAddObject:^(id model) {
            [self copyFromObject:object toObject:model];
        } updateIfExist:updateIfExist];
        return block;
    }];
    [[XQFMDBManager defaultManager] executeBlocksInTransaction:blocks];
}

//+ (void)target:(id)target performAction:(SEL)action object:(id)object delay:(NSTimeInterval)delay {
//    [[target class] cancelPreviousPerformRequestsWithTarget:target
//                                                   selector:action
//                                                     object:object];
////    self xqNotifyAction:<#(NSString *)#> withObject:<#(id)#>
//    [self performSelector:@selector(xqNotifyAction:withObject:)
//               withObject:object
//               afterDelay:delay];
//}

+ (void)saveObjectWithBlock:(InitModelBlock)initModelBlock updateIfExist:(BOOL)updateIfExist optType:(DBOptType *)optType {
    
    __block NSObject *blockModel;
    InitModelBlock initBlock = ^(id model){
        if (initModelBlock) {
            initModelBlock(model);
        }
        blockModel = model;
    };
    [self _saveObjectWithBlock:initBlock updateIfExist:updateIfExist optType:optType];
    if (blockModel) {
        switch (*optType) {
            case DBOptTypeAdd:
//                [self target:[NSNotificationCenter defaultCenter] performAction:@selector(notifyModelAdd:) object:blockModel delay:0.5];
                break;
            case DBOptTypeDelete:
//                [self target:[NSNotificationCenter defaultCenter] performAction:@selector(notifyModelDelete:) object:blockModel delay:0.5];
                break;
            case DBOptTypeUpdate:
            case DBOptTypeNone:
//                [self target:[NSNotificationCenter defaultCenter] performAction:@selector(notifyModelUpdate:) object:blockModel delay:0.5];
                break;
        }
    }
}

- (void)save {
    [self.class saveObject:self];
}

+ (void)saveObject:(__kindof NSObject *)object {
    [self saveObject:object updateIfExist:YES];
}

+ (void)saveObject:(__kindof NSObject *)object updateIfExist:(BOOL)updateIfExist {
    [self saveObjectWithBlock:^(id model) {
        [self copyFromObject:object toObject:model];
    } updateIfExist:updateIfExist];
}

+ (void)saveObjectWithBlock:(InitModelBlock)initModelBlock updateIfExist:(BOOL)updateIfExist {
    DBOptType optType = DBOptTypeNone;
    [self saveObjectWithBlock:initModelBlock updateIfExist:updateIfExist optType:&optType];
}

+ (void)_saveObjectWithBlock:(InitModelBlock)initModelBlock updateIfExist:(BOOL)updateIfExist optType:(DBOptType *)optType {
    XQDBBlock block = [self dbBlockForAddObject:initModelBlock updateIfExist:updateIfExist optType:optType];
    if (block) {
        [[XQFMDBManager defaultManager] executeBlock:block];
    }
}

- (BOOL)deleteFromDatabase {
    BOOL res = [self.class deleteObject:self];
//    [[NSNotificationCenter defaultCenter] notifyModelDelete:self];
    return res;
}

+ (BOOL)deleteObject:(__kindof NSObject *)object {
    XQDBBlock block = [self dbBlockForDeleteObject:object];
    [[XQFMDBManager defaultManager] executeBlock:block];
    return !!block;
}

+ (BOOL)deleteObjectsInTransaction:(NSArray<__kindof NSObject *> *)objects {
    NSArray<XQDBBlock> *blocks = [objects xq_compact:^id _Nonnull(__kindof NSObject * _Nonnull object) {
        return [self dbBlockForDeleteObject:object];
    }];
    [[XQFMDBManager defaultManager] executeBlocksInTransaction:blocks];
    if (blocks.count == 0 && objects > 0) {
        return NO;
    }
    return YES;
}

+ (BOOL)deleteObjectWithCondition:(XQSQLCondition *)condition {
    XQDBBlock block = [self dbBlockForDeleteObjectWithCondition:condition];
    [[XQFMDBManager defaultManager] executeBlock:block];
    return !!block;
}

+ (BOOL)deleteWhere:(NSString *)field equal:(id)value {
    XQSQLCondition *condition = [XQSQLCondition conditionWhere:field equal:value];
    return [self deleteObjectWithCondition:condition];
}

+ (BOOL)deleteWhereLocalIDEqual:(NSNumber *)localID {
    return [self deleteWhere:PROP_TO_STRING(localID) equal:localID];
}

+ (BOOL)clean {
    __block BOOL res = NO;
    __block NSError *error;
    
    XQDBBlock block = ^BOOL(FMDatabase *db){
        WCModelTableDescribtion *tableDescribtion = [self tableDescribtion];
        NSString *tableName = tableDescribtion[kTableName];
        NSString *sql = [NSString stringWithFormat:@"DROP TABLE IF EXISTS %@", tableName];
        res = [db executeUpdate:sql withErrorAndBindings:&error];
        if (res) {
            res = [db executeStatements:[self createSQL]];
            XQLog(@"Model '%@' clean success", NSStringFromClass(self));
        }
        return res;
    };
    
    [[XQFMDBManager defaultManager] executeBlock:block];
    
    if (!res)
        XQLog(@"db open failure when delete '%@', (%@)", NSStringFromClass(self), error);
    return res;
}

+ (NSArray<__kindof NSObject *> *)queryModels {
    return [self queryModelsAtIndex:0 limitCount:0];
}

+ (NSArray<__kindof NSObject *> *)queryModelsWithCondition:(XQSQLCondition *)condition {
    __block NSMutableArray *queryResult = [NSMutableArray array];
    [self queryModelsWithBlock:^(NSObject *model) {
        [queryResult addObject:model];
    } condition:condition];
    return queryResult;
}

+ (void)queryModelsWithBlock:(QueryModelBlock)queryModelBlock
                     atIndex:(NSUInteger)index
                  limitCount:(NSUInteger)limitCount {
    XQSQLCondition *condition = [XQSQLCondition new];
    [condition setLimitFrom:index limitCount:limitCount];
    [self queryModelsWithBlock:queryModelBlock
                     condition:condition];
}

+ (NSArray<__kindof NSObject *> *)queryModelsAtIndex:(NSUInteger)index limitCount:(NSUInteger)limitCount {
    XQSQLCondition *condition = [XQSQLCondition new];
    [condition setLimitFrom:index limitCount:limitCount];
    return [self queryModelsWithCondition:condition];
}

+ (instancetype)queryWhereUUIDEqual:(NSString *)UUID {
    return [self queryWhere:PROP_TO_STRING(UUID) equal:UUID];
}

+ (instancetype)queryWhereLocalIDEqual:(NSNumber *)localID {
    return [self queryWhere:PROP_TO_STRING(localID) equal:localID];
}

+ (instancetype)queryWhere:(NSString *)field equal:(id)value {
    if (!value) {
        return nil;
    }
    XQSQLCondition *condition = [XQSQLCondition conditionWhere:field equal:value];
    __kindof NSObject *result =
    [[self queryModelsWithCondition:condition] firstObject];
    return result;
}

+ (NSArray<__kindof NSObject *> *)queryModelsWhere:(NSString *)field equal:(id)value {
    XQSQLCondition *condition = [XQSQLCondition conditionWhere:field equal:value];
    return [self queryModelsWithCondition:condition];
}

+ (void)queryModelsWithBlock:(QueryModelBlock)queryModelBlock condition:(XQSQLCondition *)condition {
    WCModelTableDescribtion *tableDescribtion = [self tableDescribtion];
    WCModelDescribtion *fieldNames = tableDescribtion[kFieldNames];
    NSString *tableName = tableDescribtion[kTableName];
    
    @weakify(self);
    XQDBBlock block = ^BOOL(FMDatabase *db){
        @strongify(self);
        /*select * from user where localID=1 order by xx DESC limit 0,1*/
        NSMutableString *sql = [NSMutableString stringWithString:@"select "];
        for (NSUInteger index = 0; index < fieldNames.count; ++index) {
            NSString *name = fieldNames[index];
            [sql appendString:name];
            if (index != fieldNames.count - 1) {
                [sql appendString:@","];
            }
        }
        [sql appendFormat:@" from %@ ", tableName];
        if (condition.orderSQLs.count == 0) {
            [[self orderSQLsArray] enumerateObjectsUsingBlock:
             ^(NSDictionary<NSString *,NSNumber *> * _Nonnull obj,
               NSUInteger idx, BOOL * _Nonnull stop) {
                 XQAssert(obj.count == 1);
                [condition addOrderField:obj.allKeys.firstObject orderType:obj.allValues.firstObject.integerValue];
            }];
        }
        
        NSString *conditionSQL = [condition conditionSQL];
        if ([conditionSQL length] > 0) {
            [sql appendString:conditionSQL];
        }
        FMResultSet * rs = [db executeQuery:sql];
        while ([rs next]) {
            NSObject *object = [[self alloc] init];
            
            for (NSString *name in fieldNames) {
                id value = [rs objectForColumn:name];
                if (value && NO == [value isKindOfClass:[NSNull class]]) {
                    [object setValue:value forKey:name];
                }
            }
            if (queryModelBlock) {
                queryModelBlock(object);
            }
        }
        if (rs) {
            [rs close];
        } else {
            NSError *error = [db lastError];
            if (error.code != 0) {
                return NO;
            }
        }
        return YES;
    };
    [[XQFMDBManager defaultManager] executeBlock:block];
}

+ (void)setProperty:(NSString *)prop value:(id)value {
    [self setProperty:prop value:value condition:nil];
}

#pragma mark - advanced func

+ (XQDBBlock)dbBlockForInsertObject:(NSObject *)model {
    WCModelTableDescribtion *tableDescribtion = [self tableDescribtion];
    WCModelDescribtion *fieldNames = tableDescribtion[kFieldNames];
    NSString *tableName = tableDescribtion[kTableName];
    
    @weakify(self);
    return [^BOOL(FMDatabase *db) {
        @strongify(self);
        id uuid = [model valueForKey:PROP_TO_STRING(UUID)];
        if (!uuid) {
            //强制有 UUID
            [model setValue:[self rawUUID] forKey:PROP_TO_STRING(UUID)];
        }
        if (NO == [model willInsert]) {
            return YES;
        }
        NSMutableString *sql = [NSMutableString stringWithString:@"insert into "];
        [sql appendString:tableName];
        NSMutableArray *columnArray = [NSMutableArray array];
        NSMutableArray *valuesArray = [NSMutableArray array];
        NSMutableArray *sympleArray = [NSMutableArray array];
        [fieldNames enumerateObjectsUsingBlock:
         ^(NSString *_Nonnull fieldName, NSUInteger idx, BOOL * _Nonnull stop) {
             if (![self isPrimaryKey:fieldName]) {
                 id value = [model valueForKey:fieldName];
                 if (value && ![value isKindOfClass:[NSNull class]]) {
                     [columnArray addObject:fieldName];
                     [valuesArray addObject:value];
                     [sympleArray addObject:@"?"];
                 }
             }
         }];
        NSString *columnSql = [[columnArray valueForKey:@"description"] componentsJoinedByString:@","];
        NSString *sympleSql = [[sympleArray valueForKey:@"description"] componentsJoinedByString:@","];
        [sql appendFormat:@" (%@) values (%@)", columnSql, sympleSql];
        BOOL res = [db executeUpdate:sql withArgumentsInArray:valuesArray];
        if (res) {
            return res;
        }
        XQLog(@"insert failure:[%@](%@)", db.lastError, sql);
#if !容错
        columnArray = [NSMutableArray array];
        valuesArray = [NSMutableArray array];
        XQSQLCondition *condition = [model defaultExistCondition];
        NSString *updateSql = [self updateSqlForModel:model dbModel:nil fieldNames:fieldNames columnArray:columnArray valuesArray:valuesArray condition:condition];
        if (updateSql) {
            res = [db executeUpdate:updateSql withArgumentsInArray:valuesArray];
            if (!res) {
                XQLog(@"update 也 failure:[%@](%@)", db.lastError, updateSql);
                XQAssert(false);
            }
        } else {
            XQLogWarn(@"!!!update object sql is nil.");
            res = YES;
        }
#endif
        return res;
    } copy];
}

+ (void)setProperty:(NSString *)prop value:(id)value condition:(XQSQLCondition *)condition {
    XQDBBlock block = [self dbBlockForUpdateProperty:prop value:value condition:condition];
    [[XQFMDBManager defaultManager] executeBlock:block];
}

+ (NSUInteger)countOfCol {
    return [self countOfCondition:nil];
}

//+ (BOOL)tableExisted {
//    __block BOOL exist = NO;
//    [[XQFMDBManager defaultManager] executeBlock:^BOOL(FMDatabase *db) {
//        NSString *sql =
//        [NSString stringWithFormat:@"\
//         SELECT count(*) FROM `sqlite_master` \
//         WHERE `type` = 'table' AND lower(name) = '%@'",
//         [self tableName]];
//        
//        FMResultSet *rs = [db executeQuery:sql];
//        while ([rs next]) {
//            NSNumber *value = [rs objectForColumnIndex:0];
//            if (value.longLongValue > 0) {
//                exist = YES;
//            }
//            [rs close];
//        }
//        return YES;
//    }];
//    return exist;
//}

+ (NSUInteger)countOfWhereProp:(NSString *)prop equal:(id)value {
    XQSQLCondition *condition = [XQSQLCondition new];
    [condition addWhereField:prop compare:SQLCompareEqual value:value logicCode:LogicCodeNone];
    return [self countOfCondition:condition];
}

+ (NSUInteger)countOfWhereProp:(NSString *)prop notEqual:(id)value {
    XQSQLCondition *condition = [XQSQLCondition new];
    [condition addWhereField:prop compare:SQLCompareNotEqual value:value logicCode:LogicCodeNone];
    return [self countOfCondition:condition];
}

+ (NSUInteger)countOfCondition:(XQSQLCondition *)condition {
    NSString *tableName = NSStringFromClass(self.class);
    __block NSUInteger count = 0;
    XQDBBlock block = ^BOOL(FMDatabase *db){
        NSMutableString *sql = [NSMutableString string];
        [sql appendFormat:@"select count(*) from %@ ", tableName];
        NSString *whereSql = [condition conditionSQL];
        if (whereSql) {
            [sql appendString:whereSql];
        }
        FMResultSet * rs = [db executeQuery:sql];
        BOOL res = [rs next];
        if (res) {
            NSNumber *value = [rs objectForColumnIndex:0];
            count = value.unsignedIntegerValue;
            [rs close];
        } else {
            XQLog(@"!!! 查询表的 column count 错误!");
            return NO;
        }
        return YES;
    };
    [[XQFMDBManager defaultManager] executeBlock:block];
    return count;
}

+ (XQDBBlock)dbBlockForUpdateProperty:(NSString *)prop value:(id)value condition:(XQSQLCondition *)condition {
    NSObject *model = [self new];
    [model setValue:value forKey:prop];
    return [self dbBlockForUpdateObject:model dbModel:nil condition:condition];
}

+ (NSString *)updateSqlForModel:(NSObject *)model
                        dbModel:(NSObject *)dbModel
                     fieldNames:(WCModelDescribtion *)fieldNames
                    columnArray:(NSMutableArray *)columnArray
                    valuesArray:(NSMutableArray *)valuesArray
                      condition:(XQSQLCondition *)condition {
    NSString *tableName = NSStringFromClass(self.class);
    [fieldNames enumerateObjectsUsingBlock:
     ^(NSString *_Nonnull fieldName, NSUInteger idx, BOOL * _Nonnull stop) {
         if (![self isPrimaryKey:fieldName]) {
             if (dbModel) {
                 if ([model willUpdatedbModel:dbModel withFieldName:fieldName]) {
                     [columnArray addObject:[NSString stringWithFormat:@" %@=? ", fieldName]];
                     [valuesArray addObject:[model valueForKey:fieldName]];
                     [dbModel setValue:[model valueForKey:fieldName] forKey:fieldName];
                 }
             } else {
                 id value = [model valueForKey:fieldName];
                 if (value /* && NO == [self.class isUniqueField:fieldName]*/) {
                     [columnArray addObject:[NSString stringWithFormat:@" %@=? ", fieldName]];
                     [valuesArray addObject:[model valueForKey:fieldName]];
                     [dbModel setValue:[model valueForKey:fieldName] forKey:fieldName];
                 }
             }
         }
     }];
    if (valuesArray.count != 0) {
        NSString *columnSql = [[columnArray valueForKey:@"description"] componentsJoinedByString:@","];
        NSString *whereSql = [condition conditionSQL];
        NSMutableString *sql = [NSMutableString string];
        [sql appendFormat:@"UPDATE %@ SET %@ ", tableName, columnSql];
        if (whereSql) {
            [sql appendString:whereSql];
        }
        return sql;
    }
    return nil;
}

+ (XQDBBlock)dbBlockForUpdateObject:(NSObject *)model dbModel:(NSObject *)dbModel condition:(XQSQLCondition *)condition {
    WCModelTableDescribtion *tableDescribtion = [self tableDescribtion];
    WCModelDescribtion *fieldNames = tableDescribtion[kFieldNames];
    
    @weakify(self);
    return [^BOOL(FMDatabase *db){
        @strongify(self);
        NSMutableArray *columnArray = [NSMutableArray array];
        NSMutableArray *valuesArray = [NSMutableArray array];
        
        NSString *sql =
        [self updateSqlForModel:model dbModel:dbModel fieldNames:fieldNames columnArray:columnArray valuesArray:valuesArray condition:condition];
        if (sql) {
            BOOL res = [db executeUpdate:sql withArgumentsInArray:valuesArray];
            if (!res) {
                XQLog(@"update object error: %@(%@)", db.lastError, sql);
                XQAssert(false);
            }
            return res;
        }
        return YES;
    } copy];
}

+ (XQDBBlock)dbBlockForAddObject:(InitModelBlock)initModelBlock updateIfExist:(BOOL)updateIfExist {
    DBOptType optType = DBOptTypeNone;
    return [self dbBlockForAddObject:initModelBlock updateIfExist:updateIfExist optType:&optType];
}

+ (XQDBBlock)dbBlockForAddObject:(InitModelBlock)initModelBlock updateIfExist:(BOOL)updateIfExist optType:(DBOptType *)optType {
    XQDBBlock block;
    NSObject *model = [[self alloc] init];
    if (initModelBlock) {
        initModelBlock(model);
    }
    if (optType) {
        *optType = DBOptTypeUpdate;
    }
    NSObject *dbExistModel = [self existObject:model];
    if (dbExistModel) {
        if (!updateIfExist) {
            return nil;
        }
        //delete opt
        if (optType) {
            static SEL s_deletedSEL;
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                s_deletedSEL = NSSelectorFromString(PROP_TO_STRING(deleted));
            });
            if ([model respondsToSelector:s_deletedSEL]) {
                NSNumber *deleted = [model valueForKey:PROP_TO_STRING(deleted)];
                if (deleted.boolValue) {
                    *optType = DBOptTypeDelete;
                    block = [self dbBlockForDeleteObject:model];
                }
            }
            if (!block) {
                *optType = DBOptTypeUpdate;
            }
        }
        if (!block) {
            XQSQLCondition *condition = [model defaultExistConditionWithDbModel:dbExistModel];
            block = [self dbBlockForUpdateObject:model
                                         dbModel:dbExistModel
                                       condition:condition];
        }
    } else {
        if (optType) {
            *optType = DBOptTypeAdd;
        }
        block = [self dbBlockForInsertObject:model];
    }
    return [block copy];
}

+ (XQDBBlock)dbBlockForDeleteObject:(__kindof NSObject *)object {
    if (![self existObject:object]) { //不存在
        return nil;
    }
    XQSQLCondition *condition = [object defaultExistCondition];
    XQDBBlock block = [self dbBlockForDeleteObjectWithCondition:condition];
    return [block copy];
}

+ (XQDBBlock)dbBlockForDeleteObjectWithCondition:(XQSQLCondition *)condition {
    if (nil == condition) {
        return nil;
    }
    WCModelTableDescribtion *tableDescribtion = [self tableDescribtion];
    NSString *tableName = tableDescribtion[kTableName];
    
    return [^BOOL(FMDatabase *db){
        NSString *whereSql = [condition whereAndLimitSQL];
        NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ %@", tableName, whereSql];
        NSError *error;
        BOOL res = [db executeUpdate:sql withErrorAndBindings:&error];
        if (!res) {
            XQLogWarn(@"db failure when delete '%@', (%@)", NSStringFromClass(self), error);
        }
        return res;
    } copy];
}

#pragma mark - private func
+ (NSString *)createSQL {
    WCModelTableDescribtion *tableDescribtion = [self tableDescribtion];
    WCModelDescribtion *fieldNames = tableDescribtion[kFieldNames];
    WCModelDescribtion *fieldTypes = tableDescribtion[kFieldTypes];
    NSString *tableName = tableDescribtion[kTableName];
#if DEBUG
    //由于 sqllite 字段不允许大小写重名，因此这里检测重名
    NSMutableSet *duplicateFieldCheck = [NSMutableSet set];
    for (NSString *field in fieldNames) {
        XQAssert(NO == [duplicateFieldCheck containsObject:field.lowercaseString]);
        [duplicateFieldCheck addObject:field.lowercaseString];
    }
#endif
    NSMutableString *resultSQL =
    [NSMutableString stringWithFormat:@"CREATE TABLE IF NOT EXISTS `%@` (\n", tableName];
    XQAssert(fieldNames.count == fieldTypes.count);
    [fieldNames enumerateObjectsUsingBlock:^(NSString * _Nonnull fieldName, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *fieldType = [fieldTypes objectAtIndex:idx];
        NSString *formatString = @" `%@` %@ %@,\n";
        if (idx == fieldNames.count - 1) {
            formatString = @" `%@` %@ %@\n";
        }
        [resultSQL appendFormat:formatString, fieldName, fieldType, [self fieldDescribe:fieldName]];
    }];
    [resultSQL appendString:@");"];
    NSDictionary<NSString *, NSNumber *> *startDict = self.startValueForAutoIncrement;
    if (startDict.count > 0) {
        [startDict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull fieldName, NSNumber * _Nonnull startValue, BOOL * _Nonnull stop) {
            if (startValue.longLongValue > 0) {
                NSMutableString *fieldNames = [NSMutableString stringWithString:fieldName];
                NSMutableString *fieldValues = [NSMutableString stringWithFormat:@"%@", startValue];
                {
                    NSArray *notNullFields = [self notNullFields];
                    for (NSString *notNullField in notNullFields) {
                        if (![notNullField isEqualToString:fieldName]) {
                            [fieldNames appendString:@","];
                            [fieldNames appendString:notNullField];
                            [fieldValues appendString:@","];
                            [fieldValues appendString:@(LONG_LONG_MAX - 111).stringValue]; //避免出现冲突
                        }
                    }
                }
                [resultSQL appendFormat:@"\n\
                 insert into %@ (%@) values (%@);\n\
                 delete from %@ where %@ = %@;"
                 , tableName, fieldNames, fieldValues
                 , tableName, fieldName, startValue];
            }
        }];
    }
    return resultSQL;
}

+ (NSNumber *)safeNumberValue:(id)value {
    if (![value isKindOfClass:NSNumber.class]) {
        if ([value respondsToSelector:@selector(longLongValue)]) {
            value = @([value longLongValue]);
        } else if ([value isKindOfClass:NSArray.class]) {
            value = [value firstObject];
            value = [self safeNumberValue:value]; //递归计算
        } else {
            value = nil;
        }
    }
    return value;
}

+ (NSDictionary *)propTypeMapping {
    static NSDictionary *s_mapping;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_mapping = @{@"NSString":@"TEXT",
                      @"NSNumber":@"INTEGER",
                      @"f":@"REAL",
                      @"d":@"REAL",
                      @"B":@"INTEGER",
                      @"s":@"INTEGER",
                      @"i":@"INTEGER",
                      @"q":@"INTEGER",
                      @"I":@"INTEGER",
                      @"Q":@"INTEGER",
                      };
    });
    return s_mapping;
}

/**
 *  获取表信息，包括字段名集合，字段类型集合，表名
 *
 *  return @{@"fieldNames": NSArray, @"fieldTypes":NSArray, @"tableName":NSString}
 */

static WCModelCacheType *g_ModelBaseCache;
+(void)load {
    g_ModelBaseCache = [[NSCache alloc]init];
}

+ (WCModelTableDescribtion *)tableDescribtion {
    Class _class = [self class];
    NSString *tableName = NSStringFromClass(_class);
    NSString *cacheKey = [NSString stringWithFormat:@"%@_Describtion", tableName];
    
    if ([g_ModelBaseCache objectForKey:cacheKey]) {
        return [g_ModelBaseCache objectForKey:cacheKey];
    } else {
        NSMutableArray<NSString *> *fieldNames = [NSMutableArray array];
        NSMutableArray<NSString *> *fieldTypes = [NSMutableArray array];
        
        unsigned int outCount = 0;
        while (NO == [NSStringFromClass(_class) isEqualToString:@"NSObject"]) {
            objc_property_t *props = class_copyPropertyList(_class, &outCount);
            [self getFieldNames:fieldNames fieldTypes:fieldTypes props:props propsCount:outCount];
            
            _class = class_getSuperclass(_class);
        }
        WCModelTableDescribtion *result = @{kFieldNames:fieldNames,
                                            kFieldTypes:fieldTypes,
                                            kTableName:tableName};
        [g_ModelBaseCache setObject:result forKey:cacheKey];
        return result;
    }
}

+ (NSString *)tableName {
    return [self tableDescribtion][kTableName];
}

+ (WCModelDescribtion *)fieldNames {
    return [self tableDescribtion][kFieldNames];
}

+ (WCModelDescribtion *)fieldTypes {
    return [self tableDescribtion][kFieldTypes];
}

+ (void)getFieldTypes:(char (*)[64])fieldTypes attrStr:(const char *)attrStr {
    char *start = strstr(attrStr, "T@\"");
    if (start) {
        strcpy(*fieldTypes, start + strlen("T@\""));
        char *end = strstr(*fieldTypes, "\",");
        *end = '\0';
    } else {
        start = strstr(attrStr, "T");
        if (start) {
            strcpy(*fieldTypes, start + strlen("T"));
            char *end = strstr(*fieldTypes, ",");
            *end = '\0';
        } else {
            (*fieldTypes)[0] = '\0';
        }
    }
}

+ (void)getFieldNames:(NSMutableArray<NSString *> *)fieldNames
           fieldTypes:(NSMutableArray<NSString *> *)fieldTypes
                props:(objc_property_t *)props
           propsCount:(unsigned int)propsCount{
    for (int i = 0; i < propsCount; i++) {
        objc_property_t prop = props[i];
        static const char *const s_blacklist = ",R"; //readonly 属性不存储
        
        const char *attrStr = property_getAttributes(prop);
        char cpyDes[64];
        if (strstr(attrStr, s_blacklist) != NULL) {
            cpyDes[0] = 0;
        } else {
            [self getFieldTypes:&cpyDes attrStr:attrStr];
        }
        if (strlen(cpyDes) > 0) {
            NSString *type = [NSString stringWithUTF8String:cpyDes];
#if DEBUG
            if (type.length == 1 && ![type isEqualToString:@"@"]) {
                XQLogWarn(@"field type:%@", type);
            }
#endif
            NSString *propType = XQRequiredCast([self propTypeMapping][type], NSString);
            if (propType) {
                [fieldTypes addObject:propType];
                NSString *fieldName = [NSString stringWithUTF8String:property_getName(prop)];
                [fieldNames addObject:fieldName];
            }
        }
    }
}

@end
