import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

//单例模式构建DatabaseManager
class DatabaseManager {
  static final DatabaseManager _instance = DatabaseManager._();

  DatabaseManager._();

  factory DatabaseManager() {
    return _instance;
  }

  //登录时决定选择使用的数据库（以登录用户的UUID命名）
  static String? _databaseName;
  static Database? _database;

  //由开发者定义版本，数据库架构发生改变时可以进行迁移
  static const int _version = 1;

  setDatabaseName(String databaseName) {
    _databaseName = databaseName;
  }

  getDatabaseName() {
    return _databaseName;
  }

  //退出登录时，将_database置为空并关闭数据库连接
  closeDatabase() async {
    _database = null;
    await _database?.close();
  }

  //删除整个数据库
  dropDatabase() async {
    await deleteDatabase(
      join(await getDatabasesPath(), _databaseName),
    );
  }

  Future<Database> get getDatabase async {
    return _database ??= await _initDatabase();
  }

  Future<Database> _initDatabase() async {
    return await openDatabase(
      join(await getDatabasesPath(), _databaseName),
      version: _version,
      //首次创建数据库时，将调用_onCreate方法，并标注数据库版本号为_version
      onCreate: _onCreate,
      //如果传入的版本号高于当前该数据库使用的版本，那么将调用_onUpgrade方法
      onUpgrade: _onUpgrade,
      //如果传入的版本号低于当前该数据库使用的版本，那么将删除数据库并重新调用_onCreate方法
      onDowngrade: onDatabaseDowngradeDelete,
    );
  }

  _onCreate(Database database, int version) async {
    await database.execute('CREATE TABLE briefUserInformation(uuid INTEGER PRIMARY KEY, avatar TEXT, nickname TEXT,updatedTime INTEGER)');
    await database.execute('CREATE TABLE systemPromotion(uuid INTEGER PRIMARY KEY, avatar TEXT, name TEXT,miniAppId TEXT,updatedTime INTEGER)');
    await database.execute(
        'CREATE TABLE userSyncTable(id INTEGER PRIMARY KEY,uuid INTEGER,sequenceForCommonMessages INTEGER,sequenceForSystemMessages INTEGER,updatedTimeForFriendsGroups INTEGER,updatedTimeForFriendships INTEGER,updatedTimeForChats INTEGER,lastSyncTimeForCommonChatStatuses INTEGER,lastSyncTimeForFriendsBriefInformation INTEGER,lastSyncTimeForSystemPromotionInformation INTEGER)');
    await database.execute('CREATE TABLE friendsGroup(id INTEGER PRIMARY KEY,uuid INTEGER,orderNumber INTEGER,friendsGroupName TEXT,isDeleted INTEGER,updatedTime INTEGER)');
    await database.execute(
        'CREATE TABLE friendship(id INTEGER PRIMARY KEY,uuid INTEGER,friendsGroupId INTEGER,friendId INTEGER,shipCreatedTime INTEGER,remark TEXT,isFocus INTEGER,isDeleted INTEGER,updatedTime INTEGER)');
    await database.execute(
        'CREATE TABLE chat(id INTEGER PRIMARY KEY,uuid INTEGER,targetId INTEGER,isWithOtherUser INTEGER,isWithGroup INTEGER,isWithSystem INTEGER,isStickyOnTop INTEGER,isDeleted INTEGER,numberOfUnreadMessages INTEGER,lastMessageId INTEGER,updatedTime INTEGER)');
    await database.execute('CREATE TABLE commonChatStatus(chatId INTEGER PRIMARY KEY,lastMessageBeReadSendByMe INTEGER,readTime INTEGER,updatedTime INTEGER)');
    await database.execute(
        'CREATE TABLE commonMessage(id INTEGER PRIMARY KEY,chatId INTEGER,senderId INTEGER,receiverId INTEGER,createdTime INTEGER,isCustom INTEGER,isRecalled INTEGER,isDeleted INTEGER,isReply INTEGER,isMediaMessage INTEGER,isVoiceMessage INTEGER,customType TEXT,minimumSupportVersion TEXT,textOnError TEXT,customMessageContent TEXT,messageReplied INTEGER,messageText TEXT,messageMedias TEXT,messageVoice TEXT,sequence INTEGER)');
    await database.execute(
        'CREATE TABLE systemMessage(id INTEGER PRIMARY KEY,chatId INTEGER,senderId INTEGER,receiverId INTEGER,createdTime INTEGER,isCustom INTEGER,isRecalled INTEGER,isDeleted INTEGER,isReply INTEGER,isMediaMessage INTEGER,isVoiceMessage INTEGER,customType TEXT,minimumSupportVersion TEXT,textOnError TEXT,customMessageContent TEXT,messageReplied INTEGER,messageText TEXT,messageMedias TEXT,messageVoice TEXT,sequence INTEGER)');
    await database
        .execute('CREATE TABLE briefMiniAppInformation(id TEXT PRIMARY KEY, type TEXT, name TEXT, avatar TEXT, routingURL TEXT, url TEXT, minimumSupportVersion TEXT, lastOpenedTime INTEGER)');
    //await database.execute("");
    //await database.execute("");
  }

  _onUpgrade(Database database, int oldVersion, int newVersion) async {
    // if(oldVersion == 1){
    //   await database.execute("");
    // }
  }
}
