import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hardwares/app/modules/transaction/transaction_controller.dart';
import 'package:intl/intl.dart';

class TransactionTab extends StatelessWidget {
  final TransactionController controller;

  const TransactionTab({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.transactions.isEmpty) {
        return Center(
          child: CircularProgressIndicator(),
        );
      }

      if (controller.transactions.isEmpty) {
        return _buildEmptyTransactionState();
      }

      return Container(
        color: Color(0xFFF8F9FA),
        child: RefreshIndicator(
          onRefresh: controller.refreshTransactions,
          color: Color(0xFF1976D2),
          child: ListView.separated(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: controller.transactions.length,
            separatorBuilder: (context, index) => SizedBox(height: 12),
            itemBuilder: (context, index) {
              final transaction = controller.transactions[index];
              return _buildTransactionCard(transaction);
            },
          ),
        ),
      );
    });
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final transactionType = transaction['transaction_type'] ?? '';
    final partyType = transaction['party_type'] ?? 'customer';
    final isCustomer = partyType == 'customer';
    final isPayment = transactionType == 'rakam_prapta';
    final isReceivable = transactionType == 'paune_parne';

    // Determine colors and icons based on transaction type and party type
    Color statusColor;
    IconData iconData;

    if (isPayment) {
      // Payment received or made
      if (isCustomer) {
        statusColor = Colors.green[600]!; // Customer paying us (green)
        iconData = Icons.arrow_downward;
      } else {
        statusColor = Colors.red[600]!; // Us paying supplier (red)
        iconData = Icons.arrow_upward;
      }
    } else if (isReceivable) {
      // Amount to be received or paid
      if (isCustomer) {
        statusColor = Colors.orange[600]!; // Customer owes us (orange)
        iconData = Icons.account_balance_wallet;
      } else {
        statusColor = Colors.blue[600]!; // We owe supplier (blue)
        iconData = Icons.shopping_bag;
      }
    } else {
      // Unknown transaction type
      statusColor = Colors.grey[600]!;
      iconData = Icons.help_outline;
    }

    // Get formatted amount with thousands separator
    String formattedAmount =
        NumberFormat('#,##,###.##').format(transaction['amount'] ?? 0);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
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
            // Transaction Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Center(
                child: Icon(
                  iconData,
                  color: statusColor,
                  size: 24,
                ),
              ),
            ),

            SizedBox(width: 16),

            // Transaction Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        transaction['customer_name'] ?? 'Unknown Party',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF212121),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(width: 6),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isCustomer
                              ? Color(0xFFE6F0FB)
                              : Color(0xFFEDE9F8),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isCustomer
                                ? Color(0xFFBEE3F8)
                                : Color(0xFFD6BCFA),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          isCustomer ? 'customer' : 'supplier',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: isCustomer
                                ? Color(0xFF2B6CB0)
                                : Color(0xFF6B46C1),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),

                  // Transaction type in Nepali
                  Text(
                    controller.getTransactionTypeDisplay(transaction),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: statusColor,
                    ),
                  ),

                  SizedBox(height: 4),

                  // Date and description row
                  Row(
                    children: [
                      // Date
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 12,
                              color: Color(0xFF64748B),
                            ),
                            SizedBox(width: 4),
                            Text(
                              transaction['display_date'] ?? '',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Description (if available)
                      if (transaction['description'] != null &&
                          transaction['description'].toString().isNotEmpty) ...[
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '• ${transaction['description']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(width: 16),

            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Rs. $formattedAmount',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTransactionState() {
    return RefreshIndicator(
      onRefresh: controller.refreshTransactions,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Container(
          height: 400,
          child: Center(
            child: Container(
              padding: EdgeInsets.all(32),
              margin: EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.receipt_long_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'कुनै लेनदेन छैन',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF212121),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'तपाईंको लेनदेनको विवरण यहाँ देखिनेछ',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
