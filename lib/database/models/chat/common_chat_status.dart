import 'package:sqflite/sqflite.dart';

class CommonChatStatus {
  late int chatId; //主键，同时也是逻辑外键，与Chat表关联
  late int? lastMessageBeReadSendByMe; //最后一条由我（Chat持有者）发送的且被对方已读的消息的MessageId
  late DateTime? readTime; //已读时间
  late DateTime updatedTime; //状态最后一次更新的时间

  CommonChatStatus({
    required this.chatId,
    required this.lastMessageBeReadSendByMe,
    required this.readTime,
    required this.updatedTime,
  });

  CommonChatStatus.fromJson(Map<String, dynamic> map) {
    chatId = map['chatId'];
    lastMessageBeReadSendByMe = map['lastMessageBeReadSendByMe'];
    readTime = map['readTime'] == null ? null : DateTime.parse(map['readTime']);
    updatedTime = DateTime.parse(map['updatedTime']);
  }

  Map<String, dynamic> toSql() {
    return {
      'chatId': chatId,
      'lastMessageBeReadSendByMe': lastMessageBeReadSendByMe,
      'readTime': readTime?.millisecondsSinceEpoch,
      'updatedTime': updatedTime.millisecondsSinceEpoch,
    };
  }

  Map<String, dynamic> toUpdateSql() {
    return {
      'lastMessageBeReadSendByMe': lastMessageBeReadSendByMe,
      'readTime': readTime?.millisecondsSinceEpoch,
      'updatedTime': updatedTime.millisecondsSinceEpoch,
    };
  }

  CommonChatStatus.fromSql(Map<String, dynamic> map) {
    chatId = map['chatId'];
    lastMessageBeReadSendByMe = map['lastMessageBeReadSendByMe'];
    readTime = map['readTime'] == null ? null : DateTime.fromMillisecondsSinceEpoch(map['updatedTime']);
    updatedTime = DateTime.fromMillisecondsSinceEpoch(map['updatedTime']);
  }
}

class CommonChatStatusProvider {
  late Database database;

  CommonChatStatusProvider(this.database);

  Future<bool> insert(CommonChatStatus commonChatStatus) async {
    await database.insert('commonChatStatus', commonChatStatus.toSql());
    return true;
  }

  Future<bool> update(Map<String, dynamic> values, int chatId) async {
    await database.update('commonChatStatus', values, where: "chatId=?", whereArgs: [chatId]);
    return true;
  }

  Future<CommonChatStatus?> get(int chatId) async {
    List<Map<String, dynamic>> maps = await database.query('commonChatStatus', where: "chatId=?", whereArgs: [chatId]);
    if (maps.isNotEmpty) {
      return CommonChatStatus.fromSql(maps.first);
    }
    return null;
  }
}

class CommonChatStatusProviderWithTransaction {
  late Transaction transaction;

  CommonChatStatusProviderWithTransaction(this.transaction);

  Future<bool> insert(CommonChatStatus commonChatStatus) async {
    await transaction.insert('commonChatStatus', commonChatStatus.toSql());
    return true;
  }

  Future<bool> update(Map<String, dynamic> values, int chatId) async {
    await transaction.update('commonChatStatus', values, where: "chatId=?", whereArgs: [chatId]);
    return true;
  }

  Future<CommonChatStatus?> get(int chatId) async {
    List<Map<String, dynamic>> maps = await transaction.query('commonChatStatus', where: "chatId=?", whereArgs: [chatId]);
    if (maps.isNotEmpty) {
      return CommonChatStatus.fromSql(maps.first);
    }
    return null;
  }
}