import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hardwares/app/modules/transaction/transaction_controller.dart';
import 'package:hardwares/app/utils/database_helper.dart';

class PartyDetailController extends GetxController {
  var isLoading = false.obs;
  var partyData = <String, dynamic>{}.obs;
  var recentTransactions = <Map<String, dynamic>>[].obs;

  final DatabaseHelper _databaseHelper = DatabaseHelper();

  @override
  void onInit() {
    super.onInit();
    loadPartyData();
  }

  void loadPartyData() {
    final arguments = Get.arguments as Map<String, dynamic>?;
    if (arguments != null) {
      partyData.value = arguments;
      print('📄 Loaded party data: ${partyData.value}');
      loadRecentTransactions();
    }
  }

  Future<void> loadRecentTransactions() async {
    try {
      int partyId = partyData['id'];
      log('🔄 Loading transactions for party ID: $partyId');

      List<Map<String, dynamic>> transactions =
          await _databaseHelper.getTransactionsByPartyId(partyId);

      log('📋 Found ${transactions.length} transactions');
      recentTransactions.value = transactions.take(5).toList();
    } catch (e) {
      print('❌ Error loading transactions: $e');
      recentTransactions.value = [];
    }
  }

  // Refresh party data from database
  Future<void> refreshPartyData() async {
    try {
      isLoading.value = true;
      int partyId = partyData['id'];

      print('🔄 Refreshing party data for ID: $partyId');

      // Get updated party data from database
      Map<String, dynamic>? updatedParty =
          await _databaseHelper.getPartyById(partyId);

      if (updatedParty != null) {
        print('✅ Updated party data: $updatedParty');
        partyData.value = updatedParty;
        partyData.refresh(); // Force UI update

        // Reload transactions
        await loadRecentTransactions();

        log('💰 New balance: ${balanceAmount}');

        // ✅ NOTIFY TRANSACTION CONTROLLER TO REFRESH PARTY LIST AND TRANSACTIONS
        try {
          final TransactionController transactionController =
              Get.find<TransactionController>();
          await transactionController.loadParties();
          await transactionController
              .forceRefreshTransactions(); // Also refresh transactions
          log('🔄 Notified main party list and transaction list to refresh');
        } catch (e) {
          log('⚠️ Could not find TransactionController to refresh: $e');
        }
      } else {
        log('❌ Could not find updated party data');
      }
    } catch (e) {
      log('❌ Error refreshing party data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Force refresh when coming back from transaction entry
  Future<void> onTransactionAdded() async {
    print('🔄 Transaction was added, refreshing data...');
    await refreshPartyData();
  }

  // Get party details with debugging
  String get partyName {
    String name = partyData['name'] ?? 'Unknown Party';
    return name;
  }

  String get phoneNumber {
    String phone = partyData['phone'] ?? 'No phone';
    return phone;
  }

  double get balanceAmount {
    double balance =
        double.tryParse(partyData['balance']?.toString() ?? '0') ?? 0.0;
    return balance;
  }

  String get partyType => partyData['party_type'] ?? 'customer';

  // Calculate total amount to receive
  double get totalToReceive => balanceAmount > 0 ? balanceAmount : 0.0;

  // Get recent transaction count
  int get transactionCount => recentTransactions.length;

  // Format date for display
  String formatDate(String? dateString) {
    if (dateString == null) return '';

    try {
      DateTime date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  // Get transaction type display text
  String getTransactionTypeText(String transactionType) {
    switch (transactionType) {
      case 'paune_parne':
        return 'पाउनु पर्ने';
      case 'rakam_prapta':
        return 'प्राप्त भयो';
      default:
        return transactionType;
    }
  }

  // Get transaction type color
  Color getTransactionTypeColor(String transactionType) {
    switch (transactionType) {
      case 'paune_parne':
        return Colors.red[600]!;
      case 'rakam_prapta':
        return Colors.green[600]!;
      default:
        return Colors.grey[600]!;
    }
  }
}
