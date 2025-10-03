import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hardwares/app/modules/transction_entry/transction_entry_controller.dart';
import 'package:intl/intl.dart';
import 'package:nepali_utils/nepali_utils.dart';
import 'package:nepali_date_picker/nepali_date_picker.dart';

class TransactionEntryView extends StatelessWidget {
  TransactionEntryView({super.key});
  final controller = Get.put(TransactionEntryController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF1F5F9),
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      scrolledUnderElevation: 0,
      title: Obx(() => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getTransactionTitle(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                _getTransactionTitleNepali(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          )),
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF1E293B),
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Color(0xFF1E293B), size: 22),
        onPressed: () => Navigator.pop(Get.context!),
      ),
      shape: Border(
        bottom: BorderSide(
          color: Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
    );
  }

  String _getTransactionTitle() {
    String partyType = controller.partyData['party_type'] ?? 'customer';

    if (partyType == 'customer') {
      return controller.selectedTransactionType.value == 'paune_parne'
          ? 'Add Amount to Receive'
          : 'Record Payment Received';
    } else {
      return controller.selectedTransactionType.value == 'paune_parne'
          ? 'Add Amount to Pay'
          : 'Record Payment Made';
    }
  }

  String _getTransactionTitleNepali() {
    String partyType = controller.partyData['party_type'] ?? 'customer';

    if (partyType == 'customer') {
      return controller.selectedTransactionType.value == 'paune_parne'
          ? 'पाउनु पर्ने रकम थप्नुहोस्'
          : 'रकम प्राप्त भएको जानकारी';
    } else {
      return controller.selectedTransactionType.value == 'paune_parne'
          ? 'तिर्नु पर्ने रकम थप्नुहोस्'
          : 'भुक्तानी गरेको जानकारी';
    }
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      child: Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPartyInfoCard(),
            SizedBox(height: 12),
            _buildAmountCard(),
            SizedBox(height: 12),
            _buildDateCard(),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPartyInfoCard() {
    final isCustomer = controller.partyData['party_type'] == 'customer';

    return Card(
      color: Colors.white,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.person_outline,
                    size: 18,
                    color: Color(0xFF64748B),
                  ),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Party Information",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      "पार्टी जानकारी",
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 16),
            Divider(height: 1, thickness: 1, color: Color(0xFFEDF2F7)),
            SizedBox(height: 16),

            // Party Details
            Row(
              children: [
                // Party Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isCustomer ? Color(0xFF3182CE) : Color(0xFF805AD5),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: isCustomer
                            ? Color(0xFF3182CE).withOpacity(0.2)
                            : Color(0xFF805AD5).withOpacity(0.2),
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      controller.partyData['name']?.toString().isNotEmpty ==
                              true
                          ? controller.partyData['name'][0].toUpperCase()
                          : 'P',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 16),

                // Party Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.partyData['name'] ?? 'Unknown Party',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.phone_outlined,
                            size: 14,
                            color: Color(0xFF64748B),
                          ),
                          SizedBox(width: 4),
                          Text(
                            controller.partyData['phone'] ?? 'No phone',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Party Type Badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isCustomer ? Color(0xFFE6F0FB) : Color(0xFFEDE9F8),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isCustomer ? Color(0xFFBEE3F8) : Color(0xFFD6BCFA),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        isCustomer ? 'CUSTOMER' : 'SUPPLIER',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isCustomer
                              ? Color(0xFF2B6CB0)
                              : Color(0xFF6B46C1),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountCard() {
    return Card(
      color: Colors.white,
      margin: EdgeInsets.symmetric(horizontal: 6, vertical: 0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Row(
              children: [
                Obx(() => Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: controller.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        controller.selectedTransactionType.value ==
                                'paune_parne'
                            ? Icons.add_circle_outline
                            : Icons.check_circle_outline,
                        color: controller.primaryColor,
                        size: 18,
                      ),
                    )),
                SizedBox(width: 12),
                Obx(() => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getAmountSectionTitle(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    )),
              ],
            ),

            SizedBox(height: 16),
            Divider(height: 1, thickness: 1, color: Color(0xFFEDF2F7)),
            SizedBox(height: 16),

            // Amount Field
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      "Amount",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: controller.amountController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1E293B),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  decoration: InputDecoration(
                    hintText: 'Enter amount  ',
                    prefixIcon: Container(
                      width: 50,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      margin: EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(8),
                          bottomLeft: Radius.circular(8),
                        ),
                        border: Border(
                          right: BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Rs.',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                          color: controller.primaryColor, width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.red[400]!, width: 1),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: controller.validateAmount,
                ),
              ],
            ),

            // Maximum Amount Information
            Obx(() {
              if (controller.selectedTransactionType.value == 'rakam_prapta' &&
                  controller.maxAllowedAmount.value > 0 &&
                  controller.maxAllowedAmount.value != double.infinity) {
                return Container(
                  margin: EdgeInsets.only(top: 10),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: controller.primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: controller.primaryColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: controller.primaryColor,
                      ),
                      SizedBox(width: 8),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'अधिकतम रकम: रू. ${NumberFormat('#,##,###.00').format(controller.maxAllowedAmount.value)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: controller.primaryColor,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }
              return SizedBox.shrink();
            }),
          ],
        ),
      ),
    );
  }

  String _getAmountSectionTitle() {
    String partyType = controller.partyData['party_type'] ?? 'customer';

    if (partyType == 'customer') {
      return controller.selectedTransactionType.value == 'paune_parne'
          ? 'Amount to Receive'
          : 'Amount Received';
    } else {
      return controller.selectedTransactionType.value == 'paune_parne'
          ? 'Amount to Pay'
          : 'Amount Paid';
    }
  }

  Widget _buildDateCard() {
    return Card(
      color: Colors.white,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.calendar_today,
                    size: 18,
                    color: Color(0xFF64748B),
                  ),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "मिति (नेपाली)",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      "Transaction Date",
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 16),

            // Nepali Date Picker
            _buildNepaliDatePicker(),
          ],
        ),
      ),
    );
  }

  Widget _buildNepaliDatePicker() {
    return InkWell(
      onTap: () => _selectNepaliDate(Get.context!),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_month,
                  color: Color(0xFF64748B),
                  size: 20,
                ),
                SizedBox(width: 12),
                Obx(() => Text(
                      controller.selectedNepaliDate.value.format('yyyy MMMM d'),
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF1E293B),
                      ),
                    )),
              ],
            ),
            Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.keyboard_arrow_down,
                color: Color(0xFF64748B),
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectNepaliDate(BuildContext context) async {
    NepaliDateTime? picked = await showMaterialDatePicker(
      context: context,
      initialDate: controller.selectedNepaliDate.value,
      firstDate: NepaliDateTime(2070), // Nepali year 2070 BS
      lastDate: NepaliDateTime.now().add(Duration(days: 1)),
      initialDatePickerMode: DatePickerMode.day,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: controller.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != controller.selectedNepaliDate.value) {
      controller.updateNepaliDate(picked);
    }
  }

  Widget _buildBottomButton() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Obx(() => ElevatedButton(
              onPressed: controller.isSubmitting.value
                  ? null
                  : () => controller.submitTransaction(),
              style: ElevatedButton.styleFrom(
                backgroundColor: controller.primaryColor,
                disabledBackgroundColor:
                    controller.primaryColor.withOpacity(0.6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
              ),
              child: controller.isSubmitting.value
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Saving...',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'सेभ हुँदैछ...',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getButtonText(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            )),
      ),
    );
  }

  String _getButtonText() {
    String partyType = controller.partyData['party_type'] ?? 'customer';

    if (partyType == 'customer') {
      return controller.selectedTransactionType.value == 'paune_parne'
          ? 'Add Receivable'
          : 'Record Payment';
    } else {
      return controller.selectedTransactionType.value == 'paune_parne'
          ? 'Add Payable'
          : 'Record Payment';
    }
  }
}
