class FriendProfile{
  late int uuid;
  late int friendshipId;
  late String account;
  late List<String> roles;
  late String gender;
  late String nickname;
  late String? remark;
  late String avatar;
  late int friendsGroupId;
  late String campus;
  late String department;
  late String? major;
  late String? grade;
  late DateTime updatedTime;

  FriendProfile(this.uuid,this.friendshipId, this.account, this.roles, this.gender, this.nickname, this.remark, this.avatar, this.friendsGroupId, this.campus, this.department, this.major, this.grade, this.updatedTime);

  FriendProfile.fromJson(Map<String, dynamic> map) {
    uuid = map['uuid'];
    friendshipId = map['friendshipId'];
    account = map['account'];
    List<dynamic> tempRoles = map['roles'];
    roles = [];
    for (var value in tempRoles) {
      roles.add(value);
    }
    gender = map['gender'];
    nickname = map['nickname'];
    remark = map['remark'];
    friendsGroupId = map['friendsGroupId'];
    avatar = map['avatar'];
    campus = map['campus'];
    department = map['department'];
    major = map['major'];
    grade = map['grade'];
    updatedTime = DateTime.parse(map['updatedTime']);
  }

}
