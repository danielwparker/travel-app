// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../models/memory.dart';
//
// class MemoryProvider extends ChangeNotifier {
//   final FirebaseFirestore _db = FirebaseFirestore.instance;
//
//   final List<Memory> _memories = [ /* your seed data */ ];
//
//   List<Memory> get memoryList => _memories;
//
//   void addMemoryLocal(Memory memory) {
//     _memories.add(memory);
//     notifyListeners();
//   }
//
//   void updateMemoryLocal(Memory updated) {
//     final idx = _memories.indexWhere((m) => m.id == updated.id);
//     if (idx == -1) return;
//     _memories[idx] = updated;
//     notifyListeners();
//   }
//
//   void deleteMemoryLocal(String id) {
//     _memories.removeWhere((m) => m.id == id);
//     notifyListeners();
//   }
//
//   Future<void> addEntryToFirestore(Memory memory) async {
//     await _db.collection('journal_entries').add({
//       'id': memory.id,
//       'caption': memory.caption,
//       'description': memory.description,
//       'local_image_path': memory.localImagePath,
//       'created_at': Timestamp.fromDate(memory.createdAt),
//       'assigned_at': Timestamp.fromDate(memory.assignedAt),
//     });
//   }
//
//
//   Future<void> loadMemories() async {
//     final snapshot = await _db
//         .collection('journal_entries')
//         .orderBy('created_at', descending: true)
//         .get();
//
//     _memories = snapshot.docs.map((doc) {
//       final data = doc.data();
//
//       return Memory(
//         id: doc.id,
//         caption: data['caption'],
//         description: data['description'],
//         createdAt: (data['created_at'] as Timestamp).toDate(),
//         assignedAt: (data['assigned_at'] as Timestamp).toDate(),
//         localImagePath: data['local_image_path'] ?? '',
//         imageUrl: data['image_url'] ?? '',
//       );
//     }).toList();
//
//     notifyListeners();
//   }
// // Optional: if you want Firestore updates too (requires doc id strategy)
// // Future<void> updateEntryInFirestore(Memory memory) async { ... }
// }
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/memory.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MemoryProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  List<Memory> _memories = [];
  List<Memory> get memoryList => _memories;

  // -------------------------------
  // Upload image to Firebase Storage
  // -------------------------------
  Future<String> uploadImage(File file, String memoryId) async {
    try {
      final ref = _storage.ref().child('memory_images/$memoryId.jpg');
      final snapshot = await ref.putFile(file);
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading image: $e');
      rethrow;
    }
  }

  // -------------------------------
  // Add or update memory in Firestore
  // -------------------------------
  Future<void> addOrUpdateMemory(Memory memory) async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      String imageUrl = memory.imageUrl;

      // Upload local image if it exists
      if (memory.localImagePath.isNotEmpty && File(memory.localImagePath).existsSync()) {
        imageUrl = await uploadImage(File(memory.localImagePath), memory.id);
      }

      final data = {
        'id': memory.id,
        'caption': memory.caption,
        'description': memory.description,
        'image_url': imageUrl,
        'created_at': Timestamp.fromDate(memory.createdAt),
        'assigned_at': Timestamp.fromDate(memory.assignedAt),
        'user_id': uid,
      };

      await _db.collection('journal_entries').doc(memory.id).set(data, SetOptions(merge: true));

      // Update local list
      final updatedMemory = memory.copyWith(imageUrl: imageUrl);
      final idx = _memories.indexWhere((m) => m.id == memory.id);
      if (idx == -1) {
        _memories.add(updatedMemory);
      } else {
        _memories[idx] = updatedMemory;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error saving memory to Firestore: $e');
      rethrow;
    }
  }

  // -------------------------------
  // Load memories for current user
  // -------------------------------
  Future<void> loadMemories() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final snapshot = await _db
          .collection('journal_entries')
          .where('user_id', isEqualTo: uid)
          .orderBy('created_at', descending: true)
          .get();

      _memories = snapshot.docs.map((doc) {
        final data = doc.data();

        return Memory(
          id: data['id'] ?? doc.id,
          caption: data['caption'] ?? '',
          description: data['description'] ?? '',
          createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
          assignedAt: (data['assigned_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
          localImagePath: '',
          imageUrl: data['image_url'] ?? '',
        );
      }).toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading memories: $e');
    }
  }


  Future<void> deleteMemory(Memory memory) async {
    try {
      // 1️⃣ Delete from Firestore
      await _db.collection('journal_entries').doc(memory.id).delete();

      // 2️⃣ Delete from local list
      _memories.removeWhere((m) => m.id == memory.id);
      notifyListeners();

      // 3️⃣ Optionally, delete image from Firebase Storage
      if (memory.imageUrl.isNotEmpty) {
        try {
          final ref = _storage.refFromURL(memory.imageUrl);
          await ref.delete();
        } catch (e) {
          debugPrint('Failed to delete image from storage: $e');
        }
      }
    } catch (e) {
      debugPrint('Failed to delete memory: $e');
      rethrow;
    }
  }
}