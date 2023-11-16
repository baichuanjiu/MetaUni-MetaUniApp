import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChatsSearchPage extends StatefulWidget {
  const ChatsSearchPage({super.key});

  @override
  State<ChatsSearchPage> createState() => _ChatsSearchPageState();
}

class _ChatsSearchPageState extends State<ChatsSearchPage> {
  TextEditingController searchController = TextEditingController();

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
                    child: Hero(
                      tag: 'chatsSearchBox',
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
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(25, 0, 25, 0),
                              child: Row(
                                children: [
                                  Padding(
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
                                      textInputAction: TextInputAction.search,
                                      autocorrect: false,
                                      inputFormatters: [
                                        LengthLimitingTextInputFormatter(30),
                                      ],
                                      onTapOutside: (value){
                                        FocusManager.instance.primaryFocus?.unfocus();
                                      },
                                      onChanged: (value) {},
                                    ),
                                  ),
                                ],
                              ),
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
            const Padding(
              padding: EdgeInsets.fromLTRB(0, 5, 0, 5),
            ),
            Text(
              '搜索群聊、联系人、聊天记录等',
              style: Theme.of(context).textTheme.labelMedium?.apply(color: Theme.of(context).colorScheme.outline),
            ),
          ],
        ),
      ),
    );
  }
}
