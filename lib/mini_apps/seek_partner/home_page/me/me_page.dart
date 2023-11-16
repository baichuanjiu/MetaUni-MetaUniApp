import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:meta_uni_app/mini_apps/seek_partner/home_page/reusable_components/leaflet/card/leaflet_card_with_delete_action.dart';
import 'package:meta_uni_app/mini_apps/seek_partner/home_page/reusable_components/user_card/edit/user_card_edit_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../reusable_components/logout/logout.dart';
import '../../../../reusable_components/snack_bar/network_error_snack_bar.dart';
import '../../../../reusable_components/snack_bar/normal_snack_bar.dart';
import '../../../mini_app_manager.dart';
import '../reusable_components/leaflet/models/leaflet_data.dart';
import '../reusable_components/user_card/card/user_card.dart';
import '../reusable_components/user_card/models/user_card_data.dart';

class MePage extends StatefulWidget {
  const MePage({super.key});

  @override
  State<MePage> createState() => _MePageState();
}

class _MePageState extends State<MePage> {
  final ScrollController _scrollController = ScrollController();

  late Dio dio;
  UserCardData? userCardData;
  List<LeafletData> dataList = [];
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
    _getMyLeafletsByLastResult();
    await _getMyUserCard();
  }

  _initDio() async {
    dio = Dio(
      BaseOptions(
        baseUrl: (await MiniAppManager().getCurrentMiniAppUrl())!,
      ),
    );
  }

  _getMyUserCard() async {
    try {
      Response response;
      response = await dio.get(
        '/seekPartner/leafletAPI/user/me/userCard',
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 0:
          setState(() {
            userCardData = UserCardData.fromJson(response.data['data']['data']);
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

  _getMyLeafletsByLastResult() async {
    isLoading = true;
    hasMore = false;

    try {
      Response response;
      response = await dio.get(
        lastDateTime == null && lastId == null ? '/seekPartner/leafletAPI/leaflet/me/history' : '/seekPartner/leafletAPI/leaflet/me/history/$lastDateTime/$lastId',
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
            lastDateTime = dataList.last.createdTime;
            lastId = dataList.last.id;
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
    lastDateTime = null;
    lastId = null;
    isLoading = false;
    hasMore = true;
    await _getMyLeafletsByLastResult();
  }

  Future<bool> _deleteLeaflet(String id) async {
    try {
      Response response;
      response = await dio.delete(
        '/seekPartner/leafletAPI/leaflet/$id',
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
        //Message:"您正在对一个不存在或已被删除的搭搭请求进行删除"
        case 3:
          //Message:"您正在对一个不属于您的搭搭请求进行删除"
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
            title: const Text('删除这条搭搭请求'),
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
      return await _deleteLeaflet(id);
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
        _getMyLeafletsByLastResult();
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
        title: const Text("我的"),
      ),
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
              if (userCardData == null) {
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
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) {
                                  return UserCardEditPage(data: userCardData!);
                                },
                              ),
                            ).then((value) {
                              if (value == true) {
                                _getMyUserCard();
                              }
                            });
                          },
                          child: UserCard(
                            data: userCardData!,
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(15, 10, 10, 5),
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '发布历史',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              TextSpan(
                                text: '  Tips:长按可删除搭搭请求',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                      sliver: SliverList.builder(
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.fromLTRB(0, 5, 0, 5),
                            child: LeafletCardWithDeleteAction(
                              data: dataList[index],
                              onDelete: _onDelete,
                            ),
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
              return const Center(
                child: CupertinoActivityIndicator(),
              );
          }
        },
      ),
    );
  }
}
