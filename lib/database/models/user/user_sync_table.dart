import 'package:sqflite/sqflite.dart';

class UserSyncTable {
  late int id;
  late int uuid;
  late int sequenceForCommonMessages;
  late int sequenceForSystemMessages;
  late DateTime updatedTimeForFriendsGroups;
  late DateTime updatedTimeForFriendships;
  late DateTime updatedTimeForChats;
  late DateTime lastSyncTimeForCommonChatStatuses;
  late DateTime lastSyncTimeForFriendsBriefInformation;
  late DateTime lastSyncTimeForSystemPromotionInformation;

  UserSyncTable({
    required this.id,
    required this.uuid,
    required this.sequenceForCommonMessages,
    required this.sequenceForSystemMessages,
    required this.updatedTimeForFriendsGroups,
    required this.updatedTimeForFriendships,
    required this.updatedTimeForChats,
    required this.lastSyncTimeForCommonChatStatuses,
    required this.lastSyncTimeForFriendsBriefInformation,
    required this.lastSyncTimeForSystemPromotionInformation,
  });

  UserSyncTable.init(this.uuid) {
    id = 0;
    sequenceForCommonMessages = -1;
    sequenceForSystemMessages = -1;
    updatedTimeForFriendsGroups = DateTime.parse("2023-01-01T00:00:00.0000000");
    updatedTimeForFriendships = DateTime.parse("2023-01-01T00:00:00.0000000");
    updatedTimeForChats = DateTime.parse("2023-01-01T00:00:00.0000000");
    lastSyncTimeForCommonChatStatuses = DateTime.parse("2023-01-01T00:00:00.0000000");
    lastSyncTimeForFriendsBriefInformation = DateTime.parse("2023-01-01T00:00:00.0000000");
    lastSyncTimeForSystemPromotionInformation = DateTime.parse("2023-01-01T00:00:00.0000000");
  }

  UserSyncTable.fromJson(Map<String, dynamic> map) {
    id = map['id'];
    uuid = map['uuid'];
    sequenceForCommonMessages = map['sequenceForCommonMessages'];
    sequenceForSystemMessages = map['sequenceForSystemMessages'];
    updatedTimeForFriendsGroups = DateTime.parse(map['updatedTimeForFriendsGroups']);
    updatedTimeForFriendships = DateTime.parse(map['updatedTimeForFriendships']);
    updatedTimeForChats = DateTime.parse(map['updatedTimeForChats']);
    lastSyncTimeForCommonChatStatuses = DateTime.parse(map['lastSyncTimeForCommonChatStatuses']);
    lastSyncTimeForFriendsBriefInformation = DateTime.parse(map['lastSyncTimeForFriendsBriefInformation']);
    lastSyncTimeForSystemPromotionInformation = DateTime.parse(map['lastSyncTimeForSystemPromotionInformation']);
  }

  Map<String, dynamic> toSql() {
    return {
      'id': id,
      'uuid': uuid,
      'sequenceForCommonMessages': sequenceForCommonMessages,
      'sequenceForSystemMessages': sequenceForSystemMessages,
      'updatedTimeForFriendsGroups': updatedTimeForFriendsGroups.millisecondsSinceEpoch,
      'updatedTimeForFriendships': updatedTimeForFriendships.millisecondsSinceEpoch,
      'updatedTimeForChats': updatedTimeForChats.millisecondsSinceEpoch,
      'lastSyncTimeForCommonChatStatuses': lastSyncTimeForCommonChatStatuses.millisecondsSinceEpoch,
      'lastSyncTimeForFriendsBriefInformation': lastSyncTimeForFriendsBriefInformation.millisecondsSinceEpoch,
      'lastSyncTimeForSystemPromotionInformation': lastSyncTimeForSystemPromotionInformation.millisecondsSinceEpoch,
    };
  }

