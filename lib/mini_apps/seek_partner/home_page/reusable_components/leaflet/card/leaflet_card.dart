import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:meta_uni_app/mini_apps/seek_partner/home_page/reusable_components/leaflet/details/leaflet_details_page.dart';
import 'package:meta_uni_app/mini_apps/seek_partner/home_page/reusable_components/leaflet/models/leaflet_data.dart';
import 'package:meta_uni_app/mini_apps/seek_partner/home_page/reusable_components/tag/tags.dart';

import '../../../../../../reusable_components/formatter/date_time_formatter/date_time_formatter.dart';

class LeafletCard extends StatefulWidget {
  final LeafletData data;

  const LeafletCard({super.key, required this.data});

  @override
  State<LeafletCard> createState() => _LeafletCardState();
}

class _LeafletCardState extends State<LeafletCard> {
  @override
  Widget build(BuildContext context) {
    List<Widget> mediasList = [];
    for (var media in widget.data.medias) {
      mediasList.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(2.5, 0, 2.5, 0),
          child: AspectRatio(
            aspectRatio: media.aspectRatio,
            child: CachedNetworkImage(
              fadeInDuration: const Duration(milliseconds: 800),
              fadeOutDuration: const Duration(milliseconds: 200),
              placeholder: (context, url) => const CupertinoActivityIndicator(),
              imageUrl: media.url,
              imageBuilder: (context, imageProvider) => ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image(
                  image: imageProvider,
                  fit: BoxFit.cover,
                ),
              ),
              errorWidget: (context, url, error) => const Icon(Icons.error_outline),
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        Card(
          elevation: 0,
          margin: const EdgeInsets.fromLTRB(0, 25, 0, 0),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return LeafletDetailsPage(id: widget.data.id);
                  },
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 5, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const SizedBox(
                        height: 20,
                        width: 60,
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                widget.data.poster.nickname,
                                style: Theme.of(context).textTheme.titleMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              widget.data.channel,
                              style: Theme.of(context).textTheme.labelLarge?.apply(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.75),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0, 0, 5),
                          child: Text(
                            widget.data.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0, 0, 5),
                          child: Text(
                            widget.data.description,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        Tags(tags: widget.data.tags),
                        Container(
                          margin: const EdgeInsets.fromLTRB(0, 5, 0, 5),
                          constraints: const BoxConstraints(
                            maxHeight: 150,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: SingleChildScrollView(
                                    physics: const AlwaysScrollableScrollPhysics(
                                      parent: BouncingScrollPhysics(),
                                    ),
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: mediasList,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Flexible(
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: "截止时间  ",
                                        style: Theme.of(context).textTheme.labelMedium?.apply(
                                              color: Theme.of(context).colorScheme.outline,
                                            ),
                                      ),
                                      TextSpan(
                                        text: getFormattedDateTime(dateTime: widget.data.deadline, shouldShowTime: true),
                                        style: Theme.of(context).textTheme.labelMedium?.apply(
                                              color: Theme.of(context).colorScheme.outline,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
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
        Positioned(
          left: 15,
          child: CachedNetworkImage(
            fadeInDuration: const Duration(milliseconds: 800),
            fadeOutDuration: const Duration(milliseconds: 200),
            placeholder: (context, url) => CircleAvatar(
              radius: 25,
              backgroundColor: Theme.of(context).colorScheme.surface,
              child: const CupertinoActivityIndicator(),
            ),
            imageUrl: widget.data.poster.avatar,
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
        ),
      ],
    );
  }
}
