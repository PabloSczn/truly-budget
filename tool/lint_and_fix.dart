import 'dart:io';

Future<int> run(String cmd, List<String> args) async {
  stdout.writeln('> $cmd ${args.join(' ')}');
  final p = await Process.start(cmd, args, runInShell: true);
  await stdout.addStream(p.stdout);
  await stderr.addStream(p.stderr);
  return await p.exitCode;
}

Future<void> main() async {
  // Format (writes changes)
  if (await run('dart', ['format', '.']) != 0) exit(1);

  // Apply fixable lints
  await run('dart', ['fix', '--apply']);

  // Analyze: fail only on **errors**
  final analyze = await run('dart', ['analyze']);
  if (analyze != 0) {
    stderr.writeln('dart analyze reported errors.');
    exit(analyze);
  }
}
