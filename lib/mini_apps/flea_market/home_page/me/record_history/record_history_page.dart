import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../reusable_components/logout/logout.dart';
import '../../../../../reusable_components/snack_bar/network_error_snack_bar.dart';
import '../../../../../reusable_components/snack_bar/normal_snack_bar.dart';
import '../../../../mini_app_manager.dart';
import '../../reusable_components/record/card/record_card_with_delete_action.dart';
import '../../reusable_components/record/models/record_data.dart';

class RecordHistoryPage extends StatefulWidget {
  final String type;

  const RecordHistoryPage({super.key, required this.type});

  @override
  State<RecordHistoryPage> createState() => _RecordHistoryPageState();
}

class _RecordHistoryPageState extends State<RecordHistoryPage> {
  final ScrollController _scrollController = ScrollController();

  late Dio dio;
  List<BriefRecordData> dataList = [];
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
    await _initProfit();
    await _getMyRecordsByLastResult();
  }

  _initDio() async {
    dio = Dio(
      BaseOptions(
        baseUrl: (await MiniAppManager().getCurrentMiniAppUrl())!,
      ),
    );
  }

  double? profit;

  _initProfit() async {
    try {
      Response response;
      response = await dio.get(
        widget.type == 'sell' ? '/fleaMarket/marketAPI/user/income' : '/fleaMarket/marketAPI/user/expenditure',
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 0:
          setState(() {
            profit = double.parse(
              response.data['data'].toString(),
            );
          });
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

  _getMyRecordsByLastResult() async {
    isLoading = true;
    hasMore = false;

    try {
      Response response;
      response = await dio.get(
        lastDateTime == null && lastId == null ? '/fleaMarket/marketAPI/record/me/history/${widget.type}' : '/fleaMarket/marketAPI/record/me/history/${widget.type}/$lastDateTime/$lastId',
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 0:
          List<dynamic> tempDataList = response.data['data']['dataList'];
          for (var data in tempDataList) {
            dataList.add(BriefRecordData.fromJson(data));
          }
          if (dataList.isNotEmpty) {
            lastDateTime = dataList.last.createdTime;
            lastId = dataList.last.id;
          }
          if (tempDataList.length < 20) {
            endIndicator = Center(
              child: Container(
                padding: const EdgeInsets.fromLTRB(0, 10, 0, 40),
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

  _refresh() async {
    dataList = [];
    endIndicator = Container();
    lastDateTime = null;
    lastId = null;
    isLoading = false;
    hasMore = true;
    await _initProfit();
    await _getMyRecordsByLastResult();
  }

  Future<bool> _deleteRecord(String id) async {
    try {
      Response response;
      response = await dio.delete(
        '/fleaMarket/marketAPI/record/$id',
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
        //Message:"您正在对一个不存在或已被删除的记录进行删除"
        case 3:
          //Message:"您正在对一个不属于您的记录进行删除"
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
            title: const Text('删除这条记录'),
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
      return await _deleteRecord(id);
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
        _getMyRecordsByLastResult();
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
            return const CupertinoActivityIndicator();
          case ConnectionState.active:
            return const CupertinoActivityIndicator();
          case ConnectionState.waiting:
            return const CupertinoActivityIndicator();
          case ConnectionState.done:
            if (snapshot.hasError) {
              return const CupertinoActivityIndicator();
            }
            return Scaffold(
              body: RefreshIndicator(
                edgeOffset: 150,
                onRefresh: () async {
                  await _refresh();
                },
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverOverlapInjector(
                      handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                    ),
                    SliverToBoxAdapter(
                      child: profit == null
                          ? Container()
                          : Padding(
                              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(15, 20, 15, 20),
                                  child: Text(
                                    widget.type == 'sell' ? "共计收入：￥${profit!.toStringAsFixed(2)}" : "共计花费：￥${profit!.toStringAsFixed(2)}",
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                ),
                              ),
                            ),
                    ),
                    SliverList.builder(
                      itemCount: dataList.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                          child: RecordCardWithDeleteAction(
                            data: dataList[index],
                            onDelete: _onDelete,
                          ),
                        );
                      },
                    ),
                    SliverToBoxAdapter(
                      child: endIndicator,
                    ),
                  ],
                ),
              ),
            );
          default:
            return const CupertinoActivityIndicator();
        }
      },
    );
  }
}

class OnCompleteFormData {
  double price;
  String remark;

  OnCompleteFormData(this.price, this.remark);
}
