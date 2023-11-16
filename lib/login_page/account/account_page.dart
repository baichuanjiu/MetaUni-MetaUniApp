import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/dio_model.dart';
import '../../reusable_components/snack_bar/network_error_snack_bar.dart';
import '../models/brief_private_profile.dart';
import '../reusable_components/copyright.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
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
                    '欢迎登录，',
                    style: Theme.of(context).textTheme.headlineSmall?.apply(color: Theme.of(context).colorScheme.onSurface),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.dashboard_customize_outlined,
                        size: 16,
                      ),
                      Text(
                        'MetaUni，校内、共建、多元',
                        style: Theme.of(context).textTheme.labelMedium?.apply(color: Theme.of(context).colorScheme.onSurface),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                  ),
                  const AccountInputField(),
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
    );
  }
}

class AccountInputField extends StatefulWidget {
  const AccountInputField({super.key});

  @override
  State<AccountInputField> createState() => _AccountInputField();
}

class _AccountInputField extends State<AccountInputField> {
  FocusNode accountFocusNode = FocusNode();
  TextEditingController accountController = TextEditingController();
  String? _errorText;

  final DioModel dioModel = DioModel();

  checkAccount() async {
    try {
      Response response;
      response = await dioModel.dio.get(
        '/metaUni/userAPI/login/check/${accountController.text}',
      );
      switch (response.data['code']) {
        case 0:
          accountFocusNode.unfocus();
          accountController.clear();
          BriefPrivateProfile briefPrivateProfile = BriefPrivateProfile(response.data['data']['account'], response.data['data']['avatar'], response.data['data']['privateNickname']);
          if (mounted) {
            Navigator.pushNamed(
              context,
              '/password',
              arguments: {
                'briefPrivateProfile': briefPrivateProfile,
                'rsaPublicKey': response.data['data']['rsaPublicKey'],
              },
            );
          }
          break;
        case 1:
          //Message:"该账号不存在"
          if (mounted) {
            accountFocusNode.requestFocus();
            setState(() {
              _errorText = response.data['message'];
            });
          }
          break;
        default:
          if(mounted){
            getNetworkErrorSnackBar(context);
          }
      }
    } catch (e) {
      if(mounted){
        getNetworkErrorSnackBar(context);
      }
    }
  }

  @override
  void dispose() {
    accountFocusNode.dispose();
    accountController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          focusNode: accountFocusNode,
          controller: accountController,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.account_circle_outlined),
            labelText: '请输入账号',
            hintText: '学号或工号',
            errorText: _errorText,
            suffixIcon: IconButton(
              onPressed: () {
                if (_errorText != null) {
                  setState(() {
                    _errorText = null;
                  });
                }
                accountController.clear();
              },
              icon: const Icon(Icons.cancel_outlined),
              tooltip: '清空',
            ),
          ),
          autofocus: true,
          maxLength: 10,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          autocorrect: false,
          inputFormatters: [
            //只允许输入数字
            FilteringTextInputFormatter.allow(RegExp("[0-9]"))
          ],
          onTapOutside: (value) {
            accountFocusNode.unfocus();
          },
          onChanged: (value) {
            setState(() {
              _errorText = null;
            });
          },
          onEditingComplete: () {
            if (accountController.text.isNotEmpty) {
              checkAccount();
            } else {
              setState(() {
                _errorText = '账号不可为空';
              });
            }
          },
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
        ),
        Center(
          child: ElevatedButton(
            onPressed: () {
              if (accountController.text.isNotEmpty) {
                checkAccount();
              } else {
                accountFocusNode.requestFocus();
                setState(() {
                  _errorText = '账号不可为空';
                });
              }
            },
            child: const Text('下一步'),
          ),
        ),
      ],
    );
  }
}
