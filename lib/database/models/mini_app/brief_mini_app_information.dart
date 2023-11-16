import 'package:sqflite/sqflite.dart';

class BriefMiniAppInformation{
  late String id;
  late String type;
  late String name;
  late String avatar;
  late String? routingURL;
  late String? url;
  late String? minimumSupportVersion;
  late DateTime lastOpenedTime;

  BriefMiniAppInformation({required this.id,required this.type,required this.name,required this.avatar,this.routingURL,this.url,this.minimumSupportVersion,required this.lastOpenedTime});

  BriefMiniAppInformation.fromJson(Map<String, dynamic> map) {
    id = map['_id'];
    type = map['type'];
    name = map['name'];
    avatar = map['avatar'];
    routingURL = map['routingURL'];
    url = map['url'];
    minimumSupportVersion = map['minimumSupportVersion'];
    lastOpenedTime = DateTime.now();
  }

  Map<String, dynamic> toSql() {
    return {
      'id' : id,
      'type': type,
      'name': name,
      'avatar': avatar,
      'routingURL': routingURL,
      'url': url,
      'minimumSupportVersion':minimumSupportVersion,
      'lastOpenedTime': lastOpenedTime.millisecondsSinceEpoch,
    };
  }

  Map<String, dynamic> toUpdateSql() {
    return {
      'type': type,
      'name': name,
      'avatar': avatar,
      'routingURL': routingURL,
      'url': url,
      'minimumSupportVersion':minimumSupportVersion,
      'lastOpenedTime': lastOpenedTime.millisecondsSinceEpoch,
    };
  }

  BriefMiniAppInformation.fromSql(Map<String, dynamic> map) {
    id = map['id'];
    type = map['type'];
    name = map['name'];
    avatar = map['avatar'];
    routingURL = map['routingURL'];
    url = map['url'];
    minimumSupportVersion = map['minimumSupportVersion'];
    lastOpenedTime = DateTime.fromMillisecondsSinceEpoch(map['lastOpenedTime']);
  }
}

class BriefMiniAppInformationProvider {
  late Database database;

  BriefMiniAppInformationProvider(this.database);

  Future<bool> insert(BriefMiniAppInformation briefMiniAppInformation) async {
    await database.insert('briefMiniAppInformation', briefMiniAppInformation.toSql());
    return true;
  }

  Future<bool> update(Map<String, dynamic> values, String id) async {
    await database.update('briefMiniAppInformation', values, where: "id=?", whereArgs: [id]);
    return true;
  }

  Future<bool> delete(String id) async {
    await database.delete('briefMiniAppInformation',where: "id=?", whereArgs: [id]);
    return true;
  }

  Future<BriefMiniAppInformation?> get(String id) async {
    List<Map<String, dynamic>> maps = await database.query('briefMiniAppInformation', where: "id=?", whereArgs: [id]);
    if (maps.isNotEmpty) {
      return BriefMiniAppInformation.fromSql(maps.first);
    }
    return null;
  }

  Future<List<BriefMiniAppInformation>> getRecentlyOpenedList() async {
    List<BriefMiniAppInformation> results = [];
    List<Map<String, dynamic>> maps = await database.query('briefMiniAppInformation',orderBy: 'lastOpenedTime DESC',limit: 8);
    if (maps.isNotEmpty) {
      for (var element in maps) {
        results.add(BriefMiniAppInformation.fromSql(element));
      }
    }
    return results;
  }

  Future<String?> getURL(String id) async {
    List<Map<String, dynamic>> maps = await database.query('briefMiniAppInformation',columns: ['url'], where: "id=?", whereArgs: [id]);
    if (maps.isNotEmpty) {
      String? url = maps.first['url'];
      return url;
    }
    return null;
  }
}