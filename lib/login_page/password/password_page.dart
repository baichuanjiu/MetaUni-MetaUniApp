import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:meta_uni_app/reusable_components/snack_bar/normal_snack_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:fast_rsa/fast_rsa.dart';
import '../../database/database_manager.dart';
import '../../database/models/user/brief_user_information.dart';
import '../../database/models/user/user_sync_table.dart';
import '../../models/dio_model.dart';
import '../../reusable_components/snack_bar/network_error_snack_bar.dart';
import '../models/brief_private_profile.dart';
import '../reusable_components/copyright.dart';

class PasswordPage extends StatefulWidget {
  const PasswordPage({super.key});

  @override
  State<PasswordPage> createState() => _PasswordPage();
}

class _PasswordPage extends State<PasswordPage> {
  late BriefPrivateProfile briefPrivateProfile;
  late String rsaPublicKey;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    Map<String, dynamic> map = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    briefPrivateProfile = map['briefPrivateProfile'];
    rsaPublicKey = map['rsaPublicKey'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '欢迎，',
                      style: Theme.of(context).textTheme.headlineSmall?.apply(color: Theme.of(context).colorScheme.onSurface),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
                    ),
                    Center(
                      child: Avatar(briefPrivateProfile.avatar),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
                    ),
                    Center(
                      child: PrivateNickname(briefPrivateProfile.privateNickName),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
                    ),
                    PasswordInputField(briefPrivateProfile.account, rsaPublicKey),
                  ],
                ),
              ),
            ),
            Column(
              children: [
                const Copyright(),
                Container(
                  padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class Avatar extends StatelessWidget {
  final String avatar;

  const Avatar(this.avatar, {super.key});

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      fadeInDuration: const Duration(milliseconds: 800),
      fadeOutDuration: const Duration(milliseconds: 200),
      placeholder: (context, url) =>         CircleAvatar(
        radius: 45,
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: const CupertinoActivityIndicator(),
      ),
      imageUrl: avatar,
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: 45,
        backgroundColor: Theme.of(context).colorScheme.surface,
        backgroundImage: imageProvider,
      ),
      errorWidget: (context, url, error) => CircleAvatar(
        radius: 45,
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: const Icon(Icons.error_outline),
      ),
    );
  }
}

class PrivateNickname extends StatelessWidget {
  final String privateNickname;

  const PrivateNickname(this.privateNickname, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      privateNickname,
      style: Theme.of(context).textTheme.bodyLarge,
    );
  }
}

class PasswordInputField extends StatefulWidget {
  final String account;
  final String rsaPublicKey;

  const PasswordInputField(this.account, this.rsaPublicKey, {super.key});

  @override
  State<PasswordInputField> createState() => _PasswordInputField();
}

class _PasswordInputField extends State<PasswordInputField> {
  FocusNode passwordFocusNode = FocusNode();
  TextEditingController passwordController = TextEditingController();
  String? _helperText = '特殊字符包括：@ # _ *';
  String? _errorText;
  bool _obscureText = true;

  final DioModel dioModel = DioModel();

