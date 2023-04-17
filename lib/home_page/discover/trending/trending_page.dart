import 'package:flutter/material.dart';

class DiscoverTrendingPage extends StatelessWidget {
  const DiscoverTrendingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(seconds: 1));
        },
        child: SizedBox(
          height: double.infinity,
          width: double.infinity,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(15),
                          onTap: () {},
                          child: Card(
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: 250,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: const Image(
                                        fit: BoxFit.cover,
                                        image: AssetImage('assets/test.png'),
                                      ),
                                    ),
                                  ),
                                  Container(height: 5,),
                                  Text('第一次在树洞投稿，应该没什么人看吧，我认识她的契机是去年的棒球大赛',maxLines: 3,overflow: TextOverflow.ellipsis,),
                                  const Divider(),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Column(
                                        children: [
                                          const CircleAvatar(
                                            radius: 15,
                                            backgroundImage: AssetImage('assets/DefaultAvatar.jpg'),
                                          ),
                                          Text('小程序', style: Theme.of(context).textTheme.labelMedium),
                                        ],
                                      ),
                                      Container(
                                        width: 5,
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '标题',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context).textTheme.labelMedium,
                                            ),
                                            Text(
                                              '描述',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context).textTheme.labelSmall?.apply(color: Theme.of(context).colorScheme.outline),
                                            ),
                                          ],
                                        ),
                                      ),
                                      InkWell(
                                        borderRadius: BorderRadius.circular(10),
                                        onTap: () {},
                                        child: Icon(
                                          Icons.more_horiz_outlined,
                                          size: 20,
                                          color: Theme.of(context).colorScheme.outline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(15),
                          onTap: () {},
                          child: Card(
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    child: Text('我不知道，我想不出来，我真的想不出来，我想不出来啊'),
                                  ),
                                  const Divider(),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Column(
                                        children: [
                                          const CircleAvatar(
                                            radius: 15,
                                            backgroundImage: AssetImage('assets/DefaultAvatar.jpg'),
                                          ),
                                          Text('小程序', style: Theme.of(context).textTheme.labelMedium),
                                        ],
                                      ),
                                      Container(
                                        width: 5,
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '标题多长合适呢，到底多长合适呢',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context).textTheme.labelMedium,
                                            ),
                                            Text(
                                              '描述多长才会超出界限呢，到底是多长呢',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context).textTheme.labelSmall?.apply(color: Theme.of(context).colorScheme.outline),
                                            ),
                                          ],
                                        ),
                                      ),
                                      InkWell(
                                        borderRadius: BorderRadius.circular(10),
                                        onTap: () {},
                                        child: Icon(
                                          Icons.more_horiz_outlined,
                                          size: 20,
                                          color: Theme.of(context).colorScheme.outline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(15),
                          onTap: () {},
                          child: Card(
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: 250,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: const Image(
                                        fit: BoxFit.cover,
                                        image: AssetImage('assets/mayi.png'),
                                      ),
                                    ),
                                  ),
                                  const Divider(),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Column(
                                        children: [
                                          const CircleAvatar(
                                            radius: 15,
                                            backgroundImage: AssetImage('assets/DefaultAvatar.jpg'),
                                          ),
                                          Text('小程序', style: Theme.of(context).textTheme.labelMedium),
                                        ],
                                      ),
                                      Container(
                                        width: 5,
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '标题多长合适呢，到底多长合适呢',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context).textTheme.labelMedium,
                                            ),
                                            Text(
                                              '描述多长才会超出界限呢，到底是多长呢',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context).textTheme.labelSmall?.apply(color: Theme.of(context).colorScheme.outline),
                                            ),
                                          ],
                                        ),
                                      ),
                                      InkWell(
                                        borderRadius: BorderRadius.circular(10),
                                        onTap: () {},
                                        child: Icon(
                                          Icons.more_horiz_outlined,
                                          size: 20,
                                          color: Theme.of(context).colorScheme.outline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(15),
                          onTap: () {},
                          child: Card(
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    child: Text('我不知道，我想不出来，我真的想不出来，我想不出来啊'),
                                  ),
                                  const Divider(),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Column(
                                        children: [
                                          const CircleAvatar(
                                            radius: 15,
                                            backgroundImage: AssetImage('assets/DefaultAvatar.jpg'),
                                          ),
                                          Text('小程序', style: Theme.of(context).textTheme.labelMedium),
                                        ],
                                      ),
                                      Container(
                                        width: 5,
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '标题多长合适呢，到底多长合适呢',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context).textTheme.labelMedium,
                                            ),
                                            Text(
                                              '描述多长才会超出界限呢，到底是多长呢',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context).textTheme.labelSmall?.apply(color: Theme.of(context).colorScheme.outline),
                                            ),
                                          ],
                                        ),
                                      ),
                                      InkWell(
                                        borderRadius: BorderRadius.circular(10),
                                        onTap: () {},
                                        child: Icon(
                                          Icons.more_horiz_outlined,
                                          size: 20,
                                          color: Theme.of(context).colorScheme.outline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(15),
                          onTap: () {},
                          child: Card(
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: 250,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: const Image(
                                        fit: BoxFit.cover,
                                        image: AssetImage('assets/test.png'),
                                      ),
                                    ),
                                  ),
                                  const Divider(),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Column(
                                        children: [
                                          const CircleAvatar(
                                            radius: 15,
                                            backgroundImage: AssetImage('assets/DefaultAvatar.jpg'),
                                          ),
                                          Text('小程序', style: Theme.of(context).textTheme.labelMedium),
                                        ],
                                      ),
                                      Container(
                                        width: 5,
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '标题多长合适呢，到底多长合适呢',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context).textTheme.labelMedium,
                                            ),
                                            Text(
                                              '描述多长才会超出界限呢，到底是多长呢',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context).textTheme.labelSmall?.apply(color: Theme.of(context).colorScheme.outline),
                                            ),
                                          ],
                                        ),
                                      ),
                                      InkWell(
                                        borderRadius: BorderRadius.circular(10),
                                        onTap: () {},
                                        child: Icon(
                                          Icons.more_horiz_outlined,
                                          size: 20,
                                          color: Theme.of(context).colorScheme.outline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 5,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(15),
                          onTap: () {},
                          child: Card(
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    child: Text('道爷，我悟不出来'),
                                  ),
                                  const Divider(),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Column(
                                        children: [
                                          const CircleAvatar(
                                            radius: 15,
                                            backgroundImage: AssetImage('assets/DefaultAvatar.jpg'),
                                          ),
                                          Text('小程序', style: Theme.of(context).textTheme.labelMedium),
                                        ],
                                      ),
                                      Container(
                                        width: 5,
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '标题多长合适呢，到底多长合适呢',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context).textTheme.labelMedium,
                                            ),
                                            Text(
                                              '描述多长才会超出界限呢，到底是多长呢',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context).textTheme.labelSmall?.apply(color: Theme.of(context).colorScheme.outline),
                                            ),
                                          ],
                                        ),
                                      ),
                                      InkWell(
                                        borderRadius: BorderRadius.circular(10),
                                        onTap: () {},
                                        child: Icon(
                                          Icons.more_horiz_outlined,
                                          size: 20,
                                          color: Theme.of(context).colorScheme.outline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(15),
                          onTap: () {},
                          child: Card(
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: 250,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: const Image(
                                        fit: BoxFit.cover,
                                        image: AssetImage('assets/mayi.png'),
                                      ),
                                    ),
                                  ),
                                  Container(height: 5,),
                                  Text('樱岛麻衣想要Rush B',maxLines: 3,overflow: TextOverflow.ellipsis,),
                                  const Divider(),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Column(
                                        children: [
                                          const CircleAvatar(
                                            radius: 15,
                                            backgroundImage: AssetImage('assets/DefaultAvatar.jpg'),
                                          ),
                                          Text('小程序', style: Theme.of(context).textTheme.labelMedium),
                                        ],
                                      ),
                                      Container(
                                        width: 5,
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '标题多长合适呢，到底多长合适呢',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context).textTheme.labelMedium,
                                            ),
                                            Text(
                                              '描述多长才会超出界限呢，到底是多长呢',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context).textTheme.labelSmall?.apply(color: Theme.of(context).colorScheme.outline),
                                            ),
                                          ],
                                        ),
                                      ),
                                      InkWell(
                                        borderRadius: BorderRadius.circular(10),
                                        onTap: () {},
                                        child: Icon(
                                          Icons.more_horiz_outlined,
                                          size: 20,
                                          color: Theme.of(context).colorScheme.outline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(15),
                          onTap: () {},
                          child: Card(
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: 250,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: const Image(
                                        fit: BoxFit.cover,
                                        image: AssetImage('assets/test.png'),
                                      ),
                                    ),
                                  ),
                                  const Divider(),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Column(
                                        children: [
                                          const CircleAvatar(
                                            radius: 15,
                                            backgroundImage: AssetImage('assets/DefaultAvatar.jpg'),
                                          ),
                                          Text('小程序', style: Theme.of(context).textTheme.labelMedium),
                                        ],
                                      ),
                                      Container(
                                        width: 5,
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '标题多长合适呢，到底多长合适呢',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context).textTheme.labelMedium,
                                            ),
                                            Text(
                                              '描述多长才会超出界限呢，到底是多长呢',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context).textTheme.labelSmall?.apply(color: Theme.of(context).colorScheme.outline),
                                            ),
                                          ],
                                        ),
                                      ),
                                      InkWell(
                                        borderRadius: BorderRadius.circular(10),
                                        onTap: () {},
                                        child: Icon(
                                          Icons.more_horiz_outlined,
                                          size: 20,
                                          color: Theme.of(context).colorScheme.outline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(15),
                          onTap: () {},
                          child: Card(
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    child: Text('我不知道，我想不出来，我真的想不出来，我想不出来啊'),
                                  ),
                                  const Divider(),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Column(
                                        children: [
                                          const CircleAvatar(
                                            radius: 15,
                                            backgroundImage: AssetImage('assets/DefaultAvatar.jpg'),
                                          ),
                                          Text('小程序', style: Theme.of(context).textTheme.labelMedium),
                                        ],
                                      ),
                                      Container(
                                        width: 5,
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '标题多长合适呢，到底多长合适呢',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context).textTheme.labelMedium,
                                            ),
                                            Text(
                                              '描述多长才会超出界限呢，到底是多长呢',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context).textTheme.labelSmall?.apply(color: Theme.of(context).colorScheme.outline),
                                            ),
                                          ],
                                        ),
                                      ),
                                      InkWell(
                                        borderRadius: BorderRadius.circular(10),
                                        onTap: () {},
                                        child: Icon(
                                          Icons.more_horiz_outlined,
                                          size: 20,
                                          color: Theme.of(context).colorScheme.outline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(15),
                          onTap: () {},
                          child: Card(
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: 250,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: const Image(
                                        fit: BoxFit.cover,
                                        image: AssetImage('assets/mayi.png'),
                                      ),
                                    ),
                                  ),
                                  const Divider(),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Column(
                                        children: [
                                          const CircleAvatar(
                                            radius: 15,
                                            backgroundImage: AssetImage('assets/DefaultAvatar.jpg'),
                                          ),
                                          Text('小程序', style: Theme.of(context).textTheme.labelMedium),
                                        ],
                                      ),
                                      Container(
                                        width: 5,
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '标题多长合适呢，到底多长合适呢',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context).textTheme.labelMedium,
                                            ),
                                            Text(
                                              '描述多长才会超出界限呢，到底是多长呢',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context).textTheme.labelSmall?.apply(color: Theme.of(context).colorScheme.outline),
                                            ),
                                          ],
                                        ),
                                      ),
                                      InkWell(
                                        borderRadius: BorderRadius.circular(10),
                                        onTap: () {},
                                        child: Icon(
                                          Icons.more_horiz_outlined,
                                          size: 20,
                                          color: Theme.of(context).colorScheme.outline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
