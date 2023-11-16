import 'package:sqflite/sqflite.dart';

class Friendship {
  late int id; //主键
  late int uuid; //标识这条Friendship属于谁，主体的uuid
  late int friendsGroupId; //标识这条Friendship被主体放在哪个好友分组内
  late int friendId; //标识谁是主体的Friend，客体的uuid
  late DateTime shipCreatedTime; //成为好友的时间
  late String? remark; //主体对客体的备注名，可以为空
  late bool isFocus; //主体是否将客体设置为特别关心
  late bool isDeleted; //这条好友关系是否已被用户删除
  late DateTime updatedTime; //最后更新时间，用于实现增量更新

  Friendship({
    required this.id,
    required this.uuid,
    required this.friendsGroupId,
    required this.friendId,
    required this.shipCreatedTime,
    this.remark,
    this.isFocus = false,
    this.isDeleted = false,
    required this.updatedTime,
  });

  Friendship.fromJson(Map<String, dynamic> map) {
    id = map['id'];
    uuid = map['uuid'];
    friendsGroupId = map['friendsGroupId'];
    friendId = map['friendId'];
    shipCreatedTime = DateTime.parse(map['shipCreatedTime']);
    remark = map['remark'];
    isFocus = map['isFocus'];
    isDeleted = map['isDeleted'];
    updatedTime = DateTime.parse(map['updatedTime']);
  }

  Map<String, dynamic> toSql() {
    return {
      'id': id,
      'uuid': uuid,
      'friendsGroupId': friendsGroupId,
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
      'friendsGroupId': friendsGroupId,
      'friendId': friendId,
      'shipCreatedTime': shipCreatedTime.millisecondsSinceEpoch,
      'remark': remark,
      'isFocus': isFocus ? 1 : 0,
      'isDeleted': isDeleted ? 1 : 0,
      'updatedTime': updatedTime.millisecondsSinceEpoch,
    };
  }

  Friendship.fromSql(Map<String, dynamic> map) {
    id = map['id'];
    uuid = map['uuid'];
    friendsGroupId = map['friendsGroupId'];
    friendId = map['friendId'];
    shipCreatedTime = DateTime.fromMillisecondsSinceEpoch(map['shipCreatedTime']);
    remark = map['remark'];
    isFocus = map['isFocus'] > 0;
    isDeleted = map['isDeleted'] > 0;
    updatedTime = DateTime.fromMillisecondsSinceEpoch(map['updatedTime']);
  }
}

class FriendshipProvider {
  late Database database;

  FriendshipProvider(this.database);

  Future<bool> insert(Friendship friendship) async {
    await database.insert('friendship', friendship.toSql());
    return true;
  }

  Future<bool> update(Map<String, dynamic> values, int id) async {
    await database.update('friendship', values, where: "id=?", whereArgs: [id]);
    return true;
  }

  Future<Friendship?> get(int id) async {
    List<Map<String, dynamic>> maps = await database.query('friendship', where: "id=?", whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Friendship.fromSql(maps.first);
    }
    return null;
  }

  Future<String?> getRemark(int friendId) async {
    List<Map<String, dynamic>> maps = await database.query('friendship', columns: ['remark'], where: "friendId=? and isDeleted=0", whereArgs: [friendId]);
    if (maps.isNotEmpty) {
      String? remark = maps.first['remark'];
      return remark;
    }
    return null;
  }

  Future<Friendship?> getNotDeleted(int id) async {
    List<Map<String, dynamic>> maps = await database.query('friendship', where: "id=? and isDeleted=0", whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Friendship.fromSql(maps.first);
    }
    return null;
  }

  Future<List<Friendship>> getAllNotDeleted() async {
    List<Friendship> friendships = [];
    List<Map<String, dynamic>> maps = await database.query('friendship', where: "isDeleted=0");
    if (maps.isNotEmpty) {
      for (var element in maps) {
        friendships.add(Friendship.fromSql(element));
      }
    }
    return friendships;
  }

  Future<List<Friendship>> getFriendsInGroup(int friendsGroupId) async {
    List<Friendship> friends = [];
    List<Map<String, dynamic>> maps = await database.query('friendship', where: "friendsGroupId=? and isDeleted=0", whereArgs: [friendsGroupId]);
    if (maps.isNotEmpty) {
      for (var element in maps) {
        friends.add(Friendship.fromSql(element));
      }
    }
    return friends;
  }
}

class FriendshipProviderWithTransaction {
  late Transaction transaction;

  FriendshipProviderWithTransaction(this.transaction);

  Future<bool> insert(Friendship friendship) async {
    await transaction.insert('friendship', friendship.toSql());
    return true;
  }

  Future<bool> update(Map<String, dynamic> values, int id) async {
    await transaction.update('friendship', values, where: "id=?", whereArgs: [id]);
    return true;
  }

  Future<Friendship?> get(int id) async {
    List<Map<String, dynamic>> maps = await transaction.query('friendship', where: "id=?", whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Friendship.fromSql(maps.first);
    }
    return null;
  }

  Future<Friendship?> getNotDeleted(int id) async {
    List<Map<String, dynamic>> maps = await transaction.query('friendship', where: "id=? and isDeleted=0", whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Friendship.fromSql(maps.first);
    }
    return null;
  }
}
