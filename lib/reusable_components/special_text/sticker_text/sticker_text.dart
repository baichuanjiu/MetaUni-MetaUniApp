import 'package:cached_network_image/cached_network_image.dart';
import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// 你需要 startFlag 和 endFlag 复杂到用户在一般情况下无法进行手动输入
// 你需要解析出 url 用于加载图片

// 【<sticker>ac_受不了了_png</sticker>】
// 当检测到文本框内出现格式如 【<sticker>表情名</sticker>】 的文字段时
// 检测到 startFlag 【<sticker>
// 检测到 endFlag </sticker>】
// 检测到 表情名
// 表情名采用统一格式 系列名_标题_后缀
// 从表情名中解析出系列名和后缀，拼接出 url
// url采用统一格式 "http://IP:Port/sticker/系列名/表情名.后缀"

class StickerText extends SpecialText {
  static const String flag = "【<sticker>";
  final int start;
  final String stickerUrlPrefix;

  StickerText({required this.start, required this.stickerUrlPrefix})
      : super(
          flag,
          "</sticker>】",
          null,
        );

  @override
  InlineSpan finishText() {
    final String key = getContent();
    final List<String> splits = key.split('_');
    final url = "$stickerUrlPrefix/${splits[0]}/$key.${splits[2]}";

    return ExtendedWidgetSpan(
      actualText: toString(),
      start: start,
      alignment: PlaceholderAlignment.bottom,
      deleteAll: true,
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
    );
  }
}
