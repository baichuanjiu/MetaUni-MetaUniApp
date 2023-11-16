//单例模式构建MiniAppManager
import 'package:sqflite/sqflite.dart';

import '../database/database_manager.dart';
import '../database/models/mini_app/brief_mini_app_information.dart';

class MiniAppManager {
  static final MiniAppManager _instance = MiniAppManager._();

  MiniAppManager._();

  factory MiniAppManager() {
    return _instance;
  }

  static String _currentMiniAppId = "";

  setCurrentMiniAppId(String id) {
    _currentMiniAppId = id;
  }

  getCurrentMiniAppId() {
    return _currentMiniAppId;
  }

  Future<String?> getCurrentMiniAppUrl() async {
    Database database = await DatabaseManager().getDatabase;
    BriefMiniAppInformationProvider briefMiniAppInformationProvider = BriefMiniAppInformationProvider(database);

    return await briefMiniAppInformationProvider.getURL(_currentMiniAppId);
  }
}
