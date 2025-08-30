import 'package:flutter/material.dart';

/// Lightweight emoji selector
Future<String?> pickEmoji(BuildContext context) async {
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => _EmojiSheet(),
  );
}

class _EmojiSheet extends StatefulWidget {
  @override
  State<_EmojiSheet> createState() => _EmojiSheetState();
}

class _EmojiSheetState extends State<_EmojiSheet> {
  final controller = TextEditingController();
  String query = '';

  static const emojis = <String>[
    // Common
    '😀', '😄', '😁', '🥹', '😊', '😉', '😍', '😘', '😎', '🤩', '🥳', '🤔',
    '😴', '🤯', '😭', '😡', '👍', '👎', '👏', '🙏', '💪',
    '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍', '🤎', '💡', '🔥', '✨', '⭐',
    '🌟', '⚡', '☀️', '🌧️', '❄️', '🌈',
    // Food
    '🍔', '🍟', '🌮', '🍕', '🍝', '🍣', '🍱', '🍜', '🥗', '🍎', '🍌', '🍓',
    '🍇', '🍫', '🍪', '🍩', '☕', '🍺', '🍷',
    // Home/transport
    '🏠', '🏡', '🏢', '🏥', '🏫', '🏦', '🛒', '🚗', '🚌', '🚇', '✈️', '⛽',
    // Work/money
    '💼', '🧾', '📈', '📉', '💸', '💰', '🏦', '💳',
    // Activities
    '⚽', '🏀', '🎾', '🎮', '🎲', '🎵', '🎧', '🎸', '🎬', '📚',
    // Objects
    '🧹', '🛠️', '🧰', '🧼', '🧴', '🪥', '📦', '🎁', '🗂️',
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = query.isEmpty
        ? emojis
        : emojis.where((e) => e.contains(query)).toList();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search or paste an emoji…',
              ),
              onChanged: (v) => setState(() => query = v.trim()),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                itemCount: filtered.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemBuilder: (_, i) {
                  final emoji = filtered[i];
                  return InkWell(
                    onTap: () => Navigator.of(context).pop(emoji),
                    child: Center(
                        child:
                            Text(emoji, style: const TextStyle(fontSize: 24))),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
