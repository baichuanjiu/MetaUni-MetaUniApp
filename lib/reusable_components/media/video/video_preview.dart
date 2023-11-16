import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPreview extends StatefulWidget {
  final String previewImage;
  final double aspectRatio;
  final Duration timeTotal;
  final VideoPlayerController controller;
  final String heroTag;
  final Function jumpFunction;

  const VideoPreview({super.key, required this.previewImage, required this.aspectRatio, required this.timeTotal, required this.controller, required this.heroTag, required this.jumpFunction});

  @override
  State<VideoPreview> createState() => _VideoPreviewState();
}

//预览小窗 包括 进度、禁音、全屏 点一下切换暂停和播放
class _VideoPreviewState extends State<VideoPreview> {
  bool shouldPlay = false;

  late Duration timeLeft = widget.timeTotal;

  void setTimeLeft() {
    setState(() {
      timeLeft = widget.controller.value.duration - widget.controller.value.position;
    });
  }

  void updateState() {
    if (!shouldPlay && widget.controller.value.position.compareTo(const Duration()) > 0) {
      widget.controller.addListener(setTimeLeft);
      setState(() {
        shouldPlay = true;
        widget.controller.removeListener(updateState);
        return;
      });
    }
    if (shouldPlay) {
      widget.controller.removeListener(updateState);
      return;
    }
  }

  @override
  void initState() {
    super.initState();

    widget.controller.addListener(updateState);
  }

  @override
  void didUpdateWidget(covariant VideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.dispose();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(setTimeLeft);
    //等GC来清理这个
    //widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: shouldPlay
          ? GestureDetector(
              onTap: () {
                setState(() {
                  widget.controller.value.isPlaying ? widget.controller.pause() : widget.controller.play();
                });
              },
              child: Stack(
                children: [
                  Container(
                    color: Theme.of(context).colorScheme.shadow,
                    child: Center(
                      child: Hero(
                        tag: widget.heroTag,
                        child: AspectRatio(
                          aspectRatio: widget.controller.value.aspectRatio,
                          child: VideoPlayer(widget.controller),
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
                            if (widget.controller.value.volume != 0) {
                              setState(() {
                                widget.controller.setVolume(0);
                              });
                            } else {
                              setState(() {
                                widget.controller.setVolume(100);
                              });
                            }
                          },
                          child: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                            radius: 15,
                            child: Icon(
                              widget.controller.value.volume != 0 ? Icons.volume_up_outlined : Icons.volume_off_outlined,
                              color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
                              size: 20,
                            ),
                          ),
                        ),
                        Container(
                          width: 5,
                        ),
                        GestureDetector(
                          onTap: () {
                            widget.jumpFunction();
                          },
                          child: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                            radius: 15,
                            child: Icon(
                              Icons.fullscreen_outlined,
                              color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  widget.controller.value.isPlaying
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
                if (!widget.controller.value.isInitialized) {
                  widget.controller.initialize();
                }
                widget.controller.addListener(setTimeLeft);
                setState(() {
                  shouldPlay = true;
                  widget.controller.play();
                });
              },
              child: PreviewFrame(
                previewImage: widget.previewImage,
                timeTotal: widget.timeTotal,
              ),
            ),
    );
  }
}

String formatTime(Duration time) {
  if (time.inMinutes < 1) {
    return time.toString().substring(5, 7);
  } else if (time.inHours < 1) {
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

class PreviewFrame extends StatelessWidget {
  final String previewImage;
  final Duration timeTotal;

  const PreviewFrame({super.key, required this.previewImage, required this.timeTotal});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: CachedNetworkImage(
            fadeInDuration: const Duration(milliseconds: 800),
            fadeOutDuration: const Duration(milliseconds: 200),
            placeholder: (context, url) => const CupertinoActivityIndicator(),
            imageUrl: previewImage,
            imageBuilder: (context, imageProvider) => Image(
              image: imageProvider,
              fit: BoxFit.cover,
            ),
            errorWidget: (context, url, error) => const Icon(Icons.error_outline),
          ),
        ),
        Positioned(
          left: 15,
          bottom: 10,
          child: CountDown(
            timeLeft: timeTotal,
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
    );
  }
}
