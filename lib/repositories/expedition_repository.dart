import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/btk_record.dart';
import 'data_repository.dart';

/// Firestore-backed repository for a shared expedition.
/// Path: expeditions/{expeditionId}/btk_records/{recordId}
class ExpeditionRepository implements DataRepository {
  final String expeditionId;

  ExpeditionRepository({required this.expeditionId});

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance
          .collection('expeditions')
          .doc(expeditionId)
          .collection('btk_records');

  @override
  Stream<List<BtkRecord>> get stream =>
      _col.orderBy('date', descending: true).snapshots().map(
            (snap) => snap.docs
                .map((d) => BtkRecord.fromJson(d.data()))
                .toList(),
          );

  @override
  Future<List<BtkRecord>> getAll() async {
    final snap = await _col.orderBy('date', descending: true).get();
    return snap.docs.map((d) => BtkRecord.fromJson(d.data())).toList();
  }

  @override
  Future<void> upsert(BtkRecord record) =>
      _col.doc(record.id).set(record.toJson());

  @override
  Future<void> delete(String id) => _col.doc(id).delete();
}
