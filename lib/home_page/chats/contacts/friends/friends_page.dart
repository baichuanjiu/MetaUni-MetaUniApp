import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lpinyin/lpinyin.dart';
import 'package:meta_uni_app/bloc/contacts/should_update_contacts_view_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../bloc/bloc_manager.dart';
import '../../../../bloc/contacts/models/should_update_contacts_view_data.dart';
import '../../../../database/database_manager.dart';
import '../../../../database/models/friend/friendship.dart';
import '../../../../database/models/user/brief_user_information.dart';
import '../../../../models/dio_model.dart';
import '../../../../reusable_components/logout/logout.dart';
import '../../../../reusable_components/snack_bar/network_error_snack_bar.dart';
import '../../../../reusable_components/snack_bar/normal_snack_bar.dart';
import '../reusable_components/friend/friend_list_tile.dart';
import '../reusable_components/friend/models/friend_list_tile_data.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  late List<FriendListTileData> friends;
  late Map<String, List<FriendListTile>> indexMap;
  final Set<String> alphabet = {'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'};
  double indexHeight = 16;
  double labelHeight = 24;

  _performInitActions() async {
    friends = [];
    indexMap = {
      'A': [],
      'B': [],
      'C': [],
      'D': [],
      'E': [],
      'F': [],
      'G': [],
      'H': [],
      'I': [],
      'J': [],
      'K': [],
      'L': [],
      'M': [],
      'N': [],
      'O': [],
      'P': [],
      'Q': [],
      'R': [],
      'S': [],
      'T': [],
      'U': [],
      'V': [],
      'W': [],
      'X': [],
      'Y': [],
      'Z': [],
      '#': [],
    };
    indexList = [];
    index = [];
    currentIndex = 0;

    await initFriends();
    initFriendListTiles();
    computeIndexPositions();
    initAsideIndexBar();
    setState(() {});
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
        case 0:
          Database database = await DatabaseManager().getDatabase;
          BriefUserInformationProvider briefUserInformationProvider = BriefUserInformationProvider(database);
          BriefUserInformation briefUserInformation = BriefUserInformation.fromJson(response.data['data']);
          if (await briefUserInformationProvider.get(briefUserInformation.uuid) == null) {
            briefUserInformationProvider.insert(briefUserInformation);
          } else {
            briefUserInformationProvider.update(briefUserInformation.toUpdateSql(), briefUserInformation.uuid);
          }
          break;
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

  initFriends() async {
    Database database = await DatabaseManager().getDatabase;
    FriendshipProvider friendShipProvider = FriendshipProvider(database);
    BriefUserInformationProvider briefUserInformationProvider = BriefUserInformationProvider(database);

    List<Friendship> friendShips = await friendShipProvider.getAllNotDeleted();
    for (var friendShip in friendShips) {
      BriefUserInformation? info = await briefUserInformationProvider.get(friendShip.friendId);
      if (info == null) {
        await getBriefUserInformation(friendShip.friendId);
        info = await briefUserInformationProvider.get(friendShip.friendId);
        friends.add(
          FriendListTileData(friendShip.friendId, info!.avatar, friendShip.remark ?? info.nickname),
        );
      } else {
        friends.add(
          FriendListTileData(friendShip.friendId, info.avatar, friendShip.remark ?? info.nickname),
        );
      }
    }
  }

  void initFriendListTiles() {
    for (FriendListTileData friend in friends) {
      //获取首字母
      String index = PinyinHelper.getFirstWordPinyin(
        friend.appellation,
      ).substring(0, 1).toUpperCase();

      //如果可以识别为字母A-Z的话
      if (alphabet.contains(index)) {
        indexMap[index]!.add(
          FriendListTile(friend),
        );
      }
      //其它情况下（如数字）归类为特殊字符 #
      else {
        indexMap["#"]!.add(
          FriendListTile(friend),
        );
      }
    }
  }

  List<double> indexPositions = [0];

  void computeIndexPositions() {
    indexMap.forEach(
      (key, value) {
        if (value.isNotEmpty) {
          indexPositions.add(indexPositions[indexPositions.length - 1] + labelHeight + value.length * 56);
        }
      },
    );
  }

  PrimaryScrollController? primaryScrollController;

  void jumpToIndex(int newIndex) {
    if (newIndex > index.length) {
      newIndex = index.length;
    } else if (newIndex < 0) {
      newIndex = 0;
    }

    if (newIndex > 0) {
      setState(() {
        currentIndex = newIndex;
      });
      if (primaryScrollController!.controller!.positions.toList()[0].maxScrollExtent >= indexPositions[currentIndex - 1]) {
        primaryScrollController!.controller!.jumpTo(indexPositions[currentIndex - 1]);
      }
    }
  }

  late Future<dynamic> performInitActions;

  @override
  void initState() {
    super.initState();
    performInitActions = _performInitActions();
    primaryScrollController = context.findAncestorWidgetOfExactType<PrimaryScrollController>();
  }

  late List<SizedBox> indexList;
  late List<String> index;
  late int currentIndex;

  void initAsideIndexBar() {
    indexMap.forEach(
      (key, value) {
        if (value.isNotEmpty) {
          indexList.add(
            SizedBox(
              height: indexHeight,
              width: 28,
              child: Center(
                child: Text(
                  key,
                  style: Theme.of(context).textTheme.labelSmall!.apply(color: Theme.of(context).colorScheme.onSurface),
                ),
              ),
            ),
          );
          index.add(key);
        }
      },
    );
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
                child: friends.isEmpty
                    ? Center(
                        child: Text(
                          '还未添加任何好友呢！',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      )
                    : Stack(
                        children: [
                          CustomScrollView(
                            physics: const BouncingScrollPhysics(),
                            slivers: [
                              SliverOverlapInjector(
                                handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                              ),
                              SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (BuildContext context, int index) {
                                    String key = indexMap.keys.toList()[index];
                                    if (indexMap[key]!.isNotEmpty) {
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            height: labelHeight,
                                            padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                                            color: Theme.of(context).colorScheme.surfaceVariant,
                                            child: Row(
                                              children: [
                                                Text(
                                                  key,
                                                  style: Theme.of(context).textTheme.labelLarge!.apply(color: Theme.of(context).colorScheme.onSurfaceVariant),
                                                ),
                                              ],
                                            ),
                                          ),
                                          ...indexMap[key]!,
                                        ],
                                      );
                                    }
                                    return Container();
                                  },
                                  childCount: indexMap.length,
                                ),
                              ),
                            ],
                          ),
                          Positioned(
                            bottom: 500 - (indexHeight * (index.length + 1)),
                            right: 0,
                            child: SizedBox(
                              height: (indexList.length + 2) * indexHeight,
                              width: 78,
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 50,
                                    child: Stack(
                                      alignment: AlignmentDirectional.center,
                                      children: [
                                        currentIndex == 0
                                            ? Container()
                                            : Positioned(
                                                top: indexHeight * currentIndex - indexHeight,
                                                child: IndexBubble(index[currentIndex - 1], indexHeight),
                                              ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    width: 28,
                                    child: GestureDetector(
                                      onVerticalDragStart: (details) {
                                        double position = details.localPosition.dy;
                                        jumpToIndex((position) ~/ indexHeight);
                                      },
                                      onVerticalDragUpdate: (details) {
                                        double position = details.localPosition.dy;
                                        jumpToIndex((position) ~/ indexHeight);
                                      },
                                      onVerticalDragEnd: (details) {
                                        setState(() {
                                          currentIndex = 0;
                                        });
                                      },
                                      child: Column(
                                        children: [
                                          SizedBox(
                                            height: indexHeight,
                                            width: 28,
                                            child: Center(
                                              child: Icon(
                                                Icons.search_outlined,
                                                size: 12,
                                                color: Theme.of(context).colorScheme.onSurface,
                                              ),
                                            ),
                                          ),
                                          ...indexList,
                                        ],
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            );
          default:
            return const LoadingPage();
        }
      },
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

class IndexBubble extends StatelessWidget {
  final String index;
  final double indexHeight;

  const IndexBubble(this.index, this.indexHeight, {super.key});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: IndexBubbleClipper(),
      child: Container(
        height: indexHeight + indexHeight * 2,
        width: 48,
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Center(
          child: Text(
            index,
            style: Theme.of(context).textTheme.bodyLarge!.apply(color: Theme.of(context).colorScheme.onPrimaryContainer),
          ),
        ),
      ),
    );
  }
}

class IndexBubbleClipper extends CustomClipper<Path> {
  final Radius radius = const Radius.circular(24);

  @override
  Path getClip(Size size) {
    Path path = Path();

    path.addRRect(
      RRect.fromRectAndCorners(Rect.fromLTWH(0, 0, size.width, size.height), topLeft: radius, bottomLeft: radius, topRight: radius, bottomRight: radius),
    );

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
}
