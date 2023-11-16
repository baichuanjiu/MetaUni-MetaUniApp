import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class UserSearchResultPage extends StatefulWidget {
  const UserSearchResultPage({super.key});

  @override
  State<UserSearchResultPage> createState() => _UserSearchResultPageState();
}

class _UserSearchResultPageState extends State<UserSearchResultPage> {
  late List<BriefUserSearchResultData> searchResult = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    searchResult = [];
    List<dynamic> list = ModalRoute.of(context)!.settings.arguments as List<dynamic>;
    for (var element in list) {
      searchResult.add(BriefUserSearchResultData.fromJson(element));
    }
    setState(() {

    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("搜索结果"),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              itemCount: searchResult.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  leading: Avatar(searchResult[index].avatar),
                  title: Text(searchResult[index].nickname),
                  onTap: (){
                    Navigator.pushNamed(context, '/user/profile', arguments: searchResult[index].uuid);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class Avatar extends StatelessWidget {
  final String avatar;

  const Avatar(this.avatar, {super.key});

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
        fadeInDuration: const Duration(milliseconds: 800),
        fadeOutDuration: const Duration(milliseconds: 200),
        placeholder: (context, url) => SizedBox(
          width: 45,
          height: 45,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: const Center(
              child: CupertinoActivityIndicator(),
            ),
          ),
        ),
        imageUrl: avatar,
        imageBuilder: (context, imageProvider) => SizedBox(
          width: 45,
          height: 45,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Image(
              image: imageProvider,
            ),
          ),
        ),
        errorWidget: (context, url, error) => SizedBox(
          width: 45,
          height: 45,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: const Center(
              child: Icon(Icons.error_outline),
            ),
          ),
        )
    );
  }
}

class BriefUserSearchResultData {
  late int uuid;
  late String avatar;
  late String nickname;

  BriefUserSearchResultData.fromJson(Map<String, dynamic> map) {
    uuid = map['uuid'];
    avatar = map['avatar'];
    nickname = map['nickname'];
  }
}
