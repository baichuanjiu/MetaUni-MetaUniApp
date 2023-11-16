import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../bloc/bloc_manager.dart';
import '../../../../bloc/contacts/models/should_update_contacts_view_data.dart';
import '../../../../bloc/contacts/should_update_contacts_view_bloc.dart';
import '../../../../database/database_manager.dart';
import '../../../../database/models/friend/friendship.dart';
import '../../../../database/models/friend/friends_group.dart';
import '../../../../database/models/user/brief_user_information.dart';
import '../reusable_components/friend/friend_list_tile.dart';
import '../reusable_components/friend/models/friend_list_tile_data.dart';
import 'models/friends_group_data.dart';

class FriendsGroupsPage extends StatefulWidget {
  const FriendsGroupsPage({super.key});

  @override
  State<FriendsGroupsPage> createState() => _FriendsGroupsPageState();
}

class _FriendsGroupsPageState extends State<FriendsGroupsPage> {
  late List<FriendsGroupData> friendsGroupsData;
  late List<ExpansionPanel> expansionPanels;

  _performInitActions() async {
    friendsGroupsData = [];
    expansionPanels = [];

    await initFriendsGroups();
    await initExpansionPanels();
    setState(() {});
  }

  initFriendsGroups() async {
    Database database = await DatabaseManager().getDatabase;
    FriendsGroupProvider friendsGroupProvider = FriendsGroupProvider(database);
    List<FriendsGroup> friendsGroups = await friendsGroupProvider.getAllNotDeletedOrderByOrderNumber();
    friendsGroups.sort((a, b) => a.orderNumber.compareTo(b.orderNumber));

    for (var friendsGroup in friendsGroups) {
      FriendshipProvider friendShipProvider = FriendshipProvider(database);
      List<Friendship> friends = await friendShipProvider.getFriendsInGroup(friendsGroup.id);
      friendsGroupsData.add(
        FriendsGroupData(
          friendsGroup.friendsGroupName,
          friends,
        ),
      );
    }
  }

  Future<Column> initFriendsInGroup(List<Friendship> friends) async {
    Database database = await DatabaseManager().getDatabase;
    BriefUserInformationProvider briefUserInformationProvider = BriefUserInformationProvider(database);

    List<FriendListTile> tiles = [];
    for (Friendship friend in friends) {
      BriefUserInformation? info = await briefUserInformationProvider.get(friend.friendId);
      if (info != null) {
        tiles.add(
          FriendListTile(
            FriendListTileData(friend.friendId, info.avatar, friend.remark ?? info.nickname),
          ),
        );
      }
    }

    return Column(
      children: [
        ...tiles,
        Container(
          height: 10,
        ),
      ],
    );
  }

  initExpansionPanels() async {
    for (FriendsGroupData friendsGroup in friendsGroupsData) {
      expansionPanels.add(
        ExpansionPanel(
          headerBuilder: (context, isExpand) {
            return SizedBox(
              height: 56,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                    child: Text(
                      friendsGroup.name,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
            );
          },
          isExpanded: false,
          canTapOnHeader: true,
          body: friendsGroup.friends.isEmpty
              ? Column(
                  children: [
                    Center(
                      child: Text(
                        "该分组下没有任何好友呢！",
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    Container(
                      height: 10,
                    ),
                  ],
                )
              : await initFriendsInGroup(friendsGroup.friends),
        ),
      );
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
    return FutureBuilder(
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
              return BlocProvider<ShouldUpdateContactsViewCubit>.value(
                value: BlocManager().shouldUpdateContactsViewCubit,
                child: BlocListener<ShouldUpdateContactsViewCubit, ShouldUpdateContactsViewData?>(
                  listener: (context, newStatus) {
                    _performInitActions();
                  },
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverOverlapInjector(
                        handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (BuildContext context, int index) {
                            return ExpansionPanelList(
                              expansionCallback: (index, isExpand) {
                                setState(() {
                                  expansionPanels[index] = ExpansionPanel(
                                    headerBuilder: expansionPanels[index].headerBuilder,
                                    isExpanded: isExpand,
                                    canTapOnHeader: expansionPanels[index].canTapOnHeader,
                                    body: expansionPanels[index].body,
                                  );
                                });
                              },
                              children: expansionPanels,
                            );
                          },
                          childCount: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            default:
              return const LoadingPage();
          }
        });
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
