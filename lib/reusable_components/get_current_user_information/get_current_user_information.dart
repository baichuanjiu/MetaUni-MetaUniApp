import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../../database/database_manager.dart';
import '../../database/models/user/brief_user_information.dart';

Future<BriefUserInformation> getCurrentUserInformation() async {
  final prefs = await SharedPreferences.getInstance();

  int uuid = prefs.getInt('uuid')!;

  Database database = await DatabaseManager().getDatabase;

  BriefUserInformationProvider briefUserInformationProvider = BriefUserInformationProvider(database);
  BriefUserInformation user = (await briefUserInformationProvider.get(uuid))!;

  return user;
}
