import 'package:meta_uni_app/bloc/bloc_manager.dart';
import 'package:meta_uni_app/database/models/chat/common_chat_status.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_manager.dart';
import '../database/models/chat/chat.dart';
import '../database/models/message/common_message.dart';

//单例模式构建webSocketHelper
class WebSocketHelper {
  static final WebSocketHelper _instance = WebSocketHelper._();

  WebSocketHelper._();

  factory WebSocketHelper() {
    return _instance;
  }

  late int uuid;
  late String jwt;
  late Database database;

  initHelper(int uuid, String jwt) async {
    this.uuid = uuid;
    this.jwt = jwt;
    database = await DatabaseManager().getDatabase;
  }

  void storeNewCommonMessage(CommonMessage message) async {
    await database.transaction((transaction) async {
      CommonMessageProviderWithTransaction commonMessageProviderWithTransaction = CommonMessageProviderWithTransaction(transaction);

      commonMessageProviderWithTransaction.insert(message);

      ChatProviderWithTransaction chatProviderWithTransaction = ChatProviderWithTransaction(transaction);

      int chatId = message.chatId;
      Chat? chat = await chatProviderWithTransaction.get(chatId);
      //后续还要再修改，主要处理 未读消息数 与 消息是否已读
      if (chat == null) {
        chatProviderWithTransaction.insert(
          Chat(
            id: chatId,
            uuid: uuid,
            targetId: message.senderId,
            isWithOtherUser: true,
            numberOfUnreadMessages: 1,
            lastMessageId: message.id,
            updatedTime: message.createdTime,
          ),
        );
        CommonChatStatusProviderWithTransaction commonChatStatusProviderWithTransaction = CommonChatStatusProviderWithTransaction(transaction);
        commonChatStatusProviderWithTransaction.insert(CommonChatStatus(chatId: chatId, lastMessageSendByMe: null, isRead: null, readTime: null, updatedTime: message.createdTime));
      } else {
        chatProviderWithTransaction.update({
          'isDeleted': 0,
          'lastMessageId': message.id,
          'numberOfUnreadMessages': chat.numberOfUnreadMessages + 1,
          'updatedTime': message.createdTime.millisecondsSinceEpoch,
        }, chatId);
      }
    });
  }

  void readMessages(int chatId) async {
    await database.transaction((transaction) async {
      ChatProviderWithTransaction chatProviderWithTransaction = ChatProviderWithTransaction(transaction);
      int number = await chatProviderWithTransaction.readMessages(chatId);
      BlocManager().totalNumberOfUnreadMessagesCubit.decrement(number);
    });
  }

  void updateCommonChatStatus(CommonChatStatus newStatus) async {
    await database.transaction((transaction) async {
      CommonChatStatusProviderWithTransaction commonChatStatusProviderWithTransaction = CommonChatStatusProviderWithTransaction(transaction);
      CommonChatStatus? commonChatStatus = await commonChatStatusProviderWithTransaction.get(newStatus.chatId);
      if(commonChatStatus == null)
      {
        commonChatStatusProviderWithTransaction.insert(newStatus);
      }
      else
      {
        commonChatStatusProviderWithTransaction.update(newStatus.toUpdateSql(), newStatus.chatId);
      }
    });
  }
}
