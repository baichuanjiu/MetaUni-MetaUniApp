import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

getPermissionDeniedSnackBar(context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
      ),
      action: SnackBarAction(
        onPressed: () {
          openAppSettings();
        },
        label: '去授权',
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
    ),
  );
}
