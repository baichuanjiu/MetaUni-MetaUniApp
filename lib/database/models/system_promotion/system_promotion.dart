import 'package:sqflite/sqflite.dart';

class SystemPromotion {
  late int uuid;
  late String avatar;
  late String name;
  late String? miniAppId;
  late DateTime updatedTime;

  SystemPromotion({required this.uuid, required this.avatar, required this.name,this.miniAppId,required this.updatedTime});

  SystemPromotion.fromJson(Map<String, dynamic> map) {
    uuid = map['uuid'];
    avatar = map['avatar'];
    name = map['name'];
    miniAppId = map['miniAppId'];
    updatedTime = DateTime.parse(map['updatedTime']);
  }

  Map<String, dynamic> toSql() {
    return {
      'uuid': uuid,
      'avatar': avatar,
      'name': name,
      'miniAppId': miniAppId,
      'updatedTime': updatedTime.millisecondsSinceEpoch,
    };
  }

  Map<String, dynamic> toUpdateSql() {
    return {
      'avatar': avatar,
      'name': name,
      'miniAppId': miniAppId,
      'updatedTime': updatedTime.millisecondsSinceEpoch,
    };
  }

  SystemPromotion.fromSql(Map<String, dynamic> map) {
    uuid = map['uuid'];
    avatar = map['avatar'];
    name = map['name'];
    miniAppId = map['miniAppId'];
    updatedTime = DateTime.fromMillisecondsSinceEpoch(map['updatedTime']);
  }
}

class SystemPromotionProvider {
  late Database database;

  SystemPromotionProvider(this.database);

  Future<bool> insert(SystemPromotion systemPromotion) async {
    await database.insert('systemPromotion', systemPromotion.toSql());
    return true;
  }

  Future<bool> update(Map<String, dynamic> values, int uuid) async {
    await database.update('systemPromotion', values, where: "uuid=?", whereArgs: [uuid]);
    return true;
  }

  Future<SystemPromotion?> get(int uuid) async {
    List<Map<String, dynamic>> maps = await database.query('systemPromotion', where: "uuid=?", whereArgs: [uuid]);
    if (maps.isNotEmpty) {
      return SystemPromotion.fromSql(maps.first);
    }
    return null;
  }

  Future<List<int>> getUUIDList() async {
    List<Map<String, dynamic>> maps = await database.query('systemPromotion', columns: ['uuid']);
    List<int> dataList = [];
    for(var map in maps)
    {
      dataList.add(map['uuid']);
    }
    return dataList;
  }
}

class SystemPromotionProviderWithTransaction {
  late Transaction transaction;

  SystemPromotionProviderWithTransaction(this.transaction);

  Future<bool> insert(SystemPromotion systemPromotion) async {
    await transaction.insert('systemPromotion', systemPromotion.toSql());
    return true;
  }

  Future<bool> update(Map<String, dynamic> values, int uuid) async {
    await transaction.update('systemPromotion', values, where: "uuid=?", whereArgs: [uuid]);
    return true;
  }

  Future<SystemPromotion?> get(int uuid) async {
    List<Map<String, dynamic>> maps = await transaction.query('systemPromotion', where: "uuid=?", whereArgs: [uuid]);
    if (maps.isNotEmpty) {
      return SystemPromotion.fromSql(maps.first);
    }
    return null;
  }
}
