import 'package:flutter/material.dart';
import 'package:meta_uni_app/mini_apps/flea_market/home_page/market/market_page.dart';
import 'package:meta_uni_app/mini_apps/flea_market/home_page/me/me_page.dart';
import 'package:meta_uni_app/mini_apps/flea_market/home_page/reusable_components/mission/post/mission_post_page.dart';

import '../../../reusable_components/route_animation/route_animation.dart';

class FleaMarketHomePage extends StatefulWidget {
  const FleaMarketHomePage({super.key});

  @override
  State<FleaMarketHomePage> createState() => _FleaMarketHomePageState();
}

class _FleaMarketHomePageState extends State<FleaMarketHomePage> {
  int currentPageIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    MarketPage(),
    MePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            routeFromBottom(
              page: const MissionPostPage(),
            ),
          );
        },
        shape: const CircleBorder(),
        child: Icon(
          Icons.add_outlined,
          size: 32,
          color: Theme.of(context).colorScheme.onSecondaryContainer,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: Center(
        child: _widgetOptions.elementAt(currentPageIndex),
      ),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        selectedIndex: currentPageIndex,
        destinations: <Widget>[
          NavigationDestination(
            selectedIcon: Icon(
              Icons.sell_outlined,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
            icon: Icon(
              Icons.sell_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            label: '市场',
          ),
          NavigationDestination(
            selectedIcon: Icon(
              Icons.account_circle,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
            icon: Icon(
              Icons.account_circle_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            label: '我的',
          ),
        ],
      ),
    );
  }
}
