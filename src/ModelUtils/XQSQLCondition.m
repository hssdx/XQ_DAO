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
//  SQLCondition.m
//  Xunquan
//
//  Created by Xiongxunquan on 9/23/15.
//  Copyright © 2015 xunquan inc.. All rights reserved.
//

#import "XQSQLCondition.h"
#import "XQ_DAOUtils.h"

/**
 *  条件查询允许传入一个dictionary,格式如下：
 {
 limit:{limitAt:idxV, limitCount:cntV}
 where:{[@{logicCode:$AND/$OR field:fname, value:vvalue}, ...]}
 }
 */
NSString *const kLimitKey = @"limit";
NSString *const kLimitAtKey = @"limitAt";
NSString *const kLimitCountKey = @"limitCount";
NSString *const kWhereKey = @"where";
NSString *const kWhereFieldKey = @"field";
NSString *const kWhereValueKey = @"value";
NSString *const kLogicCodeKey = @"logicCode";
NSString *const kOperationKey = @"operation";

NSString *const kAnd = @"AND";
NSString *const kOr = @"OR";
NSString *const kLeftBracket = @"(";
NSString *const kRightBracket = @")";
NSString *const kEqual = @"=";
NSString *const kNotEqual = @"<>";
NSString *const kGreater = @">";
NSString *const kLesser = @"<";
NSString *const kEqualOrGreater = @">=";
NSString *const kEqualOrLesser = @"<=";
NSString *const kBetween = @"BETWEEN";
NSString *const kLike = @"LIKE";
NSString *const kIs = @"IS";
NSString *const kIsNot = @"IS NOT";

@interface XQSQLCondition()

@property (readwrite, strong, nonatomic) NSMutableDictionary *condition;
@property (readwrite, strong, nonatomic) NSMutableArray<NSString *> *orderSQLs;

@end

@implementation XQSQLCondition

- (NSMutableArray<NSString *> *)orderSQLs {
    if (!_orderSQLs) {
        _orderSQLs = [NSMutableArray array];
    }
    return _orderSQLs;
}

- (void)addOrderField:(NSString *)field orderType:(OrderType)orderType {
    static NSDictionary *s_typeToOrder;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_typeToOrder = @{@(OrderTypeASC):@"ASC",
                          @(OrderTypeDESC):@"DESC"};
    });
    NSString *orderSQL = [NSString stringWithFormat:@"%@ %@",
                          field, s_typeToOrder[@(orderType)]];
    [self.orderSQLs addObject:orderSQL];
}

- (instancetype)init {
    if (self = [super init]) {
        _condition = [NSMutableDictionary dictionary];
    }
    return self;
}

- (NSString *)stringWithCompare:(SQLCompare)compare {
    NSString *cmpString;
    switch (compare) {
        case SQLCompareEqual:
            cmpString = kEqual;
            break;
        case SQLCompareNotEqual:
            cmpString = kNotEqual;
            break;
        case SQLCompareGreater:
            cmpString = kGreater;
            break;
        case SQLCompareLesser:
            cmpString = kLesser;
            break;
        case SQLCompareEqualOrGreater:
            cmpString = kEqualOrGreater;
            break;
        case SQLCompareEqualOrLesser:
            cmpString = kEqualOrLesser;
            break;
        case SQLCompareBetween:
            cmpString = kBetween;
            break;
        case SQLCompareLike:
            cmpString = kLike;
            break;
        case SQLCompareIs:
            cmpString = kIs;
            break;
        case SQLCompareIsNot:
            cmpString = kIsNot;
            break;
    }
    return cmpString;
}

- (NSString *)stringWithLogic:(LogicCode)logic {
    NSString *logicString;
    switch (logic) {
        case LogicCodeNone:
            logicString = @"";
            break;
        case LogicCodeOr:
            logicString = kOr;
            break;
        case LogicCodeAnd:
            logicString = kAnd;
            break;
        case LogicCodeLeftBracket:
            logicString = kLeftBracket;
            break;
        case LogicCodeRightBracket:
            logicString = kRightBracket;
            break;
    }
    return logicString;
}

