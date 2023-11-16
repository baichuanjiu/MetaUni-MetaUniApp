import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../../../../../reusable_components/media/video/video_preview.dart';

class VideoGrid extends StatelessWidget {
  final String previewImage;
  final double aspectRatio;
  final Duration timeTotal;
  final VideoPlayerController controller;
  final String heroTag;
  final Function jumpFunction;

  const VideoGrid({super.key,required this.previewImage,required this.aspectRatio,required this.timeTotal,required this.controller,required this.heroTag,required this.jumpFunction});

  @override
  Widget build(BuildContext context) {
    return VideoPreview(previewImage: previewImage,aspectRatio: aspectRatio,timeTotal: timeTotal,controller: controller,heroTag: heroTag,jumpFunction: jumpFunction,);
  }
}
