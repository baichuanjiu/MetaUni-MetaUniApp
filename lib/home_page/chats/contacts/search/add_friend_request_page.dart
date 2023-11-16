import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:meta_uni_app/home_page/reusable_components/friends_group/choose_friends_group_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../database/database_manager.dart';
import '../../../../database/models/friend/friends_group.dart';
import '../../../../database/models/user/brief_user_information.dart';
import '../../../../models/dio_model.dart';
import '../../../../reusable_components/logout/logout.dart';
import '../../../../reusable_components/snack_bar/network_error_snack_bar.dart';
import '../../../../reusable_components/snack_bar/normal_snack_bar.dart';

class AddFriendRequestPage extends StatefulWidget {
  const AddFriendRequestPage({super.key});

  @override
  State<AddFriendRequestPage> createState() => _AddFriendRequestPageState();
}

class _AddFriendRequestPageState extends State<AddFriendRequestPage> {
  late BriefUserInformation targetUser;

  FocusNode messageTextFocusNode = FocusNode();
  TextEditingController messageTextController = TextEditingController(text: "我是");

  FocusNode remarkFocusNode = FocusNode();
  TextEditingController remarkController = TextEditingController();

  late Database database;
  late FriendsGroupProvider friendsGroupProvider;
  late int currentChosenGroupId;
  late String currentChosenGroupName;

  late Future<dynamic> init;

  final DioModel dioModel = DioModel();

  sendAddFriendRequest() async {
    if (remarkController.text.isNotEmpty) {
      List<String> check = remarkController.text.split(
        RegExp(r" +"),
      );
      check.removeWhere((element) => element == "");

      if (check.isEmpty) {
        getNormalSnackBar(context, "备注不可以只含有空格");
        return;
      }
    }
    final prefs = await SharedPreferences.getInstance();

    final String? jwt = prefs.getString('jwt');
    final int? uuid = prefs.getInt('uuid');

    try {
      Response response;
      response = await dioModel.dio.post(
        '/metaUni/userAPI/friendship/request',
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
        data: {
          'targetId': targetUser.uuid,
          'message': messageTextController.text.isEmpty ? null : messageTextController.text,
          'remark': remarkController.text.isEmpty ? null : remarkController.text,
          'friendsGroupId': currentChosenGroupId,
        },
      );
      switch (response.data['code']) {
        case 0:
        //Message:"已成功发送添加好友请求"
          if (mounted) {
            getNormalSnackBar(context, response.data['message']);
            Navigator.pop(context);
          }
          break;
        case 1:
          //Message:"使用了无效的JWT，请重新登录"
          if (mounted) {
            getNormalSnackBar(context, response.data['message']);
            logout(context);
          }
          break;
        case 2:
          //Message:"您正在尝试添加不存在的用户为好友"
          if (mounted) {
            getNormalSnackBar(context, response.data['message']);
            Navigator.pop(context);
          }
          break;
        case 3:
        //Message:"备注不可为空"
        case 4:
        //Message:"备注长度超过限制"
        case 5:
          //Message:"您正在尝试使用一个不存在的好友分组"
          if (mounted) {
            getNormalSnackBar(context, response.data['message']);
          }
          break;
        case 6:
          //Message:"你们已经是好友了"
          if (mounted) {
            getNormalSnackBar(context, response.data['message']);
            Navigator.pop(context);
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

  _init() async {
    database = await DatabaseManager().getDatabase;
    friendsGroupProvider = FriendsGroupProvider(database);

    currentChosenGroupId = await friendsGroupProvider.getFirstNotDeleted();
    currentChosenGroupName = (await friendsGroupProvider.getName(currentChosenGroupId))!;

    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    init = _init();
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();

    targetUser = ModalRoute.of(context)!.settings.arguments as BriefUserInformation;
  }

  @override
  void dispose() {
    messageTextFocusNode.dispose();
    messageTextController.dispose();

    remarkFocusNode.dispose();
    remarkController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("添加好友"),
        actions: [
          TextButton(
            onPressed: () {
              sendAddFriendRequest();
            },
            child: Text(
              "发送",
              style: Theme.of(context).textTheme.titleMedium?.apply(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
        ],
      ),
      body: FutureBuilder(
        future: init,
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
              return const CupertinoActivityIndicator();
            case ConnectionState.active:
              return const CupertinoActivityIndicator();
            case ConnectionState.waiting:
              return const CupertinoActivityIndicator();
            case ConnectionState.done:
              if (snapshot.hasError) {
                return const CupertinoActivityIndicator();
              }
              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Avatar(targetUser.avatar),
                            title: Text(targetUser.nickname),
                          ),
                          Container(
                            padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 20,
                                ),
                                const Text("填写验证信息："),
                                Container(
                                  height: 5,
                                ),
                                TextField(
                                  focusNode: messageTextFocusNode,
                                  controller: messageTextController,
                                  decoration: const InputDecoration(
                                    filled: true,
                                    border: OutlineInputBorder(borderSide: BorderSide.none),
                                    contentPadding: EdgeInsets.fromLTRB(10, 10, 0, 10),
                                    hintText: "验证信息",
                                  ),
                                  autofocus: true,
                                  maxLength: 30,
                                  maxLines: null,
                                  keyboardType: TextInputType.multiline,
                                  textInputAction: TextInputAction.next,
                                  onTapOutside: (value) {
                                    messageTextFocusNode.unfocus();
                                  },
                                ),
                                Container(
                                  height: 20,
                                ),
                                const Text("设置备注与分组："),
                                Container(
                                  height: 5,
                                ),
                                TextField(
                                  focusNode: remarkFocusNode,
                                  controller: remarkController,
                                  decoration: InputDecoration(
                                    border: const OutlineInputBorder(borderSide: BorderSide.none),
                                    contentPadding: const EdgeInsets.fromLTRB(10, 10, 0, 10),
                                    prefixIcon: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.fromLTRB(15, 0, 0, 0),
                                          child: Text(
                                            "备注：",
                                            style: Theme.of(context).textTheme.bodyLarge,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  inputFormatters: [
                                    //只允许输入最多15个字符
                                    LengthLimitingTextInputFormatter(15),
                                  ],
                                  keyboardType: TextInputType.multiline,
                                  textInputAction: TextInputAction.done,
                                  onTapOutside: (value) {
                                    remarkFocusNode.unfocus();
                                  },
                                ),
                                ListTile(
                                  title: Text(
                                    currentChosenGroupName,
                                    style: Theme.of(context).textTheme.bodyLarge,
                                  ),
                                  trailing: const Icon(
                                    Icons.chevron_right_outlined,
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute<int?>(
                                        builder: (context) => ChooseFriendsGroupPage(
                                          currentChosenGroupId: currentChosenGroupId,
                                        ),
                                      ),
                                    ).then(
                                      (value) async {
                                        if (value != null) {
                                          currentChosenGroupId = value;
                                          currentChosenGroupName = (await friendsGroupProvider.getName(currentChosenGroupId))!;
                                          setState(() {});
                                        }
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            default:
              return const CupertinoActivityIndicator();
          }
        },
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
