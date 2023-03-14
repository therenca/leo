# Leo

Server utilities to fast track backend development with dart

It is recommended to use the `as` keyword with the `import` statement when importing the package to prevent name conflicts, for example...
> `import 'package:leo/leo.dart' as leo`

To quickly put a block of code in a try catch.
```dart

// the argument for tryCatch could either be a callback to a function or a future

// as a function
Map<String, dynamic> connectToServer(){
  // may fail to reach the server
}
var results = await leo.tryCatch(connectToServer);

// as a future
Future<Map<String, dynamic>> connectToServer() async {
  // may fail to reach the server
}

var future = connectToServer();
var results = await leo.tryCatch(future);

if(results != null){
  // proceed
}

```

To log output to file 
```dart
await leo.log('data to log', logFile: 'path/to/file', clear: true, time: true);
```

To generate a random ID
```dart
var id = generateUUID(length: 30);
```

To execute a query on postgres
```dart
var dbAuth = {
  'host': 'localhost',
  'port': 5432,
  'db': 'db-name',
  'username': 'user',
  'password': 'pass'
};
var results = await leo.DB(dbAuth).query('SELECT * FROM table');
```

Leo has an ORM to help with getting and updating documents from the db (postgres)
We will be working with a postgres db whose table's schema looks like this
```sql
CREATE TABLE IF NOT EXISTS names(
  id SERIAL PRIMARY KEY,
  firstname TEXT,
  lastname TEXT,
  bio TEXT,
  age TEXT,
  dob TEXT
);
```

```dart
// to fetch all documents
var table = 'names';
var columns = '*';
var documents = await leo.ORM(dbAuth).get(table, columns);
```

```dart
// to fetch specific documents
var whereClause = {
  'firstname': 'john'
};
var documents = await leo.ORM(dbAuth).get(table, columns, values: whereClause);
```

```dart
// to insert
var table = 'names'
var data = {
  'firstname': 'john',
  'lastname': 'doe'
};

Map<String, dynamic>insertedDoc = await leo.ORM(dbAuth).insert(table, data);
```

```dart
// to update
var table = 'names';
var toChange = <String, dynamic>{
  'firstname':'james'
};
var whereClause = <String, dynamic>{
  'id': 1,
};

Map<String, dynamic>updatedDoc = await leo.ORM(dbAuth).update(table, toChange, whereClause);
```

```dart
// to add columns
var table = 'names';
var columns = <Map<String, dynamic>>[
  <String, dynamic>{
    'name': 'middlename',
    'type': 'TEXT',
    'constraints': <String>[
        'UNIQUE',
    ]
  },

  <String, dynamic>{
    'name': 'sirname',
    'type': 'TEXT',
    'constraints': <String>[
        'UNIQUE',
    ]
  },
];

var isAddedColumns = await leo.ORM(dbAuth, verbose: true).alter(table, columns, command: 'ADD');
```

```dart
// to drop columns
var columns = <Map<String, dynamic>>[{'name': 'middlename'}, {'name': 'sirname'}];
var isDropped = await leo.ORM(dbAuth, verbose: true).alter(table, columns, command: 'DROP');
```

```dart
// to delete
var table = 'names';
var whereClause = {
  'id': 1,
};

var isDeleted = await leo.ORM(dbAuth).delete(table, whereClause);
```

>To run complex queries use `leo.DB(dbAuth).query` method instead of the orm

To get a random index between a range of indexes
```dart
var index = leo.getRandomNumber(min: 10, max: 10000);
```

