import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:meta_uni_app/home_page/discover/home/note_tile/note_tile.dart';
import 'package:meta_uni_app/home_page/discover/home/recently_used_tile/recently_used_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/dio_model.dart';
import '../../../reusable_components/logout/logout.dart';
import '../../../reusable_components/snack_bar/network_error_snack_bar.dart';
import '../../../reusable_components/snack_bar/normal_snack_bar.dart';
import 'note_tile/models/note.dart';

class DiscoverHomePage extends StatefulWidget {
  const DiscoverHomePage({super.key});

  @override
  State<DiscoverHomePage> createState() => _DiscoverHomePageState();
}

class _DiscoverHomePageState extends State<DiscoverHomePage> {
  Note? latestNote;

  _getLatestNote() async {
    DioModel dioModel = DioModel();

    final prefs = await SharedPreferences.getInstance();

    final String? jwt = prefs.getString('jwt');
    final int? uuid = prefs.getInt('uuid');

    try {
      Response response;
      response = await dioModel.dio.get(
        '/metaUni/versionAPI/note/latest',
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 0:
          latestNote = Note.fromJson(response.data['data']);
          setState(() {});
          break;
        case 1:
          //Message:"使用了无效的JWT，请重新登录"
          if (context.mounted) {
            getNormalSnackBar(context, response.data['message']);
            logout(context);
          }
          break;
        default:
          if (context.mounted) {
            getNetworkErrorSnackBar(context);
          }
      }
    } catch (e) {
      if (context.mounted) {
        getNetworkErrorSnackBar(context);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _getLatestNote();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const RecentlyUsedTile(),
              const Divider(),
              NoteTile(
                note: latestNote,
              ),
              const Divider(),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: const Image(
                  fit: BoxFit.cover,
                  image: AssetImage('assets/todoroki.gif'),
                ),
              ),
              // ElevatedButton(
              //   onPressed: () async{
              //
              //     /*
              //       通过 Android App Links 启动，原神注册的App Links 为 'yuanshengame://'
              //      */
              //     await launchUrl(Uri.parse('yuanshengame://'),mode: LaunchMode.externalApplication);
              //
              //     /*
              //       没下载时走这个链接，跳到下载页
              //
              //     final Uri _url = Uri.parse('https://ys-api.mihoyo.com/event/download_porter/link/ys_cn/official/android_default');
              //     if (!await launchUrl(_url,mode: LaunchMode.externalApplication)) {
              //       throw Exception('Could not launch $_url');
              //     }
              //      */
              //
              //     /*
              //       还有一种通过查询包名启动的方式，原神的包名为 package="com.miHoYo.Yuanshen"
              //      */
              //
              //   },
              //   child: const Text("原神，启动！"),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
