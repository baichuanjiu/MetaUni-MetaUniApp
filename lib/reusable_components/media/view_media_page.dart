import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:meta_uni_app/reusable_components/media/video/view_video_page.dart';
import 'image/view_image_page.dart';
import 'models/view_media_metadata.dart';

class ViewMediaPage extends StatefulWidget {
  final List<ViewMediaMetadata> dataList;
  final int initialPage;
  final bool canShare;

  const ViewMediaPage({super.key, required this.dataList, required this.initialPage, this.canShare = false});

  @override
  State<ViewMediaPage> createState() => _ViewMediaPageState();
}

class _ViewMediaPageState extends State<ViewMediaPage> {
  late bool shouldShowMenu = true;
  late PageController pageController = PageController(initialPage: widget.initialPage);
  late List<Widget> widgetList = [];

  late bool firstBuild = true;
  late Orientation orientation = MediaQuery.of(context).orientation;
  late double opacity = 1.0;

  void changeOpacity(double newValue) {
    setState(() {
      shouldShowMenu = false;
      opacity = newValue;
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);//隐藏状态栏，底部按钮栏
    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.bottom]);//隐藏状态栏，保留底部按钮栏
    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);//显示状态栏、底部按钮栏
    //
    // SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle( //设置状态栏透明
    //   statusBarColor: Colors.transparent,
    // ));
    if (firstBuild) {
      Future.delayed(const Duration(milliseconds: 500)).then((_) => {SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light)});
      orientation;
      firstBuild = false;
    }
    widgetList = [];
    for (var data in widget.dataList) {
      if (data.type == "image") {
        widgetList.add(
          ViewImagePage(
            imageURL: data.imageURL!,
            heroTag: data.heroTag,
            canShare: widget.canShare,
            shouldShowMenu: shouldShowMenu,
            changeOpacity: changeOpacity,
          ),
        );
      } else if (data.type == "video") {
        widgetList.add(
          ViewVideoPage(
            controller: data.videoPlayerController!,
            heroTag: data.heroTag,
            shouldShowMenu: shouldShowMenu,
            changeOpacity: changeOpacity,
          ),
        );
      }
    }
    return WillPopScope(
      onWillPop: () async {
        Orientation currentOrientation = MediaQuery.of(context).orientation;
        if (currentOrientation != orientation) {
          if (currentOrientation == Orientation.portrait) {
            SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.portraitUp]);
          } else {
            SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.landscapeLeft]);
          }
        }
        Navigator.of(context).pop();
        return true;
      },
      child: GestureDetector(
        onTap: () {
          setState(() {
            shouldShowMenu = !shouldShowMenu;
          });
        },
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.shadow.withOpacity(opacity),
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(0.0),
            child: AppBar(
              backgroundColor: Theme.of(context).colorScheme.shadow.withOpacity(0),
            ),
          ),
          body: PageView(
            onPageChanged: (pageNumber) {
              for (var data in widget.dataList) {
                if (data.type == "video") {
                  data.videoPlayerController!.pause();
                }
              }
            },
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            controller: pageController,
            //allowImplicitScrolling: true,
            children: widgetList,
          ),
        ),
      ),
    );
  }
}