To output info on screen with different colors
```dart

leo.pretifyOutput('to print on screen'); // will print in green
leo.pretifyOutput('to print on screen', leo.Color.red);
```
*Isolate Spawning*
- To start an isolate and have the callback send data back - one way 
```dart
var isolatateName = 'test';
var callback = (List<dynamic> args){ // these args are passed to the callback by leo.initIsolate
  // the first arg is the name of the isolate
  // the second arg is the sendPort from the spawner
  // the third argument is your callbackArgs - actual args for your callback
  // ex: send data back to spawner by args[1].send(data), this will show up on onListenCallback
  // ex: access your function's arguments by args.last
  // ex: access name of isolate by args.first

  print('running this isolate');
  // run some code in this thread
};

var onListenCallback = (receivePort, data){
  // data is from the callback
  print(data);
};

leo.SpawnedIsolate spawned = await leo.initIsolate(
  isolateName,
  callback,
  callbackArgs: [] // your actual callback arguments
  onListenCallback: onListenCallback,
  verbose: true
);

// the spawned instance has the Isolate, ReceivePort and sendPort instances
// you can send back data to the spawned function 
```

- To start an isolate and have the callback send data back and receive as well from main - bi-directional 
```dart
var isolatateName = 'test';
var callback = (List<dynamic> args){ // these args are passed to the callback by leo.initIsolate
  // the first arg is the name of the isolate
  // the second arg is the sendPort from the spawner
  // the third argument is your callbackArgs - actual args for your callback
  // ex: send data back to spawner by args[1].send(data), this will show up on onListenCallback
  // ex: access your function's arguments by args.last
  // ex: access name of isolate by args.first

  // to make this bidirectional
  var port = ReceivePort();
  port.listen((data){
    // data from main
  })
  // send back the sendPort for you to be able to send the data from main
  // you will get this sendPort instance from the spawnedIsolate instance
  args[1].send(port.sendPort);

  print('running this isolate');
  // run some code in this thread
};

var onListenCallback = (receivePort, data){
  // data is from the callback
  print(data);
};

leo.SpawnedIsolate spawned = await leo.initIsolate(
  isolateName,
  callback,
  callbackArgs: [] // your actual callback arguments
  onListenCallback: onListenCallback,
  verbose: true
);

// the spawned instance has the Isolate, ReceivePort and sendPort instances
// you can send back data to the spawned function 

// send data back to the callback
spawned.sendPort.send('back to callback');
```

To distribute work evenly across workers
```dart
var workload = [
  'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight'
];

var howManyParts = 3;
var workloadListing = leo.Fractionate.generate(workload, howManyParts);
```

And 
```dart
/// where
/// listing == [a, b, c, d, e, f, g]
/// and afer processing we will get
/// formatted = [
/// 	[a,b],
/// 	[c,d],
/// 	[e,f],
/// 	[g]
/// ]
var workloadListing = leo.Fractionate.dualsInRow(workload);
```

To create a file quickly (will also create the recursive directories on the path)
```dart
await leo.createFile('/path/to/file');

// to clear a file/truncate a file
await leo.createFile('/path/to/file', clear: true);
```

To create a server.
The server is suited for APIs

