import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  static const _emailAddress = 'sancheznarro.pablo@gmail.com';
  String? _version;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    final versionLabel = info.buildNumber.isEmpty
        ? info.version
        : '${info.version} (${info.buildNumber})';
    if (!mounted) return;
    setState(() => _version = versionLabel);
  }

  Future<void> _handleEmailTap() async {
    final uri = Uri(
      scheme: 'mailto',
      path: _emailAddress,
      queryParameters: const {'subject': 'Feedback'},
    );

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) return;
    } catch (_) {
      // Fall back to copying the address when no email app is available.
    }

    await Clipboard.setData(const ClipboardData(text: _emailAddress));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No email app found. Email address copied to clipboard.'),
      ),
    );
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
            subtitle: const Text(_emailAddress, softWrap: true),
            isThreeLine: true,
            onTap: _handleEmailTap,
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
