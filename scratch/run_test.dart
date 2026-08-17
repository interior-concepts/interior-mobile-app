import 'dart:io';
import 'dart:convert';

void main() async {
  final process = await Process.start('flutter', ['test', 'scratch/test_widget.dart']);
  final stdoutStr = await process.stdout.transform(utf8.decoder).join();
  final file = File('scratch/stack.txt');
  await file.writeAsString(stdoutStr);
  print('Done!');
}
