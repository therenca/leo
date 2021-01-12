import 'dart:io';
import 'dart:convert';
import '../output.dart';

abstract class Ws {
	int port;
	String ip = 'localhost';

	String logFile;
	String color = 'cyan';
	String header = 'websocket';

	Future<void> start() async {
		
	}
}