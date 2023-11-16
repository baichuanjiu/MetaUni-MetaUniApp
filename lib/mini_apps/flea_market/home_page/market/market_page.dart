import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:meta_uni_app/mini_apps/flea_market/home_page/reusable_components/channel/select/channel_select_page.dart';
import 'package:meta_uni_app/mini_apps/flea_market/home_page/reusable_components/mission/card/mission_card.dart';
import 'package:meta_uni_app/mini_apps/flea_market/home_page/search/search_by_channel_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../reusable_components/logout/logout.dart';
import '../../../../reusable_components/snack_bar/network_error_snack_bar.dart';
import '../../../../reusable_components/snack_bar/normal_snack_bar.dart';
import '../../../mini_app_manager.dart';
import '../reusable_components/channel/models/channel_data.dart';
import '../reusable_components/mission/models/mission_data.dart';
import '../search/search_by_key_page.dart';

class MarketPage extends StatefulWidget {
  const MarketPage({super.key});

  @override
  State<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends State<MarketPage> {
  String searchMode = "sell";

  final ScrollController _scrollController = ScrollController();

  late Dio dio;
  List<String> channelsList = [];
  List<TextButton> channelButtonsList = [];
  List<BriefMissionData> dataList = [];
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
    await _getChannelList();
    await _getMissionsByLastResult();
  }

  _initDio() async {
    dio = Dio(
      BaseOptions(
        baseUrl: (await MiniAppManager().getCurrentMiniAppUrl())!,
      ),
    );
  }

  _selectChannel(String? initMainChannel) {
    Navigator.push<ChannelData>(
      context,
      MaterialPageRoute(builder: (context) {
        return ChannelSelectPage(
          initMainChannel: initMainChannel,
        );
      }),
    ).then((value) {
      if (value != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return SearchByChannelPage(
                searchChannel: value,
              );
            },
          ),
        );
      }
    });
  }

  _updateChannelButtonList() {
    channelButtonsList = [];
    for (var data in channelsList) {
      channelButtonsList.add(
        TextButton(
          onPressed: () {
            _selectChannel(data);
          },
          child: Text(
            data,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }
  }

  _getChannelList() async {
    try {
      Response response;
      response = await dio.get(
        '/fleaMarket/marketAPI/channel/all/main',
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 0:
          var dataList = response.data['data'];
          channelsList = [];
          for (var data in dataList) {
            channelsList.add(data);
          }
          _updateChannelButtonList();
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

  _getMissionsByLastResult() async {
    isLoading = true;
    hasMore = false;

    try {
      Response response;
      response = await dio.get(
        lastDateTime == null && lastId == null ? '/fleaMarket/marketAPI/mission/brief/$searchMode' : '/fleaMarket/marketAPI/mission/brief/$searchMode/$lastDateTime/$lastId',
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 0:
          List<dynamic> tempDataList = response.data['data']['dataList'];
          for (var data in tempDataList) {
            dataList.add(BriefMissionData.fromJson(data));
          }
          if (dataList.isNotEmpty) {
            lastDateTime = dataList.last.createdTime;
            lastId = dataList.last.id;
          }
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
    lastDateTime = null;
    lastId = null;
    isLoading = false;
    hasMore = true;
    await _getMissionsByLastResult();
  }

  @override
  void initState() {
    super.initState();

    init = _init();
    _scrollController.addListener(() {
      if (_scrollController.position.extentAfter < 300 && !isLoading && hasMore) {
        isLoading = true;
        _getMissionsByLastResult();
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
            return Scaffold(
              appBar: AppBar(
                title: SegmentedButton<String>(
                  segments: const <ButtonSegment<String>>[
                    ButtonSegment<String>(
                      value: "sell",
                      label: Text('出售'),
                      icon: Icon(Icons.shopping_basket_outlined),
                    ),
                    ButtonSegment<String>(
                      value: "purchase",
                      label: Text('求购'),
                      icon: Icon(Icons.currency_yen_outlined),
                    ),
                  ],
                  selected: <String>{searchMode},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      searchMode = newSelection.first;
                      _refresh();
                    });
                  },
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity(horizontal: -1, vertical: -1),
                  ),
                ),
                centerTitle: true,
                actions: [
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            return const SearchByKeyPage();
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
                    padding: const EdgeInsets.fromLTRB(10, 0, 0, 10),
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
                                children: [
                                  ...channelButtonsList,
                                ],
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              _selectChannel(null);
                            },
                            icon: const Icon(
                              Icons.double_arrow_outlined,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              body: RefreshIndicator(
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
                          return MissionCard(
                            data: dataList[index],
                          );
                        },
                        itemCount: dataList.length,
                      ),
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
