import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta_uni_app/reusable_components/gallery/view/reusable_components/selected_assets_bloc.dart';
import 'package:photo_manager/photo_manager.dart';

class MediaGrid extends StatefulWidget {
  final AssetEntity asset;
  final Function tapCallback;
  final Function tapCancelCallback;
  final double? height;

  const MediaGrid({super.key, required this.asset, required this.tapCallback, required this.tapCancelCallback, this.height});

  @override
  State<MediaGrid> createState() => _MediaGridState();
}

class _MediaGridState extends State<MediaGrid> {
  bool isSelected = false;
  int order = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.asset.type == AssetType.image) {
      return GestureDetector(
        onTap: () {
          setState(() {
            if (isSelected) {
              widget.tapCancelCallback(widget.asset);
            } else {
              widget.tapCallback(widget.asset);
            }
          });
        },
        child: BlocConsumer<SelectedAssetsCubit, List<AssetEntity>>(
          listener: (context, list) {
            setState(() {
              isSelected = list.contains(widget.asset);
              if (isSelected) {
                order = list.indexOf(widget.asset) + 1;
              }
            });
          },
          builder: (context, state) {
            isSelected = state.contains(widget.asset);
            if (isSelected) {
              order = state.indexOf(widget.asset) + 1;
            }
            return Container(
              decoration: isSelected
                  ? BoxDecoration(
                      border: Border.all(color: Theme.of(context).colorScheme.primaryContainer, width: 2),
                    )
                  : null,
              child: Stack(
                children: [
                  widget.height != null
                      ? Image(
                          height: widget.height,
                          image: AssetEntityImageProvider(widget.asset),
                          fit: BoxFit.cover,
                        )
                      : Positioned.fill(
                          child: Image(
                            image: AssetEntityImageProvider(widget.asset),
                            fit: BoxFit.cover,
                          ),
                        ),
                  Positioned(
                    right: 5,
                    top: 5,
                    child: isSelected
                        ? Container(
                            height: 20,
                            width: 20,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white.withOpacity(0.75), width: 0.5),
                              color: Theme.of(context).colorScheme.primaryContainer,
                            ),
                            child: Center(
                              child: Text(
                                order.toString(),
                                style: Theme.of(context).textTheme.bodyMedium?.apply(color: Theme.of(context).colorScheme.onPrimaryContainer),
                              ),
                            ),
                          )
                        : Container(
                            height: 20,
                            width: 20,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white.withOpacity(0.75), width: 0.5),
                              color: Theme.of(context).colorScheme.outline.withOpacity(0.75),
                            ),
                          ),
                  ),
                  widget.asset.mimeType != null && widget.asset.mimeType!.contains("gif")
                      ? Positioned(
                          bottom: 5,
                          right: 5,
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                            ),
                            child: Text(
                              "GIF",
                              style: Theme.of(context).textTheme.labelLarge?.apply(
                                    color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                                  ),
                            ),
                          ),
                        )
                      : Container(),
                ],
              ),
            );
          },
        ),
      );
    } else if (widget.asset.type == AssetType.video) {
      return GestureDetector(
        onTap: () {
          setState(() {
            if (isSelected) {
              widget.tapCancelCallback(widget.asset);
            } else {
              widget.tapCallback(widget.asset);
            }
          });
        },
        child: BlocConsumer<SelectedAssetsCubit, List<AssetEntity>>(
          listener: (context, list) {
            setState(() {
              isSelected = list.contains(widget.asset);
              if (isSelected) {
                order = list.indexOf(widget.asset) + 1;
              }
            });
          },
          builder: (context, state) {
            isSelected = state.contains(widget.asset);
            if (isSelected) {
              order = state.indexOf(widget.asset) + 1;
            }

            return Container(
              decoration: isSelected
                  ? BoxDecoration(
                      border: Border.all(color: Theme.of(context).colorScheme.primaryContainer, width: 2),
                    )
                  : null,
              child: Stack(
                children: [
                  widget.height != null
                      ? Image(
                          height: widget.height,
                          image: AssetEntityImageProvider(widget.asset),
                          fit: BoxFit.cover,
                        )
                      : Positioned.fill(
                          child: Image(
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
                    right: 5,
                    top: 5,
                    child: isSelected
                        ? Container(
                            height: 20,
                            width: 20,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white.withOpacity(0.75), width: 0.5),
                              color: Theme.of(context).colorScheme.primaryContainer,
                            ),
                            child: Center(
                              child: Text(
                                order.toString(),
                                style: Theme.of(context).textTheme.bodyMedium?.apply(color: Theme.of(context).colorScheme.onPrimaryContainer),
                              ),
                            ),
                          )
                        : Container(
                            height: 20,
                            width: 20,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white.withOpacity(0.75), width: 0.5),
                              color: Theme.of(context).colorScheme.outline.withOpacity(0.75),
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    } else {
      return Container();
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
