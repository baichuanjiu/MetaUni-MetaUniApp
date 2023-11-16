import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../../../database/database_manager.dart';
import '../../../database/models/friend/friends_group.dart';

// 这个页面估计是要重写一下了，奇怪的地方有点多
class ChooseFriendsGroupPage extends StatefulWidget {
  final int currentChosenGroupId;

  const ChooseFriendsGroupPage({super.key, required this.currentChosenGroupId});

  @override
  State<ChooseFriendsGroupPage> createState() => _ChooseFriendsGroupPageState();
}

class _ChooseFriendsGroupPageState extends State<ChooseFriendsGroupPage> {
  late Database database;
  late FriendsGroupProvider friendsGroupProvider;

  List<FriendsGroup> friendsGroups = [];
  List<ListTile> friendsGroupTiles = [];

  late int currentChosenGroupId = widget.currentChosenGroupId;

  late Future<dynamic> init;

  _init() async {
    database = await DatabaseManager().getDatabase;

    friendsGroupProvider = FriendsGroupProvider(database);
    friendsGroups = await friendsGroupProvider.getAllNotDeletedOrderByOrderNumber();

    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    init = _init();
  }

  @override
  Widget build(BuildContext context) {
    friendsGroupTiles = [];

    for (var element in friendsGroups) {
      if (element.id != currentChosenGroupId) {
        friendsGroupTiles.add(
          ListTile(
            title: Text(
              element.friendsGroupName,
            ),
            onTap: () {
              currentChosenGroupId = element.id;
              setState(() {});
            },
          ),
        );
      } else {
        friendsGroupTiles.add(
          ListTile(
            title: Text(
              element.friendsGroupName,
            ),
            trailing: Icon(
              Icons.done_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            onTap: () {},
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("选择分组"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, currentChosenGroupId);
            },
            child: Text(
              "确定",
              style: Theme.of(context).textTheme.titleMedium?.apply(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
        ],
      ),
      body: FutureBuilder(
        future: init,
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
              return const CupertinoActivityIndicator();
            case ConnectionState.active:
              return const CupertinoActivityIndicator();
            case ConnectionState.waiting:
              return const CupertinoActivityIndicator();
            case ConnectionState.done:
              if (snapshot.hasError) {
                return const CupertinoActivityIndicator();
              }
              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            title: const Text(
                              "创建新分组",
                            ),
                            trailing: const Icon(
                              Icons.chevron_right_outlined,
                            ),
                            onTap: () {},
                          ),
                          const Divider(),
                          ...friendsGroupTiles,
                        ],
                      ),
                    ),
                  ),
                ],
              );
            default:
              return const CupertinoActivityIndicator();
          }
        },
      ),
    );
  }
}
