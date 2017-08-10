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
//  ModelBase.h
//  Lighting
//
//  Created by Xiongxunquan on 9/12/15.
//  Copyright © 2015 xunquan inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XQModelBlocks.h"

typedef NS_ENUM(NSInteger, DBOptType) {
    DBOptTypeNone,
    DBOptTypeDelete,
    DBOptTypeAdd,
    DBOptTypeUpdate,
};

@class XQSQLCondition;

/*
 所有需要持久化的 model 需要实现 <XQDBModel> 协议
 
 你可以复制下面的代码到你的类中
 
 @property (strong, nonatomic, readonly) NSNumber *localID;
 @property (strong, nonatomic, readonly) NSNumber *deleted;
 @property (copy, nonatomic, readonly) NSString *UUID;
 
 */
@protocol XQDBModel <NSObject>

@required

- (NSNumber *)localID;
- (NSString *)UUID;
- (NSNumber *)deleted;

@optional
+ (NSArray<NSString *> *)child_uniquesAbleNull;
+ (NSArray<NSString *> *)child_uniquesNotNull;
+ (NSArray<NSString *> *)child_notNullFields;
+ (NSArray<NSDictionary<NSString *, NSNumber *> *> *)child_orderSQLsArray;

+ (NSString *)child_primaryKey;

+ (BOOL)child_isPrimaryKey:(NSString *)field;
+ (BOOL)child_isUnchangeableField:(NSString *)field;
+ (BOOL)child_isUnableNullField:(NSString *)field;

/**
 字段描述，建议默认
 */
+ (NSString *)child_createSQL;


/**
 字段描述，建议默认
 */
+ (NSString *)child_fieldDescribe:(NSString *)fieldName;

/**
 自增字段的起始值，用于保留特殊 ID，建议默认
 */
+ (NSDictionary<NSString *, NSNumber *> *)child_startValueForAutoIncrement;

/**
 默认判断存在的查询条件，默认根据uniqueIndexes生成，建议默认
 */
- (XQSQLCondition *)child_defaultExistCondition;

/**
 *  this function for just set once prop in database, such as `localID/UUID/serverID...`
 *
 *  @param dbModel   model in database
 *  @param fieldName prop name
 *
 *  @return will update this prop about prop name if return YES, or else NO
 *
 */
- (BOOL)child_willUpdatedbModel:(NSObject *)dbModel withFieldName:(NSString *)fieldName;

@end

@interface NSObject (XQ_DAO)

/**
 helper
 */
#pragma mark - helper
+ (NSString *)xq_rawUUID;
+ (NSNumber *)xq_safeNumberValue:(id)value;
+ (NSArray *)xq_idsGroupByIds:(NSArray *)ids limitCount:(NSInteger)limitCount;
/**
 查询记录
 */
#pragma mark - query
+ (NSArray<__kindof NSObject *> *)xq_queryMakeCondition:(void(^)(XQSQLCondition *condition))makeCondition;
+ (NSArray<__kindof NSObject *> *)xq_queryModelsWhere:(NSString *)field equal:(id)value;
+ (NSArray<__kindof NSObject *> *)xq_queryModels;
/*
 最好确保 field 是一个 Unique id，否则会只返回第一个结果
 */
+ (instancetype)xq_queryWhereUUIDEqual:(NSString *)UUID;
+ (instancetype)xq_queryWhereLocalIDEqual:(NSNumber *)localID;
+ (instancetype)xq_queryWhere:(NSString *)field equal:(id)value;
/**
 *  增加或更新一条记录
 *
 *  @para object         目标 model
 *  @para updateIfExist  如果存在，是否自动更新
 *
 *  注意此方法会吧 object 所有不为 nil 的属性添加/更新到数据库，如果给定的 object 在数据库存在，但是没有给定 unique id (localID/UUID) 将会直接添加而不是更新数据库中内容
 */
- (void)xq_save;
+ (void)xq_saveObject:(__kindof NSObject *)object;
+ (void)xq_saveObject:(__kindof NSObject *)object updateIfExist:(BOOL)updateIfExist;
+ (void)xq_saveObjectsInTransaction:(NSArray<__kindof NSObject *> *)objects;
+ (void)xq_saveObjectsInTransaction:(NSArray<__kindof NSObject *> *)objects updateIfExist:(BOOL)updateIfExist;

+ (void)xq_saveObjectWithBlock:(InitModelBlock)initModelBlock updateIfExist:(BOOL)updateIfExist;
+ (void)xq_saveObjectWithBlock:(InitModelBlock)initModelBlock updateIfExist:(BOOL)updateIfExist optType:(DBOptType *)optType;
/**
 *  设置全表的某个属性
 */
+ (void)xq_setProperty:(NSString *)prop value:(id)value;
+ (void)xq_setProperty:(NSString *)prop value:(id)value condition:(XQSQLCondition *)condition;
/**
 *  获取记录数量
 */
