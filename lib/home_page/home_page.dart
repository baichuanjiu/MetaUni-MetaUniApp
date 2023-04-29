import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
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

  static const List<Widget> _widgetOptions = <Widget>[
    DiscoverPage(),
    ChatsPage(),
    MePage(),
  ];

  initDatabase() async {
    if (DatabaseManager().getDatabaseName() == null) {
      final prefs = await SharedPreferences.getInstance();

      final int? uuid = prefs.getInt('uuid');
      DatabaseManager().setDatabaseName(uuid.toString());
    }
  }

  performSyncActions() async {
    Database database = await DatabaseManager().getDatabase;
    UserSyncTableProvider userSyncTableProvider = UserSyncTableProvider(database);
    final prefs = await SharedPreferences.getInstance();

    final int? uuid = prefs.getInt('uuid');
    UserSyncTable? userSyncTable = await userSyncTableProvider.get(uuid!);

    await syncFriendsGroups(userSyncTable!.updatedTimeForFriendsGroups);
    await syncFriendships(userSyncTable.updatedTimeForFriendships);
    await syncChats(userSyncTable.updatedTimeForChats);
  }

  final DioModel dioModel = DioModel();

  syncFriendsGroups(DateTime updatedTimeForFriendsGroups) async {
    final prefs = await SharedPreferences.getInstance();

    final String? jwt = prefs.getString('jwt');
    final int? uuid = prefs.getInt('uuid');

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
        case 1:
          //Message:"使用了无效的JWT，请重新登录"
          if (mounted) {
            getNormalSnackBar(context, response.data['message']);
            logout(context);
          }
          break;
        default:
          List<dynamic> dataList = response.data['data']['dataList'];
          DateTime updatedTime = DateTime.parse(response.data['data']['updatedTime']);
          Database database = await DatabaseManager().getDatabase;

          await database.transaction((transaction) async {
            FriendsGroupProviderWithTransaction friendsGroupProviderWithTransaction = FriendsGroupProviderWithTransaction(transaction);

            for (var data in dataList) {
              FriendsGroup friendsGroup = FriendsGroup.fromJson(data);
              if (await friendsGroupProviderWithTransaction.get(friendsGroup.id) == null) {
                friendsGroupProviderWithTransaction.insert(friendsGroup);
              } else {
                friendsGroupProviderWithTransaction.update(friendsGroup.toUpdateSql(), friendsGroup.id);
              }
            }

            UserSyncTableProviderWithTransaction userSyncTableProviderWithTransaction = UserSyncTableProviderWithTransaction(transaction);
            userSyncTableProviderWithTransaction.update({
              'updatedTimeForFriendsGroups': updatedTime.millisecondsSinceEpoch,
            }, uuid!);
          });
      }
    } catch (e) {
      if (mounted) {
        getNetworkErrorSnackBar(context);
      }
    }
  }

  syncFriendships(DateTime updatedTimeForFriendships) async {
    final prefs = await SharedPreferences.getInstance();

    final String? jwt = prefs.getString('jwt');
    final int? uuid = prefs.getInt('uuid');

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
        case 1:
          //Message:"使用了无效的JWT，请重新登录"
          if (mounted) {
            getNormalSnackBar(context, response.data['message']);
            logout(context);
          }
          break;
        default:
          List<dynamic> friendshipsList = response.data['data']['friendshipsList'];
          List<dynamic> briefUserInformationList = response.data['data']['briefUserInformationList'];
          DateTime updatedTime = DateTime.parse(response.data['data']['updatedTime']);
          Database database = await DatabaseManager().getDatabase;

          await database.transaction((transaction) async {
            FriendshipProviderWithTransaction friendshipProviderWithTransaction = FriendshipProviderWithTransaction(transaction);

            for (var data in friendshipsList) {
              Friendship friendship = Friendship.fromJson(data);
              if (await friendshipProviderWithTransaction.get(friendship.id) == null) {
                friendshipProviderWithTransaction.insert(friendship);
              } else {
                friendshipProviderWithTransaction.update(friendship.toUpdateSql(), friendship.id);
              }
            }

            BriefUserInformationProviderWithTransaction briefUserInformationProviderWithTransaction = BriefUserInformationProviderWithTransaction(transaction);

            for (var data in briefUserInformationList) {
              BriefUserInformation briefUserInformation = BriefUserInformation.fromJson(data);
              if (await briefUserInformationProviderWithTransaction.get(briefUserInformation.uuid) == null) {
                briefUserInformationProviderWithTransaction.insert(briefUserInformation);
              } else {
                briefUserInformationProviderWithTransaction.update(briefUserInformation.toUpdateSql(), briefUserInformation.uuid);
              }
            }

            UserSyncTableProviderWithTransaction userSyncTableProviderWithTransaction = UserSyncTableProviderWithTransaction(transaction);
            userSyncTableProviderWithTransaction.update({
              'updatedTimeForFriendships': updatedTime.millisecondsSinceEpoch,
            }, uuid!);
          });
      }
    } catch (e) {
      if (mounted) {
        getNetworkErrorSnackBar(context);
      }
    }
  }

  syncChats(DateTime updatedTimeForChats) async {
    final prefs = await SharedPreferences.getInstance();

    final String? jwt = prefs.getString('jwt');
    final int? uuid = prefs.getInt('uuid');

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
        case 1:
          //Message:"使用了无效的JWT，请重新登录"
          if (mounted) {
            getNormalSnackBar(context, response.data['message']);
            logout(context);
          }
          break;
        default:
          List<dynamic> chatsList = response.data['data']['chatsList'];
          List<dynamic> briefChatTargetInformationList = response.data['data']['briefChatTargetInformationList'];
          DateTime updatedTime = DateTime.parse(response.data['data']['updatedTime']);
          Database database = await DatabaseManager().getDatabase;

          await database.transaction((transaction) async {
            ChatProviderWithTransaction chatProviderWithTransaction = ChatProviderWithTransaction(transaction);

            for (var data in chatsList) {
              Chat chat = Chat.fromJson(data);
              if (await chatProviderWithTransaction.get(chat.id) == null) {
                chatProviderWithTransaction.insert(chat);
              } else {
                chatProviderWithTransaction.update(chat.toUpdateSql(), chat.id);
              }
            }

            BriefUserInformationProviderWithTransaction briefUserInformationProviderWithTransaction = BriefUserInformationProviderWithTransaction(transaction);

            for (var data in briefChatTargetInformationList) {
              BriefChatTargetInformation briefChatTargetInformation = BriefChatTargetInformation.fromJson(data);

              //后续还会在这里添加group与system
              if (briefChatTargetInformation.targetType == 'user') {
                BriefUserInformation info = BriefUserInformation(
                    uuid: briefChatTargetInformation.id, avatar: briefChatTargetInformation.avatar, nickname: briefChatTargetInformation.name, updatedTime: briefChatTargetInformation.updatedTime);
                if (await briefUserInformationProviderWithTransaction.get(info.uuid) == null) {
                  briefUserInformationProviderWithTransaction.insert(info);
                } else {
                  briefUserInformationProviderWithTransaction.update(info.toUpdateSql(), info.uuid);
                }
              }
            }

            UserSyncTableProviderWithTransaction userSyncTableProviderWithTransaction = UserSyncTableProviderWithTransaction(transaction);
            userSyncTableProviderWithTransaction.update({
              'updatedTimeForChats': updatedTime.millisecondsSinceEpoch,
            }, uuid!);
          });
      }
    } catch (e) {
      if (mounted) {
        getNetworkErrorSnackBar(context);
      }
    }
  }

  initWebSocket() async {
    final prefs = await SharedPreferences.getInstance();

    final String? jwt = prefs.getString('jwt');
    final int? uuid = prefs.getInt('uuid');

    if (jwt != null && uuid != null) {
      WebSocketChannel().initChannel(uuid, jwt);
    }
  }

  @override
  void initState() {
    super.initState();

    initDatabase();
    performSyncActions();
    initWebSocket();
  }

  @override
  void dispose() {
    super.dispose();

    WebSocketChannel().closeChannel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          NavigationDestination(
            selectedIcon: Icon(
              Icons.sms,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
            icon: Icon(
              Icons.sms_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            label: '消息',
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
    );
  }
}
