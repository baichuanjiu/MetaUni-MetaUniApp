import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta_uni_app/reusable_components/gallery/view/reusable_components/media_grid.dart';
import 'package:meta_uni_app/reusable_components/gallery/view/reusable_components/selected_assets_bloc.dart';
import 'package:photo_manager/photo_manager.dart';

class GalleryPage extends StatefulWidget {
  final RequestType type;
  final List<AssetEntity> selectedAssets;
  final int maxCount;

  const GalleryPage({super.key, this.type = RequestType.common, this.selectedAssets = const [], this.maxCount = 9});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  late final List<AssetPathEntity> paths;
  late AssetPathEntity currentChosenAlbum;
  late Future<dynamic> init;
  List<MediaGrid> grids = [];

  late List<AssetEntity> selectedAssets = [...widget.selectedAssets];
  late SelectedAssetsCubit selectedAssetsCubit = SelectedAssetsCubit(selectedAssets);

  bool isLoading = false;
  bool hasMore = true;
  int index = 0;
  int range = 80;

  _loadAssets() async {
    isLoading = true;
    hasMore = false;

    final List<AssetEntity> entities = await currentChosenAlbum.getAssetListRange(start: index * range, end: (index + 1) * range);
    index++;
    for (var asset in entities) {
      grids.add(
        MediaGrid(
            asset: asset,
            tapCallback: (AssetEntity asset) {
              if (widget.maxCount == 1) {
                selectedAssetsCubit.onlyOne(asset);
                setState(() {
                  selectedAssets.clear();
                  selectedAssets.add(asset);
                });
              } else {
                if (selectedAssets.length < widget.maxCount) {
                  selectedAssetsCubit.add(asset);
                  setState(() {
                    selectedAssets.add(asset);
                  });
                }
              }
            },
            tapCancelCallback: (AssetEntity asset) {
              selectedAssetsCubit.remove(asset);
              setState(() {
                selectedAssets.remove(asset);
              });
            }),
      );
    }

    if (entities.length < range) {
      hasMore = false;
    }
    else
    {
      hasMore = true;
    }

    isLoading = false;
  }

  ScrollController scrollController = ScrollController();

  _init() async {
    paths = await PhotoManager.getAssetPathList(type: widget.type);

    currentChosenAlbum = paths.first;

    await _loadAssets();
  }

  @override
  void initState() {
    super.initState();

    init = _init();
    scrollController.addListener(() {
      if (scrollController.position.extentAfter < 300 && !isLoading && hasMore) {
        isLoading = true;
        _loadAssets();
      }
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder(
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
                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text(
                              "取消",
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              final List<ListTile> tiles = [];
                              for (var path in paths) {
                                tiles.add(
                                  ListTile(
                                    onTap: () {
                                      Navigator.pop(context, path);
                                    },
                                    leading: Container(
                                      padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
                                      child: AspectRatio(
                                        aspectRatio: 1.0 / 1.0,
                                        child: Image(
                                          image: AssetEntityImageProvider((await path.getAssetListRange(start: 0, end: 1)).first),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      path.name,
                                    ),
                                    trailing: const Icon(
                                      Icons.arrow_right_outlined,
                                    ),
                                  ),
                                );
                              }

                              if (mounted) {
                                final newChosenAlbum = await showDialog<AssetPathEntity>(
                                  context: context,
                                  builder: (BuildContext context) => AlertDialog(
                                    content: Container(
                                      width: 200,
                                      constraints: BoxConstraints(
                                        maxHeight: MediaQuery.of(context).size.height,
                                        maxWidth: MediaQuery.of(context).size.width,
                                      ),
                                      child: ListView(
                                        shrinkWrap: true,
                                        children: tiles,
                                      ),
                                    ),
                                  ),
                                );
                                if (newChosenAlbum != null && currentChosenAlbum.id != newChosenAlbum.id) {
                                  currentChosenAlbum = newChosenAlbum;
                                  index = 0;
                                  scrollController.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.ease);
                                  grids = [];
                                  await _loadAssets();
                                  setState(() {});
                                }
                              }
                            },
                            child: Text(
                              "${currentChosenAlbum.name} ▼",
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          TextButton(
                            onPressed: selectedAssets.isEmpty
                                ? null
                                : () {
                                    Navigator.pop(context, selectedAssets);
                                  },
                            child: Text(selectedAssets.isEmpty ? "确定" : "确定 (${selectedAssets.length}) "),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.fromLTRB(0, 0, 0, 10),
                      child: Text("${selectedAssets.length} / ${widget.maxCount}"),
                    ),
                    Expanded(
                      child: BlocProvider<SelectedAssetsCubit>.value(
                        value: selectedAssetsCubit,
                        child: GridView.count(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          controller: scrollController,
                          crossAxisCount: 3,
                          children: grids,
                        ),
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
      ),
    );
  }
}
