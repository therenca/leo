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

		return {
			'results': results,
			'isSuccessful': isSuccessful
		};
	}

	static String getWhereClause(Map<String, dynamic> values){

		String where;
		if(values.length > 0){
			where = 'WHERE';
		} else {
			where = '';
		}

		int tracker = 0;
		values.forEach((key, value){
			tracker++;

			if(values.length == 1){
				where += ' $key=@$key';
			} else {
				if(tracker == values.length) {
					where += ' $key=@$key';
				} else {
					where += ' $key=@$key AND';
				}
			} 
		});

		return where;
	}

	static dynamic fromDB(Map<String, dynamic> data, {String table}){

		if(data['isSuccessful']){
			if(!data['results'].isEmpty){
				if(data['results'].length > 1){
					return data['results'];
				} else {
					return data['results'][0][table];
				}
			}
		}
	}

}