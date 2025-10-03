import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'hardware_orders.db');
    return await openDatabase(
      path,
      version: 5,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create orders table
    await db.execute('''
      CREATE TABLE orders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bill_code TEXT UNIQUE NOT NULL,
        customer_name TEXT NOT NULL,
        phone_number TEXT NOT NULL,
        plumber_name TEXT NOT NULL,
        plumber_id TEXT NOT NULL,
        items TEXT NOT NULL,
        total_amount REAL DEFAULT 0.0,
        total_items INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        firebase_id TEXT
      )
    ''');

    // Create parties table
    await db.execute('''
      CREATE TABLE parties(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        balance REAL DEFAULT 0.0,
        party_type TEXT DEFAULT 'customer',
        address TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        synced INTEGER DEFAULT 0
      )
    ''');

    // Create transactions table
    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        party_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        transaction_type TEXT NOT NULL,
        description TEXT,
        date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (party_id) REFERENCES parties (id)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add bill_code column if upgrading from version 1
      await db.execute('ALTER TABLE orders ADD COLUMN bill_code TEXT');

      // Update existing orders with generated bill codes
      List<Map<String, dynamic>> existingOrders = await db.query('orders');
      for (var order in existingOrders) {
        if (order['bill_code'] == null) {
          String billCode = await _generateBillCode(db);
          await db.update(
            'orders',
            {'bill_code': billCode},
            where: 'id = ?',
            whereArgs: [order['id']],
          );
        }
      }
    }

    if (oldVersion < 3) {
      // Create parties table for version 3
      await db.execute('''
        CREATE TABLE IF NOT EXISTS parties(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          phone TEXT NOT NULL,
          balance REAL DEFAULT 0.0,
          party_type TEXT DEFAULT 'customer',
          address TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          synced INTEGER DEFAULT 0
        )
      ''');
    }

    if (oldVersion < 4) {
      // Create transactions table for version 4
      await db.execute('''
        CREATE TABLE IF NOT EXISTS transactions(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          party_id INTEGER NOT NULL,
          amount REAL NOT NULL,
          transaction_type TEXT NOT NULL,
          description TEXT,
          date TEXT NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY (party_id) REFERENCES parties (id)
        )
      ''');
    }

    if (oldVersion < 5) {
      // Add synced column to transactions table
      try {
        await db.execute(
            'ALTER TABLE transactions ADD COLUMN synced INTEGER DEFAULT 0');
        await db.execute('ALTER TABLE transactions ADD COLUMN synced_at TEXT');
      } catch (e) {
        developer.log('Error adding synced columns to transactions: $e');
      }
    }
  }

  // ===== PARTY MANAGEMENT METHODS =====

  Future<int> insertParty({
    required String name,
    required String phone,
    double balance = 0.0,
    String partyType = 'customer',
    String? address,
  }) async {
    final db = await database;

    try {
      // Check if party with same phone already exists
      List<Map<String, dynamic>> existingParty = await db.query(
        'parties',
        where: 'phone = ?',
        whereArgs: [phone],
      );

      if (existingParty.isNotEmpty) {
        throw Exception('Party with phone number $phone already exists');
      }

      Map<String, dynamic> party = {
        'name': name.trim(),
        'phone': phone.trim(),
        'balance': balance,
        'party_type': partyType,
        'address': address?.trim(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'synced': 0, // Keep this
        // Remove this line: 'synced_at': null,
      };

      int id = await db.insert('parties', party);
      return id;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllParties() async {
    final db = await database;

    try {
      List<Map<String, dynamic>> parties = await db.query(
        'parties',
        orderBy: 'name ASC',
      );

      return parties;
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getPartyById(int partyId) async {
    final db = await database;

    try {
      List<Map<String, dynamic>> parties = await db.query(
        'parties',
        where: 'id = ?',
        whereArgs: [partyId],
      );

      if (parties.isNotEmpty) {
        return parties.first;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getPartyByPhone(String phone) async {
    final db = await database;

    try {
      List<Map<String, dynamic>> parties = await db.query(
        'parties',
        where: 'phone = ?',
        whereArgs: [phone],
      );

      if (parties.isNotEmpty) {
        return parties.first;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<void> updateParty({
    required int partyId,
    String? name,
    String? phone,
    double? balance,
    String? partyType,
    String? address,
  }) async {
    final db = await database;

    try {
      Map<String, dynamic> updates = {
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null) updates['name'] = name.trim();
      if (phone != null) updates['phone'] = phone.trim();
      if (balance != null) updates['balance'] = balance;
      if (partyType != null) updates['party_type'] = partyType;
      if (address != null) updates['address'] = address.trim();

      int result = await db.update(
        'parties',
        updates,
        where: 'id = ?',
        whereArgs: [partyId],
      );

      if (result > 0) {
      } else {}
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updatePartyBalance(int partyId, double newBalance) async {
    final db = await database;

    try {
      int result = await db.update(
        'parties',
        {
          'balance': newBalance,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [partyId],
      );

      if (result > 0) {
      } else {}
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteParty(int partyId) async {
    final db = await database;

    try {
      int result = await db.delete(
        'parties',
        where: 'id = ?',
        whereArgs: [partyId],
      );

      if (result > 0) {
      } else {}
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getPartiesByType(String partyType) async {
    final db = await database;

    try {
      List<Map<String, dynamic>> parties = await db.query(
        'parties',
        where: 'party_type = ?',
        whereArgs: [partyType],
        orderBy: 'name ASC',
      );

      return parties;
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> searchParties(String searchTerm) async {
    final db = await database;

    try {
      List<Map<String, dynamic>> parties = await db.query(
        'parties',
        where: 'name LIKE ? OR phone LIKE ?',
        whereArgs: ['%$searchTerm%', '%$searchTerm%'],
        orderBy: 'name ASC',
      );

      return parties;
    } catch (e) {
      return [];
    }
  }

  // ===== ORDER METHODS =====

  Future<String> _generateBillCode(Database db) async {
    String billCode;
    bool isUnique = false;
    int attempts = 0;
    Random random = Random();

    const String numbers = '0123456789';
    const String lowercase = 'abcdefghijklmnopqrstuvwxyz';
    const String allChars = numbers + lowercase;

    do {
      attempts++;
      List<String> codeChars = [];
      codeChars.add(numbers[random.nextInt(numbers.length)]);
      codeChars.add(lowercase[random.nextInt(lowercase.length)]);
      for (int i = 0; i < 2; i++) {
        codeChars.add(allChars[random.nextInt(allChars.length)]);
      }
      codeChars.shuffle(random);
      billCode = codeChars.join('');

      List<Map<String, dynamic>> existing = await db.query(
        'orders',
        where: 'bill_code = ?',
        whereArgs: [billCode],
      );
      isUnique = existing.isEmpty;

      if (attempts > 50) {
        String fallbackCode = '';
        for (int i = 0; i < 4; i++) {
          fallbackCode += allChars[random.nextInt(allChars.length)];
        }
        billCode = fallbackCode;
        break;
      }
    } while (!isUnique);

    return billCode;
  }

  // FIXED: Updated insertOrder method - returns bill_code directly instead of trying to query again
  Future<String> insertOrder({
    required String customerName,
    required String phoneNumber,
    required String plumberName,
    required String plumberId,
    required List<Map<String, dynamic>> items,
  }) async {
    final db = await database;

    // Generate bill code when creating order
    String billCode = await _generateBillCode(db);

    // Calculate totals using the new data model fields
    double totalAmount = 0.0;
    int totalItems = items.length;

    for (var item in items) {
      // Use 'rate' field from the new data model
      double rate = (item['rate'] ?? 0.0) as double;
      int quantity = (item['quantity'] ?? 1) as int;
      totalAmount += rate * quantity;
    }

    // Convert items to proper format for database storage - INCLUDING subType and subVariant
    List<Map<String, dynamic>> processedItems = items.map((item) {
      return {
        'uniqueKey': item['uniqueKey'] ?? '',
        'itemCode': item['itemCode'] ?? '',
        'itemName': item['itemName'] ?? '',
        'category': item['category'] ?? '',
        'companyName': item['companyName'] ?? '',
        'imageUrl': item['imageUrl'] ?? '',
        'isCompanyItems': item['isCompanyItems'] ?? false,
        'subType': item['subType'] ?? '', // Added subType
        'subVariant': item['subVariant'] ?? '', // Added subVariant for pipes
        'selectedVariantType': item['selectedVariantType'] ?? '',
        'selectedSize': item['selectedSize'] ?? '',
        'rate': item['rate'] ?? 0.0,
        'unit': item['unit'] ?? 'pic',
        'quantity': item['quantity'] ?? 1,
        'dateAdded': item['dateAdded'] ?? DateTime.now().toIso8601String(),
      };
    }).toList();

    Map<String, dynamic> order = {
      'bill_code': billCode,
      'customer_name': customerName,
      'phone_number': phoneNumber,
      'plumber_name': plumberName,
      'plumber_id': plumberId,
      'items': jsonEncode(
          processedItems), // Store processed items with subType and subVariant
      'total_amount': totalAmount,
      'total_items': totalItems,
      'created_at': DateTime.now().toIso8601String(),
      'synced': 0,
    };

    try {
      int id = await db.insert('orders', order);
      developer
          .log('✅ Order inserted to SQLite with ID: $id, Bill Code: $billCode');
      developer.log('📦 Items saved with subType and subVariant fields');
      // Return the bill code directly instead of querying again
      return billCode;
    } catch (e) {
      developer.log('❌ Error inserting order to SQLite: $e');
      rethrow;
    }
  }

  // FIXED: Safer getOrderById method
  Future<Map<String, dynamic>?> getOrderById(int orderId) async {
    final db = await database;
    try {
      List<Map<String, dynamic>> orders = await db.query(
        'orders',
        where: 'id = ?',
        whereArgs: [orderId],
      );

      if (orders.isNotEmpty) {
        var order =
            Map<String, dynamic>.from(orders.first); // Create a mutable copy
        // Parse items JSON back to List
        if (order['items'] != null && order['items'] is String) {
          try {
            order['items'] = jsonDecode(order['items']);
          } catch (e) {
            developer.log('⚠️ Error parsing items JSON: $e');
            order['items'] = [];
          }
        }
        return order;
      } else {
        developer.log('⚠️ Order with ID $orderId not found');
        return null;
      }
    } catch (e) {
      developer.log('❌ Error getting order by ID: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getAllOrders() async {
    final db = await database;
    try {
      List<Map<String, dynamic>> orders = await db.query(
        'orders',
        orderBy: 'created_at DESC',
      );

      // Parse items JSON for each order
      for (var order in orders) {
        if (order['items'] != null && order['items'] is String) {
          try {
            order['items'] = jsonDecode(order['items']);
          } catch (e) {
            order['items'] = [];
          }
        }
      }

      return orders;
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getUnsyncedOrders() async {
    final db = await database;
    try {
      List<Map<String, dynamic>> orders = await db.query(
        'orders',
        where: 'synced = ?',
        whereArgs: [0],
        orderBy: 'created_at DESC',
      );

      // Parse items JSON for each order
      for (var order in orders) {
        if (order['items'] != null && order['items'] is String) {
          try {
            order['items'] = jsonDecode(order['items']);
          } catch (e) {
            order['items'] = [];
          }
        }
      }

      return orders;
    } catch (e) {
      return [];
    }
  }

  Future<void> markOrderAsSynced(int orderId) async {
    final db = await database;
    try {
      await db.update(
        'orders',
        {'synced': 1},
        where: 'id = ?',
        whereArgs: [orderId],
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteOrder(int orderId) async {
    final db = await database;
    try {
      await db.delete(
        'orders',
        where: 'id = ?',
        whereArgs: [orderId],
      );
    } catch (e) {
      rethrow;
    }
  }

  // ===== TRANSACTION MANAGEMENT METHODS =====
  Future<int> insertTransaction({
    required int partyId,
    required double amount,
    required String transactionType,
    String? description,
    String? date,
  }) async {
    final db = await database;
    try {
      Map<String, dynamic> transaction = {
        'party_id': partyId,
        'amount': amount,
        'transaction_type': transactionType,
        'description': description,
        'date': date ?? DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        // Remove these lines since columns don't exist in current schema:
        // 'synced': 0,
        // 'synced_at': null,
      };

      int transactionId = await db.insert('transactions', transaction);

      // Update party balance
      Map<String, dynamic>? party = await getPartyById(partyId);
      if (party != null) {
        double currentBalance =
            double.tryParse(party['balance']?.toString() ?? '0') ?? 0.0;
        double newBalance;

        if (transactionType == 'paune_parne') {
          newBalance = currentBalance + amount;
        } else if (transactionType == 'rakam_prapta') {
          newBalance = currentBalance - amount;
        } else {
          newBalance = currentBalance;
        }

        await updatePartyBalance(partyId, newBalance);
      }

      return transactionId;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getTransactionsByPartyId(
      int partyId) async {
    final db = await database;
    try {
      List<Map<String, dynamic>> transactions = await db.query(
        'transactions',
        where: 'party_id = ?',
        whereArgs: [partyId],
        orderBy: 'date DESC',
      );
      return transactions;
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllTransactions() async {
    final db = await database;
    try {
      List<Map<String, dynamic>> transactions = await db.query(
        'transactions',
        orderBy: 'date DESC',
      );
      return transactions;
    } catch (e) {
      return [];
    }
  }

  Future<void> deleteTransaction(int transactionId) async {
    final db = await database;
    try {
      List<Map<String, dynamic>> transactionData = await db.query(
        'transactions',
        where: 'id = ?',
        whereArgs: [transactionId],
      );

      if (transactionData.isNotEmpty) {
        var transaction = transactionData.first;
        int partyId = transaction['party_id'];
        double amount =
            double.tryParse(transaction['amount']?.toString() ?? '0') ?? 0.0;
        String transactionType = transaction['transaction_type'];

        Map<String, dynamic>? party = await getPartyById(partyId);
        if (party != null) {
          double currentBalance =
              double.tryParse(party['balance']?.toString() ?? '0') ?? 0.0;
          double newBalance;

          if (transactionType == 'paune_parne') {
            newBalance = currentBalance - amount;
          } else if (transactionType == 'rakam_prapta') {
            newBalance = currentBalance + amount;
          } else {
            newBalance = currentBalance;
          }

          await updatePartyBalance(partyId, newBalance);
        }

        await db.delete(
          'transactions',
          where: 'id = ?',
          whereArgs: [transactionId],
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Updated insertOrderFromSync method for new data model - INCLUDING subType and subVariant
  Future<int> insertOrderFromSync(Map<String, dynamic> orderData) async {
    final db = await database;
    try {
      List<Map<String, dynamic>> existingOrders = await db.query(
        'orders',
        where: 'bill_code = ?',
        whereArgs: [orderData['bill_code']],
      );

      if (existingOrders.isNotEmpty) {
        return -1;
      }

      // Ensure items are properly encoded if they're not already
      if (orderData['items'] is List) {
        // Process items to ensure subType and subVariant are included
        List<Map<String, dynamic>> processedItems =
            (orderData['items'] as List).map((item) {
          Map<String, dynamic> processedItem = Map<String, dynamic>.from(item);
          // Ensure subType and subVariant are preserved
          processedItem['subType'] = item['subType'] ?? '';
          processedItem['subVariant'] = item['subVariant'] ?? '';
          return processedItem;
        }).toList();

        orderData['items'] = jsonEncode(processedItems);
      }

      int id = await db.insert('orders', orderData);
      developer.log(
          '✅ Order synced from external source with subType and subVariant preserved');
      return id;
    } catch (e) {
      rethrow;
    }
  }

  // Get unsynced parties
  Future<List<Map<String, dynamic>>> getUnsyncedParties() async {
    final db = await database;
    try {
      List<Map<String, dynamic>> parties = await db.query(
        'parties',
        where: 'synced = ?',
        whereArgs: [0],
        orderBy: 'created_at DESC',
      );
      return parties;
    } catch (e) {
      return [];
    }
  }

  // Get all transactions (since they don't have synced column)
  Future<List<Map<String, dynamic>>> getUnsyncedTransactions() async {
    final db = await database;
    try {
      // Return all transactions since we can't track sync status
      return await db.query(
        'transactions',
        orderBy: 'created_at DESC',
      );
    } catch (e) {
      return [];
    }
  }

  // Mark party as synced
  Future<void> markPartyAsSynced(int partyId) async {
    final db = await database;
    await db.update(
      'parties',
      {
        'synced': 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [partyId],
    );
  }
}
