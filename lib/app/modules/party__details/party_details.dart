import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hardwares/app/modules/party__details/party_details_controller.dart';
import 'package:hardwares/app/modules/transction_entry/transction_entry.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class PartyDetailView extends StatelessWidget {
  PartyDetailView({Key? key}) : super(key: key);
  final controller = Get.put(PartyDetailController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Obx(() => _buildBody()),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Obx(() => controller.isLoading.value
          ? Text('Party Details')
          : Text(controller.partyName)),
      backgroundColor: Colors.white,
      centerTitle: false,
      actions: [
        IconButton(
          icon: Icon(Icons.phone, color: Color(0xFF2D3748)),
          onPressed: () => _launchCall(),
          tooltip: 'Call',
        ),
        if (!controller.isLoading.value &&
            controller.totalToReceive > 0 &&
            controller.partyType == 'customer')
          IconButton(
            icon: Icon(Icons.message, color: Color(0xFF25D366)),
            onPressed: () => _launchWhatsApp(),
            tooltip: 'WhatsApp',
          ),
      ],
    );
  }

  void _launchCall() async {
    if (controller.phoneNumber.isNotEmpty) {
      final Uri phoneUri = Uri(scheme: 'tel', path: controller.phoneNumber);
      try {
        await launchUrl(phoneUri);
      } catch (e) {
        log('Could not launch phone: $e');
        Get.snackbar('Error', 'Could not launch phone app',
            snackPosition: SnackPosition.BOTTOM);
      }
    }
  }

  void _launchWhatsApp() async {
    if (controller.phoneNumber.isNotEmpty) {
      final amount = controller.totalToReceive;
      final message =
          'Namaste, your outstanding balance is Rs. ${NumberFormat('#,##,###.00').format(amount)}. Please settle as soon as possible. Thank you.';

      // Format number correctly (remove any + and ensure it starts with country code)
      String whatsappNumber = controller.phoneNumber;
      if (!whatsappNumber.startsWith('+') &&
          !whatsappNumber.startsWith('977')) {
        whatsappNumber = '977$whatsappNumber'; // Add Nepal country code
      }
      whatsappNumber = whatsappNumber.replaceAll('+', '');

      final Uri whatsappUri = Uri.parse(
          'https://wa.me/$whatsappNumber?text=${Uri.encodeComponent(message)}');
      try {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } catch (e) {
        print('Could not launch WhatsApp: $e');
        Get.snackbar('Error', 'Could not open WhatsApp',
            snackPosition: SnackPosition.BOTTOM);
      }
    }
  }

  Widget _buildBody() {
    return RefreshIndicator(
      color: Color(0xFF3182CE),
      onRefresh: () async {
        await controller.refreshPartyData();
      },
      child: CustomScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPartyOverview(),
                SizedBox(height: 16),
                _buildBalanceCard(),
                SizedBox(height: 16),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: _buildTransactionHeader(),
                ),
                SizedBox(height: 8),
              ],
            ),
          ),
          _buildTransactionsContent(),
        ],
      ),
    );
  }

  Widget _buildPartyOverview() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: controller.isLoading.value
          ? _buildLoadingShimmer()
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildPartyAvatar(),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.partyName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.phone,
                            color: Color(0xFF718096),
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            controller.phoneNumber,
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF718096),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildPartyTypeBadge(),
              ],
            ),
    );
  }

  Widget _buildLoadingShimmer() {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 18,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              SizedBox(height: 8),
              Container(
                height: 14,
                width: 140,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPartyAvatar() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: controller.partyType == 'customer'
            ? Color(0xFF3182CE)
            : Color(0xFF805AD5),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: controller.partyType == 'customer'
                ? Color(0xFF3182CE).withOpacity(0.2)
                : Color(0xFF805AD5).withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          controller.partyName.isNotEmpty
              ? controller.partyName[0].toUpperCase()
              : 'P',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildPartyTypeBadge() {
    final isCustomer = controller.partyType == 'customer';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isCustomer ? Color(0xFFE6F0FB) : Color(0xFFEDE9F8),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isCustomer ? Color(0xFFBEE3F8) : Color(0xFFD6BCFA),
          width: 1,
        ),
      ),
      child: Text(
        isCustomer ? 'CUSTOMER' : 'SUPPLIER',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isCustomer ? Color(0xFF2B6CB0) : Color(0xFF6B46C1),
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    final isCustomer = controller.partyType == 'customer';
    final amount = controller.totalToReceive;
    final hasBalance = amount != 0;

    // Colors and text depend on party type and balance
    Color bgColor, borderColor, textColor;
    String balanceText;

    if (isCustomer) {
      // For customer
      if (amount > 0) {
        // Customer owes money
        bgColor = Color(0xFFFFEEEE);
        borderColor = Color(0xFFFFCCCC);
        textColor = Color(0xFFC53030);
        balanceText = 'पाउनु पर्ने रकम'; // Amount to Receive in Nepali
      } else if (amount < 0) {
        // We owe customer (advance payment)
        bgColor = Color(0xFFE6FFFA);
        borderColor = Color(0xFFB2F5EA);
        textColor = Color(0xFF2C7A7B);
        balanceText = 'दिनु पर्ने रकम'; // Amount to Pay in Nepali
      } else {
        // No balance
        bgColor = Color(0xFFF7FAFC);
        borderColor = Color(0xFFE2E8F0);
        textColor = Color(0xFF4A5568);
        balanceText = 'हिसाब मिल्यो'; // Settled in Nepali
      }
    } else {
      // For supplier
      if (amount > 0) {
        // We owe supplier
        bgColor = Color(0xFFE6FFFA);
        borderColor = Color(0xFFB2F5EA);
        textColor = Color(0xFF2C7A7B);
        balanceText = 'तिर्नु पर्ने रकम'; // Amount to Pay in Nepali
      } else if (amount < 0) {
        // Supplier owes us (advance payment)
        bgColor = Color(0xFFFFEEEE);
        borderColor = Color(0xFFFFCCCC);
        textColor = Color(0xFFC53030);
        balanceText = 'पाउनु पर्ने रकम'; // Amount to Receive in Nepali
      } else {
        // No balance
        bgColor = Color(0xFFF7FAFC);
        borderColor = Color(0xFFE2E8F0);
        textColor = Color(0xFF4A5568);
        balanceText = 'हिसाब मिल्यो'; // Settled in Nepali
      }
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: borderColor.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: borderColor),
                    ),
                    child: Icon(
                      hasBalance
                          ? Icons.account_balance_wallet
                          : Icons.check_circle,
                      color: textColor,
                      size: 16,
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Balance Status',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A5568),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    balanceText,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'रु. ${_formatCurrency(amount.abs())}', // Using Rupee symbol in Nepali
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              _buildBalanceTrendIcon(),
            ],
          ),
        ],
      ),
    );
  }