```dart
// extend the server class
class MyServer extends leo.Server {

  @override
  final String header = '[server name]';

  @override
  final String ip = 'localhost';

  @override
  final int port = 8080;

  @override
  final leo.Color color = leo.Color.cyan;

  @override
  final String logFile = '/path/to/log';

  @override
  final Map<String, leo.RequestHandler> routes = {
    '/test': TestHandler(), // this RequestHandler is defined below
    '/ws': WebsocketHandler() // this WebSocket is defined below
  };

}

class TestHandler extends leo.RequestHandler {
  @override
  Future<Map<String, dynamic>> get([route, data]) async {
    // to access get parameters, do this
    // let's say the get request from the client is
    // http://localhost/test?key=one
    
    // to access the key value

    var key = route.req.uri.queryParameters['key'];

    var backToClient = <String, dynamic>{
      'isSuccessful': false,
    };
    
    return backToClient;
  }

  @override
  Future<Map<String, dynamic>> post([route, data]) async {
  var backToClient = <String, dynamic>{
    'isSuccessful': false,
  };

  return backToClient;
  }
}

class WebsocketHandler extends leo.Ws {
  /// an instance to store clients for this particluar handler
  leo.WsClients clients;

  WebsocketHandler({
    required this.clients
  });

  @override
  int pingInterval = 10;

  @override
  Future<void> onOpen(socket) async {
    clients.addNamelessClient(socket);
    socket.add('connection opened successfully');
    socket.listen((data) async {
        await onMessage(socket, data);
    },
    onDone: () async  => await onClose(socket),
    onError: (error) async => await onError(socket, error));
  }

  @override
  Future<void> onMessage(socket, data) async {
    leo.pretifyOutput('message from socket: $data');

    switch(data['type']){
      case 'identification': {
        clients.markClient(data['id'], socket);
        socket.add('socket identified');
        break;
      }
    }
  }

  @override
  Future<void> onClose(socket) async {
    leo.pretifyOutput('closing socket ... ', color: leo.Color.red);
    clients.remove(socket);
    leo.pretifyOutput('remaining nameless sockets: ${clients.namelessClients.length}', color: leo.Color.red);
    leo.pretifyOutput('remaining named sockets: ${clients.namedClients.length}', color: leo.Color.red);
    await socket.close();
  }

  @override
  Future<void> onError(socket, error) async {
    leo.pretifyOutput('error occured: $error, closing socket....', color: leo.Color.red);
    clients.remove(socket);
    await socket.close();
  }
}
```

Where `leo.WsClients clients` instance has already been instantiated at the root of the server as shown below
```dart
var testClients = leo.WsClients();
class MyServer extends leo.Server {
 /// server setup
 /// some code
 /// 
 @override
  final Map<String, leo.RequestHandler> routes = {
    '/ws': WebsocketHandler(clients: testClients) // this WebSocket is defined below
  };
}

```
`'/ws': WebsocketHandler(clients: testClients)`
we are passing the `testClients` to the websocket handler so that sockets can be added to this url. The `WsClients` class is a socket manager that adds, marks and removes sockets on connection termination. Once you identify your sockets, you can mark them. Marked sockets can be accessed from `getNamedClients()` or `testClients.namedClients` and unidentified socketes can be accessed from `getNamelessClients()` or `testClients.namelessClients`


to use these acquired websocket connections for this specific url, pass them to other handlers like so

```dart
var testClients = leo.WsClients();
class MyServer extends leo.Server {
 /// server setup
 /// some code
 /// 
 @override
  final Map<String, leo.RequestHandler> routes = {
    '/test': TestHandler(clients: testClients), // get clients to send data back to 
    '/ws': WebsocketHandler(clients: testClients) // pass obj to store clients
  };
}
```

where `TestHandler` is defined with ability to access the sockets
```dart
class TestHandler extends leo.RequestHandler {
  leo.WsClients clients;
  TestHandler({
    required this.clients
  })
  @override
  Future<Map<String, dynamic>> get([route, data]) async {
    // some code
    clients.namedClients[id].add('send data back to frontend');
    clients.namelessClients.forEach((sock) => sock.add('send data back to frontend'))
  }

  @override
  Future<Map<String, dynamic>> post([route, data]) async {
    // some code
  }
}
```

in order to add a middleware in the server, do this:

define the middleware
```dart
class NewMiddleware extends leo.Middleware {

	@override
	String name = 'Middleware Name';

	@override
	Future<bool> run() async {
    //you can access the request obj
    var request = route!.req;
    
    //token eg to check if token is valid for this request handle
    var bearerAuth = route!.req!.headers['Authorization']; r

    // whatever checks you want to make,
    // do them here before the request obj reaches the request handler 

    // if run returs false, the request handler will not execute
		return false; // or true
	}
}
```

add middleware to the request handler like this:
```dart
class Fetch extends leo.RequestHandler {

  // some code

	@override
	List<leo.Middleware>? middleware = [
		NewMiddleware()
	];

	//some code
}
```