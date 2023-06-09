import 'dart:convert';
import 'package:meta_uni_app/bloc/bloc_manager.dart';
import 'package:meta_uni_app/database/models/chat/common_chat_status.dart';
import 'package:meta_uni_app/database/models/message/common_message.dart';
import 'package:meta_uni_app/web_socket/models/read_messages_request_data.dart';
import 'package:meta_uni_app/web_socket/models/sync_common_messages_request_data.dart';
import 'package:meta_uni_app/web_socket/web_socket_helper.dart';
import 'package:web_socket_channel/io.dart';
import '../bloc/chat_list_tile/models/chat_list_tile_update_data.dart';
import '../database/models/friend/friendship.dart';

//单例模式构建webSocket
class WebSocketChannel {
  static final WebSocketChannel _instance = WebSocketChannel._();

  WebSocketChannel._();

  factory WebSocketChannel() {
    return _instance;
  }

  late IOWebSocketChannel _channel;
  late WebSocketHelper _webSocketHelper;
  late BlocManager _blocManager;

  initChannel(WebSocketHelper webSocketHelper, BlocManager blocManager,int sequenceForCommonMessages) {
    _webSocketHelper = webSocketHelper;
    _blocManager = blocManager;
    _channel = IOWebSocketChannel.connect(
      Uri.parse('ws://10.0.2.2:45550/metaUni/webSocketAPI/ws'),
      headers: {'UUID': _webSocketHelper.uuid, 'JWT': _webSocketHelper.jwt},
    );
    _channel.stream.listen((event) {
      print(event);
      Map<dynamic, dynamic> map = jsonDecode(event);
      switch (map["type"]) {
        case "ReadMessagesSucceed":
          int chatId = map["data"]["chatId"];
          _webSocketHelper.readMessages(chatId);
          _blocManager.chatListTileDataCubit.shouldUpdate(
            ChatListTileUpdateData(chatId: chatId),
          );
          break;
        case "MessagesBeRead":
          CommonChatStatus commonChatStatus = CommonChatStatus.fromJson(map["data"]);
          _webSocketHelper.updateCommonChatStatus(commonChatStatus);
          _blocManager.commonChatStatusCubit.shouldUpdate(commonChatStatus);
          break;
        case "NewCommonMessage":
          CommonMessage commonMessage = CommonMessage.fromJson(map["data"]);
          _webSocketHelper.storeNewCommonMessage(commonMessage);
          _blocManager.commonMessageCubit.receive(commonMessage);
          _blocManager.totalNumberOfUnreadMessagesCubit.increment(1);
          _blocManager.chatListTileDataCubit.shouldUpdate(
            ChatListTileUpdateData(chatId: commonMessage.chatId),
          );
          break;
        case "SyncCommonMessagesSucceed":
          List<dynamic> dataList = map["dataList"];
          for (List<dynamic> messages in dataList) {
            _webSocketHelper.storeNewCommonMessagesList(messages);
            _blocManager.chatListTileDataCubit.shouldUpdate(
              ChatListTileUpdateData(chatId: messages[0]["chatId"]),
            );
          }
          _webSocketHelper.updateSequenceForCommonMessages(map["currentSequence"]);
          break;
        case "NewAddFriendRequest":
          _blocManager.hasUnreadAddFriendRequestCubit.update(true);
          break;
        case "NewFriendship":
          Friendship friendship = Friendship.fromJson(
            map["data"],
          );
          _webSocketHelper.storeNewFriendship(friendship);
          break;
      }
    }, onDone: () {
      print("掉线了");
    });
    sendSyncCommonMessagesRequestData(
      sequenceForCommonMessages,
    );
  }

  closeChannel() {
    _channel.sink.close();
  }

  sendReadMessagesRequestData(int chatId) {
    _channel.sink.add(
      jsonEncode(
        ReadMessagesRequestData(uuid: _webSocketHelper.uuid, jwt: _webSocketHelper.jwt, chatId: chatId),
      ),
    );
  }

  sendSyncCommonMessagesRequestData(int sequence) {
    _channel.sink.add(
      jsonEncode(
        SyncCommonMessagesRequestData(uuid: _webSocketHelper.uuid, jwt: _webSocketHelper.jwt, sequence: sequence),
      ),
    );
  }
}
