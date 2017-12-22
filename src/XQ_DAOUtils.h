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

