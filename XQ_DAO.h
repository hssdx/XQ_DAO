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
#import <Foundation/Foundation.h>

#if __has_include(<XQ_DAO/XQ_DAO.h>)

FOUNDATION_EXPORT double XQ_DAOVersionNumber;
FOUNDATION_EXPORT const unsigned char XQ_DAOVersionString[];


#import <XQKit/XQMigrationItemBase+Protect.h>
#import <XQKit/XQMigrationItemBase.h>
#import <XQKit/XQMigrationService.h>
#import <XQKit/XQDatabaseQueue.h>
#import <XQKit/XQFMDBManager.h>
#import <XQKit/XQSQLCondition.h>
#import <XQKit/NSArray+XQUtils.h>
#import <XQKit/XQDefaultsStoreBase.h>
#import <XQKit/XQEntityUtils.h>
#import <XQKit/XQModelBlocks.h>


#else


#import "XQKit/XQMigrationItemBase+Protect.h"
#import "XQKit/XQMigrationItemBase.h"
#import "XQKit/XQMigrationService.h"
#import "XQKit/XQDatabaseQueue.h"
#import "XQKit/XQFMDBManager.h"
#import "XQKit/XQSQLCondition.h"
#import "XQKit/NSArray+XQUtils.h"
#import "XQKit/XQDefaultsStoreBase.h"
#import "XQKit/XQEntityUtils.h"
#import "XQKit/XQModelBlocks.h"


#endif


