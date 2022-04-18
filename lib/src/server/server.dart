import 'dart:io';
import 'dart:convert';
import 'http_route.dart';
import 'package:leo/leo.dart';

abstract class Server {

	late int port;
	String ip = 'localhost';

	String? logFile;
	String color = 'cyan';
	String header = 'server';

	late Map<String, RequestHandler> routes;

	// thoughts
	// let's have a global middleware utility option
	// that asserts for expected values on all uris/requests before proceeding
	Middleware? middleware;

	String? cert;
	String? privateKey;

	bool https = false;

	Future<void> start() async {
		await pretifyOutput('$header starting ...', color: color);
		var server;

		if(https){
			assert(cert != null);
			assert(privateKey != null);
			SecurityContext security = SecurityContext();
			security.useCertificateChain(cert!);
			security.usePrivateKey(privateKey!);
			server = await HttpServer.bindSecure(
				ip,
				port,
				security
			);

		} else {
			server = await HttpServer.bind(
				ip,
				port,
			);
		}

		await for (var request in server){
			await _handleRequests(request);
		}
	}

	Future<bool> _handleMiddleware(String uri, RequestHandler handler, [Route? route, dynamic data]) async {

		var isProceed = true;
		if(handler.middleware != null){
			for(var index=0; index<handler.middleware!.length; index++){
				var name = handler.middleware![index].name; 
				handler.middleware![index].data = data;
				handler.middleware![index].uri = uri;
				handler.middleware![index].route = route!;
				isProceed = await handler.middleware![index].run();

				if(!isProceed){
					await pretifyOutput('[MIDDLEWARE PER REQUEST | $name | $uri] check failed', color: 'red');
					break;
				}
			}
		}

		return isProceed;
	}

	Future<void> _handleRequests(HttpRequest request) async {

		var clientData;
		var uri = request.uri.path;
		var method = request.method;
		Route route = request.route();
		Map<String, dynamic>? backToClient;

		var mimeType;
		var contentType = request.headers.contentType;
		mimeType = contentType == null ? '' : contentType.mimeType;

		switch(mimeType){

			case 'application/json': {
				var jsonString = await utf8.decoder.bind(request).join();
				clientData = jsonDecode(jsonString);

				break;
			}

			case 'application/x-www-form-urlencoded': {

				break;
			}

			case 'multipart/form-data': {
				clientData = request;
				break;
			}

			default: {
				mimeType = 'Mimetype Not Set';
				break;
			}
		}

		await Log(
			uri, method, header: header, request: request, mimetype: mimeType, data: clientData, logFile: logFile);

		var uriPattern;
		var isGloblMiddlewareSuccessful = true; // by default
		var isMiddlewarePerRequestSuccessful = false; //by default

		if(middleware != null){
			middleware!.route = route;
			middleware!.uri = uriPattern;
			middleware!.data = clientData;
			isGloblMiddlewareSuccessful = await middleware!.run();
		}

		if(isGloblMiddlewareSuccessful){
			switch(method){
				case 'GET': {
					routes.forEach((pattern, _){
						if(route == GET(pattern)){
							uriPattern = pattern;
							return;
						}
					});
					if(uriPattern != null){
						var requestHandler = routes[uriPattern];
						isMiddlewarePerRequestSuccessful = await _handleMiddleware(uriPattern, requestHandler!, route, clientData);
						if(isMiddlewarePerRequestSuccessful){
							backToClient = await requestHandler.get(route, clientData);
						}

					} else {
						pretifyOutput('$header[GET] define request handler for $uri');
					}

					break;
				}

				case 'POST': {
					routes.forEach((pattern, _){
						if(route == POST(pattern)){
							uriPattern = pattern;
							return;
						}
					});
					if(uriPattern != null){

						var requestHandler = routes[uriPattern];
						isMiddlewarePerRequestSuccessful = await _handleMiddleware(uriPattern, requestHandler!, route, clientData);
						if(isMiddlewarePerRequestSuccessful){
							backToClient = await requestHandler.post(route, clientData);
						}

					} else {
						pretifyOutput('[$header][POST] define request handler for $uri');
					}

					break;
				}
			}
		}


		if(backToClient != null){
			request.response.headers.contentType = ContentType.json;
			request.response.write(jsonEncode(backToClient));
		} else {
			if(!isGloblMiddlewareSuccessful || !isMiddlewarePerRequestSuccessful){
				if(!isGloblMiddlewareSuccessful){
					await pretifyOutput('[MAIN MIDDLEWARE | ${middleware!.name} | $uriPattern] check failed', color: 'red');
				}
				request.response.statusCode = HttpStatus.forbidden;
			}
		}

		await request.response.close();
	}
}

abstract class RequestHandler {
	List<Middleware>? middleware;
	Future<Map<String, dynamic>> get(Route route, [dynamic data]);
	Future<Map<String, dynamic>> post(Route route, [dynamic data]);
}

abstract class Middleware {

	String? uri;
	Route? route;
	dynamic data;
	String name = 'Middleware (Set unique name for middleware)';

	Future<bool> run();
}