//
//  NSObject+Protect.h
//  Lighting
//
//  Created by Xiongxunquan on 10/23/15.
//  Copyright © 2015 xunquan inc.. All rights reserved.
//

#import "NSObject+XQ_DAO.h"

extern NSString *const kFieldNames;

@interface NSObject (XQProtect)

+ (BOOL)isPrimaryKey:(NSString *)field;
+ (BOOL)isUnchangeableField:(NSString *)field;
+ (BOOL)isUnableNullField:(NSString *)field;


+ (NSString *)primaryKey;

/**
 字段描述，建议默认
 */
+ (NSDictionary *)fieldDescribeDict;

+ (NSDictionary *)tableDescribtion;
+ (NSString *)createSQL;


/**
 字段描述，建议默认
 */
+ (NSString *)fieldDescribe:(NSString *)fieldName;

/**
 自增字段的起始值，用于保留特殊 ID，建议默认
 */
+ (NSDictionary<NSString *, NSNumber *> *)startValueForAutoIncrement;

/**
 默认判断存在的查询条件，默认根据uniqueIndexes生成，建议默认
 */
- (XQSQLCondition *)defaultExistCondition;

/**
 *  this function for just set once prop in database, such as `localID/UUID/serverID...`
 *
 *  @param dbModel   model in database
 *  @param fieldName prop name
 *
 *  @return will update this prop about prop name if return YES, or else NO
 *
 */
- (BOOL)willUpdatedbModel:(NSObject *)dbModel withFieldName:(NSString *)fieldName;

@end
