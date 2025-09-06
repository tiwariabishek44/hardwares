import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsService extends GetxService {
  static AppSettingsService get to => Get.find();

  late SharedPreferences _prefs;

  // Settings keys
  static const String _keyFirstLaunch = 'first_launch';
  static const String _keyAutoSync = 'auto_sync';
  static const String _keyOfflineMode = 'offline_mode';
  static const String _keyLastSync = 'last_sync';
  static const String _keyDefaultTaxRate = 'default_tax_rate';
  static const String _keyLanguage = 'language';

  // 🆕 Tutorial keys
  static const String _keyTutorialCompleted = 'tutorial_completed';
  static const String _keyHardwareTutorialSeen = 'hardware_tutorial_seen';
  static const String _keyPartyTutorialSeen = 'party_tutorial_seen';
  static const String _keyBillsTutorialSeen = 'bills_tutorial_seen';
  static const String _keyTransactionTutorialSeen = 'transaction_tutorial_seen';

  // Observable settings
  var isFirstLaunch = true.obs;
  var autoSyncEnabled = true.obs;
  var offlineMode = false.obs;
  var defaultTaxRate = 13.0.obs;
  var selectedLanguage = 'ne'.obs; // 'ne' for Nepali, 'en' for English

  // 🆕 Tutorial observables
  var tutorialCompleted = false.obs;
  var hardwareTutorialSeen = false.obs;
  var partyTutorialSeen = false.obs;
  var billsTutorialSeen = false.obs;
  var transactionTutorialSeen = false.obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initPreferences();
    await _loadSettings();
  }

  // Initialize SharedPreferences
  Future<void> _initPreferences() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Load all settings
  Future<void> _loadSettings() async {
    isFirstLaunch.value = _prefs.getBool(_keyFirstLaunch) ?? true;
    autoSyncEnabled.value = _prefs.getBool(_keyAutoSync) ?? true;
    offlineMode.value = _prefs.getBool(_keyOfflineMode) ?? false;
    defaultTaxRate.value = _prefs.getDouble(_keyDefaultTaxRate) ?? 13.0;
    selectedLanguage.value = _prefs.getString(_keyLanguage) ?? 'ne';

    // 🆕 Load tutorial settings
    tutorialCompleted.value = _prefs.getBool(_keyTutorialCompleted) ?? false;
    hardwareTutorialSeen.value =
        _prefs.getBool(_keyHardwareTutorialSeen) ?? false;
    partyTutorialSeen.value = _prefs.getBool(_keyPartyTutorialSeen) ?? false;
    billsTutorialSeen.value = _prefs.getBool(_keyBillsTutorialSeen) ?? false;
    transactionTutorialSeen.value =
        _prefs.getBool(_keyTransactionTutorialSeen) ?? false;
  }

  // Set first launch completed
  Future<void> setFirstLaunchCompleted() async {
    isFirstLaunch.value = false;
    await _prefs.setBool(_keyFirstLaunch, false);
  }

  // Toggle auto sync
  Future<void> toggleAutoSync(bool value) async {
    autoSyncEnabled.value = value;
    await _prefs.setBool(_keyAutoSync, value);
  }

  // Toggle offline mode
  Future<void> toggleOfflineMode(bool value) async {
    offlineMode.value = value;
    await _prefs.setBool(_keyOfflineMode, value);
  }

  // Set default tax rate
  Future<void> setDefaultTaxRate(double rate) async {
    defaultTaxRate.value = rate;
    await _prefs.setDouble(_keyDefaultTaxRate, rate);
  }

  // Set language
  Future<void> setLanguage(String language) async {
    selectedLanguage.value = language;
    await _prefs.setString(_keyLanguage, language);
  }

  // Update last sync time
  Future<void> updateLastSyncTime() async {
    String currentTime = DateTime.now().toIso8601String();
    await _prefs.setString(_keyLastSync, currentTime);
  }

  // Get last sync time
  String getLastSyncTime() {
    String lastSync = _prefs.getString(_keyLastSync) ?? '';
    if (lastSync.isEmpty) return 'Never';

    try {
      DateTime lastSyncDate = DateTime.parse(lastSync);
      Duration difference = DateTime.now().difference(lastSyncDate);

      if (difference.inMinutes < 1) return 'Just now';
      if (difference.inMinutes < 60)
        return '${difference.inMinutes} minutes ago';
      if (difference.inHours < 24) return '${difference.inHours} hours ago';
      return '${difference.inDays} days ago';
    } catch (e) {
      return 'Unknown';
    }
  }

  // 🆕 Tutorial Management Methods

  // Check if user is first time (needs any tutorial)
  bool isFirstTimeUser() {
    return !tutorialCompleted.value;
  }

  // Mark main tutorial as completed
  Future<void> setTutorialCompleted() async {
    tutorialCompleted.value = true;
    await _prefs.setBool(_keyTutorialCompleted, true);
  }

  // Hardware tutorial methods
  bool shouldShowHardwareTutorial() {
    return !hardwareTutorialSeen.value;
  }

  Future<void> setHardwareTutorialSeen() async {
    hardwareTutorialSeen.value = true;
    await _prefs.setBool(_keyHardwareTutorialSeen, true);
  }

  // Party tutorial methods
  bool shouldShowPartyTutorial() {
    return !partyTutorialSeen.value;
  }

  Future<void> setPartyTutorialSeen() async {
    partyTutorialSeen.value = true;
    await _prefs.setBool(_keyPartyTutorialSeen, true);
  }

  // Bills tutorial methods
  bool shouldShowBillsTutorial() {
    return !billsTutorialSeen.value;
  }

  Future<void> setBillsTutorialSeen() async {
    billsTutorialSeen.value = true;
    await _prefs.setBool(_keyBillsTutorialSeen, true);
  }

  // Transaction tutorial methods
  bool shouldShowTransactionTutorial() {
    return !transactionTutorialSeen.value;
  }

  Future<void> setTransactionTutorialSeen() async {
    transactionTutorialSeen.value = true;
    await _prefs.setBool(_keyTransactionTutorialSeen, true);
  }

  // Reset all tutorials (for testing or user reset)
  Future<void> resetAllTutorials() async {
    tutorialCompleted.value = false;
    hardwareTutorialSeen.value = false;
    partyTutorialSeen.value = false;
    billsTutorialSeen.value = false;
    transactionTutorialSeen.value = false;

    await _prefs.setBool(_keyTutorialCompleted, false);
    await _prefs.setBool(_keyHardwareTutorialSeen, false);
    await _prefs.setBool(_keyPartyTutorialSeen, false);
    await _prefs.setBool(_keyBillsTutorialSeen, false);
    await _prefs.setBool(_keyTransactionTutorialSeen, false);
  }

  // Get tutorial progress (for analytics or settings screen)
  Map<String, bool> getTutorialProgress() {
    return {
      'main_tutorial': tutorialCompleted.value,
      'hardware_tutorial': hardwareTutorialSeen.value,
      'party_tutorial': partyTutorialSeen.value,
      'bills_tutorial': billsTutorialSeen.value,
      'transaction_tutorial': transactionTutorialSeen.value,
    };
  }

  // Check if all tutorials are completed
  bool areAllTutorialsCompleted() {
    return tutorialCompleted.value &&
        hardwareTutorialSeen.value &&
        partyTutorialSeen.value &&
        billsTutorialSeen.value &&
        transactionTutorialSeen.value;
  }

  // Generic method for setting any boolean preference
  Future<void> setBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  // Generic method for getting any boolean preference
  bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  // Generic method for setting any string preference
  Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  // Generic method for getting any string preference
  String? getString(String key) {
    return _prefs.getString(key);
  }

  // Clear all settings (for logout)
  Future<void> clearSettings() async {
    await _prefs.clear();
    await _loadSettings();
  }
}
