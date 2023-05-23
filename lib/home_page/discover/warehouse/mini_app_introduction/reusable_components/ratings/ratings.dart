import 'package:flutter/material.dart';
import '../stars/stars.dart';

class Ratings extends StatelessWidget {
  final String averageOfRatingsString;
  final int totalNumberOfRatingPeople;
  final String totalNumberOfRatingPeopleString;
  final List<int> stars;

  const Ratings({required this.averageOfRatingsString,required this.totalNumberOfRatingPeople,required this.totalNumberOfRatingPeopleString,required this.stars, super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            children: [
              Text(
                averageOfRatingsString,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              Text(
                "out of 5",
                style: Theme.of(context).textTheme.labelLarge?.apply(color: Theme.of(context).colorScheme.outline),
              ),
            ],
          ),
        ),
        Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Stars(color: Theme.of(context).colorScheme.onSurfaceVariant, numberOfStars: 5),
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.45,
                        ),
                        child: LinearProgressIndicator(
                          value: totalNumberOfRatingPeople == 0 ? 0 : stars[4] / totalNumberOfRatingPeople,
                          valueColor: AlwaysStoppedAnimation(Theme.of(context).colorScheme.onSurfaceVariant),
                          borderRadius: BorderRadius.circular(2),
                          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Stars(color: Theme.of(context).colorScheme.onSurfaceVariant, numberOfStars: 4),
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.45,
                        ),
                        child: LinearProgressIndicator(
                          value: totalNumberOfRatingPeople == 0 ? 0 : stars[3] / totalNumberOfRatingPeople,
                          valueColor: AlwaysStoppedAnimation(Theme.of(context).colorScheme.onSurfaceVariant),
                          borderRadius: BorderRadius.circular(2),
                          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Stars(color: Theme.of(context).colorScheme.onSurfaceVariant, numberOfStars: 3),
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.45,
                        ),
                        child: LinearProgressIndicator(
                          value: totalNumberOfRatingPeople == 0 ? 0 : stars[2] / totalNumberOfRatingPeople,
                          valueColor: AlwaysStoppedAnimation(Theme.of(context).colorScheme.onSurfaceVariant),
                          borderRadius: BorderRadius.circular(2),
                          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Stars(color: Theme.of(context).colorScheme.onSurfaceVariant, numberOfStars: 2),
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.45,
                        ),
                        child: LinearProgressIndicator(
                          value: totalNumberOfRatingPeople == 0 ? 0 : stars[1] / totalNumberOfRatingPeople,
                          valueColor: AlwaysStoppedAnimation(Theme.of(context).colorScheme.onSurfaceVariant),
                          borderRadius: BorderRadius.circular(2),
                          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Stars(color: Theme.of(context).colorScheme.onSurfaceVariant, numberOfStars: 1),
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.45,
                        ),
                        child: LinearProgressIndicator(
                          value: totalNumberOfRatingPeople == 0 ? 0 : stars[0] / totalNumberOfRatingPeople,
                          valueColor: AlwaysStoppedAnimation(Theme.of(context).colorScheme.onSurfaceVariant),
                          borderRadius: BorderRadius.circular(2),
                          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                "$totalNumberOfRatingPeopleString 人打分",
                style: Theme.of(context).textTheme.labelMedium?.apply(color: Theme.of(context).colorScheme.outline),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
