import 'package:flutter/material.dart';

import '../emoji_prefix_button.dart';

class ExpenseNoteFormField extends StatefulWidget {
  final TextEditingController controller;
  final String emoji;
  final VoidCallback onPickEmoji;
  final String placeholder;

  const ExpenseNoteFormField({
    super.key,
    required this.controller,
    required this.emoji,
    required this.onPickEmoji,
    this.placeholder = 'Expense',
  });

  @override
  State<ExpenseNoteFormField> createState() => _ExpenseNoteFormFieldState();
}

class _ExpenseNoteFormFieldState extends State<ExpenseNoteFormField> {
  void _collapseSelectionIfNeeded() {
    if (!mounted) return;
    final selection = widget.controller.selection;
    if (!selection.isValid || selection.isCollapsed) return;

    widget.controller.selection = TextSelection.collapsed(
      offset: selection.extentOffset,
    );
  }

  void _handleTap() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _collapseSelectionIfNeeded();
    });
    Future<void>.delayed(const Duration(milliseconds: 80), () {
      _collapseSelectionIfNeeded();
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      onTap: _handleTap,
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
