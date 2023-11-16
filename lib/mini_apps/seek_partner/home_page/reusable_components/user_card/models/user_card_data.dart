import 'package:meta_uni_app/mini_apps/seek_partner/home_page/models/brief_user_info/brief_user_info.dart';
import 'package:meta_uni_app/mini_apps/seek_partner/home_page/models/media/media_metadata.dart';

class UserCardData {
  late BriefUserInfo user;
  late String? summary;
  late MediaMetadata backgroundImage;

  UserCardData(this.user, this.summary, this.backgroundImage);

  UserCardData.fromJson(Map<String, dynamic> map) {
    user = BriefUserInfo.fromJson(map['user']);
    summary = map['summary'];
    backgroundImage = MediaMetadata.fromJson(map['backgroundImage']);
  }
}
