import 'package:flutter/material.dart';
import 'package:meta_uni_app/reusable_components/gallery/view/modal/gallery_modal.dart';
import 'package:photo_manager/photo_manager.dart';

Future<AssetEntity?> pickVideoModal({required BuildContext context}) async {
  final assets = await showModalBottomSheet<List<AssetEntity>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (BuildContext context) {
      return const GalleryModal(
        type: RequestType.video,
        maxCount: 1,
      );
    },
  );

  if (assets == null || assets.isEmpty) {
    return null;
  } else {
    return assets.first;
  }
}
