import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta_uni_app/reusable_components/gallery/function/pick_multiple_medias.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../../../../../../reusable_components/gallery/view/reusable_components/media_grid.dart';
import '../../../../../../../reusable_components/gallery/view/reusable_components/selected_assets_bloc.dart';

class GallerySlide extends StatefulWidget {
  final RequestType type;
  final int maxCount;
  final Function sendMessage;

  const GallerySlide({super.key, this.type = RequestType.common, this.maxCount = 9,required this.sendMessage});

  @override
  State<GallerySlide> createState() => _GallerySlideState();
}

class _GallerySlideState extends State<GallerySlide> {
  late final List<AssetPathEntity> paths;
  late AssetPathEntity currentChosenAlbum;
  late Future<dynamic> init;
  List<MediaGrid> grids = [];

  late SelectedAssetsCubit selectedAssetsCubit = context.read<SelectedAssetsCubit>();
  late List<AssetEntity> selectedAssets = selectedAssetsCubit.state;

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
          height: 200,
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
          },
        ),
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

  final ScrollController _scrollController = ScrollController();

  _init() async {
    paths = await PhotoManager.getAssetPathList(type: widget.type);

    currentChosenAlbum = paths.first;

    await _loadAssets();
  }

  @override
  void initState() {
    super.initState();

    init = _init();
    _scrollController.addListener(() {
      if (_scrollController.position.extentAfter < 300 && !isLoading && hasMore) {
        isLoading = true;
        _loadAssets();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
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
            return BlocConsumer<SelectedAssetsCubit, List<AssetEntity>>(
              listener: (context, newAssets) {
                setState(() {
                  selectedAssets = newAssets;
                });
              },
              builder: (context, state) {
                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        controller: _scrollController,
                        child: Row(
                          children: grids,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 56,
                      width: double.infinity,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                            child: TextButton(
                              onPressed: () async {
                                selectedAssets = await pickMultipleMedias(context: context, selectedAssets: selectedAssets, maxCount: widget.maxCount);
                                selectedAssetsCubit.replace(selectedAssets);
                                setState(() {});
                              },
                              child: const Text("相册"),
                            ),
                          ),
                          Text("${selectedAssets.length} / ${widget.maxCount}"),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                            child: ElevatedButton(
                              onPressed: selectedAssets.isEmpty ? null : () {
                                widget.sendMessage();
                              },
                              child: const Text("发送"),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          default:
            return const Center(
              child: CupertinoActivityIndicator(),
            );
        }
      },
    );
  }
}
