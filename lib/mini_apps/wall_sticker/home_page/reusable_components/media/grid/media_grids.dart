import 'package:flutter/material.dart';
import 'package:meta_uni_app/reusable_components/media/view_media_page.dart';
import 'package:meta_uni_app/reusable_components/route_animation/route_animation.dart';
import 'package:video_player/video_player.dart';
import '../../../../../../../reusable_components/media/models/view_media_metadata.dart';
import '../image/image_grid.dart';
import '../models/media_metadata.dart';
import '../video/video_grid.dart';

class MediaGrids extends StatefulWidget {
  final List<MediaMetadata> dataList;

  const MediaGrids({super.key, required this.dataList});

  @override
  State<MediaGrids> createState() => _MediaGridsState();
}

class _MediaGridsState extends State<MediaGrids> {
  late List<ViewMediaMetadata> viewMediaMetadataList = [];
  late List<Widget> grids = [];
  late int currentIndex = 0;

  _initGrids() {
    viewMediaMetadataList = [];
    grids = [];
    currentIndex = 0;
    for (var data in widget.dataList) {
      String heroTag = DateTime.now().microsecondsSinceEpoch.toString();
      if (data.type == "image") {
        viewMediaMetadataList.add(
          ViewMediaMetadata(type: "image", heroTag: heroTag, imageURL: data.url),
        );
        int index = currentIndex;
        grids.add(
          ImageGrid(
            url: data.url,
            heroTag: heroTag,
            jumpFunction: () {
              Navigator.push(
                context,
                routeFadeIn(
                  page: ViewMediaPage(
                    dataList: viewMediaMetadataList,
                    initialPage: index,
                  ),
                  opaque: false,
                ),
                // CupertinoPageRoute(builder: (context) {
                //   return ViewMediaPage(
                //     dataList: viewMediaMetadataList,
                //     initialPage: index,
                //   );
                // }),
              );
            },
          ),
        );
        currentIndex++;
      } else if (data.type == "video") {
        VideoPlayerController controller = VideoPlayerController.networkUrl(
          Uri.parse(data.url),
        );
        viewMediaMetadataList.add(
          ViewMediaMetadata(type: "video", heroTag: heroTag, videoPlayerController: controller),
        );
        int index = currentIndex;
        grids.add(
          VideoGrid(
              previewImage: data.previewImage!,
              aspectRatio: data.aspectRatio,
              timeTotal: data.timeTotal!,
              controller: controller,
              heroTag: heroTag,
              jumpFunction: () {
                Navigator.push(
                  context,
                  routeFadeIn(
                    page: ViewMediaPage(
                      dataList: viewMediaMetadataList,
                      initialPage: index,
                    ),
                    opaque: false,
                  ),
                  // CupertinoPageRoute(builder: (context) {
                  //   return ViewMediaPage(
                  //     dataList: viewMediaMetadataList,
                  //     initialPage: index,
                  //   );
                  // }),
                );
              }),
        );
        currentIndex++;
      }
    }
  }

  @override
  void initState() {
    super.initState();

    _initGrids();
  }

  @override
  void didUpdateWidget(covariant MediaGrids oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.dataList.length != widget.dataList.length) {
      _initGrids();
    } else {
      for (int i = 0; i < widget.dataList.length; i++) {
        if (widget.dataList[i].url != oldWidget.dataList[i].url) {
          _initGrids();
          break;
        }
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //原来Twitter限制了只能上传4张图片或视频，那就好办了。
    //上传多个媒体时固定使用16比9
    //其实是一个描边Card
    switch (widget.dataList.length) {
      case 1:
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: Theme.of(context).colorScheme.outline,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(12)),
          ),
          clipBehavior: Clip.antiAliasWithSaveLayer,
          child: AspectRatio(
            aspectRatio: widget.dataList[0].aspectRatio,
            child: grids[0],
          ),
        );

      case 2:
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: Theme.of(context).colorScheme.outline,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(12)),
          ),
          clipBehavior: Clip.antiAliasWithSaveLayer,
          child: AspectRatio(
            aspectRatio: 16.0 / 9.0,
            child: Row(
              children: [
                AspectRatio(
                  aspectRatio: 8.0 / 9.0,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(0, 0, 1, 0),
                    child: grids[0],
                  ),
                ),
                AspectRatio(
                  aspectRatio: 8.0 / 9.0,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(1, 0, 0, 0),
                    child: grids[1],
                  ),
                ),
              ],
            ),
          ),
        );
      case 3:
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: Theme.of(context).colorScheme.outline,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(12)),
          ),
          clipBehavior: Clip.antiAliasWithSaveLayer,
          child: AspectRatio(
            aspectRatio: 16.0 / 9.0,
            child: Row(
              children: [
                AspectRatio(
                  aspectRatio: 8.0 / 9.0,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(0, 0, 2, 0),
                    child: grids[0],
                  ),
                ),
                AspectRatio(
                  aspectRatio: 8.0 / 9.0,
                  child: Column(
                    children: [
                      AspectRatio(
                        aspectRatio: 8.0 / 4.5,
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(0, 0, 0, 1),
                          child: grids[1],
                        ),
                      ),
                      AspectRatio(
                        aspectRatio: 8.0 / 4.5,
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(0, 1, 0, 0),
                          child: grids[2],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      case 4:
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: Theme.of(context).colorScheme.outline,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(12)),
          ),
          clipBehavior: Clip.antiAliasWithSaveLayer,
          child: AspectRatio(
            aspectRatio: 16.0 / 9.0,
            child: Row(
              children: [
                AspectRatio(
                  aspectRatio: 8.0 / 9.0,
                  child: Column(
                    children: [
                      AspectRatio(
                        aspectRatio: 8.0 / 4.5,
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(0, 0, 1, 1),
                          child: grids[0],
                        ),
                      ),
                      AspectRatio(
                        aspectRatio: 8.0 / 4.5,
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(0, 1, 1, 0),
                          child: grids[2],
                        ),
                      ),
                    ],
                  ),
                ),
                AspectRatio(
                  aspectRatio: 8.0 / 9.0,
                  child: Column(
                    children: [
                      AspectRatio(
                        aspectRatio: 8.0 / 4.5,
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(1, 0, 0, 1),
                          child: grids[1],
                        ),
                      ),
                      AspectRatio(
                        aspectRatio: 8.0 / 4.5,
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(1, 1, 0, 0),
                          child: grids[3],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      default:
        return Container();
    }
  }
}