- (NSString *)getLimitSql {
    NSDictionary *limitDict = XQDAORequiredCast([self.condition objectForKey:kLimitKey], NSDictionary);
    if ([limitDict count] == 0) {
        return @"";
    }
    NSString *limitSql = @"";
    NSNumber *atIndexNumber = [limitDict objectForKey:kLimitAtKey];
    NSNumber *countNumber = [limitDict objectForKey:kLimitCountKey];
    if (countNumber.longLongValue == 0) {
        return @"";
    }
    limitSql = [NSString stringWithFormat:@" limit %@,%@ ", atIndexNumber, countNumber];
    return limitSql;
}

- (NSString *)getWhereSql {
    NSMutableString *whereSql = [NSMutableString stringWithString:@""];
    NSArray<NSDictionary *> *whereArray = XQDAORequiredCast([self.condition objectForKey:kWhereKey], NSArray);
    if ([whereArray count] == 0) {
        return whereSql;
    }
    [whereSql appendFormat:@"where "];
    [whereArray enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull whereDict, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *logicCode = [whereDict objectForKey:kLogicCodeKey];
        NSString *whereField = [whereDict objectForKey:kWhereFieldKey];
        NSString *compareStr = [whereDict objectForKey:kOperationKey];
        id whereValue = [whereDict objectForKey:kWhereValueKey];
        
        if (idx > 0 && ([logicCode isEqualToString:kAnd] || [logicCode isEqualToString:kOr])) {
            [whereSql appendFormat:@" %@ ", logicCode];
        } else if ([logicCode isEqualToString:kLeftBracket] || [logicCode isEqualToString:kRightBracket]) {
            [whereSql appendFormat:@"%@", logicCode];
        }
        if (whereField.length > 0) {
            if ([whereValue isKindOfClass:[NSString class]]) {
                [whereSql appendFormat:@" %@ %@ '%@' ", whereField, compareStr, whereValue];
            } else if ([whereValue isKindOfClass:[NSNumber class]]){
                [whereSql appendFormat:@" %@ %@ %@ ", whereField, compareStr, whereValue];
            } else if ([whereValue isKindOfClass:[NSNull class]]) {
                [whereSql appendFormat:@" %@ %@ NULL ", whereField, compareStr];
            } else {
                XQDAOAssert(false);
            }
        }
    }];
    return whereSql;
}

#pragma mark - public func
+ (instancetype)SQLConditionWithCondition:(XQSQLCondition *)aCondition {
    XQSQLCondition *condition = [XQSQLCondition new];
    condition.orderSQLs = [aCondition.orderSQLs mutableCopy];
    condition.condition = [aCondition.condition mutableCopy];
    return condition;
}

- (void)where:(NSString *)field compare:(SQLCompare)compare value:(id)value {
    [self addWhereField:field compare:compare value:value];
}

+ (instancetype)condition {
    return [self new];
}

+ (instancetype)conditionWhere:(NSString *)field equal:(id)value {
    XQSQLCondition *condition = [self new];
    [condition where:field compare:SQLCompareEqual value:value];
    return condition;
}

+ (instancetype)conditionWhere:(NSString *)field notEqual:(id)value {
    XQSQLCondition *condition = [self new];
    [condition where:field compare:SQLCompareNotEqual value:value];
    return condition;
}

+ (instancetype)conditionWhere:(NSString *)field greater:(id)value {
    XQSQLCondition *condition = [self new];
    [condition where:field compare:SQLCompareGreater value:value];
    return condition;
}

+ (instancetype)conditionWhere:(NSString *)field lesser:(id)value {
    XQSQLCondition *condition = [self new];
    [condition where:field compare:SQLCompareLesser value:value];
    return condition;
}

+ (instancetype)conditionWhere:(NSString *)field equalOrGreater:(id)value {
    XQSQLCondition *condition = [self new];
    [condition where:field compare:SQLCompareEqualOrGreater value:value];
    return condition;
}

+ (instancetype)conditionWhere:(NSString *)field equalOrLesser:(id)value {
    XQSQLCondition *condition = [self new];
    [condition where:field compare:SQLCompareEqualOrLesser value:value];
    return condition;
}

- (void)reset {
    [self.condition removeAllObjects];
    [self.orderSQLs removeAllObjects];
}

