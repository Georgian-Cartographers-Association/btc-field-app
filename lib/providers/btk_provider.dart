import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/btk_record.dart';
import '../repositories/cloud_repository.dart';
import '../repositories/data_repository.dart';
import '../repositories/expedition_repository.dart';
import '../repositories/local_repository.dart';
import 'auth_provider.dart';
import 'settings_provider.dart';

class BtkNotifier extends StateNotifier<List<BtkRecord>> {
  BtkNotifier(this._repo) : super([]) {
    _init();
  }

  final DataRepository _repo;
  StreamSubscription<List<BtkRecord>>? _cloudSub;

  void _init() {
    final s = _repo.stream;
    if (s != null) {
      // Cloud / expedition: subscribe to Firestore real-time stream
      _cloudSub = s.listen((records) {
        if (mounted) state = records;
      });
    } else {
      // Local: one-shot load
      _repo.getAll().then((records) {
        if (mounted) state = records;
      });
    }
  }

  @override
  void dispose() {
    _cloudSub?.cancel();
    super.dispose();
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
    await _repo.upsert(record);
    return record;
  }

  Future<void> update(BtkRecord record) async {
    state = [
      for (final r in state)
        if (r.id == record.id) record else r
    ];
    await _repo.upsert(record);
  }

  Future<void> remove(String id) async {
    state = state.where((r) => r.id != id).toList();
    await _repo.delete(id);
  }
}

/// Provider automatically recreates BtkNotifier when storage mode, auth state
/// or expedition ID changes — switching modes reloads data.
final btkProvider =
    StateNotifierProvider<BtkNotifier, List<BtkRecord>>((ref) {
  final settings = ref.watch(
    settingsProvider.select((s) => (
      mode: s.storageMode,
      expId: s.expeditionId,
    )),
  );
  final user = ref.watch(authProvider).valueOrNull;

  final DataRepository repo;
  switch (settings.mode) {
    case StorageMode.cloud:
      if (user != null) {
        repo = CloudRepository(uid: user.uid);
      } else {
        repo = LocalRepository();
      }
    case StorageMode.expedition:
      if (user != null && settings.expId != null) {
        repo = ExpeditionRepository(expeditionId: settings.expId!);
      } else {
        repo = LocalRepository();
      }
    case StorageMode.local:
      repo = LocalRepository();
  }

  return BtkNotifier(repo);
});
