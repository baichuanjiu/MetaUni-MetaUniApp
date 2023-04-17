import 'package:sqflite/sqflite.dart';

class UserSynchronizationTable {
  late int uuid;
  late int sequenceForCommonMessages;
  late int sequenceForSystemMessages;
  late DateTime updatedTimeForFriendsGroups;
  late DateTime updatedTimeForFriendShips;
  late DateTime updatedTimeForChats;
  late DateTime updatedTimeForFriendsBriefInformation;

  UserSynchronizationTable({
    required this.uuid,
    required this.sequenceForCommonMessages,
    required this.sequenceForSystemMessages,
    required this.updatedTimeForFriendsGroups,
    required this.updatedTimeForFriendShips,
    required this.updatedTimeForChats,
    required this.updatedTimeForFriendsBriefInformation,
  });

  UserSynchronizationTable.init(this.uuid){
    sequenceForCommonMessages = -1;
    sequenceForSystemMessages = -1;
    updatedTimeForFriendsGroups = DateTime.parse("2023-01-01T00:00:00.0000000");
    updatedTimeForFriendShips = DateTime.parse("2023-01-01T00:00:00.0000000");
    updatedTimeForChats = DateTime.parse("2023-01-01T00:00:00.0000000");
    updatedTimeForFriendsBriefInformation = DateTime.parse("2023-01-01T00:00:00.0000000");
  }

  UserSynchronizationTable.fromJson(Map<String, dynamic> map) {
    uuid = map['uuid'];
    sequenceForCommonMessages = map['sequenceForCommonMessages'];
    sequenceForSystemMessages = map['sequenceForSystemMessages'];
    updatedTimeForFriendsGroups = DateTime.parse(map['updatedTimeForFriendsGroups']);
    updatedTimeForFriendShips = DateTime.parse(map['updatedTimeForFriendShips']);
    updatedTimeForChats = DateTime.parse(map['updatedTimeForChats']);
    updatedTimeForFriendsBriefInformation = DateTime.parse(map['updatedTimeForFriendsBriefInformation']);
  }

  Map<String, dynamic> toSql() {
    return {
      'uuid': uuid,
      'sequenceForCommonMessages': sequenceForCommonMessages,
      'sequenceForSystemMessages': sequenceForSystemMessages,
      'updatedTimeForFriendsGroups': updatedTimeForFriendsGroups.millisecondsSinceEpoch,
      'updatedTimeForFriendShips': updatedTimeForFriendShips.millisecondsSinceEpoch,
      'updatedTimeForChats': updatedTimeForChats.millisecondsSinceEpoch,
      'updatedTimeForFriendsBriefInformation':updatedTimeForFriendsBriefInformation.millisecondsSinceEpoch,
    };
  }

  UserSynchronizationTable.fromSql(Map<String, dynamic> map) {
    uuid = map['uuid'];
    sequenceForCommonMessages = map['sequenceForCommonMessages'];
    sequenceForSystemMessages = map['sequenceForSystemMessages'];
    updatedTimeForFriendsGroups = DateTime.fromMillisecondsSinceEpoch(map['updatedTimeForFriendsGroups']);
    updatedTimeForFriendShips = DateTime.fromMillisecondsSinceEpoch(map['updatedTimeForFriendShips']);
    updatedTimeForChats = DateTime.fromMillisecondsSinceEpoch(map['updatedTimeForChats']);
    updatedTimeForFriendsBriefInformation = DateTime.fromMillisecondsSinceEpoch(map['updatedTimeForFriendsBriefInformation']);
  }
}

class UserSynchronizationTableProvider {
  late Database database;

  UserSynchronizationTableProvider(this.database);

  Future<bool> insert(UserSynchronizationTable userSynchronizationTable) async {
    await database.insert('userSynchronizationTable', userSynchronizationTable.toSql());
    return true;
  }

  Future<UserSynchronizationTable?> get(int uuid) async {
    List<Map<String, dynamic>> maps = await database.query('userSynchronizationTable', where: "uuid=?", whereArgs: [uuid]);
    if (maps.isNotEmpty) {
      return UserSynchronizationTable.fromSql(maps.first);
    }
    return null;
  }
}

class UserSynchronizationTableProviderWithTransaction {
  late Transaction transaction;

  UserSynchronizationTableProviderWithTransaction(this.transaction);

  Future<bool> insert(UserSynchronizationTable userSynchronizationTable) async {
    await transaction.insert('userSynchronizationTable', userSynchronizationTable.toSql());
    return true;
  }

  Future<bool> update(Map<String, dynamic> values, int uuid) async {
    await transaction.update('userSynchronizationTable', values, where: "uuid=?", whereArgs: [uuid]);
    return true;
  }

  Future<UserSynchronizationTable?> get(int uuid) async {
    List<Map<String, dynamic>> maps = await transaction.query('userSynchronizationTable', where: "uuid=?", whereArgs: [uuid]);
    if (maps.isNotEmpty) {
      return UserSynchronizationTable.fromSql(maps.first);
    }
    return null;
  }
}