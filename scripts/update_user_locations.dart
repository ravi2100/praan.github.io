import 'dart:io';
import 'package:csv/csv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:panchayat_mitra/firebase_options.dart';

void main() async {
  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final firestore = FirebaseFirestore.instance;
  final usersCollection = firestore.collection('users');

  // Read the CSV file
  final input = File('c:/Users/nicpa/Downloads/panchayatlist-1.csv').openRead();
  final fields = await input
      .transform(SystemEncoding().decoder)
      .transform(const CsvToListConverter())
      .toList();

  // Remove the header row
  fields.removeAt(0);

  for (var row in fields) {
    if (row.length >= 4) {
      final block = row[0].toString().trim();
      final panchayat = row[1].toString().trim();
      final email = row[2].toString().trim();

      if (email.isNotEmpty) {
        try {
          // Find user by email
          final querySnapshot = await usersCollection
              .where('email', isEqualTo: email)
              .get();

          if (querySnapshot.docs.isNotEmpty) {
            for (var doc in querySnapshot.docs) {
              // Update user with block and panchayat
              await doc.reference.update({
                'block': block,
                'panchayat': panchayat,
              });
              print('Updated user: $email');
            }
          } else {
            print('User not found: $email');
          }
        } catch (e) {
          print('Error updating user $email: $e');
        }
      }
    }
  }

  print('Script finished.');
}