// Helper method for Indian format currency
  String _formatCurrency(double amount) {
    // Convert to integer if it's a whole number
    if (amount == amount.roundToDouble()) {
      amount = amount.roundToDouble();
    }

    // Format with Indian number system (lakhs, crores)
    String numString = amount.toString();

    // If it's an integer value, format without decimal
    if (numString.endsWith('.0')) {
      numString = numString.substring(0, numString.length - 2);
    }

    // If number is less than 1000, no formatting needed
    if (double.parse(numString) < 1000) {
      return numString;
    }

    // Split by decimal point
    List<String> parts = numString.split('.');
    String wholePart = parts[0];

    // Apply Indian number formatting to whole part
    String result = '';
    int len = wholePart.length;

    // Add the last 3 digits
    result = wholePart.substring(len - 3);

    // Add the rest with commas after every 2 digits
    int remaining = len - 3;
    int pos = remaining;

    while (pos > 0) {
      if (pos >= 2) {
        result = wholePart.substring(pos - 2, pos) + "," + result;
        pos -= 2;
      } else {
        result = wholePart.substring(0, pos) + "," + result;
        break;
      }
    }

    // Add back the decimal part if it exists
    if (parts.length > 1) {
      result = result + "." + parts[1];
    }

    return result;
  }

  Widget _buildBalanceTrendIcon() {
    final isCustomer = controller.partyType == 'customer';
    final amount = controller.totalToReceive;

    // Skip if balance is zero
    if (amount == 0) return SizedBox();

    Color iconColor = isCustomer
        ? (amount > 0 ? Color(0xFFC53030) : Color(0xFF2C7A7B))
        : (amount > 0 ? Color(0xFF2C7A7B) : Color(0xFFC53030));

    IconData iconData = isCustomer
        ? Icons.arrow_downward_outlined
        : Icons.arrow_upward_outlined;

    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        iconData,
        size: 24,
        color: iconColor,
      ),
    );
  }

  Widget _buildTransactionHeader() {
    return Text(
      'Transction History', // Changed to Nepali
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Color(0xFF2D3748),
      ),
    );
  }

  Widget _buildTransactionsContent() {
    if (controller.isLoading.value) {
      return SliverFillRemaining(
        child: _buildLoadingTransactions(),
      );
    } else if (controller.recentTransactions.isEmpty) {
      return _buildNoTransactions();
    } else {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index == 0) {
              return _buildTransactionsContainer(
                child: Column(
                  children: [
                    Divider(height: 1, thickness: 1, color: Color(0xFFEDF2F7)),
                  ],
                ),
              );
            } else if (index <= controller.recentTransactions.length) {
              final transactionIndex = index - 1;
              final transaction =
                  controller.recentTransactions[transactionIndex];
              final isLast =
                  transactionIndex == controller.recentTransactions.length - 1;

              return _buildTransactionsContainer(
                showBottomPadding: isLast,
                child: _buildTransactionItem(transaction, isLast),
              );
            } else {
              return SizedBox(height: 80); // Bottom padding
            }
          },
          childCount: controller.recentTransactions.length + 2,
        ),
      );
    }
  }

  Widget _buildTransactionsContainer(
      {required Widget child, bool showBottomPadding = false}) {
    return Container(
      margin: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: showBottomPadding ? 16 : 0,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildLoadingTransactions() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Color(0xFF3182CE),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'लेनदेनहरू लोड गर्दै...',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF718096),
            ),
          ),
        ],
      ),
    );
  }

  // Updated _buildTransactionItem method with consistent colors
  Widget _buildTransactionItem(Map<String, dynamic> transaction, bool isLast) {
    final amount =
        double.tryParse(transaction['amount']?.toString() ?? '0') ?? 0.0;
    final transactionType = transaction['transaction_type'] ?? 'unknown';
    final isCustomer = controller.partyType == 'customer';
    final date = controller.formatDate(transaction['date']);
    final description = transaction['description'] ?? '';
    final billCode = transaction['bill_code'];

    // Define consistent colors for both transaction items and bottom buttons
    Color indicatorBgColor, indicatorBorderColor, indicatorTextColor;
    IconData iconData;
    String actionText;
    bool isPositiveForBalance;

    if (isCustomer) {
      if (transactionType == 'paune_parne') {
        // Customer - Amount to receive - Red theme
        indicatorBgColor = Color(0xFFFFF5F5);
        indicatorBorderColor = Color(0xFFFFCCCC);
        indicatorTextColor = Color(0xFFC53030);
        iconData = Icons.arrow_downward;
        actionText = 'पाउनु पर्ने';
        isPositiveForBalance = true;
      } else {
        // Customer - Amount received - Green theme
        indicatorBgColor = Color(0xFFF0FFF4);
        indicatorBorderColor = Color(0xFFC6F6D5);
        indicatorTextColor = Color(0xFF2F855A);
        iconData = Icons.arrow_downward;
        actionText = 'प्राप्त भयो';
        isPositiveForBalance = false;
      }
    } else {
      if (transactionType == 'paune_parne') {
        // Supplier - Amount to pay - Green theme (reversed logic)
        indicatorBgColor = Color(0xFFF0FFF4);
        indicatorBorderColor = Color(0xFFC6F6D5);
        indicatorTextColor = Color(0xFF2F855A);
        iconData = Icons.arrow_upward;
        actionText = 'तिर्नु पर्ने';
        isPositiveForBalance = false;
      } else {
        // Supplier - Amount paid - Red theme (reversed logic)
        indicatorBgColor = Color(0xFFFFF5F5);
        indicatorBorderColor = Color(0xFFFFCCCC);
        indicatorTextColor = Color(0xFFC53030);
        iconData = Icons.arrow_upward;
        actionText = 'रकम तिरेको';
        isPositiveForBalance = true;
      }
    }

    return Container(
      decoration: BoxDecoration(
        border: !isLast
            ? Border(
                bottom: BorderSide(color: Color(0xFFEDF2F7), width: 1),
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: isLast
              ? BorderRadius.vertical(bottom: Radius.circular(10))
              : null,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: indicatorBgColor,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: indicatorBorderColor, width: 1),
                      ),
                      child: Center(
                        child: Icon(
                          iconData,
                          size: 22,
                          color: indicatorTextColor,
                        ),
                      ),
                    ),
                    SizedBox(width: 14),

                    // Transaction details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                actionText,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2D3748),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: indicatorBgColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: indicatorBorderColor,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  'Rs. ${NumberFormat('#,##,###.00').format(amount.abs())}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: indicatorTextColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6),

                          // Transaction date and description
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Color(0xFFEDF2F7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  date,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF4A5568),
                                  ),
                                ),
                              ),
                              if (billCode != null &&
                                  billCode.toString().isNotEmpty) ...[
                                SizedBox(width: 6),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFE6FFFA),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.receipt,
                                        size: 10,
                                        color: Color(0xFF2C7A7B),
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        billCode.toString().toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF2C7A7B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),

                          if (description.isNotEmpty) ...[
                            SizedBox(height: 6),
                            Text(
                              description,
                              style: TextStyle(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: Color(0xFF718096),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoTransactions() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 24),
            Text(
              'अहिलेसम्म कुनै लेनदेन छैन',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'No transactions found',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF718096),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            _buildEmptyStateGuide(),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateGuide() {
    final isCustomer = controller.partyType == 'customer';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'लेनदेन कसरी थप्ने?',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
          SizedBox(height: 12),

          // First option
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Color(0xFFFFF5F5).withOpacity(0.7),
                  shape: BoxShape.circle,
                  border: Border.all(color: Color(0xFFFFCCCC)),
                ),
                child: Icon(
                  Icons.arrow_circle_up_outlined,
                  size: 16,
                  color: Color(0xFFC53030),
                ),
              ),
              SizedBox(width: 12),
              Text(
                isCustomer
                    ? 'पाउनु पर्ने रकम जोड्न तलको रातो बटन प्रयोग गर्नुहोस्'
                    : 'तिर्नु पर्ने रकम जोड्न तलको रातो बटन प्रयोग गर्नुहोस्',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF4A5568),
                ),
              ),
            ],
          ),

          SizedBox(height: 12),

          // Second option
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Color(0xFFF0FFF4).withOpacity(0.7),
                  shape: BoxShape.circle,
                  border: Border.all(color: Color(0xFFC6F6D5)),
                ),
                child: Icon(
                  Icons.arrow_circle_down_outlined,
                  size: 16,
                  color: Color(0xFF2F855A),
                ),
              ),
              SizedBox(width: 12),
              Text(
                isCustomer
                    ? 'प्राप्त रकम जोड्न तलको हरियो बटन प्रयोग गर्नुहोस्'
                    : 'तिरेको रकम जोड्न तलको हरियो बटन प्रयोग गर्नुहोस्',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF4A5568),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Updated _buildBottomNavigation method with consistent colors
  Widget _buildBottomNavigation() {
    final isCustomer = controller.partyType == 'customer';

    // Define consistent colors that match the transaction items
    // Primary button - for "Amount to Receive" (customer) or "Amount to Pay" (supplier)
    Color primaryBgColor = isCustomer ? Color(0xFFFFF5F5) : Color(0xFFF0FFF4);
    Color primaryBorderColor =
        isCustomer ? Color(0xFFFFCCCC) : Color(0xFFC6F6D5);
    Color primaryTextColor = isCustomer ? Color(0xFFC53030) : Color(0xFF2F855A);

    // Secondary button - for "Amount Received" (customer) or "Amount Paid" (supplier)
    Color secondaryBgColor = isCustomer ? Color(0xFFF0FFF4) : Color(0xFFFFF5F5);
    Color secondaryBorderColor =
        isCustomer ? Color(0xFFC6F6D5) : Color(0xFFFFCCCC);
    Color secondaryTextColor =
        isCustomer ? Color(0xFF2F855A) : Color(0xFFC53030);

    // Button text based on party type - in Nepali
    String primaryButtonText =
        isCustomer ? 'रकम पाउनु पर्ने' : 'रकम तिर्नु पर्ने';
    String secondaryButtonText = isCustomer ? 'रकम प्राप्त' : 'रकम तिरेको';

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFEDF2F7), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Primary Button
            Expanded(
              child: ElevatedButton(
                onPressed: () => isCustomer
                    ? _showReceiveAmountDialog()
                    : _showGiveAmountDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBgColor,
                  foregroundColor: primaryTextColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: primaryBorderColor),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      primaryButtonText,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(width: 12),

            // Secondary Button
            Expanded(
              child: ElevatedButton(
                onPressed: () => isCustomer
                    ? _showAmountReceivedDialog()
                    : _showAmountPaidDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: secondaryBgColor,
                  foregroundColor: secondaryTextColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: secondaryBorderColor),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      secondaryButtonText,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Transaction entry methods
  void _showReceiveAmountDialog() {
    Get.to(() => TransactionEntryView(), arguments: {
      'partyData': controller.partyData.value,
      'transactionType': 'paune_parne',
    })?.then((result) {
      if (result == true) {
        controller.onTransactionAdded();
      }
    });
  }

  void _showAmountReceivedDialog() {
    Get.to(() => TransactionEntryView(), arguments: {
      'partyData': controller.partyData.value,
      'transactionType': 'rakam_prapta',
    })?.then((result) {
      if (result == true) {
        controller.onTransactionAdded();
      }
    });
  }

  void _showGiveAmountDialog() {
    Get.to(() => TransactionEntryView(), arguments: {
      'partyData': controller.partyData.value,
      'transactionType': 'paune_parne',
    })?.then((result) {
      if (result == true) {
        controller.onTransactionAdded();
      }
    });
  }

  void _showAmountPaidDialog() {
    Get.to(() => TransactionEntryView(), arguments: {
      'partyData': controller.partyData.value,
      'transactionType': 'rakam_prapta',
    })?.then((result) {
      if (result == true) {
        controller.onTransactionAdded();
      }
    });
  }
}
