import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../../../models/dio_model.dart';
import '../../../reusable_components/media_store/media_store.dart';
import '../../../reusable_components/snack_bar/network_error_snack_bar.dart';
import '../../../reusable_components/snack_bar/normal_snack_bar.dart';

class ViewImagePage extends StatefulWidget {
  const ViewImagePage({super.key});

  @override
  State<ViewImagePage> createState() => _ViewImagePageState();
}

class _ViewImagePageState extends State<ViewImagePage> {
  late String image;
  late String heroTag;
  final DioModel dioModel = DioModel();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    var args = ModalRoute.of(context)!.settings.arguments as Map;
    heroTag = args["heroTag"];
    image = args["image"];
  }

  showOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 228),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 4,
                    width: 32,
                    margin: const EdgeInsets.fromLTRB(0, 22, 0, 22),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4),
                      borderRadius: const BorderRadius.all(
                        Radius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: ListTile.divideTiles(
                      context: context,
                      tiles: [
                        SizedBox(
                          height: 60,
                          child: InkWell(
                            onTap: () {},
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('发送给好友'),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 60,
                          child: InkWell(
                            onTap: () async {
                              try{
                                //从网络获取图片
                                final response = await dioModel.dio.get(image,options: Options(receiveTimeout:1000,responseType: ResponseType.bytes));
                                //设定图片前缀
                                //final prefix = DateTime.now().toString().substring(0,19).replaceAll(' ', '_');
                                //设定图片名
                                //final imageName = '${prefix}_${path.basename(image)}';
                                final imageName = path.basename(image);
                                //使用临时保存目录将图片临时保存
                                final tempDir = await getTemporaryDirectory();
                                final localPath = path.join(tempDir.path, imageName);
                                final imageFile = File(localPath);
                                await imageFile.writeAsBytes(response.data);
                                //调用Android原生API，将图片存储到相册
                                final mediaStore = MediaStore();
                                await mediaStore.addImage(file: imageFile, name: imageName);
                                //删除临时保存的图片
                                await imageFile.delete();
                                if(mounted){
                                  Navigator.pop(context);
                                  getNormalSnackBar(context, '保存成功');
                                }
                              }catch(e){
                                Navigator.pop(context);
                                getNetworkErrorSnackBar(context);
                              }
                            },
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('保存到手机'),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 60,
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('取消'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
      },
      child: Stack(
        children: [
          Scaffold(
            body: GestureDetector(
              onLongPress: () {
                showOptions();
              },
              child: Center(
                child: Hero(
                  tag: heroTag,
                  child: CachedNetworkImage(
                    fadeInDuration: const Duration(milliseconds: 800),
                    fadeOutDuration: const Duration(milliseconds: 200),
                    placeholder: (context, url) => const CupertinoActivityIndicator(),
                    imageUrl: image,
                    errorWidget: (context, url, error) => const Icon(Icons.error_outline),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 28,
            right: 0,
            child: IconButton(
              onPressed: () {
                showOptions();
              },
              icon: Icon(
                Icons.more_horiz_outlined,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
