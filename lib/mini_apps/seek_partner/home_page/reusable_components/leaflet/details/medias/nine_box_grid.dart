import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:meta_uni_app/reusable_components/media/models/view_media_metadata.dart';
import '../../../../../../../reusable_components/media/view_media_page.dart';
import '../../../../../../../reusable_components/route_animation/route_animation.dart';
import '../../../../models/media/media_metadata.dart';

class NineBoxGrid extends StatefulWidget {
  final List<MediaMetadata> medias;

  const NineBoxGrid({super.key, required this.medias});

  @override
  State<NineBoxGrid> createState() => _NineBoxGridState();
}

class _NineBoxGridState extends State<NineBoxGrid> {
  @override
  Widget build(BuildContext context) {
    List<ViewMediaMetadata> viewMediaMetadataList = [];
    List<Widget> mediaList = [];
    int currentIndex = 0;
    for (var media in widget.medias) {
      String heroTag = DateTime.now().microsecondsSinceEpoch.toString();
      viewMediaMetadataList.add(
        ViewMediaMetadata(type: "image", heroTag: heroTag, imageURL: media.url),
      );
      int index = currentIndex;
      mediaList.add(
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              routeFadeIn(
                page: ViewMediaPage(
                  dataList: viewMediaMetadataList,
                  initialPage: index,
                ),
                opaque: false,
              ),
            );
          },
          child: Hero(
            tag: heroTag,
            child: CachedNetworkImage(
              fadeInDuration: const Duration(milliseconds: 800),
              fadeOutDuration: const Duration(milliseconds: 200),
              placeholder: (context, url) => const CupertinoActivityIndicator(),
              imageUrl: media.url,
              imageBuilder: (context, imageProvider) => Image(
                image: imageProvider,
                fit: BoxFit.cover,
              ),
              errorWidget: (context, url, error) => const Icon(Icons.error_outline),
            ),
          ),
        ),
      );
      currentIndex++;
    }

    return mediaList.isEmpty
        ? Container()
        : ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: mediaList.length == 1
                ? mediaList[0]
                : mediaList.length == 2 || mediaList.length == 4
                    ? AspectRatio(
                        aspectRatio: 4 / mediaList.length,
                        child: GridView.count(
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 2,
                          crossAxisSpacing: 2,
                          children: mediaList,
                        ),
                      )
                    : AspectRatio(
                        aspectRatio: 1 / ((mediaList.length / 3).ceil() / 3),
                        child: GridView.count(
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 3,
                          mainAxisSpacing: 2,
                          crossAxisSpacing: 2,
                          children: mediaList,
                        ),
                      ),
          );
  }
}
