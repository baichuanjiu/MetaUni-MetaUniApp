import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:meta_uni_app/mini_apps/mini_app_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../reusable_components/logout/logout.dart';
import '../../../../../reusable_components/snack_bar/network_error_snack_bar.dart';
import '../../../../../reusable_components/snack_bar/normal_snack_bar.dart';
import '../../reusable_components/sticker/models/sticker_data.dart';
import '../../reusable_components/sticker/sticker/sticker.dart';

class WallStickerTodayPage extends StatefulWidget {
  const WallStickerTodayPage({super.key});

  @override
  State<WallStickerTodayPage> createState() => WallStickerTodayPageState();
}

class WallStickerTodayPageState extends State<WallStickerTodayPage> {
  final ScrollController _scrollController = ScrollController();

  late Dio dio;
  List<StickerData> dataList = [];
  Widget endIndicator = Container();
  DateTime? lastDateTime;
  String? lastId;
  bool isLoading = false;
  bool hasMore = true;

  late final String? jwt;
  late final int? uuid;

  late Future<dynamic> init;

  _init() async {
    final prefs = await SharedPreferences.getInstance();
    jwt = prefs.getString('jwt');
    uuid = prefs.getInt('uuid');
    await _initDio();
    await _getTodayStickersByLastResult();
  }

  _initDio() async {
    dio = Dio(
      BaseOptions(
        baseUrl: (await MiniAppManager().getCurrentMiniAppUrl())!,
      ),
    );
  }

  _getTodayStickersByLastResult() async {
    isLoading = true;
    hasMore = false;

    try {
      Response response;
      response = await dio.get(
        lastDateTime == null && lastId == null ? '/wallSticker/stickerAPI/sticker/today' : '/wallSticker/stickerAPI/sticker/today/$lastDateTime/$lastId',
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

  Future<void> animateToTop() async {
    await _scrollController.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.ease);
  }

  bool topIsOutOfScreen() {
    return _scrollController.offset >= MediaQuery.of(context).size.height;
  }

  refresh() async {
    dataList = [];
    endIndicator = Container();
    lastDateTime = null;
    lastId = null;
    isLoading = false;
    hasMore = true;
    await _getTodayStickersByLastResult();
  }

  @override
  void initState() {
    super.initState();

    init = _init();
    _scrollController.addListener(() {
      if (_scrollController.position.extentAfter < 300 && !isLoading && hasMore) {
        isLoading = true;
        _getTodayStickersByLastResult();
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
              return RefreshIndicator(
                onRefresh: () async {
                  await refresh();
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  controller: _scrollController,
                  slivers: <Widget>[
                    SliverList.builder(
                      itemCount: dataList.length,
                      itemBuilder: (context, index) {
                        return Sticker(
                          stickerData: dataList[index],
                        );
                      },
                    ),
                    SliverToBoxAdapter(
                      child: endIndicator,
                    ),
                  ],
                ),
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
