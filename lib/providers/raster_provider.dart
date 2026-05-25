import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/raster_layer.dart';

const _prefRasters = 'raster_layers';
const _prefRasterImgPrefix = 'raster_img_';

class RasterNotifier extends StateNotifier<List<RasterLayer>> {
  RasterNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefRasters);
    if (raw != null) {
      final list = jsonDecode(raw) as List<dynamic>;
      state = list.map((e) => RasterLayer.fromJson(e as Map<String, dynamic>)).toList();
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefRasters, jsonEncode(state.map((r) => r.toJson()).toList()));
  }

  /// Saves image bytes and returns the storage path/key.
  Future<String> _storeImage(Uint8List bytes, String id) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_prefRasterImgPrefix$id', base64Encode(bytes));
      return 'web:$id';
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final folder = Directory('${dir.path}/rasters');
      await folder.create(recursive: true);
      final file = File('${folder.path}/$id.png');
      await file.writeAsBytes(bytes);
      return file.path;
    }
  }

  Future<Uint8List?> loadImageBytes(RasterLayer layer) async {
    if (layer.storagePath.startsWith('web:')) {
      final id = layer.storagePath.substring(4);
      final prefs = await SharedPreferences.getInstance();
      final b64 = prefs.getString('$_prefRasterImgPrefix$id');
      if (b64 == null) return null;
      return base64Decode(b64);
    } else {
      final file = File(layer.storagePath);
      if (!await file.exists()) return null;
      return await file.readAsBytes();
    }
  }

  Future<void> add({
    required String name,
    required Uint8List imageBytes,
    required double northLat,
    required double southLat,
    required double eastLon,
    required double westLon,
    double opacity = 0.7,
  }) async {
    final id = const Uuid().v4().substring(0, 8);
    final path = await _storeImage(imageBytes, id);
    final layer = RasterLayer(
      id: id,
      name: name,
      northLat: northLat,
      southLat: southLat,
      eastLon: eastLon,
      westLon: westLon,
      opacity: opacity,
      storagePath: path,
    );
    state = [...state, layer];
    await _persist();
  }

  Future<void> update(RasterLayer layer) async {
    state = [for (final l in state) if (l.id == layer.id) layer else l];
    await _persist();
  }

  Future<void> toggleVisible(String id) async {
    state = [
      for (final l in state)
        if (l.id == id) (l..visible = !l.visible) else l
    ];
    await _persist();
  }

  Future<void> remove(String id) async {
    final layer = state.firstWhere((l) => l.id == id);
    // Delete stored image
    if (layer.storagePath.startsWith('web:')) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_prefRasterImgPrefix$id');
    } else {
      final file = File(layer.storagePath);
      if (await file.exists()) await file.delete();
    }
    state = state.where((l) => l.id != id).toList();
    await _persist();
  }
}

final rasterProvider =
    StateNotifierProvider<RasterNotifier, List<RasterLayer>>((ref) => RasterNotifier());
