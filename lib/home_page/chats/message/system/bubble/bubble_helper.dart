import 'package:flutter/material.dart';

class SystemMessageBubbleHelper{
  final void Function(EditableTextState?) setEditableTextState;
  final void Function() removeContextMenu;

  SystemMessageBubbleHelper(this.setEditableTextState, this.removeContextMenu);
}