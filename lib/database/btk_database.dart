import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/btk_record.dart';
import '../models/photo.dart';

/// SQLite wrapper — used on Android/native only.
/// Web continues to use SharedPreferences via BtkNotifier.
class BtkDatabase {
  static Database? _db;

  static Future<Database> get database async {
    assert(!kIsWeb, 'BtkDatabase is not available on web');
    _db ??= await _open();
    return _db!;
  }

  static Future<Database> _open() async {
    final dbPath = join(await getDatabasesPath(), 'btk_field_app.db');
    return openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE btk_records (
            id          TEXT PRIMARY KEY,
            json        TEXT NOT NULL,
            date        TEXT NOT NULL,
            location    TEXT DEFAULT '',
            latitude    REAL,
            longitude   REAL,
            updated_at  TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE photos (
            id          TEXT PRIMARY KEY,
            record_id   TEXT NOT NULL,
            file_path   TEXT NOT NULL,
            caption     TEXT DEFAULT '',
            sort_order  INTEGER DEFAULT 0,
            created_at  TEXT NOT NULL,
            FOREIGN KEY (record_id) REFERENCES btk_records(id) ON DELETE CASCADE
          )
        ''');
        await db.execute(
            'CREATE INDEX idx_records_date ON btk_records(date DESC)');
        await db.execute(
            'CREATE INDEX idx_photos_record ON photos(record_id)');
      },
    );
  }

  // ── BtkRecord ───────────────────────────────────────────────────────────────

  static Future<List<BtkRecord>> getAllRecords() async {
    final db = await database;
    final rows = await db.query('btk_records', orderBy: 'date DESC');
    return rows
        .map((r) => BtkRecord.fromJson(jsonDecode(r['json'] as String)))
        .toList();
  }

  static Future<void> upsertRecord(BtkRecord r) async {
    final db = await database;
    await db.insert(
      'btk_records',
      {
        'id': r.id,
        'json': jsonEncode(r.toJson()),
        'date': r.date.toIso8601String(),
        'location': r.location,
        'latitude': r.latitude,
        'longitude': r.longitude,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> deleteRecord(String id) async {
    final db = await database;
    // photos are cascade-deleted by FK
    await db.delete('btk_records', where: 'id = ?', whereArgs: [id]);
  }

  // ── Photos ──────────────────────────────────────────────────────────────────

  static Future<List<Photo>> getPhotos(String recordId) async {
    final db = await database;
    final rows = await db.query(
      'photos',
      where: 'record_id = ?',
      whereArgs: [recordId],
      orderBy: 'sort_order ASC, created_at ASC',
    );
    return rows.map(Photo.fromMap).toList();
  }

  static Future<void> insertPhoto(Photo p) async {
    final db = await database;
    await db.insert('photos', p.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  static Future<void> deletePhoto(String id) async {
    final db = await database;
    await db.delete('photos', where: 'id = ?', whereArgs: [id]);
  }
}
