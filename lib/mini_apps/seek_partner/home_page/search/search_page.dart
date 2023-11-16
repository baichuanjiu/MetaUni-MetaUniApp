import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../reusable_components/logout/logout.dart';
import '../../../../reusable_components/snack_bar/network_error_snack_bar.dart';
import '../../../../reusable_components/snack_bar/normal_snack_bar.dart';
import '../../../mini_app_manager.dart';
import '../reusable_components/leaflet/card/leaflet_card.dart';
import '../reusable_components/leaflet/models/leaflet_data.dart';

class SeekPartnerSearchPage extends StatefulWidget {
  final List<String> channelList;

  const SeekPartnerSearchPage({super.key, required this.channelList});

  @override
  State<SeekPartnerSearchPage> createState() => _SeekPartnerSearchPageState();
}

class _SeekPartnerSearchPageState extends State<SeekPartnerSearchPage> {
  final TextEditingController searchController = TextEditingController();
  late String searchKey = "";
  late DateTime baseTime = DateTime.now();

  List<Widget> chips = [];
  late String channel = widget.channelList.first;

  _updateChips() {
    chips = [];
    for (var data in widget.channelList) {
      chips.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
          child: GestureDetector(
            onTap: () {
              setState(
                () {
                  channel = data;
                  _updateChips();
                  _reloadAndSearch();
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

  late Dio dio;

  late final SharedPreferences prefs;
  late final String? jwt;
  late final int? uuid;

  final ScrollController _scrollController = ScrollController();
  List<LeafletData> dataList = [];
  Widget endIndicator = Container();
  int offset = 0;
  bool isLoading = false;
  bool hasMore = true;

  late Future<dynamic> init;

  _init() async {
    await _initDio();
    prefs = await SharedPreferences.getInstance();
    jwt = prefs.getString('jwt');
    uuid = prefs.getInt('uuid');

    _updateChips();
    await _reloadAndSearch();
  }

  _initDio() async {
    dio = Dio(
      BaseOptions(
        baseUrl: (await MiniAppManager().getCurrentMiniAppUrl())!,
      ),
    );
  }

  _search() async {
    isLoading = true;
    hasMore = false;

    try {
      Response response;
      response = await dio.post(
        '/seekPartner/leafletAPI/leaflet/search',
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
        data: {
          'searchKey': searchKey,
          'baseTime': baseTime.toIso8601String(),
          'offset': offset,
          'channel': channel,
        },
      );
      switch (response.data['code']) {
        case 0:
          List<dynamic> tempDataList = response.data['data']['dataList'];
          for (var data in tempDataList) {
            dataList.add(LeafletData.fromJson(data));
          }
          offset += tempDataList.length;
          if (tempDataList.length < 20) {
            endIndicator = const Center(
              child: Padding(
                padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
                child: Text("没有更多了呢"),
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
        case 2:
          //Message:"查询失败，查询关键词不可为空"
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

    isLoading = false;
  }

  _reloadAndSearch() async {
    List<String> searchKeys = searchController.text.split(
      RegExp(r" +"),
    );
    searchKeys.removeWhere((element) => element == "");

    if (searchKeys.isEmpty) {
      setState(() {
        dataList = [];
        endIndicator = const Center(
          child: Padding(
            padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
            child: Text("未输入搜索内容"),
          ),
        );
        offset = 0;
        baseTime = DateTime.now();
        isLoading = false;
        hasMore = false;
      });
    } else {
      searchKey = searchController.text;
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.ease).then((value) async {
        dataList = [];
        endIndicator = Container();
        offset = 0;
        baseTime = DateTime.now();
        isLoading = false;
        hasMore = true;
        await _search();
      });
    }
  }

  @override
  void initState() {
    super.initState();

    init = _init();
    _scrollController.addListener(() {
      if (_scrollController.position.extentAfter < 300 && !isLoading && hasMore) {
        isLoading = true;
        _search();
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
      body: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: false,
            snap: true,
            title: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                borderRadius: const BorderRadius.all(
                  Radius.circular(50.0),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(25, 0, 25, 0),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                      child: Icon(
                        Icons.search_outlined,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: '搜索',
                        ),
                        autofocus: true,
                        textInputAction: TextInputAction.search,
                        autocorrect: false,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(30),
                        ],
                        onTapOutside: (value) {
                          FocusManager.instance.primaryFocus?.unfocus();
                        },
                        onEditingComplete: () {
                          _reloadAndSearch();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _reloadAndSearch();
                },
                child: const Text("搜索"),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(50),
              child: Container(
                height: 50,
                padding: const EdgeInsets.fromLTRB(10, 3, 10, 7),
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
                            children: [...chips],
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
  }
}
