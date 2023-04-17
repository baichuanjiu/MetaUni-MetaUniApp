import 'package:sqflite/sqflite.dart';

class BriefUserInformation {
  late int uuid;
  late String avatar;
  late String nickname;
  late DateTime updatedTime;

  BriefUserInformation({required this.uuid, required this.avatar, required this.nickname,required this.updatedTime});

  BriefUserInformation.fromJson(Map<String, dynamic> map) {
    uuid = map['uuid'];
    avatar = map['avatar'];
    nickname = map['nickname'];
    updatedTime = DateTime.parse(map['updatedTime']);
  }

  Map<String, dynamic> toSql() {
    return {
      'uuid': uuid,
      'avatar': avatar,
      'nickname': nickname,
      'updatedTime': updatedTime.millisecondsSinceEpoch,
    };
  }

  Map<String, dynamic> toUpdateSql() {
    return {
      'avatar': avatar,
      'nickname': nickname,
      'updatedTime': updatedTime.millisecondsSinceEpoch,
    };
  }

  BriefUserInformation.fromSql(Map<String, dynamic> map) {
    uuid = map['uuid'];
    avatar = map['avatar'];
    nickname = map['nickname'];
    updatedTime = DateTime.fromMillisecondsSinceEpoch(map['updatedTime']);
  }
}

class BriefUserInformationProvider {
  late Database database;

  BriefUserInformationProvider(this.database);

  Future<bool> insert(BriefUserInformation briefUserInformation) async {
    await database.insert('briefUserInformation', briefUserInformation.toSql());
    return true;
  }

  Future<bool> update(Map<String, dynamic> values, int uuid) async {
    await database.update('briefUserInformation', values, where: "uuid=?", whereArgs: [uuid]);
    return true;
  }

  Future<BriefUserInformation?> get(int uuid) async {
    List<Map<String, dynamic>> maps = await database.query('briefUserInformation', where: "uuid=?", whereArgs: [uuid]);
    if (maps.isNotEmpty) {
      return BriefUserInformation.fromSql(maps.first);
    }
    return null;
  }
}

class BriefUserInformationProviderWithTransaction {
  late Transaction transaction;

  BriefUserInformationProviderWithTransaction(this.transaction);

  Future<bool> insert(BriefUserInformation briefUserInformation) async {
    await transaction.insert('briefUserInformation', briefUserInformation.toSql());
    return true;
  }

  Future<bool> update(Map<String, dynamic> values, int uuid) async {
    await transaction.update('briefUserInformation', values, where: "uuid=?", whereArgs: [uuid]);
    return true;
  }

  Future<BriefUserInformation?> get(int uuid) async {
    List<Map<String, dynamic>> maps = await transaction.query('briefUserInformation', where: "uuid=?", whereArgs: [uuid]);
    if (maps.isNotEmpty) {
      return BriefUserInformation.fromSql(maps.first);
    }
    return null;
  }
}
