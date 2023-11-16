import 'dart:convert';
import 'package:meta_uni_app/bloc/bloc_manager.dart';
import 'package:meta_uni_app/database/models/chat/common_chat_status.dart';
import 'package:meta_uni_app/database/models/message/common_message.dart';
import 'package:meta_uni_app/web_socket/models/read_messages_request_data.dart';
import 'package:meta_uni_app/web_socket/models/sync_messages_request_data.dart';
import 'package:meta_uni_app/web_socket/web_socket_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/io.dart';
import '../bloc/chat_list_tile/models/chat_list_tile_update_data.dart';
import '../bloc/contacts/models/should_update_contacts_view_data.dart';
import '../database/models/friend/friendship.dart';
import '../database/models/message/system_message.dart';

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

  initChannel(WebSocketHelper webSocketHelper, BlocManager blocManager, int sequenceForCommonMessages, int sequenceForSystemMessages, Function(int, int) reconnectWebSocket) {
    _webSocketHelper = webSocketHelper;
    _blocManager = blocManager;
    int lastSequenceForCommonMessages = sequenceForCommonMessages;
    int lastSequenceForSystemMessages = sequenceForSystemMessages;
    _channel = IOWebSocketChannel.connect(
      Uri.parse('ws://10.0.2.2:45550/metaUni/webSocketAPI/ws'),
      headers: {'UUID': _webSocketHelper.uuid, 'JWT': _webSocketHelper.jwt},
    );

    _channel.stream.listen(
      (event) async {
        Map<dynamic, dynamic> map = jsonDecode(event);
        switch (map["type"]) {
          case "ReadCommonMessagesSucceed":
            int chatId = map["data"]["chatId"];
            _webSocketHelper.readMessages(chatId);
            _blocManager.chatListTileDataCubit.shouldUpdate(
              ChatListTileUpdateData(chatId: chatId),
            );
            break;
          case "ReadSystemMessagesSucceed":
            int chatId = map["data"]["chatId"];
            _webSocketHelper.readMessages(chatId);
            _blocManager.chatListTileDataCubit.shouldUpdate(
              ChatListTileUpdateData(chatId: chatId),
            );
            break;
          case "CommonMessagesBeRead":
            CommonChatStatus commonChatStatus = CommonChatStatus.fromJson(map["data"]);
            _webSocketHelper.updateCommonChatStatus(commonChatStatus);
            _blocManager.commonChatStatusCubit.shouldUpdate(commonChatStatus);
            break;
          case "NewCommonMessage":
            CommonMessage commonMessage = CommonMessage.fromJson(map["data"]);
            int numberOfUnreadMessages = await _webSocketHelper.storeNewCommonMessage(commonMessage);
            _blocManager.commonMessageCubit.receive(commonMessage);
            _blocManager.totalNumberOfUnreadMessagesCubit.increment(numberOfUnreadMessages);
            _blocManager.chatListTileDataCubit.shouldUpdate(
              ChatListTileUpdateData(chatId: commonMessage.chatId),
            );
            break;
          case "NewSystemMessage":
            SystemMessage systemMessage = SystemMessage.fromJson(map["data"]);
            int numberOfUnreadMessages = await _webSocketHelper.storeNewSystemMessage(systemMessage);
            _blocManager.systemMessageCubit.receive(systemMessage);
            _blocManager.totalNumberOfUnreadMessagesCubit.increment(numberOfUnreadMessages);
            _blocManager.chatListTileDataCubit.shouldUpdate(
              ChatListTileUpdateData(chatId: systemMessage.chatId),
            );
            break;
          case "CommonMessageBeRecalled":
            CommonMessage commonMessage = CommonMessage.fromJson(map["data"]);
            _webSocketHelper.commonMessageBeRecalled(commonMessage);
            _blocManager.commonMessageBeRecalledCubit.recall(commonMessage);
            _blocManager.chatListTileDataCubit.shouldUpdate(
              ChatListTileUpdateData(chatId: commonMessage.chatId, messageBeRecalled: true, messageBeRecalledId: commonMessage.id),
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
            lastSequenceForCommonMessages = map["newSequence"];
            _webSocketHelper.updateSequenceForCommonMessages(map["newSequence"]);
            if (map["hasMore"]) {
              sendSyncCommonMessagesRequestData(
                lastSequenceForCommonMessages,
              );
            }
            break;
          case "SyncSystemMessagesSucceed":
            List<dynamic> dataList = map["dataList"];
            for (List<dynamic> messages in dataList) {
              _webSocketHelper.storeNewSystemMessagesList(messages);
              _blocManager.chatListTileDataCubit.shouldUpdate(
                ChatListTileUpdateData(chatId: messages[0]["chatId"]),
              );
            }
            lastSequenceForSystemMessages = map["newSequence"];
            _webSocketHelper.updateSequenceForSystemMessages(map["newSequence"]);
            if (map["hasMore"]) {
              sendSyncSystemMessagesRequestData(
                lastSequenceForSystemMessages,
              );
            }
            break;
          case "NewAddFriendRequest":
            _blocManager.hasUnreadAddFriendRequestCubit.update(true);
            break;
          case "NewFriendship":
            Friendship friendship = Friendship.fromJson(
              map["data"],
            );
            _webSocketHelper.storeNewFriendship(friendship);
            BlocManager().shouldUpdateContactsViewCubit.shouldUpdate(
                  ShouldUpdateContactsViewData(),
                );
          case "FriendshipBeDeleted":
            Friendship friendship = Friendship.fromJson(
              map["data"],
            );
            _webSocketHelper.storeNewFriendship(friendship);
            BlocManager().shouldUpdateContactsViewCubit.shouldUpdate(
                  ShouldUpdateContactsViewData(),
                );
            break;
        }
      },
      onDone: () async {
        // 断线重连逻辑
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        final jwt = prefs.getString('jwt');
        final uuid = prefs.getInt('uuid');
        if (jwt != null && uuid != null) {
          reconnectWebSocket(lastSequenceForCommonMessages, lastSequenceForSystemMessages);
        }
      },
    );
    sendSyncCommonMessagesRequestData(
      lastSequenceForCommonMessages,
    );
    sendSyncSystemMessagesRequestData(
      lastSequenceForSystemMessages,
    );
  }

  closeChannel() {
    _channel.sink.close();
  }

  sendReadCommonMessagesRequestData(int chatId) {
    _channel.sink.add(
      jsonEncode(
        ReadCommonMessagesRequestData(uuid: _webSocketHelper.uuid, jwt: _webSocketHelper.jwt, chatId: chatId),
      ),
    );
  }

  sendReadSystemMessagesRequestData(int chatId) {
    _channel.sink.add(
      jsonEncode(
        ReadSystemMessagesRequestData(uuid: _webSocketHelper.uuid, jwt: _webSocketHelper.jwt, chatId: chatId),
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

  sendSyncSystemMessagesRequestData(int sequence) {
    _channel.sink.add(
      jsonEncode(
        SyncSystemMessagesRequestData(uuid: _webSocketHelper.uuid, jwt: _webSocketHelper.jwt, sequence: sequence),
      ),
    );
  }
}
