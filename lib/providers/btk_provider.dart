import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../core/constants.dart';
import '../database/btk_database.dart';
import '../models/btk_record.dart';
import '../services/migration_service.dart';

class BtkNotifier extends StateNotifier<List<BtkRecord>> {
  BtkNotifier() : super([]) {
    _load();
  }

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<void> _load() async {
    if (kIsWeb) {
      await _loadWeb();
    } else {
      await MigrationService.migrateIfNeeded();
      state = await BtkDatabase.getAllRecords();
    }
  }

  Future<void> _loadWeb() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.prefRecords);
    if (raw != null) {
      final list = jsonDecode(raw) as List<dynamic>;
      state =
          list.map((e) => BtkRecord.fromJson(e as Map<String, dynamic>)).toList();
    }
  }

  Future<void> _saveWeb() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AppConstants.prefRecords,
      jsonEncode(state.map((r) => r.toJson()).toList()),
    );
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  Future<BtkRecord> add({double? lat, double? lon}) async {
    final record = BtkRecord(
      id: const Uuid().v4().substring(0, 8).toUpperCase(),
      date: DateTime.now(),
      latitude: lat,
      longitude: lon,
    );
    state = [...state, record];
    if (kIsWeb) {
      await _saveWeb();
    } else {
      await BtkDatabase.upsertRecord(record);
    }
    return record;
  }

  Future<void> update(BtkRecord record) async {
    state = [
      for (final r in state)
        if (r.id == record.id) record else r
    ];
    if (kIsWeb) {
      await _saveWeb();
    } else {
      await BtkDatabase.upsertRecord(record);
    }
  }

  Future<void> remove(String id) async {
    state = state.where((r) => r.id != id).toList();
    if (kIsWeb) {
      await _saveWeb();
    } else {
      await BtkDatabase.deleteRecord(id); // photos cascade-deleted by FK
    }
  }
}

final btkProvider =
    StateNotifierProvider<BtkNotifier, List<BtkRecord>>((ref) => BtkNotifier());