  UserSyncTable.fromSql(Map<String, dynamic> map) {
    id = map['id'];
    uuid = map['uuid'];
    sequenceForCommonMessages = map['sequenceForCommonMessages'];
    sequenceForSystemMessages = map['sequenceForSystemMessages'];
    updatedTimeForFriendsGroups = DateTime.fromMillisecondsSinceEpoch(map['updatedTimeForFriendsGroups']);
    updatedTimeForFriendships = DateTime.fromMillisecondsSinceEpoch(map['updatedTimeForFriendships']);
    updatedTimeForChats = DateTime.fromMillisecondsSinceEpoch(map['updatedTimeForChats']);
    lastSyncTimeForCommonChatStatuses = DateTime.fromMillisecondsSinceEpoch(map['lastSyncTimeForCommonChatStatuses']);
    lastSyncTimeForFriendsBriefInformation = DateTime.fromMillisecondsSinceEpoch(map['lastSyncTimeForFriendsBriefInformation']);
    lastSyncTimeForSystemPromotionInformation = DateTime.fromMillisecondsSinceEpoch(map['lastSyncTimeForSystemPromotionInformation']);
  }
}

class UserSyncTableProvider {
  late Database database;

  UserSyncTableProvider(this.database);

  Future<bool> insert(UserSyncTable userSyncTable) async {
    await database.insert('userSyncTable', userSyncTable.toSql());
    return true;
  }

  Future<bool> update(Map<String, dynamic> values, int uuid) async {
    await database.update('userSyncTable', values, where: "uuid=?", whereArgs: [uuid]);
    return true;
  }

  Future<UserSyncTable?> get(int uuid) async {
    List<Map<String, dynamic>> maps = await database.query('userSyncTable', where: "uuid=?", whereArgs: [uuid]);
    if (maps.isNotEmpty) {
      return UserSyncTable.fromSql(maps.first);
    }
    return null;
  }

  Future<int?> getSequenceForCommonMessages(int uuid) async {
    List<Map<String, dynamic>> maps = await database.query('userSyncTable', columns: ["sequenceForCommonMessages"], where: "uuid=?", whereArgs: [uuid]);
    if (maps.isNotEmpty) {
      return maps.first["sequenceForCommonMessages"];
    }
    return null;
  }

  Future<bool> updateSequenceForCommonMessages(int uuid, int sequence) async {
    await database.update(
      'userSyncTable',
      {
        'sequenceForCommonMessages': sequence,
      },
      where: "uuid=?",
      whereArgs: [uuid],
    );
    return true;
  }

  Future<int?> getSequenceForSystemMessages(int uuid) async {
    List<Map<String, dynamic>> maps = await database.query('userSyncTable', columns: ["sequenceForSystemMessages"], where: "uuid=?", whereArgs: [uuid]);
    if (maps.isNotEmpty) {
      return maps.first["sequenceForSystemMessages"];
    }
    return null;
  }

  Future<bool> updateSequenceForSystemMessages(int uuid, int sequence) async {
    await database.update(
      'userSyncTable',
      {
        'sequenceForSystemMessages': sequence,
      },
      where: "uuid=?",
      whereArgs: [uuid],
    );
    return true;
  }
}

class UserSyncTableProviderWithTransaction {
  late Transaction transaction;

  UserSyncTableProviderWithTransaction(this.transaction);

  Future<bool> insert(UserSyncTable userSyncTable) async {
    await transaction.insert('userSyncTable', userSyncTable.toSql());
    return true;
  }

  Future<bool> update(Map<String, dynamic> values, int uuid) async {
    await transaction.update('userSyncTable', values, where: "uuid=?", whereArgs: [uuid]);
    return true;
  }

  Future<bool> updateSequenceForCommonMessages(int uuid, int sequence) async {
    await transaction.update(
      'userSyncTable',
      {
        'sequenceForCommonMessages': sequence,
      },
      where: "uuid=?",
      whereArgs: [uuid],
    );
    return true;
  }

  Future<bool> updateSequenceForSystemMessages(int uuid, int sequence) async {
    await transaction.update(
      'userSyncTable',
      {
        'sequenceForSystemMessages': sequence,
      },
      where: "uuid=?",
      whereArgs: [uuid],
    );
    return true;
  }

  Future<UserSyncTable?> get(int uuid) async {
    List<Map<String, dynamic>> maps = await transaction.query('userSyncTable', where: "uuid=?", whereArgs: [uuid]);
    if (maps.isNotEmpty) {
      return UserSyncTable.fromSql(maps.first);
    }
    return null;
  }
}
