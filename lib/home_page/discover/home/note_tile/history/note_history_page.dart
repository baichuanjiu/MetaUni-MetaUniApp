import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:meta_uni_app/home_page/discover/home/note_tile/note_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../models/dio_model.dart';
import '../../../../../reusable_components/logout/logout.dart';
import '../../../../../reusable_components/snack_bar/network_error_snack_bar.dart';
import '../../../../../reusable_components/snack_bar/normal_snack_bar.dart';
import '../models/note.dart';

class NoteHistoryPage extends StatefulWidget {
  const NoteHistoryPage({super.key});

  @override
  State<NoteHistoryPage> createState() => _NoteHistoryPageState();
}

class _NoteHistoryPageState extends State<NoteHistoryPage> {
  late List<Note> dataList;

  late Future<dynamic> init;

  _getAllNotes() async {
    dataList = [];
    DioModel dioModel = DioModel();

    final prefs = await SharedPreferences.getInstance();

    final String? jwt = prefs.getString('jwt');
    final int? uuid = prefs.getInt('uuid');

    try {
      Response response;
      response = await dioModel.dio.get(
        '/metaUni/versionAPI/note/all',
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 0:
          List<dynamic> allNotes = response.data['data']['dataList'];
          for (var note in allNotes) {
            dataList.add(Note.fromJson(note));
          }
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
    init = _getAllNotes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("历史笔记"),
        centerTitle: true,
      ),
      body: FutureBuilder(
        future: init,
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
              return const Center(
                child: CupertinoActivityIndicator(),
              );
            case ConnectionState.active:
              return const Center(
                child: CupertinoActivityIndicator(),
              );
            case ConnectionState.waiting:
              return const Center(
                child: CupertinoActivityIndicator(),
              );
            case ConnectionState.done:
              if (snapshot.hasError) {
                return const Center(
                  child: CupertinoActivityIndicator(),
                );
              }
              return CustomScrollView(
                slivers: [
                  SliverList.separated(
                    itemBuilder: (context, index) {
                      return NoteTile(note: dataList[index]);
                    },
                    itemCount: dataList.length,
                    separatorBuilder: (BuildContext context, int index) {
                      return const Divider();
                    },
                  ),
                ],
              );
            default:
              return const Center(
                child: CupertinoActivityIndicator(),
              );
          }
        },
      ),
    );
  }
}
