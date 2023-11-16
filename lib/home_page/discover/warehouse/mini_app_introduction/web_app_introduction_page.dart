import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:meta_uni_app/home_page/discover/warehouse/mini_app_introduction/reusable_components/preview/introduction_preview.dart';
import 'package:meta_uni_app/home_page/discover/warehouse/mini_app_introduction/reusable_components/ratings_and_reviews/ratings_and_reviews.dart';
import 'package:meta_uni_app/home_page/discover/warehouse/mini_app_introduction/reusable_components/readme/introduction_readme.dart';
import 'package:meta_uni_app/home_page/discover/warehouse/mini_app_introduction/reusable_components/stars/stars.dart';
import 'package:meta_uni_app/home_page/discover/warehouse/models/mini_app_information.dart';
import 'package:meta_uni_app/reusable_components/open_mini_app/open_mini_app.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../models/dio_model.dart';
import '../../../../reusable_components/formatter/number_formatter/number_formatter.dart';
import '../../../../reusable_components/logout/logout.dart';
import '../../../../reusable_components/snack_bar/network_error_snack_bar.dart';
import '../../../../reusable_components/snack_bar/normal_snack_bar.dart';
import '../models/web_app.dart';
import 'models/mini_app_introduction.dart';
import 'models/mini_app_review.dart';
import 'reusable_components/guide/introduction_guide.dart';

class WebAppIntroductionPage extends StatefulWidget {
  const WebAppIntroductionPage({super.key});

  @override
  State<WebAppIntroductionPage> createState() => _WebAppIntroductionPageState();
}

class _WebAppIntroductionPageState extends State<WebAppIntroductionPage> with TickerProviderStateMixin {
  late MiniAppInformation miniAppInformation;
  late WebApp webApp;
  late MiniAppIntroduction miniAppIntroduction;
  bool isReady = false;
  MiniAppReview? latestReview;
  late int totalNumberOfRatingPeople = 0;
  late String totalNumberOfRatingPeopleString = "0";
  late int averageOfStars = 0;
  late String averageOfRatingsString = "0.0";
  late String trendValueString = "0.0";
  List<Widget> preview = [];

