class BaseProfile {
  late int uuid;
  late String account;
  late List<String> roles;
  late String gender;
  late String nickname;
  late String avatar;
  late String campus;
  late String department;
  late String? major;
  late String? grade;
  late DateTime updatedTime;

  BaseProfile(this.uuid, this.account, this.roles, this.gender, this.nickname, this.avatar, this.campus, this.department, this.major, this.grade, this.updatedTime);

  BaseProfile.fromJson(Map<String, dynamic> map) {
    uuid = map['uuid'];
    account = map['account'];
    List<dynamic> tempRoles = map['roles'];
    roles = [];
    for (var value in tempRoles) {
      roles.add(value);
    }
    gender = map['gender'];
    nickname = map['nickname'];
    avatar = map['avatar'];
    campus = map['campus'];
    department = map['department'];
    major = map['major'];
    grade = map['grade'];
    updatedTime = DateTime.parse(map['updatedTime']);
  }
}
