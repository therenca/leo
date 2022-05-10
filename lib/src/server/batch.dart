import '../output.dart';
import 'server.dart' as server;
import 'http_route.dart' as http_route;

class Batch {
	String uri;
	dynamic data;
	String method;
	http_route.Route route;
	Map<String, server.RequestHandler> routes;

	bool? _isMiddlewarePerRequestSuccessful;

	Batch({
		required this.uri,
		required this.data,
		required this.route,
		required this.routes,
		required this.method,
	});

	bool? get isMiddlewarePerRequestSuccessful => _isMiddlewarePerRequestSuccessful;

	Future <void> _handleMiddleware() async {
		var handler = routes[uri]!;
		_isMiddlewarePerRequestSuccessful = true;

		if(handler.middleware != null){
			for(var index=0; index<handler.middleware!.length; index++){
				var name = handler.middleware![index].name; 
				handler.middleware![index].data = data;
				handler.middleware![index].uri = uri;
				handler.middleware![index].route = route;
				bool isProceed = await handler.middleware![index].run();

				if(isProceed == false){
					_isMiddlewarePerRequestSuccessful = false;
					await pretifyOutput('[MIDDLEWARE PER REQUEST | $name | $uri] check failed', color: 'red');
					return;
				}
			}
		}
	}

	Future<Map<String, dynamic>?> run() async {
		Map<String, dynamic>? backToClient;
		var handler = routes[uri];
		await _handleMiddleware();
		if(_isMiddlewarePerRequestSuccessful ?? false){
			switch(method){
				case 'GET': {
					backToClient = await handler!.get(route, data);
					break;
				}

				case 'POST': {
					backToClient = await handler!.post(route, data);
					break;
				}
			}
		}

		return backToClient;
	}
}