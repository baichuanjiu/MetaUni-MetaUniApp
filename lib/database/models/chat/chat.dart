import 'package:sqflite/sqflite.dart';

class Chat {
  late int id; //主键
  late int uuid; //标识这条Chat记录属于谁，主体的UUID
  late int targetId; //标识这条Chat记录是主体与谁进行的，客体的UUID，客体可以是OtherUser、Group、System
  late bool isWithOtherUser; //客体是OtherUser
  late bool isWithGroup; //客体是Group
  late bool isWithSystem; //客体是System
  late bool isStickyOnTop; //主体是否将与客体的对话置顶
  late bool isDeleted; //主体是否已将与客体的对话删除（暂时不显示在消息列表中，直到对话中下一条消息产生）
  late int numberOfUnreadMessages; //该会话中主体的未读消息数
  late int? lastMessageId; //该会话中最新一条消息的消息Id
  late DateTime updatedTime; //该会话状态最后一次更新的时间

  Chat({
    required this.id,
    required this.uuid,
    required this.targetId,
    this.isWithOtherUser = false,
    this.isWithGroup = false,
    this.isWithSystem = false,
    this.isStickyOnTop = false,
    this.isDeleted = false,
    required this.numberOfUnreadMessages,
    this.lastMessageId,
    required this.updatedTime,
  });

  Chat.fromJson(Map<String, dynamic> map) {
    id = map['id'];
    uuid = map['uuid'];
    targetId = map['targetId'];
    isWithOtherUser = map['isWithOtherUser'];
    isWithGroup = map['isWithGroup'];
    isWithSystem = map['isWithSystem'];
    isStickyOnTop = map['isStickyOnTop'];
    isDeleted = map['isDeleted'];
    numberOfUnreadMessages = map['numberOfUnreadMessages'];
    lastMessageId = map['lastMessageId'];
    updatedTime = DateTime.parse(map['updatedTime']);
  }

  Map<String, dynamic> toSql() {
    return {
      'id': id,
      'uuid': uuid,
      'targetId': targetId,
      'isWithOtherUser': isWithOtherUser ? 1 : 0,
      'isWithGroup': isWithGroup ? 1 : 0,
      'isWithSystem': isWithSystem ? 1 : 0,
      'isStickyOnTop': isStickyOnTop ? 1 : 0,
      'isDeleted': isDeleted ? 1 : 0,
      'numberOfUnreadMessages': numberOfUnreadMessages,
      'lastMessageId': lastMessageId,
      'updatedTime': updatedTime.millisecondsSinceEpoch,
    };
  }

  Map<String, dynamic> toUpdateSql() {
    return {
      'targetId': targetId,
      'isWithOtherUser': isWithOtherUser ? 1 : 0,
      'isWithGroup': isWithGroup ? 1 : 0,
      'isWithSystem': isWithSystem ? 1 : 0,
      'isStickyOnTop': isStickyOnTop ? 1 : 0,
      'isDeleted': isDeleted ? 1 : 0,
      'numberOfUnreadMessages': numberOfUnreadMessages,
      'lastMessageId': lastMessageId,
      'updatedTime': updatedTime.millisecondsSinceEpoch,
    };
  }

  Chat.fromSql(Map<String, dynamic> map) {
    id = map['id'];
    uuid = map['uuid'];
    targetId = map['targetId'];
    isWithOtherUser = map['isWithOtherUser'] > 0;
    isWithGroup = map['isWithGroup'] > 0;
    isWithSystem = map['isWithSystem'] > 0;
    isStickyOnTop = map['isStickyOnTop'] > 0;
    isDeleted = map['isDeleted'] > 0;
    numberOfUnreadMessages = map['numberOfUnreadMessages'];
    lastMessageId = map['lastMessageId'];
    updatedTime = DateTime.fromMillisecondsSinceEpoch(map['updatedTime']);
  }
}

class ChatProvider {
  late Database database;

  ChatProvider(this.database);

  Future<bool> insert(Chat chat) async {
    await database.insert('chat', chat.toSql());
    return true;
  }

  Future<bool> update(Map<String, dynamic> values, int id) async {
    await database.update('chat', values, where: "id=?", whereArgs: [id]);
    return true;
  }

