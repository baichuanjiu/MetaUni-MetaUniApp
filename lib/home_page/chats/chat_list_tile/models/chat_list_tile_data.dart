import '../../../../database/models/chat/chat.dart';
import 'brief_chat_target_information.dart';

class ChatListTileData {
  late Chat chat;
  late String? messagePreview;
  late DateTime? lastMessageCreatedTime;
  late BriefChatTargetInformation briefChatTargetInformation; //会话对象的信息

  ChatListTileData({
    required this.chat,
    this.messagePreview,
    this.lastMessageCreatedTime,
    required this.briefChatTargetInformation,
  });
}
