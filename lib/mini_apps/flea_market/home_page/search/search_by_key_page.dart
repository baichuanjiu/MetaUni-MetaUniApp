import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../reusable_components/logout/logout.dart';
import '../../../../reusable_components/snack_bar/network_error_snack_bar.dart';
import '../../../../reusable_components/snack_bar/normal_snack_bar.dart';
import '../../../mini_app_manager.dart';
import '../reusable_components/mission/card/mission_card.dart';
import '../reusable_components/mission/models/mission_data.dart';

class SearchByKeyPage extends StatefulWidget {
  const SearchByKeyPage({super.key});

  @override
  State<SearchByKeyPage> createState() => _SearchByKeyPageState();
}

class _SearchByKeyPageState extends State<SearchByKeyPage> {
  final TextEditingController searchController = TextEditingController();
  late String searchKey = "";
  String searchMode = "sell";

  final ScrollController _scrollController = ScrollController();

  late Dio dio;
  List<BriefMissionData> dataList = [];
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
    await _reloadAndSearch();
  }

  _initDio() async {
    dio = Dio(
      BaseOptions(
        baseUrl: (await MiniAppManager().getCurrentMiniAppUrl())!,
      ),
    );
  }

  _searchMissionsByKey() async {
    isLoading = true;
    hasMore = false;

    try {
      Response response;
      response = await dio.post(
        '/fleaMarket/marketAPI/mission/search/key',
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
        data: {
          'searchKey': searchKey,
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
        lastDateTime = null;
        endIndicator = const Text("未输入搜索内容");
        lastId = null;
        isLoading = false;
        hasMore = false;
      });
    } else {
      searchKey = searchController.text;
      if(_scrollController.hasClients)
      {
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.ease).then((value) async {
          dataList = [];
          endIndicator = const Text("没有更多了呢");
          lastDateTime = null;
          lastId = null;
          isLoading = false;
          hasMore = true;
          await _searchMissionsByKey();
        });
      }
      else
      {
        dataList = [];
        endIndicator = const Text("没有更多了呢");
        lastDateTime = null;
        lastId = null;
        isLoading = false;
        hasMore = true;
        await _searchMissionsByKey();
      }
    }
  }

  @override
  void initState() {
    super.initState();

    init = _init();
    _scrollController.addListener(() {
      if (_scrollController.position.extentAfter < 300 && !isLoading && hasMore) {
        isLoading = true;
        _searchMissionsByKey();
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
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              _reloadAndSearch();
            },
            child: const Text("搜索"),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(51),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(0, 5, 0, 10),
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
                      _reloadAndSearch();
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
          await _reloadAndSearch();
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
                    child: isLoading ? const CupertinoActivityIndicator() : endIndicator,
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
