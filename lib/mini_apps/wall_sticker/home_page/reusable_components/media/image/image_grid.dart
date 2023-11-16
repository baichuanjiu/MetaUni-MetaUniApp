import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ImageGrid extends StatelessWidget {
  final String url;
  final String heroTag;
  final Function jumpFunction;

  const ImageGrid({super.key,required this.url,required this.heroTag,required this.jumpFunction});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        jumpFunction();
      },
      child: Hero(
        tag: heroTag,
        child: CachedNetworkImage(
          fadeInDuration: const Duration(milliseconds: 800),
          fadeOutDuration: const Duration(milliseconds: 200),
          placeholder: (context, url) => const CupertinoActivityIndicator(),
          imageUrl: url,
          imageBuilder: (context, imageProvider) => Image(
            image: imageProvider,
            fit: BoxFit.cover,
          ),
          errorWidget: (context, url, error) => const Icon(Icons.error_outline),
        ),
      ),
    );
  }
}
