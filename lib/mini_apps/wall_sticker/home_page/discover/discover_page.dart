import 'package:flutter/material.dart';
import 'package:meta_uni_app/mini_apps/wall_sticker/home_page/discover/today/today_page.dart';
import 'package:meta_uni_app/mini_apps/wall_sticker/home_page/discover/trend/trend_page.dart';
import 'package:meta_uni_app/reusable_components/snack_bar/normal_snack_bar.dart';

import '../../../../reusable_components/route_animation/route_animation.dart';
import '../reusable_components/sticker/post/sticker_post_page.dart';
import '../search/search_page.dart';
import 'expandable_fab/expandable_fab.dart';

class WallStickerDiscoverPage extends StatefulWidget {
  const WallStickerDiscoverPage({super.key});

  @override
  State<WallStickerDiscoverPage> createState() => _WallStickerDiscoverPageState();
}

class _WallStickerDiscoverPageState extends State<WallStickerDiscoverPage> with SingleTickerProviderStateMixin {
  GlobalKey<WallStickerTodayPageState> todayPageStateKey = GlobalKey();
  GlobalKey<WallStickerTrendPageState> trendPageStateKey = GlobalKey();

  final _tabs = const <Tab>[
    Tab(
      text: '今日',
    ),
    Tab(
      text: '热点',
    ),
  ];
  late final TabController _tabController = TabController(length: _tabs.length, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  todayPageBackToTopAndRefresh() async {
    todayPageStateKey.currentState!.animateToTop().then((value) {
      todayPageStateKey.currentState!.refresh();
    });
  }

  trendPageBackToTopAndRefresh() async {
    trendPageStateKey.currentState!.animateToTop().then((value) {
      trendPageStateKey.currentState!.refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("墙贴"),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) {
                  return const WallStickerSearchPage();
                }),
              );
            },
            icon: const Icon(
              Icons.search_outlined,
            ),
            tooltip: "搜索",
          ),
        ],
        bottom: TabBar(
          tabs: _tabs,
          controller: _tabController,
          unselectedLabelStyle: Theme.of(context).textTheme.labelMedium,
        ),
        notificationPredicate: (ScrollNotification notification) {
          return notification.depth == 1;
        },
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          WallStickerTodayPage(key: todayPageStateKey),
          WallStickerTrendPage(key: trendPageStateKey),
        ],
      ),
      floatingActionButton: ExpandableFab(
        distance: 112.0,
        //distance: 75.0,
        children: [
          ActionButton(
            onPressed: () {
              showDateRangePicker(
                context: context,
                firstDate: DateTime(2023, 09, 01),
                lastDate: DateTime.now(),
                initialDateRange: DateTimeRange(
                  start: DateTime.now().subtract(const Duration(days: 7)),
                  end: DateTime.now(),
                ),
                helpText: "查询范围",
                confirmText: "查询",
                saveText: "查询",
              ).then((value) {
                if (value != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) {
                      return WallStickerSearchPage(
                        dateTimeRange: value,
                      );
                    }),
                  );
                }
              });
            },
            icon: const Icon(
              Icons.calendar_month_outlined,
            ),
          ),
          ActionButton(
            onPressed: () {
              Navigator.push(
                context,
                routeFromBottom(
                  page: const StickerPostPage(),
                ),
              ).then((value) async {
                if (value == true) {
                  if (_tabController.index != 0) {
                    getNormalSnackBar(context, "贴贴成功");
                    _tabController.animateTo(0);
                  } else {
                    if (todayPageStateKey.currentState!.topIsOutOfScreen()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "贴贴成功",
                              ),
                            ],
                          ),
                          action: SnackBarAction(
                            onPressed: () {
                              todayPageBackToTopAndRefresh();
                            },
                            label: '查看',
                          ),
                          duration: const Duration(milliseconds: 3000),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                        ),
                      );
                    } else {
                      getNormalSnackBar(context, "贴贴成功");
                      todayPageBackToTopAndRefresh();
                    }
                  }
                }
              });
            },
            icon: const Icon(
              Icons.create_outlined,
            ),
          ),
          ActionButton(
            onPressed: () async {
              if (_tabController.index == 0) {
                todayPageBackToTopAndRefresh();
              } else if (_tabController.index == 1) {
                trendPageBackToTopAndRefresh();
              }
            },
            icon: const Icon(
              Icons.rocket_outlined,
            ),
          ),
        ],
      ),
    );
  }
}
