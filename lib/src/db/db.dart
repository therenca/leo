import 'dart:async';
import 'package:postgres/postgres.dart';

import '../log.dart';
import '../output.dart';

class DB {
	dynamic _conn;
	String errorFile;
	Map<String, dynamic> auth;
	DB(this.auth, {String this.errorFile}){

		_conn = PostgreSQLConnection(
			auth['host'], auth['port'], auth['db'],
			username: auth['username'],
			password: auth['password']
		);
	}

	Future<Map<String, dynamic>> query(
		String sql, {Map<String, dynamic> values, String identifier}) async {
		
		await _conn.open();

		List<dynamic> results;
		bool isSuccessful = true;

		try {
			results = await _conn.mappedResultsQuery(
				sql, substitutionValues: values
			);
		} catch(e){
			var error = '$identifier: ${e.toString()}';
			results = [];
			isSuccessful = false;

			pretifyOutput('[POSTGRESS] $error', color: 'red');
			if(errorFile != null){
				await log(error, logFile: errorFile);
			}
		}

		await _conn.close();

		// thoughts
		// we are returning here unparsed values from db because
		// we assume you want the data as it is from the db, you can parse
		// it yourself

		// the DB.fromDB static method is for parsing the data from the server,
		// gets sanitized before reaching you. This only works with the ORM.

		return {
			'results': results,
			'isSuccessful': isSuccessful
		};
	}

	static String getWhereClause(Map<String, dynamic> values){

		String _where;
		if(values.length > 0){
			_where = 'WHERE';
		} else {
			_where = '';
		}

		int tracker = 0;
		values.forEach((key, value){
			tracker++;

			if(values.length == 1){
				_where += ' $key=@$key';
			} else {
				if(tracker == values.length) {
					_where += ' $key=@$key';
				} else {
					_where += ' $key=@$key AND';
				}
			} 
		});

		return _where;
	}

	static String getSetClause(Map<String, dynamic> values){
		String _set = 'SET';

		int tracker = 0;
		values.forEach((key, value){
			tracker++;

			if(values.length == 1){
				_set += ' $key=@$key';
			} else {
				if(tracker == values.length) {
					_set += ' $key=@$key';
				} else {
					_set += ' $key=@$key,';
				}
			} 
		});

		return _set;

	}

	static String getConstraints(List<String> constraints){
		var part = '';
		int threshold = constraints.length - 1;
		for(var index=0; index<constraints.length; index++){
			if(index < threshold){
				part += '${constraints[index]} ';
			} else if(index == threshold){
				part += '${constraints[index]}';
			}
		}

		return part;
	}

	static dynamic fromDB(Map<String, dynamic> data, {String table}){

		if(data['isSuccessful']){
			if(!data['results'].isEmpty){
				if(data['results'].length > 1){
					return data['results'].map((row){
						return row[table];
					}).toList();
				} else {
					return [data['results'][0][table]];
				}
			} else {
				return [];
			}
		}
	}
}