import 'package:flutter/material.dart';

class EmojiPrefixButton extends StatelessWidget {
  final String emoji;
  final VoidCallback onTap;
  const EmojiPrefixButton(
      {super.key, required this.emoji, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: IconButton(
        padding: EdgeInsets.zero,
        splashRadius: 20,
        onPressed: onTap,
        tooltip: 'Choose emoji',
        icon: Transform.translate(
          offset: const Offset(1, 7),
          child: Text(emoji, style: const TextStyle(fontSize: 22, height: 1)),
        ),
      ),
    );
  }
}
