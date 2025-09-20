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
      setState(() => _version = '${info.version}+${info.buildNumber}');
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
