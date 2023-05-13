import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta_uni_app/bloc/contacts/has_unread_add_friend_request_bloc.dart';
import 'package:meta_uni_app/models/dio_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../../bloc/chat_list_tile/chat_list_tile_bloc.dart';
import '../../bloc/chat_list_tile/models/chat_list_tile_update_data.dart';
import '../../database/database_manager.dart';
import '../../database/models/chat/chat.dart';
import '../../database/models/friend/friendship.dart';
import '../../database/models/message/common_message.dart';
import '../../database/models/user/brief_user_information.dart';
import '../../reusable_components/logout/logout.dart';
import '../../reusable_components/snack_bar/network_error_snack_bar.dart';
import '../../reusable_components/snack_bar/normal_snack_bar.dart';
import 'chat_list_tile/chat_list_tile.dart';
import 'chat_list_tile/models/brief_chat_target_information.dart';
import 'chat_list_tile/models/chat_list_tile_data.dart';
import 'search/search_box.dart';

class ChatsPage extends StatefulWidget {
  const ChatsPage({super.key});

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  List<ChatListTileData> chatListTilesData = [];
  List<ChatListTile> chatListTiles = [];

  late Database database;
  late ChatProvider chatProvider;
  late FriendshipProvider friendshipProvider;
  late BriefUserInformationProvider briefUserInformationProvider;
  late CommonMessageProvider commonMessageProvider;

  _performInitActions() async {
    await initChats();
    initChatListTiles();
    setState(() {});
  }

  Future<ChatListTileData?> getChatListTileData(Chat chat) async {
    if (chat.isWithOtherUser) {
      String? remark = await friendshipProvider.getRemark(chat.targetId);
      BriefUserInformation? info = await briefUserInformationProvider.get(chat.targetId);

      if (info == null) {
        await getBriefUserInformation(chat.targetId);
        info = await briefUserInformationProvider.get(chat.targetId);
      }

      String? messagePreview;
      DateTime? lastMessageCreatedTime;
      if (chat.lastMessageId != null) {
        CommonMessage? lastMessage = await commonMessageProvider.get(chat.lastMessageId!);
        if (lastMessage != null) {
          //这里后续还要修改，比如如果发送了图片的话
          //同时时间显示也需要修改
          messagePreview = lastMessage.messageText;
          lastMessageCreatedTime = lastMessage.createdTime;
        }
      }

      if (info != null) {
        return ChatListTileData(
          chatId: chat.id,
          messagePreview: messagePreview,
          lastMessageCreatedTime: lastMessageCreatedTime,
          numberOfUnreadMessages: chat.numberOfUnreadMessages,
          briefChatTargetInformation:
              BriefChatTargetInformation(chatId: chat.id, targetType: "user", id: chat.targetId, avatar: info.avatar, name: remark ?? info.nickname, updatedTime: info.updatedTime),
        );
      }
    }
    return null;
  }

  getBriefUserInformation(int queryUUID) async {
    final prefs = await SharedPreferences.getInstance();

    final String? jwt = prefs.getString('jwt');
    final int? uuid = prefs.getInt('uuid');

    final DioModel dioModel = DioModel();

    try {
      Response response;
      response = await dioModel.dio.get(
        '/metaUni/userAPI/profile/brief/$queryUUID',
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 1:
          //Message:"使用了无效的JWT，请重新登录"
          if (mounted) {
            getNormalSnackBar(context, response.data['message']);
            logout(context);
          }
          break;
        case 2:
          //Message:"没有找到目标用户的个人信息"
          if (mounted) {
            getNormalSnackBar(context, response.data['message']);
          }
          break;
        default:
          Database database = await DatabaseManager().getDatabase;
          BriefUserInformationProvider briefUserInformationProvider = BriefUserInformationProvider(database);
          BriefUserInformation briefUserInformation = BriefUserInformation.fromJson(response.data['data']);
          if (await briefUserInformationProvider.get(briefUserInformation.uuid) == null) {
            briefUserInformationProvider.insert(briefUserInformation);
          } else {
            briefUserInformationProvider.update(briefUserInformation.toUpdateSql(), briefUserInformation.uuid);
          }
      }
    } catch (e) {
      if (mounted) {
        getNetworkErrorSnackBar(context);
      }
    }
  }

