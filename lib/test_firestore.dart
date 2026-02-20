import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Try to find an existing restaurant ID
  final userDoc = await FirebaseFirestore.instance.collection('profiles').limit(1).get();
  if (userDoc.docs.isEmpty) {
    print('No user profile found');
    return;
  }
  
  final profileData = userDoc.docs.first.data();
  final restaurantId = profileData['restaurantId'] as String?;
  
  if (restaurantId == null) {
      print('No restaurant ID found');
      return;
  }

  print('Testing restaurant ID: $restaurantId');
  final stockDocs = await FirebaseFirestore.instance
      .collection('restaurants')
      .doc(restaurantId)
      .collection('inventory')
      .limit(2)
      .get();
      
  print('Inventory results: ${stockDocs.docs.length}');
  for (var doc in stockDocs.docs) {
    print(doc.data());
  }
}
