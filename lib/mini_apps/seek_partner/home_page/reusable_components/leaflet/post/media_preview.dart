import 'dart:io';
import 'package:flutter/material.dart';

class MediaPreview extends StatefulWidget {
  final File file;
  final Function onRemove;

  const MediaPreview({super.key, required this.file, required this.onRemove});

  @override
  State<MediaPreview> createState() => _MediaPreviewState();
}

class _MediaPreviewState extends State<MediaPreview> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.file(
            widget.file,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: () {
              widget.onRemove();
            },
            child: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.outline.withOpacity(0.5),
              radius: 10,
              child: Icon(
                Icons.close_outlined,
                color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
