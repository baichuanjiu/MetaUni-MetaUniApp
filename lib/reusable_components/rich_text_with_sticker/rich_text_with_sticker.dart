import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../sticker/sticker_manager.dart';

class RichTextWithSticker extends StatefulWidget {
  final String text;
  final TextStyle? textStyle;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool isSelectable;
  final Widget Function(BuildContext, EditableTextState)? contextMenuBuilder;

  const RichTextWithSticker({super.key, required this.text, this.textStyle, this.maxLines, this.overflow, this.isSelectable = false, this.contextMenuBuilder});

  @override
  State<RichTextWithSticker> createState() => _RichTextWithStickerState();
}

class _RichTextWithStickerState extends State<RichTextWithSticker> {
  late List<InlineSpan> spanList;

  @override
  Widget build(BuildContext context) {
    spanList = [];
    String stickerUrlPrefix = StickerManager().getStickerUrlPrefix();
    List<String> textList = widget.text.replaceAll("【<sticker>", "【<split/>】【<sticker/>】").replaceAll("</sticker>】", "【<split/>】").split("【<split/>】");
    for (var text in textList) {
      if (text.startsWith("【<sticker/>】")) {
        String key = text.replaceAll("【<sticker/>】", "");
        List<String> splits = key.split('_');
        String url = "$stickerUrlPrefix/${splits[0]}/$key.${splits[2]}";

        spanList.add(
          WidgetSpan(
            child: SizedBox(
              height: 36,
              width: 36,
              child: CachedNetworkImage(
                fadeInDuration: const Duration(milliseconds: 800),
                fadeOutDuration: const Duration(milliseconds: 200),
                placeholder: (context, url) => const CupertinoActivityIndicator(),
                imageUrl: url,
                imageBuilder: (context, imageProvider) => Image(image: imageProvider),
                errorWidget: (context, url, error) => const Icon(Icons.error_outline),
              ),
            ),
          ),
        );
      } else {
        spanList.add(
          TextSpan(
            text: text,
            style: widget.textStyle ?? Theme.of(context).textTheme.bodyLarge,
          ),
        );
      }
    }

    if (widget.isSelectable) {
      if (widget.contextMenuBuilder == null) {
        return SelectableText.rich(
          TextSpan(
            children: spanList,
          ),
          maxLines: widget.maxLines,
        );
      } else {
        return SelectableText.rich(
          TextSpan(
            children: spanList,
          ),
          maxLines: widget.maxLines,
          contextMenuBuilder: widget.contextMenuBuilder,
        );
      }
    } else {
      return RichText(
        text: TextSpan(
          children: spanList,
        ),
        maxLines: widget.maxLines,
        overflow: widget.overflow ?? TextOverflow.clip,
      );
    }
  }
}
