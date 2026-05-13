import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../emoji_prefix_button.dart';

class ExpenseNoteFormField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String emoji;
  final VoidCallback onPickEmoji;
  final String placeholder;

  const ExpenseNoteFormField({
    super.key,
    required this.controller,
    this.focusNode,
    required this.emoji,
    required this.onPickEmoji,
    this.placeholder = 'Expense',
  });

  @override
  State<ExpenseNoteFormField> createState() => _ExpenseNoteFormFieldState();
}

class _ExpenseNoteFormFieldState extends State<ExpenseNoteFormField> {
  FocusNode? _internalFocusNode;

  FocusNode get _focusNode => widget.focusNode ?? _internalFocusNode!;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = widget.focusNode == null ? FocusNode() : null;
  }

  @override
  void didUpdateWidget(covariant ExpenseNoteFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode == widget.focusNode) return;
    _internalFocusNode?.dispose();
    _internalFocusNode = widget.focusNode == null ? FocusNode() : null;
  }

  @override
  void dispose() {
    _internalFocusNode?.dispose();
    super.dispose();
  }

  Future<void> _showKeyboard() async {
    try {
      await SystemChannels.textInput.invokeMethod<void>('TextInput.show');
    } on Object {
      // Some test and desktop environments do not attach a text input channel.
    }
  }

  void _handleTap() {
    _focusNode.requestFocus();
    unawaited(_showKeyboard());
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: _focusNode,
      onTap: _handleTap,
      onTapAlwaysCalled: true,
      decoration: InputDecoration(
        labelText: 'What for?',
        hintText: widget.placeholder,
        prefixIcon: EmojiPrefixButton(
          emoji: widget.emoji,
          onTap: widget.onPickEmoji,
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 44,
          minHeight: 44,
          maxWidth: 52,
        ),
      ),
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? 'Please enter a note' : null,
    );
  }
}
