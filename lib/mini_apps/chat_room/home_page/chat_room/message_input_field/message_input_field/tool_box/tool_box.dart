import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../../../../reusable_components/snack_bar/no_permission_snack_bar.dart';
import 'album/gallery_slide.dart';

class Toolbox extends StatefulWidget {
  final Function sendMessage;
  final Function(File) sendCameraMedia;

  const Toolbox({super.key, required this.sendMessage, required this.sendCameraMedia});

  @override
  State<Toolbox> createState() => _ToolboxState();
}

class _ToolboxState extends State<Toolbox> {
  String currentState = "";

  @override
  Widget build(BuildContext context) {
    switch (currentState) {
      case "Album":
        return GallerySlide(
          sendMessage: widget.sendMessage,
        );
      default:
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: GridView.count(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            crossAxisCount: 4,
            children: [
              GestureDetector(
                onTap: () async {
                  if (await Permission.photos.request().isGranted) {
                    if (mounted) {
                      setState(() {
                        currentState = "Album";
                      });
                    }
                  } else {
                    if (mounted) {
                      getPermissionDeniedSnackBar(context, '未获得相册访问权限');
                    }
                  }
                },
                child: Column(
                  children: [
                    Icon(
                      Icons.image_rounded,
                      size: 56,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    Text(
                      "相册",
                      style: Theme.of(context).textTheme.labelLarge?.apply(color: Theme.of(context).colorScheme.onSurface),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () async {
                  if (await Permission.camera.request().isGranted) {
                    ImagePicker mediaPicker = ImagePicker();

                    if (mounted) {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) => AlertDialog(
                          content: SizedBox(
                            height: 64,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Center(
                                    child: InkWell(
                                      onTap: () async {
                                        Navigator.pop(context);
                                        XFile? image = await mediaPicker.pickImage(source: ImageSource.camera);
                                        if (image == null) {
                                          if (Platform.isAndroid) {
                                            LostDataResponse response = await mediaPicker.retrieveLostData();
                                            if (!response.isEmpty) {
                                              image = response.file;
                                            }
                                          }
                                        }
                                        if (image != null) {
                                          widget.sendCameraMedia(
                                            File.fromUri(
                                              Uri.file(image.path),
                                            ),
                                          );
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(15),
                                      child: Container(
                                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                                        child: const Column(
                                          children: [
                                            Icon(
                                              Icons.camera_outlined,
                                            ),
                                            Text("拍摄"),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const VerticalDivider(),
                                Expanded(
                                  child: Center(
                                    child: InkWell(
                                      onTap: () async {
                                        Navigator.pop(context);
                                        XFile? video = await mediaPicker.pickVideo(source: ImageSource.camera);
                                        if (video == null) {
                                          if (Platform.isAndroid) {
                                            LostDataResponse response = await mediaPicker.retrieveLostData();
                                            if (!response.isEmpty) {
                                              video = response.file;
                                            }
                                          }
                                        }
                                        if (video != null) {
                                          widget.sendCameraMedia(
                                            File.fromUri(
                                              Uri.file(video.path),
                                            ),
                                          );
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(15),
                                      child: Container(
                                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                                        child: const Column(
                                          children: [
                                            Icon(
                                              Icons.videocam_outlined,
                                            ),
                                            Text("录像"),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                  } else {
                    if (mounted) {
                      getPermissionDeniedSnackBar(context, '未获得相机使用权限');
                    }
                  }
                },
                child: Column(
                  children: [
                    Icon(
                      Icons.camera_alt_rounded,
                      size: 56,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    Text(
                      "相机",
                      style: Theme.of(context).textTheme.labelLarge?.apply(color: Theme.of(context).colorScheme.onSurface),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
    }
  }
}
