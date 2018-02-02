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
//  ModelBase.m
//  Xunquan
//
//  Created by Xiongxunquan on 9/12/15.
//  Copyright © 2015 xunquan inc.. All rights reserved.
//

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

#import "NSObject+XQ_DAO.h"
#import "XQSQLCondition.h"
#import "XQFMDBManager.h"
#import "XQ_DAOUtils.h"

#import <objc/runtime.h>
#import <FMDB/FMDB.h>

#define RETURN_IF_CONFIGURATION_EXIST(_SEL) \
if (self.xq_modelConfiguration._SEL) { \
    return self.xq_modelConfiguration._SEL; \
}

#define CALL_CHILD_IF_EXIST(_SEL) \
if ([self respondsToSelector:@selector(child_##_SEL)]) { \
    return [(id<XQDBModel>)self child_##_SEL]; \
}

#define CALL_CHILD_IF_EXIST_PRAMA1(_SEL, _PRAMA1) \
if ([self respondsToSelector:@selector(child_##_SEL:)]) { \
    return [(id<XQDBModel>)self child_##_SEL:_PRAMA1]; \
}

#define CALL_CHILD_IF_EXIST_PRAMA1_PRAMA2(_SEL1, _SEL2, _PRAMA1, _PRAMA2) \
if ([self respondsToSelector:@selector(child_##_SEL1:_SEL2:)]) { \
    return [(id<XQDBModel>)self child_##_SEL1:_PRAMA1 _SEL2:_PRAMA2]; \
}

/**
 *  model表信息，包括字段名集合，字段类型集合，表名
 *  @{@"fieldNames": NSArray, @"fieldTypes":NSArray, @"tableName":NSString}
 */
typedef NSArray<NSString *> WCModelDescribtion;
typedef NSDictionary<NSString *, id> WCModelTableDescribtion;
typedef NSCache<NSString *, WCModelTableDescribtion *> WCModelCacheType;

NSString *const kFieldNames = @"xq_fieldNames";
NSString *const kFieldTypes = @"xq_fieldTypes";
NSString *const kTableName = @"xq_tableName";

static char xq_model_configuration_key;

@implementation XQDBModelConfiguration

+ (instancetype)configuration {
    XQDBModelConfiguration *configuration = [[self alloc] init];
    [configuration addUniquesNotNull:@[XQDAO_SEL_TO_STRING(UUID)]];
    [configuration addUniquesNotNull:@[XQDAO_SEL_TO_STRING(localID)]];
    return configuration;
}

- (instancetype)init {
    if (self = [super init]) {
        _uniquesAbleNull = [NSMutableArray array];
        _uniquesNotNull = [NSMutableArray array];
        _notNullFields = [NSMutableArray array];
        _orderFieldInfo = [NSMutableArray array];
        _startValueForAutoIncrement = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)addUniquesNotNull:(NSArray *)objects {
    if (objects.count == 0) {
        return;
    }
    [_uniquesNotNull addObjectsFromArray:objects];
    [self addUniquesAbleNull:objects];
    [self addNotNullFields:objects];
}

- (void)addUniquesAbleNull:(NSArray *)objects {
    if (objects.count == 0) {
        return;
    }
    [_uniquesAbleNull addObjectsFromArray:objects];
}

- (void)addNotNullFields:(NSArray *)objects {
    if (objects.count == 0) {
        return;
    }
    [_notNullFields addObjectsFromArray:objects];
}

- (void)addOrderFieldInfo:(NSArray *)objects {
    if (objects.count == 0) {
        return;
    }
    [_orderFieldInfo addObjectsFromArray:objects];
}

- (void)addStartValueForAutoIncrement:(NSDictionary *)objects {
    [_startValueForAutoIncrement addEntriesFromDictionary:objects];
}

@end

@implementation NSObject (XQ_DAO)

+ (void)load {
    [self xq_dao_swizzleInstanceMethod:NSSelectorFromString(@"setLocalID:")
                                  with:@selector(swizzle_setLocalID:)];
}

- (void)swizzle_setLocalID:(NSNumber *)localID {
    localID = [self.class xq_safeNumberValue:localID];
    [self swizzle_setLocalID:localID];
}

#pragma mark - configuration
+ (XQDBModelConfiguration *)xq_modelConfiguration {
    return objc_getAssociatedObject(self, &xq_model_configuration_key);
}

+ (void)setXq_modelConfiguration:(XQDBModelConfiguration *)configuration {
    objc_setAssociatedObject(self, &xq_model_configuration_key, configuration, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - override func

+ (NSArray<NSString *> *)xq_uniquesAbleNull {
    RETURN_IF_CONFIGURATION_EXIST(uniquesAbleNull)
    CALL_CHILD_IF_EXIST(uniquesAbleNull)
    return [self xq_uniquesNotNull];
}

+ (NSArray<NSString *> *)xq_uniquesNotNull {
    RETURN_IF_CONFIGURATION_EXIST(uniquesNotNull)
    CALL_CHILD_IF_EXIST(uniquesNotNull)
    return @[XQDAO_SEL_TO_STRING(localID),
             XQDAO_SEL_TO_STRING(UUID)];
}

+ (NSArray<NSString *> *)xq_notNullFields {
    RETURN_IF_CONFIGURATION_EXIST(notNullFields)
    CALL_CHILD_IF_EXIST(notNullFields)
    return [self xq_uniquesNotNull];
}

+ (NSArray<NSDictionary<NSString *, NSNumber *> *> *)xq_orderFieldInfo {
    RETURN_IF_CONFIGURATION_EXIST(orderFieldInfo)
    CALL_CHILD_IF_EXIST(orderFieldInfo)
    return @[@{XQDAO_SEL_TO_STRING(localID):@(OrderTypeDESC)}];
}

+ (NSString *)xq_primaryKey {
    RETURN_IF_CONFIGURATION_EXIST(primaryKey)
    CALL_CHILD_IF_EXIST(primaryKey)
    return XQDAO_SEL_TO_STRING(localID);
}

+ (BOOL)xq_isPrimaryKey:(NSString *)field {
    CALL_CHILD_IF_EXIST_PRAMA1(isPrimaryKey, field)
    if (!field) {
        return NO;
    }
    if ([field isEqualToString:[self xq_primaryKey]]) {
        return YES;
    }
    return NO;
}

+ (BOOL)xq_isUnchangeableField:(NSString *)field {
    CALL_CHILD_IF_EXIST_PRAMA1(isUnchangeableField, field)
    if (!field) {
        return NO;
    }
    if ([[self xq_uniquesAbleNull] containsObject:field]) {
        return YES;
    }
    return NO;
}

+ (BOOL)xq_isUnableNullField:(NSString *)field {
    CALL_CHILD_IF_EXIST_PRAMA1(isUnableNullField, field)
    if (!field) {
        return NO;
    }
    if ([[self xq_notNullFields] containsObject:field]) {
        return YES;
    }
    return NO;
}

+ (NSDictionary *)xq_fieldDescribeDict {
    NSMutableSet *fieldsSet = [NSMutableSet set];
    NSMutableDictionary *fieldDescribes = [NSMutableDictionary dictionary];
    fieldDescribes[XQDAO_SEL_TO_STRING(deleted)] = @"DEFAULT 0";
    fieldDescribes[self.xq_primaryKey] = @"PRIMARY KEY AUTOINCREMENT NOT NULL";
    [fieldsSet addObject:self.xq_primaryKey];
    NSArray<NSString *> *fields  = [self xq_uniquesNotNull];
    for (NSString *field in fields) {
        if ([fieldsSet containsObject:field]) {
            continue;
        }
        [fieldsSet addObject:field];
        fieldDescribes[field] = @"NOT NULL UNIQUE";
    }
    NSMutableSet<NSString *> *notNullfields = [NSMutableSet set];
    [notNullfields addObjectsFromArray:[self xq_notNullFields]];
    for (NSString *field in notNullfields) {
        if ([fieldsSet containsObject:field]) {
            continue;
        }
        [fieldsSet addObject:field];
        fieldDescribes[field] = @"NOT NULL";
    }
    return fieldDescribes;
}

+ (NSString *)xq_fieldDescribe:(NSString *)fieldName {
    CALL_CHILD_IF_EXIST_PRAMA1(fieldDescribe, fieldName)
    NSDictionary *mapping = [self xq_fieldDescribeDict];
    NSString *result = mapping[fieldName];
    if ([result length] > 0) {
        return result;
    } else {
        return @"";
    }
}

+ (NSDictionary<NSString *, NSNumber *> *)xq_startValueForAutoIncrement {
    RETURN_IF_CONFIGURATION_EXIST(startValueForAutoIncrement)
    CALL_CHILD_IF_EXIST(startValueForAutoIncrement)
    return @{XQDAO_SEL_TO_STRING(localID):@100};
}

- (XQSQLCondition *)xq_defaultExistCondition {
    CALL_CHILD_IF_EXIST(defaultExistCondition)
    return [self xq_defaultExistConditionWithDbModel:nil];
}

- (XQSQLCondition *)xq_defaultExistConditionWithDbModel:(__kindof NSObject *)dbModel {
    XQSQLCondition *condition = [XQSQLCondition new];
    NSArray<NSString *> *fields = [self.class xq_uniquesAbleNull];
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
- (BOOL)xq_willInsert {
    NSArray *fields = [self.class xq_notNullFields];
    for (NSString *field in fields) {
        if ([field isEqualToString:[self.class xq_primaryKey]]) {
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
            XQDAOLog(@"[xq_dao]!!![%@](%@)field error so can't insert this object", [self.class xq_tableName], field);
            return NO;
        }
    }
    return YES;
}

/**
 * 如果是需要更新的字段，或数据库中不存在，则需要更新
 * 返回 YES 则更新当前值，否则返回 NO
 */
- (BOOL)xq_willUpdatedbModel:(NSObject *)dbModel withFieldName:(NSString *)fieldName {
    CALL_CHILD_IF_EXIST_PRAMA1_PRAMA2(willUpdatedbModel, withFieldName, dbModel, fieldName)

    id value = [self valueForKey:fieldName];
    if (!value) {
        return NO;
    }
    id dbValue = [dbModel valueForKey:fieldName];
    if (!dbValue) {
        return YES;
    }
    if ([self.class xq_isUnchangeableField:fieldName]) {
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
                XQDAOLog(@"[xq_dao]>%@< >%@<", XQDAO_OBJ_CLASS_NAME([self valueForKey:fieldName]), XQDAO_OBJ_CLASS_NAME([dbModel valueForKey:fieldName]));
                XQDAOLog(@"[xq_dao]这里有一个隐患，需要注意 NSNumber 类型和 NSString 类型之间的兼容性，这应该在你定义 EntityModel 时需要注意。可以参见 serverID 和 localID 字段重写的 setter.");
                return NO;
            }
        }
        return YES;
    }
    return YES;
}

#pragma mark - public func
+ (NSObject *)xq_existObject:(NSObject *)modelObj {
    if (!modelObj) {
        return nil;
    }
    XQSQLCondition *condition = [modelObj xq_defaultExistCondition];
    if ([condition.condition count] == 0) {
        return nil;
    }
    NSObject *result = [self xq_queryModelsWithCondition:condition].firstObject;
    return result;
}

+ (void)xq_copyFromObject:(NSObject *)fromObject toObject:(NSObject *)toObject {
    WCModelTableDescribtion *tableDescribtion = [self xq_tableDescribtion];
    WCModelDescribtion *fieldNames = tableDescribtion[kFieldNames];
    [fieldNames enumerateObjectsUsingBlock:^(NSString * _Nonnull fieldName, NSUInteger idx, BOOL * _Nonnull stop) {
        id value = [fromObject valueForKey:fieldName];
        if (value) {
            [toObject setValue:value forKey:fieldName];
        }
    }];
}

+ (void)xq_saveObjectsInTransaction:(NSArray<__kindof NSObject *> *)objects updateIfExist:(BOOL)updateIfExist {
    if (objects.count == 0) {
        return;
    }
    NSMutableArray<NSObject *> *deleteModels = [NSMutableArray array];
    NSMutableArray<NSObject *> *saveModels = [NSMutableArray array];
    NSMutableDictionary *rejectDuplicateFieldDict = [NSMutableDictionary new]; //判重 field -> valuesSet
    NSArray *fields = [self xq_uniquesAbleNull];
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
    [self xq_deleteObjectsInTransaction:deleteModels];
    [self _xq_saveObjectsInTransaction:saveModels updateIfExist:updateIfExist];
    if (deleteModels.count > 0) {
//        [self xqNotifyAction:@"DeleteModels" withObject:deleteModels];
    }
    if (saveModels.count > 0) {
//        [self xqNotifyAction:@"AddModels" withObject:saveModels];
    }
}

+ (void)xq_saveObjectsInTransaction:(NSArray<__kindof NSObject *> *)objects {
    [self xq_saveObjectsInTransaction:objects updateIfExist:YES];
}

+ (void)_xq_saveObjectsInTransaction:(NSArray<__kindof NSObject *> *)objects updateIfExist:(BOOL)updateIfExist {
    if (objects.count == 0) {
        return;
    }
    NSArray<XQDBBlock> *blocks = xq_dao_compact(objects, ^id(id obj) {
        XQDBBlock block = [self xq_dbBlockForAddObject:^(id model) {
            [self xq_copyFromObject:obj toObject:model];
        } updateIfExist:updateIfExist];
        return block;
    });
    [[XQFMDBManager defaultManager] executeBlocksInTransaction:blocks];
}

+ (void)xq_saveObjectWithBlock:(InitModelBlock)initModelBlock updateIfExist:(BOOL)updateIfExist optType:(DBOptType *)optType {
    
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
                break;
            case DBOptTypeDelete:
                break;
            case DBOptTypeUpdate:
            case DBOptTypeNone:
                break;
        }
    }
}

- (void)xq_save {
    [self.class xq_saveObject:self];
}

+ (void)xq_saveObject:(__kindof NSObject *)object {
    [self xq_saveObject:object updateIfExist:YES];
}

+ (void)xq_saveObject:(__kindof NSObject *)object updateIfExist:(BOOL)updateIfExist {
    [self xq_saveObjectWithBlock:^(id model) {
        [self xq_copyFromObject:object toObject:model];
    } updateIfExist:updateIfExist];
}

+ (void)xq_saveObjectWithBlock:(InitModelBlock)initModelBlock updateIfExist:(BOOL)updateIfExist {
    DBOptType optType = DBOptTypeNone;
    [self xq_saveObjectWithBlock:initModelBlock updateIfExist:updateIfExist optType:&optType];
}

+ (void)_saveObjectWithBlock:(InitModelBlock)initModelBlock updateIfExist:(BOOL)updateIfExist optType:(DBOptType *)optType {
    XQDBBlock block = [self xq_dbBlockForAddObject:initModelBlock updateIfExist:updateIfExist optType:optType];
    if (block) {
        [[XQFMDBManager defaultManager] executeBlock:block];
    }
}

- (BOOL)xq_deleteFromDatabase {
    BOOL res = [self.class xq_deleteObject:self];
    return res;
}

+ (BOOL)xq_deleteObject:(__kindof NSObject *)object {
    XQDBBlock block = [self xq_dbBlockForDeleteObject:object];
    [[XQFMDBManager defaultManager] executeBlock:block];
    return !!block;
}

+ (BOOL)xq_deleteObjectsInTransaction:(NSArray<__kindof NSObject *> *)objects {
    NSArray<XQDBBlock> *blocks = xq_dao_compact(objects, ^id(id obj) {
        return [self xq_dbBlockForDeleteObject:obj];
    });
    [[XQFMDBManager defaultManager] executeBlocksInTransaction:blocks];
    if (blocks.count == 0 && objects > 0) {
        return NO;
    }
    return YES;
}

+ (BOOL)xq_deleteObjectWithCondition:(XQSQLCondition *)condition {
    XQDBBlock block = [self xq_dbBlockForDeleteObjectWithCondition:condition];
    [[XQFMDBManager defaultManager] executeBlock:block];
    return !!block;
}

+ (BOOL)xq_deleteWhere:(NSString *)field equal:(id)value {
    XQSQLCondition *condition = [XQSQLCondition conditionWhere:field equal:value];
    return [self xq_deleteObjectWithCondition:condition];
}

+ (BOOL)xq_deleteWhereLocalIDEqual:(NSNumber *)localID {
    return [self xq_deleteWhere:XQDAO_SEL_TO_STRING(localID) equal:localID];
}

+ (BOOL)xq_clean {
    __block BOOL res = NO;
    __block NSError *error;
    
    XQDBBlock block = ^BOOL(FMDatabase *db){
        WCModelTableDescribtion *tableDescribtion = [self xq_tableDescribtion];
        NSString *tableName = tableDescribtion[kTableName];
        NSString *sql = [NSString stringWithFormat:@"DROP TABLE IF EXISTS %@", tableName];
        res = [db executeUpdate:sql withErrorAndBindings:&error];
        if (res) {
            res = [db executeStatements:[self xq_createSQL]];
            XQDAOLog(@"[xq_dao]Model '%@' clean success", NSStringFromClass(self));
        }
        return res;
    };
    
    [[XQFMDBManager defaultManager] executeBlock:block];
    
    if (!res)
        XQDAOLog(@"[xq_dao]db open failure when delete '%@', (%@)", NSStringFromClass(self), error);
    return res;
}

+ (NSArray<__kindof NSObject *> *)xq_queryModels {
    return [self xq_queryModelsAtIndex:0 limitCount:0];
}

+ (NSArray<__kindof NSObject *> *)xq_queryModelsWithCondition:(XQSQLCondition *)condition {
    NSMutableArray *result = [NSMutableArray array];
    [self xq_queryModelsWithBlock:^(NSObject *model) {
        [result addObject:model];
    } condition:condition];
    return result;
}

+ (NSArray<__kindof NSObject *> *)xq_queryModelsAtIndex:(NSUInteger)index limitCount:(NSUInteger)limitCount {
    return
    [self xq_queryMakeCondition:^(XQSQLCondition *condition) {
        [condition setLimitFrom:index limitCount:limitCount];
    }];
}

+ (instancetype)xq_queryWhereUUIDEqual:(NSString *)UUID {
    return [self xq_queryWhere:XQDAO_SEL_TO_STRING(UUID) equal:UUID];
}

+ (instancetype)xq_queryWhereLocalIDEqual:(NSNumber *)localID {
    return [self xq_queryWhere:XQDAO_SEL_TO_STRING(localID) equal:localID];
}

+ (instancetype)xq_queryWhere:(NSString *)field equal:(id)value {
    if (!value) {
        return nil;
    }
    XQSQLCondition *condition = [XQSQLCondition conditionWhere:field equal:value];
    __kindof NSObject *result =
    [[self xq_queryModelsWithCondition:condition] firstObject];
    return result;
}

+ (NSArray<__kindof NSObject *> *)xq_queryMakeCondition:(void(^)(XQSQLCondition *condition))makeCondition {
    XQSQLCondition *condition = [XQSQLCondition condition];
    if (makeCondition) {
        makeCondition(condition);
    }
    return [self xq_queryModelsWithCondition:condition];
}

+ (NSArray<__kindof NSObject *> *)xq_queryModelsWhere:(NSString *)field equal:(id)value {
    XQSQLCondition *condition = [XQSQLCondition conditionWhere:field equal:value];
    return [self xq_queryModelsWithCondition:condition];
}

+ (void)xq_queryModelsWithBlock:(QueryModelBlock)queryModelBlock condition:(XQSQLCondition *)condition {
    WCModelTableDescribtion *tableDescribtion = [self xq_tableDescribtion];
    WCModelDescribtion *fieldNames = tableDescribtion[kFieldNames];
    NSString *tableName = tableDescribtion[kTableName];
    
    __weak typeof(self) _weak_self = self;
    XQDBBlock block = ^BOOL(FMDatabase *db){
        __strong typeof(_weak_self) self = _weak_self;
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
            [[self xq_orderFieldInfo] enumerateObjectsUsingBlock:
             ^(NSDictionary<NSString *,NSNumber *> * _Nonnull obj,
               NSUInteger idx, BOOL * _Nonnull stop) {
                 XQDAOAssert(obj.count == 1);
                [condition addOrderField:obj.allKeys.firstObject
                               orderType:obj.allValues.firstObject.integerValue];
            }];
        }
        
        NSMutableArray *argValues = [NSMutableArray array];
        NSString *conditionSQL = [condition conditionArgValues:argValues];
        if ([conditionSQL length] > 0) {
            [sql appendString:conditionSQL];
        }
        FMResultSet * rs = [db executeQuery:sql withArgumentsInArray:argValues];
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

+ (void)xq_setProperty:(NSString *)prop value:(id)value {
    [self xq_setProperty:prop value:value condition:nil];
}

#pragma mark - advanced func

+ (XQDBBlock)xq_dbBlockForInsertObject:(NSObject *)model {
    WCModelTableDescribtion *tableDescribtion = [self xq_tableDescribtion];
    WCModelDescribtion *fieldNames = tableDescribtion[kFieldNames];
    NSString *tableName = tableDescribtion[kTableName];
    
    __weak typeof(self) _weak_self = self;
    return [^BOOL(FMDatabase *db) {
        __strong typeof(_weak_self) self = _weak_self;
        id uuid = [model valueForKey:XQDAO_SEL_TO_STRING(UUID)];
        if (!uuid) {
            //强制有 UUID
            [model setValue:[self xq_rawUUID] forKey:XQDAO_SEL_TO_STRING(UUID)];
        }
        if (NO == [model xq_willInsert]) {
            return YES;
        }
        NSMutableString *sql = [NSMutableString stringWithString:@"insert into "];
        [sql appendString:tableName];
        NSMutableArray *columnArray = [NSMutableArray array];
        NSMutableArray *valuesArray = [NSMutableArray array];
        NSMutableArray *sympleArray = [NSMutableArray array];
        [fieldNames enumerateObjectsUsingBlock:
         ^(NSString *_Nonnull fieldName, NSUInteger idx, BOOL * _Nonnull stop) {
             if (![self xq_isPrimaryKey:fieldName]) {
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
        XQDAOLog(@"[xq_dao]insert failure:[%@](%@)", db.lastError, sql);
#if !容错
        columnArray = [NSMutableArray array];
        valuesArray = [NSMutableArray array];
        XQSQLCondition *condition = [model xq_defaultExistCondition];
        NSString *updateSql = [self xq_updateSqlForModel:model dbModel:nil fieldNames:fieldNames columnArray:columnArray valuesArray:valuesArray condition:condition];
        if (updateSql) {
            res = [db executeUpdate:updateSql withArgumentsInArray:valuesArray];
            if (!res) {
                XQDAOLog(@"[xq_dao]update 也 failure:[%@](%@)", db.lastError, updateSql);
                XQDAOAssert(false);
            }
        } else {
            XQDAOLog(@"[xq_dao]!!!update object sql is nil.");
            res = YES;
        }
#endif
        return res;
    } copy];
}

+ (void)xq_setProperty:(NSString *)prop value:(id)value condition:(XQSQLCondition *)condition {
    XQDBBlock block = [self xq_dbBlockForUpdateProperty:prop value:value condition:condition];
    [[XQFMDBManager defaultManager] executeBlock:block];
}

+ (NSUInteger)xq_countOfCol {
    return [self xq_countOfCondition:nil];
}

#if 0
+ (BOOL)xq_tableExisted {
    __block BOOL exist = NO;
    [[XQFMDBManager defaultManager] executeBlock:^BOOL(FMDatabase *db) {
        NSString *sql =
        [NSString stringWithFormat:@"\
         SELECT count(*) FROM `sqlite_master` \
         WHERE `type` = 'table' AND lower(name) = '%@'",
         [self xq_tableName]];
        
        FMResultSet *rs = [db executeQuery:sql];
        while ([rs next]) {
            NSNumber *value = [rs objectForColumnIndex:0];
            if (value.longLongValue > 0) {
                exist = YES;
            }
            [rs close];
        }
        return YES;
    }];
    return exist;
}
#endif

+ (NSUInteger)xq_countOfWhereProp:(NSString *)prop equal:(id)value {
    XQSQLCondition *condition = [XQSQLCondition new];
    [condition addWhereField:prop compare:SQLCompareEqual value:value logicCode:LogicCodeNone];
    return [self xq_countOfCondition:condition];
}

+ (NSUInteger)xq_countOfWhereProp:(NSString *)prop notEqual:(id)value {
    XQSQLCondition *condition = [XQSQLCondition new];
    [condition addWhereField:prop compare:SQLCompareNotEqual value:value logicCode:LogicCodeNone];
    return [self xq_countOfCondition:condition];
}

+ (NSUInteger)xq_countOfMakeCondition:(void(^)(XQSQLCondition *condition))makeCondition {
    XQSQLCondition *condition;
    if (makeCondition) {
        condition = [XQSQLCondition condition];
        makeCondition(condition);
    }
    return [self xq_countOfCondition:condition];
}

+ (NSUInteger)xq_countOfCondition:(XQSQLCondition *)condition {
    NSString *tableName = NSStringFromClass(self.class);
    __block NSUInteger count = 0;
    XQDBBlock block = ^BOOL(FMDatabase *db){
        NSMutableString *sql = [NSMutableString string];
        [sql appendFormat:@"select count(*) from %@ ", tableName];
        NSMutableArray *argValues = [NSMutableArray array];
        NSString *whereSql = [condition conditionArgValues:argValues];
        if (whereSql) {
            [sql appendString:whereSql];
        }
        FMResultSet * rs = [db executeQuery:sql withArgumentsInArray:argValues];
        BOOL res = [rs next];
        if (res) {
            NSNumber *value = [rs objectForColumnIndex:0];
            count = value.unsignedIntegerValue;
            [rs close];
        } else {
            XQDAOLog(@"[xq_dao]!!! 查询表的 column count 错误!");
            return NO;
        }
        return YES;
    };
    [[XQFMDBManager defaultManager] executeBlock:block];
    return count;
}

+ (XQDBBlock)xq_dbBlockForUpdateProperty:(NSString *)prop value:(id)value condition:(XQSQLCondition *)condition {
    NSObject *model = [self new];
    [model setValue:value forKey:prop];
    return [self xq_dbBlockForUpdateObject:model dbModel:nil condition:condition];
}

+ (NSString *)xq_updateSqlForModel:(NSObject *)model
                           dbModel:(NSObject *)dbModel
                        fieldNames:(WCModelDescribtion *)fieldNames
                       columnArray:(NSMutableArray *)columnArray
                       valuesArray:(NSMutableArray *)valuesArray
                         condition:(XQSQLCondition *)condition {
    NSString *tableName = NSStringFromClass(self.class);
    [fieldNames enumerateObjectsUsingBlock:
     ^(NSString *_Nonnull fieldName, NSUInteger idx, BOOL * _Nonnull stop) {
         if (![self xq_isPrimaryKey:fieldName]) {
             if (dbModel) {
                 if ([model xq_willUpdatedbModel:dbModel withFieldName:fieldName]) {
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
    if (valuesArray.count > 0) {
        NSString *columnSql = [[columnArray valueForKey:@"description"] componentsJoinedByString:@","];
        NSMutableArray *argValues = [NSMutableArray array];
        NSString *whereSql = [condition conditionArgValues:argValues];
        NSMutableString *sql = [NSMutableString string];
        [sql appendFormat:@"UPDATE %@ SET %@ ", tableName, columnSql];
        if (whereSql) {
            [sql appendString:whereSql];
            [valuesArray addObjectsFromArray:argValues];
        }
        return sql;
    }
    return nil;
}

+ (XQDBBlock)xq_dbBlockForUpdateObject:(NSObject *)model dbModel:(NSObject *)dbModel condition:(XQSQLCondition *)condition {
    WCModelTableDescribtion *tableDescribtion = [self xq_tableDescribtion];
    WCModelDescribtion *fieldNames = tableDescribtion[kFieldNames];
    
    __weak typeof(self) _weak_self = self;
    return [^BOOL(FMDatabase *db){
        __strong typeof(_weak_self) self = _weak_self;
        NSMutableArray *columnArray = [NSMutableArray array];
        NSMutableArray *valuesArray = [NSMutableArray array];
        
        NSString *sql =
        [self xq_updateSqlForModel:model dbModel:dbModel fieldNames:fieldNames columnArray:columnArray valuesArray:valuesArray condition:condition];
        if (sql) {
            BOOL res = [db executeUpdate:sql withArgumentsInArray:valuesArray];
            if (!res) {
                XQDAOLog(@"[xq_dao]update object error: %@(%@)", db.lastError, sql);
                XQDAOAssert(false);
            }
            return res;
        }
        return YES;
    } copy];
}

+ (XQDBBlock)xq_dbBlockForAddObject:(InitModelBlock)initModelBlock updateIfExist:(BOOL)updateIfExist {
    DBOptType optType = DBOptTypeNone;
    return [self xq_dbBlockForAddObject:initModelBlock updateIfExist:updateIfExist optType:&optType];
}

+ (XQDBBlock)xq_dbBlockForAddObject:(InitModelBlock)initModelBlock updateIfExist:(BOOL)updateIfExist optType:(DBOptType *)optType {
    XQDBBlock block;
    NSObject *model = [[self alloc] init];
    if (initModelBlock) {
        initModelBlock(model);
    }
    if (optType) {
        *optType = DBOptTypeUpdate;
    }
    NSObject *dbExistModel = [self xq_existObject:model];
    if (dbExistModel) {
        if (!updateIfExist) {
            return nil;
        }
        //delete opt
        if (optType) {
            static SEL s_deletedSEL;
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                s_deletedSEL = NSSelectorFromString(XQDAO_SEL_TO_STRING(deleted));
            });
            if ([model respondsToSelector:s_deletedSEL]) {
                NSNumber *deleted = [model valueForKey:XQDAO_SEL_TO_STRING(deleted)];
                if (deleted.boolValue) {
                    *optType = DBOptTypeDelete;
                    block = [self xq_dbBlockForDeleteObject:model];
                }
            }
            if (!block) {
                *optType = DBOptTypeUpdate;
            }
        }
        if (!block) {
            XQSQLCondition *condition = [model xq_defaultExistConditionWithDbModel:dbExistModel];
            block = [self xq_dbBlockForUpdateObject:model
                                         dbModel:dbExistModel
                                       condition:condition];
        }
    } else {
        if (optType) {
            *optType = DBOptTypeAdd;
        }
        block = [self xq_dbBlockForInsertObject:model];
    }
    return [block copy];
}

+ (XQDBBlock)xq_dbBlockForDeleteObject:(__kindof NSObject *)object {
    if (![self xq_existObject:object]) { //不存在
        return nil;
    }
    XQSQLCondition *condition = [object xq_defaultExistCondition];
    XQDBBlock block = [self xq_dbBlockForDeleteObjectWithCondition:condition];
    return [block copy];
}

+ (XQDBBlock)xq_dbBlockForDeleteObjectWithCondition:(XQSQLCondition *)condition {
    if (nil == condition) {
        return nil;
    }
    WCModelTableDescribtion *tableDescribtion = [self xq_tableDescribtion];
    NSString *tableName = tableDescribtion[kTableName];
    
    return [^BOOL(FMDatabase *db){
        NSString *whereSql = [condition whereAndLimitSQL];
        NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ %@", tableName, whereSql];
        NSError *error;
        BOOL res = [db executeUpdate:sql withErrorAndBindings:&error];
        if (!res) {
            XQDAOLog(@"[xq_dao]!!!db failure when delete '%@', (%@)", NSStringFromClass(self), error);
        }
        return res;
    } copy];
}

#pragma mark - private func
+ (NSString *)xq_createSQL {
    RETURN_IF_CONFIGURATION_EXIST(createSQL)
    CALL_CHILD_IF_EXIST(createSQL)
    
    WCModelTableDescribtion *tableDescribtion = [self xq_tableDescribtion];
    WCModelDescribtion *fieldNames = tableDescribtion[kFieldNames];
    WCModelDescribtion *fieldTypes = tableDescribtion[kFieldTypes];
    NSString *tableName = tableDescribtion[kTableName];
#if DEBUG
    //由于 sqllite 字段不允许大小写重名，因此这里检测重名
    NSMutableSet *duplicateFieldCheck = [NSMutableSet set];
    for (NSString *field in fieldNames) {
        XQDAOAssert(NO == [duplicateFieldCheck containsObject:field.lowercaseString]);
        [duplicateFieldCheck addObject:field.lowercaseString];
    }
#endif
    NSMutableString *resultSQL =
    [NSMutableString stringWithFormat:@"CREATE TABLE IF NOT EXISTS `%@` (\n", tableName];
    XQDAOAssert(fieldNames.count == fieldTypes.count);
    [fieldNames enumerateObjectsUsingBlock:^(NSString * _Nonnull fieldName, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *fieldType = [fieldTypes objectAtIndex:idx];
        NSString *formatString = @" `%@` %@ %@,\n";
        if (idx == fieldNames.count - 1) {
            formatString = @" `%@` %@ %@\n";
        }
        [resultSQL appendFormat:formatString, fieldName, fieldType, [self xq_fieldDescribe:fieldName]];
    }];
    [resultSQL appendString:@");"];
    NSDictionary<NSString *, NSNumber *> *startDict = self.xq_startValueForAutoIncrement;
    if (startDict.count > 0) {
        [startDict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull fieldName, NSNumber * _Nonnull startValue, BOOL * _Nonnull stop) {
            if (startValue.longLongValue > 0) {
                NSMutableString *fieldNames = [NSMutableString stringWithString:fieldName];
                NSMutableString *fieldValues = [NSMutableString stringWithFormat:@"%@", startValue];
                {
                    NSArray *xq_notNullFields = [self xq_notNullFields];
                    for (NSString *notNullField in xq_notNullFields) {
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

+ (NSNumber *)xq_safeNumberValue:(id)value {
    if (![value isKindOfClass:NSNumber.class]) {
        if ([value respondsToSelector:@selector(longLongValue)]) {
            value = @([value longLongValue]);
        } else if ([value isKindOfClass:NSArray.class]) {
            value = [value firstObject];
            value = [self xq_safeNumberValue:value]; //递归计算
        } else {
            value = nil;
        }
    }
    return value;
}

+ (NSString*)xq_rawUUID {
    NSString *uuid = nil;
    CFUUIDRef puuid = CFUUIDCreate(nil);
    CFStringRef uuidString = CFUUIDCreateString(nil, puuid);
    uuid = (NSString *)CFBridgingRelease(CFStringCreateCopy(NULL, uuidString));
    XQDAOCFRelease(puuid);
    XQDAOCFRelease(uuidString);
    return uuid;
}

+ (NSArray *)xq_idsGroupByIds:(NSArray *)ids limitCount:(NSInteger)limitCount {
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

#pragma mark - meta data
/**
 *  获取表信息，包括字段名集合，字段类型集合，表名
 *
 *  return @{@"fieldNames": NSArray, @"fieldTypes":NSArray, @"tableName":NSString}
 */

+ (NSCache *)xq_modelMetaDataCache {
    static NSCache *s_modelMetaDataCache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_modelMetaDataCache = [[NSCache alloc] init];
    });
    return s_modelMetaDataCache;
}

+ (WCModelTableDescribtion *)xq_tableDescribtion {
    Class _class = [self class];
    NSString *tableName = NSStringFromClass(_class);
    NSString *cacheKey = [NSString stringWithFormat:@"%@_Describtion", tableName];
    
    if ([self.xq_modelMetaDataCache objectForKey:cacheKey]) {
        return [self.xq_modelMetaDataCache objectForKey:cacheKey];
    } else {
        NSMutableArray<NSString *> *fieldNames = [NSMutableArray array];
        NSMutableArray<NSString *> *fieldTypes = [NSMutableArray array];
        
        unsigned int outCount = 0;
        while (NO == [NSStringFromClass(_class) isEqualToString:@"NSObject"]) {
            objc_property_t *props = class_copyPropertyList(_class, &outCount);
            [self xq_getFieldNames:fieldNames fieldTypes:fieldTypes props:props propsCount:outCount];
            
            _class = class_getSuperclass(_class);
        }
        WCModelTableDescribtion *result = @{kFieldNames:fieldNames,
                                            kFieldTypes:fieldTypes,
                                            kTableName:tableName};
        [self.xq_modelMetaDataCache setObject:result forKey:cacheKey];
        return result;
    }
}

+ (NSString *)xq_tableName {
    return [self xq_tableDescribtion][kTableName];
}

+ (WCModelDescribtion *)xq_fieldNames {
    return [self xq_tableDescribtion][kFieldNames];
}

+ (WCModelDescribtion *)xq_fieldTypes {
    return [self xq_tableDescribtion][kFieldTypes];
}

+ (NSDictionary *)xq_propTypeMapping {
    //https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html#//apple_ref/doc/uid/TP40008048-CH101
    
    static NSDictionary *s_mapping;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_mapping = @{@"NSString":@"TEXT",
                      @"NSNumber":@"INTEGER",
                      @"c":@"INTEGER",
                      @"d":@"REAL",
                      @"i":@"INTEGER",
                      @"f":@"REAL",
                      @"l":@"INTEGER",
                      @"s":@"INTEGER",
                      @"I":@"INTEGER",
                      @"B":@"INTEGER",
                      @"q":@"INTEGER",
                      @"Q":@"INTEGER",
                      };
    });
    return s_mapping;
}

+ (void)xq_getFieldTypes:(char (*)[64])fieldTypes attrStr:(const char *)attrStr {
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

+ (void)xq_getFieldNames:(NSMutableArray<NSString *> *)fieldNames
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
            [self xq_getFieldTypes:&cpyDes attrStr:attrStr];
        }
        if (strlen(cpyDes) > 0) {
            NSString *type = [NSString stringWithUTF8String:cpyDes];
#if DEBUG
            if (type.length == 1 && ![type isEqualToString:@"@"]) {
                XQDAOLog(@"[xq_dao]field type:%@", type);
            }
#endif
            NSString *propType = XQDAORequiredCast([self xq_propTypeMapping][type], NSString);
            if (propType) {
                [fieldTypes addObject:propType];
                NSString *fieldName = [NSString stringWithUTF8String:property_getName(prop)];
                [fieldNames addObject:fieldName];
            }
        }
    }
}

@end

#pragma clang diagnostic pop
