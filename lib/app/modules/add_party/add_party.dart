import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hardwares/app/modules/add_party/add_party_controller.dart';

class AddPartyView extends StatelessWidget {
  AddPartyView({Key? key}) : super(key: key);
  final controller = Get.put(AddPartyController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: _buildAppBar(context),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPartyTypeSelector(),
                    SizedBox(height: 20),
                    _buildPartyForm(),
                    SizedBox(height: 16),
                    _buildOpeningBalanceCard(),
                  ],
                ),
              ),
            ),
            _buildBottomSubmitBar(context),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Obx(() => Text(
            'Add New ${controller.partyType}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF212121),
            ),
          )),
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF212121),
      elevation: 0.5,
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Color(0xFF212121), size: 22),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildPartyTypeSelector() {
    return Card(
      color: Colors.white,
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Obx(() => Row(
              children: [
                _buildTypeButton(
                  title: 'Customer',
                  icon: Icons.person_outline,
                  isSelected: !controller.isSupplier.value,
                  onTap: () => controller.isSupplier.value = false,
                ),
                _buildTypeButton(
                  title: 'Supplier',
                  icon: Icons.inventory_2_outlined,
                  isSelected: controller.isSupplier.value,
                  onTap: () => controller.isSupplier.value = true,
                ),
              ],
            )),
      ),
    );
  }

  Widget _buildTypeButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required Function() onTap,
  }) {
    return Expanded(
      child: Material(
        color: isSelected ? Color(0xFF1976D2) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.white : Colors.grey[600],
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[600],
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOpeningBalanceCard() {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Form Header
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Color(0xFF1976D2),
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Opening Balance',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF212121),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6),
            Divider(),
            SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: controller.openingBalanceController,
                        keyboardType:
                            TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF212121),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter amount (optional)',
                          hintStyle: TextStyle(
                            color: const Color.fromARGB(255, 96, 96, 96),
                          ),
                          prefixIcon: Container(
                            width: 40,
                            child: Center(
                              child: Text(
                                'Rs.',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                BorderSide(color: Colors.grey[300]!, width: 1),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                BorderSide(color: Colors.grey[300]!, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                                color: Color(0xFF1976D2), width: 1.5),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Updated note text with new Nepali instructions
            Obx(() => Text(
                  controller.isSupplier.value
                      ? 'नोट: कुनै पनि पुरानो तिर्नु पर्ने रकम छ भने opening balance मा लेख्नुहोला'
                      : 'नोट: कुनै पनि पुरानो लिनु पर्ने रकम छ भने opening balance मा लेख्नुहोला',
                  style: TextStyle(
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                    color: const Color.fromARGB(255, 45, 44, 44),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildPartyForm() {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Form Header
              Obx(() => Row(
                    children: [
                      Icon(
                        controller.partyIcon,
                        color: Color(0xFF1976D2),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '${controller.partyType} Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF212121),
                        ),
                      ),
                    ],
                  )),
              SizedBox(height: 6),
              Divider(),
              SizedBox(height: 16),

              // Party Name Field
              Obx(() => _buildTextField(
                    controller: controller.partyNameController,
                    label: '${controller.partyType} Name *',
                    hint: 'Enter name',
                    icon: controller.partyIcon,
                    validator: controller.validateName,
                    textCapitalization: TextCapitalization.words,
                  )),

              SizedBox(height: 18),

              // Phone Number Field
              _buildTextField(
                controller: controller.phoneNumberController,
                label: 'Phone Number *',
                hint: 'Enter 10-digit phone number',
                icon: Icons.phone,
                validator: controller.validatePhone,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: const Color.fromARGB(255, 36, 36, 36),
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          textCapitalization: textCapitalization,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: TextStyle(
            fontSize: 15,
            color: Color(0xFF212121),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: const Color.fromARGB(255, 96, 96, 96),
            ),
            prefixIcon: Icon(
              icon,
              color: Colors.grey[600],
              size: 20,
            ),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(0xFF1976D2), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red[400]!, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red[400]!, width: 1.5),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            errorStyle: TextStyle(
              color: Colors.red[700],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSubmitBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(Get.context!),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                  side: BorderSide(color: Colors.grey[300]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Obx(() => ElevatedButton(
                    onPressed: () {
                      if (!controller.isSubmitting.value) {
                        FocusScope.of(context).unfocus();
                        controller.submitParty();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF1976D2),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.blue[100],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    child: controller.isSubmitting.value
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Saving...',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.save,
                                size: 20,
                                color: Colors.white,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Save ${controller.partyType}',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                  )),
            ),
          ],
        ),
      ),
    );
  }
}
