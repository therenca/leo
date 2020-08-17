import 'dart:io';
import 'create_file.dart';

Future<void> log(String data, {String logFile, bool clear=false}) async {
	await createFile(logFile, clear: clear);
	String now = DateTime.now().toIso8601String();
	String output = '[$now] $data';
	await File(logFile).writeAsString(output, mode: FileMode.append);
}