import 'package:flutter/material.dart';
import 'package:truly_budget/widgets/emoji_selector.dart';

class AddCategoryDialog extends StatefulWidget {
  const AddCategoryDialog({super.key});

  @override
  State<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  final nameCtrl = TextEditingController();
  String selectedEmoji = '🗂️';
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Category'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Category name',
                prefixIcon: Icon(Icons.label_outline),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please enter a name'
                  : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('Emoji:', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(width: 8),
                Text(selectedEmoji, style: const TextStyle(fontSize: 24)),
                const Spacer(),
                OutlinedButton.icon(
                  icon: const Icon(Icons.emoji_emotions_outlined),
                  label: const Text('Choose'),
                  onPressed: () async {
                    final e = await pickEmoji(context);
                    if (e != null && e.isNotEmpty) {
                      setState(() => selectedEmoji = e);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, (nameCtrl.text.trim(), selectedEmoji));
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
