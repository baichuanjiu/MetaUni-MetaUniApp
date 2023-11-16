import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../models/dio_model.dart';
import '../../../../reusable_components/logout/logout.dart';
import '../../../../reusable_components/snack_bar/network_error_snack_bar.dart';
import '../../../../reusable_components/snack_bar/normal_snack_bar.dart';

class ContactsSearchPage extends StatefulWidget {
  const ContactsSearchPage({super.key});

  @override
  State<ContactsSearchPage> createState() => _ContactsSearchPageState();
}

class _ContactsSearchPageState extends State<ContactsSearchPage> {
  TextEditingController searchController = TextEditingController();

  int? searchKey;

  final DioModel dioModel = DioModel();

  searchUser() async {
    final prefs = await SharedPreferences.getInstance();

    final String? jwt = prefs.getString('jwt');
    final int? uuid = prefs.getInt('uuid');

    try {
      Response response;
      response = await dioModel.dio.get(
        '/metaUni/userAPI/user/search/${searchKey.toString()}',
        options: Options(headers: {
          'JWT': jwt,
          'UUID': uuid,
        }),
      );
      switch (response.data['code']) {
        case 0:
          if (mounted) {
            Navigator.pushNamed(context, '/contacts/search/result/user',arguments: response.data['data']['searchResult']);
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
        //Message:"未找到符合条件的结果"
          if (mounted) {
            getNormalSnackBar(context, response.data['message']);
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
  void dispose() {
    searchController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: Scaffold(
                        body: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(50.0),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(25, 0, 25, 0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                                  child: Icon(
                                    Icons.search_outlined,
                                    color: Theme.of(context).colorScheme.outline,
                                  ),
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: searchController,
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      hintText: '搜索',
                                    ),
                                    autofocus: true,
                                    keyboardType: TextInputType.number,
                                    textInputAction: TextInputAction.search,
                                    autocorrect: false,
                                    inputFormatters: [
                                      //只允许输入数字
                                      FilteringTextInputFormatter.allow(RegExp("[0-9]")),
                                      //只允许输入最多10个字符
                                      LengthLimitingTextInputFormatter(10),
                                    ],
                                    onTapOutside: (value){
                                      FocusManager.instance.primaryFocus?.unfocus();
                                    },
                                    onChanged: (value) {
                                      if(value.isNotEmpty){
                                        searchKey = int.parse(value);
                                        setState(() {
                                        });
                                      }
                                      else{
                                        searchKey = null;
                                        setState(() {
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('取消'),
                  ),
                ],
              ),
            ),
            searchKey == null?Container():ListTile(
              leading: const Icon(
                Icons.person_add_alt,
              ),
              title: Text('找人：$searchKey'),
              onTap: (){
                searchUser();
              },
            ),
            searchKey == null?Container():ListTile(
              leading: const Icon(
                Icons.group_add_outlined,
              ),
              title: Text('找群：$searchKey'),
              onTap: (){},
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
            ),
            Text(
              '搜索用户、群组等',
              style: Theme.of(context).textTheme.labelMedium?.apply(color: Theme.of(context).colorScheme.outline),
            ),
          ],
        ),
      ),
    );
  }
}
