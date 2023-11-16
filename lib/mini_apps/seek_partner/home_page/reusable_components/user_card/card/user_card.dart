import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/user_card_data.dart';

class UserCard extends StatefulWidget {
  final UserCardData data;
  final File? backgroundImagePreview;

  const UserCard({super.key, required this.data, this.backgroundImagePreview});

  @override
  State<UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<UserCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 3.375 / 2.125,
              child: widget.backgroundImagePreview != null
                  ? Image.file(
                      widget.backgroundImagePreview!,
                      fit: BoxFit.cover,
                    )
                  : CachedNetworkImage(
                      fadeInDuration: const Duration(milliseconds: 800),
                      fadeOutDuration: const Duration(milliseconds: 200),
                      placeholder: (context, url) => const Center(
                        child: CupertinoActivityIndicator(),
                      ),
                      imageUrl: widget.data.backgroundImage.url,
                      imageBuilder: (context, imageProvider) => Image(
                        image: imageProvider,
                        fit: BoxFit.cover,
                      ),
                      errorWidget: (context, url, error) => const Center(
                        child: CupertinoActivityIndicator(),
                      ),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 5, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CachedNetworkImage(
                      fadeInDuration: const Duration(milliseconds: 800),
                      fadeOutDuration: const Duration(milliseconds: 200),
                      placeholder: (context, url) => CircleAvatar(
                        radius: 25,
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        child: const CupertinoActivityIndicator(),
                      ),
                      imageUrl: widget.data.user.avatar,
                      imageBuilder: (context, imageProvider) => CircleAvatar(
                        radius: 25,
                        backgroundImage: imageProvider,
                      ),
                      errorWidget: (context, url, error) => CircleAvatar(
                        radius: 25,
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        child: const Icon(Icons.error_outline),
                      ),
                    ),
                    Container(
                      width: 10,
                    ),
                    Expanded(
                      child: Text(
                        widget.data.user.nickname,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.apply(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                Container(
                  height: 5,
                ),
                Text(
                  widget.data.summary ?? '这个用户很神秘，什么都没有留下',
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge?.apply(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
