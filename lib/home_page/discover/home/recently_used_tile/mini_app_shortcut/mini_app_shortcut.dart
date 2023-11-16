import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:meta_uni_app/reusable_components/open_mini_app/open_mini_app.dart';
import '../../../../../database/models/mini_app/brief_mini_app_information.dart';

class MiniAppShortcut extends StatelessWidget {
  final BriefMiniAppInformation info;

  const MiniAppShortcut({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: () {
        if (info.type == 'ClientApp' && info.routingURL != null && info.minimumSupportVersion != null) {
          openClientApp(info.id, info.routingURL!, info.minimumSupportVersion!, context);
        } else if (info.type == 'WebApp' && info.url != null) {
          openWebApp(info.id, info.url!, info.name, context);
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Avatar(info.avatar),
          Container(
            height: 2,
          ),
          Text(
            info.name,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
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
      placeholder: (context, url) => CircleAvatar(
        radius: 25,
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: const CupertinoActivityIndicator(),
      ),
      imageUrl: avatar,
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: 25,
        backgroundImage: imageProvider,
      ),
      errorWidget: (context, url, error) => CircleAvatar(
        radius: 25,
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: const Icon(Icons.error_outline),
      ),
    );
  }
}
