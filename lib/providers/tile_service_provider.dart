import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/tile_service.dart';

const _prefKey = 'tile_services';

class TileServiceNotifier extends StateNotifier<List<TileService>> {
  TileServiceNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw != null) {
      state = (jsonDecode(raw) as List)
          .map((e) => TileService.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, jsonEncode(state.map((s) => s.toJson()).toList()));
  }

  Future<void> add(TileService svc) async {
    state = [...state, svc];
    await _persist();
  }

  Future<void> addFromTemplate(Map<String, dynamic> tpl, String name) async {
    final svc = TileService(
      id: const Uuid().v4().substring(0, 8),
      name: name.isNotEmpty ? name : tpl['name'] as String,
      urlTemplate: tpl['urlTemplate'] as String,
      subdomains: List<String>.from(tpl['subdomains'] as List? ?? []),
    );
    await add(svc);
  }

  Future<void> update(TileService svc) async {
    state = [for (final s in state) if (s.id == svc.id) svc else s];
    await _persist();
  }

  Future<void> toggleVisible(String id) async {
    state = [
      for (final s in state)
        if (s.id == id) (s..visible = !s.visible) else s
    ];
    await _persist();
  }

  Future<void> setOpacity(String id, double opacity) async {
    state = [
      for (final s in state)
        if (s.id == id) (s..opacity = opacity) else s
    ];
    await _persist();
  }

  Future<void> remove(String id) async {
    state = state.where((s) => s.id != id).toList();
    await _persist();
  }
}

final tileServiceProvider =
    StateNotifierProvider<TileServiceNotifier, List<TileService>>(
        (ref) => TileServiceNotifier());
