import 'package:flutter/material.dart';

getNetworkErrorSnackBar(context){
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              '网络连接失败，请检查您的网络，或稍后再试',
              maxLines: null,
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 1500),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
    ),
  );
}