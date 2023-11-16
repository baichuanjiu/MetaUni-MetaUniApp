import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../database/models/user/brief_user_information.dart';
import '../../../../reusable_components/get_current_user_information/get_current_user_information.dart';
import '../../../../reusable_components/logout/logout.dart';
import '../../../../reusable_components/shimmer/shimmer.dart';
import '../../../../reusable_components/snack_bar/network_error_snack_bar.dart';
import '../../../../reusable_components/snack_bar/normal_snack_bar.dart';
import '../../../mini_app_manager.dart';
import '../reusable_components/sticker/models/sticker_data.dart';
import '../reusable_components/sticker/sticker/sticker_with_delete_action.dart';
import '../search/search_page.dart';

class WallStickerMePage extends StatefulWidget {
  const WallStickerMePage({super.key});

  @override
  State<WallStickerMePage> createState() => _WallStickerMePageState();
}

class _WallStickerMePageState extends State<WallStickerMePage> {
  final ScrollController _scrollController = ScrollController();

  late Future<dynamic> initMyBriefInformation;
  late BriefUserInformation me;

  _initMyBriefInformation() async {
    me = await getCurrentUserInformation();
  }

  late Dio dio;

  _initDio() async {
    dio = Dio(
      BaseOptions(
        baseUrl: (await MiniAppManager().getCurrentMiniAppUrl())!,
      ),
    );
  }

  late final SharedPreferences prefs;
  late final String? jwt;
  late final int? uuid;

  late Future<dynamic> initMyStickers;
  late int myStickersNumber = 0;

