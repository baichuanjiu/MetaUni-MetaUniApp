import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:meta_uni_app/mini_apps/seek_partner/home_page/reusable_components/leaflet/card/leaflet_card.dart';
import 'package:meta_uni_app/mini_apps/seek_partner/home_page/reusable_components/leaflet/models/leaflet_data.dart';
import 'package:meta_uni_app/mini_apps/seek_partner/home_page/search/search_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../reusable_components/logout/logout.dart';
import '../../../../reusable_components/snack_bar/network_error_snack_bar.dart';
import '../../../../reusable_components/snack_bar/normal_snack_bar.dart';
import '../../../mini_app_manager.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final ScrollController _scrollController = ScrollController();

  late Dio dio;
  List<String> channelList = [];
  List<Widget>? chips;
  List<LeafletData> dataList = [];
  Widget endIndicator = Container();
  DateTime baseTime = DateTime.now();
  int offset = 0;
  String channel = "全部";
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
    await _getChannelList();
    await _getLeafletByOffset();
  }

  _initDio() async {
    dio = Dio(
      BaseOptions(
        baseUrl: (await MiniAppManager().getCurrentMiniAppUrl())!,
      ),
    );
  }

  _updateChips() {
    chips = [];
    for (var data in channelList) {
      chips!.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
          child: GestureDetector(
            onTap: () {
              setState(
                () {
                  channel = data;
                  _updateChips();
                  refresh();
                },
              );
            },
            child: Chip(
              label: Text(data),
              backgroundColor: data == channel ? Theme.of(context).colorScheme.primaryContainer : null,
            ),
          ),
        ),
      );
    }
  }

  _getChannelList() async {
    try {
      Response response;
      response = await dio.get(
        '/seekPartner/leafletAPI/leaflet/channelList',
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 0:
          var dataList = response.data['data'];
          channelList = [];
          for (var data in dataList) {
            channelList.add(data);
          }
          _updateChips();
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

  _getLeafletByOffset() async {
    isLoading = true;
    hasMore = false;

    try {
      Response response;
      response = await dio.get(
        '/seekPartner/leafletAPI/leaflet/$baseTime&$offset&$channel',
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 0:
          List<dynamic> tempDataList = response.data['data']['dataList'];
          for (var data in tempDataList) {
            dataList.add(LeafletData.fromJson(data));
          }
          if (dataList.isNotEmpty) {
            offset += dataList.length;
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

  refresh() async {
    dataList = [];
    endIndicator = Container();
    baseTime = DateTime.now();
    offset = 0;
    isLoading = false;
    hasMore = true;
    await _getLeafletByOffset();
  }

  @override
  void initState() {
    super.initState();

    init = _init();
    _scrollController.addListener(() {
      if (_scrollController.position.extentAfter < 300 && !isLoading && hasMore) {
        isLoading = true;
        _getLeafletByOffset();
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
              appBar: AppBar(
                title: const Text("搭搭广场"),
                centerTitle: true,
              ),
              body: const Center(
                child: CupertinoActivityIndicator(),
              ),
            );
          case ConnectionState.active:
            return Scaffold(
              appBar: AppBar(
                title: const Text("搭搭广场"),
                centerTitle: true,
              ),
              body: const Center(
                child: CupertinoActivityIndicator(),
              ),
            );
          case ConnectionState.waiting:
            return Scaffold(
              appBar: AppBar(
                title: const Text("搭搭广场"),
                centerTitle: true,
              ),
              body: const Center(
                child: CupertinoActivityIndicator(),
              ),
            );
          case ConnectionState.done:
            if (snapshot.hasError) {
              return Scaffold(
                appBar: AppBar(
                  title: const Text("搭搭广场"),
                  centerTitle: true,
                ),
                body: const Center(
                  child: CupertinoActivityIndicator(),
                ),
              );
            }
            if (chips == null) {
              return Scaffold(
                appBar: AppBar(
                  title: const Text("搭搭广场"),
                  centerTitle: true,
                ),
                body: const Center(
                  child: CupertinoActivityIndicator(),
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async {
                await refresh();
              },
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverAppBar(
                    floating: true,
                    pinned: false,
                    snap: true,
                    title: const Text("搭搭广场"),
                    actions: [
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) {
                                return SeekPartnerSearchPage(channelList: channelList);
                              },
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.search_outlined,
                        ),
                        tooltip: "搜索",
                      ),
                    ],
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(50),
                      child: Container(
                        height: 50,
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              width: 0.5,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ),
                        child: Center(
                          child: Row(
                            children: [
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  physics: const AlwaysScrollableScrollPhysics(
                                    parent: BouncingScrollPhysics(),
                                  ),
                                  child: Row(
                                    children: [...chips!],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                    sliver: SliverList.builder(
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.fromLTRB(0, 5, 0, 5),
                          child: LeafletCard(data: dataList[index]),
                        );
                      },
                      itemCount: dataList.length,
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 50),
                    sliver: SliverToBoxAdapter(
                      child: endIndicator,
                    ),
                  ),
                ],
              ),
            );
          default:
            return Scaffold(
              appBar: AppBar(
                title: const Text("搭搭广场"),
                centerTitle: true,
              ),
              body: const Center(
                child: CupertinoActivityIndicator(),
              ),
            );
        }
      },
    );
  }
}
