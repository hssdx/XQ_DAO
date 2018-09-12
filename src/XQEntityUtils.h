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
//  XQEntityUtils.h
//  xunquan
//
//  Created by quanxiong on 16/6/19.
//  Copyright © 2016年 xunquan inc.. All rights reserved.
//

#ifndef XQEntityUtils_h
#define XQEntityUtils_h

#define ASSIGN_STRING_TO_NUM_ARRAY(_STRING, _ARRAY) \
NSArray<NSString *> *stringArr = [_STRING componentsSeparatedByString:@","]; \
_ARRAY = [stringArr bk_map:^id _Nonnull(NSString * _Nonnull obj) { \
    return @([obj longLongValue]); \
}]; \

/**
 *  绑定 可变数组 与 字符串 数据，只允许 数据库 去读写字符串，外界不允许修改
 *
 *  @param _ARRAY           数组
 *  @param _ARRAY_SETTER    数组的 setter 方法名称
 */
#define FP_IMP_MUTABLE_ARRAY_GETTER_SETTER(_ARRAY, _ARRAY_SETTER) \
@synthesize _ARRAY = _##_ARRAY; \
@synthesize _ARRAY##String = _##_ARRAY##String; \
\
- (NSString *)_ARRAY##String { \
    return [_##_ARRAY yy_modelToJSONString]; \
} \
\
- (void)_ARRAY_SETTER##String:(__kindof NSString *)_ARRAY##String { \
_##_ARRAY = [[_##_ARRAY##String jsonValueDecoded] mutableCopy]; \
}

/**
 *  绑定可变字典与 JSON 串的数据，只允许 数据库 去读写字符串，外界不允许修改
 *
 *  @param _DICT     字典
 *  @param _JSONSTR  能被解析为字典的 JSON 字符串
 */
#define FP_IMP_MUTABLE_DICT_GETTER_SETTER(_DICT, _DICT_SETTER) \
@synthesize _DICT = _##_DICT;  \
@synthesize _DICT##Json = _##_DICT##Json;  \
\
- (__kindof NSString *)_DICT##Json { \
    return [_##_DICT yy_modelToJSONString]; \
} \
\
- (void)_DICT_SETTER##Json:(__kindof NSString *)_DICT##Json { \
    _##_DICT = [[_DICT##Json jsonValueDecoded] mutableCopy]; \
}

/**
 *  绑定 数组 与 字符串 数据，在读写 数组 与 字符串 时，同时更新对应的绑定数据
 *
 *  @param _ARRAY           数组
 *  @param _ARRAY_SETTER    数组的 setter 方法名称
 */
#define FP_IMP_ARRAY_GETTER_SETTER(_ARRAY, _ARRAY_SETTER) \
@synthesize _ARRAY = _##_ARRAY; \
@synthesize _ARRAY##String = _##_ARRAY##String; \
\
- (void)_ARRAY_SETTER:(NSArray *)_ARRAY { \
    _##_ARRAY##String = [_ARRAY yy_modelToJSONString]; \
    _##_ARRAY = [_ARRAY copy]; \
} \
\
- (NSArray *)_ARRAY { \
    if (_##_ARRAY##String.length > 0 && _##_ARRAY.count == 0) { \
        _##_ARRAY = [_##_ARRAY##String jsonValueDecoded]; \
    } \
    return _##_ARRAY; \
} \
\
- (void)_ARRAY_SETTER##String:(__kindof NSString *)_ARRAY##String { \
    _##_ARRAY = [_##_ARRAY##String jsonValueDecoded]; \
    _##_ARRAY##String = [_ARRAY##String copy]; \
} \
\
- (NSString *)_ARRAY##String { \
    if (_##_ARRAY##String.length == 0 && _##_ARRAY.count > 0) { \
        _##_ARRAY##String = [_##_ARRAY yy_modelToJSONString]; \
    } \
    return _##_ARRAY##String; \
}

/**
 *  绑定 字符串数组 与 字符串 数据，在读写 字符串数组 与  字符串 时，同时更新对应的绑定数据
 *
 *  @param _ARRAY           字符串数组
 *  @param _ARRAY_SETTER    字符串数组的 setter 方法名称
 */
#define FP_IMP_STR_ARRAY_GETTER_SETTER(_ARRAY, _ARRAY_SETTER) \
@synthesize _ARRAY = _##_ARRAY; \
@synthesize _ARRAY##String = _##_ARRAY##String; \
\
- (void)_ARRAY_SETTER:(__kindof NSArray<NSString *> *)_ARRAY { \
    _##_ARRAY##String = [_ARRAY componentsJoinedByString:@","]; \
    _##_ARRAY = _ARRAY; \
} \
\
- (__kindof NSArray<NSString *> *)_ARRAY { \
    if (_##_ARRAY##String.length > 0 && _##_ARRAY.count == 0) { \
        _##_ARRAY = [_##_ARRAY##String componentsSeparatedByString:@","]; \
    } \
    return _##_ARRAY; \
} \
\
- (__kindof NSString *)_ARRAY##String { \
    if (_##_ARRAY##String.length == 0 && _##_ARRAY.count > 0) { \
        _##_ARRAY##String = [_##_ARRAY componentsJoinedByString:@","]; \
    } \
    return _##_ARRAY##String; \
} \
\
- (void)_ARRAY_SETTER##String:(__kindof NSString *)_ARRAY##String { \
    _##_ARRAY = [_##_ARRAY##String componentsSeparatedByString:@","]; \
    _##_ARRAY##String = _ARRAY##String; \
}

