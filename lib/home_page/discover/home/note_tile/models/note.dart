class Note{
  late String id;
  late String title;
  late String description;
  late String version;
  late DateTime createdTime;

  Note.fromJson(Map<String, dynamic> map) {
    id = map['id'];
    title = map['title'];
    description = map['description'];
    version = map['version'];
    createdTime = DateTime.parse(map['createdTime']);
  }
}