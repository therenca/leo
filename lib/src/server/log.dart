import 'dart:io';
import '../output.dart';
import '../log.dart' as log;

Future<void> Log(String uri, String method, {String? header, HttpRequest? request, String? mimetype, dynamic data, String? logFile}) async {
	if(data == null){
		data = '-';
	} else if(data is HttpRequest){
		data = '[REQUEST OBJECT]';
	}
	var ipAddress;
	if(request !=null){
		var connectionInfo = request.connectionInfo;
		if(connectionInfo != null){
			ipAddress = connectionInfo.remoteAddress.address;
		}
	}
	var now = DateTime.now().toIso8601String();

	await pretifyOutput('[$now][$ipAddress]$header[$method][$mimetype]', endLine: '', color: 'yellow');
	await pretifyOutput('[$uri]', endLine: '', color: 'cyan');
	await pretifyOutput(' <== ', endLine: '', color: 'yellow');
	await pretifyOutput('$data');

	if(logFile != null){
		var toLog = '[$now][$ipAddress]$header[$method][$uri] <== $data';
		await log.log(toLog, logFile: logFile, time: false);
	}
}