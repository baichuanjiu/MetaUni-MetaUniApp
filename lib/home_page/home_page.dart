import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta_uni_app/bloc/bloc_manager.dart';
import 'package:meta_uni_app/bloc/contacts/has_unread_add_friend_request_bloc.dart';
import 'package:meta_uni_app/bloc/message/total_number_of_unread_messages_bloc.dart';
import 'package:meta_uni_app/database/models/chat/common_chat_status.dart';
import 'package:meta_uni_app/database/models/system_promotion/system_promotion.dart';
import 'package:meta_uni_app/reusable_components/check_version/version_manager.dart';
import 'package:meta_uni_app/reusable_components/sticker/sticker_manager.dart';
import 'package:meta_uni_app/web_socket/web_socket_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../bloc/chat_list_tile/chat_list_tile_bloc.dart';
import '../bloc/message/common_message_bloc.dart';
import '../database/database_manager.dart';
import '../database/models/chat/chat.dart';
import '../database/models/friend/friends_group.dart';
import '../database/models/friend/friendship.dart';
import '../database/models/user/brief_user_information.dart';
import '../database/models/user/user_sync_table.dart';
import '../models/dio_model.dart';
import '../reusable_components/logout/logout.dart';
import '../reusable_components/snack_bar/network_error_snack_bar.dart';
import '../reusable_components/snack_bar/normal_snack_bar.dart';
import '../web_socket/web_socket_channel.dart';
import 'chats/chat_list_tile/models/brief_chat_target_information.dart';
import 'chats/chats_page.dart';
import 'discover/discover_page.dart';
import 'me/me_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentPageIndex = 0;

  late final List<Widget> _widgetOptions = <Widget>[
    const DiscoverPage(),
    ChatsPage(
      performInitActions: performInitActions,
    ),
    const MePage(),
  ];

  late Database database;
  late final SharedPreferences prefs;
  late final String jwt;

  late final int uuid;
  final DioModel dioModel = DioModel();

  _init() async {
    prefs = await SharedPreferences.getInstance();
    jwt = prefs.getString('jwt')!;
    uuid = prefs.getInt('uuid')!;

    VersionManager().initAppVersion();
    if (mounted) {
      VersionManager().checkLatestVersion(context);
    }

    await initDatabase();
    database = await DatabaseManager().getDatabase;
    performInitActions();
    initWebSocket(null, null);
  }

  initDatabase() async {
    if (DatabaseManager().getDatabaseName() == null) {
      DatabaseManager().setDatabaseName(uuid.toString());
    }
  }

  performInitActions() async {
    UserSyncTableProvider userSyncTableProvider = UserSyncTableProvider(database);

    UserSyncTable? userSyncTable = await userSyncTableProvider.get(uuid);

    initStickerManager();
    checkHasUnreadAddFriendRequest();
    syncFriendsGroups(userSyncTable!.updatedTimeForFriendsGroups);
    syncFriendships(userSyncTable.updatedTimeForFriendships);
    await syncChats(userSyncTable.updatedTimeForChats);
    updateTotalNumberOfUnreadMessages();
    syncCommonChatStatus(userSyncTable.lastSyncTimeForCommonChatStatuses);

    SystemPromotionProvider systemPromotionProvider = SystemPromotionProvider(database);
    syncSystemPromotionInformation(
      userSyncTable.lastSyncTimeForSystemPromotionInformation,
      await systemPromotionProvider.getUUIDList(),
    );
  }

  initStickerManager() async {
    StickerManager().setStickerUrlPrefix(context);
  }

  checkHasUnreadAddFriendRequest() async {
    try {
      Response response;
      response = await dioModel.dio.get(
        '/metaUni/userAPI/friendship/request/hasUnread',
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 0:
          BlocManager().hasUnreadAddFriendRequestCubit.update(response.data['data']);
          break;
        case 1:
          //Message:"使用了无效的JWT，请重新登录"
          if (mounted) {
            getNormalSnackBar(context, response.data['message']);
            logout(context);
          }
          break;
        default:
          if (mounted) {
            getNetworkErrorSnackBar(context);
          }
      }
    } catch (e) {
      if (mounted) {
        getNetworkErrorSnackBar(context);
      }
    }
  }

  syncFriendsGroups(DateTime updatedTimeForFriendsGroups) async {
    try {
      Response response;
      response = await dioModel.dio.get(
        '/metaUni/userAPI/friendGroup/sync',
        queryParameters: {
          'updatedTime': updatedTimeForFriendsGroups,
        },
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 0:
          List<dynamic> dataList = response.data['data']['dataList'];
          DateTime updatedTime = DateTime.parse(response.data['data']['updatedTime']);
          Database database = await DatabaseManager().getDatabase;

          await database.transaction((transaction) async {
            FriendsGroupProviderWithTransaction friendsGroupProviderWithTransaction = FriendsGroupProviderWithTransaction(transaction);

            for (var data in dataList) {
              FriendsGroup friendsGroup = FriendsGroup.fromJson(data);
              var g = await friendsGroupProviderWithTransaction.get(friendsGroup.id);
              if (g == null) {
                friendsGroupProviderWithTransaction.insert(friendsGroup);
              } else {
                if (g.updatedTime.isBefore(friendsGroup.updatedTime)) {
                  friendsGroupProviderWithTransaction.update(friendsGroup.toUpdateSql(), friendsGroup.id);
                }
              }
            }

            UserSyncTableProviderWithTransaction userSyncTableProviderWithTransaction = UserSyncTableProviderWithTransaction(transaction);
            userSyncTableProviderWithTransaction.update({
              'updatedTimeForFriendsGroups': updatedTime.millisecondsSinceEpoch,
            }, uuid);
          });
          break;
        case 1:
          //Message:"使用了无效的JWT，请重新登录"
          if (mounted) {
            getNormalSnackBar(context, response.data['message']);
            logout(context);
          }
          break;
        default:
          if (mounted) {
            getNetworkErrorSnackBar(context);
          }
      }
    } catch (e) {
      if (mounted) {
        getNetworkErrorSnackBar(context);
      }
    }
  }

  syncFriendships(DateTime updatedTimeForFriendships) async {
    try {
      Response response;
      response = await dioModel.dio.get(
        '/metaUni/userAPI/friendship/sync',
        queryParameters: {
          'updatedTime': updatedTimeForFriendships,
        },
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 0:
          List<dynamic> friendshipsList = response.data['data']['friendshipsList'];
          List<dynamic> briefUserInformationList = response.data['data']['briefUserInformationList'];
          DateTime updatedTime = DateTime.parse(response.data['data']['updatedTime']);
          Database database = await DatabaseManager().getDatabase;

          await database.transaction((transaction) async {
            FriendshipProviderWithTransaction friendshipProviderWithTransaction = FriendshipProviderWithTransaction(transaction);

            for (var data in friendshipsList) {
              Friendship friendship = Friendship.fromJson(data);
              var f = await friendshipProviderWithTransaction.get(friendship.id);
              if (f == null) {
                friendshipProviderWithTransaction.insert(friendship);
              } else {
                if (f.updatedTime.isBefore(friendship.updatedTime)) {
                  friendshipProviderWithTransaction.update(friendship.toUpdateSql(), friendship.id);
                }
              }
            }

            BriefUserInformationProviderWithTransaction briefUserInformationProviderWithTransaction = BriefUserInformationProviderWithTransaction(transaction);

            for (var data in briefUserInformationList) {
              BriefUserInformation briefUserInformation = BriefUserInformation.fromJson(data);
              var info = await briefUserInformationProviderWithTransaction.get(briefUserInformation.uuid);
              if (info == null) {
                briefUserInformationProviderWithTransaction.insert(briefUserInformation);
              } else {
                if (info.updatedTime.isBefore(briefUserInformation.updatedTime)) {
                  briefUserInformationProviderWithTransaction.update(briefUserInformation.toUpdateSql(), briefUserInformation.uuid);
                }
              }
            }

            UserSyncTableProviderWithTransaction userSyncTableProviderWithTransaction = UserSyncTableProviderWithTransaction(transaction);
            userSyncTableProviderWithTransaction.update({
              'updatedTimeForFriendships': updatedTime.millisecondsSinceEpoch,
            }, uuid);
          });
          break;
        case 1:
          //Message:"使用了无效的JWT，请重新登录"
          if (mounted) {
            getNormalSnackBar(context, response.data['message']);
            logout(context);
          }
          break;
        default:
          if (mounted) {
            getNetworkErrorSnackBar(context);
          }
      }
    } catch (e) {
      if (mounted) {
        getNetworkErrorSnackBar(context);
      }
    }
  }

  syncChats(DateTime updatedTimeForChats) async {
    try {
      Response response;
      response = await dioModel.dio.get(
        '/metaUni/messageAPI/chat/sync',
        queryParameters: {
          'updatedTime': updatedTimeForChats,
        },
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 0:
          List<dynamic> chatsList = response.data['data']['chatsList'];
          List<dynamic> briefChatTargetInformationList = response.data['data']['briefChatTargetInformationList'];
          DateTime updatedTime = DateTime.parse(response.data['data']['updatedTime']);
          Database database = await DatabaseManager().getDatabase;

          await database.transaction((transaction) async {
            ChatProviderWithTransaction chatProviderWithTransaction = ChatProviderWithTransaction(transaction);

            for (var data in chatsList) {
              Chat chat = Chat.fromJson(data);
              var c = await chatProviderWithTransaction.get(chat.id);
              if (c == null) {
                chatProviderWithTransaction.insert(chat);
              } else {
                if (c.updatedTime.isBefore(chat.updatedTime)) {
                  chatProviderWithTransaction.update(chat.toUpdateSql(), chat.id);
                }
              }
            }

            BriefUserInformationProviderWithTransaction briefUserInformationProviderWithTransaction = BriefUserInformationProviderWithTransaction(transaction);

            for (var data in briefChatTargetInformationList) {
              BriefChatTargetInformation briefChatTargetInformation = BriefChatTargetInformation.fromJson(data);

              //后续还会在这里添加group与system
              if (briefChatTargetInformation.targetType == 'user') {
                BriefUserInformation info = BriefUserInformation(
                    uuid: briefChatTargetInformation.id, avatar: briefChatTargetInformation.avatar, nickname: briefChatTargetInformation.name, updatedTime: briefChatTargetInformation.updatedTime);
                var i = await briefUserInformationProviderWithTransaction.get(info.uuid);
                if (i == null) {
                  briefUserInformationProviderWithTransaction.insert(info);
                } else {
                  if (i.updatedTime.isBefore(info.updatedTime)) {
                    briefUserInformationProviderWithTransaction.update(info.toUpdateSql(), info.uuid);
                  }
                }
              }
            }

            UserSyncTableProviderWithTransaction userSyncTableProviderWithTransaction = UserSyncTableProviderWithTransaction(transaction);
            userSyncTableProviderWithTransaction.update({
              'updatedTimeForChats': updatedTime.millisecondsSinceEpoch,
            }, uuid);
          });
          break;
        case 1:
          //Message:"使用了无效的JWT，请重新登录"
          if (mounted) {
            getNormalSnackBar(context, response.data['message']);
            logout(context);
          }
          break;
        default:
          if (mounted) {
            getNetworkErrorSnackBar(context);
          }
      }
    } catch (e) {
      if (mounted) {
        getNetworkErrorSnackBar(context);
      }
    }
  }

  syncCommonChatStatus(DateTime lastSyncTimeForCommonChatStatuses) async {
    try {
      Response response;
      response = await dioModel.dio.get(
        '/metaUni/messageAPI/chat/commonChatStatus/sync',
        queryParameters: {
          'lastSyncTime': lastSyncTimeForCommonChatStatuses,
        },
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 0:
          List<dynamic> dataList = response.data['data']['dataList'];
          DateTime updatedTime = DateTime.parse(response.data['data']['updatedTime']);
          Database database = await DatabaseManager().getDatabase;

          await database.transaction((transaction) async {
            CommonChatStatusProviderWithTransaction commonChatStatusProviderWithTransaction = CommonChatStatusProviderWithTransaction(transaction);

            for (var data in dataList) {
              CommonChatStatus commonChatStatus = CommonChatStatus.fromJson(data);
              var status = await commonChatStatusProviderWithTransaction.get(commonChatStatus.chatId);
              if (status == null) {
                commonChatStatusProviderWithTransaction.insert(commonChatStatus);
              } else {
                if (status.updatedTime.isBefore(commonChatStatus.updatedTime)) {
                  commonChatStatusProviderWithTransaction.update(commonChatStatus.toUpdateSql(), commonChatStatus.chatId);
                }
              }
            }

            UserSyncTableProviderWithTransaction userSyncTableProviderWithTransaction = UserSyncTableProviderWithTransaction(transaction);
            userSyncTableProviderWithTransaction.update({
              'lastSyncTimeForCommonChatStatuses': updatedTime.millisecondsSinceEpoch,
            }, uuid);
          });
          break;
        case 1:
          //Message:"使用了无效的JWT，请重新登录"
          if (mounted) {
            getNormalSnackBar(context, response.data['message']);
            logout(context);
          }
          break;
        default:
          if (mounted) {
            getNetworkErrorSnackBar(context);
          }
      }
    } catch (e) {
      if (mounted) {
        getNetworkErrorSnackBar(context);
      }
    }
  }

  syncSystemPromotionInformation(DateTime lastSyncTimeForSystemPromotionInformation, List<int> queryList) async {
    try {
      Response response;
      response = await dioModel.dio.get(
        '/metaUni/messageAPI/systemPromotion/sync',
        queryParameters: {
          'lastSyncTime': lastSyncTimeForSystemPromotionInformation,
          'queryList': queryList,
        },
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 0:
          List<dynamic> dataList = response.data['data']['dataList'];
          DateTime updatedTime = DateTime.parse(response.data['data']['updatedTime']);
          Database database = await DatabaseManager().getDatabase;

          await database.transaction((transaction) async {
            SystemPromotionProviderWithTransaction systemPromotionProviderWithTransaction = SystemPromotionProviderWithTransaction(transaction);

            for (var data in dataList) {
              SystemPromotion systemPromotion = SystemPromotion.fromJson(data);
              var promotion = await systemPromotionProviderWithTransaction.get(systemPromotion.uuid);
              if (promotion == null) {
                systemPromotionProviderWithTransaction.insert(systemPromotion);
              } else {
                if (promotion.updatedTime.isBefore(systemPromotion.updatedTime)) {
                  systemPromotionProviderWithTransaction.update(systemPromotion.toUpdateSql(), systemPromotion.uuid);
                }
              }
            }

            UserSyncTableProviderWithTransaction userSyncTableProviderWithTransaction = UserSyncTableProviderWithTransaction(transaction);
            userSyncTableProviderWithTransaction.update({
              'lastSyncTimeForSystemPromotionInformation': updatedTime.millisecondsSinceEpoch,
            }, uuid);
          });
          break;
        case 1:
          //Message:"使用了无效的JWT，请重新登录"
          if (mounted) {
            getNormalSnackBar(context, response.data['message']);
            logout(context);
          }
          break;
        default:
          if (mounted) {
            getNetworkErrorSnackBar(context);
          }
      }
    } catch (e) {
      if (mounted) {
        getNetworkErrorSnackBar(context);
      }
    }
  }

  updateTotalNumberOfUnreadMessages() async {
    ChatProvider chatProvider = ChatProvider(database);

    int number = await chatProvider.getTotalNumberOfUnreadMessages();
    BlocManager().totalNumberOfUnreadMessagesCubit.update(number);
  }

  reconnectWebSocket(int lastSequenceForCommonMessages, int lastSequenceForSystemMessages) async {
    // 随机等待一段时间后重连
    // 1~20秒
    int waitTime = Random().nextInt(20) + 1;
    Future.delayed(
      Duration(seconds: waitTime),
    ).then((value) {
      performInitActions();
      initWebSocket(lastSequenceForCommonMessages, lastSequenceForSystemMessages);
    });
  }

  initWebSocket(int? lastSequenceForCommonMessages, int? lastSequenceForSystemMessages) async {
    await WebSocketHelper().initHelper(uuid, jwt);
    int sequenceForCommonMessages;
    int sequenceForSystemMessages;
    if (lastSequenceForCommonMessages != null) {
      sequenceForCommonMessages = lastSequenceForCommonMessages;
    } else {
      sequenceForCommonMessages = await WebSocketHelper().getSequenceForCommonMessages();
    }
    if (lastSequenceForSystemMessages != null) {
      sequenceForSystemMessages = lastSequenceForSystemMessages;
    } else {
      sequenceForSystemMessages = await WebSocketHelper().getSequenceForSystemMessages();
    }
    WebSocketChannel().initChannel(
      WebSocketHelper(),
      BlocManager(),
      sequenceForCommonMessages,
      sequenceForSystemMessages,
      reconnectWebSocket,
    );
  }

  @override
  void initState() {
    super.initState();

    _init();
  }

  @override
  void dispose() {
    WebSocketChannel().closeChannel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<CommonMessageCubit>.value(value: BlocManager().commonMessageCubit),
        BlocProvider<TotalNumberOfUnreadMessagesCubit>.value(value: BlocManager().totalNumberOfUnreadMessagesCubit),
        BlocProvider<ChatListTileCubit>.value(value: BlocManager().chatListTileDataCubit),
        BlocProvider<HasUnreadAddFriendRequestCubit>.value(value: BlocManager().hasUnreadAddFriendRequestCubit),
      ],
      child: Scaffold(
        body: Center(
          child: _widgetOptions.elementAt(currentPageIndex),
        ),
        bottomNavigationBar: NavigationBar(
          onDestinationSelected: (int index) {
            setState(() {
              currentPageIndex = index;
            });
          },
          selectedIndex: currentPageIndex,
          destinations: <Widget>[
            NavigationDestination(
              selectedIcon: Icon(
                Icons.interests,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
              icon: Icon(
                Icons.interests_outlined,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              label: '发现',
            ),
            BlocBuilder<TotalNumberOfUnreadMessagesCubit, int>(
              builder: (context, number) => NavigationDestination(
                selectedIcon: number == 0
                    ? Icon(
                        Icons.sms,
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                      )
                    : Badge(
                        label: Text(number > 99 ? "99+" : number.toString()),
                        child: Icon(
                          Icons.sms,
                          color: Theme.of(context).colorScheme.onSecondaryContainer,
                        ),
                      ),
                icon: number == 0
                    ? Icon(
                        Icons.sms_outlined,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      )
                    : Badge(
                        label: Text(number > 99 ? "99+" : number.toString()),
                        child: Icon(
                          Icons.sms_outlined,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                label: '消息',
              ),
            ),
            NavigationDestination(
              selectedIcon: Icon(
                Icons.account_circle,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
              icon: Icon(
                Icons.account_circle_outlined,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              label: '我的',
            ),
          ],
        ),
      ),
    );
  }
}
