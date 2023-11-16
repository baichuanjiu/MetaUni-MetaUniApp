import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'models/friend_list_tile_data.dart';

class FriendListTile extends StatelessWidget {
  final FriendListTileData friendListTileData;

  const FriendListTile(this.friendListTileData, {super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListTile(
        onTap: () {
          Navigator.pushNamed(context, '/user/profile', arguments: friendListTileData.uuid);
        },
        leading: Avatar(friendListTileData.avatar),
        title: Text(
          friendListTileData.appellation,
          style: Theme.of(context).textTheme.bodyLarge,
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
        placeholder: (context, url) => SizedBox(
          width: 45,
          height: 45,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: const Center(
              child: CupertinoActivityIndicator(),
            ),
          ),
        ),
        imageUrl: avatar,
        imageBuilder: (context, imageProvider) => SizedBox(
          width: 45,
          height: 45,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Image(
              image: imageProvider,
            ),
          ),
        ),
        errorWidget: (context, url, error) => SizedBox(
          width: 45,
          height: 45,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: const Center(
              child: Icon(Icons.error_outline),
            ),
          ),
        )
    );
  }
}
