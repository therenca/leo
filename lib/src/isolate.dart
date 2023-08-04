import 'dart:async';
import 'dart:isolate';
import 'output.dart';

Future<SpawnedIsolate> initIsolate(
	String name,
	Function(List<Object?>) callback,
	{
		Function? onListenCallback,
		List<dynamic>? callbackArgs,
		bool verbose=false
	}) async {

	Isolate isolate;
	var isolateName = '[isolate][$name]';
	var completer = Completer<SpawnedIsolate>();
	var receivePort = ReceivePort();

	isolate = await Isolate.spawn(callback, [name, receivePort.sendPort, callbackArgs]);
	if(verbose){
		pretifyOutput('$isolateName ----- started ---- ', color: Color.cyann);
	}

	Stream stream = receivePort.asBroadcastStream();
	stream.listen((data) async {
		if(data is SendPort){
			completer.complete(SpawnedIsolate(
				stream: stream,
				sendPort: data,
				isolate: isolate,
				receivePort: receivePort,
			));
		} else if(data == 'done'){
			receivePort.close();
			if(verbose){
				pretifyOutput('$isolateName ------ ended -----', color: Color.red);
			}
		} else {
			if(verbose){
				pretifyOutput('$isolateName: $data');
			}
			
			if(onListenCallback != null){
				await onListenCallback(receivePort, data);
			}
		}
	});

	return completer.future;
}

class SpawnedIsolate {
	Stream stream;
	Isolate isolate;
	SendPort sendPort;
	ReceivePort receivePort;

	SpawnedIsolate({
		required this.stream,
		required this.isolate,
		required this.sendPort,
		required this.receivePort,
	});
}