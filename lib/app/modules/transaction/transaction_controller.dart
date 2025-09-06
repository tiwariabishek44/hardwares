import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/database_helper.dart';
import 'package:nepali_utils/nepali_utils.dart';

class TransactionController extends GetxController {
  // Observable variables
  var isLoading = false.obs;
  var transactions = <Map<String, dynamic>>[].obs;
  var parties = <Map<String, dynamic>>[].obs;
  var isRefreshing = false.obs;

  final DatabaseHelper _databaseHelper = DatabaseHelper();

  @override
  void onInit() {
    super.onInit();
    loadTransactions();
    loadParties();
  }

  // Load ALL transactions from local database
  void loadTransactions() async {
    isLoading.value = true;

    try {
      // Get all party transactions (both paune_parne and rakam_prapta)
      List<Map<String, dynamic>> partyTransactions =
          await _databaseHelper.getAllTransactions();

      // Process each transaction to get party details
      List<Map<String, dynamic>> processedPartyTransactions = [];

      for (var transaction in partyTransactions) {
        try {
          // Get party details for this transaction
          Map<String, dynamic>? party =
              await _databaseHelper.getPartyById(transaction['party_id']);

          // Determine transaction type
          bool isPayment = transaction['transaction_type'] == 'rakam_prapta';
          bool isReceivable = transaction['transaction_type'] == 'paune_parne';

          // Convert string date to DateTime for proper display
          String displayDate = "";
          try {
            if (transaction['date'] != null) {
              DateTime dateTime = DateTime.parse(transaction['date']);
              NepaliDateTime nepaliDate = NepaliDateTime.fromDateTime(dateTime);
              displayDate = nepaliDate.format('yyyy/MM/dd');
            }
          } catch (e) {
            displayDate = transaction['date']?.substring(0, 10) ?? "";
          }

          Map<String, dynamic> processedTransaction = {
            'id': 'party_${transaction['id']}',
            'type': isPayment ? 'payment' : 'receivable',
            'customer_name': party?['name'] ?? 'Unknown Party',
            'amount': transaction['amount'] ?? 0.0,
            'date': transaction['date']?.substring(0, 10) ??
                DateTime.now().toString().substring(0, 10),
            'display_date': displayDate,
            'status': isPayment ? 'completed' : 'pending',
            'description': transaction['description'],
            'phone_number': party?['phone'] ?? '',
            'transaction_source': 'party',
            'party_id': transaction['party_id'],
            'party_type': party?['party_type'] ?? 'customer',
            'transaction_type': transaction['transaction_type'],
          };

          processedPartyTransactions.add(processedTransaction);
        } catch (e) {
          log('❌ Error processing party transaction ${transaction['id']}: $e');
          // Add transaction with minimal data if party lookup fails
          processedPartyTransactions.add({
            'id': 'party_${transaction['id']}',
            'type': 'unknown',
            'customer_name': 'Unknown Party',
            'amount': transaction['amount'] ?? 0.0,
            'date': transaction['date']?.substring(0, 10) ??
                DateTime.now().toString().substring(0, 10),
            'status': 'unknown',
            'description': transaction['description'],
            'phone_number': '',
            'transaction_source': 'party',
            'party_id': transaction['party_id'],
            'party_type': 'unknown',
            'transaction_type': transaction['transaction_type'],
          });
        }
      }

      // Sort by date (newest first)
      processedPartyTransactions.sort((a, b) {
        try {
          DateTime dateA = DateTime.parse(a['date']);
          DateTime dateB = DateTime.parse(b['date']);
          return dateB.compareTo(dateA); // Newest first
        } catch (e) {
          return 0;
        }
      });

      transactions.value = processedPartyTransactions;

      log('✅ Loaded ${transactions.length} party transactions');
    } catch (e) {
      log('❌ Error loading transactions: $e');
      transactions.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  // Load parties from SQLite database
  Future<void> loadParties() async {
    try {
      log('📋 Loading parties from database...');
      List<Map<String, dynamic>> partiesData =
          await _databaseHelper.getAllParties();
      parties.value = partiesData;
      parties.refresh(); // Force UI update
      log('✅ Loaded ${parties.length} parties from database');

      // Debug: Print party balances
      for (var party in parties) {
        log('  Party: ${party['name']} - Balance: Rs.${party['balance']}');
      }
    } catch (e) {
      log('❌ Error loading parties: $e');
      parties.value = [];
    }
  }

  // Refresh both transactions and parties
  Future<void> refreshTransactions() async {
    isRefreshing.value = true;

    try {
      await Future.wait([
        Future(() => loadTransactions()),
        Future(() => loadParties()),
      ]);
    } catch (e) {
      log('Error refreshing data: $e');
    } finally {
      isRefreshing.value = false;
    }
  }

  // Calculate total amount received (from all completed transactions)
  double getTotalReceived() {
    return transactions
        .where((t) => (t['amount'] ?? 0.0) > 0)
        .fold(0.0, (sum, t) => sum + (t['amount'] ?? 0.0));
  }

  // Calculate total expenses (negative amounts)
  double getTotalExpenses() {
    return transactions
        .where((t) => (t['amount'] ?? 0.0) < 0)
        .fold(0.0, (sum, t) => sum + (t['amount']?.abs() ?? 0.0));
  }

  // Calculate net balance
  double getNetBalance() {
    return getTotalReceived() - getTotalExpenses();
  }

  // Get total number of orders
  int getTotalOrders() {
    return transactions.where((t) => t['transaction_source'] == 'order').length;
  }

  // Get total number of party payments
  int getTotalPartyPayments() {
    return transactions.where((t) => t['transaction_source'] == 'party').length;
  }

  // Get formatted date
  String getFormattedDate(String dateStr) {
    try {
      // Handle both ISO format and date-only format
      DateTime date;
      if (dateStr.contains('T')) {
        date = DateTime.parse(dateStr);
      } else {
        date = DateTime.parse(dateStr);
      }
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  // Add party and refresh the list
  void addPartyAndRefresh(Map<String, dynamic> party) {
    parties.add(party);
    parties.refresh(); // Trigger UI update
  }

  // Update party balance (if needed for future transactions)
  Future<void> updatePartyBalance(int partyId, double newBalance) async {
    try {
      await _databaseHelper.updatePartyBalance(partyId, newBalance);
      loadParties(); // Reload to get updated data
    } catch (e) {
      print('Error updating party balance: $e');
    }
  }

  // Delete party
  Future<void> deleteParty(int partyId) async {
    try {
      await _databaseHelper.deleteParty(partyId);
      loadParties(); // Reload to get updated list

      Get.snackbar(
        'Success',
        'Party deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green[600],
        colorText: Colors.white,
        margin: EdgeInsets.all(16),
        borderRadius: 8,
      );
    } catch (e) {
      print('Error deleting party: $e');
      Get.snackbar(
        'Error',
        'Failed to delete party',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[600],
        colorText: Colors.white,
        margin: EdgeInsets.all(16),
        borderRadius: 8,
      );
    }
  }

  // Search parties
  Future<List<Map<String, dynamic>>> searchParties(String searchTerm) async {
    try {
      return await _databaseHelper.searchParties(searchTerm);
    } catch (e) {
      print('Error searching parties: $e');
      return [];
    }
  }

  // Get parties by type (customer/supplier)
  Future<List<Map<String, dynamic>>> getPartiesByType(String type) async {
    try {
      return await _databaseHelper.getPartiesByType(type);
    } catch (e) {
      print('Error getting parties by type: $e');
      return [];
    }
  }

  // Calculate total party balances
  double getTotalPartyBalance() {
    return parties.fold(0.0, (sum, party) => sum + (party['balance'] ?? 0.0));
  }

  // Get parties who owe us money (positive balance)
  List<Map<String, dynamic>> getPartiesOwingUs() {
    return parties.where((party) => (party['balance'] ?? 0.0) > 0).toList();
  }

  // Get parties we owe money to (negative balance)
  List<Map<String, dynamic>> getPartiesWeOwe() {
    return parties.where((party) => (party['balance'] ?? 0.0) < 0).toList();
  }

  // Force refresh parties from database
  Future<void> forceRefreshParties() async {
    try {
      print('🔄 Force refreshing parties from database...');
      List<Map<String, dynamic>> partiesData =
          await _databaseHelper.getAllParties();
      parties.value = partiesData;
      parties.refresh(); // Force UI update
      print('✅ Force refreshed ${parties.length} parties');
    } catch (e) {
      print('❌ Error force refreshing parties: $e');
    }
  }

  // Refresh specific party by ID
  Future<void> refreshPartyById(int partyId) async {
    try {
      print('🔄 Refreshing party ID: $partyId');
      Map<String, dynamic>? updatedParty =
          await _databaseHelper.getPartyById(partyId);

      if (updatedParty != null) {
        // Find and update the party in the list
        int index = parties.indexWhere((party) => party['id'] == partyId);
        if (index != -1) {
          parties[index] = updatedParty;
          parties.refresh();
          print(
              '✅ Updated party in list: ${updatedParty['name']} - Balance: ${updatedParty['balance']}');
        } else {
          // If party not found in list, refresh all parties
          await forceRefreshParties();
        }
      }
    } catch (e) {
      print('❌ Error refreshing party by ID: $e');
    }
  }

  // Force refresh transactions (useful after adding party transactions)
  Future<void> forceRefreshTransactions() async {
    try {
      print('🔄 Force refreshing all transactions...');
      loadTransactions();
    } catch (e) {
      print('❌ Error force refreshing transactions: $e');
    }
  }

  // Get formatted date in Nepali
  String getNepaliFormattedDate(String dateStr) {
    try {
      DateTime date = DateTime.parse(dateStr);
      NepaliDateTime nepaliDate = NepaliDateTime.fromDateTime(date);
      return nepaliDate.format('yyyy/MM/dd');
    } catch (e) {
      return dateStr;
    }
  }

  // Get transaction type display name
  String getTransactionTypeDisplay(Map<String, dynamic> transaction) {
    final transactionType = transaction['transaction_type'] ?? '';
    final partyType = transaction['party_type'] ?? 'customer';

    if (transactionType == 'rakam_prapta') {
      if (partyType == 'customer') {
        return 'रकम प्राप्त भयो'; // Amount received
      } else {
        return 'भुक्तानी गरियो'; // Payment made
      }
    } else if (transactionType == 'paune_parne') {
      if (partyType == 'customer') {
        return 'पाउनु पर्ने रकम'; // Amount receivable
      } else {
        return 'तिर्नु पर्ने रकम'; // Amount payable
      }
    } else {
      return 'अज्ञात लेनदेन'; // Unknown transaction
    }
  }
}