  initChats() async {
    database = await DatabaseManager().getDatabase;
    chatProvider = ChatProvider(database);

    friendshipProvider = FriendshipProvider(database);
    briefUserInformationProvider = BriefUserInformationProvider(database);
    commonMessageProvider = CommonMessageProvider(database);

    List<Chat> chats = await chatProvider.getAllNotDeleted();

    for (var chat in chats) {
      ChatListTileData? chatListTileData = await getChatListTileData(chat);
      if (chatListTileData != null) {
        chatListTilesData.add(chatListTileData);
      }
    }
  }

  void initChatListTiles() {
    for (ChatListTileData chat in chatListTilesData) {
      chatListTiles.add(
        ChatListTile(chatListTileData: chat),
      );
    }
  }

  updateChatListTile(int chatId) async {
    Chat chat = (await chatProvider.get(chatId))!;
    ChatListTileData? chatListTileData = await getChatListTileData(chat);
    if (chatListTileData != null) {
      int index = chatListTiles.indexWhere((element) => element.chatListTileData.chatId == chatId);
      if (index != -1) {
        chatListTiles.replaceRange(
          index,
          index + 1,
          [
            ChatListTile(
              chatListTileData: chatListTileData,
            ),
          ],
        );
      } else {
        chatListTiles.add(
          ChatListTile(
            chatListTileData: chatListTileData,
          ),
        );
      }
      setState(() {});
    }
  }

  late Future<dynamic> performInitActions;

  @override
  void initState() {
    super.initState();
    performInitActions = _performInitActions();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ChatListTileCubit, ChatListTileUpdateData?>(
          listener: (context, chatListTileUpdateData) {
            updateChatListTile(chatListTileUpdateData!.chatId);
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('消息'),
          centerTitle: true,
          actions: [
            BlocBuilder<HasUnreadAddFriendRequestCubit, bool>(
              builder: (context, state) {
                return state
                    ? IconButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/contacts');
                        },
                        icon: const Badge(
                          child: Icon(Icons.people_outlined),
                        ),
                        tooltip: '通讯录',
                      )
                    : IconButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/contacts');
                        },
                        icon: const Icon(Icons.people_outlined),
                        tooltip: '通讯录',
                      );
              },
            ),
            PopupMenuButton(
              itemBuilder: (BuildContext context) {
                return [
                  const PopupMenuItem(
                    child: ListTile(
                      leading: Icon(
                        Icons.wechat_outlined,
                      ),
                      title: Text('创建群聊'),
                    ),
                  ),
                  PopupMenuItem(
                    onTap: () async {
                      await Future.delayed(Duration.zero);
                      if (mounted) {
                        Navigator.pushNamed(context, '/contacts/search');
                      }
                    },
                    child: const ListTile(
                      leading: Icon(
                        Icons.person_add_alt_rounded,
                      ),
                      title: Text('添加好友/群'),
                    ),
                  ),
                  const PopupMenuItem(
                    child: ListTile(
                      leading: Icon(
                        Icons.feedback_rounded,
                      ),
                      title: Text('问题反馈'),
                    ),
                  ),
                ];
              },
              offset: const Offset(0, 56),
              tooltip: '快捷操作',
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            await Future.delayed(const Duration(seconds: 1));
          },
          child: SizedBox(
            height: double.infinity,
            width: double.infinity,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  const ChatsSearchBox(),
                  FutureBuilder(
                    future: performInitActions,
                    builder: (context, snapshot) {
                      switch (snapshot.connectionState) {
                        case ConnectionState.none:
                          return const LoadingPage();
                        case ConnectionState.active:
                          return const LoadingPage();
                        case ConnectionState.waiting:
                          return const LoadingPage();
                        case ConnectionState.done:
                          if (snapshot.hasError) {
                            return const LoadingPage();
                          }
                          return Column(
                            children: chatListTiles.isEmpty
                                ? [
                                    Center(
                                      child: Text(
                                        "还未收到任何消息呢！",
                                        style: Theme.of(context).textTheme.bodyLarge,
                                      ),
                                    ),
                                  ]
                                : [
                                    ...chatListTiles,
                                  ],
                          );
                        default:
                          return const LoadingPage();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Center(
        child: CupertinoActivityIndicator(),
      ),
    );
  }
}
