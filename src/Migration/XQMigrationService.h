//
//  MigrationService.h
//  Lighting
//
//  Created by Xiongxunquan on 11/2/15.
//  Copyright © 2015 xunquan inc.. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XQMigrationService : NSObject

- (void)startMigrationFromVersion:(int32_t)fromVersion toVersion:(int32_t)toVersion;

@end