  final ScrollController _controller = ScrollController();
  bool isCollapsed = false;
  bool isShowingTitle = false;
  late IconButton backUpButtonWithOpacity = IconButton(
    onPressed: () {
      Navigator.pop(context);
    },
    icon: CircleAvatar(
      backgroundColor: Theme.of(context).colorScheme.background.withOpacity(0.8),
      child: Icon(
        Icons.arrow_back_ios_new_outlined,
        color: Theme.of(context).colorScheme.onBackground,
      ),
    ),
  );
  late IconButton backUpButton = IconButton(
    onPressed: () {
      Navigator.pop(context);
    },
    icon: const Icon(
      Icons.arrow_back_ios_new_outlined,
    ),
  );
  late FilledButton startButton = FilledButton.tonal(
    onPressed: () {
      openWebApp(webApp.id, webApp.url, webApp.name, context);
    },
    child: const Text("开始使用"),
  );
  late Widget _leading = backUpButtonWithOpacity;
  late final Widget _title = FadeTransition(
    opacity: fadeInAnimation,
    child: CachedNetworkImage(
      fadeInDuration: const Duration(milliseconds: 800),
      fadeOutDuration: const Duration(milliseconds: 200),
      placeholder: (context, url) => const CupertinoActivityIndicator(),
      imageUrl: miniAppInformation.avatar,
      imageBuilder: (context, imageProvider) => SizedBox(
        width: 42,
        height: 42,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image(
            image: imageProvider,
          ),
        ),
      ),
      errorWidget: (context, url, error) => const Icon(Icons.error_outline),
    ),
  );
  late final List<Widget> _actions = [
    FadeTransition(
      opacity: fadeInAnimation,
      child: Container(
        padding: const EdgeInsets.fromLTRB(0, 0, 16, 0),
        child: startButton,
      ),
    ),
  ];

  late AnimationController fadeOutAnimationController;
  late Animation<double> fadeOutAnimation;

  late AnimationController fadeInAnimationController;
  late Animation<double> fadeInAnimation;

  late Future<dynamic> init;
  final DioModel dioModel = DioModel();

  _init() async {
    final prefs = await SharedPreferences.getInstance();

    final String? jwt = prefs.getString('jwt');
    final int? uuid = prefs.getInt('uuid');

    try {
      Response response;
      response = await dioModel.dio.get(
        '/metaUni/miniAppAPI/miniApp/introduction/webApp/${miniAppInformation.id}',
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 0:
          webApp = WebApp.fromJson(response.data['data']['webApp']);
          miniAppIntroduction = MiniAppIntroduction.fromJson(response.data['data']['miniAppIntroduction']);
          if (response.data['data']['latestReview'] != null) {
            latestReview = MiniAppReview.fromJson(response.data['data']['latestReview']);
          }

          int totalNumberOfStars = 0;
          miniAppIntroduction.stars.asMap().forEach((index, value) {
            totalNumberOfRatingPeople += value;
            totalNumberOfStars += (index + 1) * value;
          });
          if (totalNumberOfRatingPeople == 0) {
            averageOfStars = 0;
            averageOfRatingsString = "0.0";
            totalNumberOfRatingPeopleString = "0";
          } else {
            double averageOfRatings = totalNumberOfStars / totalNumberOfRatingPeople;
            averageOfStars = averageOfRatings.round();
            averageOfRatingsString = getFormattedDouble(averageOfRatings);
            totalNumberOfRatingPeopleString = getFormattedInt(totalNumberOfRatingPeople);
          }

          trendValueString = getFormattedDouble(miniAppInformation.trendValue);

          for (int i = 0; i < miniAppIntroduction.preview.length; i++) {
            if (i != miniAppIntroduction.preview.length - 1) {
              preview.add(
                CachedNetworkImage(
                  fadeInDuration: const Duration(milliseconds: 800),
                  fadeOutDuration: const Duration(milliseconds: 200),
                  placeholder: (context, url) => const CupertinoActivityIndicator(),
                  imageUrl: miniAppIntroduction.preview[i],
                  imageBuilder: (context, imageProvider) => ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image(
                      image: imageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
              preview.add(
                Container(
                  width: 10,
                ),
              );
            } else {
              preview.add(
                CachedNetworkImage(
                  fadeInDuration: const Duration(milliseconds: 800),
                  fadeOutDuration: const Duration(milliseconds: 200),
                  placeholder: (context, url) => const CupertinoActivityIndicator(),
                  imageUrl: miniAppIntroduction.preview[i],
                  imageBuilder: (context, imageProvider) => ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image(
                      image: imageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            }
          }

          setState((){
            isReady = true;
          });
          break;
        case 1:
          //Message:"使用了无效的JWT，请重新登录"
          if (mounted) {
            getNormalSnackBar(context, response.data['message']);
            logout(context);
          }
          break;
        case 2:
          //Message:"您正在尝试获取不存在的MiniApp介绍"
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

  @override
  void initState() {
    super.initState();

    init = _init();

    fadeOutAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    fadeOutAnimation = Tween(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: fadeOutAnimationController, curve: Curves.easeOut),
    );

    fadeInAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    fadeInAnimation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: fadeInAnimationController, curve: Curves.easeIn),
    );

    _controller.addListener(
      () {
        if (isCollapsed && _controller.position.extentBefore < 144) {
          isCollapsed = false;
          _leading = backUpButtonWithOpacity;
          setState(() {});
        }

        if (!isCollapsed && _controller.position.extentBefore >= 144) {
          isCollapsed = true;
          _leading = backUpButton;
          setState(() {});
        }

        if (isShowingTitle && _controller.position.extentBefore < 270) {
          isShowingTitle = false;
          fadeInAnimationController.reverse();
          fadeOutAnimationController.reverse();
          setState(() {});
        }

        if (!isShowingTitle && _controller.position.extentBefore >= 270) {
          isShowingTitle = true;
          fadeInAnimationController.forward();
          fadeOutAnimationController.forward();
          setState(() {});
        }
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    miniAppInformation = ModalRoute.of(context)!.settings.arguments as MiniAppInformation;
  }

  @override
  void dispose() {
    _controller.dispose();
    fadeOutAnimationController.dispose();
    fadeInAnimationController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: init,
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
            return const Scaffold(
              body: Center(
                child: CupertinoActivityIndicator(),
              ),
            );
          case ConnectionState.active:
            return const Scaffold(
              body: Center(
                child: CupertinoActivityIndicator(),
              ),
            );
          case ConnectionState.waiting:
            return const Scaffold(
              body: Center(
                child: CupertinoActivityIndicator(),
              ),
            );
          case ConnectionState.done:
            if (snapshot.hasError) {
              return const Scaffold(
                body: Center(
                  child: CupertinoActivityIndicator(),
                ),
              );
            }
            if(!isReady)
            {
              return const Scaffold(
                body: Center(
                  child: CupertinoActivityIndicator(),
                ),
              );
            }
            return Scaffold(
              body: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                controller: _controller,
                slivers: [
                  SliverAppBar(
                    title: _title,
                    expandedHeight: 210,
                    floating: false,
                    pinned: true,
                    snap: false,
                    stretch: true,
                    leading: _leading,
                    actions: _actions,
                    flexibleSpace: FlexibleSpaceBar(
                      background: CachedNetworkImage(
                        fadeInDuration: const Duration(milliseconds: 800),
                        fadeOutDuration: const Duration(milliseconds: 200),
                        placeholder: (context, url) => const CupertinoActivityIndicator(),
                        imageUrl: miniAppInformation.backgroundImage,
                        imageBuilder: (context, imageProvider) => ClipRRect(
                          child: Image(
                            image: imageProvider,
                            fit: BoxFit.cover,
                          ),
                        ),
                        errorWidget: (context, url, error) => const Icon(Icons.error_outline),
                      ),
                      collapseMode: CollapseMode.parallax,
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    sliver: SliverToBoxAdapter(
                      child: FadeTransition(
                        opacity: fadeOutAnimation,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CachedNetworkImage(
                              fadeInDuration: const Duration(milliseconds: 800),
                              fadeOutDuration: const Duration(milliseconds: 200),
                              placeholder: (context, url) => const CupertinoActivityIndicator(),
                              imageUrl: miniAppInformation.avatar,
                              imageBuilder: (context, imageProvider) => SizedBox(
                                width: 114,
                                height: 114,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image(
                                    image: imageProvider,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => const Icon(Icons.error_outline),
                            ),
                            Container(
                              width: 16,
                            ),
                            Expanded(
                              child: SizedBox(
                                height: 118,
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          miniAppInformation.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context).textTheme.titleLarge,
                                        ),
                                        Text(
                                          miniAppInformation.description,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context).textTheme.labelLarge?.apply(color: Theme.of(context).colorScheme.outline),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            startButton,
                                          ],
                                        ),
                                        IconButton(
                                          onPressed: () {},
                                          tooltip: "举报",
                                          icon: Icon(
                                            Icons.report_outlined,
                                            color: Theme.of(context).colorScheme.secondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SliverDivider(),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    sliver: SliverToBoxAdapter(
                      child: SizedBox(
                        height: 80,
                        child: GridView.count(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          scrollDirection: Axis.horizontal,
                          mainAxisSpacing: 20,
                          crossAxisCount: 1,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "$totalNumberOfRatingPeopleString 评分",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelLarge?.apply(color: Theme.of(context).colorScheme.outline),
                                ),
                                Text(
                                  averageOfRatingsString,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleLarge?.apply(color: Theme.of(context).colorScheme.outline),
                                ),
                                Column(
                                  children: [
                                    Stars(color: Theme.of(context).colorScheme.outline, numberOfStars: averageOfStars),
                                    Container(
                                      height: 4,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "近期热度",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelLarge?.apply(color: Theme.of(context).colorScheme.outline),
                                ),
                                Icon(
                                  Icons.local_fire_department_outlined,
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                                Text(
                                  trendValueString,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelLarge?.apply(color: Theme.of(context).colorScheme.outline),
                                ),
                              ],
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "开发者",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelLarge?.apply(color: Theme.of(context).colorScheme.outline),
                                ),
                                Icon(
                                  Icons.verified_outlined,
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                                Text(
                                  miniAppIntroduction.developer,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelLarge?.apply(color: Theme.of(context).colorScheme.outline),
                                ),
                              ],
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "应用类型",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelLarge?.apply(color: Theme.of(context).colorScheme.outline),
                                ),
                                Icon(
                                  Icons.public_outlined,
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                                Text(
                                  "网页应用",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelLarge?.apply(color: Theme.of(context).colorScheme.outline),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SliverDivider(),
                  IntroductionPreview(
                    preview: preview,
                  ),
                  const SliverDivider(),
                  IntroductionGuide(
                    guide: miniAppIntroduction.guide,
                  ),
                  const SliverDivider(),
                  RatingsAndReviews(
                      latestReview: latestReview,
                      averageOfRatingsString: averageOfRatingsString,
                      totalNumberOfRatingPeople: totalNumberOfRatingPeople,
                      totalNumberOfRatingPeopleString: totalNumberOfRatingPeopleString,
                      stars: miniAppIntroduction.stars),
                  const SliverDivider(),
                  IntroductionReadme(
                    readme: miniAppIntroduction.readme,
                  ),
                ],
              ),
            );
          default:
            return const Scaffold(
              body: Center(
                child: CupertinoActivityIndicator(),
              ),
            );
        }
      },
    );
  }
}

class SliverDivider extends StatelessWidget {
  const SliverDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const SliverPadding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
      sliver: SliverToBoxAdapter(
        child: Divider(),
      ),
    );
  }
}
