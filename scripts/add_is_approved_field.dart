import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final firestore = FirebaseFirestore.instance;
  final collectionRef = firestore.collection('model_answers');
  final snapshot = await collectionRef.get();
  final batch = firestore.batch();

  for (final doc in snapshot.docs) {
    batch.update(doc.reference, {'isApproved': false});
  }

  await batch.commit();

  print('Successfully updated ${snapshot.docs.length} documents.');
}
