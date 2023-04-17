import 'package:sqflite/sqflite.dart';

class FriendsGroup {
  late int friendsGroupId; //主键
  late int userId; //标识该好友分组属于谁，主体的UUID
  late int orderNumber; //标识主体对该好友分组的排序
  late String friendsGroupName; //主体对该好友分组的命名
  late String friends; //哪些好友在该好友分组内，以JSON形式存储的Int数组，数组内容为friendShipId
  late bool isDeleted; //这一分组是否已被用户选择删除
  late DateTime updatedTime; //最后更新时间，用于实现增量更新

  FriendsGroup({
    required this.friendsGroupId,
    required this.userId,
    required this.orderNumber,
    required this.friendsGroupName,
    required this.friends,
    this.isDeleted = false,
    required this.updatedTime,
  });

  FriendsGroup.fromJson(Map<String, dynamic> map) {
    friendsGroupId = map['friendsGroupId'];
    userId = map['userId'];
    orderNumber = map['orderNumber'];
    friendsGroupName = map['friendsGroupName'];
    friends = map['friends'];
    isDeleted = map['isDeleted'];
    updatedTime = DateTime.parse(map['updatedTime']);
  }

  Map<String, dynamic> toSql() {
    return {
      'friendsGroupId': friendsGroupId,
      'userId': userId,
      'orderNumber': orderNumber,
      'friendsGroupName': friendsGroupName,
      'friends': friends,
      'isDeleted': isDeleted ? 1 : 0,
      'updatedTime': updatedTime.millisecondsSinceEpoch,
    };
  }

  Map<String, dynamic> toUpdateSql() {
    return {
      'userId': userId,
      'orderNumber': orderNumber,
      'friendsGroupName': friendsGroupName,
      'friends': friends,
      'isDeleted': isDeleted ? 1 : 0,
      'updatedTime': updatedTime.millisecondsSinceEpoch,
    };
  }

  FriendsGroup.fromSql(Map<String, dynamic> map) {
    friendsGroupId = map['friendsGroupId'];
    userId = map['userId'];
    orderNumber = map['orderNumber'];
    friendsGroupName = map['friendsGroupName'];
    friends = map['friends'];
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

  Future<bool> update(Map<String, dynamic> values, int friendsGroupId) async {
    await database.update('friendsGroup', values, where: "friendsGroupId=?", whereArgs: [friendsGroupId]);
    return true;
  }

  Future<FriendsGroup?> get(int friendsGroupId) async {
    List<Map<String, dynamic>> maps = await database.query('friendsGroup', where: "friendsGroupId=?", whereArgs: [friendsGroupId]);
    if (maps.isNotEmpty) {
      return FriendsGroup.fromSql(maps.first);
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

  Future<FriendsGroup?> getNotDeleted(int friendsGroupId) async {
    List<Map<String, dynamic>> maps = await database.query('friendsGroup', where: "friendsGroupId=? & isDeleted=0", whereArgs: [friendsGroupId]);
    if (maps.isNotEmpty) {
      return FriendsGroup.fromSql(maps.first);
    }
    return null;
  }

  Future<List<FriendsGroup>> getAllNotDeleted() async {
    List<FriendsGroup> friendsGroups = [];
    List<Map<String, dynamic>> maps = await database.query('friendsGroup', where: "isDeleted=0");
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

  Future<bool> update(Map<String, dynamic> values, int friendsGroupId) async {
    await transaction.update('friendsGroup', values, where: "friendsGroupId=?", whereArgs: [friendsGroupId]);
    return true;
  }

  Future<FriendsGroup?> get(int friendsGroupId) async {
    List<Map<String, dynamic>> maps = await transaction.query('friendsGroup', where: "friendsGroupId=?", whereArgs: [friendsGroupId]);
    if (maps.isNotEmpty) {
      return FriendsGroup.fromSql(maps.first);
    }
    return null;
  }

  Future<FriendsGroup?> getNotDeleted(int friendsGroupId) async {
    List<Map<String, dynamic>> maps = await transaction.query('friendsGroup', where: "friendsGroupId=? & isDeleted=0", whereArgs: [friendsGroupId]);
    if (maps.isNotEmpty) {
      return FriendsGroup.fromSql(maps.first);
    }
    return null;
  }
}
