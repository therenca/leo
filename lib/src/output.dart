import 'dart:io';
import 'dart:async';
import 'create_file.dart';
import 'package:colorize/colorize.dart';

Future<void> formatError(String info, 
	{
		String error='',
		String filePath,
		bool clear=false
	}) async {

	Colorize errorInfo = Colorize('$info: $error');
	errorInfo.red();
	// errorInfo.bgWhite();
	// errorInfo.blink();
	// errorInfo.apply();

	print(errorInfo);
	await _write(filePath, '$info:$error', clear);
}

Future<void> pretifyOutput(String info,
	{
		String color='', 
		String filePath,
		bool clear=false
	}) async {

	Colorize toPretify = Colorize(info);

	switch(color){

		case 'white': {
			toPretify.white();
		}
		break;

		case 'red': {
			toPretify.red();
		}
		break;

		case 'yellow': {
			toPretify.yellow();
		}
		break;

		case 'magenta': {
			toPretify.magenta();
		}
		break;

		case 'cyan': {
			toPretify.cyan();
		}
		break;

		case 'blue': {
			toPretify.blue();
		}
		break;

		default: {
			toPretify.green();
		}
		break;
	}

	print(toPretify);

	if(filePath != null){
		await _write(filePath, info, clear);
	}
}

Future<void> _write(String filePath, String data, bool clear) async {
	await createFile(filePath, clear: clear);
	await File(filePath).writeAsString('$data\n', mode: FileMode.append);
}