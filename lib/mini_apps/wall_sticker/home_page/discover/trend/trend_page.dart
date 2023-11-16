import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../reusable_components/logout/logout.dart';
import '../../../../../reusable_components/snack_bar/network_error_snack_bar.dart';
import '../../../../../reusable_components/snack_bar/normal_snack_bar.dart';
import '../../../../mini_app_manager.dart';
import '../../reusable_components/sticker/models/sticker_data.dart';
import '../../reusable_components/sticker/sticker/sticker.dart';

class WallStickerTrendPage extends StatefulWidget {
  const WallStickerTrendPage({super.key});

  @override
  State<WallStickerTrendPage> createState() => WallStickerTrendPageState();
}

class WallStickerTrendPageState extends State<WallStickerTrendPage> {
  final ScrollController _scrollController = ScrollController();

  late Dio dio;

  late final String? jwt;
  late final int? uuid;

  List<StickerData> dataList = [];
  Widget endIndicator = Container();
  int rank = 0;
  bool isLoading = false;
  bool hasMore = true;

  late Future<dynamic> init;

  _init() async {
    await _initDio();
    final prefs = await SharedPreferences.getInstance();
    jwt = prefs.getString('jwt');
    uuid = prefs.getInt('uuid');

    await _getTrendStickersByRank();
  }

  _initDio() async {
    dio = Dio(
      BaseOptions(
        baseUrl: (await MiniAppManager().getCurrentMiniAppUrl())!,
      ),
    );
  }

  _getTrendStickersByRank() async {
    isLoading = true;
    hasMore = false;

    try {
      Response response;
      response = await dio.get(
        '/wallSticker/stickerAPI/sticker/trend/$rank',
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
          rank += tempDataList.length;
          if (tempDataList.length < 20) {
            endIndicator = const Center(
              child: Padding(
                padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
                child: Text("没有更多了呢"),
              ),
            );
            hasMore = false;
          }
          else
          {
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

  bool topIsOutOfScreen(){
    return _scrollController.offset >= MediaQuery.of(context).size.height;
  }

  refresh() async {
    dataList = [];
    endIndicator = Container();
    rank = 0;
    isLoading = false;
    hasMore = true;
    await _getTrendStickersByRank();
  }

  @override
  void initState() {
    super.initState();

    init = _init();
    _scrollController.addListener(() {
      if (_scrollController.position.extentAfter < 300 && !isLoading && hasMore) {
        isLoading = true;
        _getTrendStickersByRank();
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
