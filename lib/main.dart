import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'home_page/chats/contacts/contacts_page.dart';
import 'home_page/chats/message/friend/message_page.dart';
import 'home_page/chats/search/search_page.dart';
import 'home_page/discover/warehouse/search/search_page.dart';
import 'home_page/home_page.dart';
import 'home_page/me/settings/settings_page.dart';
import 'home_page/me/settings/subpages/change_seed_color_page.dart';
import 'home_page/reusable_components/image/view_image_page.dart';
import 'home_page/reusable_components/profile/user_profile_page.dart';
import 'login_page/password/password_page.dart';
import 'reusable_components/snack_bar/network_error_snack_bar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_page/account/account_page.dart';
import 'models/dio_model.dart';
import 'models/theme_model.dart';
import 'not_found_page/not_found_page.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
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
          options: Options(headers: {
            'JWT': jwt,
            'UUID': uuid,
          }),
        );
        switch (response.data['code']) {
          case 1:
          //Message:"用户Token已过期，请重新登录"
            await prefs.remove('jwt');
            await prefs.remove('uuid');
            _hasLogin = false;
            break;
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
        if (mounted) {
          getNetworkErrorSnackBar(context);
        }
      }
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    checkLoginStatus = _checkLoginStatus();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
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
            // if (snapshot.hasError) {
            //   return const LoadingPage();
            // }
              return MaterialApp(
                supportedLocales: const [
                  Locale("zh", "CH"),
                  //Locale("en", "US"),
                ],
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                theme: ThemeData(
                  platform: TargetPlatform.iOS,
                  useMaterial3: true,
                  fontFamily: 'Roboto',
                  colorScheme:
                  ColorScheme.fromSeed(seedColor: Color(Provider.of<ThemeModel>(context).seedColor), brightness: Provider.of<ThemeModel>(context).isDarkMode ? Brightness.dark : Brightness.light),
                ),
                routes: {
                  '/account': (context) => const AccountPage(),
                  '/password': (context) => const PasswordPage(),
                  '/home': (context) => const HomePage(),
                  '/chats/search': (context) => const ChatsSearchPage(),
                  '/chats/message/friend': (context) => const FriendMessagePage(),
                  '/contacts': (context) => const ContactsPage(),
                  '/discover/warehouse/search': (context) => const DiscoverWarehouseSearchPage(),
                  '/user/profile': (context) => const UserProfilePage(),
                  '/settings': (context) => const SettingsPage(),
                  '/settings/seedColor': (context) => const ChangeSeedColorPage(),
                  '/view/image': (context) => const ViewImagePage(),
                },
                onUnknownRoute: (RouteSettings setting) => MaterialPageRoute(builder: (context) => const NotFoundPage()),
                home: _hasLogin ? const HomePage() : const AccountPage(),
              );
            default:
              return const LoadingPage();
          }
        });
  }
}

class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        platform: TargetPlatform.iOS,
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(seedColor: Color(Provider.of<ThemeModel>(context).seedColor), brightness: Provider.of<ThemeModel>(context).isDarkMode ? Brightness.dark : Brightness.light),
      ),
      home: const Scaffold(
        body: SafeArea(
          child: Center(
            child: CupertinoActivityIndicator(),
          ),
        ),
      ),
    );
  }
}
