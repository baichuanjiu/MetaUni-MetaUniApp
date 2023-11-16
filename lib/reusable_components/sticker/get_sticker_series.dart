import 'package:dio/dio.dart';
import 'package:meta_uni_app/models/dio_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../logout/logout.dart';
import '../snack_bar/network_error_snack_bar.dart';
import '../snack_bar/normal_snack_bar.dart';

class StickerSeries {
  late String id; //唯一标识
  late String preview; //预览图资源地址
  late String tittle; //表情包名称

  StickerSeries({
    required this.id,
    required this.preview,
    required this.tittle,
  });

  StickerSeries.fromJson(Map<String, dynamic> map) {
    id = map['id'];
    preview = map['preview'];
    tittle = map['tittle'];
  }
}

Future<List<StickerSeries>> getStickerSeries(BuildContext context) async {
  final DioModel dioModel = DioModel();

  final prefs = await SharedPreferences.getInstance();

  final String? jwt = prefs.getString('jwt');
  final int? uuid = prefs.getInt('uuid');

  try {
    Response response;
    response = await dioModel.dio.get(
      '/metaUni/messageAPI/sticker/series',
      options: Options(headers: {
        'JWT': jwt,
        'UUID': uuid,
      }),
    );
    switch (response.data['code']) {
      case 0:
        var dataList = response.data['data']['dataList'];
        List<StickerSeries> stickerSeries = [];
        for (var data in dataList) {
          stickerSeries.add(
            StickerSeries.fromJson(data),
          );
        }
        return stickerSeries;
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

  return [];
}
