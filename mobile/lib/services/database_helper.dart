import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/device_status.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'readings.db');
    return await openDatabase(
      path,
      version: 2, // Bump version for migration
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE readings(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp TEXT,
            ph REAL,
            turbidity REAL,
            waterLevelRaw INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE alerts(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp TEXT,
            message TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS alerts(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              timestamp TEXT,
              message TEXT
            )
          ''');
        }
      },
    );
  }

  Future<void> insertReading(DeviceStatus status) async {
    final database = await db;
    await database.insert(
      'readings',
      {
        'timestamp': DateTime.now().toIso8601String(),
        'ph': status.ph,
        'turbidity': status.turbidity,
        'waterLevelRaw': status.waterLevelRaw,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getReadings() async {
    final database = await db;
    return await database.query('readings', orderBy: 'timestamp DESC');
  }

  Future<void> insertAlert(String message) async {
    final database = await db;
    await database.insert(
      'alerts',
      {
        'timestamp': DateTime.now().toIso8601String(),
        'message': message,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getAlerts({DateTime? start, DateTime? end}) async {
    final database = await db;
    String? where;
    List<dynamic>? whereArgs;
    if (start != null && end != null) {
      where = 'timestamp >= ? AND timestamp <= ?';
      whereArgs = [start.toIso8601String(), end.toIso8601String()];
    }
    return await database.query(
      'alerts',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'timestamp DESC',
    );
  }
}