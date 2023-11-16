import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../../reusable_components/logout/logout.dart';
import '../../../../../../reusable_components/snack_bar/network_error_snack_bar.dart';
import '../../../../../../reusable_components/snack_bar/normal_snack_bar.dart';
import '../../../../../mini_app_manager.dart';
import '../models/channel_data.dart';

class ChannelSelectPage extends StatefulWidget {
  final String? initMainChannel;

  const ChannelSelectPage({super.key, this.initMainChannel});

  @override
  State<ChannelSelectPage> createState() => _ChannelSelectPageState();
}

class _ChannelSelectPageState extends State<ChannelSelectPage> {
  List<String> mainChannelsList = [];
  List<NavigationRailDestination> navigationRailDestinations = [];
  Map<String, List<String>> channelsMap = {};
  List<Widget> subChannelSelectButtonsList = [];

  int _selectedIndex = 0;

  late Future<dynamic> init;

  _init() async {
    await _getAllChannels();
    if (widget.initMainChannel != null) {
      _selectedIndex = mainChannelsList.indexOf(widget.initMainChannel!);
      if (_selectedIndex < 0) {
        _selectedIndex = 0;
      }
    }
    _updateSubChannelSelectButtonsList();
  }

  _getAllChannels() async {
    mainChannelsList = [];
    navigationRailDestinations = [];
    channelsMap = {};

    final Dio dio = Dio(
      BaseOptions(
        baseUrl: (await MiniAppManager().getCurrentMiniAppUrl())!,
      ),
    );

    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString('jwt');
    final uuid = prefs.getInt('uuid');

    try {
      Response response;
      response = await dio.get(
        '/fleaMarket/marketAPI/channel/all',
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 0:
          var data = response.data['data'];
          (data as Map<String, dynamic>).forEach((key, value) {
            mainChannelsList.add(key);
            navigationRailDestinations.add(
              NavigationRailDestination(
                icon: Text(key, style: Theme.of(context).textTheme.bodyMedium),
                selectedIcon: Text(
                  key,
                  style: Theme.of(context).textTheme.bodyMedium?.apply(
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                ),
                label: Text(key),
              ),
            );
            List<String> tempList = [];
            for (var element in (value as List<dynamic>)) {
              tempList.add(element);
            }
            channelsMap.addEntries([MapEntry(key, tempList)]);
          });
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

  _updateSubChannelSelectButtonsList() {
    subChannelSelectButtonsList = [];
    for (var element in channelsMap[mainChannelsList[_selectedIndex]]!) {
      subChannelSelectButtonsList.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
          child: TextButton(
            onPressed: () {
              Navigator.pop(
                context,
                ChannelData(
                  mainChannel: mainChannelsList[_selectedIndex],
                  subChannel: element,
                ),
              );
            },
            child: Text(element),
          ),
        ),
      );
    }
    subChannelSelectButtonsList.add(
      Padding(
        padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
        child: TextButton(
          onPressed: () {
            Navigator.pop(
              context,
              ChannelData(
                mainChannel: mainChannelsList[_selectedIndex],
              ),
            );
          },
          child: const Text("无"),
        ),
      ),
    );
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    init = _init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("选择频道"),
        centerTitle: true,
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
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: IntrinsicHeight(
                            child: NavigationRail(
                              selectedIndex: _selectedIndex,
                              onDestinationSelected: (int index) {
                                setState(() {
                                  _selectedIndex = index;
                                  _updateSubChannelSelectButtonsList();
                                });
                              },
                              destinations: [
                                ...navigationRailDestinations,
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const VerticalDivider(thickness: 1, width: 1),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Wrap(
                                    children: [
                                      ...subChannelSelectButtonsList,
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
