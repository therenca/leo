import 'dart:async';
import 'dart:isolate';

import 'output.dart';

Future<SpawnedIsolate> initIsolate<T>(
    String name, void Function(List<Object?>) callback,
    {Function? onListenCallback, T? args, bool verbose = false}) async {
  Isolate isolate;
  var receivePort = ReceivePort();
  var isolateName = '[isolate][$name]';
  var completer = Completer<SpawnedIsolate>();

  isolate = await Isolate.spawn(callback, [name, receivePort.sendPort, args]);
  if (verbose) {
    pretifyOutput('$isolateName ----- started ---- ', color: Color.cyann);
  }

  receivePort.listen((data) async {
    if (data is SendPort) {
      completer.complete(SpawnedIsolate(
          isolate: isolate, sendPort: data, receivePort: receivePort));
    } else if (data == 'done') {
      receivePort.close();
      if (verbose) {
        pretifyOutput('$isolateName ------ ended -----', color: Color.red);
      }
    } else {
      if (onListenCallback != null) {
        await onListenCallback(receivePort, data);
      }
    }
  });

  return completer.future;
}

class SpawnedIsolate {
  Isolate isolate;
  ReceivePort receivePort;
  SendPort sendPort;

  SpawnedIsolate(
      {required this.isolate,
      required this.receivePort,
      required this.sendPort});
}
