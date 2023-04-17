import 'package:flutter/material.dart';

class CommonMessageBubbleHelper{
  final void Function(EditableTextState?) setEditableTextState;
  final void Function() removeContextMenu;

  CommonMessageBubbleHelper(this.setEditableTextState, this.removeContextMenu);
}