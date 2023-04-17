import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../database/database_manager.dart';
import '../../../models/theme_model.dart';
import '../../../reusable_components/logout/logout.dart';

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
              onPressed: (){
                logout(context);
              },
              child: const Text('退出登录'),
            ),
            ElevatedButton(
              onPressed: () {
                DatabaseManager().dropDatabase();
              },
              child: const Text('删库跑路'),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsGroup1 extends StatelessWidget{
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

class SettingsGroup2 extends StatelessWidget{
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
              Navigator.pushNamed(context, '');
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

class SettingsGroup3 extends StatefulWidget{
  const SettingsGroup3({super.key});

  @override
  State<SettingsGroup3> createState() => _SettingsGroup3State();
}

class _SettingsGroup3State extends State<SettingsGroup3>{
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

class SettingsGroup4 extends StatelessWidget{
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
          ListTile(
            title: const Text('版本更新'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(0, 0, 5, 0),
                  child: Text(
                    'V1.00',
                    style: Theme.of(context).textTheme.labelSmall?.apply(color: Theme.of(context).colorScheme.outline),
                  ),
                ),
                const TrailingIcon(),
              ],
            ),
            onTap: () {
              Navigator.pushNamed(context, '');
            },
          ),
          ListTile(
            title: const Text('历史更新公告'),
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

class TrailingIcon extends StatelessWidget{
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