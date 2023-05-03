import 'package:sqflite/sqflite.dart';

class CommonChatStatus {
  late int id; //主键
  late int uuid; //标识这条Status记录属于谁
  late int chatId; //外键，与Chat表关联
  late int? lastMessageSendByMe; //最后一条由我（Chat持有者）发送的消息的MessageId
  late bool? isRead; //对方（Chat中的Target）是否已读我（Chat持有者）发送的最后一条消息
  late DateTime? readTime; //已读时间
  late DateTime updatedTime; //状态最后一次更新的时间

  CommonChatStatus({
    required this.id,
    required this.uuid,
    required this.chatId,
    required this.lastMessageSendByMe,
    required this.isRead,
    required this.readTime,
    required this.updatedTime,
  });

  CommonChatStatus.fromJson(Map<String, dynamic> map) {
    id = map['id'];
    uuid = map['uuid'];
    chatId = map['chatId'];
    lastMessageSendByMe = map['lastMessageSendByMe'];
    isRead = map['isRead'];
    readTime = map['readTime'] == null ? null : DateTime.parse(map['readTime']);
    updatedTime = DateTime.parse(map['updatedTime']);
  }

  Map<String, dynamic> toSql() {
    return {
      'id': id,
      'uuid': uuid,
      'chatId': chatId,
      'lastMessageSendByMe': lastMessageSendByMe,
      'isRead': isRead == null
          ? null
          : isRead!
              ? 1
              : 0,
      'readTime': readTime?.millisecondsSinceEpoch,
      'updatedTime': updatedTime.millisecondsSinceEpoch,
    };
  }

  Map<String, dynamic> toUpdateSql() {
    return {
      'lastMessageSendByMe': lastMessageSendByMe,
      'isRead': isRead == null
          ? null
          : isRead!
              ? 1
              : 0,
      'readTime': readTime?.millisecondsSinceEpoch,
      'updatedTime': updatedTime.millisecondsSinceEpoch,
    };
  }

  CommonChatStatus.fromSql(Map<String, dynamic> map) {
    id = map['id'];
    uuid = map['uuid'];
    chatId = map['chatId'];
    lastMessageSendByMe = map['lastMessageSendByMe'];
    isRead = map['isRead'] == null ? null : map['isRead'] > 0;
    readTime = map['readTime'] == null ? null : DateTime.parse(map['readTime']);
    updatedTime = DateTime.fromMillisecondsSinceEpoch(map['updatedTime']);
  }
}

class CommonChatStatusProvider {
  late Database database;

  CommonChatStatusProvider(this.database);
}

class CommonChatStatusProviderWithTransaction {
  late Transaction transaction;

  CommonChatStatusProviderWithTransaction(this.transaction);

  Future<bool> insert(CommonChatStatus commonChatStatus) async {
    await transaction.insert('commonChatStatus', commonChatStatus.toSql());
    return true;
  }

  Future<bool> update(Map<String, dynamic> values, int id) async {
    await transaction.update('commonChatStatus', values, where: "id=?", whereArgs: [id]);
    return true;
  }

  Future<CommonChatStatus?> get(int id) async {
    List<Map<String, dynamic>> maps = await transaction.query('commonChatStatus', where: "id=?", whereArgs: [id]);
    if (maps.isNotEmpty) {
      return CommonChatStatus.fromSql(maps.first);
    }
    return null;
  }
}