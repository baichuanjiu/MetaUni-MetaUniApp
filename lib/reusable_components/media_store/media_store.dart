import 'dart:io';
import 'package:flutter/services.dart';

class MediaStore {
  static const _channel = MethodChannel('flutter_media_store');

  Future<void> addImage({required File file, required String name}) async {
    await _channel.invokeMethod('addImage', {'path': file.path, 'name': name});
  }
}