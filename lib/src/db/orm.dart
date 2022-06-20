import 'db.dart';
import '../output.dart';

class ORM {
	Map<String, dynamic> auth;
	bool verbose;

	ORM(this.auth, {this.verbose=false});

	Future<dynamic> _run(sql, [Map<String, dynamic>?values, String? table, bool? isReturning]) async {
		if(isReturning == true){
			sql = sql + ' RETURNING *';
		}
		var fromDB = await DB(auth, verbose: verbose).query(sql, values: values, identifier: table);
		if(isReturning == true){
			return fromDB['isSuccessful'] ? DB.fromDB(fromDB, table: table).first : null;
		} else {
			return fromDB['isSuccessful'];
		}
	}

	Future<dynamic> get(
		String table, String column, {Map<String, dynamic>? values}) async {	
		values == null ? values = <String, dynamic>{} : values = values; 
		String whereClause = DB.getWhereClause(values);

		var sql;
		if(whereClause.isEmpty){
			sql = 'SELECT $column FROM $table';
		} else {
			sql = 'SELECT $column FROM $table $whereClause';
		}

		if(verbose){
			pretifyOutput('[SQL] $sql');
		}
		
		var fromDB = await DB(auth).query(sql, values: values, identifier: table);
		return DB.fromDB(fromDB, table: table);
	}

	Future<Map<String, dynamic>?> insert(String table, Map<String, dynamic> values) async {
		String valuesF = '';
		String columns = '';

		int tracker = 0;
		values.forEach((key, value){
			tracker++;

			if(values.length == 1){
				columns += key;
				valuesF += ' @$key';
			} else {
				if(tracker == values.length) {
					columns += key;
					valuesF += ' @$key';
				} else {
					columns += '$key, ';
					valuesF += '@$key, ';
				}
			}
		});

		var sql = 'INSERT INTO $table ($columns) values($valuesF)';
		return await _run(sql, values, table, true) as Map<String, dynamic>?;
	}

	Future<Map<String, dynamic>?> update(
		String table, Map<String, dynamic> change, Map<String, dynamic> values) async {

		String whereClause = DB.getWhereClause(values);
		String updateClause = DB.getSetClause(change);
		var sql = 'UPDATE $table $updateClause $whereClause';

		values.addAll(change);
		return await _run(sql, values, table, true) as Map<String, dynamic>?;
	}

	Future<bool> alter(String table, List<Map<String, dynamic>> columns, {String? command}) async {
		String sql = 'ALTER TABLE $table ';
		var subSql = '$command COLUMN ';
		var thresholdX = columns.length - 1;
		for(var index=0; index<columns.length; index++){

			var tempSql = subSql;
			var column = columns[index];
			var columnName = column['name'];
			switch(command){
				case 'ADD': {
					var constraints = '';
					String dataType = column['type'];
					List<String>? constraintListing = column['constraints'];
					if(constraintListing != null){
						constraints = DB.getConstraints(constraintListing);
					}
					if(constraints.isNotEmpty){
						tempSql += '$columnName $dataType ' + constraints;
					} else {
						tempSql += '$columnName $dataType';
					}
					if(index < thresholdX){
						tempSql += ',';
					}
					sql += tempSql;
					break;
				}

				case 'DROP': {
					tempSql += ' $columnName';
					if(index < thresholdX){
						tempSql += ','; 
					}
					sql += tempSql; 
					break;
				}

			}
		}

		return await _run(sql, <String, dynamic>{}, table, false) as bool;
	}

	Future<int> count(String table, {Map<String, dynamic>? values}) async {
		var sql;
		if(values != null){
			String whereCaluse = DB.getWhereClause(values);
			sql = 'SELECT COUNT(*) FROM $table $whereCaluse';
		} else {
			sql = 'SELECT COUNT (*) FROM $table';
		}

		if(verbose){
			pretifyOutput('[SQL] $sql');
		}

		var fromDB = await DB(auth).query(sql, values: values, identifier: table);
		var counted = DB.fromDB(fromDB, table: table, action: 'count');

		return counted;		
	}

	Future<bool> delete(String table, Map<String, dynamic> values) async {

		String whereClause = DB.getWhereClause(values);
		var sql = 'DELETE FROM $table $whereClause';
		return await _run(sql, values, table, false) as bool;

	}

	Future<bool> clear(String table) async {
		var sql = 'TRUNCATE TABLE $table';
		return await _run(sql, <String, dynamic>{}, table, false) as bool;
	}
}