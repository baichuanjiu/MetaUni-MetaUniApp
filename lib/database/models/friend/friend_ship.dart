import 'package:sqflite/sqflite.dart';

class FriendShip {
  late int friendShipId; //主键
  late int userId; //标识这条FriendShip属于谁，主体的UUID
  late int friendId; //标识谁是主体的Friend，客体的UUID
  late DateTime shipCreatedTime; //成为好友的时间
  late String? remark; //主体对客体的备注名，可以为空
  late bool isFocus; //主体是否将客体设置为特别关心
  late bool isDeleted; //这条好友关系是否已被用户删除
  late DateTime updatedTime; //最后更新时间，用于实现增量更新

  FriendShip({
    required this.friendShipId,
    required this.userId,
    required this.friendId,
    required this.shipCreatedTime,
    this.remark,
    this.isFocus = false,
    this.isDeleted = false,
    required this.updatedTime,
  });

  FriendShip.fromJson(Map<String, dynamic> map) {
    friendShipId = map['friendShipId'];
    userId = map['userId'];
    friendId = map['friendId'];
    shipCreatedTime = DateTime.parse(map['shipCreatedTime']);
    remark = map['remark'];
    isFocus = map['isFocus'];
    isDeleted = map['isDeleted'];
    updatedTime = DateTime.parse(map['updatedTime']);
  }

  Map<String, dynamic> toSql() {
    return {
      'friendShipId': friendShipId,
      'userId': userId,
      'friendId': friendId,
      'shipCreatedTime': shipCreatedTime.millisecondsSinceEpoch,
      'remark': remark,
      'isFocus': isFocus ? 1 : 0,
      'isDeleted': isDeleted ? 1 : 0,
      'updatedTime': updatedTime.millisecondsSinceEpoch,
    };
  }

  Map<String, dynamic> toUpdateSql() {
    return {
      'userId': userId,
      'friendId': friendId,
      'shipCreatedTime': shipCreatedTime.millisecondsSinceEpoch,
      'remark': remark,
      'isFocus': isFocus ? 1 : 0,
      'isDeleted': isDeleted ? 1 : 0,
      'updatedTime': updatedTime.millisecondsSinceEpoch,
    };
  }

  FriendShip.fromSql(Map<String, dynamic> map) {
    friendShipId = map['friendShipId'];
    userId = map['userId'];
    friendId = map['friendId'];
    shipCreatedTime = DateTime.fromMillisecondsSinceEpoch(map['shipCreatedTime']);
    remark = map['remark'];
    isFocus = map['isFocus'] > 0;
    isDeleted = map['isDeleted'] > 0;
    updatedTime = DateTime.fromMillisecondsSinceEpoch(map['updatedTime']);
  }
}

class FriendShipProvider {
  late Database database;

  FriendShipProvider(this.database);

  Future<bool> insert(FriendShip friendShip) async {
    await database.insert('friendShip', friendShip.toSql());
    return true;
  }

  Future<bool> update(Map<String, dynamic> values, int friendShipId) async {
    await database.update('friendShip', values, where: "friendShipId=?", whereArgs: [friendShipId]);
    return true;
  }

  Future<FriendShip?> get(int friendShipId) async {
    List<Map<String, dynamic>> maps = await database.query('friendShip', where: "friendShipId=?", whereArgs: [friendShipId]);
    if (maps.isNotEmpty) {
      return FriendShip.fromSql(maps.first);
    }
    return null;
  }

  Future<String?> getRemark(int friendId)async{
    List<Map<String, dynamic>> maps = await database.query('friendShip',columns: ['remark'], where: "friendId=?", whereArgs: [friendId]);
    if (maps.isNotEmpty) {
      String remark = maps.first['remark'];
      if(remark.isNotEmpty){
        return remark;
      }
    }
    return null;
  }

  Future<List<FriendShip>> getAll() async {
    List<FriendShip> friendShips = [];
    List<Map<String, dynamic>> maps = await database.query('friendShip');
    if (maps.isNotEmpty) {
      for (var element in maps) {
        friendShips.add(FriendShip.fromSql(element));
      }
    }
    return friendShips;
  }

  Future<FriendShip?> getNotDeleted(int friendShipId) async {
    List<Map<String, dynamic>> maps = await database.query('friendShip', where: "friendShipId=? & isDeleted=0", whereArgs: [friendShipId]);
    if (maps.isNotEmpty) {
      return FriendShip.fromSql(maps.first);
    }
    return null;
  }

  Future<List<FriendShip>> getAllNotDeleted() async {
    List<FriendShip> friendShips = [];
    List<Map<String, dynamic>> maps = await database.query('friendShip', where: "isDeleted=0");
    if (maps.isNotEmpty) {
      for (var element in maps) {
        friendShips.add(FriendShip.fromSql(element));
      }
    }
    return friendShips;
  }
}

class FriendShipProviderWithTransaction {
  late Transaction transaction;

  FriendShipProviderWithTransaction(this.transaction);

  Future<bool> insert(FriendShip friendShip) async {
    await transaction.insert('friendShip', friendShip.toSql());
    return true;
  }

  Future<bool> update(Map<String, dynamic> values, int friendShipId) async {
    await transaction.update('friendShip', values, where: "friendShipId=?", whereArgs: [friendShipId]);
    return true;
  }

  Future<FriendShip?> get(int friendShipId) async {
    List<Map<String, dynamic>> maps = await transaction.query('friendShip', where: "friendShipId=?", whereArgs: [friendShipId]);
    if (maps.isNotEmpty) {
      return FriendShip.fromSql(maps.first);
    }
    return null;
  }

  Future<FriendShip?> getNotDeleted(int friendShipId) async {
    List<Map<String, dynamic>> maps = await transaction.query('friendShip', where: "friendShipId=? & isDeleted=0", whereArgs: [friendShipId]);
    if (maps.isNotEmpty) {
      return FriendShip.fromSql(maps.first);
    }
    return null;
  }
}
