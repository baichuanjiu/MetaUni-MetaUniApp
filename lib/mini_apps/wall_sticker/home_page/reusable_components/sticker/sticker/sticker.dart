import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:meta_uni_app/reusable_components/formatter/date_time_formatter/date_time_formatter.dart';
import 'package:meta_uni_app/reusable_components/formatter/number_formatter/number_formatter.dart';
import 'package:meta_uni_app/reusable_components/rich_text_with_sticker/rich_text_with_sticker.dart';
import '../../media/grid/media_grids.dart';
import '../../tag/tags.dart';
import '../buttons/sticker_like_button.dart';
import '../details/sticker_details_page.dart';
import '../models/sticker_data.dart';

class Sticker extends StatefulWidget {
  final StickerData stickerData;
  final bool isInTimeLine;
  final bool shouldShowReplyTo;
  final bool disableTap;
  final bool disableCopyText;

  const Sticker({super.key, required this.stickerData, this.isInTimeLine = false, this.shouldShowReplyTo = true, this.disableTap = false, this.disableCopyText = true});

  @override
  State<Sticker> createState() => _StickerState();
}

class _StickerState extends State<Sticker> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: widget.disableTap
              ? null
              : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StickerDetailsPage(
                        id: widget.stickerData.id,
                      ),
                    ),
                  );
                },
          child: Padding(
            padding: EdgeInsets.fromLTRB(10, widget.isInTimeLine ? 3 : 10, 10, 0),
            child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(50, 0, 0, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 10,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    widget.shouldShowReplyTo && widget.stickerData.replyTo != null
                                        ? RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: "回复",
                                            style: Theme.of(context).textTheme.bodyMedium,
                                          ),
                                          TextSpan(
                                            text: " @${widget.stickerData.replyTo}",
                                            style: Theme.of(context).textTheme.bodyMedium?.apply(color: Theme.of(context).colorScheme.primary),
                                          ),
                                        ],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                        : Container(),
                                    Row(
                                      children: [
                                        Flexible(
                                          child: RichText(
                                            text: TextSpan(
                                              children: [
                                                TextSpan(
                                                  text: widget.stickerData.briefUserInfo.nickname,
                                                  style: Theme.of(context).textTheme.bodyLarge,
                                                ),
                                                TextSpan(
                                                  text: " @${widget.stickerData.isAnonymous ? "********" : widget.stickerData.briefUserInfo.uuid}",
                                                  style: Theme.of(context).textTheme.bodyMedium?.apply(color: Theme.of(context).colorScheme.outline),
                                                ),
                                              ],
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          " · ${getFormattedDateTime(dateTime: widget.stickerData.createdTime, shouldShowTime: true)}",
                                          style: Theme.of(context).textTheme.labelMedium?.apply(color: Theme.of(context).colorScheme.outline),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: widget.disableTap ? null : () {},
                                icon: Icon(
                                  Icons.more_horiz_outlined,
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                          RichTextWithSticker(
                            text: widget.stickerData.text,
                            isSelectable: !widget.disableCopyText,
                          ),
                          Container(
                            height: 5,
                          ),
                          Tags(tags: widget.stickerData.tags),
                          Container(
                            height: 5,
                          ),
                          MediaGrids(
                            dataList: widget.stickerData.medias,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              StickerLikeButton(id: widget.stickerData.id, isDeleted: widget.stickerData.isDeleted, isLiked: widget.stickerData.isLiked, likesNumber: widget.stickerData.likesNumber),
                              TextButton.icon(
                                onPressed: null,
                                icon: Icon(
                                  Icons.question_answer_outlined,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                                label: Text(
                                  getFormattedInt(widget.stickerData.repliesNumber),
                                  style: Theme.of(context).textTheme.labelSmall?.apply(
                                    color: Theme.of(context).colorScheme.outline,
                                  ),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: null,
                                icon: Icon(
                                  Icons.timeline_outlined,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                                label: Text(
                                  getFormattedDouble(widget.stickerData.trendValue),
                                  style: Theme.of(context).textTheme.labelSmall?.apply(
                                    color: Theme.of(context).colorScheme.outline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              widget.isInTimeLine
                  ? Positioned(
                top: 0,
                bottom: 0,
                left: 24,
                child: Container(
                  width: 2,
                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.25),
                ),
              )
                  : Container(),
              Avatar(widget.stickerData.briefUserInfo.avatar),
            ],
          ),
          ),
        ),
        widget.isInTimeLine ? Container() : const Divider(),
      ],
    );
  }
}

class Avatar extends StatelessWidget {
  final String avatar;

  const Avatar(this.avatar, {super.key});

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      fadeInDuration: const Duration(milliseconds: 800),
      fadeOutDuration: const Duration(milliseconds: 200),
      placeholder: (context, url) => CircleAvatar(
        radius: 25,
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: const CupertinoActivityIndicator(),
      ),
      imageUrl: avatar,
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: 25,
        backgroundImage: imageProvider,
      ),
      errorWidget: (context, url, error) => CircleAvatar(
        radius: 25,
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: const Icon(Icons.error_outline),
      ),
    );
  }
}
