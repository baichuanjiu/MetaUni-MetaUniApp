import 'package:flutter/material.dart';
import 'tag.dart';

class Tags extends StatelessWidget{
  final List<String> tags;

  const Tags({super.key,required this.tags});

  @override
  Widget build(BuildContext context) {
    List<Tag> data = [];
    for (String tag in tags) {
      data.add(Tag(text: tag,));
    }

    return Wrap(children: data,);
  }

}