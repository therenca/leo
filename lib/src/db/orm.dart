import 'db.dart';
import '../output.dart';

class ORM {
	Map<String, dynamic> auth;
	bool verbose;

	ORM(this.auth, {this.verbose=false});

	Future<bool> _run(sql, [values]) async {
		if(verbose){
			pretifyOutput('[SQL] $sql');
		}

		var fromDB = await DB(auth).query(sql, values: values);
		return fromDB['isSuccessful'];
	}

	Future<dynamic> get(
		String table, String column, {Map<String, dynamic> values}) async {
		
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
		
		var fromDB = await DB(auth).query(sql, values: values);
		return DB.fromDB(fromDB, table: table);
	}

	Future<bool> insert(String table, Map<String, dynamic> values) async {

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
		
		return await _run(sql, values);
	}

	Future<bool> update(
		String table, Map<String, dynamic> change, Map<String, dynamic> values) async {

		String whereClause = DB.getWhereClause(values);
		String updateClause = DB.getSetClause(change);
		var sql = 'UPDATE $table $updateClause $whereClause';

		values.addAll(change);

		return await _run(sql, values);
	}

	Future<bool> alter(String table, List<Map<String, dynamic>> columns, {String command}) async {

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
					List<String> constraintListing = column['constraints'];
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

		return _run(sql);
	}

	Future<bool> delete(String table, Map<String, dynamic> values) async {

		String whereClause = DB.getWhereClause(values);
		var sql = 'DELETE FROM $table $whereClause';
		return await _run(sql, values);

	}
}