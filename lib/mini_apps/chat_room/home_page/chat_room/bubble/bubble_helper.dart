import 'package:flutter/material.dart';

class MessageBubbleHelper{
  final void Function(EditableTextState?) setEditableTextState;
  final void Function() removeContextMenu;

  MessageBubbleHelper(this.setEditableTextState, this.removeContextMenu);
}