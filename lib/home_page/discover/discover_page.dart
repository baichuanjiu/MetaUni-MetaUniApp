import 'package:flutter/material.dart';
import 'package:meta_uni_app/home_page/discover/trend/trend_page.dart';
import 'warehouse/warehouse_page.dart';
import 'home/home_page.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  final _tabs = const <Tab>[
    Tab(
      icon: Icon(Icons.local_fire_department_outlined),
      text: '推荐',
    ),
    Tab(
      icon: Icon(Icons.home_outlined),
      text: '首页',
    ),
    Tab(
      icon: Icon(Icons.local_shipping_outlined),
      text: '仓库',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: 1,
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('发现'),
          bottom: TabBar(
            tabs: _tabs,
            unselectedLabelStyle: Theme.of(context).textTheme.labelMedium,
          ),
          notificationPredicate: (ScrollNotification notification) {
            return notification.depth == 1;
          },
        ),
        body: const TabBarView(
          children: [
            DiscoverTrendPage(),
            DiscoverHomePage(),
            DiscoverWarehousePage(),
          ],
        ),
      ),
    );
  }
}
