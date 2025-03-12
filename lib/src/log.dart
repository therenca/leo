import 'dart:io';
import 'create_file.dart';

Future<void> log(String data, String? file, {
	bool clear=false,
	bool time=true
}) async {
	if(file != null) await createFile(file, clear: clear);

	String output;
	if(time){
		String now = DateTime.now().toIso8601String();
		output = '[$now] $data\n';
	} else {
		output = '$data\n';
	}

	if(file != null){
		await File(file ).writeAsString(output, mode: FileMode.append);
	}
}