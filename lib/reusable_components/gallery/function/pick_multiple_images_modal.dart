import 'package:flutter/material.dart';
import 'package:meta_uni_app/reusable_components/gallery/view/modal/gallery_modal.dart';
import 'package:photo_manager/photo_manager.dart';

Future<List<AssetEntity>> pickMultipleImagesModal({required BuildContext context, List<AssetEntity> selectedAssets = const [], int maxCount = 9}) async {
  final assets = await showModalBottomSheet<List<AssetEntity>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (BuildContext context) {
      return GalleryModal(
        type: RequestType.image,
        selectedAssets: selectedAssets,
        maxCount: maxCount,
      );
    },
  );

  return assets ?? [];
}
