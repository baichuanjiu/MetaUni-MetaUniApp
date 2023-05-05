import 'package:flutter/material.dart';

class DiscoverHomePage extends StatelessWidget {
  const DiscoverHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Column(
                children: [
                  ListTile(
                    leading: const Text('最近使用'),
                    trailing: IconButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/discover/warehouse/search');
                      },
                      icon: const Icon(Icons.search_outlined),
                    ),
                  ),
                  SizedBox(
                    height: 170,
                    child: GridView.count(
                      physics: const NeverScrollableScrollPhysics(),
                      primary: false,
                      padding: const EdgeInsets.all(0),
                      crossAxisSpacing: 5,
                      mainAxisSpacing: 0,
                      crossAxisCount: 4,
                      children: <Widget>[
                        InkWell(
                          borderRadius: BorderRadius.circular(15),
                          onTap: () {},
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 25,
                                backgroundImage: AssetImage('assets/DefaultAvatar.jpg'),
                              ),
                              Text(
                                '小程序',
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(15),
                          onTap: () {},
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 25,
                                backgroundImage: AssetImage('assets/DefaultAvatar.jpg'),
                              ),
                              Text(
                                '小程序',
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(15),
                          onTap: () {},
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 25,
                                backgroundImage: AssetImage('assets/DefaultAvatar.jpg'),
                              ),
                              Text(
                                '小程序',
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(15),
                          onTap: () {},
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 25,
                                backgroundImage: AssetImage('assets/DefaultAvatar.jpg'),
                              ),
                              Text(
                                '小程序',
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(15),
                          onTap: () {},
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 25,
                                backgroundImage: AssetImage('assets/DefaultAvatar.jpg'),
                              ),
                              Text(
                                '小程序',
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(15),
                          onTap: () {},
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 25,
                                backgroundImage: AssetImage('assets/DefaultAvatar.jpg'),
                              ),
                              Text(
                                '小程序',
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(15),
                          onTap: () {},
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 25,
                                backgroundImage: AssetImage('assets/DefaultAvatar.jpg'),
                              ),
                              Text(
                                '小程序',
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(15),
                          onTap: () {},
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 25,
                                backgroundImage: AssetImage('assets/DefaultAvatar.jpg'),
                              ),
                              Text(
                                '小程序',
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(),
              InkWell(
                onTap: () {},
                child: Column(
                  children: [
                    ListTile(
                      title: Text('版本更新通知'),
                      subtitle: Text(DateTime.now().toString().substring(0,16),style: TextStyle(color: Theme.of(context).colorScheme.outline),),
                      trailing: Icon(Icons.read_more_outlined),
                    ),
                    Container(
                      height: 90,
                      padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
                      child: Text(
                        '        这里描述内容简介，内容很长，内容很长，内容很长，内容很长，内容很长，内容很长，内容很长，内容很长，内容很长，内容很长，内容很长，内容很长，内容很长，内容很长，内容很长，内容很长，内容很长，内容很长，内容很长，内容很长，内容很长，内容很长，内容很长，内容很长，内容很长，内容很长，内容很长，内容很长，内容很长，内容很长，内容很长，内容很长，内容很长，内容很长，内容很长，内容很长，内容很长，内容很长，内容很长，内容很长，内容很长，内容很长，内容很长，内容很长，内容很长',
                        style: Theme.of(context).textTheme.bodyMedium?.apply(color: Theme.of(context).colorScheme.outline),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Card(
                //elevation: 0,
                //color: Theme.of(context).colorScheme.surfaceVariant,
                // shape: RoundedRectangleBorder(
                //   side: BorderSide(
                //     color: Theme.of(context).colorScheme.outline,
                //   ),
                //   borderRadius: const BorderRadius.all(Radius.circular(12)),
                // ),
                child: SizedBox(
                  height: 350,
                  width: 800,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: const Image(
                      fit: BoxFit.cover,
                      image: AssetImage('assets/test.png'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
