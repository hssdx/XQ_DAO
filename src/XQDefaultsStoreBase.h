//
//  XQDefaultsStoreBase.h
//  xunquan
//
//  Created by quanxiong on 16/6/12.
//  Copyright © 2016年 xunquan inc.. All rights reserved.
//

#import <Foundation/Foundation.h>


#define UD_PROP_TO_STRING(PROP_NAME) [NSString stringWithFormat:@"FPUserDefault_%@", PROP_TO_STRING(PROP_NAME)]

#define IMP_GETTER_SETTER(GETTER, SETTER) IMP_GETTER_SETTER_SETTER_EXTENSION(GETTER, SETTER, ;)

#define IMP_GETTER_SETTER_SETTER_EXTENSION(GETTER, SETTER, SETTER_EXTENSION) \
@synthesize GETTER = _##GETTER; \
- (void)SETTER:(id)GETTER { \
    @synchronized (self) { \
        _##GETTER = GETTER; \
        [self.userDefaults setObject:_##GETTER forKey:UD_PROP_TO_STRING(GETTER)]; \
        SETTER_EXTENSION \
        [self synchronize]; \
    }; \
} \
\
- (id)GETTER { \
    @synchronized (self) { \
        if (!_##GETTER) { \
            _##GETTER = [self.userDefaults objectForKey:UD_PROP_TO_STRING(GETTER)]; \
        } \
    }; \
    return _##GETTER; \
}

@interface XQDefaultsStoreBase : NSObject

+ (instancetype)sharedStore;
- (NSUserDefaults *)userDefaults;
- (BOOL)synchronize;
/**
 *  archive
 */
+ (BOOL)archiveObject:(id)object withKey:(NSString *)key;
+ (id)unarchiveObjectWithKey:(NSString *)key;
@end
