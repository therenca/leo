import 'dart:async';
import 'package:postgres/postgres.dart';

import '../log.dart';
import '../output.dart';

class Auth {
  late String host;
  late int port;
  late String db;
  late String username;
  late String password;

  Auth(
      {required this.host,
      required this.port,
      required this.db,
      required this.username,
      required this.password});
}

class DB {
  late Auth auth;
  String? errorFile;
  bool verbose = false;
  PostgreSQLConnection? _conn;

  DB(this.auth, this.verbose);

  Future<PostgreSQLConnection> get conn async {
    if (_conn == null || (_conn?.isClosed ?? true)) {
      _conn = PostgreSQLConnection(auth.host, auth.port, auth.db,
          username: auth.username, password: auth.password);
      await _conn!.open();
    }
    return _conn!;
  }

  Future<List<Map<String, Map<String, dynamic>>>?> query(String sql,
      {Map<String, dynamic>? values, String? identifier}) async {
    List<Map<String, Map<String, dynamic>>>? results;

    try {
      if (verbose) {
        pretifyOutput('[EXECUTING SQL]', color: Color.cyann, endLine: '');
        pretifyOutput(sql);
      }
      var c = await conn;
      results = await c.mappedResultsQuery(sql, substitutionValues: values);
      if (verbose) {
        pretifyOutput('[RESULTS]', color: Color.cyann, endLine: '');
        pretifyOutput('$results');
      }
    } catch (e) {
      var error = '${identifier ?? '--'}: ${e.toString()}';
      pretifyOutput('[POSTGRESS]', color: Color.cyann, endLine: '');
      pretifyOutput('[ERROR]', color: Color.red, endLine: '');
      pretifyOutput('$error', color: Color.yellow);
      if (errorFile != null) {
        await log(error, errorFile!);
      }
    }
    // thoughts
    // we are returning here unparsed values from db because
    // we assume you want the data as it is from the db, you can parse
    // it yourself

    // the DB.fromDB static method is for parsing the data from the server,
    // gets sanitized before reaching you. This only works with the ORM.

    return results;
  }

  static String getWhereClause(Map<String, dynamic> values) {
    String _where;
    if (values.length > 0) {
      _where = 'WHERE';
    } else {
      _where = '';
    }

    int tracker = 0;
    values.forEach((key, value) {
      tracker++;

      if (values.length == 1) {
        _where += ' $key=@$key';
      } else {
        if (tracker == values.length) {
          _where += ' $key=@$key';
        } else {
          _where += ' $key=@$key AND';
        }
      }
    });

    return _where;
  }

  static String getSetClause(Map<String, dynamic> values) {
    String _set = 'SET';

    int tracker = 0;
    values.forEach((key, value) {
      tracker++;

      if (values.length == 1) {
        _set += ' $key=@$key';
      } else {
        if (tracker == values.length) {
          _set += ' $key=@$key';
        } else {
          _set += ' $key=@$key,';
        }
      }
    });

    return _set;
  }

  static String getConstraints(List<String> constraints) {
    var part = '';
    int threshold = constraints.length - 1;
    for (var index = 0; index < constraints.length; index++) {
      if (index < threshold) {
        part += '${constraints[index]} ';
      } else if (index == threshold) {
        part += '${constraints[index]}';
      }
    }

    return part;
  }

  static List<T>? fromDB<T>(List<Map<String, Map<String, dynamic>>>? data,
      {String? table, String? action}) {
    if (data?.isNotEmpty ?? false) {
      if (data!.length > 1) {
        return data.map<T>((row) {
          var tbl = row.keys.toList().first;
          return row[tbl] as T;
        }).toList();
      } else {
        var tbl = data.first.keys.toList().first;
        var item = data.first[tbl];
        var ac = item?.keys.toList().first;
        T? parsed;
        switch (ac) {
          case 'count':
            {
              parsed = item!['count'] as T;
              break;
            }
          default:
            {
              parsed = item as T;
              break;
            }
        }
        return <T>[parsed!];
      }
    } else {
      return [];
    }
  }
}

enum Joins { inner, left, right, full }
