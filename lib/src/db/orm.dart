import 'db.dart' as dbse;
import '../output.dart';

class ORM {
  late dbse.DB db;
  ORM(this.db);
  Future<dynamic> _run<T>(sql,
      [Map<String, dynamic>? values, String? table, bool? isReturning]) async {
    if (isReturning == true) {
      sql = sql + ' RETURNING *';
    }
    var fromDB = await db.query(sql, values: values, identifier: table);
    if (isReturning == true) {
      return dbse.DB.fromDB<Map<String, dynamic>>(fromDB, table: table)?.first
          as T;
    } else {
      return (fromDB != null) as T;
    }
  }

  Future<List<Map<String, dynamic>>?> query(String sql) async {
    var fromDb = await db.query(sql);
    return dbse.DB.fromDB<Map<String, dynamic>>(fromDb);
  }

  Future<List<Map<String, dynamic>>?> get(String table, String column,
      {Map<String, dynamic>? values, int? limit, int? offset}) async {
    values == null ? values = <String, dynamic>{} : values = values;
    String whereClause = dbse.DB.getWhereClause(values);

    var sql;
    if (whereClause.isEmpty) {
      sql = 'SELECT $column FROM $table';
    } else {
      sql = 'SELECT $column FROM $table $whereClause';
    }

    sql = '$sql${limit != null ? ' LIMIT $limit' : ''}';
    sql = '$sql${offset != null ? ' OFFSET $offset' : ''}';

    if (db.verbose) {
      pretifyOutput('[SQL] $sql');
    }

    var fromDB = await db.query(sql, values: values, identifier: table);
    return dbse.DB.fromDB<Map<String, dynamic>>(fromDB, table: table);
  }

  Future<Map<String, dynamic>?> insert(
      String table, Map<String, dynamic> values) async {
    String valuesF = '';
    String columns = '';

    int tracker = 0;
    values.forEach((key, value) {
      tracker++;

      if (values.length == 1) {
        columns += key;
        valuesF += ' @$key';
      } else {
        if (tracker == values.length) {
          columns += key;
          valuesF += ' @$key';
        } else {
          columns += '$key, ';
          valuesF += '@$key, ';
        }
      }
    });

    var sql = 'INSERT INTO $table ($columns) values($valuesF)';
    return await _run<Map<String, dynamic>?>(sql, values, table, true);
  }

  Future<Map<String, dynamic>?> update(String table,
      Map<String, dynamic> change, Map<String, dynamic> values) async {
    String whereClause = dbse.DB.getWhereClause(values);
    String updateClause = dbse.DB.getSetClause(change);
    var sql = 'UPDATE $table $updateClause $whereClause';

    values.addAll(change);
    return await _run<Map<String, dynamic>?>(sql, values, table, true);
  }

  Future<bool> alter(String table, List<Map<String, dynamic>> columns,
      {String? command}) async {
    String sql = 'ALTER TABLE $table ';
    var subSql = '$command COLUMN ';
    var thresholdX = columns.length - 1;
    for (var index = 0; index < columns.length; index++) {
      var tempSql = subSql;
      var column = columns[index];
      var columnName = column['name'];
      switch (command) {
        case 'ADD':
          {
            var constraints = '';
            String dataType = column['type'];
            List<String>? constraintListing = column['constraints'];
            if (constraintListing != null) {
              constraints = dbse.DB.getConstraints(constraintListing);
            }
            if (constraints.isNotEmpty) {
              tempSql += '$columnName $dataType ' + constraints;
            } else {
              tempSql += '$columnName $dataType';
            }
            if (index < thresholdX) {
              tempSql += ',';
            }
            sql += tempSql;
            break;
          }

        case 'DROP':
          {
            tempSql += ' $columnName';
            if (index < thresholdX) {
              tempSql += ',';
            }
            sql += tempSql;
            break;
          }
      }
    }
    return await _run<bool>(sql, <String, dynamic>{}, table, false);
  }

  Future<List<Map<String, Map<String, dynamic>>>?> join(String sql,
      {Map<String, dynamic>? values}) async {
    return await db.query(sql, values: values);
  }

  Future<int> count(String table, {Map<String, dynamic>? values}) async {
    var sql;
    if (values != null) {
      String whereCaluse = dbse.DB.getWhereClause(values);
      sql = 'SELECT COUNT(*) FROM $table $whereCaluse';
    } else {
      sql = 'SELECT COUNT (*) FROM $table';
    }
    if (db.verbose) {
      pretifyOutput('[SQL] $sql');
    }
    var fromDB = await db.query(sql, values: values, identifier: table);
    var counted = dbse.DB.fromDB<int>(fromDB, table: table, action: 'count');
    return counted!.first;
  }

  Future<bool> delete(String table, Map<String, dynamic> values) async {
    String whereClause = dbse.DB.getWhereClause(values);
    var sql = 'DELETE FROM $table $whereClause';
    return await _run<bool>(sql, values, table, false);
  }

  Future<bool> clear(String table) async {
    var sql = 'TRUNCATE TABLE $table';
    return await _run<bool>(sql, <String, dynamic>{}, table, false);
  }
}
