import 'package:meta_uni_app/mini_apps/chat_room/home_page/chat_room/models/message_media.dart';
import 'package:meta_uni_app/mini_apps/chat_room/home_page/chat_room/models/sender.dart';

class Message {
  late String messageId;
  late Sender sender;
  late DateTime createdTime;
  late bool isCustom;
  late bool isRecalled;
  late bool isDeleted;
  late bool isReply;
  late bool isMediaMessage;
  late bool isVoiceMessage;
  late String? customType;
  late String? minimumSupportVersion;
  late String? textOnError;
  late String? customMessageContent;
  late Message? messageReplied;
  late String? messageText;
  late List<MessageMedia>? messageMedias;
  late String? messageVoice;

  Message.fromJson(Map<String, dynamic> map) {
    messageId = map['messageId'];
    sender = Sender.fromJson(
      map['sender'],
    );
    createdTime = DateTime.parse(
      map['createdTime'],
    );
    isCustom = map['isCustom'];
    isRecalled = map['isRecalled'];
    isDeleted = false;
    isReply = map['isReply'];
    isMediaMessage = map['isMediaMessage'];
    isVoiceMessage = map['isVoiceMessage'];
    if (isCustom) {
      customType = map['customType'];
      minimumSupportVersion = map['minimumSupportVersion'];
      textOnError = map['textOnError'];
      customMessageContent = map['customMessageContent'];
    } else {
      customType = null;
      minimumSupportVersion = null;
      textOnError = null;
      customMessageContent = null;
    }
    if (isReply) {
      messageReplied = Message.fromJson(
        map['messageReplied'],
      );
    } else {
      messageReplied = null;
    }
    messageText = map['messageText'];
    if (isMediaMessage) {
      messageMedias = [];
      List<dynamic> dataList = map['messageMedias'];
      for (var data in dataList) {
        messageMedias!.add(
          MessageMedia.fromJson(data),
        );
      }
    } else {
      messageMedias = null;
    }
    if (isVoiceMessage) {
      messageVoice = map['messageVoice'];
    } else {
      messageVoice = null;
    }
  }
}
