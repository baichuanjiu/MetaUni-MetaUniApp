import 'package:flutter/material.dart';
import 'package:meta_uni_app/reusable_components/shimmer/shimmer.dart';
import '../../../../reusable_components/formatter/date_time_formatter/date_time_formatter.dart';
import 'details/note_details_page.dart';
import 'models/note.dart';

class NoteTile extends StatefulWidget {
  final Note? note;

  const NoteTile({super.key, this.note});

  @override
  State<NoteTile> createState() => _NoteTileState();
}

class _NoteTileState extends State<NoteTile> {
  @override
  Widget build(BuildContext context) {
    if (widget.note == null) {
      return const InformationLoadingPlaceholder();
    } else {
      return InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NoteDetailsPage(note: widget.note!),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text(widget.note!.title),
              subtitle: Text(
                "${getFormattedDateTime(dateTime: widget.note!.createdTime)}  V${widget.note!.version}",
                style: TextStyle(color: Theme.of(context).colorScheme.outline),
              ),
              trailing: Icon(
                Icons.read_more_outlined,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 0, 15, 10),
              child: Text(
                widget.note!.description,
                style: Theme.of(context).textTheme.bodyMedium?.apply(color: Theme.of(context).colorScheme.outline),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }
  }
}

class InformationLoadingPlaceholder extends StatelessWidget {
  const InformationLoadingPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ShimmerLoading(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(15, 15, 20, 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(0, 0, 0, 5),
                height: 20,
                width: 100,
                color: Theme.of(context).colorScheme.surface,
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(0, 0, 0, 20),
                height: 10,
                width: 120,
                color: Theme.of(context).colorScheme.surface,
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(25, 0, 0, 5),
                height: 15,
                color: Theme.of(context).colorScheme.surface,
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(0, 0, 0, 5),
                height: 15,
                color: Theme.of(context).colorScheme.surface,
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(0, 0, 0, 5),
                height: 15,
                color: Theme.of(context).colorScheme.surface,
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(0, 0, 0, 5),
                height: 15,
                color: Theme.of(context).colorScheme.surface,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
