import 'dart:convert';
import 'package:meta_uni_app/bloc/bloc_manager.dart';
import 'package:meta_uni_app/database/models/chat/common_chat_status.dart';
import 'package:meta_uni_app/database/models/message/common_message.dart';
import 'package:meta_uni_app/web_socket/models/read_messages_request_data.dart';
import 'package:meta_uni_app/web_socket/web_socket_helper.dart';
import 'package:web_socket_channel/io.dart';
import '../bloc/chat_list_tile/models/chat_list_tile_update_data.dart';

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

  initChannel(WebSocketHelper webSocketHelper, BlocManager blocManager) {
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
      }
    }, onDone: () {
      print("掉线了");
    });
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
}
