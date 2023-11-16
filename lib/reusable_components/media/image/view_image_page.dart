import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../../models/dio_model.dart';
import '../../media_store/media_store.dart';
import '../../snack_bar/network_error_snack_bar.dart';
import '../../snack_bar/normal_snack_bar.dart';

class ViewImagePage extends StatefulWidget {
  final String imageURL;
  final String heroTag;
  final bool canShare;
  final bool shouldShowMenu;
  final Function changeOpacity;

  const ViewImagePage({super.key, required this.imageURL, required this.heroTag, this.canShare = false, required this.shouldShowMenu, required this.changeOpacity});

  @override
  State<ViewImagePage> createState() => _ViewImagePageState();
}

class _ViewImagePageState extends State<ViewImagePage> {
  final DioModel dioModel = DioModel();
  late List<Widget> tiles = [];

  @override
  void initState() {
    super.initState();

    tiles = [];
    if (widget.canShare) {
      tiles.add(
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
      );
    }
    tiles.add(
      SizedBox(
        height: 60,
        child: InkWell(
          onTap: () async {
            try {
              //从网络获取图片
              final response = await dioModel.dio.get(widget.imageURL, options: Options(receiveTimeout: const Duration(seconds: 10), responseType: ResponseType.bytes));
              //设定图片前缀
              //final prefix = DateTime.now().toString().substring(0,19).replaceAll(' ', '_');
              //设定图片名
              //final imageName = '${prefix}_${path.basename(image)}';
              final imageName = path.basename(widget.imageURL);
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
              if (mounted) {
                Navigator.pop(context);
                getNormalSnackBar(context, '保存成功');
              }
            } catch (e) {
              if (mounted) {
                Navigator.pop(context);
                getNetworkErrorSnackBar(context);
              }
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
    );
    tiles.add(
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
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  showOptions() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: ListTile.divideTiles(
              context: context,
              tiles: tiles,
            ).toList(),
          ),
        );
      },
    );
  }

  Offset dragStart = const Offset(0, 0);
  Offset dragDelta = const Offset(0, 0);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (context, constraints) => Stack(
              children: [
                Positioned(
                  left: dragDelta.dx == 0
                      ? null
                      : dragDelta.dx.isNegative
                          ? null
                          : dragDelta.dx,
                  top: dragDelta.dy == 0
                      ? null
                      : dragDelta.dy.isNegative
                          ? null
                          : dragDelta.dy,
                  right: dragDelta.dx == 0
                      ? null
                      : dragDelta.dx.isNegative
                          ? -dragDelta.dx
                          : null,
                  bottom: dragDelta.dy == 0
                      ? null
                      : dragDelta.dy.isNegative
                          ? -dragDelta.dy
                          : null,
                  height: constraints.maxHeight,
                  width: constraints.maxWidth,
                  child: SafeArea(
                    child: Center(
                      child: GestureDetector(
                        onLongPress: () {
                          showOptions();
                        },
                        onVerticalDragStart: (details) {
                          dragStart = details.localPosition;
                        },
                        onVerticalDragUpdate: (details) {
                          setState(() {
                            dragDelta = details.localPosition - dragStart;
                            widget.changeOpacity((0.5 - dragDelta.distanceSquared / 15000).isNegative ? 0.5 : (1.0 - dragDelta.distanceSquared / 15000));
                          });
                        },
                        onVerticalDragEnd: (details) {
                          if (dragDelta.distanceSquared >= 15000 || details.velocity.pixelsPerSecond.dy.abs() >= 100) {
                            Navigator.maybePop(context);
                          } else {
                            widget.changeOpacity(1.0);
                            setState(() {
                              dragDelta = const Offset(0, 0);
                            });
                          }
                        },
                        child: SingleChildScrollView(
                          child: Hero(
                            tag: widget.heroTag,
                            child: CachedNetworkImage(
                              fadeInDuration: const Duration(milliseconds: 800),
                              fadeOutDuration: const Duration(milliseconds: 200),
                              placeholder: (context, url) => const CupertinoActivityIndicator(),
                              imageUrl: widget.imageURL,
                              errorWidget: (context, url, error) => const Icon(Icons.error_outline),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                widget.shouldShowMenu
                    ? Positioned(
                        top: 5,
                        left: 10,
                        child: SafeArea(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.maybePop(context);
                            },
                            child: CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                              radius: 15,
                              child: Icon(
                                Icons.arrow_back_ios_outlined,
                                color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      )
                    : Container(),
                widget.shouldShowMenu
                    ? Positioned(
                        top: 5,
                        right: 10,
                        child: SafeArea(
                          child: GestureDetector(
                            onTap: () {
                              showOptions();
                            },
                            child: CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                              radius: 15,
                              child: Icon(
                                Icons.more_horiz_outlined,
                                color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      )
                    : Container(),
              ],
            ));
  }
}
