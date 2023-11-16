import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta_uni_app/bloc/bloc_manager.dart';
import 'package:meta_uni_app/bloc/recently_used_mini_apps/recently_used_mini_apps_bloc.dart';
import 'package:meta_uni_app/database/models/mini_app/brief_mini_app_information.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../database/database_manager.dart';
import 'mini_app_shortcut/mini_app_shortcut.dart';

class RecentlyUsedTile extends StatefulWidget {
  const RecentlyUsedTile({super.key});

  @override
  State<RecentlyUsedTile> createState() => _RecentlyUsedTileState();
}

class _RecentlyUsedTileState extends State<RecentlyUsedTile> {
  late Database database;
  late BriefMiniAppInformationProvider briefMiniAppInformationProvider;

  late List<MiniAppShortcut> recentlyUsedMiniApps = [];

  final List<String> readMe = [
    "要听我唱首词吗？\n\n虞美人·听雨\n宋·蒋捷\n少年听雨歌楼上，红烛昏罗帐。\n壮年听雨客舟中，江阔云低、断雁叫西风。\n而今听雨僧庐下，鬓已星星也。\n悲欢离合总无情，一任阶前、点滴到天明。\n",
    "要听我唱首词吗？\n\n蝶恋花·春景\n宋·苏轼\n花褪残红青杏小。燕子飞时，绿水人家绕。\n枝上柳绵吹又少。天涯何处无芳草。\n墙里秋千墙外道。墙外行人，墙里佳人笑。\n笑渐不闻声渐悄。多情却被无情恼。\n",
    "要听我唱首词吗？\n\n点绛唇·蹴罢秋千\n宋·李清照\n蹴罢秋千，起来慵整纤纤手。\n露浓花瘦，薄汗轻衣透。\n见客入来，袜刬金钗溜。\n和羞走，倚门回首，却把青梅嗅。\n",
    "要听我唱首词吗？\n\n一剪梅·红藕香残玉簟秋\n宋·李清照\n红藕香残玉簟秋。轻解罗裳，独上兰舟。\n云中谁寄锦书来？雁字回时，月满西楼。\n花自飘零水自流。一种相思，两处闲愁。\n此情无计可消除，才下眉头，却上心头。\n",
    "要听我吟首诗吗？\n\n集杭州俗语诗\n清·黄增\n色不迷人人自迷，情人眼里出西施。\n有缘千里来相会，三笑徒然当一痴。\n",
    "要听我吟首诗吗？\n\n题鹤林寺僧舍\n唐·李涉\n终日昏昏醉梦间，忽闻春尽强登山。\n因过竹院逢僧话，偷得浮生半日闲。\n",
    "要听我吟首诗吗？\n\n咸阳城东楼\n唐·许浑\n一上高城万里愁，蒹葭杨柳似汀洲。\n溪云初起日沉阁，山雨欲来风满楼。\n鸟下绿芜秦苑夕，蝉鸣黄叶汉宫秋。\n行人莫问当年事，故国东来渭水流。\n",
    "要听我唱首词吗？\n\n菩萨蛮·书江西造口壁\n宋·辛弃疾\n郁孤台下清江水，中间多少行人泪。西北望长安，可怜无数山。\n青山遮不住，毕竟东流去。江晚正愁余，山深闻鹧鸪。\n",
    "要听我唱首词吗？\n\n丑奴儿·书博山道中壁\n宋·辛弃疾\n少年不识愁滋味，爱上层楼。爱上层楼，为赋新词强说愁。\n而今识尽愁滋味，欲说还休。欲说还休，却道天凉好个秋。\n",
    "要听我唱首词吗？\n\n一剪梅·中秋无月\n宋·辛弃疾\n忆对中秋丹桂丛，花在杯中，月在杯中。今宵楼上一尊同，云湿纱窗，雨湿纱窗。\n浑欲乘风问化工，路也难通，信也难通。满堂唯有烛花红，杯且从容，歌且从容。\n",
    "要听我吟首诗吗？\n\n杂感\n清·黄景仁\n仙佛茫茫两未成，只知独夜不平鸣。\n风蓬飘尽悲歌气，泥絮沾来薄幸名。\n十有九人堪白眼，百无一用是书生。\n莫因诗卷愁成谶，春鸟秋虫自作声。\n",
    "想要看三行情书吗？\n\nI am\nnot happy\nbeca se...\n",
    "想要看三行情书吗？\n\n[\n陌生，爱\n)\n",
    "想要看三行情书吗？\n\n我不等你谁等你\n我不等你我等谁\n你不等我我等你\n",
    "想要看三行情书吗？\n\n怕你知道\n怕你不知道\n怕你知道装作不知道\n",
    "在想今天吃什么吗？\n\n寿司\n盖浇\n炸串\n汉堡\n炒面\n",
    "在想今天吃什么吗？\n\n火锅\n煎饼\n意面\n西瓜\n包子\n",
    "在想今天吃什么吗？\n\n榴莲\n冰棍\n面包\n蛋糕\n海鲜\n",
    "在想今天吃什么吗？\n\n啤酒鸭\n小炒肉\n狮子头\n水煮鱼\n鸡公煲\n",
    "想知道今天的音乐推荐？\n\n王菲 《暧昧》\n王菲 《百年孤寂》\n王菲 《我也不想这样》\n王菲 《容易受伤的女人》\n 王菲 《红豆》\n",
    "想知道今天的音乐推荐？\n\n孙燕姿 《匿名万岁》\n孙燕姿 《我怀念的》\n孙燕姿 《半句再见》\n 孙燕姿 《开始懂了》\n孙燕姿 《愚人的国度》\n",
    "想知道今天的音乐推荐？\n\n梁静茹 《爱久见人心》\n梁静茹 《夜夜夜夜》\n梁静茹 《可惜不是你》\n 梁静茹 《分手快乐》\n梁静茹 《勇气》\n",
    "想知道今天的音乐推荐？\n\n宇多田ヒカル 《One Last Kiss》\n",
    "想知道今天的音乐推荐？\n\n少女时代 《Gee》\n",
    "想知道今天的音乐推荐？\n\n刘若英 《成全》\n张远 《嘉宾》\n莫文蔚 《他不爱我》\n张信哲 《爱如潮水》\n阿杜 《他一定很爱你》\n",
    "想知道今天的音乐推荐？\n\n金玟岐 《岁月神偷》\n金玟岐 《珊珊》\n金玟岐 《腻味》\n金玟岐 《不要不要》\n 金玟岐 《沙发》\n",
    "想知道今天的音乐推荐？\n\n莫文蔚 《电台情歌》\n",
    "想知道今天的音乐推荐？\n\nTWICE 《Talk that Talk》\nTWICE 《CHEER UP》\nTWICE 《YES or YES》\nTWICE 《SET ME FREE》\n",
    "想知道今天的音乐推荐？\n\nEd Sheeran 《Perfect》\n",
    "想知道今天的音乐推荐？\n\nLefty Hand Cream 《恋音と雨空》\n",
    "想要获得游戏推荐？\n\n《Outer Wilds》\n",
    "想要获得动画推荐？\n\n《比宇宙更远的地方》\n《BanG Dream! It's MyGO!!!!!》\n",
    "想要看我的发疯文学？\n\n啊，抱歉，做不到。\n",
    "想要看我发卖萌颜文字？\n\n啊，抱歉，做不到。\n",
  ];
  late String text;