  Future<bool> changeStickyStatus(bool isStickyOnTop, int id) async {
    await database.update('chat', {"isStickyOnTop": isStickyOnTop ? 1 : 0}, where: "id=?", whereArgs: [id]);
    return true;
  }

  Future<bool> delete(int id) async {
    await database.update('chat', {"isDeleted": 1}, where: "id=?", whereArgs: [id]);
    return true;
  }

  Future<Chat?> get(int id) async {
    List<Map<String, dynamic>> maps = await database.query('chat', where: "id=?", whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Chat.fromSql(maps.first);
    }
    return null;
  }

  Future<int?> getWithUserNotDeleted(int targetId) async {
    List<Map<String, dynamic>> maps = await database.query('chat', columns: ["id"], where: "targetId=? and isWithOtherUser=1 and isDeleted=0", whereArgs: [targetId]);
    if (maps.isNotEmpty) {
      return maps.first["id"];
    }
    return null;
  }

  Future<List<Chat>> getAll() async {
    List<Chat> chats = [];
    List<Map<String, dynamic>> maps = await database.query('chat');
    if (maps.isNotEmpty) {
      for (var element in maps) {
        chats.add(Chat.fromSql(element));
      }
    }
    return chats;
  }

  Future<Chat?> getNotDeleted(int id) async {
    List<Map<String, dynamic>> maps = await database.query('chat', where: "id=? and isDeleted=0", whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Chat.fromSql(maps.first);
    }
    return null;
  }

  Future<List<Chat>> getAllNotDeletedOrderByIsStickyOnTop() async {
    List<Chat> chats = [];
    List<Map<String, dynamic>> maps = await database.query('chat', where: "isDeleted=0", orderBy: "isStickyOnTop DESC");
    if (maps.isNotEmpty) {
      for (var element in maps) {
        chats.add(Chat.fromSql(element));
      }
    }
    return chats;
  }

  Future<int> getTotalNumberOfUnreadMessages() async {
    List<Map<String, dynamic>> maps = await database.query('chat', columns: ["numberOfUnreadMessages"], where: "isDeleted=0");
    int number = 0;
    for (var element in maps) {
      number += element["numberOfUnreadMessages"] as int;
    }
    return number;
  }

  Future<int> getNumberOfUnreadMessages(int id) async {
    List<Map<String, dynamic>> maps = await database.query('chat', columns: ["numberOfUnreadMessages"], where: "id=?", whereArgs: [id]);
    return maps.first["numberOfUnreadMessages"];
  }

  Future<int> readMessages(int id) async {
    List<Map<String, dynamic>> maps = await database.query('chat', columns: ["numberOfUnreadMessages"], where: "id=?", whereArgs: [id]);
    int numberOfUnreadMessages = maps.first["numberOfUnreadMessages"];
    await database.update(
        'chat',
        {
          'numberOfUnreadMessages': 0,
        },
        where: "id=?",
        whereArgs: [id]);
    return numberOfUnreadMessages;
  }
}

class ChatProviderWithTransaction {
  late Transaction transaction;

  ChatProviderWithTransaction(this.transaction);

  Future<bool> insert(Chat chat) async {
    await transaction.insert('chat', chat.toSql());
    return true;
  }

  Future<bool> update(Map<String, dynamic> values, int id) async {
    await transaction.update('chat', values, where: "id=?", whereArgs: [id]);
    return true;
  }

  Future<Chat?> get(int id) async {
    List<Map<String, dynamic>> maps = await transaction.query('chat', where: "id=?", whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Chat.fromSql(maps.first);
    }
    return null;
  }

  Future<int> readMessages(int id) async {
    List<Map<String, dynamic>> maps = await transaction.query('chat', columns: ["numberOfUnreadMessages"], where: "id=?", whereArgs: [id]);
    int numberOfUnreadMessages = maps.first["numberOfUnreadMessages"];
    await transaction.update(
        'chat',
        {
          'numberOfUnreadMessages': 0,
        },
        where: "id=?",
        whereArgs: [id]);
    return numberOfUnreadMessages;
  }
}
