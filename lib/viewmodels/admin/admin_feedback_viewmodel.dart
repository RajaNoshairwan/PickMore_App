// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/foundation.dart';
//
// import '../../core/constants/collections.dart';
// import '../../models/feedback_model.dart';
//
// class AdminFeedbackViewModel extends ChangeNotifier {
//   final FirebaseFirestore _db = FirebaseFirestore.instance;
//   List<FeedbackModel> feedbacks = [];
//   bool loading = false;
//
//   Future<void> load() async {
//     loading = true;
//     notifyListeners();
//     final snap = await _db.collection(FireCollections.feedback).get();
//     feedbacks =
//         snap.docs.map((d) => FeedbackModel.fromMap(d.id, d.data())).toList();
//     loading = false;
//     notifyListeners();
//   }
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants/collections.dart';
import '../../models/feedback_model.dart';

class AdminFeedbackViewModel extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<FeedbackModel> feedbacks = [];
  bool loading = false;
  String? error;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final snap = await _db.collection(FireCollections.feedback).get();
      feedbacks = snap.docs
          .map((d) => FeedbackModel.fromMap(d.id, d.data()))
          .toList()
        ..sort((a, b) =>
            (b.createdAt?.millisecondsSinceEpoch ?? 0)
                .compareTo(a.createdAt?.millisecondsSinceEpoch ?? 0));
    } catch (e) {
      error = e.toString();
      debugPrint('AdminFeedback load error: $e');
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}