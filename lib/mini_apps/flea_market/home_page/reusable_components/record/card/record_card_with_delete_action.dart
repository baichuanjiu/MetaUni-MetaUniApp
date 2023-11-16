import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../details/record_details_page.dart';
import '../models/record_data.dart';

class RecordCardWithDeleteAction extends StatefulWidget {
  final BriefRecordData data;
  final Function onDelete;

  const RecordCardWithDeleteAction({super.key, required this.data, required this.onDelete});

  @override
  State<RecordCardWithDeleteAction> createState() => _RecordCardWithDeleteActionState();
}

class _RecordCardWithDeleteActionState extends State<RecordCardWithDeleteAction> with TickerProviderStateMixin {
  late AnimationController fadeOutAnimationController;
  late Animation<double> fadeOutAnimation;

  late AnimationController deleteAnimationController;
  late Animation<double> deleteAnimation;

  void deleteTile() {
    fadeOutAnimationController.forward().then((value) => {deleteAnimationController.forward()});
  }

  @override
  void initState() {
    super.initState();

    fadeOutAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    fadeOutAnimation = Tween(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: fadeOutAnimationController, curve: Curves.easeOut),
    );

    deleteAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    deleteAnimation = Tween(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: deleteAnimationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    fadeOutAnimationController.dispose();
    deleteAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    RichText header;
    if (widget.data.campus != null) {
      header = RichText(
        text: TextSpan(
          children: [
            WidgetSpan(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 5, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    child: Text(
                      widget.data.campus!,
                      style: Theme.of(context).textTheme.bodyLarge?.apply(
                            color: Theme.of(context).colorScheme.onSecondaryContainer,
                          ),
                    ),
                  ),
                ),
              ),
            ),
            TextSpan(
              text: widget.data.title,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    } else {
      header = RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: widget.data.title,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }

    List<Widget> tags = [];
    for (var tag in widget.data.tags) {
      tags.add(
        Text(
          tag,
          style: Theme.of(context).textTheme.labelMedium?.apply(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
      );
      tags.add(
        Text(
          " | ",
          style: Theme.of(context).textTheme.labelSmall?.apply(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
      );
    }
    if (tags.isNotEmpty) {
      tags.removeLast();
    }

    return SizeTransition(
      axis: Axis.vertical,
      sizeFactor: deleteAnimation,
      child: FadeTransition(
        opacity: fadeOutAnimation,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return RecordDetailsPage(id: widget.data.id);
                  },
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                widget.data.cover == null
                    ? Container()
                    : widget.data.cover!.type == "video"
                        ? AspectRatio(
                            aspectRatio: widget.data.cover!.aspectRatio,
                            child: CachedNetworkImage(
                              fadeInDuration: const Duration(milliseconds: 800),
                              fadeOutDuration: const Duration(milliseconds: 200),
                              placeholder: (context, url) => const CupertinoActivityIndicator(),
                              imageUrl: widget.data.cover!.previewImage!,
                              imageBuilder: (context, imageProvider) => ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: Image(
                                        image: imageProvider,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      left: 10,
                                      bottom: 10,
                                      child: Container(
                                        padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(5),
                                          color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                                        ),
                                        child: Text(
                                          formatTime(widget.data.cover!.timeTotal!),
                                          style: Theme.of(context).textTheme.labelLarge?.apply(
                                                color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                                              ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              errorWidget: (context, url, error) => const Icon(Icons.error_outline),
                            ),
                          )
                        : AspectRatio(
                            aspectRatio: widget.data.cover!.aspectRatio,
                            child: CachedNetworkImage(
                              fadeInDuration: const Duration(milliseconds: 800),
                              fadeOutDuration: const Duration(milliseconds: 200),
                              placeholder: (context, url) => const CupertinoActivityIndicator(),
                              imageUrl: widget.data.cover!.url,
                              imageBuilder: (context, imageProvider) => ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image(
                                  image: imageProvider,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              errorWidget: (context, url, error) => const Icon(Icons.error_outline),
                            ),
                          ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(2, 6, 2, 2),
                  child: header,
                ),
                widget.data.tags.isEmpty
                    ? Container()
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(2, 2, 2, 2),
                        child: Wrap(
                          children: tags,
                        ),
                      ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(2, 2, 2, 2),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "成交价格：",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        TextSpan(
                          text: "￥${widget.data.price.toStringAsFixed(2)}",
                          style: Theme.of(context).textTheme.bodyMedium?.apply(
                                color: Colors.orange,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(2, 2, 2, 2),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "备注：",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        TextSpan(
                          text: widget.data.remark,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FilledButton.tonal(
                      onPressed: () async {
                        if (await widget.onDelete(widget.data.id)) {
                          deleteTile();
                        }
                      },
                      child: const Text("删除"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
