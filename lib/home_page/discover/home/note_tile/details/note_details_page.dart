import 'package:flutter/material.dart';

import '../../../../../reusable_components/formatter/date_time_formatter/date_time_formatter.dart';
import '../history/note_history_page.dart';
import '../models/note.dart';

class NoteDetailsPage extends StatefulWidget {
  final Note note;

  const NoteDetailsPage({super.key, required this.note});

  @override
  State<NoteDetailsPage> createState() => _NoteDetailsPageState();
}

class _NoteDetailsPageState extends State<NoteDetailsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("开发者笔记"),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const NoteHistoryPage(),
                ),
              );
            },
            icon: const Icon(
              Icons.article_outlined,
            ),
            tooltip: "历史",
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.note.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Container(
              height: 5,
            ),
            Text(
              "${getFormattedDateTime(dateTime: widget.note.createdTime)}  V${widget.note.version}",
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
            Container(
              height: 10,
            ),
            Text(
              widget.note.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
