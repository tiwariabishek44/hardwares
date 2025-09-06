import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hardwares/app/modules/party__details/party_details.dart';
import 'package:hardwares/app/modules/transaction/transaction_controller.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class PartyTab extends StatelessWidget {
  final TransactionController controller;

  const PartyTab({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Add a reactive variable to track the current filter
    final Rx<String> selectedFilter = 'all'.obs;

    return Obx(() {
      if (controller.parties.isEmpty) {
        return _buildEmptyPartyState();
      }

      // Filter parties based on selected filter
      List<Map<String, dynamic>> filteredParties = controller.parties;

      if (selectedFilter.value == 'customer') {
        filteredParties = controller.parties
            .where((party) => party['party_type'] == 'customer')
            .toList();
      } else if (selectedFilter.value == 'supplier') {
        filteredParties = controller.parties
            .where((party) => party['party_type'] == 'supplier')
            .toList();
      }

      return Container(
        color: Color(0xFFF8F9FA),
        child: Column(
          children: [
            // Filter chips row
            _buildFilterChips(selectedFilter),

            // Party list
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  print('🔄 Manual refresh triggered for party list');
                  await controller.forceRefreshParties();
                },
                child: filteredParties.isEmpty
                    ? _buildNoPartiesForFilter(selectedFilter.value)
                    : ListView.separated(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 80),
                        physics: AlwaysScrollableScrollPhysics(),
                        itemCount: filteredParties.length,
                        separatorBuilder: (context, index) =>
                            SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final party = filteredParties[index];
                          return _buildPartyCard(party);
                        },
                      ),
              ),
            ),
          ],
        ),
      );
    });
  }

  // New widget for filter chips
  Widget _buildFilterChips(Rx<String> selectedFilter) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // All Filter
            Obx(() => _buildFilterChip(
                  label: 'All',
                  icon: Icons.people,
                  count: controller.parties.length,
                  isSelected: selectedFilter.value == 'all',
                  onTap: () => selectedFilter.value = 'all',
                )),
            SizedBox(width: 12),

            // Customer Filter
            Obx(() {
              int customerCount = controller.parties
                  .where((party) => party['party_type'] == 'customer')
                  .length;
              return _buildFilterChip(
                label: 'Customer',
                icon: Icons.person,
                count: customerCount,
                isSelected: selectedFilter.value == 'customer',
                onTap: () => selectedFilter.value = 'customer',
                chipColor: Color(0xFF1976D2),
              );
            }),
            SizedBox(width: 12),

            // Supplier Filter
            Obx(() {
              int supplierCount = controller.parties
                  .where((party) => party['party_type'] == 'supplier')
                  .length;
              return _buildFilterChip(
                label: 'Supplier',
                icon: Icons.inventory_2_outlined,
                count: supplierCount,
                isSelected: selectedFilter.value == 'supplier',
                onTap: () => selectedFilter.value = 'supplier',
                chipColor: Color(0xFF9C27B0),
              );
            }),
          ],
        ),
      ),
    );
  }

  // Individual filter chip widget
  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
    Color chipColor = const Color(0xFF455A64),
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? chipColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: isSelected ? chipColor : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? chipColor : Colors.grey[600],
              ),
            ),
            SizedBox(width: 6),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? chipColor : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget to show when no parties match the filter
  Widget _buildNoPartiesForFilter(String filterType) {
    String message;
    IconData icon;
    Color color;

    switch (filterType) {
      case 'customer':
        message = 'कुनै ग्राहक भेटिएन';
        icon = Icons.person_off;
        color = Color(0xFF1976D2);
        break;
      case 'supplier':
        message = 'कुनै आपूर्तिकर्ता भेटिएन';
        color = Color(0xFF9C27B0);
        break;
      default:
        message = 'कुनै पार्टी भेटिएन';
        color = Colors.grey[700]!;
    }

    return ListView(
      padding: EdgeInsets.all(20),
      physics: AlwaysScrollableScrollPhysics(), // For pull-to-refresh to work
      children: [
        SizedBox(height: 20),
        Text(
          message,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 20),
      ],
    );
  }

  // Updated _buildPartyCard method for the PartyTab class
  Widget _buildPartyCard(Map<String, dynamic> party) {
    final balance = double.tryParse(party['balance']?.toString() ?? '0') ?? 0.0;
    final isCustomer = party['party_type'] == 'customer';

    return GestureDetector(
      onTap: () async {
        // Navigate to party details and wait for result
        final result = await Get.to(() => PartyDetailView(), arguments: party);

        // If we get any result (transaction was added), refresh the party list
        if (result != null) {
          log('🔄 Returned from party details, refreshing party list...');
          await controller.forceRefreshParties();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              // Party Avatar - color still indicates customer/supplier type
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isCustomer
                      ? Color(0xFF1976D2).withOpacity(0.1)
                      : Color(0xFF9C27B0).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: isCustomer
                          ? Color(0xFF1976D2).withOpacity(0.3)
                          : Color(0xFF9C27B0).withOpacity(0.3)),
                ),
                child: Center(
                  child: Text(
                    party['name']?.substring(0, 1).toUpperCase() ?? 'P',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isCustomer ? Color(0xFF1976D2) : Color(0xFF9C27B0),
                    ),
                  ),
                ),
              ),

              SizedBox(width: 16),

              // Party Details - removed customer/supplier label
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      party['name'] ?? 'Unknown Party',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF212121),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.phone_outlined,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: 4),
                        Text(
                          party['phone'] ?? 'No phone',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(width: 16),

              // Balance Section - Show "Settled" for zero balance
              balance != 0
                  ? _buildBalanceIndicator(balance, isCustomer)
                  : _buildSettledIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  // Updated balance indicator for non-zero balances (unchanged)
  Widget _buildBalanceIndicator(double balance, bool isCustomer) {
    // Colors and text depend on party type and balance
    Color textColor = Colors.red;
    String balanceText = '';
    IconData iconData = Icons.help_outline;

    // Format balance with comma separators (Indian format)
    final formattedBalance = _formatCurrency(balance.abs());

    if (isCustomer) {
      // For customer
      if (balance > 0) {
        // Customer owes money
        textColor = Color(0xFF2C7A7B);
        balanceText = 'पाउनु पर्ने';
        iconData = Icons.arrow_downward;
      } else {
        // Customer has negative balance (we owe customer)
        textColor = Color(0xFFC53030);
        balanceText = 'दिनु पर्ने';
        iconData = Icons.arrow_upward;
      }
    } else {
      // For supplier
      if (balance > 0) {
        // We owe supplier
        textColor = Color(0xFFC53030);
        balanceText = 'तिर्नु पर्ने';
        iconData = Icons.arrow_upward;
      } else {
        // Supplier owes us
        textColor = Color(0xFF2C7A7B);
        balanceText = 'पाउनु पर्ने';
        iconData = Icons.arrow_downward;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'Rs. $formattedBalance',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              iconData,
              size: 14,
              color: textColor,
            ),
            SizedBox(width: 4),
            Text(
              balanceText,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // New widget to show "Settled" for zero balance
  Widget _buildSettledIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'Rs. 0',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF4A5568),
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Settled',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF718096),
          ),
        ),
      ],
    );
  }

  // Add this helper method to format currency with Indian number format
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

  // Empty state widget remains the same...
  Widget _buildEmptyPartyState() {
    // Existing implementation remains unchanged...
    return RefreshIndicator(
      onRefresh: () async {
        await controller.forceRefreshParties();
      },
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              SizedBox(height: 2.h),

              // Empty State
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[100]!, Colors.blue[50]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.people_outline,
                  size: 25.sp,
                  color: Colors.blue[400],
                ),
              ),

              SizedBox(height: 24),

              Text(
                'अहिलेसम्म कुनै पार्टी छैन',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212121),
                ),
              ),

              SizedBox(height: 8),

              Text(
                'पहिलो पटक प्रयोग गर्दै हुनुहुन्छ? तलका निर्देशनहरू हेर्नुहोस्',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 32),

              // Beautiful Guide Card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF1976D2).withOpacity(0.05),
                      Color(0xFF1976D2).withOpacity(0.02),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Color(0xFF1976D2).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Color(0xFF1976D2),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.school,
                            color: Colors.white,
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'पार्टी व्यवस्थापन सिक्नुहोस्',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Content remains the same...
                    Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Step 1
                          _buildDetailedStep(
                            step: '१',
                            title: 'नयाँ पार्टी थप्नुहोस्',
                            description:
                                'ग्राहक वा supplier को नाम, फोन नम्बर र ठेगाना राखेर नयाँ पार्टी बनाउनुहोस्',
                            color: Color(0xFF1976D2),
                            icon: Icons.person_add,
                            buttonText: 'Add Party',
                          ),

                          SizedBox(height: 20),

                          // Divider
                          Row(
                            children: [
                              Expanded(child: Divider(color: Colors.grey[300])),
                              Container(
                                margin: EdgeInsets.symmetric(horizontal: 16),
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  'त्यसपछि',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: Colors.grey[300])),
                            ],
                          ),

                          SizedBox(height: 20),

                          // Step 2
                          _buildDetailedStep(
                            step: '२',
                            title: 'सजिलो लेनदेन व्यवस्थापन',
                            description:
                                'पार्टी Add गरेपछि, पार्टीलाई click गरेर transaction entry गर्न सक्नुहुन्छ। ',
                            color: Colors.green[600]!,
                            icon: Icons.account_balance_wallet,
                            buttonText: 'लेनदेन व्यवस्थापन',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10.h),
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods remain the same...
  Widget _buildDetailedStep({
    required String step,
    required String title,
    required String description,
    required Color color,
    required IconData icon,
    required String buttonText,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Step header
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    step,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF212121),
                  ),
                ),
              ),
              Icon(icon, color: color, size: 24),
            ],
          ),

          SizedBox(height: 12),

          // Description
          Text(
            description,
            style: TextStyle(
              fontSize: 15.sp,
              color: const Color.fromARGB(255, 34, 34, 34),
              height: 1.5,
            ),
          ),

          SizedBox(height: 16),

          // Button preview with arrow
          if (step != "२")
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.touch_app,
                  color: color,
                  size: 16,
                ),
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        step == '१' ? Icons.person_add : Icons.manage_accounts,
                        size: 16,
                        color: color,
                      ),
                      SizedBox(width: 6),
                      Text(
                        buttonText,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                Icon(
                  Icons.arrow_upward,
                  color: color,
                  size: 16,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
