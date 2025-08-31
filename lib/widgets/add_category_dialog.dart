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

  Future<void> _pickEmoji() async {
    final e = await pickEmoji(context);
    if (e != null && e.isNotEmpty) {
      setState(() => selectedEmoji = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Category'),
      content: Form(
        key: _formKey,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Leading emoji acts as the selector button
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _pickEmoji,
              child: Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    Text(selectedEmoji, style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Category name',
                  hintText: 'e.g. Groceries',
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please enter a name'
                    : null,
              ),
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
