import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:meta_uni_app/home_page/chats/contacts/search/add_friend_request_page.dart';
import 'package:meta_uni_app/home_page/chats/contacts/search/user_search_result_page.dart';
import 'package:photo_manager/photo_manager.dart';
import 'home_page/chats/contacts/contacts_page.dart';
import 'home_page/chats/contacts/search/contacts_search_page.dart';
import 'home_page/chats/message/friend/message_page.dart';
import 'home_page/chats/message/system/message_page.dart';
import 'home_page/chats/search/search_page.dart';
import 'home_page/discover/warehouse/mini_app_introduction/client_app_introduction_page.dart';
import 'home_page/discover/warehouse/mini_app_introduction/web_app_introduction_page.dart';
import 'home_page/discover/warehouse/search/search_page.dart';
import 'home_page/home_page.dart';
import 'home_page/me/settings/settings_page.dart';
import 'home_page/me/settings/subpages/change_passwrod_page.dart';
import 'home_page/me/settings/subpages/change_seed_color_page.dart';
import 'home_page/reusable_components/profile/user_profile_page.dart';
import 'login_page/password/password_page.dart';
import 'mini_apps/chat_room/home_page/home_page.dart';
import 'mini_apps/flea_market/home_page/home_page.dart';
import 'mini_apps/seek_partner/home_page/home_page.dart';
import 'mini_apps/wall_sticker/home_page/home_page.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page/account/account_page.dart';
import 'mini_apps/wall_sticker/home_page/reusable_components/sticker/details/sticker_details_page.dart';
import 'models/dio_model.dart';
import 'models/theme_model.dart';
import 'not_found_page/not_found_page.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeModel>(
          create: (context) => ThemeModel(),
        ),
      ],
      child: const MetaUni(),
    ),
  );
}

class MetaUni extends StatefulWidget {
  const MetaUni({super.key});

  @override
  State<MetaUni> createState() => _MetaUni();
}

class _MetaUni extends State<MetaUni> {
  final DioModel dioModel = DioModel();
  late bool _hasLogin;
  late Future<dynamic> checkLoginStatus;

  _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();

    final String? jwt = prefs.getString('jwt');
    final int? uuid = prefs.getInt('uuid');

    if (jwt == null) {
      _hasLogin = false;
    } else {
      try {
        Response response;
        response = await dioModel.dio.get(
          '/metaUni/userAPI/login/check',
          options: Options(
            headers: {
              'JWT': jwt,
              'UUID': uuid,
            },
          ),
        );
        switch (response.data['code']) {
          case 0:
            _hasLogin = true;
            break;
          case 1:
          //Message:"用户Token已过期，请重新登录"
          case 2:
            //Message:"账号在另外一台设备登录，若并非您的操作，请及时联系客服反馈情况"
            await prefs.remove('jwt');
            await prefs.remove('uuid');
            _hasLogin = false;
            break;
          default:
            _hasLogin = true;
        }
      } catch (e) {
        _hasLogin = true;
      } finally {
        setState(() {});
      }
    }
  }

  @override
  void initState() {
    super.initState();

    PhotoManager.clearFileCache();
    checkLoginStatus = _checkLoginStatus();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      supportedLocales: const [
        Locale("zh", "CH"),
        Locale("en", "US"),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        platform: TargetPlatform.iOS,
        useMaterial3: true,
        //fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(seedColor: Color(Provider.of<ThemeModel>(context).seedColor), brightness: Provider.of<ThemeModel>(context).isDarkMode ? Brightness.dark : Brightness.light),
      ),
      routes: {
        '/account': (context) => const AccountPage(),
        '/password': (context) => const PasswordPage(),
        '/home': (context) => const HomePage(),
        '/chats/search': (context) => const ChatsSearchPage(),
        '/chats/message/friend': (context) => const FriendMessagePage(),
        '/chats/message/system': (context) => const SystemMessagePage(),
        '/contacts': (context) => const ContactsPage(),
        '/contacts/search': (context) => const ContactsSearchPage(),
        '/contacts/search/result/user': (context) => const UserSearchResultPage(),
        '/contacts/add/friend': (context) => const AddFriendRequestPage(),
        '/discover/warehouse/search': (context) => const DiscoverWarehouseSearchPage(),
        '/discover/warehouse/clientApp/introduction': (context) => const ClientAppIntroductionPage(),
        '/discover/warehouse/webApp/introduction': (context) => const WebAppIntroductionPage(),
        '/user/profile': (context) => const UserProfilePage(),
        '/user/profile/routeFromFriendMessagePage': (context) => const UserProfilePage(),
        '/settings': (context) => const SettingsPage(),
        '/settings/seedColor': (context) => const ChangeSeedColorPage(),
        '/settings/changePassword': (context) => const ChangePasswordPage(),

        //以下是miniApp相关页面
        '/miniApps/wallSticker': (context) => const WallStickerHomePage(),
        '/miniApps/chatRoom': (context) => const ChatRoomHomePage(),
        '/miniApps/seekPartner': (context) => const SeekPartnerHomePage(),
        '/miniApps/fleaMarket': (context) => const FleaMarketHomePage(),
      },
      onGenerateRoute: (RouteSettings settings) {
        final name = settings.name;
        if (name != null) {
          if (name.startsWith('/miniApps/wallSticker/')) {
            final jumpUrl = name.split('/miniApps/wallSticker/')[1];
            if (jumpUrl.startsWith('stickerDetailsPage/')) {
              return MaterialPageRoute(
                builder: (context) {
                  return StickerDetailsPage(
                    id: jumpUrl.split('stickerDetailsPage/')[1],
                  );
                },
                settings: settings,
              );
            }
          }
        }
        return null;
      },
      onUnknownRoute: (RouteSettings setting) => MaterialPageRoute(builder: (context) => const NotFoundPage()),
      home: FutureBuilder(
        future: checkLoginStatus,
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
              return const LoadingPage();
            case ConnectionState.active:
              return const LoadingPage();
            case ConnectionState.waiting:
              return const LoadingPage();
            case ConnectionState.done:
              if (snapshot.hasError) {
                return const LoadingPage();
              }
              return _hasLogin ? const HomePage() : const AccountPage();
            default:
              return const LoadingPage();
          }
        },
      ),
    );
  }
}

class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: CupertinoActivityIndicator(),
        ),
      ),
    );
  }
}
