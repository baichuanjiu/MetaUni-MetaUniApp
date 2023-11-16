import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../reusable_components/logout/logout.dart';
import '../../../../reusable_components/snack_bar/network_error_snack_bar.dart';
import '../../../../reusable_components/snack_bar/normal_snack_bar.dart';
import '../../../mini_app_manager.dart';
import '../reusable_components/channel/models/channel_data.dart';
import '../reusable_components/channel/select/channel_select_page.dart';
import '../reusable_components/mission/card/mission_card.dart';
import '../reusable_components/mission/models/mission_data.dart';

class SearchByChannelPage extends StatefulWidget {
  final ChannelData searchChannel;

  const SearchByChannelPage({super.key, required this.searchChannel});

  @override
  State<SearchByChannelPage> createState() => _SearchByChannelPageState();
}

class _SearchByChannelPageState extends State<SearchByChannelPage> {
  late ChannelData searchChannel = widget.searchChannel;
  String searchMode = "sell";

  final ScrollController _scrollController = ScrollController();

  late Dio dio;
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
    await _searchMissionsByChannel();
  }

  _initDio() async {
    dio = Dio(
      BaseOptions(
        baseUrl: (await MiniAppManager().getCurrentMiniAppUrl())!,
      ),
    );
  }

  _searchMissionsByChannel() async {
    isLoading = true;
    hasMore = false;

    try {
      Response response;
      response = await dio.post(
        '/fleaMarket/marketAPI/mission/search/channel',
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
        data: {
          'channelData': searchChannel,
          'type': searchMode,
          'lastDateTime': lastDateTime,
          'lastId': lastId,
        },
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
    await _searchMissionsByChannel();
  }

  @override
  void initState() {
    super.initState();

    init = _init();
    _scrollController.addListener(() {
      if (_scrollController.position.extentAfter < 300 && !isLoading && hasMore) {
        isLoading = true;
        _searchMissionsByChannel();
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
        title: Text(
          searchChannel.toString(),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push<ChannelData>(
                context,
                MaterialPageRoute(builder: (context) {
                  return ChannelSelectPage(
                    initMainChannel: searchChannel.mainChannel,
                  );
                }),
              ).then((value) {
                if (value != null) {
                  setState(() {
                    searchChannel = value;
                  });
                  _refresh();
                }
              });
            },
            icon: const Icon(
              Icons.list_outlined,
            ),
            tooltip: "频道",
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(46),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(0, 0, 0, 10),
                child: SegmentedButton<String>(
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
              ),
            ],
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
  }
}
