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

var isInserted = await leo.ORM(dbAuth).insert(table, data);
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

var isUpdated = await leo.ORM(dbAuth).update(table, toChange, whereClause);
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
leo.pretifyOutput('to print on screen', color: 'red'); // white, red, magenta, yellow, cyan, blue, defaults to green
```

To start an isolate
```dart
var isolatateName = 'test'
var callback = (){ print('running this isolate')  return 'testing'; };
var onListenCallback = (data){
  print(data);
}
var isolateInfo = await initIsolate(isolateName, callback, onListenCallback: onListenCallback, verbose: true);

// isolateInfo returns a map with the isolate instance, receiver and the sendPort
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
  final String color = 'cyan'; // white, red, magenta, yellow, cyan, blue, defaults to green

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