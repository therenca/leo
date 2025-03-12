import 'dart:io';
import 'dart:async';

Future<File> createFile(String filePath, {bool clear=false}) async {
	var isExists = await File(filePath).exists();

	if(isExists == false){
		await File(filePath).create(recursive: true);
		
	} else {
		if(clear){
			await File(filePath).writeAsString('');
		}
	}

	return File(filePath);
}