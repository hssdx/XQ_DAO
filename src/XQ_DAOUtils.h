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
//  XQ_DAOUtils.h
//  XQ_DAO
//
//  Created by quanxiong on 2017/12/22.
//  Copyright © 2017年 com.hssdx. All rights reserved.
//

#import <Foundation/Foundation.h>


#define xq_dao_force_inline __inline__ __attribute__((always_inline))

#define XQDAORequiredCast(_id, _class) xq_dao_obj_for_class(_id, [_class class])

#define XQDAO_SEL_TO_STRING(_PROP_NAME) NSStringFromSelector(@selector(_PROP_NAME))

#define XQDAOCFRelease(_V) if (_V) { CFRelease(_V); _V = NULL; }

#define XQDAO_OBJ_CLASS_NAME(_OBJ) NSStringFromClass([_OBJ class])


#if DEBUG //if

#define XQDAOAssert(e) assert(e)
#define XQDAOLog(...) xq_dao_log(__VA_ARGS__)

#else //else

#define XQDAOAssert(e) (void)0
#define XQDAOLog(...) (void)0


#endif


extern id xq_dao_obj_for_class(id _id, Class cls);
extern NSArray *xq_dao_compact(NSArray *array, id (^block)(id obj));
extern void xq_dao_log(NSString *fmt, ...);

@interface NSObject (XQ_DAO_HELPER)

+ (BOOL)xq_dao_swizzleInstanceMethod:(SEL)originalSel with:(SEL)newSel;
+ (BOOL)xq_dao_swizzleClassMethod:(SEL)originalSel with:(SEL)newSel;

@end

