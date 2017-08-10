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
//  XQDatabaseQueue.h
//  fmdb
//
//  Created by August Mueller on 6/22/11.
//  Copyright 2011 Flying Meat Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class FMDatabase;

@interface XQDatabaseQueue : NSObject

- (BOOL)isNestedQueue;

/** Path of database */

@property (atomic, retain, nullable) NSString *path;

/** Open flags */

@property (atomic, readonly) int openFlags;

/**  Custom virtual file system name */

@property (atomic, copy, nullable) NSString *vfsName;

///----------------------------------------------------
/// @name Initialization, opening, and closing of queue
///----------------------------------------------------

/** Create queue using path.
 
 @param aPath The file path of the database.
 
 @return The `XQDatabaseQueue` object. `nil` on error.
 */

+ (instancetype)databaseQueueWithPath:(NSString * _Nullable)aPath;

/** Create queue using file URL.
 
 @param url The file `NSURL` of the database.
 
 @return The `XQDatabaseQueue` object. `nil` on error.
 */

+ (instancetype)databaseQueueWithURL:(NSURL * _Nullable)url;

/** Create queue using path and specified flags.
 
 @param aPath The file path of the database.
 @param openFlags Flags passed to the openWithFlags method of the database.
 
 @return The `XQDatabaseQueue` object. `nil` on error.
 */
+ (instancetype)databaseQueueWithPath:(NSString * _Nullable)aPath flags:(int)openFlags;

/** Create queue using file URL and specified flags.
 
 @param url The file `NSURL` of the database.
 @param openFlags Flags passed to the openWithFlags method of the database.
 
 @return The `XQDatabaseQueue` object. `nil` on error.
 */
+ (instancetype)databaseQueueWithURL:(NSURL * _Nullable)url flags:(int)openFlags;

/** Create queue using path.
 
 @param aPath The file path of the database.
 
 @return The `XQDatabaseQueue` object. `nil` on error.
 */

- (instancetype)initWithPath:(NSString * _Nullable)aPath;

/** Create queue using file URL.
 
 @param url The file `NSURL of the database.
 
 @return The `XQDatabaseQueue` object. `nil` on error.
 */

- (instancetype)initWithURL:(NSURL * _Nullable)url;

/** Create queue using path and specified flags.
 
 @param aPath The file path of the database.
 @param openFlags Flags passed to the openWithFlags method of the database.
 
 @return The `XQDatabaseQueue` object. `nil` on error.
 */

- (instancetype)initWithPath:(NSString * _Nullable)aPath flags:(int)openFlags;

/** Create queue using file URL and specified flags.
 
 @param url The file path of the database.
 @param openFlags Flags passed to the openWithFlags method of the database.
 
 @return The `XQDatabaseQueue` object. `nil` on error.
 */

- (instancetype)initWithURL:(NSURL * _Nullable)url flags:(int)openFlags;

/** Create queue using path and specified flags.
 
 @param aPath The file path of the database.
 @param openFlags Flags passed to the openWithFlags method of the database
 @param vfsName The name of a custom virtual file system
 
 @return The `XQDatabaseQueue` object. `nil` on error.
 */

- (instancetype)initWithPath:(NSString * _Nullable)aPath flags:(int)openFlags vfs:(NSString * _Nullable)vfsName;

/** Create queue using file URL and specified flags.
 
 @param url The file `NSURL of the database.
 @param openFlags Flags passed to the openWithFlags method of the database
 @param vfsName The name of a custom virtual file system
 
 @return The `XQDatabaseQueue` object. `nil` on error.
 */

- (instancetype)initWithURL:(NSURL * _Nullable)url flags:(int)openFlags vfs:(NSString * _Nullable)vfsName;

/** Returns the Class of 'FMDatabase' subclass, that will be used to instantiate database object.
 
 Subclasses can override this method to return specified Class of 'FMDatabase' subclass.
 
 @return The Class of 'FMDatabase' subclass, that will be used to instantiate database object.
 */

+ (Class)databaseClass;

/** Close database used by queue. */

- (void)close;

/** Interupt pending database operation. */

- (void)interrupt;

///-----------------------------------------------
/// @name Dispatching database operations to queue
///-----------------------------------------------

/** Synchronously perform database operations on queue.
 
 @param block The code to be run on the queue of `XQDatabaseQueue`
 */

- (void)inDatabase:(__attribute__((noescape)) void (^)(FMDatabase *db))block;

/** Synchronously perform database operations on queue, using transactions.

 @param block The code to be run on the queue of `XQDatabaseQueue`
 */

- (void)inTransaction:(__attribute__((noescape)) void (^)(FMDatabase *db, BOOL *rollback))block;

/** Synchronously perform database operations on queue, using deferred transactions.

 @param block The code to be run on the queue of `XQDatabaseQueue`
 */

- (void)inDeferredTransaction:(__attribute__((noescape)) void (^)(FMDatabase *db, BOOL *rollback))block;

///-----------------------------------------------
/// @name Dispatching database operations to queue
///-----------------------------------------------

/** Synchronously perform database operations using save point.

 @param block The code to be run on the queue of `XQDatabaseQueue`
 */

// NOTE: you can not nest these, since calling it will pull another database out of the pool and you'll get a deadlock.
// If you need to nest, use FMDatabase's startSavePointWithName:error: instead.
- (NSError * _Nullable)inSavePoint:(__attribute__((noescape)) void (^)(FMDatabase *db, BOOL *rollback))block;

@end

NS_ASSUME_NONNULL_END
