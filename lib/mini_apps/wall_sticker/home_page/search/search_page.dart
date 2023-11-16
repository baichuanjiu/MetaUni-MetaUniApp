import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../reusable_components/logout/logout.dart';
import '../../../../reusable_components/snack_bar/network_error_snack_bar.dart';
import '../../../../reusable_components/snack_bar/normal_snack_bar.dart';
import '../../../mini_app_manager.dart';
import '../reusable_components/sticker/models/sticker_data.dart';
import '../reusable_components/sticker/sticker/sticker.dart';
import '../reusable_components/sticker/sticker/sticker_with_delete_action.dart';

class WallStickerSearchPage extends StatefulWidget {
  final DateTimeRange? dateTimeRange;
  final String searchMode;

  const WallStickerSearchPage({super.key, this.dateTimeRange, this.searchMode = "all"});

  @override
  State<WallStickerSearchPage> createState() => _WallStickerSearchPageState();
}

class _WallStickerSearchPageState extends State<WallStickerSearchPage> {
  final TextEditingController searchController = TextEditingController();
  late String searchKey = "";
  late DateTimeRange? dateTimeRange = widget.dateTimeRange;
  late String searchMode = widget.searchMode;

  late Dio dio;

  late final SharedPreferences prefs;
  late final String? jwt;
  late final int? uuid;

  final ScrollController _scrollController = ScrollController();
  List<StickerData> dataList = [];
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

    if (dateTimeRange != null) {
      _reloadAndSearch();
    } else {
      hasMore = false;
    }
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
        '/wallSticker/stickerAPI/sticker/search',
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
        data: {
          'searchKey': searchKey,
          'start': dateTimeRange?.start.toIso8601String(),
          'end': dateTimeRange?.end
              .add(
                const Duration(days: 1, microseconds: -1),
              )
              .toIso8601String(),
          'searchMode': searchMode,
          'offset': offset,
        },
      );
      switch (response.data['code']) {
        case 0:
          List<dynamic> tempDataList = response.data['data']['dataList'];
          for (var data in tempDataList) {
            dataList.add(StickerData.fromJson(data));
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
        case 2:
          //Message:"查询失败，因为传递了不合法的参数"
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

    if (searchKeys.isEmpty && dateTimeRange == null) {
      getNormalSnackBar(context, "搜索内容与查询日期范围不能同时为空");
      setState(() {
        dataList = [];
        endIndicator = const Center(
          child: Padding(
            padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
            child: Text("没有更多了呢"),
          ),
        );
        offset = 0;
        isLoading = false;
        hasMore = false;
      });
    } else {
      searchKey = searchController.text;
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.ease).then((value) async {
        dataList = [];
        endIndicator = Container();
        offset = 0;
        isLoading = false;
        hasMore = true;
        await _search();
      });
    }
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
                        autofocus: widget.dateTimeRange == null,
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
              preferredSize: const Size.fromHeight(103),
              child: Column(
                children: [
                  InkWell(
                    onTap: () {
                      showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2023, 09, 01),
                        lastDate: DateTime.now(),
                        initialDateRange: dateTimeRange == null
                            ? DateTimeRange(
                                start: DateTime.now().subtract(const Duration(days: 7)),
                                end: DateTime.now(),
                              )
                            : dateTimeRange!,
                        helpText: "查询范围",
                        confirmText: "确认",
                        saveText: "确认",
                      ).then((value) {
                        setState(() {
                          dateTimeRange = value;
                        });
                        _reloadAndSearch();
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(0, 5, 0, 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Container(
                            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                              borderRadius: const BorderRadius.all(
                                Radius.circular(8.0),
                              ),
                            ),
                            child: Text(
                              dateTimeRange == null ? "起始日期" : dateTimeRange!.start.toString().substring(0, 10),
                            ),
                          ),
                          const Text("至"),
                          Container(
                            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                              borderRadius: const BorderRadius.all(
                                Radius.circular(8.0),
                              ),
                            ),
                            child: Text(
                              dateTimeRange == null ? "结束日期" : dateTimeRange!.end.toString().substring(0, 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.fromLTRB(0, 5, 0, 10),
                    child: SegmentedButton<String>(
                      segments: const <ButtonSegment<String>>[
                        ButtonSegment<String>(
                          value: "all",
                          label: Text('所有人'),
                          icon: Icon(Icons.people_rounded),
                        ),
                        ButtonSegment<String>(
                          value: "me",
                          label: Text('仅自己'),
                          icon: Icon(Icons.person_rounded),
                        ),
                      ],
                      selected: <String>{searchMode},
                      onSelectionChanged: (Set<String> newSelection) {
                        setState(() {
                          searchMode = newSelection.first;
                        });
                        _reloadAndSearch();
                      },
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
          SliverList.builder(
            itemCount: dataList.length,
            itemBuilder: (context, index) {
              return searchMode == "me"
                  ? StickerWithDeleteAction(
                      stickerData: dataList[index],
                      onDelete: _onDelete,
                    )
                  : Sticker(
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
  }
}
