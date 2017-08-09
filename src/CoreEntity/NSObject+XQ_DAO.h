//
//  ModelBase.h
//  Lighting
//
//  Created by Xiongxunquan on 9/12/15.
//  Copyright © 2015 xunquan inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XQModelBlocks.h"
//#import "FPDModelConstants.h"

typedef NS_ENUM(NSInteger, DBOptType) {
    DBOptTypeNone,
    DBOptTypeDelete,
    DBOptTypeAdd,
    DBOptTypeUpdate,
};

@class XQSQLCondition;

@protocol XQDBModel <NSObject>
@optional
- (NSString *)localId;
- (NSString *)UUID;
- (NSNumber *)deleted;

@end

@interface NSObject (XQ_DAO)

//@property (strong, nonatomic) NSNumber *localID;
//@property (strong, nonatomic) NSNumber *deleted;
//@property (copy, nonatomic) NSString *UUID;

+ (NSString *)rawUUID;

//@end
//
//@interface NSObject(Database)

+ (NSNumber *)safeNumberValue:(id)value;

/**
 helper
 */
+ (NSArray *)idsGroupByIds:(NSArray *)ids limitCount:(NSInteger)limitCount;
/**
 查询记录
 */
+ (NSArray<__kindof NSObject *> *)queryModelsWhere:(NSString *)field equal:(id)value;
+ (NSArray<__kindof NSObject *> *)queryModels;
+ (NSArray<__kindof NSObject *> *)queryModelsWithCondition:(XQSQLCondition *)condition;
+ (NSArray<__kindof NSObject *> *)queryModelsAtIndex:(NSUInteger)index
                                              limitCount:(NSUInteger)limitCount;
+ (void)queryModelsWithBlock:(QueryModelBlock)queryModelBlock
                     atIndex:(NSUInteger)index
                  limitCount:(NSUInteger)limitCount;
+ (void)queryModelsWithBlock:(QueryModelBlock)queryModelBlock
                   condition:(XQSQLCondition *)condition;
+ (instancetype)queryWhereUUIDEqual:(NSString *)UUID;
+ (instancetype)queryWhereLocalIDEqual:(NSNumber *)localID;
+ (instancetype)queryWhere:(NSString *)field equal:(id)value;
/**
 *  增加或更新一条记录
 *
 *  @para object         目标 model
 *  @para updateIfExist  如果存在，是否自动更新
 *
 *  注意此方法会吧 object 所有不为 nil 的属性添加/更新到数据库，如果给定的 object 在数据库存在，但是没有给定 unique id (localID/UUID) 将会直接添加而不是更新数据库中内容
 */
- (void)save;
+ (void)saveObject:(__kindof NSObject *)object;
+ (void)saveObject:(__kindof NSObject *)object updateIfExist:(BOOL)updateIfExist;
+ (void)saveObjectsInTransaction:(NSArray<__kindof NSObject *> *)objects;
+ (void)saveObjectsInTransaction:(NSArray<__kindof NSObject *> *)objects updateIfExist:(BOOL)updateIfExist;

+ (void)saveObjectWithBlock:(InitModelBlock)initModelBlock updateIfExist:(BOOL)updateIfExist;
+ (void)saveObjectWithBlock:(InitModelBlock)initModelBlock updateIfExist:(BOOL)updateIfExist optType:(DBOptType *)optType;
/**
 *  设置全表的某个属性
 */
+ (void)setProperty:(NSString *)prop value:(id)value;
+ (void)setProperty:(NSString *)prop value:(id)value condition:(XQSQLCondition *)condition;
/**
 *  获取记录数量
 */
//+ (BOOL)tableExisted;
+ (NSUInteger)countOfCol;
+ (NSUInteger)countOfWhereProp:(NSString *)prop equal:(id)value;
+ (NSUInteger)countOfWhereProp:(NSString *)prop notEqual:(id)value;
+ (NSUInteger)countOfCondition:(XQSQLCondition *)condition;
/**
 *  删除 model
 */
- (BOOL)deleteFromDatabase;
+ (BOOL)deleteObject:(__kindof NSObject *)object;
+ (BOOL)deleteObjectsInTransaction:(NSArray<__kindof NSObject *> *)objects;
+ (BOOL)deleteObjectWithCondition:(XQSQLCondition *)condition;
+ (BOOL)deleteWhere:(NSString *)field equal:(id)value;
+ (BOOL)deleteWhereLocalIDEqual:(NSNumber *)localID;
/**
 *  清空当前数据表
 */
+ (BOOL)clean;

#pragma mark - 选择重写
/**
 唯一的，但是允许为NULL，没有强制唯一约束，但是不允许更新该字段
 并且一次事物中如果有2条以上记录出现同样的值，会忽略前面的那个，并报警告
 默认判断存在记录，会使根据此字段查询是否数据库存在，如果存在则会走更新而不是插入
 注意，uniquesNotNull 是 uniquesAbleNull 的子集
 */
+ (NSArray<NSString *> *)uniquesAbleNull;
/**
 唯一不允许为NULL
 */
+ (NSArray<NSString *> *)uniquesNotNull;
/**
 不允许为NULL 的字段
 注意，uniquesNotNull 也是 notNullFields 的子集
 */
+ (NSArray<NSString *> *)notNullFields;

/**
 排序字段，可自定义，因为dict是无序的，所以数组里每个dict只能有一个key，value
 example: @[@{PROP_TO_STRING(localID):@(OrderTypeDESC)}]
 */
+ (NSArray<NSDictionary<NSString *, NSNumber *> *> *)orderSQLsArray;
@end
