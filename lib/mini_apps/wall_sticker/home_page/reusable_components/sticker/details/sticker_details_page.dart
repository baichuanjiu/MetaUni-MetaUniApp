import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../../../reusable_components/logout/logout.dart';
import '../../../../../../../reusable_components/route_animation/route_animation.dart';
import '../../../../../../../reusable_components/snack_bar/network_error_snack_bar.dart';
import '../../../../../../../reusable_components/snack_bar/normal_snack_bar.dart';
import '../../../../../mini_app_manager.dart';
import '../buttons/sticker_like_button.dart';
import '../models/reply_info.dart';
import '../models/sticker_data.dart';
import '../post/sticker_post_page.dart';
import '../sticker/sticker.dart';
import 'sticker_details_card.dart';

class StickerDetailsPage extends StatefulWidget {
  final String id;

  const StickerDetailsPage({super.key, required this.id});

  @override
  State<StickerDetailsPage> createState() => _StickerDetailsPageState();
}

class _StickerDetailsPageState extends State<StickerDetailsPage> {
  final ScrollController _scrollController = ScrollController();
  Key centerKey = const Key("centerKey");
  bool shouldShowFab = false;

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

  late StickerData stickerData;

  _getStickerData() async {
    try {
      Response response;
      response = await dio.get(
        '/wallSticker/stickerAPI/sticker/${widget.id}',
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 0:
          stickerData = StickerData.fromJson(response.data['data']['sticker']);
          setState(() {});
          break;
        case 1:
          //Message:"使用了无效的JWT，请重新登录"
          if (mounted) {
            getNormalSnackBar(context, response.data['message']);
            logout(context);
          }
          break;
        case 2:
          //Message:"您正在对一个不存在的贴贴进行查询"
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

  List<StickerData> timeLineDataList = [];
  int timeLineOffset = 0;
  bool timeLineIsLoading = false;
  bool timeLineHasMore = true;

  _getTimeLineByOffset() async {
    timeLineIsLoading = true;
    timeLineHasMore = false;

    try {
      Response response;
      response = await dio.get(
        '/wallSticker/stickerAPI/sticker/timeLine/${widget.id}/$timeLineOffset',
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 0:
          List<dynamic> tempDataList = response.data['data']['dataList'];
          for (var data in tempDataList) {
            timeLineDataList.add(StickerData.fromJson(data));
          }
          timeLineOffset += tempDataList.length;
          if (tempDataList.length < 20) {
            timeLineHasMore = false;
          }
          else
          {
            timeLineHasMore = true;
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
        case 2:
          //Message:"您正在对一个不存在的贴贴的时间线进行查询"
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

    timeLineIsLoading = false;
  }

  List<StickerData> repliesDataList = [];
  int repliesOffset = 0;
  bool repliesIsLoading = false;
  bool repliesHasMore = true;
  Widget repliesEndIndicator = Container();

  _getRepliesByOffset() async {
    repliesIsLoading = true;
    repliesHasMore = false;

    try {
      Response response;
      response = await dio.get(
        '/wallSticker/stickerAPI/sticker/replies/${widget.id}/$repliesOffset',
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 0:
          List<dynamic> tempDataList = response.data['data']['dataList'];
          for (var data in tempDataList) {
            repliesDataList.add(StickerData.fromJson(data));
          }
          repliesOffset += tempDataList.length;
          if (tempDataList.length < 20) {
            repliesEndIndicator = const Center(
              child: Padding(
                padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
                child: Text("没有更多了呢"),
              ),
            );
            repliesHasMore = false;
          }
          else
          {
            repliesHasMore = true;
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

    repliesIsLoading = false;
  }

  late Future<dynamic> init;

  _init() async {
    await _initDio();
    prefs = await SharedPreferences.getInstance();
    jwt = prefs.getString('jwt');
    uuid = prefs.getInt('uuid');

    _getTimeLineByOffset();
    await _getRepliesByOffset();
    await _getStickerData();
  }

  @override
  void initState() {
    super.initState();

    init = _init();
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
      if (_scrollController.position.extentBefore < 300 && !timeLineIsLoading && timeLineHasMore) {
        timeLineIsLoading = true;
        _getTimeLineByOffset();
      }
      if (_scrollController.position.extentAfter < 300 && !repliesIsLoading && repliesHasMore) {
        repliesIsLoading = true;
        _getRepliesByOffset();
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
        title: const Text("墙贴"),
      ),
      floatingActionButton: shouldShowFab
          ? Container(
              margin: const EdgeInsets.fromLTRB(0, 0, 0, 56),
              child: FloatingActionButton(
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
              ),
            )
          : null,
      body: FutureBuilder(
        future: init,
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
              return const Center(
                child: CupertinoActivityIndicator(),
              );
            case ConnectionState.active:
              return const Center(
                child: CupertinoActivityIndicator(),
              );
            case ConnectionState.waiting:
              return const Center(
                child: CupertinoActivityIndicator(),
              );
            case ConnectionState.done:
              if (snapshot.hasError) {
                return const Center(
                  child: CupertinoActivityIndicator(),
                );
              }
              return Column(
                children: [
                  Expanded(
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      controller: _scrollController,
                      center: centerKey,
                      slivers: [
                        SliverList.builder(
                          itemCount: timeLineDataList.length,
                          itemBuilder: (context, index) {
                            return Sticker(
                              stickerData: timeLineDataList[index],
                              isInTimeLine: true,
                              disableCopyText: false,
                            );
                          },
                        ),
                        SliverPadding(
                          padding: EdgeInsets.zero,
                          key: centerKey,
                        ),
                        SliverToBoxAdapter(
                          child: StickerDetailsCard(stickerData: stickerData),
                        ),
                        SliverList.builder(
                          itemCount: repliesDataList.length,
                          itemBuilder: (context, index) {
                            return Sticker(
                              stickerData: repliesDataList[index],
                              shouldShowReplyTo: false,
                              disableCopyText: false,
                            );
                          },
                        ),
                        SliverToBoxAdapter(
                          child: repliesEndIndicator,
                        ),
                      ],
                    ),
                  ),
                  stickerData.isDeleted
                      ? Container()
                      : Container(
                    constraints: const BoxConstraints(
                      maxHeight: 56,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Theme.of(context).colorScheme.outline, width: 0.2),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(5, 5, 0, 5),
                    child: Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  routeFromBottom(
                                    page: StickerPostPage(
                                      replyInfo: ReplyInfo(replyStickerId: widget.id, replyTo: stickerData.briefUserInfo.nickname),
                                    ),
                                  ),
                                ).then((value) async {
                                  if (value == true) {
                                    getNormalSnackBar(context, "贴贴成功");
                                    repliesHasMore = true;
                                    _getRepliesByOffset();
                                  }
                                });
                              },
                              borderRadius: BorderRadius.circular(5),
                              child: Container(
                                height: double.infinity,
                                padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                                color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.6),
                                child: Row(
                                  children: [
                                    Text(
                                      "回复",
                                      style: Theme.of(context).textTheme.bodyLarge?.apply(
                                        color: Theme.of(context).colorScheme.onSecondaryContainer.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        StickerLikeButton(
                          id: stickerData.id,
                          isDeleted: stickerData.isDeleted,
                          isLiked: stickerData.isLiked,
                          likesNumber: stickerData.likesNumber,
                          isOnlyIcon: true,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            default:
              return const Center(
                child: CupertinoActivityIndicator(),
              );
          }
        },
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
      placeholder: (context, url) => CircleAvatar(
        radius: 25,
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: const CupertinoActivityIndicator(),
      ),
      imageUrl: avatar,
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: 25,
        backgroundImage: imageProvider,
      ),
      errorWidget: (context, url, error) => CircleAvatar(
        radius: 25,
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: const Icon(Icons.error_outline),
      ),
    );
  }
}
