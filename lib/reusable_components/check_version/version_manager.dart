//单例模式构建VersionManager
import 'package:dio/dio.dart';
import 'package:meta_uni_app/reusable_components/check_version/check_version.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/dio_model.dart';
import '../logout/logout.dart';
import '../snack_bar/network_error_snack_bar.dart';
import '../snack_bar/normal_snack_bar.dart';

class VersionManager {
  static final VersionManager _instance = VersionManager._();

  VersionManager._();

  factory VersionManager() {
    return _instance;
  }

  static String _appVersion = "";
  static bool _hasNewVersion = false;
  static String _latestVersion = "";
  static String _downloadUrl = "";

  initAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    _appVersion = packageInfo.version;
  }

  checkLatestVersion(context) async {
    DioModel dioModel = DioModel();

    final prefs = await SharedPreferences.getInstance();

    final String? jwt = prefs.getString('jwt');
    final int? uuid = prefs.getInt('uuid');

    try {
      Response response;
      response = await dioModel.dio.get(
        '/metaUni/versionAPI/version/latest',
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 0:
          _latestVersion = response.data['data']['version'];
          _downloadUrl = response.data['data']['downloadUrl'];
          _hasNewVersion = !checkVersion(_latestVersion);
          break;
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
  }

  getAppVersion() {
    return _appVersion;
  }

  checkHasNewVersion() {
    return _hasNewVersion;
  }

  getLatestVersion() {
    return _latestVersion;
  }

  getDownloadUrl() {
    return _downloadUrl;
  }
}
