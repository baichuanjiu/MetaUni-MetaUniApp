import 'package:meta_uni_app/bloc/bloc_manager.dart';
import 'package:meta_uni_app/database/models/chat/common_chat_status.dart';
import 'package:meta_uni_app/database/models/user/user_sync_table.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_manager.dart';
import '../database/models/chat/chat.dart';
import '../database/models/friend/friendship.dart';
import '../database/models/message/common_message.dart';
import '../database/models/message/system_message.dart';

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

  Future<int> storeNewCommonMessage(CommonMessage message) async {
    int numberOfUnreadMessages = 1;
    await database.transaction(
      (transaction) async {
        CommonMessageProviderWithTransaction commonMessageProviderWithTransaction = CommonMessageProviderWithTransaction(transaction);

        bool updateFlag = false;
        var m = await commonMessageProviderWithTransaction.get(message.id);
        if (m != null) {
          if (m.sequence < message.sequence) {
            commonMessageProviderWithTransaction.update(message.toSql(), message.id);
            updateFlag = true;
          }
        } else {
          commonMessageProviderWithTransaction.insert(message);
          updateFlag = true;
        }

        if(updateFlag)
        {
          UserSyncTableProviderWithTransaction userSyncTableProviderWithTransaction = UserSyncTableProviderWithTransaction(transaction);
          userSyncTableProviderWithTransaction.updateSequenceForCommonMessages(uuid, message.sequence);
          userSyncTableProviderWithTransaction.update(
              {
                'updatedTimeForChats': message.createdTime.millisecondsSinceEpoch,
              }, uuid);

          ChatProviderWithTransaction chatProviderWithTransaction = ChatProviderWithTransaction(transaction);

          int chatId = message.chatId;
          Chat? chat = await chatProviderWithTransaction.get(chatId);

          if (chat == null) {
            chatProviderWithTransaction.insert(
              Chat(
                id: chatId,
                uuid: uuid,
                targetId: message.senderId,
                isWithOtherUser: true,
                numberOfUnreadMessages: numberOfUnreadMessages,
                lastMessageId: message.id,
                updatedTime: message.createdTime,
              ),
            );
            CommonChatStatusProviderWithTransaction commonChatStatusProviderWithTransaction = CommonChatStatusProviderWithTransaction(transaction);
            commonChatStatusProviderWithTransaction.insert(
              CommonChatStatus(chatId: chatId, lastMessageBeReadSendByMe: null, readTime: null, updatedTime: message.createdTime),
            );
          } else {
            numberOfUnreadMessages = chat.numberOfUnreadMessages + 1;
            chatProviderWithTransaction.update({
              'isDeleted': 0,
              'lastMessageId': message.id,
              'numberOfUnreadMessages': numberOfUnreadMessages,
              'updatedTime': message.createdTime.millisecondsSinceEpoch,
            }, chatId);
          }
        }
      },
    );
    return numberOfUnreadMessages;
  }

  Future<int> storeNewSystemMessage(SystemMessage message) async {
    int numberOfUnreadMessages = 1;
    await database.transaction(
          (transaction) async {
        SystemMessageProviderWithTransaction systemMessageProviderWithTransaction = SystemMessageProviderWithTransaction(transaction);

        bool updateFlag = false;
        var m = await systemMessageProviderWithTransaction.get(message.id);
        if (m != null) {
          if (m.sequence < message.sequence) {
            systemMessageProviderWithTransaction.update(message.toSql(), message.id);
            updateFlag = true;
          }
        } else {
          systemMessageProviderWithTransaction.insert(message);
          updateFlag = true;
        }

        if(updateFlag)
        {
          UserSyncTableProviderWithTransaction userSyncTableProviderWithTransaction = UserSyncTableProviderWithTransaction(transaction);
          userSyncTableProviderWithTransaction.updateSequenceForSystemMessages(uuid, message.sequence);
          userSyncTableProviderWithTransaction.update(
              {
                'updatedTimeForChats': message.createdTime.millisecondsSinceEpoch,
              }, uuid);

          ChatProviderWithTransaction chatProviderWithTransaction = ChatProviderWithTransaction(transaction);

          int chatId = message.chatId;
          Chat? chat = await chatProviderWithTransaction.get(chatId);

          if (chat == null) {
            chatProviderWithTransaction.insert(
              Chat(
                id: chatId,
                uuid: uuid,
                targetId: message.senderId,
                isWithSystem: true,
                numberOfUnreadMessages: numberOfUnreadMessages,
                lastMessageId: message.id,
                updatedTime: message.createdTime,
              ),
            );
          } else {
            numberOfUnreadMessages = chat.numberOfUnreadMessages + 1;
            chatProviderWithTransaction.update({
              'isDeleted': 0,
              'lastMessageId': message.id,
              'numberOfUnreadMessages': numberOfUnreadMessages,
              'updatedTime': message.createdTime.millisecondsSinceEpoch,
            }, chatId);
          }
        }
      },
    );
    return numberOfUnreadMessages;
  }

  void commonMessageBeRecalled(CommonMessage message) async {
    await database.transaction(
      (transaction) async {
        CommonMessageProviderWithTransaction commonMessageProviderWithTransaction = CommonMessageProviderWithTransaction(transaction);

        bool updateFlag = false;
        var m = await commonMessageProviderWithTransaction.get(message.id);
        if (m != null) {
          if (m.sequence < message.sequence) {
            commonMessageProviderWithTransaction.update(message.toSql(), message.id);
            updateFlag = true;
          }
        } else {
          commonMessageProviderWithTransaction.insert(message);
          updateFlag = true;
        }

        if(updateFlag)
        {
          UserSyncTableProviderWithTransaction userSyncTableProviderWithTransaction = UserSyncTableProviderWithTransaction(transaction);
          userSyncTableProviderWithTransaction.updateSequenceForCommonMessages(uuid, message.sequence);
        }
      },
    );
  }

  void readMessages(int chatId) async {
    await database.transaction(
      (transaction) async {
        ChatProviderWithTransaction chatProviderWithTransaction = ChatProviderWithTransaction(transaction);
        int number = await chatProviderWithTransaction.readMessages(chatId);
        BlocManager().totalNumberOfUnreadMessagesCubit.decrement(number);
      },
    );
  }

  void updateCommonChatStatus(CommonChatStatus newStatus) async {
    await database.transaction(
      (transaction) async {
        CommonChatStatusProviderWithTransaction commonChatStatusProviderWithTransaction = CommonChatStatusProviderWithTransaction(transaction);
        CommonChatStatus? commonChatStatus = await commonChatStatusProviderWithTransaction.get(newStatus.chatId);
        if (commonChatStatus == null) {
          commonChatStatusProviderWithTransaction.insert(newStatus);
        } else {
          commonChatStatusProviderWithTransaction.update(newStatus.toUpdateSql(), newStatus.chatId);
        }
      },
    );
  }

  Future<int> getSequenceForCommonMessages() async {
    UserSyncTableProvider userSyncTableProvider = UserSyncTableProvider(database);
    return (await userSyncTableProvider.getSequenceForCommonMessages(uuid))!;
  }

  Future<int> getSequenceForSystemMessages() async {
    UserSyncTableProvider userSyncTableProvider = UserSyncTableProvider(database);
    return (await userSyncTableProvider.getSequenceForSystemMessages(uuid))!;
  }

  void storeNewCommonMessagesList(List<dynamic> messages) async {
    await database.transaction(
      (transaction) async {
        CommonMessageProviderWithTransaction commonMessageProviderWithTransaction = CommonMessageProviderWithTransaction(transaction);

        for (var message in messages) {
          var m = await commonMessageProviderWithTransaction.get(message["id"]);
          if (m != null) {
            if (m.sequence < message["sequence"]) {
              commonMessageProviderWithTransaction.update(CommonMessage.fromJson(message).toSql(), message["id"]);
            }
          } else {
            commonMessageProviderWithTransaction.insert(CommonMessage.fromJson(message));
          }
        }
      },
    );
  }

  void storeNewSystemMessagesList(List<dynamic> messages) async {
    await database.transaction(
          (transaction) async {
        SystemMessageProviderWithTransaction systemMessageProviderWithTransaction = SystemMessageProviderWithTransaction(transaction);

        for (var message in messages) {
          var m = await systemMessageProviderWithTransaction.get(message["id"]);
          if (m != null) {
            if (m.sequence < message["sequence"]) {
              systemMessageProviderWithTransaction.update(SystemMessage.fromJson(message).toSql(), message["id"]);
            }
          } else {
            systemMessageProviderWithTransaction.insert(SystemMessage.fromJson(message));
          }
        }
      },
    );
  }

  void updateSequenceForCommonMessages(int sequence) async {
    UserSyncTableProvider userSyncTableProvider = UserSyncTableProvider(database);
    userSyncTableProvider.updateSequenceForCommonMessages(uuid, sequence);
  }

  void updateSequenceForSystemMessages(int sequence) async {
    UserSyncTableProvider userSyncTableProvider = UserSyncTableProvider(database);
    userSyncTableProvider.updateSequenceForCommonMessages(uuid, sequence);
  }

  void storeNewFriendship(Friendship friendship) async {
    await database.transaction(
      (transaction) async {
        FriendshipProviderWithTransaction friendshipProviderWithTransaction = FriendshipProviderWithTransaction(transaction);

        bool updateFlag = false;
        var f = await friendshipProviderWithTransaction.get(friendship.id);
        if(f != null)
        {
          if(f.updatedTime.isBefore(friendship.updatedTime))
          {
            friendshipProviderWithTransaction.update(friendship.toUpdateSql(), friendship.id);
            updateFlag = true;
          }
        }
        else
        {
          friendshipProviderWithTransaction.insert(friendship);
          updateFlag = true;
        }

        if(updateFlag)
        {
          UserSyncTableProviderWithTransaction userSyncTableProviderWithTransaction = UserSyncTableProviderWithTransaction(transaction);
          userSyncTableProviderWithTransaction.update(
              {
                'updatedTimeForFriendships': friendship.updatedTime.millisecondsSinceEpoch,
              }, uuid);
        }
      },
    );
  }
}