//+ (BOOL)tableExisted;
+ (NSUInteger)xq_countOfCol;
+ (NSUInteger)xq_countOfWhereProp:(NSString *)prop equal:(id)value;
+ (NSUInteger)xq_countOfWhereProp:(NSString *)prop notEqual:(id)value;
+ (NSUInteger)xq_countOfCondition:(XQSQLCondition *)condition;
/**
 *  删除 model
 */
- (BOOL)xq_deleteFromDatabase;
+ (BOOL)xq_deleteObject:(__kindof NSObject *)object;
+ (BOOL)xq_deleteObjectsInTransaction:(NSArray<__kindof NSObject *> *)objects;
+ (BOOL)xq_deleteObjectWithCondition:(XQSQLCondition *)condition;
+ (BOOL)xq_deleteWhere:(NSString *)field equal:(id)value;
+ (BOOL)xq_deleteWhereLocalIDEqual:(NSNumber *)localID;
/**
 *  清空当前数据表
 */
+ (BOOL)xq_clean;

#pragma mark - 选择重写
/*
 重写下面的方法，请实现 <XQDBModel> 协议，并改 `xq_` 前缀为 `child_`
 例如:
 // assetId 是一个允许为空的唯一 id，它默认只能被写入一次，在它为 null 时，允许重复，但是对于有效数据不允许重复
 // !! 注意：写入有效数据时，要注意合并等情况的发生
 + (NSArray<NSString *> *)child_uniquesAbleNull {
    NSMutableArray *fields = [[self xq_uniquesAbleNull] mutableCopy];
    [fields addObject:PROP_TO_STRING(assetId)];
    return fields;
 }
 //表示不允许为空的字段
 + (NSArray<NSString *> *)child_notNullFields {
    NSMutableArray *fields = [[self xq_notNullFields] mutableCopy];
    [fields addObject:PROP_TO_STRING(dateTime)];
    [fields addObject:PROP_TO_STRING(type)];
    [fields addObject:PROP_TO_STRING(addType)];
    [fields addObject:PROP_TO_STRING(ownerId)];
    [fields addObject:PROP_TO_STRING(uploaderId)];
    return fields;
 }
 //排序字段，按照前后顺序优先级排序
 + (NSArray<NSDictionary<NSString *, NSNumber *> *> *)child_orderSQLsArray {
    return @[@{PROP_TO_STRING(netDateTaken):@(OrderTypeDESC)},
             @{PROP_TO_STRING(dateTaken):@(OrderTypeDESC)},
             @{PROP_TO_STRING(createTime):@(OrderTypeDESC)}];
 }
 
 */
/**
 唯一的，但是允许为NULL，没有强制唯一约束，但是不允许更新该字段
 并且一次事物中如果有2条以上记录出现同样的值，会忽略前面的那个，并报警告
 默认判断存在记录，会使根据此字段查询是否数据库存在，如果存在则会走更新而不是插入
 注意，uniquesNotNull 是 uniquesAbleNull 的子集
 */
+ (NSArray<NSString *> *)xq_uniquesAbleNull;
/**
 唯一不允许为NULL
 */
+ (NSArray<NSString *> *)xq_uniquesNotNull;
/**
 不允许为NULL 的字段
 注意，uniquesNotNull 也是 notNullFields 的子集
 */
+ (NSArray<NSString *> *)xq_notNullFields;

/**
 排序字段，可自定义，因为dict是无序的，所以数组里每个dict只能有一个key，value
 example: @[@{PROP_TO_STRING(localID):@(OrderTypeDESC)}]
 */
+ (NSArray<NSDictionary<NSString *, NSNumber *> *> *)xq_orderSQLsArray;


+ (BOOL)xq_isPrimaryKey:(NSString *)field;
+ (BOOL)xq_isUnchangeableField:(NSString *)field;
+ (BOOL)xq_isUnableNullField:(NSString *)field;


+ (NSString *)xq_primaryKey;

/**
 字段描述，建议默认
 */
+ (NSDictionary *)xq_fieldDescribeDict;

+ (NSDictionary *)xq_tableDescribtion;

+ (NSString *)xq_createSQL;


/**
 字段描述，默认从 xq_fieldDescribeDict 生成
 */
+ (NSString *)xq_fieldDescribe:(NSString *)fieldName;

/**
 自增字段的起始值，用于保留特殊 ID，建议默认
 */
+ (NSDictionary<NSString *, NSNumber *> *)xq_startValueForAutoIncrement;

/**
 默认判断存在的查询条件，默认根据uniqueIndexes生成，建议默认
 */
- (XQSQLCondition *)xq_defaultExistCondition;

/**
 *  this function for just set once prop in database, such as `localID/UUID/serverID...`
 *
 *  @param dbModel   model in database
 *  @param fieldName prop name
 *
 *  @return will update this prop about prop name if return YES, or else NO
 *
 */
- (BOOL)xq_willUpdatedbModel:(NSObject *)dbModel withFieldName:(NSString *)fieldName;

@end