/**
 *  绑定 Number 数组 与 字符串 数据，在读写 Number 数组 与  字符串 时，同时更新对应的绑定数据
 *
 *  @param _ARRAY           Number 数组
 *  @param _ARRAY_SETTER    Number 数组的 setter 方法名称
 */
#define FP_IMP_NUM_ARRAY_GETTER_SETTER(_ARRAY, _ARRAY_SETTER) \
@synthesize _ARRAY = _##_ARRAY; \
@synthesize _ARRAY##String = _##_ARRAY##String; \
\
- (void)_ARRAY_SETTER:(__kindof NSArray<NSNumber *> *)_ARRAY { \
    _##_ARRAY##String = [_ARRAY componentsJoinedByString:@","]; \
    _##_ARRAY = _ARRAY; \
} \
\
- (__kindof NSArray<NSNumber *> *)_ARRAY { \
    if (_##_ARRAY##String.length > 0 && _##_ARRAY.count == 0) { \
        ASSIGN_STRING_TO_NUM_ARRAY(_##_ARRAY##String, _##_ARRAY) \
    } \
    return _##_ARRAY; \
} \
\
- (__kindof NSString *)_ARRAY##String { \
    if (_##_ARRAY##String.length == 0 && _##_ARRAY.count > 0) { \
        _##_ARRAY##String = [_##_ARRAY componentsJoinedByString:@","]; \
    } \
    return _##_ARRAY##String; \
} \
\
- (void)_ARRAY_SETTER##String:(__kindof NSString *)_ARRAY##String { \
    ASSIGN_STRING_TO_NUM_ARRAY(_##_ARRAY##String, _##_ARRAY) \
    _##_ARRAY##String = _ARRAY##String; \
}


/**
 *  绑定字典与 JSON 串的数据，在读写字典与 JSON 串时，同时更新对应的绑定数据
 *
 *  @param _DICT     字典
 *  @param _JSONSTR  能被解析为字典的 JSON 字符串
 */
#define FP_IMP_DICT_GETTER_SETTER(_DICT, _DICT_SETTER) \
@synthesize _DICT = _##_DICT;  \
@synthesize _DICT##Json = _##_DICT##Json;  \
\
- (void)_DICT_SETTER:(__kindof NSDictionary *)_DICT { \
    _##_DICT##Json = [_DICT yy_modelToJSONString]; \
    _##_DICT = _DICT; \
} \
\
- (__kindof NSDictionary *)_DICT { \
    if (_##_DICT##Json.length > 0 && _##_DICT.count == 0) { \
        _##_DICT = [_##_DICT##Json jsonValueDecoded]; \
    } \
    return _##_DICT; \
} \
\
- (__kindof NSString *)_DICT##Json { \
    if (_##_DICT##Json.length == 0 && _##_DICT) { \
        _##_DICT##Json = [_##_DICT yy_modelToJSONString]; \
    } \
    return _##_DICT##Json; \
} \
\
- (void)_DICT_SETTER##Json:(__kindof NSString *)_DICT##Json { \
    id dict = [_DICT##Json jsonValueDecoded]; \
    if ([dict isKindOfClass:_##_DICT.class]) { \
        _##_DICT = dict; \
    } \
    _##_DICT##Json = _DICT##Json; \
}

/**
 *  在定义一组结构化数据（数组、字典等）时，同事定义一个与之对应的字符串序列化数据，来达到存储到数据库中的目的
 *
 *  @param _COPY       copy 或 strong
 *  @param _PROP_TYPE  属性类型，NSDictionary 或 NSArray
 *  @param _PROP_NAME  属性名称
 */
#define FP_ARRAY_PROPERTY(_COPY, _PROP_NAME, _TYPE) \
@property (_COPY, nonatomic) NSArray< _TYPE *> * _PROP_NAME; \
@property (_COPY, nonatomic) NSString * _PROP_NAME##String

#define FP_STR_ARRAY_PROPERTY(_COPY, _PROP_NAME) \
FP_ARRAY_PROPERTY(_COPY, _PROP_NAME, NSString)

#define FP_NUM_ARRAY_PROPERTY(_COPY, _PROP_NAME) \
FP_ARRAY_PROPERTY(_COPY, _PROP_NAME, NSNumber)

#define FP_DICTIONARY_PROPERTY(_COPY, _PROP_NAME, _TYPE_KEY, _TYPE_VALUE) \
@property (_COPY, nonatomic) NSDictionary< _TYPE_KEY , _TYPE_VALUE > * _PROP_NAME; \
@property (_COPY, nonatomic) NSString * _PROP_NAME##Json

//可变
#define FP_MUTABLE_ARRAY_PROPERTY(_COPY, _PROP_NAME, _TYPE) \
@property (_COPY, nonatomic) NSMutableArray< _TYPE *> * _PROP_NAME; \
@property (_COPY, nonatomic) NSString * _PROP_NAME##String

#define FP_MUTABLE_STR_ARRAY_PROPERTY(_COPY, _PROP_NAME) \
FP_MUTABLE_ARRAY_PROPERTY(_COPY, _PROP_NAME, NSString)

#define FP_MUTABLE_NUM_ARRAY_PROPERTY(_COPY, _PROP_NAME) \
FP_MUTABLE_ARRAY_PROPERTY(_COPY, _PROP_NAME, NSNumber)

#define FP_MUTABLE_DICTIONARY_PROPERTY(_COPY, _PROP_NAME) \
@property (_COPY, nonatomic) NSMutableDictionary * _PROP_NAME; \
@property (_COPY, nonatomic) NSString * _PROP_NAME##Json


#endif /* XQEntityUtils_h */
