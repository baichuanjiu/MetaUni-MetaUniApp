import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

class ViewVideoPage extends StatefulWidget {
  final VideoPlayerController controller;
  final String heroTag;
  final bool shouldShowMenu;
  final Function changeOpacity;

  const ViewVideoPage({super.key, required this.controller, required this.heroTag, required this.shouldShowMenu, required this.changeOpacity});

  @override
  State<ViewVideoPage> createState() => _ViewVideoPageState();
}

class _ViewVideoPageState extends State<ViewVideoPage> with TickerProviderStateMixin {
  late bool shouldShowTimeCurrent = false;
  late bool shouldShowVolumeSlider = false;
  late bool shouldShowVolumeCurrent = false;

  late Duration timeTotal = widget.controller.value.duration;
  late Duration timeCurrent = widget.controller.value.position;
  late double volumeCurrent = widget.controller.value.volume;
  late double volumeLast = volumeCurrent;

  late AnimationController playOrPauseAnimationController;
  late Animation<double> playOrPauseAnimation;

  void timeCurrentListener() {
    if (currentIconState != widget.controller.value.isPlaying) {
      playOrPauseAnimationController.isCompleted ? playOrPauseAnimationController.reverse() : playOrPauseAnimationController.forward();
      currentIconState = !currentIconState;
    }

    setState(() {
      timeCurrent = widget.controller.value.position;
    });
  }

  //true时为暂停标志，点击后暂停，播放状态
  //false时播放标志，点击后播放，暂停状态
  late bool currentIconState;

  //开始滑动进度条时视频是否正在播放
  late bool isPlayingWhenSlideStart;

