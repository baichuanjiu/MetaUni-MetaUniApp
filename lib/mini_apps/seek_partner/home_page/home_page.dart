import 'package:flutter/material.dart';
import 'package:meta_uni_app/mini_apps/seek_partner/home_page/explore/explore_page.dart';
import 'package:meta_uni_app/mini_apps/seek_partner/home_page/reusable_components/leaflet/post/leaflet_edit_page.dart';

import '../../../reusable_components/route_animation/route_animation.dart';
import 'me/me_page.dart';

class SeekPartnerHomePage extends StatefulWidget {
const SeekPartnerHomePage({super.key});

@override
State<SeekPartnerHomePage> createState() => _SeekPartnerHomePageState();
}

class _SeekPartnerHomePageState extends State<SeekPartnerHomePage> {
  int currentPageIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    ExplorePage(),
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
              page: const LeafletEditPage(),
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
              Icons.catching_pokemon,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
            icon: Icon(
              Icons.catching_pokemon_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            label: '搭搭',
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
