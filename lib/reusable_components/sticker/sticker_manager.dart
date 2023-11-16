//单例模式构建StickerManager
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:meta_uni_app/models/dio_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../logout/logout.dart';
import '../snack_bar/network_error_snack_bar.dart';
import '../snack_bar/normal_snack_bar.dart';

class StickerManager {
  static final StickerManager _instance = StickerManager._();

  StickerManager._();

  factory StickerManager() {
    return _instance;
  }

  Future<String> _getStickerUrlPrefix(BuildContext context) async {
    final DioModel dioModel = DioModel();

    final prefs = await SharedPreferences.getInstance();

    final String? jwt = prefs.getString('jwt');
    final int? uuid = prefs.getInt('uuid');

    try {
      Response response;
      response = await dioModel.dio.get(
        '/metaUni/messageAPI/sticker/urlPrefix',
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 0:
          return response.data['data'];
      //break;
        case 1:
        //Message:"使用了无效的JWT，请重新登录"
          if (context.mounted) {
            getNormalSnackBar(context, response.data['message']);
            logout(context);
          }
          break;
        default:
          if (context.mounted) {
            getNetworkErrorSnackBar(context);
          }
      }
    } catch (e) {
      if (context.mounted) {
        getNetworkErrorSnackBar(context);
      }
    }

    return "";
  }

  static String _stickerUrlPrefix = "";

  setStickerUrlPrefix(BuildContext context) async{
    _stickerUrlPrefix = await _getStickerUrlPrefix(context);
  }

  String getStickerUrlPrefix() {
    return _stickerUrlPrefix;
  }
}
