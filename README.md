# XQ_DAO
基于 FMDB，十分方便、轻量的数据库组件，避免写 SQL 语句的烦恼

# 集成
```
pod XQ_DAO
```

## XQ_DAO 是一种基于 FMDB 的简单对象存储模型，支持面向对象的增删改查、批量增加数据、数据模型升级等特性
## XQ_DAO 十分方便集成，不需要集成任何类，对原有业务入侵小，非常轻便
### 使用方法

首先你得创建一个 User  实例

```
@interface User : NSObject <XQDBModel>

XQ_DB_PROPERTY

@property (copy, nonatomic) NSString *userName;
@property (copy, nonatomic) NSString *phone;
@property (strong, nonatomic) NSNumber *userId;
@property (strong, nonatomic) NSNumber *gender;
@property (copy, nonatomic) NSString *nick;
@property (copy, nonatomic) NSString *portrait;

@end



@implementation User

+ (void)load {
    XQDBModelConfiguration *configuration = [XQDBModelConfiguration configuration];
    [configuration addUniquesNotNull:@[PROP_TO_STRING(userId)]];
    self.xq_modelConfiguration = configuration;
    XQLog(@"[%@],[%@],[%@]",
          [self xq_uniquesNotNull],
          [self xq_notNullFields],
          [self xq_uniquesAbleNull]);
}

@end
```

以上，就简单创建了一个 User 的 Entity，同时规定了 userId 字段是唯一并且不允许为 nil。
然后，在 AppDelegate 的 didFinishLaunch 方法中，调用下面的方法：

```
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    //...
    [self.class setupDatabase];
    return YES;
}

+ (void)setupDatabase {
    XQMigrationService *migration = [XQMigrationService new];
    /*
    这创建 migration, migration 版本建议从1开始，这里表示是数据迁移的目标版本是 2
    migration.version = 2; //target version
    
    //db version 2
    {
        XQMigrationItemBase *migrationItem = [XQMigrationItemBase new];
        //表示为 User 表添加一个 userName 字段，类型为 String
        [migrationItem addField:@"userName" forTable:@"User" fieldType:FieldTypeString];
        [migration addMigrationItem:migrationItem version:2];
    }
    */
    [[XQFMDBManager defaultManager] setupDatabaseWithClasses:@[@"User",
                                                               //@"Entity1",
                                                               //@"Entity2",
                                                               //...
                                                               ]
                                            migrationService:migration];
}
```

然后就可以使用 User 这个 entity 了：
## 添加一份数据：

```
User *user = [User new];
user.userId = @1;
user.nick = @"昵称";
user.userName = @"小明";
[user xq_save];
```

## 查询这份数据：
```
User *user = [User xq_queryMakeCondition:^(XQSQLCondition *condition) {
	[condition andWhere:PROP_TO_STRING(userId) equal:@1];
}];
``` 
或者
```
NSArray<User *> *users = [User xq_queryModels];
```
## 批量增加数据：
```
NSMutableArray<User *> *users = [@[] mutableCopy];
for (NSUInteger idx = 0; idx < 5; ++idx) {
	User *user = [User new];
	user.nick = [NSString stringWithFormat:@"user_%@", @(self.datasource.count+1+idx)];
	user.userId = @(idx+100); //特别地，如果不写这句，控制台会报出警告，因为 userId 是唯一并且不允许为 nil 的
	[users addObject:model];
}
[User xq_saveObjectsInTransaction:models];
```
## 修改操作和增加数据操作一样

## 清空这个表
```
[User xq_clean];
```
## 删除一个数据
```
[User xq_deleteWhere:PROP_TO_STRING(userId) equal:@1]
```
## XQSQLCondition 用于生成 SQL 查询语句，是对 SQL 语句的简单抽象封装