- (instancetype)setLimitFrom:(NSUInteger)atIndex limitCount:(NSUInteger)limitCount {
    NSNumber *atIndexNumber = [NSNumber numberWithUnsignedInteger:atIndex];
    NSNumber *limitCntNumber = [NSNumber numberWithUnsignedInteger:limitCount];
    self.condition[kLimitKey] = @{kLimitAtKey:atIndexNumber,
                                  kLimitCountKey:limitCntNumber};
    return self;
}

- (instancetype)addLogicCode:(LogicCode)logicCode {
    [self addWhereField:@"" compare:SQLCompareEqual value:@"" logicCode:logicCode];
    return self;
}

- (instancetype)addWhereField:(NSString *)field
                      compare:(SQLCompare)compare
                        value:(id)value {
    [self addWhereField:field compare:compare value:value logicCode:LogicCodeNone];
    return self;
}

- (instancetype)andWhere:(NSString *)field equal:(id)value {
    [self addWhereField:field compare:SQLCompareEqual value:value logicCode:LogicCodeAnd];
    return self;
}

- (instancetype)andWhere:(NSString *)field notEqual:(id)value {
    [self addWhereField:field compare:SQLCompareNotEqual value:value logicCode:LogicCodeAnd];
    return self;
}

- (instancetype)orWhere:(NSString *)field equal:(id)value {
    [self addWhereField:field compare:SQLCompareEqual value:value logicCode:LogicCodeOr];
    return self;
}

- (instancetype)orWhere:(NSString *)field notEqual:(id)value {
    [self addWhereField:field compare:SQLCompareNotEqual value:value logicCode:LogicCodeOr];
    return self;
}

- (instancetype)andWhere:(NSString *)field is:(id)value {
    [self addWhereField:field compare:SQLCompareIs value:value logicCode:LogicCodeAnd];
    return self;
}

- (instancetype)andWhere:(NSString *)field isNot:(id)value {
    [self addWhereField:field compare:SQLCompareIsNot value:value logicCode:LogicCodeAnd];
    return self;
}

- (instancetype)orWhere:(NSString *)field is:(id)value {
    [self addWhereField:field compare:SQLCompareIs value:value logicCode:LogicCodeOr];
    return self;
}

- (instancetype)orWhere:(NSString *)field isNot:(id)value {
    [self addWhereField:field compare:SQLCompareIsNot value:value logicCode:LogicCodeOr];
    return self;
}

- (instancetype)addWhereField:(NSString *)field
                      compare:(SQLCompare)compare
                        value:(id)value
                    logicCode:(LogicCode)logicCode {
    if (!field || !value) {
        return self;
    }
    
    NSMutableArray *whereArray = self.condition[kWhereKey];
    if (NO == [whereArray isKindOfClass:[NSMutableArray class]]) {
        whereArray = [NSMutableArray array];
        self.condition[kWhereKey] = whereArray;
    }
    NSString *cmpString = [self stringWithCompare:compare];
    NSString *logicString = @"";
    if ([whereArray count] > 0 || (logicCode != LogicCodeOr && logicCode != LogicCodeAnd)) {
        logicString = [self stringWithLogic:logicCode];
    }
    [whereArray addObject:@{kLogicCodeKey:logicString,
                            kWhereFieldKey:field,
                            kOperationKey:cmpString,
                            kWhereValueKey:value}];
    return self;
}

- (NSString *)conditionSQL {
    NSMutableString *sql = [NSMutableString string];
    [sql appendString:[self getWhereSql]];
    if (self.orderSQLs.count > 0) {
        [sql appendString:@" ORDER BY "];
        [self.orderSQLs enumerateObjectsUsingBlock:
         ^(NSString *sqlItem, NSUInteger idx, BOOL *stop) {
             [sql appendString:sqlItem];
             if (idx < self.orderSQLs.count - 1) {
                 [sql appendString:@", "];
             }
        }];
    }
    [sql appendString:[self getLimitSql]];
    return sql;
}

- (NSString *)whereAndLimitSQL {
    NSMutableString *sql = [NSMutableString string];
    [sql appendString:[self getWhereSql]];
    [sql appendString:[self getLimitSql]];
    return sql;
}

@end
