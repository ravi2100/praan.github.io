import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:panchayat_mitra/firebase_options.dart';

Future<void> main() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final firestore = FirebaseFirestore.instance;
  final grievancesCollection = firestore.collection('grievances');

  try {
    final snapshot = await grievancesCollection.get();
    if (snapshot.docs.isEmpty) {
      print('The grievances collection is already empty.');
      return;
    }

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
      print('Deleted grievance with ID: ${doc.id}');
    }

    print(
      'Successfully deleted ${snapshot.docs.length} grievances from the collection.',
    );
  } catch (e) {
    print('An error occurred while deleting grievances: $e');
  }
}
