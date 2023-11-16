import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:meta_uni_app/mini_apps/flea_market/home_page/me/mission_history/mission_history_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../database/models/user/brief_user_information.dart';
import '../../../../reusable_components/get_current_user_information/get_current_user_information.dart';
import '../../../../reusable_components/logout/logout.dart';
import '../../../../reusable_components/snack_bar/network_error_snack_bar.dart';
import '../../../../reusable_components/snack_bar/normal_snack_bar.dart';
import '../../../mini_app_manager.dart';
import 'record_history/record_history_page.dart';

class MePage extends StatefulWidget {
  const MePage({super.key});

  @override
  State<MePage> createState() => _MePageState();
}

class _MePageState extends State<MePage> {
  late BriefUserInformation me;

  _initMyBriefInformation() async {
    me = await getCurrentUserInformation();
  }

  final _tabs = const <Tab>[
    Tab(
      text: '出售',
    ),
    Tab(
      text: '求购',
    ),
    Tab(
      text: '已售',
    ),
    Tab(
      text: '已入',
    ),
  ];

  late Dio dio;

  _initDio() async {
    dio = Dio(
      BaseOptions(
        baseUrl: (await MiniAppManager().getCurrentMiniAppUrl())!,
      ),
    );
  }

  late final String? jwt;
  late final int? uuid;

  double? profit;

  _initProfit() async {
    try {
      Response response;
      response = await dio.get(
        '/fleaMarket/marketAPI/user/profit',
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

  late Future<dynamic> init;

  _init() async {
    await _initMyBriefInformation();
    await _initDio();

    final prefs = await SharedPreferences.getInstance();
    jwt = prefs.getString('jwt');
    uuid = prefs.getInt('uuid');
    _initProfit();
  }

  @override
  void initState() {
    super.initState();

    init = _init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DefaultTabController(
        initialIndex: 0,
        length: _tabs.length,
        child: NestedScrollView(
          physics: const BouncingScrollPhysics(),
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return [
              SliverOverlapAbsorber(
                handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                sliver: SliverAppBar(
                  title: const Text('我的'),
                  expandedHeight: 180,
                  collapsedHeight: 56,
                  floating: false,
                  pinned: true,
                  snap: false,
                  leading: IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.arrow_back_ios_new_outlined),
                  ),
                  forceElevated: innerBoxIsScrolled,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Center(
                      child: SafeArea(
                        child: FutureBuilder(
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
                                  return InkWell(
                                    onTap: () {
                                      Navigator.pushNamed(context, '/user/profile', arguments: me.uuid).then((value) {
                                        setState(() {
                                          _initMyBriefInformation();
                                        });
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
                                      constraints: const BoxConstraints(
                                        maxHeight: 65,
                                      ),
                                      child: Row(
                                        children: [
                                          Avatar(me.avatar),
                                          Expanded(
                                            child: Container(
                                              padding: const EdgeInsets.fromLTRB(15, 0, 0, 0),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  SingleChildScrollView(
                                                    scrollDirection: Axis.horizontal,
                                                    physics: const BouncingScrollPhysics(),
                                                    child: Text(
                                                      me.nickname,
                                                      style: Theme.of(context).textTheme.headlineSmall,
                                                    ),
                                                  ),
                                                  SingleChildScrollView(
                                                    scrollDirection: Axis.horizontal,
                                                    physics: const BouncingScrollPhysics(),
                                                    child: Text(
                                                      'UUID：${me.uuid.toString()}',
                                                      style: Theme.of(context).textTheme.labelSmall?.apply(color: Theme.of(context).colorScheme.outline),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          profit == null
                                              ? Container()
                                              : Container(
                                                  constraints: BoxConstraints(
                                                    maxWidth: MediaQuery.of(context).size.width * 0.45,
                                                  ),
                                                  child: SingleChildScrollView(
                                                    scrollDirection: Axis.horizontal,
                                                    physics: const BouncingScrollPhysics(),
                                                    child: profit! > 0
                                                        ? Text(
                                                            "+ ￥${profit!.toStringAsFixed(2)}",
                                                            style: Theme.of(context).textTheme.bodyLarge?.apply(color: Colors.green),
                                                          )
                                                        : profit! < 0
                                                            ? Text(
                                                                "- ￥${profit!.toStringAsFixed(2).substring(1)}",
                                                                style: Theme.of(context).textTheme.bodyLarge?.apply(color: Colors.red),
                                                              )
                                                            : Text(
                                                                "￥${profit!.toStringAsFixed(2)}",
                                                                style: Theme.of(context).textTheme.bodyLarge,
                                                              ),
                                                  ),
                                                ),
                                        ],
                                      ),
                                    ),
                                  );
                                default:
                                  return const CupertinoActivityIndicator();
                              }
                            }),
                      ),
                    ),
                    collapseMode: CollapseMode.parallax,
                  ),
                  bottom: TabBar(
                    tabs: _tabs,
                    unselectedLabelStyle: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ),
            ];
          },
          body: const TabBarView(
            children: [
              Center(
                child: MissionHistoryPage(
                  type: "sell",
                ),
              ),
              Center(
                child: MissionHistoryPage(
                  type: "purchase",
                ),
              ),
              Center(
                child: RecordHistoryPage(
                  type: "sell",
                ),
              ),
              Center(
                child: RecordHistoryPage(
                  type: "purchase",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Avatar extends StatelessWidget {
  final String avatar;

  const Avatar(this.avatar, {super.key});

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      fadeInDuration: const Duration(milliseconds: 800),
      fadeOutDuration: const Duration(milliseconds: 200),
      placeholder: (context, url) => SizedBox(
        width: 55,
        height: 55,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: const Center(
            child: CupertinoActivityIndicator(),
          ),
        ),
      ),
      imageUrl: avatar,
      imageBuilder: (context, imageProvider) => SizedBox(
        width: 55,
        height: 55,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Image(
            image: imageProvider,
          ),
        ),
      ),
      errorWidget: (context, url, error) => SizedBox(
        width: 55,
        height: 55,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: const Center(
            child: Icon(Icons.error_outline),
          ),
        ),
      ),
    );
  }
}
