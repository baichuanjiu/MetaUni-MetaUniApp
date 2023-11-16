import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:meta_uni_app/reusable_components/get_current_user_information/get_current_user_information.dart';
import '../../database/models/user/brief_user_information.dart';
import '../../reusable_components/shimmer/shimmer.dart';
import 'settings/settings_page.dart';

class MePage extends StatefulWidget {
  const MePage({super.key});

  @override
  State<MePage> createState() => _MePageState();
}

class _MePageState extends State<MePage> {
  late Future<dynamic> initMyBriefInformation;
  late BriefUserInformation me;

  _initMyBriefInformation() async {
    me = await getCurrentUserInformation();
  }

  @override
  void initState() {
    super.initState();

    initMyBriefInformation = _initMyBriefInformation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
            icon: const Icon(Icons.settings_outlined),
            tooltip: '设置',
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            FutureBuilder(
                future: initMyBriefInformation,
                builder: (context, snapshot) {
                  switch (snapshot.connectionState) {
                    case ConnectionState.none:
                      return const MyInformationLoadingPlaceholder();
                    case ConnectionState.active:
                      return const MyInformationLoadingPlaceholder();
                    case ConnectionState.waiting:
                      return const MyInformationLoadingPlaceholder();
                    case ConnectionState.done:
                      if (snapshot.hasError) {
                        return const MyInformationLoadingPlaceholder();
                      }
                      return InkWell(
                        onTap: () {
                          Navigator.pushNamed(context, '/user/profile', arguments: me.uuid).then((value){
                            setState(() {
                              _initMyBriefInformation();
                            });
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
                          child: Row(
                            children: [
                              Avatar(me.avatar),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.fromLTRB(15, 0, 0, 0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        physics: const BouncingScrollPhysics(),
                                        child: Text(
                                          me.nickname,
                                          style: Theme.of(context).textTheme.headlineSmall,
                                        ),
                                      ),
                                      Text(
                                        'UUID：${me.uuid.toString()}',
                                        style: Theme.of(context).textTheme.labelSmall?.apply(color: Theme.of(context).colorScheme.outline),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    default:
                      return const MyInformationLoadingPlaceholder();
                  }
                }),
            const SettingsGroup1(),
            const SettingsGroup3(),
            const SettingsGroup4(),
          ],
        ),
      ),
    );
  }
}

class MyInformationLoadingPlaceholder extends StatelessWidget {
  const MyInformationLoadingPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ShimmerLoading(
        child: Container(
          padding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
          child: Row(
            children: [
              SizedBox(
                width: 90,
                height: 90,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    color: Theme.of(context).colorScheme.surface,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(15, 0, 0, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 24,
                      width: 123,
                      margin: const EdgeInsets.fromLTRB(0, 4, 0, 4),
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    Container(
                      height: 11,
                      width: 101,
                      margin: const EdgeInsets.fromLTRB(0, 2.5, 0, 2.5),
                      color: Theme.of(context).colorScheme.surface,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
          width: 90,
          height: 90,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: const Center(
              child: CupertinoActivityIndicator(),
            ),
          ),
        ),
        imageUrl: avatar,
        imageBuilder: (context, imageProvider) => SizedBox(
          width: 90,
          height: 90,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image(
              image: imageProvider,
            ),
          ),
        ),
        errorWidget: (context, url, error) => SizedBox(
          width: 90,
          height: 90,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: const Center(
              child: Icon(Icons.error_outline),
            ),
          ),
        )
    );
  }
}
