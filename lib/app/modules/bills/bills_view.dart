import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hardwares/app/modules/bills/bills_controller.dart';
import 'package:hardwares/app/modules/bills_detail/bills_detail_view.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class BillsView extends StatelessWidget {
  BillsView({Key? key}) : super(key: key);
  final controller = Get.put(BillsController());

  @override
  Widget build(BuildContext context) {
    // Force refresh and debug when building
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.refreshOrders();
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Obx(() => _buildBody()),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF212121),
      elevation: 0,
      centerTitle: false,
      scrolledUnderElevation: 0,
      title: Text(
        'Bills',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF212121),
        ),
      ),
      actions: [
        Obx(() => Container(
              margin: EdgeInsets.only(right: 16),
              child: IconButton(
                icon: controller.isRefreshing
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
                onPressed:
                    controller.isRefreshing ? null : controller.refreshOrders,
                tooltip: 'Refresh',
              ),
            )),
      ],
    );
  }

  Widget _buildBody() {
    if (controller.isLoading) {
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
                'Loading Bills',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212121),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Please wait while we load your bills...',
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

    if (controller.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      color: Color(0xFFF8F9FA),
      child: Column(
        children: [
          // Header Section
          Container(
            color: Colors.white,
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.receipt_long,
                  color: Color(0xFF1976D2),
                  size: 20,
                ),
                SizedBox(width: 12),
                Text(
                  'All Bills',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF212121),
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(0xFF1976D2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${controller.totalOrders} bills',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1976D2),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bills List
          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.refreshOrders,
              color: Color(0xFF1976D2),
              child: Container(
                padding: EdgeInsets.all(16),
                child: ListView.separated(
                  itemCount: controller.orders.length,
                  separatorBuilder: (context, index) => SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final order = controller.orders[index];
                    return _buildOrderCard(order);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: controller.refreshOrders,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              SizedBox(height: 40),

              // Empty State Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.receipt_long_outlined,
                  size: 40,
                  color: Colors.blue[400],
                ),
              ),

              SizedBox(height: 20),

              // Main Message
              Text(
                'अहिलेसम्म कुनै Item list/ Bill छैन',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212121),
                ),
              ),

              SizedBox(height: 8),

              Text(
                'तपाईंले customer को लागि बनाउने   plumbing सामानको list यहाँ देखिन्छ',
                style: TextStyle(
                  fontSize: 15.sp,
                  color: const Color.fromARGB(255, 39, 38, 38),
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 32),

              // Sample bill preview
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
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
                    Row(
                      children: [
                        Icon(
                          Icons.preview,
                          color: Color(0xFF1976D2),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'बिल यस्तो देखिन्छ:',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF212121),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 12),

                    // Sample bill card
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          // Status icon
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.green[200]!),
                            ),
                            child: Icon(
                              Icons.cloud_done,
                              color: Colors.green[700],
                              size: 16,
                            ),
                          ),

                          SizedBox(width: 12),

                          // Bill info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ram Babu Shrestha',
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFF212121),
                                  ),
                                ),
                                Text(
                                  '२०८१-०३-१५',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color:
                                        const Color.fromARGB(255, 57, 57, 57),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Click indicator
                          Row(
                            children: [
                              Text(
                                'Click',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: Colors.grey[500],
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.grey[400],
                                size: 12,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 8),

                    // Click instruction
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.touch_app,
                          color: Color(0xFF1976D2),
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'यस्तै बिलमा click गरेर detail हेर्नुहोस्',
                          style: TextStyle(
                            fontSize: 15.sp,
                            color: Color(0xFF1976D2),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final orderId = order['id'] as int;
    final isUnsynced = (order['synced'] ?? 0) == 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isUnsynced ? Colors.orange[400]! : Colors.green[400]!,
          width: isUnsynced ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        // Always navigate to details view, no sync operation here
        onTap: () => Get.to(() => BillsDetailView(), arguments: order),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              // Sync Status Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isUnsynced ? Colors.orange[50] : Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        isUnsynced ? Colors.orange[200]! : Colors.green[200]!,
                  ),
                ),
                child: Center(
                  child: Icon(
                    isUnsynced ? Icons.cloud_off : Icons.cloud_done,
                    color: isUnsynced ? Colors.orange[700] : Colors.green[700],
                    size: 20,
                  ),
                ),
              ),

              SizedBox(width: 16),

              // Order Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order['customer_name'] ?? 'Unknown Customer',
                      style: TextStyle(
                        fontSize: 16.5.sp,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF212121),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      controller.getFormattedDate(order['created_at']),
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: const Color.fromARGB(255, 25, 25, 25),
                      ),
                    ),
                  ],
                ),
              ),

              // Navigation Arrow
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBillInstructionItem({
    required String step,
    required String title,
    required String description,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Step number
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF212121),
                        ),
                      ),
                    ),
                    Icon(icon, color: color, size: 20),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.blue[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
