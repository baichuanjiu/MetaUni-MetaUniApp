import 'package:flutter/material.dart';
import 'package:meta_uni_app/home_page/discover/warehouse/mini_app_introduction/models/mini_app_review.dart';
import 'package:meta_uni_app/reusable_components/formatter/date_time_formatter/date_time_formatter.dart';

import '../ratings/ratings.dart';
import '../stars/stars_rating.dart';

class RatingsAndReviews extends StatelessWidget {
  final MiniAppReview? latestReview;
  final String averageOfRatingsString;
  final int totalNumberOfRatingPeople;
  final String totalNumberOfRatingPeopleString;
  final List<int> stars;

  const RatingsAndReviews(
      {required this.latestReview, required this.averageOfRatingsString, required this.totalNumberOfRatingPeople, required this.totalNumberOfRatingPeopleString, required this.stars, super.key});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "打分 & 评价",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                latestReview == null
                    ? Container()
                    : TextButton(
                        onPressed: () {},
                        child: const Text("查看全部"),
                      ),
              ],
            ),
            Ratings(
              averageOfRatingsString: averageOfRatingsString,
              totalNumberOfRatingPeople: totalNumberOfRatingPeople,
              totalNumberOfRatingPeopleString: totalNumberOfRatingPeopleString,
              stars: stars,
            ),
            Container(
              height: 10,
            ),
            latestReview == null
                ? Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                        child: const Text("还没有人发表过评价呢"),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.create_outlined, size: 18),
                            label: const Text("发表评价"),
                          ),
                        ],
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(15),
                          onTap: () {},
                          child: Card(
                            child: Column(
                              children: [
                                ListTile(
                                  title: Text(latestReview!.title),
                                  subtitle: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      StarsRating(fillColor: Theme.of(context).colorScheme.primary, backgroundColor: Theme.of(context).colorScheme.outline, numberOfStars: latestReview!.stars),
                                    ],
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Text(
                                        getFormattedDateTime(dateTime: latestReview!.createdTime),
                                        style: Theme.of(context).textTheme.labelSmall?.apply(color: Theme.of(context).colorScheme.outline),
                                      ),
                                      Text(
                                        latestReview!.nickname,
                                        style: Theme.of(context).textTheme.labelSmall?.apply(color: Theme.of(context).colorScheme.outline),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  child: Text(
                                    latestReview!.content,
                                    maxLines: 8,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
