import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ReferendumResultCardData {
  late int uuid;
  late String avatar;
  late String nickname;
  late int agreeNumber;
  late int disagreeNumber;

  ReferendumResultCardData.fromJson(Map<String, dynamic> map) {
    uuid = map['uuid'];
    avatar = map['avatar'];
    nickname = map['nickname'];
    agreeNumber = map['agreeNumber'];
    disagreeNumber = map['disagreeNumber'];
  }
}

class ReferendumResultCard extends StatefulWidget {
  final ReferendumResultCardData referendumResultCardData;

  const ReferendumResultCard({super.key, required this.referendumResultCardData});

  @override
  State<ReferendumResultCard> createState() => _ReferendumResultCardState();
}

class _ReferendumResultCardState extends State<ReferendumResultCard> {
  @override
  Widget build(BuildContext context) {
    bool isExiled = widget.referendumResultCardData.agreeNumber >= widget.referendumResultCardData.disagreeNumber;

    return Container(
      margin: const EdgeInsets.fromLTRB(0, 5, 0, 10),
      width: MediaQuery.of(context).size.width * 0.9,
      child: Card(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: isExiled
                        ? const Image(
                            fit: BoxFit.fill,
                            image: AssetImage('assets/ReferendumSucceedBackgroundImage.png'),
                          )
                        : const Image(
                            fit: BoxFit.fill,
                            image: AssetImage('assets/ReferendumFailedBackgroundImage.jpg'),
                            opacity: AlwaysStoppedAnimation(0.90),
                          ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 5),
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            "公投结果：",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                          child: CachedNetworkImage(
                            fadeInDuration: const Duration(milliseconds: 800),
                            fadeOutDuration: const Duration(milliseconds: 200),
                            placeholder: (context, url) => const CupertinoActivityIndicator(),
                            imageUrl: widget.referendumResultCardData.avatar,
                            imageBuilder: (context, imageProvider) => CircleAvatar(
                              radius: 20,
                              backgroundImage: imageProvider,
                            ),
                            errorWidget: (context, url, error) => const Icon(Icons.error_outline),
                          ),
                        ),
                        Flexible(
                          child: Text(
                            " ${widget.referendumResultCardData.nickname} ",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            Text(
                              "同意",
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Container(
                              height: 5,
                            ),
                            Text(
                              " ${widget.referendumResultCardData.agreeNumber} 票",
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        Text(
                          "对",
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Column(
                          children: [
                            Text(
                              "反对",
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Container(
                              height: 5,
                            ),
                            Text(
                              " ${widget.referendumResultCardData.disagreeNumber} 票",
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 5, 15, 25),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 15, 5, 0),
                          child: Text(
                            "经组织研究决定：",
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        RotationTransition(
                          turns: const AlwaysStoppedAnimation(-30 / 360),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Theme.of(context).colorScheme.primary, width: 6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isExiled ? "放逐" : "驳回",
                              style: Theme.of(context).textTheme.displaySmall?.apply(
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
