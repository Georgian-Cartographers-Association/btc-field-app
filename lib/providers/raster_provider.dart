import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/raster_layer.dart';

class RasterNotifier extends StateNotifier<List<RasterLayer>> {
  RasterNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await rootBundle.loadString('assets/rasters/catalog.json');
      final catalog = jsonDecode(raw) as Map<String, dynamic>;
      final layers = (catalog['rasters'] as List)
          .map((e) => RasterLayer.fromCatalog(e as Map<String, dynamic>))
          .toList();

      // Overlay user prefs (visibility / opacity)
      final prefs = await SharedPreferences.getInstance();
      for (final r in layers) {
        final v = prefs.getBool('raster_vis_${r.id}');
        final o = prefs.getDouble('raster_opa_${r.id}');
        if (v != null) r.visible = v;
        if (o != null) r.opacity = o;
      }
      state = layers;
    } catch (_) {
      state = [];
    }
  }

  Future<void> toggleVisible(String id) async {
    state = [
      for (final l in state)
        if (l.id == id) (l..visible = !l.visible) else l
    ];
    final prefs = await SharedPreferences.getInstance();
    final layer = state.firstWhere((l) => l.id == id);
    await prefs.setBool('raster_vis_$id', layer.visible);
  }

  Future<void> setOpacity(String id, double opacity) async {
    state = [
      for (final l in state)
        if (l.id == id) (l..opacity = opacity) else l
    ];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('raster_opa_$id', opacity);
  }
}

final rasterProvider =
    StateNotifierProvider<RasterNotifier, List<RasterLayer>>((ref) => RasterNotifier());
