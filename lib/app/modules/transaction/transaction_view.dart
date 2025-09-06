import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hardwares/app/modules/add_party/add_party.dart';
import 'package:hardwares/app/modules/party_tab/party.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'transaction_controller.dart';

class TransactionView extends StatelessWidget {
  TransactionView({Key? key}) : super(key: key);
  final controller = Get.put(TransactionController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: Obx(() => _buildBody()),
      floatingActionButton: _buildFloatingActionButton(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF212121),
      elevation: 0,
      centerTitle: false,
      automaticallyImplyLeading: false,
      title: Text(
        'Parties', // Changed from 'Finance' to 'Parties'
        style: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
          color: Color(0xFF212121),
        ),
      ),
      actions: [
        Obx(() => Container(
              margin: EdgeInsets.only(right: 16),
              child: IconButton(
                icon: controller.isRefreshing.value
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF1976D2),
                        ),
                      )
                    : Icon(
                        Icons.refresh,
                        color: Color(0xFF1976D2),
                        size: 24,
                      ),
                onPressed: controller.isRefreshing.value
                    ? null
                    : controller.refreshTransactions,
                tooltip: 'Refresh',
              ),
            )),
      ],
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Container(
          height: 1,
          color: Colors.grey[200],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (controller.isLoading.value) {
      return _buildLoadingState();
    }

    // Directly return the PartyTab without any TabBarView
    return PartyTab(controller: controller);
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        Get.to(() => AddPartyView());
      },
      backgroundColor: Color(0xFF1976D2),
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      icon: Icon(
        Icons.person_add,
        size: 20.sp,
      ),
      label: Text(
        'Add Party',
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: Color(0xFF1976D2),
              strokeWidth: 3,
            ),
            SizedBox(height: 20),
            Text(
              'Loading Parties', // Changed from 'Loading Transactions'
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF212121),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Please wait while we load your data...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
