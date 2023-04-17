import 'dart:ui';

import 'package:flutter/material.dart';
import 'search/search_box.dart';

class DiscoverWarehousePage extends StatelessWidget {
  const DiscoverWarehousePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(seconds: 1));
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics(),),
          primary: false,
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: Container(padding: EdgeInsets.fromLTRB(0, 10, 0, 0), child: DiscoverWarehouseSearchBox()),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(10),
              sliver: SliverGrid.count(
                crossAxisSpacing: 0,
                mainAxisSpacing: 0,
                crossAxisCount: 2,
                children: <Widget>[
                  InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: () {},
                    child: Card(
                      elevation: 0,
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      child: Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          Column(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: const Image(
                                          fit: BoxFit.cover,
                                          image: AssetImage('assets/test.png'),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(
                                height: 40,
                              ),
                            ],
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 7.0, sigmaY: 7.0),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: const [
                                          SizedBox(
                                            height: 53,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              SizedBox(
                                height: 40,
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Text(
                                      '小程序',
                                      style: Theme.of(context).textTheme.labelLarge,
                                    ),
                                    Text(
                                      '没啥用处呢',
                                      style: Theme.of(context).textTheme.labelSmall?.apply(color: Theme.of(context).colorScheme.outline),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Positioned(
                            bottom: 30,
                            child: Column(
                              children: [
                                SizedBox(
                                  width: 45,
                                  height: 45,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: const Image(
                                      image: AssetImage('assets/DefaultAvatar.jpg'),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: () {},
                    child: Card(
                      elevation: 0,
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      child: Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          Column(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: const Image(
                                          fit: BoxFit.cover,
                                          image: AssetImage('assets/test.png'),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(
                                height: 40,
                              ),
                            ],
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 7.0, sigmaY: 7.0),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: const [
                                          SizedBox(
                                            height: 53,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              SizedBox(
                                height: 40,
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Text(
                                      '小程序',
                                      style: Theme.of(context).textTheme.labelLarge,
                                    ),
                                    Text(
                                      '没啥用处呢',
                                      style: Theme.of(context).textTheme.labelSmall?.apply(color: Theme.of(context).colorScheme.outline),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Positioned(
                            bottom: 30,
                            child: Column(
                              children: [
                                SizedBox(
                                  width: 45,
                                  height: 45,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: const Image(
                                      image: AssetImage('assets/DefaultAvatar.jpg'),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: () {},
                    child: Card(
                      elevation: 0,
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      child: Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          Column(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: const Image(
                                          fit: BoxFit.cover,
                                          image: AssetImage('assets/test.png'),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(
                                height: 40,
                              ),
                            ],
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 7.0, sigmaY: 7.0),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: const [
                                          SizedBox(
                                            height: 53,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              SizedBox(
                                height: 40,
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Text(
                                      '小程序',
                                      style: Theme.of(context).textTheme.labelLarge,
                                    ),
                                    Text(
                                      '没啥用处呢',
                                      style: Theme.of(context).textTheme.labelSmall?.apply(color: Theme.of(context).colorScheme.outline),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Positioned(
                            bottom: 30,
                            child: Column(
                              children: [
                                SizedBox(
                                  width: 45,
                                  height: 45,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: const Image(
                                      image: AssetImage('assets/DefaultAvatar.jpg'),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: () {},
                    child: Card(
                      elevation: 0,
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      child: Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          Column(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: const Image(
                                          fit: BoxFit.cover,
                                          image: AssetImage('assets/test.png'),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(
                                height: 40,
                              ),
                            ],
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 7.0, sigmaY: 7.0),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: const [
                                          SizedBox(
                                            height: 53,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              SizedBox(
                                height: 40,
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Text(
                                      '小程序',
                                      style: Theme.of(context).textTheme.labelLarge,
                                    ),
                                    Text(
                                      '没啥用处呢',
                                      style: Theme.of(context).textTheme.labelSmall?.apply(color: Theme.of(context).colorScheme.outline),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Positioned(
                            bottom: 30,
                            child: Column(
                              children: [
                                SizedBox(
                                  width: 45,
                                  height: 45,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: const Image(
                                      image: AssetImage('assets/DefaultAvatar.jpg'),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: () {},
                    child: Card(
                      elevation: 0,
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      child: Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          Column(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: const Image(
                                          fit: BoxFit.cover,
                                          image: AssetImage('assets/test.png'),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(
                                height: 40,
                              ),
                            ],
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 7.0, sigmaY: 7.0),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: const [
                                          SizedBox(
                                            height: 53,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              SizedBox(
                                height: 40,
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Text(
                                      '小程序',
                                      style: Theme.of(context).textTheme.labelLarge,
                                    ),
                                    Text(
                                      '没啥用处呢',
                                      style: Theme.of(context).textTheme.labelSmall?.apply(color: Theme.of(context).colorScheme.outline),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Positioned(
                            bottom: 30,
                            child: Column(
                              children: [
                                SizedBox(
                                  width: 45,
                                  height: 45,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: const Image(
                                      image: AssetImage('assets/DefaultAvatar.jpg'),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: () {},
                    child: Card(
                      elevation: 0,
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      child: Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          Column(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: const Image(
                                          fit: BoxFit.cover,
                                          image: AssetImage('assets/test.png'),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(
                                height: 40,
                              ),
                            ],
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 7.0, sigmaY: 7.0),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: const [
                                          SizedBox(
                                            height: 53,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              SizedBox(
                                height: 40,
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Text(
                                      '小程序',
                                      style: Theme.of(context).textTheme.labelLarge,
                                    ),
                                    Text(
                                      '没啥用处呢',
                                      style: Theme.of(context).textTheme.labelSmall?.apply(color: Theme.of(context).colorScheme.outline),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Positioned(
                            bottom: 30,
                            child: Column(
                              children: [
                                SizedBox(
                                  width: 45,
                                  height: 45,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: const Image(
                                      image: AssetImage('assets/DefaultAvatar.jpg'),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: () {},
                    child: Card(
                      elevation: 0,
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      child: Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          Column(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: const Image(
                                          fit: BoxFit.cover,
                                          image: AssetImage('assets/test.png'),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(
                                height: 40,
                              ),
                            ],
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 7.0, sigmaY: 7.0),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: const [
                                          SizedBox(
                                            height: 53,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              SizedBox(
                                height: 40,
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Text(
                                      '小程序',
                                      style: Theme.of(context).textTheme.labelLarge,
                                    ),
                                    Text(
                                      '没啥用处呢',
                                      style: Theme.of(context).textTheme.labelSmall?.apply(color: Theme.of(context).colorScheme.outline),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Positioned(
                            bottom: 30,
                            child: Column(
                              children: [
                                SizedBox(
                                  width: 45,
                                  height: 45,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: const Image(
                                      image: AssetImage('assets/DefaultAvatar.jpg'),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: () {},
                    child: Card(
                      elevation: 0,
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      child: Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          Column(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: const Image(
                                          fit: BoxFit.cover,
                                          image: AssetImage('assets/test.png'),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(
                                height: 40,
                              ),
                            ],
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 7.0, sigmaY: 7.0),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: const [
                                          SizedBox(
                                            height: 53,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              SizedBox(
                                height: 40,
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Text(
                                      '小程序',
                                      style: Theme.of(context).textTheme.labelLarge,
                                    ),
                                    Text(
                                      '没啥用处呢',
                                      style: Theme.of(context).textTheme.labelSmall?.apply(color: Theme.of(context).colorScheme.outline),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Positioned(
                            bottom: 30,
                            child: Column(
                              children: [
                                SizedBox(
                                  width: 45,
                                  height: 45,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: const Image(
                                      image: AssetImage('assets/DefaultAvatar.jpg'),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
