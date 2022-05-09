import 'server.dart' as server;
import 'http_route.dart' as http_route;

class MatchUri {
	static String? GET(Map<String, server.RequestHandler> routes, http_route.Route route){
		String? matched;
		routes.forEach((pattern, _){
			if(route == http_route.GET(pattern)){
				matched = pattern;
				return;
			}
		});

		return matched;
	}

	static String? POST(Map<String, server.RequestHandler> routes, http_route.Route route){
		String? matched;
		routes.forEach((pattern, _){
			if(route == http_route.POST(pattern)){
				matched = pattern;
				return;
			}
		});

		return matched;
	}
}