  _performInitActions() async {
    await initRecentlyUsedMiniApps();
    setState(() {});
  }

  initRecentlyUsedMiniApps() async {
    database = await DatabaseManager().getDatabase;
    briefMiniAppInformationProvider = BriefMiniAppInformationProvider(database);

    List<BriefMiniAppInformation> infoList = await briefMiniAppInformationProvider.getRecentlyOpenedList();

    recentlyUsedMiniApps = [];
    for (var info in infoList) {
      recentlyUsedMiniApps.add(MiniAppShortcut(info: info));
    }
  }

  late Future<dynamic> performInitActions;

  @override
  void initState() {
    super.initState();
    text = readMe[Random().nextInt(readMe.length)];
    performInitActions = _performInitActions();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RecentlyUsedMiniAppsCubit>.value(
      value: BlocManager().recentlyUsedMiniAppsCubit,
      child: BlocListener<RecentlyUsedMiniAppsCubit, BriefMiniAppInformation?>(
        listener: (context, info) {
          _performInitActions();
        },
        child: Column(
          children: [
            ListTile(
              leading: Text(
                '最近使用',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              trailing: IconButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/discover/warehouse/search');
                },
                icon: Icon(
                  Icons.search_outlined,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
            recentlyUsedMiniApps.isEmpty
                ? Column(
                    children: [
                      const Icon(
                        Icons.flutter_dash_outlined,
                      ),
                      SelectableText("嘿，我要如何才能让你驻足？\n$text",textAlign: TextAlign.center,),
                    ],
                  )
                : ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: GridView.count(
                      physics: const NeverScrollableScrollPhysics(),
                      primary: false,
                      padding: const EdgeInsets.all(0),
                      shrinkWrap: true,
                      crossAxisSpacing: 5,
                      mainAxisSpacing: 0,
                      crossAxisCount: 4,
                      children: recentlyUsedMiniApps,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
