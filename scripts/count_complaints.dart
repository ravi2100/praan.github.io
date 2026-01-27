import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:panchayat_mitra/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final firestore = FirebaseFirestore.instance;
  final grievances = await firestore
      .collection('grievances')
      .where('block', isEqualTo: 'amrapara')
      .get();

  print('Number of complaints in amrapara block: ${grievances.docs.length}');
}
