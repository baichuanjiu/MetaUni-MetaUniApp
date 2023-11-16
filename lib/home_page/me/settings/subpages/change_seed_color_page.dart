import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../models/theme_model.dart';

class ChangeSeedColorPage extends StatefulWidget {
  const ChangeSeedColorPage({super.key});

  @override
  State<ChangeSeedColorPage> createState() => _ChangeSeedColorPageState();
}

class _ChangeSeedColorPageState extends State<ChangeSeedColorPage> {
  late Color pickerColor;
  late Color originalSeedColor;

  initPickerColor() async {
    originalSeedColor = Color(await InitThemeTool.initThemeColor());
    pickerColor = originalSeedColor;
  }

  changeSeedColor(Color color) {
    setState(() => pickerColor = color);
    Provider.of<ThemeModel>(context, listen: false).changeThemeColor(pickerColor.value);
  }

  showColorPicker() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('选择一个颜色'),
          content: SingleChildScrollView(
            child: MaterialPicker(
              pickerColor: pickerColor,
              onColorChanged: changeSeedColor,
              enableLabel: true, // only on portrait mode
              portraitOnly: true,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('取消'),
              onPressed: () {
                setState(() => pickerColor = originalSeedColor);
                Provider.of<ThemeModel>(context, listen: false).changeThemeColor(originalSeedColor.value);
                if (mounted) {
                  Navigator.pop(context);
                }
              },
            ),
            FilledButton(
              child: const Text('确定'),
              onPressed: () async {
                originalSeedColor = pickerColor;

                final prefs = await SharedPreferences.getInstance();

                await prefs.setInt('seedColor', pickerColor.value);

                if (mounted) {
                  Navigator.pop(context);
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();

    initPickerColor();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('修改主题色'),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_ios_new_outlined),
        ),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            showColorPicker();
          },
          child: const Text('选择颜色'),
        ),
      ),
    );
  }
}
