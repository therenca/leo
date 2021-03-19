import 'dart:io';
import 'dart:convert';
import 'log.dart';
import 'http_route.dart';
import '../output.dart';

abstract class Server {

	int port;
	String ip = 'localhost';

	String logFile;
	String color = 'cyan';
	String header = 'server';
	Map<String, RequestHandler> routes;

	// thoughts
	// let's have a global middleware utility option
	// that asserts for expected values on all uris/requests before proceeding

	String cert;
	String privateKey;

	bool https = false;

	Future<void> start() async {
		await pretifyOutput('$header starting ...', color: color);
		var server;

		if(https){
			assert(cert != null);
			assert(privateKey != null);
			SecurityContext security = SecurityContext();
			security.useCertificateChain(cert);
			security.usePrivateKey(privateKey);
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

	Future<void> _handleRequests(HttpRequest request) async {

		var clientData;
		Map<String, dynamic> postData;
		var uri = request.uri.path;
		var method = request.method;
		Map<String, dynamic> backToClient;
		Route route = request.route();

		var mimeType;
		var contentType = request.headers.contentType;
		// clientData = await utf8.decodeStream(request);
		// clientData = await utf8.decoder.bind(request).join();
		mimeType = contentType == null ? '' : contentType.mimeType;


		switch(mimeType){

			case 'application/json': {
				clientData = await utf8.decoder.bind(request).join();
				postData = jsonDecode(clientData);

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
					var proceed = await requestHandler.Middleware(uriPattern, route, postData);
					if(proceed){
						backToClient = await requestHandler.Get(route, postData);
					}
				} else {
					pretifyOutput('[$header][GET] define request handler for $uri');
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
					var proceed = await requestHandler.Middleware(uriPattern, route, postData == null ? clientData : postData);
					if(proceed){
						backToClient = await requestHandler.Post(route, postData == null ? clientData : postData);
					}
				} else {
					pretifyOutput('[$header][POST] define request handler for $uri');
				}

				break;
			}
		}

		if(backToClient != null){
			request.response.headers.contentType = ContentType.json;
			request.response.write(jsonEncode(backToClient));
		}

		await request.response.close();
	}
}

abstract class RequestHandler {
	Future<Map<String, dynamic>> Get([Route route, dynamic data]);
	Future<Map<String, dynamic>> Post([Route route, dynamic data]);
	Future<bool> Middleware(String uri, [Route route, dynamic data]) async {
		return true;
	}
}