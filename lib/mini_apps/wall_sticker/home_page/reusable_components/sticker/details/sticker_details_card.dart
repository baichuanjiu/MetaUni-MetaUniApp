import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:meta_uni_app/reusable_components/formatter/date_time_formatter/date_time_formatter.dart';
import 'package:meta_uni_app/reusable_components/formatter/number_formatter/number_formatter.dart';
import 'package:meta_uni_app/reusable_components/rich_text_with_sticker/rich_text_with_sticker.dart';
import '../../media/grid/media_grids.dart';
import '../../tag/tags.dart';
import '../buttons/sticker_like_button.dart';
import '../models/sticker_data.dart';

class StickerDetailsCard extends StatefulWidget {
  final StickerData stickerData;

  const StickerDetailsCard({super.key, required this.stickerData});

  @override
  State<StickerDetailsCard> createState() => _StickerDetailsCardState();
}

class _StickerDetailsCardState extends State<StickerDetailsCard> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(10, widget.stickerData.replyTo != null ? 0 : 10, 10, 0),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(0, 0, 0, 10),
                child: Row(
                  children: [
                    Column(
                      children: [
                        widget.stickerData.replyTo != null
                            ? Container(
                                height: 10,
                                width: 2,
                                color: Theme.of(context).colorScheme.secondary.withOpacity(0.25),
                              )
                            : Container(),
                        Avatar(widget.stickerData.briefUserInfo.avatar),
                      ],
                    ),
                    Container(
                      width: 10,
                    ),
                    Expanded(
                      child: Container(
                        margin: widget.stickerData.replyTo != null ? const EdgeInsets.fromLTRB(0, 10, 0, 0) : null,
                        child: Row(
                          children: [
                            Expanded(
                              child: widget.stickerData.replyTo != null
                                  ? Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        RichText(
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
                                        ),
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
                                          ],
                                        ),
                                      ],
                                    )
                                  : Container(
                                      margin: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  widget.stickerData.briefUserInfo.nickname,
                                                  style: Theme.of(context).textTheme.bodyLarge,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  "@${widget.stickerData.isAnonymous ? "********" : widget.stickerData.briefUserInfo.uuid}",
                                                  style: Theme.of(context).textTheme.bodyMedium?.apply(color: Theme.of(context).colorScheme.outline),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                            IconButton(
                              onPressed: () {},
                              icon: Icon(
                                Icons.more_horiz_outlined,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(5, 0, 5, 5),
                    child: RichTextWithSticker(
                      text: widget.stickerData.text,
                      isSelectable: true,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(5, 0, 5, 5),
                    child: Tags(tags: widget.stickerData.tags),
                  ),
                  MediaGrids(
                    dataList: widget.stickerData.medias,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                          child: Text(
                            getFormattedDateTime(dateTime: widget.stickerData.createdTime, shouldShowTime: true),
                            style: Theme.of(context).textTheme.labelMedium?.apply(color: Theme.of(context).colorScheme.outline),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      Row(
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
                ],
              ),
            ],
          ),
        ),
        const Divider(),
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
