import 'brief_chat_target_information.dart';

class ChatListTileData {
  late int chatId;
  late String? messagePreview;
  late DateTime? lastMessageCreatedTime;
  late int numberOfUnreadMessages;
  late BriefChatTargetInformation briefChatTargetInformation; //会话对象的信息

  ChatListTileData({
    required this.chatId,
    this.messagePreview,
    this.lastMessageCreatedTime,
    required this.numberOfUnreadMessages,
    required this.briefChatTargetInformation,
  });
}
