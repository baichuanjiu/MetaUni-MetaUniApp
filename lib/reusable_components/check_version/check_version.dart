import 'package:meta_uni_app/reusable_components/check_version/version_manager.dart';

bool checkVersion(String minimumSupportVersion){
  //版本号格式示例：1.0.0
  List<String> minimumSupportVersionNumbers = minimumSupportVersion.split('.');

  String appVersion = VersionManager().getAppVersion();
  List<String> appVersionNumbers = appVersion.split('.');
  if (int.parse(minimumSupportVersionNumbers[0]) > int.parse(appVersionNumbers[0])) {
    return false;
  } else if (int.parse(minimumSupportVersionNumbers[0]) < int.parse(appVersionNumbers[0])) {
    return true;
  } else {
    if (int.parse(minimumSupportVersionNumbers[1]) > int.parse(appVersionNumbers[1])) {
      return false;
    } else if (int.parse(minimumSupportVersionNumbers[1]) < int.parse(appVersionNumbers[1])) {
      return true;
    } else {
      if (int.parse(minimumSupportVersionNumbers[2]) > int.parse(appVersionNumbers[2])) {
        return false;
      } else {
        return true;
      }
    }
  }
}