import 'package:sqflite/sqflite.dart';

class SystemMessage {
  late int id; //消息ID，一条消息记录的唯一标识
  late int chatId; //会话ID，标识这条消息属于哪个会话
  late int senderId; //消息发送者的ID
  late int receiverId; //消息接收者的ID
  late DateTime createdTime; //消息产生时间
  late bool isCustom; //是否是特殊消息
  late bool isRecalled; //是否已被撤回
  late bool isDeleted; //是否已被删除
  late bool isReply; //是否是某条消息的回复
  late bool isMediaMessage; //是否是带有图像或视频的消息
  late bool isVoiceMessage; //是否是语音消息
  late String? customType; //特殊消息类型
  late String? minimumSupportVersion; //特殊消息最低支持的应用版本
  late String? textOnError; //特殊消息不支持时，显示的文字
  late String? customMessageContent; //特殊消息内容，为JSON形式存储的字符串
  late int? messageReplied; //回复的某条消息的消息ID
  late String? messageText; //消息的文本内容
  late String? messageMedias; //消息附带的图像或视频，以JSON形式存储的对象数组，数组内容为图像或视频资源存储地址及其它需要的属性
  late String? messageVoice; //以JSON形式存储的对象，对象内容为语音消息资源存储地址以及其它需要的属性
  late int sequence; //该SystemMessage对于消息所有者来说的Sequence，用于消息对齐

  SystemMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.receiverId,
    required this.createdTime,
    this.isCustom = false,
    this.isRecalled = false,
    this.isDeleted = false,
    this.isReply = false,
    this.isMediaMessage = false,
    this.isVoiceMessage = false,
    this.customType,
    this.minimumSupportVersion,
    this.textOnError,
    this.customMessageContent,
    this.messageReplied,
    this.messageText,
    this.messageMedias,
    this.messageVoice,
    required this.sequence,
  });

  SystemMessage.fromJson(Map<String, dynamic> map) {
    id = map['id'];
    chatId = map['chatId'];
    senderId = map['senderId'];
    receiverId = map['receiverId'];
    createdTime = DateTime.parse(map['createdTime']);
    isCustom = map['isCustom'];
    isRecalled = map['isRecalled'];
    isDeleted = map['isDeleted'];
    isReply = map['isReply'];
    isMediaMessage = map['isMediaMessage'];
    isVoiceMessage = map['isVoiceMessage'];
    customType = map['customType'];
    minimumSupportVersion = map['minimumSupportVersion'];
    textOnError = map['textOnError'];
    customMessageContent = map['customMessageContent'];
    messageReplied = map['messageReplied'];
    messageText = map['messageText'];
    messageMedias = map['messageMedias'];
    messageVoice = map['messageVoice'];
    sequence = map['sequence'];
  }

  Map<String, dynamic> toSql() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'receiverId': receiverId,
      'createdTime': createdTime.millisecondsSinceEpoch,
      'isCustom': isCustom ? 1 : 0,
      'isRecalled': isRecalled ? 1 : 0,
      'isDeleted': isDeleted ? 1 : 0,
      'isReply': isReply ? 1 : 0,
      'isMediaMessage': isMediaMessage ? 1 : 0,
      'isVoiceMessage': isVoiceMessage ? 1 : 0,
      'customType': customType,
      'minimumSupportVersion': minimumSupportVersion,
      'textOnError': textOnError,
      'customMessageContent': customMessageContent,
      'messageReplied': messageReplied,
      'messageText': messageText,
      'messageMedias': messageMedias,
      'messageVoice': messageVoice,
      'sequence': sequence,
    };
  }

  SystemMessage.fromSql(Map<String, dynamic> map) {
    id = map['id'];
    chatId = map['chatId'];
    senderId = map['senderId'];
    receiverId = map['receiverId'];
    createdTime = DateTime.fromMillisecondsSinceEpoch(map['createdTime']);
    isCustom = map['isCustom'] > 0;
    isRecalled = map['isRecalled'] > 0;
    isDeleted = map['isDeleted'] > 0;
    isReply = map['isReply'] > 0;
    isMediaMessage = map['isMediaMessage'] > 0;
    isVoiceMessage = map['isVoiceMessage'] > 0;
    customType = map['customType'];
    minimumSupportVersion = map['minimumSupportVersion'];
    textOnError = map['textOnError'];
    customMessageContent = map['customMessageContent'];
    messageReplied = map['messageReplied'];
    messageText = map['messageText'];
    messageMedias = map['messageMedias'];
    messageVoice = map['messageVoice'];
    sequence = map['sequence'];
  }
}

class SystemMessageProvider {
  late Database database;

  SystemMessageProvider(this.database);

  Future<SystemMessage?> get(int id) async {
    List<Map<String, dynamic>> maps = await database.query('systemMessage', where: "id=?", whereArgs: [id]);
    if (maps.isNotEmpty) {
      return SystemMessage.fromSql(maps.first);
    }
    return null;
  }

  Future<List<SystemMessage>> getHistoryMessagesNotDeletedOrderByIdByLastId(int chatId, int? lastId, int count) async {
    List<SystemMessage> messages = [];
    List<Map<String, dynamic>> maps;
    if (lastId == null) {
      maps = await database.query('systemMessage', where: "chatId=? and isDeleted=0", whereArgs: [chatId], orderBy: "id DESC", limit: count);
    } else {
      maps = await database.query('systemMessage', where: "chatId=? and isDeleted=0 and id<?", whereArgs: [chatId, lastId], orderBy: "id DESC", limit: count);
    }
    if (maps.isNotEmpty) {
      for (var element in maps) {
        messages.add(SystemMessage.fromSql(element));
      }
    }
    return messages;
  }
}

class SystemMessageProviderWithTransaction {
  late Transaction transaction;

  SystemMessageProviderWithTransaction(this.transaction);

  Future<bool> insert(SystemMessage systemMessage) async {
    await transaction.insert('systemMessage', systemMessage.toSql());
    return true;
  }

  Future<bool> update(Map<String, dynamic> values, int id) async {
    await transaction.update('systemMessage', values, where: "id=?", whereArgs: [id]);
    return true;
  }

  Future<SystemMessage?> get(int id) async {
    List<Map<String, dynamic>> maps = await transaction.query('systemMessage', where: "id=?", whereArgs: [id]);
    if (maps.isNotEmpty) {
      return SystemMessage.fromSql(maps.first);
    }
    return null;
  }

  Future<bool> hasThisMessage(int id) async {
    List<Map<String, dynamic>> maps = await transaction.query('systemMessage', columns: ["id"], where: "id=?", whereArgs: [id]);
    if (maps.isNotEmpty) {
      return true;
    }
    return false;
  }
}
