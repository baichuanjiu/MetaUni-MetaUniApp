import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/dio_model.dart';
import '../../../reusable_components/logout/logout.dart';
import '../../../reusable_components/snack_bar/network_error_snack_bar.dart';
import '../../../reusable_components/snack_bar/normal_snack_bar.dart';
import 'feed/card/feed_card.dart';
import 'feed/models/feed_data.dart';

class DiscoverTrendPage extends StatefulWidget {
  const DiscoverTrendPage({super.key});

  @override
  State<DiscoverTrendPage> createState() => _DiscoverTrendPageState();
}

class _DiscoverTrendPageState extends State<DiscoverTrendPage> {
  final ScrollController _scrollController = ScrollController();

  DioModel dioModel = DioModel();
  List<FeedData> dataList = [];
  int rank = 0;
  bool isLoading = false;
  bool hasMore = true;

  late final String? jwt;
  late final int? uuid;

  late Future<dynamic> init;

  _init() async {
    final prefs = await SharedPreferences.getInstance();
    jwt = prefs.getString('jwt');
    uuid = prefs.getInt('uuid');
    await _getFeedByRank();
  }

  _getFeedByRank() async {
    isLoading = true;
    hasMore = false;

    try {
      Response response;
      response = await dioModel.dio.get(
        '/metaUni/feedAPI/feed/$rank',
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 0:
          List<dynamic> tempDataList = response.data['data']['dataList'];
          for (var data in tempDataList) {
            dataList.add(FeedData.fromJson(data));
          }
          rank += tempDataList.length;
          if (tempDataList.length < 20) {
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

  _refresh() async {
    dataList = [];
    rank = 0;
    isLoading = false;
    hasMore = true;
    await _getFeedByRank();
  }

  @override
  void initState() {
    super.initState();

    init = _init();
    _scrollController.addListener(() {
      if (_scrollController.position.extentAfter < 300 && !isLoading && hasMore) {
        isLoading = true;
        _getFeedByRank();
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
    return FutureBuilder(
      future: init,
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
            return Scaffold(
              appBar: AppBar(),
              body: const Center(
                child: CupertinoActivityIndicator(),
              ),
            );
          case ConnectionState.active:
            return Scaffold(
              appBar: AppBar(),
              body: const Center(
                child: CupertinoActivityIndicator(),
              ),
            );
          case ConnectionState.waiting:
            return Scaffold(
              appBar: AppBar(),
              body: const Center(
                child: CupertinoActivityIndicator(),
              ),
            );
          case ConnectionState.done:
            if (snapshot.hasError) {
              return Scaffold(
                appBar: AppBar(),
                body: const Center(
                  child: CupertinoActivityIndicator(),
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async {
                await _refresh();
              },
              child: dataList.isEmpty
                  ? Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                                child: isLoading ? const CupertinoActivityIndicator() : const Text("没有更多了呢"),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : MasonryGridView.count(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                      crossAxisCount: 2,
                      mainAxisSpacing: 5,
                      crossAxisSpacing: 5,
                      itemBuilder: (context, index) {
                        return FeedCard(
                          data: dataList[index],
                        );
                      },
                      itemCount: dataList.length,
                    ),
            );
          default:
            return Scaffold(
              appBar: AppBar(),
              body: const Center(
                child: CupertinoActivityIndicator(),
              ),
            );
        }
      },
    );
  }
}
