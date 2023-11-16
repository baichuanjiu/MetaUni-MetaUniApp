import 'package:video_player/video_player.dart';

class ViewMediaMetadata {
  final String type; //"image" or "video"
  final String? imageURL;
  final VideoPlayerController? videoPlayerController;
  final String heroTag;

  ViewMediaMetadata({required this.type, this.imageURL, this.videoPlayerController, required this.heroTag});
}
