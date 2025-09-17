import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _appVersion = '1.0.1'; // in sync with pubspec

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'TrulyBudget',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text('Version: $_appVersion'),
          const SizedBox(height: 24),
          const Text('Contact'),
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('sancheznarro.pablo@gmail.com'),
            onTap: () async {
              final uri = Uri(
                scheme: 'mailto',
                path: 'sancheznarro.pablo@gmail.com',
                query: 'subject=TrulyBudget%20Feedback',
              );
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
          ),
        ],
      ),
    );
  }
}
