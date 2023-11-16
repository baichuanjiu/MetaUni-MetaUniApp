import 'package:flutter/material.dart';
import 'discover/discover_page.dart';
import 'me/me_page.dart';

class WallStickerHomePage extends StatefulWidget {
  const WallStickerHomePage({super.key});

  @override
  State<WallStickerHomePage> createState() => _WallStickerHomePageState();
}

class _WallStickerHomePageState extends  State<WallStickerHomePage>
{
  int currentPageIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    WallStickerDiscoverPage(),
    WallStickerMePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              Icons.interests,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
            icon: Icon(
              Icons.interests_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            label: '发现',
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