import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:meta_uni_app/mini_apps/mini_app_manager.dart';
import 'package:meta_uni_app/models/dio_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../../bloc/bloc_manager.dart';
import '../../database/database_manager.dart';
import '../../database/models/mini_app/brief_mini_app_information.dart';
import '../check_version/check_version.dart';
import '../logout/logout.dart';
import '../snack_bar/network_error_snack_bar.dart';
import '../snack_bar/normal_snack_bar.dart';
import '../web_view/web_view_page.dart';

openClientApp(String id, String routingURL, String minimumSupportVersion, BuildContext context) async {
  if (context.mounted) {
    if (checkVersion(minimumSupportVersion)) {
      MiniAppManager().setCurrentMiniAppId(id);
      if (context.mounted) {
        Navigator.pushNamed(
          context,
          routingURL,
        );
      }
    } else {
      if (context.mounted) {
        getNormalSnackBar(context, "不符合最低版本要求，更新以使用该功能");
      }
    }
    if (context.mounted) {
      updateInformation(id, context);
    }
  }
}

openWebApp(String id, String url, String name, BuildContext context) async {
  MiniAppManager().setCurrentMiniAppId(id);
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => WebViewPage(
        title: name,
        url: url,
      ),
    ),
  );
  updateInformation(id, context);
}

updateInformation(String id, BuildContext context) async {
  Database database = await DatabaseManager().getDatabase;
  BriefMiniAppInformationProvider briefMiniAppInformationProvider = BriefMiniAppInformationProvider(database);

  DioModel dioModel = DioModel();

  final prefs = await SharedPreferences.getInstance();

  final String? jwt = prefs.getString('jwt');
  final int? uuid = prefs.getInt('uuid');

  BriefMiniAppInformation? info;

  try {
    Response response;
    response = await dioModel.dio.get(
      '/metaUni/miniAppAPI/miniApp/open/$id',
      options: Options(headers: {
        'JWT': jwt,
        'UUID': uuid,
      }),
    );
    switch (response.data['code']) {
      case 0:
        info = BriefMiniAppInformation.fromJson(response.data['data']);

        if ((await briefMiniAppInformationProvider.get(id)) == null) {
          briefMiniAppInformationProvider.insert(info);
        } else {
          briefMiniAppInformationProvider.update(info.toUpdateSql(), id);
        }
        notifyViewToUpdate(id);
        break;
      case 1:
        //Message:"使用了无效的JWT，请重新登录"
        if (context.mounted) {
          getNormalSnackBar(context, response.data['message']);
          logout(context);
        }
        break;
      case 2:
        //Message:"您正在尝试打开不存在的MiniApp"
        if (context.mounted) {
          getNormalSnackBar(context, response.data['message']);
          await briefMiniAppInformationProvider.delete(id);
          notifyViewToUpdate(id);
        }
        break;
      default:
        if (context.mounted) {
          briefMiniAppInformationProvider.update({
            'lastOpenedTime': DateTime.now().millisecondsSinceEpoch,
          }, id);
          notifyViewToUpdate(id);
          getNetworkErrorSnackBar(context);
        }
    }
  } catch (e) {
    if (context.mounted) {
      briefMiniAppInformationProvider.update({
        'lastOpenedTime': DateTime.now().millisecondsSinceEpoch,
      }, id);
      notifyViewToUpdate(id);
      getNetworkErrorSnackBar(context);
    }
  }
}

notifyViewToUpdate(String id) async {
  Database database = await DatabaseManager().getDatabase;
  BriefMiniAppInformationProvider briefMiniAppInformationProvider = BriefMiniAppInformationProvider(database);

  BlocManager blocManager = BlocManager();
  BriefMiniAppInformation? info = await briefMiniAppInformationProvider.get(id);
  blocManager.recentlyUsedMiniAppsCubit.shouldUpdate(info);
}
