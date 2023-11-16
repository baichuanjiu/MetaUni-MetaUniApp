import 'dart:async';
import 'package:dio/dio.dart';
import 'package:fast_rsa/fast_rsa.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:meta_uni_app/models/dio_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../reusable_components/logout/logout.dart';
import '../../../../reusable_components/snack_bar/network_error_snack_bar.dart';
import '../../../../reusable_components/snack_bar/normal_snack_bar.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  FocusNode passwordFocusNode = FocusNode();
  TextEditingController passwordController = TextEditingController();
  String? _helperText = '特殊字符包括：@ # _ *';
  String? _errorText;
  bool _obscureText = true;
  bool hasRSAPublicKey = false;
  late Timer timer;
  late String rsaPublicKey;

  final DioModel dioModel = DioModel();
  late String jwt;
  late int uuid;

  late Future<dynamic> init;

  getRSAPublicKey() async {
    try {
      Response response;
      response = await dioModel.dio.get(
        '/metaUni/userAPI/user/password/rsaPublicKey',
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 0:
          rsaPublicKey = response.data['data'];
          hasRSAPublicKey = true;
          setState(() {});
          break;
        case 1:
          //Message:"使用了无效的JWT，请重新登录"
          if (mounted) {
            getNormalSnackBar(context, response.data['message']);
            logout(context);
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

  changePassword() async {
    Uint8List byteRSAPassword = await RSA.encryptPKCS1v15Bytes(Uint8List.fromList(passwordController.text.codeUnits), rsaPublicKey);
    try {
      Response response;
      response = await dioModel.dio.put(
        '/metaUni/userAPI/user/password',
        data: {
          'newPassword': String.fromCharCodes(byteRSAPassword),
        },
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 0:
          if (mounted) {
            getNormalSnackBar(context, response.data['message']);
            logout(context);
          }
          break;
        case 1:
          //Message:"使用了无效的JWT，请重新登录"
          if (mounted) {
            getNormalSnackBar(context, response.data['message']);
            logout(context);
          }
          break;
        case 2:
          //Message:"修改密码超时，请重新尝试"
          if (mounted) {
            getNormalSnackBar(context, response.data['message']);
            getRSAPublicKey();
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

  _init() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    jwt = prefs.getString('jwt')!;
    uuid = prefs.getInt('uuid')!;

    await getRSAPublicKey();
    timer = Timer.periodic(
        const Duration(
          minutes: 4,
        ), (timer) {
      getRSAPublicKey();
    });
  }

  @override
  void initState() {
    super.initState();

    init = _init();
  }

  @override
  void dispose() {
    timer.cancel();
    passwordFocusNode.dispose();
    passwordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("修改密码"),
      ),
      body: FutureBuilder(
        future: init,
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
              return const Center(
                child: CupertinoActivityIndicator(),
              );
            case ConnectionState.active:
              return const Center(
                child: CupertinoActivityIndicator(),
              );
            case ConnectionState.waiting:
              return const Center(
                child: CupertinoActivityIndicator(),
              );
            case ConnectionState.done:
              if (snapshot.hasError) {
                return const Center(
                  child: CupertinoActivityIndicator(),
                );
              }
              if (!hasRSAPublicKey) {
                return const Center(
                  child: CupertinoActivityIndicator(),
                );
              } else {
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                        child: TextField(
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
                            labelText: '请输入新密码',
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
                              passwordFocusNode.unfocus();
                            } else {
                              setState(() {
                                _errorText = '密码不可为空';
                              });
                            }
                          },
                        ),
                      ),
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                            if (passwordController.text.isNotEmpty) {
                              changePassword();
                            } else {
                              setState(() {
                                passwordFocusNode.requestFocus();
                                _errorText = '密码不可为空';
                              });
                            }
                          },
                          child: const Text('修改密码'),
                        ),
                      ),
                    ],
                  ),
                );
              }
            default:
              return const Center(
                child: CupertinoActivityIndicator(),
              );
          }
        },
      ),
    );
  }
}
