//
//  SQLCondition.h
//  Lighting
//
//  Created by Xiongxunquan on 9/23/15.
//  Copyright © 2015 xunquan inc.. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, LogicCode) {
    LogicCodeNone,
    LogicCodeAnd,
    LogicCodeOr,
    LogicCodeLeftBracket,
    LogicCodeRightBracket,
};

typedef NS_ENUM(NSInteger, SQLCompare) {
    SQLCompareEqual,
    SQLCompareNotEqual,
    SQLCompareGreater,
    SQLCompareLesser,
    SQLCompareEqualOrGreater,
    SQLCompareEqualOrLesser,
    SQLCompareBetween,
    SQLCompareLike,
    SQLCompareIs,
    SQLCompareIsNot,
};

typedef NS_ENUM(NSInteger, OrderType) {
    OrderTypeASC,
    OrderTypeDESC
};

@interface XQSQLCondition : NSObject

@property (readonly, strong, nonatomic) NSMutableDictionary *condition;
@property (readonly, strong, nonatomic) NSMutableArray<NSString *> *orderSQLs;

+ (instancetype)SQLConditionWithCondition:(XQSQLCondition *)condition;
+ (instancetype)conditionWhere:(NSString *)field equal:(id)value;
+ (instancetype)conditionWhere:(NSString *)field notEqual:(id)value;
+ (instancetype)conditionWhere:(NSString *)field greater:(id)value;
+ (instancetype)conditionWhere:(NSString *)field lesser:(id)value;
+ (instancetype)conditionWhere:(NSString *)field equalOrGreater:(id)value;
+ (instancetype)conditionWhere:(NSString *)field equalOrLesser:(id)value;

- (void)reset;
- (instancetype)setLimitFrom:(NSUInteger)atIndex limitCount:(NSUInteger)limitCount;
- (instancetype)addLogicCode:(LogicCode)logicCode;
- (instancetype)addWhereField:(NSString *)field compare:(SQLCompare)compare value:(id)value;
- (instancetype)addWhereField:(NSString *)field compare:(SQLCompare)compare value:(id)value logicCode:(LogicCode)logicCode;

- (instancetype)andWhere:(NSString *)field equal:(id)value;
- (instancetype)andWhere:(NSString *)field notEqual:(id)value;
- (instancetype)orWhere:(NSString *)field equal:(id)value;
- (instancetype)orWhere:(NSString *)field notEqual:(id)value;

- (instancetype)andWhere:(NSString *)field is:(id)value;
- (instancetype)andWhere:(NSString *)field isNot:(id)value;
- (instancetype)orWhere:(NSString *)field is:(id)value;
- (instancetype)orWhere:(NSString *)field isNot:(id)value;

- (NSString *)conditionSQL;
- (NSString *)whereAndLimitSQL;
- (void)addOrderField:(NSString *)field orderType:(OrderType)orderType;

@end
