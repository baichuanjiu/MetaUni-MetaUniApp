import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

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

class CountDown extends StatelessWidget {
  final Duration timeLeft;

  const CountDown({super.key, required this.timeLeft});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
      ),
      child: Text(
        formatTime(timeLeft),
        style: Theme.of(context).textTheme.labelLarge?.apply(
          color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
        ),
      ),
    );
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

class MediaPreview extends StatefulWidget {
  final File file;
  final bool isVideo;
  final Function remove;

  const MediaPreview({super.key, required this.file, this.isVideo = false, required this.remove});

  @override
  State<MediaPreview> createState() => _MediaPreviewState();
}

class _MediaPreviewState extends State<MediaPreview> {
  late bool shouldPlay = false;

  late Duration timeLeft = controller.value.duration;
  late VideoPlayerController controller = VideoPlayerController.file(
    widget.file,
  )..initialize().then((_) {
    setState(() {});
  });

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isVideo) {
      return Container(
        margin: const EdgeInsets.fromLTRB(0, 0, 5, 0),
        child: AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: Center(
            child: shouldPlay
                ? GestureDetector(
              onTap: () {
                setState(() {
                  controller.value.isPlaying ? controller.pause() : controller.play();
                });
              },
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      color: Theme.of(context).colorScheme.shadow,
                      child: VideoPlayer(controller),
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
                  Positioned(
                    left: 15,
                    bottom: 10,
                    child: CountDown(
                      timeLeft: timeLeft,
                    ),
                  ),
                  Positioned(
                    right: 15,
                    bottom: 10,
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (controller.value.volume != 0) {
                              setState(() {
                                controller.setVolume(0);
                              });
                            } else {
                              setState(() {
                                controller.setVolume(100);
                              });
                            }
                          },
                          child: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                            radius: 15,
                            child: Icon(
                              controller.value.volume != 0 ? Icons.volume_up_outlined : Icons.volume_off_outlined,
                              color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  controller.value.isPlaying
                      ? Container()
                      : Center(
                    child: Icon(
                      Icons.play_circle_outlined,
                      color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
                      size: 48,
                    ),
                  ),
                ],
              ),
            )
                : GestureDetector(
              onTap: () {
                controller.addListener(() {
                  setState(() {
                    timeLeft = controller.value.duration - controller.value.position;
                  });
                });
                setState(() {
                  shouldPlay = true;
                  controller.play();
                });
              },
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      color: Theme.of(context).colorScheme.shadow,
                      child: VideoPlayer(controller),
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
                  Positioned(
                    left: 15,
                    bottom: 10,
                    child: CountDown(
                      timeLeft: controller.value.duration,
                    ),
                  ),
                  Center(
                    child: Icon(
                      Icons.live_tv_outlined,
                      color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
                      size: 48,
                    ),
                  ),
                ],
              ),
            ),
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
                child: Image.file(
                  widget.file,
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