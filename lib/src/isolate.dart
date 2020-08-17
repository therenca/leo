import 'dart:async';
import 'dart:isolate';

import 'output.dart';

Future<Map<String, dynamic>> initIsolate(
	String name,
	Function callback,
	{
		Function onListenCallback,
		List<dynamic> callbackArgs,
		bool verbose=false
	}) async {

	Isolate isolate;
	var isolateName = 'Isolate $name';
	var completer = Completer<Map<String, dynamic>>();
	var isolateToMainStream = ReceivePort();
	var isolateParts = <String, dynamic>{};

	isolate = await Isolate.spawn(callback, [isolateName, isolateToMainStream.sendPort, callbackArgs]);
	isolateParts['isolate'] = isolate;
	// isolateParts['isolateToMainStreamPort'] = isolateToMainStream;

	String header = '[$isolateName]';

	if(verbose){
		await pretifyOutput('$header ----- started ---- ', color: 'cyan');
	}

	isolateToMainStream.listen((data) async {

		if(data is SendPort){
			isolateParts['sendPort'] = data;
			completer.complete(isolateParts);
		} else if(data == 'done'){
			isolateToMainStream.close();
			if(verbose){
				pretifyOutput('[$isolateName] ------ ended -----', color: 'red');
			}
		} else {
			if(onListenCallback != null){
				await onListenCallback(isolateToMainStream, data);
			}
			// onListenCallback ?? await onListenCallback(data);
		}
	});

	return completer.future;
}