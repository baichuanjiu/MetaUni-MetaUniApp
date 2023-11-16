import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../view/page/gallery_page.dart';

Future<List<AssetEntity>> pickMultipleMedias({required BuildContext context, List<AssetEntity> selectedAssets = const [], int maxCount = 9}) async {
  final assets = await Navigator.push<List<AssetEntity>>(
    context,
    MaterialPageRoute(builder: (context) {
      return GalleryPage(
        selectedAssets: selectedAssets,
        maxCount: maxCount,
      );
    }),
  );

  return assets ?? [];
}