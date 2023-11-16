import 'package:sqflite/sqflite.dart';

class FriendsGroup {
  late int id; //主键
  late int uuid; //标识该好友分组属于谁，主体的UUID
  late int orderNumber; //标识主体对该好友分组的排序
  late String friendsGroupName; //主体对该好友分组的命名
  late bool isDeleted; //这一分组是否已被用户选择删除
  late DateTime updatedTime; //最后更新时间，用于实现增量更新

  FriendsGroup({
    required this.id,
    required this.uuid,
    required this.orderNumber,
    required this.friendsGroupName,
    this.isDeleted = false,
    required this.updatedTime,
  });

  FriendsGroup.fromJson(Map<String, dynamic> map) {
    id = map['id'];
    uuid = map['uuid'];
    orderNumber = map['orderNumber'];
    friendsGroupName = map['friendsGroupName'];
    isDeleted = map['isDeleted'];
    updatedTime = DateTime.parse(map['updatedTime']);
  }

  Map<String, dynamic> toSql() {
    return {
      'id': id,
      'uuid': uuid,
      'orderNumber': orderNumber,
      'friendsGroupName': friendsGroupName,
      'isDeleted': isDeleted ? 1 : 0,
      'updatedTime': updatedTime.millisecondsSinceEpoch,
    };
  }

  Map<String, dynamic> toUpdateSql() {
    return {
      'uuid': uuid,
      'orderNumber': orderNumber,
      'friendsGroupName': friendsGroupName,
      'isDeleted': isDeleted ? 1 : 0,
      'updatedTime': updatedTime.millisecondsSinceEpoch,
    };
  }

  FriendsGroup.fromSql(Map<String, dynamic> map) {
    id = map['id'];
    uuid = map['uuid'];
    orderNumber = map['orderNumber'];
    friendsGroupName = map['friendsGroupName'];
    isDeleted = map['isDeleted'] > 0;
    updatedTime = DateTime.fromMillisecondsSinceEpoch(map['updatedTime']);
  }
}

class FriendsGroupProvider {
  late Database database;

  FriendsGroupProvider(this.database);

  Future<bool> insert(FriendsGroup friendsGroup) async {
    await database.insert('friendsGroup', friendsGroup.toSql());
    return true;
  }

  Future<bool> update(Map<String, dynamic> values, int id) async {
    await database.update('friendsGroup', values, where: "id=?", whereArgs: [id]);
    return true;
  }

  Future<FriendsGroup?> get(int id) async {
    List<Map<String, dynamic>> maps = await database.query('friendsGroup', where: "id=?", whereArgs: [id]);
    if (maps.isNotEmpty) {
      return FriendsGroup.fromSql(maps.first);
    }
    return null;
  }

  Future<int> getFirstNotDeleted() async {
    List<Map<String, dynamic>> maps = await database.query('friendsGroup',columns: ['id'], where: "orderNumber=1 and isDeleted=0");
    return maps.first['id'];
  }

  Future<String?> getName(int id) async {
    List<Map<String, dynamic>> maps = await database.query('friendsGroup',columns: ['friendsGroupName'], where: "id=?", whereArgs: [id]);
    if (maps.isNotEmpty) {
      return maps.first['friendsGroupName'];
    }
    return null;
  }

  Future<List<FriendsGroup>> getAll() async {
    List<FriendsGroup> friendsGroups = [];
    List<Map<String, dynamic>> maps = await database.query('friendsGroup');
    if (maps.isNotEmpty) {
      for (var element in maps) {
        friendsGroups.add(FriendsGroup.fromSql(element));
      }
    }
    return friendsGroups;
  }

  Future<FriendsGroup?> getNotDeleted(int id) async {
    List<Map<String, dynamic>> maps = await database.query('friendsGroup', where: "id=? and isDeleted=0", whereArgs: [id]);
    if (maps.isNotEmpty) {
      return FriendsGroup.fromSql(maps.first);
    }
    return null;
  }

  Future<List<FriendsGroup>> getAllNotDeletedOrderByOrderNumber() async {
    List<FriendsGroup> friendsGroups = [];
    List<Map<String, dynamic>> maps = await database.query('friendsGroup', where: "isDeleted=0",orderBy: "orderNumber");
    if (maps.isNotEmpty) {
      for (var element in maps) {
        friendsGroups.add(FriendsGroup.fromSql(element));
      }
    }
    return friendsGroups;
  }
}

class FriendsGroupProviderWithTransaction{
  late Transaction transaction;

  FriendsGroupProviderWithTransaction(this.transaction);

  Future<bool> insert(FriendsGroup friendsGroup) async {
    await transaction.insert('friendsGroup', friendsGroup.toSql());
    return true;
  }

  Future<bool> update(Map<String, dynamic> values, int id) async {
    await transaction.update('friendsGroup', values, where: "id=?", whereArgs: [id]);
    return true;
  }

  Future<FriendsGroup?> get(int id) async {
    List<Map<String, dynamic>> maps = await transaction.query('friendsGroup', where: "id=?", whereArgs: [id]);
    if (maps.isNotEmpty) {
      return FriendsGroup.fromSql(maps.first);
    }
    return null;
  }

  Future<FriendsGroup?> getNotDeleted(int id) async {
    List<Map<String, dynamic>> maps = await transaction.query('friendsGroup', where: "id=? and isDeleted=0", whereArgs: [id]);
    if (maps.isNotEmpty) {
      return FriendsGroup.fromSql(maps.first);
    }
    return null;
  }
}
