import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String? _version;

  @override
  void initState() {
    super.initState();
    () async {
      final info = await PackageInfo.fromPlatform();
      final versionLabel = info.buildNumber.isEmpty
          ? info.version
          : '${info.version} (${info.buildNumber})';
      setState(() => _version = versionLabel);
    }();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('TrulyBudget',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Version: ${_version ?? '…'}'),
          const SizedBox(height: 24),
          const Text('Contact'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.email_outlined),
            title: const Text('Email'),
            subtitle: const Text(
              'sancheznarro.pablo@gmail.com',
              softWrap: true,
            ),
            isThreeLine: true,
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
          const SizedBox(height: 8),
          Text(
            'TrulyBudget is a solo project.\nI am always open to feedback and quick to fix any errors. Don\'t hesitate to reach out!',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