  _getMyStickersNumber() async {
    try {
      Response response;
      response = await dio.get(
        '/wallSticker/stickerAPI/sticker/me/stickersNumber',
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 0:
          setState(() {
            myStickersNumber = response.data['data'];
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

  List<StickerData> dataList = [];
  Widget endIndicator = Container();
  DateTime? lastDateTime;
  String? lastId;
  bool isLoading = false;
  bool hasMore = true;

  _getMyStickersByLastResult() async {
    isLoading = true;
    hasMore = false;

    try {
      Response response;
      response = await dio.get(
        lastDateTime == null && lastId == null ? '/wallSticker/stickerAPI/sticker/me/stickers' : '/wallSticker/stickerAPI/sticker/me/stickers/$lastDateTime/$lastId',
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 0:
          List<dynamic> tempDataList = response.data['data']['dataList'];
          for (var data in tempDataList) {
            dataList.add(StickerData.fromJson(data));
          }
          if (dataList.isNotEmpty) {
            lastDateTime = dataList.last.createdTime;
            lastId = dataList.last.id;
          }
          if (tempDataList.length < 20) {
            endIndicator = Center(
              child: Container(
                padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                child: const Text("没有更多了呢"),
              ),
            );
            hasMore = false;
          } else {
            hasMore = true;
          }
          setState(() {});
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

    isLoading = false;
  }

  _initMyStickers() async {
    await _initDio();
    prefs = await SharedPreferences.getInstance();
    jwt = prefs.getString('jwt');
    uuid = prefs.getInt('uuid');

    _getMyStickersNumber();
    await _getMyStickersByLastResult();
  }

  _refresh() async {
    dataList = [];
    endIndicator = Container();
    lastDateTime = null;
    lastId = null;
    isLoading = false;
    hasMore = true;
    _getMyStickersNumber();
    await _getMyStickersByLastResult();
  }

  Future<bool> _deleteSticker(String id) async {
    try {
      Response response;
      response = await dio.delete(
        '/wallSticker/stickerAPI/sticker/$id',
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 0:
          setState(() {
            myStickersNumber--;
          });
          return true;
        //break;
        case 1:
          //Message:"使用了无效的JWT，请重新登录"
          if (mounted) {
            getNormalSnackBar(context, response.data['message']);
            logout(context);
            return false;
          }
          break;
        case 2:
        //Message:"您正在对一个不存在或已被删除的贴贴进行删除"
        case 3:
          //Message:"您正在对一个不属于您的贴贴进行删除"
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
    return false;
  }

  Future<bool> _onDelete(String id) async {
    if ((await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('将这条贴贴撕下'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('确定'),
              ),
            ],
          ),
        )) ==
        true) {
      return await _deleteSticker(id);
    }

    return false;
  }

  bool shouldShowFab = false;

  @override
  void initState() {
    super.initState();

    initMyBriefInformation = _initMyBriefInformation();
    initMyStickers = _initMyStickers();

    _scrollController.addListener(() {
      if (_scrollController.offset.abs() >= MediaQuery.of(context).size.height) {
        setState(() {
          shouldShowFab = true;
        });
      } else {
        setState(() {
          shouldShowFab = false;
        });
      }
      if (_scrollController.position.extentAfter < 300 && !isLoading && hasMore) {
        isLoading = true;
        _getMyStickersByLastResult();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("我的"),
        automaticallyImplyLeading: true,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) {
                  return const WallStickerSearchPage(
                    searchMode: "me",
                  );
                }),
              );
            },
            icon: const Icon(
              Icons.search_outlined,
            ),
            tooltip: "搜索",
          ),
        ],
      ),
      floatingActionButton: shouldShowFab
          ? FloatingActionButton(
              onPressed: () {
                _scrollController.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.ease);
              },
              child: _scrollController.offset >= 0
                  ? const Icon(
                      Icons.arrow_upward,
                    )
                  : const Icon(
                      Icons.arrow_downward,
                    ),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await _refresh();
                },
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          FutureBuilder(
                              future: initMyBriefInformation,
                              builder: (context, snapshot) {
                                switch (snapshot.connectionState) {
                                  case ConnectionState.none:
                                    return const MyInformationLoadingPlaceholder();
                                  case ConnectionState.active:
                                    return const MyInformationLoadingPlaceholder();
                                  case ConnectionState.waiting:
                                    return const MyInformationLoadingPlaceholder();
                                  case ConnectionState.done:
                                    if (snapshot.hasError) {
                                      return const MyInformationLoadingPlaceholder();
                                    }
                                    return InkWell(
                                      onTap: () {
                                        Navigator.pushNamed(context, '/user/profile', arguments: me.uuid).then((value) {
                                          setState(() {
                                            _initMyBriefInformation();
                                          });
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
                                        child: Row(
                                          children: [
                                            Avatar(me.avatar),
                                            Expanded(
                                              child: Container(
                                                padding: const EdgeInsets.fromLTRB(15, 0, 0, 0),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    SingleChildScrollView(
                                                      scrollDirection: Axis.horizontal,
                                                      physics: const BouncingScrollPhysics(),
                                                      child: Text(
                                                        me.nickname,
                                                        style: Theme.of(context).textTheme.headlineSmall,
                                                      ),
                                                    ),
                                                    SingleChildScrollView(
                                                      scrollDirection: Axis.horizontal,
                                                      physics: const BouncingScrollPhysics(),
                                                      child: Text(
                                                        'UUID：${me.uuid.toString()}',
                                                        style: Theme.of(context).textTheme.labelSmall?.apply(color: Theme.of(context).colorScheme.outline),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            Container(
                                              constraints: BoxConstraints(
                                                maxWidth: MediaQuery.of(context).size.width * 0.45,
                                              ),
                                              child: SingleChildScrollView(
                                                scrollDirection: Axis.horizontal,
                                                physics: const BouncingScrollPhysics(),
                                                child: Text("$myStickersNumber条贴贴"),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  default:
                                    return const MyInformationLoadingPlaceholder();
                                }
                              }),
                          const Divider(),
                        ],
                      ),
                    ),
                    FutureBuilder(
                        future: initMyStickers,
                        builder: (context, snapshot) {
                          switch (snapshot.connectionState) {
                            case ConnectionState.none:
                              return const SliverToBoxAdapter(
                                child: Center(
                                  child: CupertinoActivityIndicator(),
                                ),
                              );
                            case ConnectionState.active:
                              return const SliverToBoxAdapter(
                                child: Center(
                                  child: CupertinoActivityIndicator(),
                                ),
                              );
                            case ConnectionState.waiting:
                              return const SliverToBoxAdapter(
                                child: Center(
                                  child: CupertinoActivityIndicator(),
                                ),
                              );
                            case ConnectionState.done:
                              if (snapshot.hasError) {
                                return const SliverToBoxAdapter(
                                  child: Center(
                                    child: CupertinoActivityIndicator(),
                                  ),
                                );
                              }
                              return SliverList.builder(
                                itemCount: dataList.length,
                                itemBuilder: (context, index) {
                                  return StickerWithDeleteAction(
                                    stickerData: dataList[index],
                                    onDelete: _onDelete,
                                  );
                                },
                              );
                            default:
                              return const SliverToBoxAdapter(
                                child: Center(
                                  child: CupertinoActivityIndicator(),
                                ),
                              );
                          }
                        }),
                    SliverToBoxAdapter(
                      child: endIndicator,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MyInformationLoadingPlaceholder extends StatelessWidget {
  const MyInformationLoadingPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ShimmerLoading(
        child: Container(
          padding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
          child: Row(
            children: [
              SizedBox(
                width: 55,
                height: 55,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    color: Theme.of(context).colorScheme.surface,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(15, 0, 0, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 24,
                      width: 123,
                      margin: const EdgeInsets.fromLTRB(0, 4, 0, 4),
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    Container(
                      height: 11,
                      width: 101,
                      margin: const EdgeInsets.fromLTRB(0, 2.5, 0, 2.5),
                      color: Theme.of(context).colorScheme.surface,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Avatar extends StatelessWidget {
  final String avatar;

  const Avatar(this.avatar, {super.key});

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      fadeInDuration: const Duration(milliseconds: 800),
      fadeOutDuration: const Duration(milliseconds: 200),
      placeholder: (context, url) => SizedBox(
        width: 55,
        height: 55,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: const Center(
            child: CupertinoActivityIndicator(),
          ),
        ),
      ),
      imageUrl: avatar,
      imageBuilder: (context, imageProvider) => SizedBox(
        width: 55,
        height: 55,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Image(
            image: imageProvider,
          ),
        ),
      ),
      errorWidget: (context, url, error) => SizedBox(
        width: 55,
        height: 55,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: const Center(
            child: Icon(Icons.error_outline),
          ),
        ),
      ),
    );
  }
}
