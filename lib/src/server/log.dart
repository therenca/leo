import 'dart:io';
import '../output.dart';

Future<void> Log(String uri, String method, {String header, HttpRequest request, dynamic data}) async {
	if(data == null){
		data = '-';
	}
	var now = DateTime.now().toIso8601String();

	await pretifyOutput('[$now]$header[$method]', endLine: '', color: 'yellow');
	await pretifyOutput('[$uri]', endLine: '', color: 'cyan');
	await pretifyOutput(' <== ', endLine: '', color: 'yellow');
	await pretifyOutput('$data');

}