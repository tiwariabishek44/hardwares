import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hardwares/app/modules/bills/bills_view.dart';
import 'package:hardwares/app/modules/hardware_catlouge/hardware_catlouge_view.dart';
import 'package:hardwares/app/modules/transaction/transaction_view.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../login/login_controller.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final LoginController loginController = Get.find<LoginController>();

    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Obx(() => Column(
                    children: [
                      // Profile Avatar
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Color(0xFF1976D2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            loginController.getUserName().isNotEmpty
                                ? loginController.getUserName()[0].toUpperCase()
                                : 'P',
                            style: TextStyle(
                              fontSize: 36.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 16),

                      // Name
                      Text(
                        loginController.getUserName(),
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF212121),
                        ),
                      ),

                      SizedBox(height: 4),

                      // Phone
                      Text(
                        '+977 ${loginController.getUserPhone()}',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Color(0xFF757575),
                        ),
                      ),

                      SizedBox(height: 8),

                      // Professional Badge
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Color(0xFF1976D2).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Hardware Professional',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1976D2),
                          ),
                        ),
                      ),
                    ],
                  )),
            ),

            SizedBox(height: 32),

            // Menu Items
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Profile Info
                    _buildMenuItem(
                      icon: Icons.person,
                      title: 'Profile Information',
                      onTap: () => _showProfileInfo(context, loginController),
                    ),

                    SizedBox(height: 16),

                    // About Us
                    _buildMenuItem(
                      icon: Icons.info,
                      title: 'About Us',
                      onTap: () => _showAbout(context),
                    ),

                    SizedBox(height: 32),

                    // Logout Button
                    Container(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _showLogoutDialog(context, loginController),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFE53E3E),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                        ),
                        icon: Icon(Icons.logout, size: 20),
                        label: Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    Spacer(),

                    // App Version
                    Text(
                      'Hardware App v1.0.0',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Color(0xFF9E9E9E),
                      ),
                    ),

                    SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Color(0xFF1976D2).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: Color(0xFF1976D2),
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Color(0xFF212121),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Color(0xFFBDBDBD),
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }

  void _showProfileInfo(BuildContext context, LoginController controller) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: EdgeInsets.all(24),
        title: Text(
          'Profile Information',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: Color(0xFF212121),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildInfoItem('Name', controller.getUserName()),
            _buildInfoItem('Phone', '+977 ${controller.getUserPhone()}'),
            _buildInfoItem('Address', controller.getUserAddress()),
            _buildInfoItem('Date of Birth', controller.getDateOfBirth()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'Close',
              style: TextStyle(
                color: Color(0xFF1976D2),
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                color: Color(0xFF757575),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value.isNotEmpty ? value : 'Not provided',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Color(0xFF212121),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: EdgeInsets.all(24),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Color(0xFF1976D2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.hardware,
                color: Colors.white,
                size: 24,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Hardware App',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: Color(0xFF212121),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version 1.0.0',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1976D2),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'A comprehensive digital solution for hardware professionals to manage inventory, create bills, track parties, and handle transactions efficiently.',
              style: TextStyle(
                fontSize: 14.sp,
                color: Color(0xFF616161),
                height: 1.5,
              ),
            ),
            SizedBox(height: 16),
            Text(
              '© 2024 Hardware Solutions',
              style: TextStyle(
                fontSize: 12.sp,
                color: Color(0xFF9E9E9E),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'OK',
              style: TextStyle(
                color: Color(0xFF1976D2),
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, LoginController controller) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: EdgeInsets.all(24),
        title: Text(
          'Logout',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: Color(0xFF212121),
          ),
        ),
        content: Text(
          'Are you sure you want to logout from your account?',
          style: TextStyle(
            fontSize: 16.sp,
            color: Color(0xFF616161),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFF757575),
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              controller.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFE53E3E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              elevation: 0,
            ),
            child: Text(
              'Logout',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class UserMainScreenController extends GetxController {
  // Current tab index
  var currentIndex = 0.obs;

  // Page storage bucket for maintaining scroll position
  PageStorageBucket bucket = PageStorageBucket();

  // List of pages - Updated with 4 tabs
  List<Widget> pages = [
    HardwareCatalogView(),
    BillsView(),
    TransactionView(),
    ProfileView(), // Settings/Profile tab
  ];

  // Current screen getter
  Widget get currentScreen => pages[currentIndex.value];

  // Change tab index
  void changeTabIndex(int index) {
    if (index >= 0 && index < pages.length) {
      currentIndex.value = index;
    }
  }
}
