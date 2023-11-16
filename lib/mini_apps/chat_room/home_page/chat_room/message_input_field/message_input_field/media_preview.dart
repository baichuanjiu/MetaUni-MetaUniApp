import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class MediaPreview extends StatefulWidget {
  final AssetEntity asset;
  final bool isVideo;
  final Function remove;

  const MediaPreview({super.key, required this.asset, this.isVideo = false, required this.remove});

  @override
  State<MediaPreview> createState() => _MediaPreviewState();
}

class _MediaPreviewState extends State<MediaPreview> {
  @override
  Widget build(BuildContext context) {
    if (widget.isVideo) {
      return Container(
        margin: const EdgeInsets.fromLTRB(0, 0, 5, 0),
        child: Center(
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image(
                  height: 200,
                  image: AssetEntityImageProvider(widget.asset),
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                left: 5,
                bottom: 5,
                child: TotalTime(
                  time: widget.asset.videoDuration,
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: () {
                    widget.remove();
                  },
                  child: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                    radius: 10,
                    child: Icon(
                      Icons.close_outlined,
                      color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return Container(
        margin: const EdgeInsets.fromLTRB(0, 0, 5, 0),
        child: Center(
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image(
                  height: 200,
                  image: AssetEntityImageProvider(widget.asset),
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: () {
                    widget.remove();
                  },
                  child: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                    radius: 10,
                    child: Icon(
                      Icons.close_outlined,
                      color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}

String formatTime(Duration time) {
  if (time.inHours < 1) {
    return time.toString().substring(2, 7);
  } else {
    int digit = 0;
    double number = time.inHours.toDouble();
    while (number >= 1) {
      digit++;
      number = (number / 10);
    }
    return time.toString().substring(0, 6 + digit);
  }
}

class TotalTime extends StatelessWidget {
  final Duration time;

  const TotalTime({super.key, required this.time});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
      ),
      child: Text(
        formatTime(time),
        style: Theme.of(context).textTheme.labelLarge?.apply(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
            ),
      ),
    );
  }
}
