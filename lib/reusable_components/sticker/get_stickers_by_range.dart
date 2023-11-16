import 'package:dio/dio.dart';
import 'package:meta_uni_app/models/dio_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../logout/logout.dart';
import '../snack_bar/network_error_snack_bar.dart';
import '../snack_bar/normal_snack_bar.dart';

class Sticker {
  late String id; //唯一标识
  late String url; //资源地址
  late String tittle; //表情包名称
  late String text; //复制时显示的文本

  Sticker({
    required this.id,
    required this.url,
    required this.tittle,
    required this.text,
  });

  Sticker.fromJson(Map<String, dynamic> map) {
    id = map['id'];
    url = map['url'];
    tittle = map['tittle'];
    text = map['text'];
  }
}

Future<List<Sticker>> getStickersByRange(BuildContext context, String stickerSeriesId, int start, int count) async {
  final DioModel dioModel = DioModel();

  final prefs = await SharedPreferences.getInstance();

  final String? jwt = prefs.getString('jwt');
  final int? uuid = prefs.getInt('uuid');

  try {
    Response response;
    response = await dioModel.dio.get(
      '/metaUni/messageAPI/sticker/$stickerSeriesId/$start&$count',
      options: Options(headers: {
        'JWT': jwt,
        'UUID': uuid,
      }),
    );
    switch (response.data['code']) {
      case 0:
        var dataList = response.data['data']['dataList'];
        List<Sticker> stickers = [];
        for (var data in dataList) {
          stickers.add(
            Sticker.fromJson(data),
          );
        }
        return stickers;
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
