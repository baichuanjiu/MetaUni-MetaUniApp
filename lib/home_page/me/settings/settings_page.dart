import 'package:flutter/material.dart';
import 'package:meta_uni_app/reusable_components/check_version/version_manager.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/theme_model.dart';
import '../../../reusable_components/logout/logout.dart';
import '../../discover/home/note_tile/history/note_history_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_ios_new_outlined),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SettingsGroup1(),
            const SettingsGroup2(),
            const SettingsGroup3(),
            const SettingsGroup4(),
            ElevatedButton(
              onPressed: () {
                logout(context);
              },
              child: const Text('退出登录'),
            ),
            // ElevatedButton(
            //   onPressed: () {
            //     DatabaseManager().dropDatabase();
            //     logout(context);
            //   },
            //   child: const Text('删库跑路'),
            // ),
          ],
        ),
      ),
    );
  }
}

class SettingsGroup1 extends StatelessWidget {
  const SettingsGroup1({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: ListTile.divideTiles(
        context: context,
        tiles: [
          ListTile(
            title: const Text('消息通知'),
            trailing: const TrailingIcon(),
            onTap: () {
              Navigator.pushNamed(context, '');
            },
          ),
          ListTile(
            title: const Text('快捷访问'),
            trailing: const TrailingIcon(),
            onTap: () {
              Navigator.pushNamed(context, '');
            },
          ),
        ],
      ).toList(),
    );
  }
}

class SettingsGroup2 extends StatelessWidget {
  const SettingsGroup2({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: ListTile.divideTiles(
        context: context,
        tiles: [
          ListTile(
            title: const Text('隐私设定'),
            trailing: const TrailingIcon(),
            onTap: () {
              Navigator.pushNamed(context, '');
            },
          ),
          ListTile(
            title: const Text('修改密码'),
            trailing: const TrailingIcon(),
            onTap: () {
              Navigator.pushNamed(context, '/settings/changePassword');
            },
          ),
          ListTile(
            title: const Text('管理应用存储空间'),
            trailing: const TrailingIcon(),
            onTap: () {
              Navigator.pushNamed(context, '');
            },
          ),
        ],
      ).toList(),
    );
  }
}

class SettingsGroup3 extends StatefulWidget {
  const SettingsGroup3({super.key});

  @override
  State<SettingsGroup3> createState() => _SettingsGroup3State();
}

class _SettingsGroup3State extends State<SettingsGroup3> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: ListTile.divideTiles(
        context: context,
        tiles: [
          ListTile(
            title: const Text('暗色模式'),
            trailing: Switch(
              value: Provider.of<ThemeModel>(context).isDarkMode,
              onChanged: (value) async {
                final prefs = await SharedPreferences.getInstance();

                await prefs.setBool('isDarkMode', value);

                if (mounted) {
                  Provider.of<ThemeModel>(context, listen: false).changeBrightness(value);
                }

                setState(() {});
              },
            ),
          ),
          ListTile(
            title: const Text('修改主题色'),
            trailing: const TrailingIcon(),
            onTap: () {
              Navigator.pushNamed(context, '/settings/seedColor');
            },
          ),
        ],
      ).toList(),
    );
  }
}

class SettingsGroup4 extends StatelessWidget {
  const SettingsGroup4({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: ListTile.divideTiles(
        context: context,
        tiles: [
          ListTile(
            title: const Text('问题反馈'),
            trailing: const TrailingIcon(),
            onTap: () {
              Navigator.pushNamed(context, '');
            },
          ),
          const VersionUpdateTile(),
          ListTile(
            title: const Text('历史通知'),
            trailing: const TrailingIcon(),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NoteHistoryPage(),
                ),
              );
            },
          ),
        ],
      ).toList(),
    );
  }
}

class VersionUpdateTile extends StatefulWidget {
  const VersionUpdateTile({super.key});

  @override
  State<VersionUpdateTile> createState() => _VersionUpdateTileState();
}

class _VersionUpdateTileState extends State<VersionUpdateTile> {
  final String version = VersionManager().getAppVersion();
  final bool hasNewVersion = VersionManager().checkHasNewVersion();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text('版本更新'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(0, 0, 5, 0),
            child: Text(
              "V$version",
              style: Theme.of(context).textTheme.labelSmall?.apply(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          hasNewVersion
              ? const Badge(
                  child: TrailingIcon(),
                )
              : const TrailingIcon(),
        ],
      ),
      onTap: () {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('最新版本：V${VersionManager().getLatestVersion()}'),
              actions: [
                TextButton(
                  child: const Text('我知道了'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                FilledButton(
                  child: const Text('去下载'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    launchUrl(
                      Uri.parse(
                        VersionManager().getDownloadUrl(),
                      ),
                      mode: LaunchMode.inAppWebView,
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class TrailingIcon extends StatelessWidget {
  const TrailingIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.arrow_forward_ios_outlined,
      size: 20,
      color: Theme.of(context).colorScheme.outline,
    );
  }
}
