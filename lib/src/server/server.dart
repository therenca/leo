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

		Map<String, dynamic> postData;
		var uri = request.uri.path;
		var method = request.method;
		Map<String, dynamic> backToClient;
		Route route = request.route();

		var contentType = request.headers.contentType;
		if(contentType != null){
			var mimeType = contentType.mimeType;
			if(mimeType == 'application/json'){
				String postDataJson = await utf8.decoder.bind(request).join();
				postData = jsonDecode(postDataJson);
			}
		}

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
					backToClient = await requestHandler.Get(route, postData);
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
					backToClient = await requestHandler.Post(route, postData);
				} else {
					pretifyOutput('[$header][POST] define request handler for $uri');
				}

				break;
			}
		}

		await Log(
			uri, method, header: header, request: request, data: postData, logFile: logFile);

		if(backToClient != null){
			request.response.write(jsonEncode(backToClient));
		}

		await request.response.close();

	}
}

abstract class RequestHandler {
	Future<Map<String, dynamic>> Get([Route route, Map<String, dynamic> data]);
	Future<Map<String, dynamic>> Post([Route route, Map<String, dynamic>  data]);
}