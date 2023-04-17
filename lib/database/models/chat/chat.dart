import 'package:sqflite/sqflite.dart';

class Chat {
  late int chatId; //主键
  late int targetId; //标识这条Chat记录是主体与谁进行的，客体的UUID，客体可以是OtherUser、Group、System
  late bool isWithOtherUser; //客体是OtherUser
  late bool isWithGroup; //客体是Group
  late bool isWithSystem; //客体是System
  late bool isStickyOnTop; //主体是否将与客体的对话置顶
  late bool isDeleted; //主体是否已将与客体的对话删除（暂时不显示在消息列表中，直到对话中下一条消息产生）
  late int numberOfUnreadMessages; //该会话中主体的未读消息数
  late int? lastMessageId; //该会话中最新一条消息的消息Id
  late bool isRead; //该会话中的最新一条消息是否已读
  late DateTime updatedTime; //该会话状态最后一次更新的时间

  Chat(
      {required this.chatId,
      required this.targetId,
      this.isWithOtherUser = false,
      this.isWithGroup = false,
      this.isWithSystem = false,
      this.isStickyOnTop = false,
      this.isDeleted = false,
      required this.numberOfUnreadMessages,
      this.lastMessageId,
      this.isRead = false,
      required this.updatedTime});

  Chat.fromJson(Map<String, dynamic> map) {
    chatId = map['chatId'];
    targetId = map['targetId'];
    isWithOtherUser = map['isWithOtherUser'];
    isWithGroup = map['isWithGroup'];
    isWithSystem = map['isWithSystem'];
    isStickyOnTop = map['isStickyOnTop'];
    isDeleted = map['isDeleted'];
    numberOfUnreadMessages = map['numberOfUnreadMessages'];
    lastMessageId = map['lastMessageId'];
    isRead = map['isRead'];
    updatedTime = DateTime.parse(map['updatedTime']);
  }

  Map<String, dynamic> toSql() {
    return {
      'chatId': chatId,
      'targetId': targetId,
      'isWithOtherUser': isWithOtherUser ? 1 : 0,
      'isWithGroup': isWithGroup ? 1 : 0,
      'isWithSystem': isWithSystem ? 1 : 0,
      'isStickyOnTop': isStickyOnTop ? 1 : 0,
      'isDeleted': isDeleted ? 1 : 0,
      'numberOfUnreadMessages': numberOfUnreadMessages,
      'lastMessageId': lastMessageId,
      'isRead': isRead ? 1 : 0,
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
      'isRead': isRead ? 1 : 0,
      'updatedTime': updatedTime.millisecondsSinceEpoch,
    };
  }

  Chat.fromSql(Map<String, dynamic> map) {
    chatId = map['chatId'];
    targetId = map['targetId'];
    isWithOtherUser = map['isWithOtherUser'] > 0;
    isWithGroup = map['isWithGroup'] > 0;
    isWithSystem = map['isWithSystem'] > 0;
    isStickyOnTop = map['isStickyOnTop'] > 0;
    isDeleted = map['isDeleted'] > 0;
    numberOfUnreadMessages = map['numberOfUnreadMessages'];
    lastMessageId = map['lastMessageId'];
    isRead = map['isRead'] > 0;
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

  Future<bool> update(Map<String, dynamic> values, int chatId) async {
    await database.update('chat', values, where: "chatId=?", whereArgs: [chatId]);
    return true;
  }

  Future<Chat?> get(int chatId) async {
    List<Map<String, dynamic>> maps = await database.query('chat', where: "chatId=?", whereArgs: [chatId]);
    if (maps.isNotEmpty) {
      return Chat.fromSql(maps.first);
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

  Future<Chat?> getNotDeleted(int chatId) async {
    List<Map<String, dynamic>> maps = await database.query('chat', where: "chatId=? & isDeleted=0", whereArgs: [chatId]);
    if (maps.isNotEmpty) {
      return Chat.fromSql(maps.first);
    }
    return null;
  }

  Future<List<Chat>> getAllNotDeleted() async {
    List<Chat> chats = [];
    List<Map<String, dynamic>> maps = await database.query('chat', where: "isDeleted=0");
    if (maps.isNotEmpty) {
      for (var element in maps) {
        chats.add(Chat.fromSql(element));
      }
    }
    return chats;
  }
}

class ChatProviderWithTransaction{
  late Transaction transaction;

  ChatProviderWithTransaction(this.transaction);

  Future<bool> insert(Chat chat) async {
    await transaction.insert('chat', chat.toSql());
    return true;
  }

  Future<bool> update(Map<String, dynamic> values, int chatId) async {
    await transaction.update('chat', values, where: "chatId=?", whereArgs: [chatId]);
    return true;
  }

  Future<Chat?> get(int chatId) async {
    List<Map<String, dynamic>> maps = await transaction.query('chat', where: "chatId=?", whereArgs: [chatId]);
    if (maps.isNotEmpty) {
      return Chat.fromSql(maps.first);
    }
    return null;
  }
}
