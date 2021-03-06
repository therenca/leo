import 'dart:async';
import 'output.dart';

Future<dynamic> tryCatch(dynamic callback, 
	{List<dynamic> args, bool verbose=false}) async {
	Completer completer = Completer<dynamic>();

	var results;
	try{
		if(callback is Future){
			results = await callback;
		}

		if(callback is Function){
			if(args != null){
				results = callback(args);
			} else {
				results = callback();
			}
		}
	} catch(e){
		if(verbose){
			pretifyOutput('[TRY CATCH] ${e.toString()}', color: 'red');
		}
	}

	completer.complete(results);
	return completer.future;
}