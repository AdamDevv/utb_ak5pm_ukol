import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/game.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _databaseCache;

  DatabaseService._init();

  Future<Database> get _database async {
    if (_databaseCache == null) {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'steam_tracker.db');

      _databaseCache = await openDatabase(
        path,
        version: 1,
        onCreate: _createDatabase,
      );
    }

    return _databaseCache!;
  }

  Future _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE games (
        appid INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        last_modified INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_games_last_modified ON games (last_modified DESC)
    ''');

    await db.execute('''
      CREATE INDEX idx_games_name ON games (name)
    ''');
  }

  Future<void> insertGames(List<Game> games) async {
    final db = await _database;
    final batch = db.batch();

    for (final game in games) {
      batch.insert(
        'games',
        {
          'appid': game.appid,
          'name': game.name,
          'last_modified': game.lastModified,
        },
        conflictAlgorithm: ConflictAlgorithm.fail,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<void> deleteAllGames() async {
    final db = await _database;
    await db.delete('games');
  }

  Future<int> getGamesCount() async {
    final db = await _database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM games');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<Game>> getGamesSortedByLastModified(int limit, int offset) async {
    final db = await _database;
    final maps = await db.query(
      'games',
      orderBy: 'last_modified DESC',
      limit: limit,
      offset: offset,
    );
    return maps.map((map) => Game.fromDynamic(map)).toList();
  }
}
