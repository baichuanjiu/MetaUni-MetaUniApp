import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../../../reusable_components/logout/logout.dart';
import '../../../../../../../reusable_components/snack_bar/network_error_snack_bar.dart';
import '../../../../../../../reusable_components/snack_bar/normal_snack_bar.dart';
import '../../../../../../mini_app_manager.dart';

class ReferendumCardData {
  late String chatRoomName;
  late int uuid;
  late String avatar;
  late String nickname;
  late String reason;
  late DateTime deadline;
  late bool hasVoted;

  ReferendumCardData.fromJson(Map<String, dynamic> map) {
    chatRoomName = map['chatRoomName'];
    uuid = map['uuid'];
    avatar = map['avatar'];
    nickname = map['nickname'];
    reason = map['reason'];
    deadline = DateTime.parse(map['deadline']);
    hasVoted = map['hasVoted'] != null;
  }
}

class ReferendumCard extends StatefulWidget {
  final ReferendumCardData referendumCardData;
  final Function onVote;

  const ReferendumCard({super.key, required this.referendumCardData, required this.onVote});

  @override
  State<ReferendumCard> createState() => _ReferendumCardState();
}

class _ReferendumCardState extends State<ReferendumCard> {
  late int timeLeft;
  late int countDown;
  late bool isOver;

  voteReferendum(bool agree) async {
    final dio = Dio(
      BaseOptions(
        baseUrl: (await MiniAppManager().getCurrentMiniAppUrl())!,
      ),
    );
    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString('jwt')!;
    final uuid = prefs.getInt('uuid')!;

    try {
      Response response;
      response = await dio.get(
        '/chatRoom/referendum/vote/${widget.referendumCardData.chatRoomName}&${widget.referendumCardData.uuid}&${agree ? "agree" : "disagree"}',
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 0:
          widget.onVote();
          break;
        case 1:
          //Message:"使用了无效的JWT，请重新登录"
          if (mounted) {
            getNormalSnackBar(context, response.data['message']);
            logout(context);
          }
          break;
        case 2:
        //Message:"投票失败，传递参数有误"
        case 3:
        //Message:"投票失败，该聊天室不存在"
        case 4:
          //Message:"投票失败，投票时间已结束"
          if (mounted) {
            getNormalSnackBar(context, response.data['message']);
          }
          break;
        default:
          if (mounted) {
            getNetworkErrorSnackBar(context);
          }
      }
    } catch (e) {
      if (mounted) {
        getNetworkErrorSnackBar(context);
      }
    }
  }

  @override
  void initState() {
    super.initState();

    DateTime now = DateTime.now();

    timeLeft = widget.referendumCardData.deadline.millisecondsSinceEpoch - now.millisecondsSinceEpoch;
    if (timeLeft <= 0) {
      isOver = true;
    } else {
      countDown = timeLeft;
      isOver = false;

      Timer timer = Timer.periodic(const Duration(milliseconds: 1), (timer) {
        if (timer.tick >= timeLeft) {
          timer.cancel();
          setState(() {
            countDown = 0;
            isOver = true;
          });
        }
        setState(() {
          countDown = timeLeft - timer.tick;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 5, 0, 10),
      width: MediaQuery.of(context).size.width * 0.9,
      child: Card(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            children: [
              const Row(
                children: [
                  Expanded(
                    child: Image(
                      fit: BoxFit.fill,
                      image: AssetImage('assets/ReferendumBackgroundImage.jpg'),
                      opacity: AlwaysStoppedAnimation(0.8),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 5, 10, 0),
                    child: Row(
                      children: [
                        Text(
                          "对 ",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                          child: CachedNetworkImage(
                            fadeInDuration: const Duration(milliseconds: 800),
                            fadeOutDuration: const Duration(milliseconds: 200),
                            placeholder: (context, url) => const CupertinoActivityIndicator(),
                            imageUrl: widget.referendumCardData.avatar,
                            imageBuilder: (context, imageProvider) => CircleAvatar(
                              radius: 20,
                              backgroundImage: imageProvider,
                            ),
                            errorWidget: (context, url, error) => const Icon(Icons.error_outline),
                          ),
                        ),
                        Flexible(
                          child: Text(
                            " ${widget.referendumCardData.nickname} 发动公投",
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
                    padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                    child: Text("\t\t\t\t\t\t\t\t情景描述：某人对 ${widget.referendumCardData.nickname} 发动了公投，尝试将其逐出该聊天室，被放逐的家伙将在一个小时内禁止进入该聊天室。"),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
                    child: Text("\t\t\t\t\t\t\t\t统计规则：倒计时结束时，同意票数大于等于反对票数即视作放逐提案通过"),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                    child: Text("\t\t\t\t\t\t\t\t放逐理由：${widget.referendumCardData.reason}"),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(0, 0, 5, isOver ? 10 : 5),
                    child: isOver
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                "公投已结束！",
                                style: Theme.of(context).textTheme.titleLarge?.apply(
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                                child: Text(
                                  "\t\t\t\t\t\t${(countDown / 1000).toStringAsFixed(3)} s",
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                              widget.referendumCardData.hasVoted
                                  ? Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          "您已投票！",
                                          style: Theme.of(context).textTheme.titleLarge?.apply(
                                                color: Theme.of(context).colorScheme.primary,
                                              ),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      children: [
                                        TextButton(
                                          onPressed: () {
                                            voteReferendum(false);
                                          },
                                          child: const Text("反对"),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            voteReferendum(true);
                                          },
                                          child: const Text("同意"),
                                        ),
                                      ],
                                    ),
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
