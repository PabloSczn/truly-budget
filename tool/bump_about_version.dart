import 'dart:io';

void main() {
  final pubspec = File('pubspec.yaml');
  if (!pubspec.existsSync()) {
    stderr.writeln('pubspec.yaml not found.');
    exit(1);
  }

  final pubspecText = pubspec.readAsStringSync();
  final match =
      RegExp(r'^version:\s*([^\s#]+)', multiLine: true).firstMatch(pubspecText);
  if (match == null) {
    stderr.writeln('Could not find "version:" in pubspec.yaml.');
    exit(1);
  }
  final version = match.group(1)!;

  const aboutPath = 'lib/screens/about_screen.dart';
  final aboutFile = File(aboutPath);
  if (!aboutFile.existsSync()) {
    stderr.writeln('File not found: $aboutPath');
    exit(1);
  }

  var code = aboutFile.readAsStringSync();

  // Replace only the string literal, preserve comments/spacing.
  final re = RegExp(r"(static\s+const\s+_appVersion\s*=\s*')([^']*)(')");
  if (!re.hasMatch(code)) {
    stderr.writeln('Could not find static const _appVersion in $aboutPath');
    exit(1);
  }

  final newCode =
      code.replaceFirstMapped(re, (m) => "${m.group(1)}$version${m.group(3)}");

  if (newCode != code) {
    aboutFile.writeAsStringSync(newCode);
    stdout.writeln('Updated _appVersion to $version in $aboutPath');
    // Exit 2 so pre-commit knows files changed and asks you to re-commit.
    exit(2);
  } else {
    stdout.writeln('About screen already up to date ($version).');
  }
}
