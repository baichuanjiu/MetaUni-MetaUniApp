import 'package:sqflite/sqflite.dart';

class CommonMessage {
  late int id; //消息ID，一条消息记录的唯一标识
  late int chatId; //会话ID，标识这条消息属于哪个会话
  late int senderId; //消息发送者的ID
  late int receiverId; //消息接收者的ID
  late DateTime createdTime; //消息产生时间
  late bool isCustom; //是否是特殊消息
  late bool isRecalled; //是否已被撤回
  late bool isDeleted; //是否已被删除
  late bool isReply; //是否是某条消息的回复
  late bool isImageMessage; //是否是带有图片的消息
  late bool isVoiceMessage; //是否是语音消息
  late bool isRead; //是否已读
  late String? customType; //特殊消息类型
  late String? minimumSupportVersion; //特殊消息最低支持的应用版本
  late String? textOnError; //特殊消息不支持时，显示的文字
  late String? customMessageContent; //特殊消息内容，为JSON形式存储的字符串
  late int? messageReplied; //回复的某条消息的消息ID
  late String? messageText; //消息的文本内容
  late String? messageImage; //消息附带的图片，以JSON形式存储的字符串数组，数组内容为图片资源存储地址
  late String? messageVoice; //语音消息资源存储地址
  late int sequence; //该CommonMessage对于消息所有者来说的Sequence，用于消息对齐

  CommonMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.receiverId,
    required this.createdTime,
    this.isCustom = false,
    this.isRecalled = false,
    this.isDeleted = false,
    this.isReply = false,
    this.isImageMessage = false,
    this.isVoiceMessage = false,
    this.isRead = false,
    this.customType,
    this.minimumSupportVersion,
    this.textOnError,
    this.customMessageContent,
    this.messageReplied,
    this.messageText,
    this.messageImage,
    this.messageVoice,
    required this.sequence,
  });

  CommonMessage.fromJson(Map<String, dynamic> map) {
    id = map['id'];
    chatId = map['chatId'];
    senderId = map['senderId'];
    receiverId = map['receiverId'];
    createdTime = DateTime.parse(map['createdTime']);
    isCustom = map['isCustom'];
    isRecalled = map['isRecalled'];
    isDeleted = map['isDeleted'];
    isReply = map['isReply'];
    isImageMessage = map['isImageMessage'];
    isVoiceMessage = map['isVoiceMessage'];
    isRead = map['isRead'];
    customType = map['customType'];
    minimumSupportVersion = map['minimumSupportVersion'];
    textOnError = map['textOnError'];
    customMessageContent = map['customMessageContent'];
    messageReplied = map['messageReplied'];
    messageText = map['messageText'];
    messageImage = map['messageImage'];
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
      'isImageMessage': isImageMessage ? 1 : 0,
      'isVoiceMessage': isVoiceMessage ? 1 : 0,
      'isRead': isRead ? 1 : 0,
      'customType': customType,
      'minimumSupportVersion': minimumSupportVersion,
      'textOnError': textOnError,
      'customMessageContent': customMessageContent,
      'messageReplied': messageReplied,
      'messageText': messageText,
      'messageImage': messageImage,
      'messageVoice': messageVoice,
      'sequence': sequence,
    };
  }

  CommonMessage.fromSql(Map<String, dynamic> map) {
    id = map['id'];
    chatId = map['chatId'];
    senderId = map['senderId'];
    receiverId = map['receiverId'];
    createdTime = DateTime.fromMillisecondsSinceEpoch(map['createdTime']);
    isCustom = map['isCustom'] > 0;
    isRecalled = map['isRecalled'] > 0;
    isDeleted = map['isDeleted'] > 0;
    isReply = map['isReply'] > 0;
    isImageMessage = map['isImageMessage'] > 0;
    isVoiceMessage = map['isVoiceMessage'] > 0;
    isRead = map['isRead'] > 0;
    customType = map['customType'];
    minimumSupportVersion = map['minimumSupportVersion'];
    textOnError = map['textOnError'];
    customMessageContent = map['customMessageContent'];
    messageReplied = map['messageReplied'];
    messageText = map['messageText'];
    messageImage = map['messageImage'];
    messageVoice = map['messageVoice'];
    sequence = map['sequence'];
  }
}

class CommonMessageProvider {
  late Database database;

  CommonMessageProvider(this.database);

  Future<CommonMessage?> get(int id) async {
    List<Map<String, dynamic>> maps = await database.query('commonMessage', where: "id=?", whereArgs: [id]);
    if (maps.isNotEmpty) {
      return CommonMessage.fromSql(maps.first);
    }
    return null;
  }

  Future<List<CommonMessage>> getAllNotDeletedInChat(int chatId) async {
    List<CommonMessage> messages = [];
    List<Map<String, dynamic>> maps = await database.query('commonMessage', where: "chatId=? & isDeleted=0", whereArgs: [chatId]);
    if (maps.isNotEmpty) {
      for (var element in maps) {
        messages.add(CommonMessage.fromSql(element));
      }
    }
    return messages;
  }
}

class CommonMessageProviderWithTransaction {
  late Transaction transaction;

  CommonMessageProviderWithTransaction(this.transaction);

  Future<bool> insert(CommonMessage commonMessage) async {
    await transaction.insert('commonMessage', commonMessage.toSql());
    return true;
  }

  Future<bool> update(Map<String, dynamic> values, int id) async {
    await transaction.update('commonMessage', values, where: "id=?", whereArgs: [id]);
    return true;
  }

  Future<CommonMessage?> get(int id) async {
    List<Map<String, dynamic>> maps = await transaction.query('commonMessage', where: "id=?", whereArgs: [id]);
    if (maps.isNotEmpty) {
      return CommonMessage.fromSql(maps.first);
    }
    return null;
  }
}
