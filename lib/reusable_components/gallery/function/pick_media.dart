import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../view/page/gallery_page.dart';

Future<AssetEntity?> pickMedia({required BuildContext context}) async {
  final assets = await Navigator.push<List<AssetEntity>>(
    context,
    MaterialPageRoute(builder: (context) {
      return const GalleryPage(
        maxCount: 1,
      );
    }),
  );

  if (assets == null || assets.isEmpty) {
    return null;
  } else {
    return assets.first;
  }
}