  login() async {
    try {
      Response response;
      Uint8List byteRSAPassword = await RSA.encryptPKCS1v15Bytes(Uint8List.fromList(passwordController.text.codeUnits), widget.rsaPublicKey);
      response = await dioModel.dio.post(
        '/metaUni/userAPI/login',
        data: {
          'account': widget.account,
          'password': String.fromCharCodes(byteRSAPassword),
        },
      );
      switch (response.data['code']) {
        case 0:
          passwordFocusNode.unfocus();
          passwordController.clear();
          final prefs = await SharedPreferences.getInstance();

          await prefs.setString(
            'jwt',
            response.data['data']['jwt'],
          );
          await prefs.setInt(
            'uuid',
            response.data['data']['uuid'],
          );

          DatabaseManager().setDatabaseName(response.data['data']['uuid'].toString());
          Database database = await DatabaseManager().getDatabase;

          await database.transaction((transaction) async {
            BriefUserInformationProviderWithTransaction briefUserInformationProviderWithTransaction = BriefUserInformationProviderWithTransaction(transaction);

            BriefUserInformation briefUserInformation = BriefUserInformation.fromJson(response.data['data']);
            if (await briefUserInformationProviderWithTransaction.get(briefUserInformation.uuid) == null) {
              briefUserInformationProviderWithTransaction.insert(
                briefUserInformation,
              );
            } else {
              briefUserInformationProviderWithTransaction.update(
                briefUserInformation.toUpdateSql(),
                briefUserInformation.uuid,
              );
            }

            UserSyncTableProviderWithTransaction userSyncTableProviderWithTransaction = UserSyncTableProviderWithTransaction(transaction);
            if (await userSyncTableProviderWithTransaction.get(response.data['data']['uuid']) == null) {
              userSyncTableProviderWithTransaction.insert(
                UserSyncTable.init(response.data['data']['uuid']),
              );
            }
          });

          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
          }
          break;
        case 1:
          //Message:"登录超时，请重新尝试"
          if (mounted) {
            getNormalSnackBar(context, response.data['message']);
            Navigator.pushNamedAndRemoveUntil(context, '/account', (route) => false);
          }
          break;
        case 2:
          //Message:"账号或密码错误"
          if (mounted) {
            passwordFocusNode.requestFocus();
            setState(() {
              _errorText = response.data['message'];
            });
          }
          break;
        default:
          if(mounted)
          {
            getNetworkErrorSnackBar(context);
          }
      }
    } catch (e) {
      if(mounted)
      {
        getNetworkErrorSnackBar(context);
      }
    }
  }

  @override
  void dispose() {
    passwordFocusNode.dispose();
    passwordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          focusNode: passwordFocusNode,
          controller: passwordController,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            prefixIcon: passwordController.text.isEmpty
                ? const Icon(Icons.password_outlined)
                : IconButton(
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                    icon: _obscureText ? const Icon(Icons.visibility_off_outlined) : const Icon(Icons.visibility_outlined),
                    tooltip: _obscureText ? '显示密码' : '隐藏密码',
                  ),
            labelText: '请输入密码',
            hintText: '数字、字母、特殊字符',
            helperText: _helperText,
            errorText: _errorText,
            suffixIcon: IconButton(
              onPressed: () {
                if (_errorText != null) {
                  setState(() {
                    _errorText = null;
                  });
                } else {
                  setState(() {});
                }
                passwordController.clear();
              },
              icon: const Icon(Icons.cancel_outlined),
              tooltip: '清空',
            ),
          ),
          autofocus: true,
          obscureText: _obscureText,
          maxLength: 30,
          textInputAction: TextInputAction.done,
          autocorrect: false,
          inputFormatters: [
            //只允许输入数字、字母、特殊字符（@ # _ *）
            FilteringTextInputFormatter.allow(RegExp("[a-zA-Z0-9@#_*]"))
          ],
          onTap: () {
            setState(() {
              _helperText = '特殊字符包括：@ # _ *';
            });
          },
          onTapOutside: (value) {
            passwordFocusNode.unfocus();
            setState(() {
              _helperText = null;
            });
          },
          onChanged: (value) {
            setState(() {
              _errorText = null;
            });
          },
          onEditingComplete: () {
            if (passwordController.text.isNotEmpty) {
              login();
            } else {
              setState(() {
                _errorText = '密码不可为空';
              });
            }
          },
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
        ),
        Stack(
          children: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  if (passwordController.text.isNotEmpty) {
                    login();
                  } else {
                    setState(() {
                      passwordFocusNode.requestFocus();
                      _errorText = '密码不可为空';
                    });
                  }
                },
                child: const Text('登录'),
              ),
            ),
            Positioned(
              right: 0,
              child: TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/password/forget');
                },
                child: Text(
                  '忘记密码？',
                  style: Theme.of(context).textTheme.labelMedium?.apply(decoration: TextDecoration.underline),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
