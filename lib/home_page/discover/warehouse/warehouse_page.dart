import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/dio_model.dart';
import '../../../reusable_components/logout/logout.dart';
import '../../../reusable_components/snack_bar/network_error_snack_bar.dart';
import '../../../reusable_components/snack_bar/normal_snack_bar.dart';
import 'models/mini_app_information.dart';
import 'search/search_box.dart';

class DiscoverWarehousePage extends StatefulWidget {
  const DiscoverWarehousePage({super.key});

  @override
  State<DiscoverWarehousePage> createState() => _DiscoverWarehousePageState();
}

class _DiscoverWarehousePageState extends State<DiscoverWarehousePage> {
  final DioModel dioModel = DioModel();
  int rank = 0;
  List<MiniAppInformationGrid> miniAppInformationGrids = [];
  bool isReady = false;
  Widget endIndicator = Container();
  bool isLoading = false;
  bool hasMore = true;

  late Future<dynamic> init;

  _getMiniAppsByRank() async {
    final prefs = await SharedPreferences.getInstance();

    final String? jwt = prefs.getString('jwt');
    final int? uuid = prefs.getInt('uuid');

    isLoading = true;
    hasMore = false;

    try {
      Response response;
      response = await dioModel.dio.get(
        '/metaUni/miniAppAPI/miniApp/$rank',
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 0:
          List<dynamic> dataList = response.data['data'];
          for (var element in dataList) {
            miniAppInformationGrids = [
              ...miniAppInformationGrids,
              MiniAppInformationGrid(
                miniAppInformation: MiniAppInformation.fromJson(element),
              ),
            ];
          }
          rank += dataList.length;
          if (dataList.length < 20) {
            endIndicator = const Center(
              child: Padding(
                padding: EdgeInsets.fromLTRB(0, 0, 0, 10),
                child: Text("没有更多了呢"),
              ),
            );
            hasMore = false;
          }
          else
          {
            hasMore = true;
          }
          setState(() {
            isReady = true;
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

    isLoading = false;
  }

  ScrollController appsListController = ScrollController();

  @override
  void initState() {
    super.initState();

    init = _getMiniAppsByRank();
    appsListController.addListener(() {
      if(appsListController.position.extentAfter < 300 && !isLoading && hasMore){
        isLoading = true;
        _getMiniAppsByRank();
      }
    });
  }

  @override
  void dispose() {
    appsListController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          rank = 0;
          miniAppInformationGrids = [];
          endIndicator = Container();
          isLoading = false;
          hasMore = true;
          await _getMiniAppsByRank();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          controller: appsListController,
          primary: false,
          slivers: <Widget>[
            const SliverToBoxAdapter(
              child: Padding(padding: EdgeInsets.fromLTRB(0, 10, 0, 0), child: DiscoverWarehouseSearchBox(),),
            ),
            FutureBuilder(
              future: init,
              builder: (context, snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.none:
                    return SliverToBoxAdapter(
                      child: Center(
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                          child: const CupertinoActivityIndicator(),
                        ),
                      ),
                    );
                  case ConnectionState.active:
                    return SliverToBoxAdapter(
                      child: Center(
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                          child: const CupertinoActivityIndicator(),
                        ),
                      ),
                    );
                  case ConnectionState.waiting:
                    return SliverToBoxAdapter(
                      child: Center(
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                          child: const CupertinoActivityIndicator(),
                        ),
                      ),
                    );
                  case ConnectionState.done:
                    if (snapshot.hasError) {
                      return SliverToBoxAdapter(
                        child: Center(
                          child: Container(
                            margin: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                            child: const CupertinoActivityIndicator(),
                          ),
                        ),
                      );
                    }
                    if (!isReady) {
                      return SliverToBoxAdapter(
                        child: Center(
                          child: Container(
                            margin: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                            child: const CupertinoActivityIndicator(),
                          ),
                        ),
                      );
                    }
                    return SliverPadding(
                      padding: const EdgeInsets.all(10),
                      sliver: SliverGrid.count(
                        crossAxisSpacing: 0,
                        mainAxisSpacing: 0,
                        crossAxisCount: 2,
                        children: miniAppInformationGrids,
                      ),
                    );
                  default:
                    return SliverToBoxAdapter(
                      child: Center(
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                          child: const CupertinoActivityIndicator(),
                        ),
                      ),
                    );
                }
              },
            ),
            SliverToBoxAdapter(
              child: endIndicator,
            ),
          ],
        ),
      ),
    );
  }
}

class MiniAppInformationGrid extends StatelessWidget {
  final MiniAppInformation miniAppInformation;

  const MiniAppInformationGrid({required this.miniAppInformation, super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: () {
        if(miniAppInformation.type == "ClientApp")
        {
          Navigator.pushNamed(context, '/discover/warehouse/clientApp/introduction',arguments: miniAppInformation);
        }
        else if(miniAppInformation.type == "WebApp"){
          Navigator.pushNamed(context, '/discover/warehouse/webApp/introduction',arguments: miniAppInformation);
        }
      },
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
                        child: CachedNetworkImage(
                          fadeInDuration: const Duration(milliseconds: 800),
                          fadeOutDuration: const Duration(milliseconds: 200),
                          placeholder: (context, url) => const CupertinoActivityIndicator(),
                          imageUrl: miniAppInformation.backgroundImage,
                          imageBuilder: (context, imageProvider) => ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image(
                              image: imageProvider,
                              fit: BoxFit.cover,
                            ),
                          ),
                          errorWidget: (context, url, error) => const Icon(Icons.error_outline),
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
                    filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
                    child: const Column(
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              height: 56,
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
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 0, 5, 0),
                          child: Center(
                            child: Text(
                              miniAppInformation.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(5, 0, 10, 0),
                          child: Center(
                            child: Text(
                              miniAppInformation.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelSmall?.apply(color: Theme.of(context).colorScheme.outline),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: 35,
              child: Column(
                children: [
                  CachedNetworkImage(
                    fadeInDuration: const Duration(milliseconds: 800),
                    fadeOutDuration: const Duration(milliseconds: 200),
                    placeholder: (context, url) => const CupertinoActivityIndicator(),
                    imageUrl: miniAppInformation.avatar,
                    imageBuilder: (context, imageProvider) => SizedBox(
                      width: 42,
                      height: 42,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image(
                          image: imageProvider,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => const Icon(Icons.error_outline),
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
