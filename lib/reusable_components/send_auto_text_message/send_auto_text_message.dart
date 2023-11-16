import 'package:dio/dio.dart';
import 'package:meta_uni_app/database/database_manager.dart';
import 'package:meta_uni_app/models/dio_model.dart';
import 'package:sqflite/sqflite.dart';
import '../../bloc/bloc_manager.dart';
import '../../bloc/chat_list_tile/models/chat_list_tile_update_data.dart';
import '../../database/models/chat/chat.dart';
import '../../database/models/chat/common_chat_status.dart';
import '../../database/models/message/common_message.dart';
import '../../database/models/user/user_sync_table.dart';
import '../logout/logout.dart';
import '../snack_bar/network_error_snack_bar.dart';
import '../snack_bar/normal_snack_bar.dart';

storeNewMessage(CommonMessage message, int uuid) async {
  Database database = await DatabaseManager().getDatabase;

  await database.transaction((transaction) async {
    CommonMessageProviderWithTransaction commonMessageProviderWithTransaction = CommonMessageProviderWithTransaction(transaction);

    commonMessageProviderWithTransaction.insert(message);

    UserSyncTableProviderWithTransaction userSyncTableProviderWithTransaction = UserSyncTableProviderWithTransaction(transaction);
    userSyncTableProviderWithTransaction.updateSequenceForCommonMessages(uuid, message.sequence);
    userSyncTableProviderWithTransaction.update({
      'updatedTimeForChats': message.createdTime.millisecondsSinceEpoch,
    }, uuid);

    ChatProviderWithTransaction chatProviderWithTransaction = ChatProviderWithTransaction(transaction);
    CommonChatStatusProviderWithTransaction commonChatStatusProviderWithTransaction = CommonChatStatusProviderWithTransaction(transaction);

    int chatId = message.chatId;
    Chat? chat = await chatProviderWithTransaction.get(chatId);
    if (chat == null) {
      chatProviderWithTransaction.insert(
        Chat(
          id: chatId,
          uuid: uuid,
          targetId: message.receiverId,
          isWithOtherUser: true,
          numberOfUnreadMessages: 0,
          lastMessageId: message.id,
          updatedTime: message.createdTime,
        ),
      );
      commonChatStatusProviderWithTransaction.insert(
        CommonChatStatus(chatId: chatId, lastMessageBeReadSendByMe: null, readTime: null, updatedTime: message.createdTime),
      );
    } else {
      chatProviderWithTransaction.update({
        'isDeleted': 0,
        'lastMessageId': message.id,
        'updatedTime': message.createdTime.millisecondsSinceEpoch,
      }, chatId);
    }
  });
}

Future<bool> sendAutoTextMessage(int targetId, String message, String jwt, int uuid, context) async {
  DioModel dioModel = DioModel();

  Map<String, dynamic> formDataMap = {
    "receiverId": targetId,
    "messageText": "自动消息：$message",
  };

  try {
    Response response;
    var formData = FormData.fromMap(
      formDataMap,
      ListFormat.multiCompatible,
    );
    response = await dioModel.dio.post(
      '/metaUni/messageAPI/commonMessage/common',
      data: formData,
      options: Options(headers: {
        'JWT': jwt,
        'UUID': uuid,
      }),
    );
    switch (response.data['code']) {
      case 0:
        CommonMessage message = CommonMessage.fromJson(response.data['data']);
        await storeNewMessage(message, uuid);
        BlocManager().chatListTileDataCubit.shouldUpdate(
              ChatListTileUpdateData(
                chatId: message.chatId,
              ),
            );
        return true;
        //break;
      case 1:
        //Message:"使用了无效的JWT，请重新登录"
        if (context.mounted) {
          getNormalSnackBar(context, response.data['message']);
          logout(context);
        }
        break;
      case 2:
      //Message:"目标用户不存在"
      case 3:
      //Message:"您正在尝试回复一条不属于该对话的消息"
      case 4:
      //Message:"发送消息失败，文字内容与媒体文件内容不能同时为空"
      case 5:
      //Message:"发送消息失败，上传媒体文件数超过限制"
      case 6:
      //Message:"发送消息失败，禁止上传规定格式以外的文件"
      case 7:
        //Message:"发送消息失败，您已被对方屏蔽"
        if (context.mounted) {
          getNormalSnackBar(context, response.data['message']);
        }
        break;
      case 8:
      //Message:"发生错误，消息发送失败"
      case 9:
        //Message:"发生错误，消息发送失败"
        if (context.mounted) {
          getNetworkErrorSnackBar(context);
        }
        break;
      default:
        if (context.mounted) {
          getNetworkErrorSnackBar(context);
        }
    }
  } catch (e) {
    if (context.mounted) {
      getNetworkErrorSnackBar(context);
    }
  }

  return false;
}
