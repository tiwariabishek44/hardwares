import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'customer_requirement_list';

  // Save order to Firebase using SQLite bill code for uniformity
  Future<String> saveRequirementListToFirebase({
    required String billCode, // Bill code from SQLite (uniform)
    required String customerName,
    required String phoneNumber,
    required String plumberId,
    required String plumberName,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      // Calculate totals
      double totalAmount = 0.0;
      for (var item in items) {
        double price = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
        int quantity = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
        totalAmount += price * quantity;
      }

      // Create order data using the SQLite bill code for uniformity
      Map<String, dynamic> orderData = {
        'bill_code': billCode, // Use the SAME bill code from SQLite
        'customer_name': customerName,
        'phone_number': phoneNumber,
        'plumber_id': plumberId,
        'plumber_name': plumberName,
        'items': items,
        'created_at': DateTime.now().toIso8601String(),
        'synced_at': DateTime.now().toIso8601String(),
        'source': 'mobile_app', // Track source
      };

      // Use bill code as Firebase document ID for consistency and easy lookup
      await _firestore
          .collection(_collectionName)
          .doc(billCode) // Document ID = Bill Code (uniform)
          .set(orderData);

      log('✅ Order saved to Firebase with uniform Bill Code: $billCode');
      return billCode; // Return the same bill code
    } catch (e) {
      log('❌ Error saving order to Firebase: $e');
      rethrow;
    }
  }

  // Get order from Firebase by bill code
  Future<Map<String, dynamic>?> getOrderByBillCode(String billCode) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('orders').doc(billCode).get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      } else {
        return null;
      }
    } catch (e) {
      log('Error getting order by bill code: $e');
      rethrow;
    }
  }

  // Get all orders for a plumber
  Future<List<Map<String, dynamic>>> getOrdersForPlumber(
      String plumberId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('orders')
          .where('plumber_id', isEqualTo: plumberId)
          .orderBy('created_at', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();
    } catch (e) {
      log('Error getting orders for plumber: $e');
      rethrow;
    }
  }
}
