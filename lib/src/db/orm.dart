import 'db.dart';
import '../output.dart';

class ORM {
	Map<String, dynamic> auth;
	bool verbose;

	ORM(this.auth, {this.verbose=false});

	Future<bool> _run(sql, values) async {
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
		String table, String column, dynamic change, Map<String, dynamic> values) async {

		String whereClause = DB.getWhereClause(values);
		var sql = 'UPDATE $table SET $column=@change $whereClause';
		values['change'] = change;

		return await _run(sql, values);
	}
}