  @override
  void initState() {
    super.initState();

    if (!widget.controller.value.isInitialized) {
      widget.controller.initialize().then((value) {
        setState(() {
          timeTotal = widget.controller.value.duration;
        });
      });
    }
    widget.controller.addListener(timeCurrentListener);
    playOrPauseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    if (widget.controller.value.isPlaying) {
      currentIconState = true;
      playOrPauseAnimation = Tween(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: playOrPauseAnimationController, curve: Curves.ease),
      );
    } else {
      currentIconState = false;
      playOrPauseAnimation = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: playOrPauseAnimationController, curve: Curves.ease),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    widget.controller.removeListener(timeCurrentListener);
    super.dispose();
  }

  Offset dragStart = const Offset(0, 0);
  Offset dragDelta = const Offset(0, 0);

  @override
  Widget build(BuildContext context) {
    if (!widget.shouldShowMenu) {
      shouldShowVolumeSlider = false;
    }
    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        children: [
          Positioned(
            left: dragDelta.dx == 0
                ? null
                : dragDelta.dx.isNegative
                    ? null
                    : dragDelta.dx,
            top: dragDelta.dy == 0
                ? null
                : dragDelta.dy.isNegative
                    ? null
                    : dragDelta.dy,
            right: dragDelta.dx == 0
                ? null
                : dragDelta.dx.isNegative
                    ? -dragDelta.dx
                    : null,
            bottom: dragDelta.dy == 0
                ? null
                : dragDelta.dy.isNegative
                    ? -dragDelta.dy
                    : null,
            height: constraints.maxHeight,
            width: constraints.maxWidth,
            child: SafeArea(
              child: Center(
                child: GestureDetector(
                  onVerticalDragStart: (details) {
                    dragStart = details.localPosition;
                  },
                  onVerticalDragUpdate: (details) {
                    setState(() {
                      dragDelta = details.localPosition - dragStart;
                      widget.changeOpacity((0.5 - dragDelta.distanceSquared / 15000).isNegative ? 0.5 : (1.0 - dragDelta.distanceSquared / 15000));
                    });
                  },
                  onVerticalDragEnd: (details) {
                    if (dragDelta.distanceSquared >= 15000 || details.velocity.pixelsPerSecond.dy.abs() >= 100) {
                      Navigator.maybePop(context);
                    } else {
                      widget.changeOpacity(1.0);
                      setState(() {
                        dragDelta = const Offset(0, 0);
                      });
                    }
                  },
                  child: Hero(
                    tag: widget.heroTag,
                    child: AspectRatio(
                      aspectRatio: widget.controller.value.aspectRatio,
                      child: VideoPlayer(widget.controller),
                    ),
                  ),
                ),
              ),
            ),
          ),
          widget.shouldShowMenu && shouldShowTimeCurrent
              ? SafeArea(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                      ),
                      child: Text(
                        formatTime(timeCurrent),
                        style: Theme.of(context).textTheme.titleLarge?.apply(
                              color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                            ),
                      ),
                    ),
                  ),
                )
              : Container(),
          widget.shouldShowMenu && shouldShowVolumeCurrent
              ? SafeArea(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            volumeCurrent != 0 ? Icons.volume_up_outlined : Icons.volume_off_outlined,
                            color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
                            size: 24,
                          ),
                          const SizedBox(
                            height: 0,
                            width: 2,
                          ),
                          Text(
                            (volumeCurrent * 100).toInt().toString(),
                            style: Theme.of(context).textTheme.titleLarge?.apply(
                                  color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : Container(),
          widget.shouldShowMenu
              ? Positioned(
                  top: 5,
                  left: 10,
                  child: SafeArea(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.maybePop(context);
                      },
                      child: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                        radius: 15,
                        child: Icon(
                          Icons.arrow_back_ios_outlined,
                          color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                )
              : Container(),
          widget.shouldShowMenu
              ? Positioned(
                  bottom: 0,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.fromLTRB(15, 0, 15, 5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  VideoTimer(timeCurrent: timeCurrent, timeTotal: timeTotal),
                                ],
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Column(
                                    children: [
                                      shouldShowVolumeSlider
                                          ? Container(
                                              constraints: const BoxConstraints(
                                                maxHeight: 150,
                                              ),
                                              width: 30,
                                              child: RotatedBox(
                                                quarterTurns: -1,
                                                child: Slider(
                                                  onChangeStart: (newValue) {
                                                    setState(() {
                                                      shouldShowVolumeCurrent = true;
                                                    });
                                                  },
                                                  onChanged: (newValue) {
                                                    setState(() {
                                                      widget.controller.setVolume(newValue);
                                                      volumeCurrent = newValue;
                                                    });
                                                  },
                                                  onChangeEnd: (newValue) {
                                                    setState(() {
                                                      shouldShowVolumeSlider = false;
                                                    });
                                                    Future.delayed(const Duration(seconds: 1)).then((_) {
                                                      setState(() {
                                                        shouldShowVolumeCurrent = false;
                                                      });
                                                    });
                                                  },
                                                  value: volumeCurrent,
                                                  activeColor: Colors.white.withOpacity(0.7),
                                                  inactiveColor: Theme.of(context).colorScheme.outline.withOpacity(0.7),
                                                ),
                                              ),
                                            )
                                          : Container(),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            shouldShowVolumeSlider = !shouldShowVolumeSlider;
                                          });
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
                                    ],
                                  ),
                                  Container(
                                    width: 5,
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      if (MediaQuery.of(context).orientation == Orientation.portrait) {
                                        SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft]);
                                      } else {
                                        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
                                      }
                                    },
                                    child: CircleAvatar(
                                      backgroundColor: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                                      radius: 15,
                                      child: Icon(
                                        Icons.screen_rotation_outlined,
                                        color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                          child: Row(
                            children: [
                              InkWell(
                                onTap: () {
                                  widget.controller.value.isPlaying ? widget.controller.pause() : widget.controller.play();
                                },
                                child: AnimatedIcon(icon: AnimatedIcons.play_pause, color: Colors.white.withOpacity(0.7), size: 36, progress: playOrPauseAnimation),
                              ),
                              Expanded(
                                child: Slider(
                                  onChangeStart: (newValue) {
                                    if (widget.controller.value.isPlaying) {
                                      isPlayingWhenSlideStart = true;
                                      widget.controller.pause();
                                    } else {
                                      isPlayingWhenSlideStart = false;
                                    }
                                    setState(() {
                                      shouldShowTimeCurrent = true;
                                    });
                                  },
                                  onChanged: (newValue) {
                                    setState(() {
                                      timeCurrent = Duration(microseconds: (newValue * timeTotal.inMicroseconds).toInt());
                                      widget.controller.seekTo(timeCurrent);
                                    });
                                  },
                                  onChangeEnd: (newValue) {
                                    if (isPlayingWhenSlideStart && !widget.controller.value.isPlaying && (timeCurrent.compareTo(timeTotal) != 0)) {
                                      widget.controller.play();
                                    }
                                    setState(() {
                                      shouldShowTimeCurrent = false;
                                    });
                                  },
                                  value: widget.controller.value.isInitialized ? timeCurrent.inMicroseconds / timeTotal.inMicroseconds : 0,
                                  activeColor: Colors.white.withOpacity(0.7),
                                  inactiveColor: Theme.of(context).colorScheme.outline.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Container(),
        ],
      ),
    );
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

class VideoTimer extends StatelessWidget {
  final Duration timeCurrent;
  final Duration timeTotal;

  const VideoTimer({super.key, required this.timeCurrent, required this.timeTotal});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
      ),
      child: Text(
        "${formatTime(timeCurrent)} / ${formatTime(timeTotal)}",
        style: Theme.of(context).textTheme.labelLarge?.apply(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
            ),
      ),
    );
  }
}
