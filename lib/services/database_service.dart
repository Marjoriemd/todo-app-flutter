import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task.dart';

/// Servicio singleton para gestionar la base de datos SQLite.
/// Implementa el patrón Singleton para asegurar una única instancia.
class DatabaseService {
  static const String _databaseName = 'todo_app.db';
  static const int _databaseVersion = 1;
  static const String _tableName = 'tasks';

  // Instancia única del servicio (Singleton)
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  /// Devuelve la instancia de la base de datos, inicializándola si es necesario.
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Inicializa la base de datos y crea las tablas necesarias.
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    return openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  /// Crea la tabla de tareas al inicializar la base de datos.
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT DEFAULT '',
        is_completed INTEGER NOT NULL DEFAULT 0,
        priority TEXT NOT NULL DEFAULT 'media',
        created_at TEXT NOT NULL,
        due_date TEXT
      )
    ''');
  }

  // ─── CRUD Operations ────────────────────────────────────────────────────────

  /// [CREATE] Inserta una nueva tarea en la base de datos.
  Future<void> insertTask(Task task) async {
    final db = await database;
    await db.insert(
      _tableName,
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// [READ] Obtiene todas las tareas ordenadas por fecha de creación.
  Future<List<Task>> getAllTasks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: 'created_at DESC',
    );
    return maps.map(Task.fromMap).toList();
  }

  /// [READ] Obtiene tareas filtradas por estado de completado.
  Future<List<Task>> getTasksByStatus({required bool isCompleted}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'is_completed = ?',
      whereArgs: [isCompleted ? 1 : 0],
      orderBy: 'created_at DESC',
    );
    return maps.map(Task.fromMap).toList();
  }

  /// [UPDATE] Actualiza una tarea existente en la base de datos.
  Future<void> updateTask(Task task) async {
    final db = await database;
    await db.update(
      _tableName,
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  /// [UPDATE] Cambia únicamente el estado de completado de una tarea.
  Future<void> toggleTaskCompletion(String id, bool isCompleted) async {
    final db = await database;
    await db.update(
      _tableName,
      {'is_completed': isCompleted ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// [DELETE] Elimina una tarea por su ID.
  Future<void> deleteTask(String id) async {
    final db = await database;
    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// [DELETE] Elimina todas las tareas completadas.
  Future<int> deleteCompletedTasks() async {
    final db = await database;
    return db.delete(
      _tableName,
      where: 'is_completed = ?',
      whereArgs: [1],
    );
  }

  /// Cierra la conexión con la base de datos.
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
