import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hardwares/app/modules/transaction/transaction_controller.dart';

class FinanceSummary extends StatelessWidget {
  final TransactionController controller;

  const FinanceSummary({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 90,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // Amount Received Card
                _buildCleanSummaryCard(
                  title: 'Amount Received',
                  amount: controller.getTotalReceived(),
                  icon: Icons.arrow_upward,
                  isPositive: true,
                ),

                SizedBox(width: 12),

                // Expenses Card
                _buildCleanSummaryCard(
                  title: 'Expenses',
                  amount: controller.getTotalExpenses(),
                  icon: Icons.arrow_downward,
                  isPositive: false,
                ),

                SizedBox(width: 12),

                // Net Balance Card
                _buildCleanSummaryCard(
                  title: 'Net Balance',
                  amount: controller.getNetBalance(),
                  icon: Icons.account_balance_wallet,
                  isBalance: true,
                ),

                SizedBox(width: 12),

                // Total Orders Card
                _buildCleanSummaryCard(
                  title: 'Total Orders',
                  amount: controller.getTotalOrders().toDouble(),
                  icon: Icons.receipt_long,
                  showCurrency: false,
                ),

                SizedBox(width: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCleanSummaryCard({
    required String title,
    required double amount,
    required IconData icon,
    bool isPositive = false,
    bool isBalance = false,
    bool showCurrency = true,
  }) {
    // Simple color logic - no fancy colors
    Color textColor;
    Color backgroundColor;
    Color borderColor;

    if (isBalance) {
      // Net balance uses blue
      textColor = Color(0xFF1976D2);
      backgroundColor = Colors.white;
      borderColor = Color(0xFF1976D2).withOpacity(0.3);
    } else if (isPositive) {
      // Income uses green
      textColor = Colors.green[700]!;
      backgroundColor = Colors.white;
      borderColor = Colors.green[300]!;
    } else {
      // Expenses and others use standard colors
      textColor = Colors.red[700]!;
      backgroundColor = Colors.white;
      borderColor = Colors.red[300]!;
    }

    // For non-financial data (like order count), use neutral colors
    if (!showCurrency) {
      textColor = Colors.grey[700]!;
      borderColor = Colors.grey[300]!;
    }

    return Container(
      width: 160,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Icon and Title Row
          Row(
            children: [
              Icon(
                icon,
                color: textColor,
                size: 18,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          SizedBox(height: 8),

          // Amount
          Text(
            showCurrency
                ? 'Rs. ${amount.abs().toStringAsFixed(0)}'
                : amount.toStringAsFixed(0),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
