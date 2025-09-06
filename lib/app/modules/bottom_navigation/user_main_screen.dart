import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'user_main_screen_controller.dart';

class UserMainScreen extends StatelessWidget {
  const UserMainScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final UserMainScreenController controller =
        Get.put(UserMainScreenController());

    return Scaffold(
      backgroundColor: Color(0xFFFAFAFA),
      body: Obx(() => SafeArea(
            child: PageStorage(
              bucket: controller.bucket,
              child: controller.currentScreen,
            ),
          )),

      // Professional Bottom Navigation Bar with 4 tabs
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: Colors.grey[200]!,
              width: 0.5,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Obx(() => Container(
                height: 70,
                child: BottomNavigationBar(
                  currentIndex: controller.currentIndex.value,
                  onTap: (index) => controller.changeTabIndex(index),
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: Colors.transparent,
                  selectedItemColor: Color(0xFF2563EB),
                  unselectedItemColor: Color(0xFF6B7280),
                  selectedLabelStyle: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                  elevation: 0,
                  showSelectedLabels: true,
                  showUnselectedLabels: true,
                  items: [
                    BottomNavigationBarItem(
                      icon: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: controller.currentIndex.value == 0
                              ? Color(0xFF2563EB).withOpacity(0.08)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          controller.currentIndex.value == 0
                              ? Icons.home_rounded
                              : Icons.home_outlined,
                          size: 22,
                        ),
                      ),
                      label: 'Home',
                    ),
                    BottomNavigationBarItem(
                      icon: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: controller.currentIndex.value == 1
                              ? Color(0xFF2563EB).withOpacity(0.08)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          controller.currentIndex.value == 1
                              ? Icons.receipt_long_rounded
                              : Icons.receipt_long_outlined,
                          size: 22,
                        ),
                      ),
                      label: 'Bills',
                    ),
                    BottomNavigationBarItem(
                      icon: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: controller.currentIndex.value == 2
                              ? Color(0xFF2563EB).withOpacity(0.08)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          controller.currentIndex.value == 2
                              ? Icons.people_rounded
                              : Icons.people_outlined,
                          size: 22,
                        ),
                      ),
                      label: 'Party',
                    ),
                    BottomNavigationBarItem(
                      icon: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: controller.currentIndex.value == 3
                              ? Color(0xFF2563EB).withOpacity(0.08)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          controller.currentIndex.value == 3
                              ? Icons.settings_rounded
                              : Icons.settings_outlined,
                          size: 22,
                        ),
                      ),
                      label: 'Settings',
                    ),
                  ],
                ),
              )),
        ),
      ),
    );
  }
}
