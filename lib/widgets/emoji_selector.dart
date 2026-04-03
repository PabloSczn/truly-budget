import 'package:flutter/material.dart';

// Lightweight emoji selector
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
    '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍', '🤎', '💌', '💡', '🔥', '✨',
    '⭐',
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
    '🧹', '🛠️', '🧰', '🧼', '🧴', '🪥', '🦷', '📱', '📅', '📦', '🎁', '🗂️',
  ];

  static final Map<String, List<String>> emojiTags = {
    // faces / feelings
    '😀': ['happy', 'smile', 'grin', 'face'],
    '😄': ['happy', 'smile', 'grin'],
    '😁': ['happy', 'smile', 'grin', 'teeth'],
    '🥹': ['teary', 'proud', 'happy', 'cry'],
    '😊': ['happy', 'smile', 'blush', 'content'],
    '😉': ['wink', 'flirt', 'happy'],
    '😍': ['love', 'hearts', 'eyes', 'romance'],
    '😘': ['kiss', 'love', 'heart'],
    '😎': ['cool', 'sunglasses'],
    '🤩': ['star', 'excited', 'amazed'],
    '🥳': ['party', 'celebrate', 'birthday'],
    '🤔': ['think', 'hmm', 'question'],
    '😴': ['sleep', 'tired'],
    '🤯': ['mind blown', 'shock', 'wow'],
    '😭': ['cry', 'sad', 'tears'],
    '😡': ['angry', 'mad'],
    '👍': ['thumbs up', 'ok', 'approve', 'yes'],
    '👎': ['thumbs down', 'no', 'disapprove'],
    '👏': ['applause', 'clap', 'bravo'],
    '🙏': ['pray', 'please', 'thanks'],
    '💪': ['strong', 'gym', 'muscle'],

    // hearts / symbols
    '❤️': ['heart', 'love', 'red'],
    '🧡': ['heart', 'love', 'orange'],
    '💛': ['heart', 'love', 'yellow'],
    '💚': ['heart', 'love', 'green'],
    '💙': ['heart', 'love', 'blue'],
    '💜': ['heart', 'love', 'purple'],
    '🖤': ['heart', 'love', 'black'],
    '🤍': ['heart', 'love', 'white'],
    '🤎': ['heart', 'love', 'brown'],
    '💌': ['love letter', 'letter', 'mail', 'romance', 'envelope', 'heart'],
    '💡': ['idea', 'light', 'bulb'],
    '🔥': ['fire', 'hot', 'flame'],
    '✨': ['sparkles', 'shine', 'magic'],
    '⭐': ['star', 'favorite'],
    '🌟': ['star', 'glow', 'favorite'],
    '⚡': ['bolt', 'zap', 'electric'],
    '☀️': ['sun', 'weather', 'day'],
    '🌧️': ['rain', 'weather', 'cloud'],
    '❄️': ['snow', 'cold', 'winter'],
    '🌈': ['rainbow', 'color'],

    // food & drink
    '🍔': ['burger', 'food', 'lunch'],
    '🍟': ['fries', 'food'],
    '🌮': ['taco', 'food'],
    '🍕': ['pizza', 'food', 'meal'],
    '🍝': ['pasta', 'spaghetti', 'food'],
    '🍣': ['sushi', 'food', 'japanese'],
    '🍱': ['bento', 'food', 'japanese'],
    '🍜': ['ramen', 'noodles', 'food'],
    '🥗': ['salad', 'healthy', 'food'],
    '🍎': ['apple', 'fruit', 'food'],
    '🍌': ['banana', 'fruit'],
    '🍓': ['strawberry', 'fruit'],
    '🍇': ['grapes', 'fruit'],
    '🍫': ['chocolate', 'sweet'],
    '🍪': ['cookie', 'sweet', 'snack'],
    '🍩': ['donut', 'sweet'],
    '☕': ['coffee', 'tea', 'drink'],
    '🍺': ['beer', 'drink', 'bar'],
    '🍷': ['wine', 'drink', 'bar'],

    // home / transport
    '🏠': ['home', 'house'],
    '🏡': ['house', 'garden', 'home'],
    '🏢': ['office', 'building', 'work'],
    '🏥': ['hospital', 'health'],
    '🏫': ['school', 'education'],
    '🏦': ['bank', 'money'],
    '🛒': ['shopping', 'groceries', 'cart'],
    '🚗': ['car', 'transport', 'auto'],
    '🚌': ['bus', 'transport'],
    '🚇': ['metro', 'train', 'underground'],
    '✈️': ['plane', 'flight', 'travel'],
    '⛽': ['fuel', 'gas', 'petrol'],

    // work / money
    '💼': ['work', 'job', 'briefcase', 'salary'],
    '🧾': ['receipt', 'bill', 'expense'],
    '📈': ['up', 'growth', 'stocks', 'increase'],
    '📉': ['down', 'decrease', 'stocks'],
    '💸': ['money', 'cash', 'spend'],
    '💰': ['money', 'bag', 'savings'],
    '💳': ['card', 'credit', 'debit'],

    // activities
    '⚽': ['football', 'soccer', 'sport'],
    '🏀': ['basketball', 'sport'],
    '🎾': ['tennis', 'sport'],
    '🎮': ['game', 'gaming', 'controller'],
    '🎲': ['dice', 'board game', 'game'],
    '🎵': ['music', 'note', 'song'],
    '🎧': ['headphones', 'music'],
    '🎸': ['guitar', 'music'],
    '🎬': ['movie', 'film', 'cinema'],
    '📚': ['books', 'study', 'read'],

    // objects
    '🧹': ['clean', 'broom', 'housework'],
    '🛠️': ['tools', 'repair', 'fix'],
    '🧰': ['toolbox', 'repair'],
    '🧼': ['soap', 'clean'],
    '🧴': ['bottle', 'clean', 'care'],
    '🪥': ['toothbrush', 'teeth'],
    '🦷': ['tooth', 'teeth', 'dentist', 'dental'],
    '📱': ['phone', 'mobile', 'call', 'telephone'],
    '📅': ['calendar', 'date', 'schedule', 'appointment'],
    '📦': ['package', 'parcel', 'box'],
    '🎁': ['gift', 'present'],
    '🗂️': ['organize', 'folder', 'files'],
  };

  List<String> _filterEmojis(String q) {
    if (q.trim().isEmpty) return emojis;
    final terms = q
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();

    bool matches(String emoji) {
      // If user typed an actual emoji, "contains" still works.
      if (emoji.contains(q)) return true;

      final tags = emojiTags[emoji] ?? const [];
      // All terms must be found in any of the tags.
      return terms.every((t) => tags.any((tag) => tag.contains(t)));
    }

    return emojis.where(matches).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filterEmojis(query);

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
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
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
