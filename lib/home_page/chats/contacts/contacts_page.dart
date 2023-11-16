import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta_uni_app/home_page/chats/contacts/reusable_components/receive_add_friend_request/receive_add_friend_request_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../../../bloc/bloc_manager.dart';
import '../../../bloc/contacts/has_unread_add_friend_request_bloc.dart';
import '../../../bloc/message/total_number_of_unread_messages_bloc.dart';
import '../../../database/database_manager.dart';
import '../../../database/models/user/brief_user_information.dart';
import '../../../database/models/user/user_sync_table.dart';
import '../../../models/dio_model.dart';
import '../../../reusable_components/logout/logout.dart';
import '../../../reusable_components/snack_bar/network_error_snack_bar.dart';
import '../../../reusable_components/snack_bar/normal_snack_bar.dart';
import '../search/search_box.dart';
import 'friends/friends_page.dart';
import 'friends_groups/friends_groups_page.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  final _tabs = const <Tab>[
    Tab(
      text: '好友',
    ),
    Tab(
      text: '分组',
    ),
    Tab(
      text: '群聊',
    ),
  ];

  performSyncActions() async {
    Database database = await DatabaseManager().getDatabase;
    UserSyncTableProvider userSyncTableProvider = UserSyncTableProvider(database);
    final prefs = await SharedPreferences.getInstance();

    final int? uuid = prefs.getInt('uuid');
    UserSyncTable? userSyncTable = await userSyncTableProvider.get(uuid!);

    await syncFriendsInformation(userSyncTable!.lastSyncTimeForFriendsBriefInformation);
  }

  final DioModel dioModel = DioModel();

  syncFriendsInformation(DateTime lastSyncTimeForFriendsBriefInformation) async {
    final prefs = await SharedPreferences.getInstance();

    final String? jwt = prefs.getString('jwt');
    final int? uuid = prefs.getInt('uuid');

    try {
      Response response;
      response = await dioModel.dio.get(
        '/metaUni/userAPI/friendship/friendsInformation/sync',
        queryParameters: {
          'lastSyncTime': lastSyncTimeForFriendsBriefInformation,
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
            BriefUserInformationProviderWithTransaction briefUserInformationProviderWithTransaction = BriefUserInformationProviderWithTransaction(transaction);

            for (var data in dataList) {
              BriefUserInformation briefUserInformation = BriefUserInformation.fromJson(data);
              if (await briefUserInformationProviderWithTransaction.get(briefUserInformation.uuid) == null) {
                briefUserInformationProviderWithTransaction.insert(briefUserInformation);
              } else {
                briefUserInformationProviderWithTransaction.update(briefUserInformation.toUpdateSql(), briefUserInformation.uuid);
              }
            }

            UserSyncTableProviderWithTransaction userSyncTableProviderWithTransaction = UserSyncTableProviderWithTransaction(transaction);
            userSyncTableProviderWithTransaction.update({
              'lastSyncTimeForFriendsBriefInformation': updatedTime.millisecondsSinceEpoch,
            }, uuid!);
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

  @override
  void initState() {
    super.initState();

    performSyncActions();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<TotalNumberOfUnreadMessagesCubit>.value(value: BlocManager().totalNumberOfUnreadMessagesCubit),
        BlocProvider<HasUnreadAddFriendRequestCubit>.value(value: BlocManager().hasUnreadAddFriendRequestCubit),
      ],
      child: Scaffold(
        body: DefaultTabController(
          initialIndex: 1,
          length: _tabs.length,
          child: NestedScrollView(
            physics: const BouncingScrollPhysics(),
            headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
              return [
                SliverOverlapAbsorber(
                  handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                  sliver: SliverAppBar(
                    title: const Text('通讯录'),
                    expandedHeight: 275,
                    collapsedHeight: 56,
                    floating: false,
                    pinned: true,
                    snap: false,
                    leading: IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: BlocBuilder<TotalNumberOfUnreadMessagesCubit, int>(
                        builder: (context, number) => number == 0
                            ? const Icon(Icons.arrow_back_ios_new_outlined)
                            : Badge(
                                label: Text(number > 99 ? "99+" : number.toString()),
                                child: const Icon(Icons.arrow_back_ios_new_outlined),
                              ),
                      ),
                    ),
                    actions: [
                      IconButton(
                        tooltip: '添加',
                        onPressed: () {
                          Navigator.pushNamed(context, '/contacts/search');
                        },
                        icon: const Icon(Icons.person_add_alt_outlined),
                      ),
                    ],
                    forceElevated: innerBoxIsScrolled,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.fromLTRB(0, 80, 0, 5),
                              child: const ChatsSearchBox(),
                            ),
                            Column(
                              children: ListTile.divideTiles(
                                context: context,
                                tiles: [
                                  ListTile(
                                    title: const Text('新朋友'),
                                    trailing: BlocBuilder<HasUnreadAddFriendRequestCubit, bool>(
                                      builder: (context, state) {
                                        return state
                                            ? const Badge(
                                                child: Icon(
                                                  Icons.chevron_right_outlined,
                                                ),
                                              )
                                            : const Icon(
                                                Icons.chevron_right_outlined,
                                              );
                                      },
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const ReceiveAddFriendRequestPage(),
                                        ),
                                      );
                                    },
                                  ),
                                  ListTile(
                                    title: const Text('群通知'),
                                    trailing: const Icon(
                                      Icons.chevron_right_outlined,
                                    ),
                                    onTap: () {},
                                  ),
                                ],
                              ).toList(),
                            ),
                          ],
                        ),
                      ),
                      collapseMode: CollapseMode.parallax,
                    ),
                    bottom: TabBar(
                      tabs: _tabs,
                      unselectedLabelStyle: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              children: [
                const FriendsPage(),
                const FriendsGroupsPage(),
                Builder(
                  builder: (BuildContext context) {
                    return CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverOverlapInjector(
                          handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                        ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (BuildContext context, int index) {
                              return ListTile(
                                leading: SizedBox(
                                  width: 45,
                                  height: 45,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(5),
                                    child: const Image(
                                      image: AssetImage('assets/DefaultAvatar.jpg'),
                                    ),
                                  ),
                                ),
                                title: const Text(
                                  '女朋友',
                                ),
                                subtitle: const Text('Hello,World!'),
                                trailing: Text(
                                  '05:20',
                                  style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 11),
                                ),
                                onTap: () {},
                              );
                            },
                            childCount: 30,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
