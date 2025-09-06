import 'package:get/get.dart';
import 'selecte_items_controller.dart';

class SavedItemsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SelectedItemsController>(
      () => SelectedItemsController(),
    );
  }
}
