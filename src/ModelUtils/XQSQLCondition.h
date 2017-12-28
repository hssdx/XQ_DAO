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
//  SQLCondition.h
//  Xunquan
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
+ (instancetype)condition;
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

- (NSString *)conditionSQL __attribute__((deprecated("有 SQL注入风险，请使用 conditionArgValues: 替代")));
- (NSString *)conditionArgValues:(NSMutableArray *)values;
- (NSString *)whereAndLimitSQL;
- (void)addOrderField:(NSString *)field orderType:(OrderType)orderType;

@end
