import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Exams
  Future<List<Map<String, dynamic>>> getExams() async {
    final snapshot = await _db.collection('exams').get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  // Questions (PYQs and Extra Questions)
  Future<List<Map<String, dynamic>>> getQuestions(String type, String examId, String subject, String chapter) async {
    final snapshot = await _db.collection('questions')
        .where('type', isEqualTo: type)
        .where('examId', isEqualTo: examId)
        .where('subject', isEqualTo: subject)
        .where('chapter', isEqualTo: chapter)
        .get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  // Question Stats
  Future<Map<String, int>> getSubjectStats(String type, String examId, String subject) async {
    try {
      final snapshot = await _db.collection('questions')
          .where('type', isEqualTo: type)
          .where('examId', isEqualTo: examId)
          .where('subject', isEqualTo: subject)
          .get();
          
      final questions = snapshot.docs.map((doc) => doc.data()).toList();
      final chapters = questions.map((q) => q['chapter'] as String?).where((c) => c != null && c.isNotEmpty).toSet();
      
      return {
        'questions': questions.length,
        'chapters': chapters.length,
      };
    } catch (e) {
      return {'questions': 0, 'chapters': 0};
    }
  }

  // Notes
  Future<List<Map<String, dynamic>>> getNotes(String examId, String subject, String chapter) async {
    final snapshot = await _db.collection('notes')
        .where('examId', isEqualTo: examId)
        .where('subject', isEqualTo: subject)
        .where('chapter', isEqualTo: chapter)
        .get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  // Test Series
  Future<List<Map<String, dynamic>>> getTestSeries(String examId) async {
    final snapshot = await _db.collection('testSeries')
        .where('examId', isEqualTo: examId)
        .get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  // Books
  Future<List<Map<String, dynamic>>> getBooks(String examId, String subject) async {
    final snapshot = await _db.collection('books')
        .where('examId', isEqualTo: examId)
        .where('subject', isEqualTo: subject)
        .get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }
}

// Global instance for easy access without Riverpod boilerplate for simple screens
final firebaseService = FirebaseService();
