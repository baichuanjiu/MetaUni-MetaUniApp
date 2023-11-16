import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:meta_uni_app/reusable_components/special_text/sticker_text/sticker_text.dart';

class CustomTextSpanBuilder extends SpecialTextSpanBuilder {
  final String stickerUrlPrefix;

  CustomTextSpanBuilder({this.stickerUrlPrefix = ""});

  @override
  SpecialText? createSpecialText(String flag, {TextStyle? textStyle, SpecialTextGestureTapCallback? onTap, required int index}) {
    if (flag == "") return null;

    if (isStart(flag, StickerText.flag)) {
      return StickerText(
        start: index - (StickerText.flag.length - 1),
        stickerUrlPrefix: stickerUrlPrefix,
      );
    }
    return null;
  }
}