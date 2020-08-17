import 'dart:math';
import 'dart:convert';

String generateUUID({int length=25}){
	var _random = Random.secure();
	var values = List<int>.generate(length, (i) => _random.nextInt(256));
	return base64Url.encode(values);
}