import '../output.dart';
import 'server.dart' as server;
import 'http_route.dart' as http_route;
import 'response.dart';

class Batch {
	String uri;
	dynamic data;
	String method;
	http_route.Route route;
	bool verbose;
	Map<String, server.RequestHandler> routes;

	bool? _isMiddlewarePerRequestSuccessful;

	Batch({
		required this.uri,
		required this.data,
		required this.route,
		required this.routes,
		required this.method,
		required this.verbose,
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
					if(verbose){
						await pretifyOutput('[MIDDLEWARE PER REQUEST | $name | $uri] check failed', color: Color.red);
					}
					return;
				}
			}
		}
	}

	Future<Response?> run() async {
		Response? response;
		var handler = routes[uri];
		await _handleMiddleware();
		if(_isMiddlewarePerRequestSuccessful ?? false){
			// Use the new generic handle method that supports all HTTP methods
			response = await handler!.handle(route, data);
		}

		return response;
	}
}