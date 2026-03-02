import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/memory.dart';

class MemoryProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final List<Memory> _memories = [ /* your seed data */ ];

  List<Memory> get memoryList => _memories;

  void addMemoryLocal(Memory memory) {
    _memories.add(memory);
    notifyListeners();
  }

  void updateMemoryLocal(Memory updated) {
    final idx = _memories.indexWhere((m) => m.id == updated.id);
    if (idx == -1) return;
    _memories[idx] = updated;
    notifyListeners();
  }

  void deleteMemoryLocal(String id) {
    _memories.removeWhere((m) => m.id == id);
    notifyListeners();
  }

  Future<void> addEntryToFirestore(Memory memory) async {
    await _db.collection('journal_entries').add({
      'id': memory.id,
      'caption': memory.caption,
      'description': memory.description,
      'local_image_path': memory.localImagePath,
      'created_at': Timestamp.fromDate(memory.createdAt),
      'assigned_at': Timestamp.fromDate(memory.assignedAt),
    });
  }

// Optional: if you want Firestore updates too (requires doc id strategy)
// Future<void> updateEntryInFirestore(Memory memory) async { ... }
}
