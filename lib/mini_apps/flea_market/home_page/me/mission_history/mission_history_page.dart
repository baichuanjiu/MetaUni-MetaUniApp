import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:meta_uni_app/mini_apps/flea_market/home_page/reusable_components/mission/card/mission_card_with_actions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../reusable_components/logout/logout.dart';
import '../../../../../reusable_components/snack_bar/network_error_snack_bar.dart';
import '../../../../../reusable_components/snack_bar/normal_snack_bar.dart';
import '../../../../mini_app_manager.dart';
import '../../reusable_components/mission/models/mission_data.dart';

class MissionHistoryPage extends StatefulWidget {
  final String type;

  const MissionHistoryPage({super.key, required this.type});

  @override
  State<MissionHistoryPage> createState() => _MissionHistoryPageState();
}

class _MissionHistoryPageState extends State<MissionHistoryPage> {
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
    await _getMyMissionsByLastResult();
  }

  _initDio() async {
    dio = Dio(
      BaseOptions(
        baseUrl: (await MiniAppManager().getCurrentMiniAppUrl())!,
      ),
    );
  }

  _getMyMissionsByLastResult() async {
    isLoading = true;
    hasMore = false;

    try {
      Response response;
      response = await dio.get(
        lastDateTime == null && lastId == null ? '/fleaMarket/marketAPI/mission/me/history/${widget.type}' : '/fleaMarket/marketAPI/mission/me/history/${widget.type}/$lastDateTime/$lastId',
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
    await _getMyMissionsByLastResult();
  }

  Future<bool> _completeMission(String id, double price, String remark) async {
    Map<String, dynamic> formDataMap = {
      'missionId': id,
      'price': price,
      'remark': remark,
    };

    try {
      Response response;
      var formData = FormData.fromMap(
        formDataMap,
        ListFormat.multiCompatible,
      );
      response = await dio.post(
        '/fleaMarket/marketAPI/record',
        data: formData,
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
        //Message:"您正在对一个不存在或已被删除的记录进行操作"
        case 3:
          //Message:"您正在对一个不属于您的记录进行操作"
          if (mounted) {
            getNormalSnackBar(context, response.data['message']);
          }
          break;
        case 4:
          //Message:"发生错误，操作失败"
          if (mounted) {
            getNetworkErrorSnackBar(context);
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

  Future<bool> _onComplete(String id) async {
    final TextEditingController priceController = TextEditingController(
      text: "0.00",
    );
    final FocusNode priceFocusNode = FocusNode();

    final TextEditingController remarkController = TextEditingController();
    final FocusNode remarkFocusNode = FocusNode();

    var onCompleteFormData = await showModalBottomSheet<OnCompleteFormData>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "确认结算",
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 10, 0, 5),
                      child: TextField(
                        controller: priceController,
                        focusNode: priceFocusNode,
                        autofocus: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          filled: true,
                          labelText: "成交价格",
                        ),
                        inputFormatters: [
                          //金额正则
                          FilteringTextInputFormatter.allow(
                            RegExp(r"^[0-9]+[.]?[0-9]{0,2}"),
                          ),
                        ],
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        onTapOutside: (details) {
                          priceFocusNode.unfocus();
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 10, 0, 5),
                      child: TextField(
                        controller: remarkController,
                        focusNode: remarkFocusNode,
                        autofocus: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          filled: true,
                          labelText: "备注",
                        ),
                        inputFormatters: [
                          //只允许输入最多50个字符
                          LengthLimitingTextInputFormatter(50),
                        ],
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.done,
                        onTapOutside: (details) {
                          remarkFocusNode.unfocus();
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        FilledButton(
                          onPressed: () {
                            Navigator.pop(
                              context,
                              OnCompleteFormData(double.parse(priceController.text.isEmpty ? "0.00" : priceController.text), remarkController.text.isEmpty ? "无" : remarkController.text),
                            );
                          },
                          child: const Text("确定"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (onCompleteFormData != null) {
      return await _completeMission(id, onCompleteFormData.price, onCompleteFormData.remark);
    } else {
      return false;
    }
  }

  Future<bool> _deleteMission(String id) async {
    try {
      Response response;
      response = await dio.delete(
        '/fleaMarket/marketAPI/mission/$id',
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
      return await _deleteMission(id);
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
        _getMyMissionsByLastResult();
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
                    SliverList.builder(
                      itemCount: dataList.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                          child: MissionCardWithActions(
                            data: dataList[index],
                            onComplete: _onComplete,
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
