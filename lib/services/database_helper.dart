import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';

import '../models/admin.dart';
import '../models/app_notification.dart';
import '../models/feedback_entry.dart';
import '../models/item.dart';
import '../models/promotion.dart';
import '../models/redeemed_voucher.dart';
import '../models/shop.dart';
import '../models/user.dart';
import '../models/voucher.dart';

class DatabaseHelper {
  DatabaseHelper._internal();

  static final DatabaseHelper instance = DatabaseHelper._internal();

  static const _databaseName = 'dvoucher.db';
  static const _databaseVersion = 13;

  static const usersTable = 'users';
  static const adminsTable = 'admins';
  static const shopsTable = 'shops';
  static const vouchersTable = 'vouchers';
  static const redeemedTable = 'redeemed';
  static const feedbackTable = 'feedback';
  static const promotionsTable = 'promotions';
  static const voucherImagesTable = 'voucher_images';
  static const promotionImagesTable = 'promotion_images';
  static const promotionVouchersTable = 'promotion_vouchers';
  static const itemsTable = 'items';
  static const favoriteVouchersTable = 'favorite_vouchers';
  static const notificationsTable = 'notifications';
  static const promotionLikesTable = 'promotion_likes';
  static const promotionCommentsTable = 'promotion_comments';

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $usersTable (
        user_id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        notifications_enabled INTEGER NOT NULL DEFAULT 1,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE $adminsTable (
        admin_id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $shopsTable (
        shop_id INTEGER PRIMARY KEY AUTOINCREMENT,
        admin_id INTEGER NOT NULL,
        shop_name TEXT NOT NULL,
        shop_address TEXT NOT NULL,
        contact_number TEXT NOT NULL,
        logo_path TEXT,
        FOREIGN KEY(admin_id) REFERENCES $adminsTable(admin_id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE $vouchersTable (
        voucher_id INTEGER PRIMARY KEY AUTOINCREMENT,
        admin_id INTEGER NOT NULL,
        shop_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        code TEXT NOT NULL UNIQUE,
        original_price REAL NOT NULL,
        discount_value REAL NOT NULL,
        discount_type TEXT NOT NULL DEFAULT 'percentage',
        discounted_price REAL NOT NULL,
        expiry_date TEXT NOT NULL,
        usage_limit INTEGER NOT NULL,
        shop_name TEXT NOT NULL,
        shop_address TEXT NOT NULL,
        image_path TEXT,
        item_id INTEGER,
        contact_name TEXT,
        contact_phone TEXT,
        status TEXT NOT NULL,
        FOREIGN KEY(admin_id) REFERENCES $adminsTable(admin_id) ON DELETE CASCADE,
        FOREIGN KEY(shop_id) REFERENCES $shopsTable(shop_id) ON DELETE CASCADE,
        FOREIGN KEY(item_id) REFERENCES $itemsTable(item_id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $redeemedTable (
        redeem_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        voucher_id INTEGER NOT NULL,
        date_redeemed TEXT NOT NULL,
        redeem_status TEXT NOT NULL DEFAULT 'Pending',
        redeem_note TEXT,
        redeemed_by TEXT,
        FOREIGN KEY(user_id) REFERENCES $usersTable(user_id) ON DELETE CASCADE,
        FOREIGN KEY(voucher_id) REFERENCES $vouchersTable(voucher_id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE $feedbackTable (
        feedback_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        voucher_id INTEGER NOT NULL,
        rating INTEGER NOT NULL,
        comment TEXT NOT NULL,
        date TEXT NOT NULL,
        FOREIGN KEY(user_id) REFERENCES $usersTable(user_id) ON DELETE CASCADE,
        FOREIGN KEY(voucher_id) REFERENCES $vouchersTable(voucher_id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE $promotionsTable (
        promotion_id INTEGER PRIMARY KEY AUTOINCREMENT,
        admin_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        shop_name TEXT NOT NULL,
        shop_address TEXT NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        image_path TEXT,
        created_at TEXT NOT NULL,
        contact_name TEXT,
        contact_phone TEXT,
        show_on_home INTEGER NOT NULL DEFAULT 1,
        show_on_vouchers INTEGER NOT NULL DEFAULT 0,
        impressions INTEGER NOT NULL DEFAULT 0,
        clicks INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY(admin_id) REFERENCES $adminsTable(admin_id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE $voucherImagesTable (
        voucher_image_id INTEGER PRIMARY KEY AUTOINCREMENT,
        voucher_id INTEGER NOT NULL,
        image_path TEXT NOT NULL,
        FOREIGN KEY(voucher_id) REFERENCES $vouchersTable(voucher_id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE $promotionImagesTable (
        promotion_image_id INTEGER PRIMARY KEY AUTOINCREMENT,
        promotion_id INTEGER NOT NULL,
        image_path TEXT NOT NULL,
        FOREIGN KEY(promotion_id) REFERENCES $promotionsTable(promotion_id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE $favoriteVouchersTable (
        favorite_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        voucher_id INTEGER NOT NULL,
        added_at TEXT NOT NULL,
        UNIQUE(user_id, voucher_id),
        FOREIGN KEY(user_id) REFERENCES $usersTable(user_id) ON DELETE CASCADE,
        FOREIGN KEY(voucher_id) REFERENCES $vouchersTable(voucher_id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE $notificationsTable (
        notification_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        type TEXT,
        created_at TEXT NOT NULL,
        is_read INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY(user_id) REFERENCES $usersTable(user_id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE $itemsTable (
        item_id INTEGER PRIMARY KEY AUTOINCREMENT,
        admin_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        category TEXT,
        original_price REAL NOT NULL,
        discounted_price REAL NOT NULL,
        image_path TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY(admin_id) REFERENCES $adminsTable(admin_id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE $promotionVouchersTable (
        promotion_voucher_id INTEGER PRIMARY KEY AUTOINCREMENT,
        promotion_id INTEGER NOT NULL,
        voucher_id INTEGER NOT NULL,
        FOREIGN KEY(promotion_id) REFERENCES $promotionsTable(promotion_id) ON DELETE CASCADE,
        FOREIGN KEY(voucher_id) REFERENCES $vouchersTable(voucher_id) ON DELETE CASCADE,
        UNIQUE(promotion_id, voucher_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE $promotionLikesTable (
        like_id INTEGER PRIMARY KEY AUTOINCREMENT,
        promotion_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        is_like INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        UNIQUE(promotion_id, user_id),
        FOREIGN KEY(promotion_id) REFERENCES $promotionsTable(promotion_id) ON DELETE CASCADE,
        FOREIGN KEY(user_id) REFERENCES $usersTable(user_id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE $promotionCommentsTable (
        comment_id INTEGER PRIMARY KEY AUTOINCREMENT,
        promotion_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        comment TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY(promotion_id) REFERENCES $promotionsTable(promotion_id) ON DELETE CASCADE,
        FOREIGN KEY(user_id) REFERENCES $usersTable(user_id) ON DELETE CASCADE
      )
    ''');

    // Seed a default admin account for first-time use
    await db.insert(
      adminsTable,
      {
        'name': 'Admin',
        'email': 'kh@gmail.com',
        'password': '123456',
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 5) {
      await db.execute('PRAGMA foreign_keys = OFF');
      await db.execute('DROP TABLE IF EXISTS $feedbackTable');
      await db.execute('DROP TABLE IF EXISTS $redeemedTable');
      await db.execute('DROP TABLE IF EXISTS $vouchersTable');
      await db.execute('DROP TABLE IF EXISTS $shopsTable');
      await db.execute('DROP TABLE IF EXISTS $adminsTable');
      await db.execute('DROP TABLE IF EXISTS $usersTable');
      await db.execute('DROP TABLE IF EXISTS $promotionsTable');
      await db.execute('DROP TABLE IF EXISTS $promotionImagesTable');
      await db.execute('DROP TABLE IF EXISTS $voucherImagesTable');
      await db.execute('PRAGMA foreign_keys = ON');
      await _onCreate(db, newVersion);
      return;
    }

    if (oldVersion < 6) {
      await db.execute('PRAGMA foreign_keys = OFF');
      await db.execute('DROP TABLE IF EXISTS $promotionsTable');
      await db.execute('DROP TABLE IF EXISTS $promotionImagesTable');
      await db.execute('PRAGMA foreign_keys = ON');
      await db.execute('''
        CREATE TABLE $promotionsTable (
          promotion_id INTEGER PRIMARY KEY AUTOINCREMENT,
          admin_id INTEGER NOT NULL,
          title TEXT NOT NULL,
          description TEXT NOT NULL,
          shop_name TEXT NOT NULL,
          shop_address TEXT NOT NULL,
          start_date TEXT NOT NULL,
          end_date TEXT NOT NULL,
          image_path TEXT,
          created_at TEXT NOT NULL,
          contact_name TEXT,
          contact_phone TEXT,
          FOREIGN KEY(admin_id) REFERENCES $adminsTable(admin_id) ON DELETE CASCADE
        )
      ''');
      await db.execute('''
        CREATE TABLE $promotionImagesTable (
          promotion_image_id INTEGER PRIMARY KEY AUTOINCREMENT,
          promotion_id INTEGER NOT NULL,
          image_path TEXT NOT NULL,
          FOREIGN KEY(promotion_id) REFERENCES $promotionsTable(promotion_id) ON DELETE CASCADE
        )
      ''');
    }

    if (oldVersion >= 6 && oldVersion < 7) {
      await db.execute(
        "ALTER TABLE $vouchersTable ADD COLUMN contact_name TEXT",
      );
      await db.execute(
        "ALTER TABLE $vouchersTable ADD COLUMN contact_phone TEXT",
      );
      await db.execute(
        "ALTER TABLE $promotionsTable ADD COLUMN contact_name TEXT",
      );
      await db.execute(
        "ALTER TABLE $promotionsTable ADD COLUMN contact_phone TEXT",
      );
    }

    if (oldVersion < 8) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $voucherImagesTable (
          voucher_image_id INTEGER PRIMARY KEY AUTOINCREMENT,
          voucher_id INTEGER NOT NULL,
          image_path TEXT NOT NULL,
          FOREIGN KEY(voucher_id) REFERENCES $vouchersTable(voucher_id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS $promotionImagesTable (
          promotion_image_id INTEGER PRIMARY KEY AUTOINCREMENT,
          promotion_id INTEGER NOT NULL,
          image_path TEXT NOT NULL,
          FOREIGN KEY(promotion_id) REFERENCES $promotionsTable(promotion_id) ON DELETE CASCADE
        )
      ''');
    }

    if (oldVersion < 9) {
      await db.execute(
        "ALTER TABLE $usersTable ADD COLUMN notifications_enabled INTEGER NOT NULL DEFAULT 1",
      );
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $favoriteVouchersTable (
          favorite_id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          voucher_id INTEGER NOT NULL,
          added_at TEXT NOT NULL,
          UNIQUE(user_id, voucher_id),
          FOREIGN KEY(user_id) REFERENCES $usersTable(user_id) ON DELETE CASCADE,
          FOREIGN KEY(voucher_id) REFERENCES $vouchersTable(voucher_id) ON DELETE CASCADE
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $notificationsTable (
          notification_id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER,
          title TEXT NOT NULL,
          body TEXT NOT NULL,
          type TEXT,
          created_at TEXT NOT NULL,
          is_read INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY(user_id) REFERENCES $usersTable(user_id) ON DELETE CASCADE
        )
      ''');
    }

    if (oldVersion < 10) {
      await db.execute(
        "ALTER TABLE $promotionsTable ADD COLUMN shop_name TEXT NOT NULL DEFAULT ''",
      );
      await db.execute(
        "ALTER TABLE $promotionsTable ADD COLUMN shop_address TEXT NOT NULL DEFAULT ''",
      );
    }

    if (oldVersion < 11) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $itemsTable (
          item_id INTEGER PRIMARY KEY AUTOINCREMENT,
          admin_id INTEGER NOT NULL,
          name TEXT NOT NULL,
          description TEXT,
          category TEXT,
          original_price REAL NOT NULL,
          discounted_price REAL NOT NULL,
          image_path TEXT,
          is_active INTEGER NOT NULL DEFAULT 1,
          created_at TEXT NOT NULL,
          updated_at TEXT,
          FOREIGN KEY(admin_id) REFERENCES $adminsTable(admin_id) ON DELETE CASCADE
        )
      ''');
      await db.execute(
        "ALTER TABLE $vouchersTable ADD COLUMN item_id INTEGER",
      );
      await db.execute(
        "ALTER TABLE $usersTable ADD COLUMN is_active INTEGER NOT NULL DEFAULT 1",
      );
    }

    if (oldVersion < 12) {
      await db.execute(
        "ALTER TABLE $promotionsTable ADD COLUMN show_on_home INTEGER NOT NULL DEFAULT 1",
      );
      await db.execute(
        "ALTER TABLE $promotionsTable ADD COLUMN show_on_vouchers INTEGER NOT NULL DEFAULT 0",
      );
      await db.execute(
        "ALTER TABLE $promotionsTable ADD COLUMN impressions INTEGER NOT NULL DEFAULT 0",
      );
      await db.execute(
        "ALTER TABLE $promotionsTable ADD COLUMN clicks INTEGER NOT NULL DEFAULT 0",
      );
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $promotionVouchersTable (
          promotion_voucher_id INTEGER PRIMARY KEY AUTOINCREMENT,
          promotion_id INTEGER NOT NULL,
          voucher_id INTEGER NOT NULL,
          FOREIGN KEY(promotion_id) REFERENCES $promotionsTable(promotion_id) ON DELETE CASCADE,
          FOREIGN KEY(voucher_id) REFERENCES $vouchersTable(voucher_id) ON DELETE CASCADE,
          UNIQUE(promotion_id, voucher_id)
        )
      ''');
    }

    if (oldVersion < 13) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $promotionLikesTable (
          like_id INTEGER PRIMARY KEY AUTOINCREMENT,
          promotion_id INTEGER NOT NULL,
          user_id INTEGER NOT NULL,
          is_like INTEGER NOT NULL DEFAULT 1,
          created_at TEXT NOT NULL,
          UNIQUE(promotion_id, user_id),
          FOREIGN KEY(promotion_id) REFERENCES $promotionsTable(promotion_id) ON DELETE CASCADE,
          FOREIGN KEY(user_id) REFERENCES $usersTable(user_id) ON DELETE CASCADE
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $promotionCommentsTable (
          comment_id INTEGER PRIMARY KEY AUTOINCREMENT,
          promotion_id INTEGER NOT NULL,
          user_id INTEGER NOT NULL,
          comment TEXT NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY(promotion_id) REFERENCES $promotionsTable(promotion_id) ON DELETE CASCADE,
          FOREIGN KEY(user_id) REFERENCES $usersTable(user_id) ON DELETE CASCADE
        )
      ''');
    }
  }

  Future<int> insertUser(AppUser user) async {
    final db = await database;
    final payload = user.copyWith(email: user.email.toLowerCase());
    final map = payload.toMap()..remove('user_id');
    return db.insert(
      usersTable,
      map,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<AppUser?> getUserByEmail(String email) async {
    final db = await database;
    final maps = await db.query(
      usersTable,
      where: 'LOWER(email) = ?',
      whereArgs: [email.toLowerCase()],
      limit: 1,
    );
    if (maps.isEmpty) {
      return null;
    }
    return AppUser.fromMap(maps.first);
  }

  Future<AppUser?> validateUser(String email, String password) async {
    final db = await database;
    final maps = await db.query(
      usersTable,
      where: 'LOWER(email) = ? AND password = ?',
      whereArgs: [email.toLowerCase(), password],
      limit: 1,
    );
    if (maps.isEmpty) {
      return null;
    }
    return AppUser.fromMap(maps.first);
  }

  // Admin CRUD operations
  /// Insert a new admin into the database
  Future<int> insertAdmin(Admin admin) async {
    final db = await database;
    final payload = admin.copyWith(
      email: admin.email.trim().toLowerCase(),
      password: admin.password.trim(),
    );
    final map = payload.toMap()..remove('admin_id');
    return db.insert(
      adminsTable,
      map,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  /// Get admin by email
  Future<Admin?> getAdminByEmail(String email) async {
    final db = await database;
    final maps = await db.query(
      adminsTable,
      where: 'LOWER(email) = ?',
      whereArgs: [email.toLowerCase()],
      limit: 1,
    );
    if (maps.isEmpty) {
      return null;
    }
    return Admin.fromMap(maps.first);
  }

  /// Validate admin credentials
  Future<Admin?> validateAdmin(String email, String password) async {
    final db = await database;
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedPassword = password.trim();
    if (normalizedEmail.isEmpty || normalizedPassword.isEmpty) {
      return null;
    }
    final maps = await db.query(
      adminsTable,
      where: 'LOWER(email) = ? AND password = ?',
      whereArgs: [normalizedEmail, normalizedPassword],
      limit: 1,
    );
    if (maps.isEmpty) {
      return null;
    }
    return Admin.fromMap(maps.first);
  }

  // Item management
  Future<int> insertItem(Item item) async {
    final db = await database;
    final map = item.copyWith(
      name: item.name.trim(),
      description: item.description?.trim(),
      category: item.category?.trim(),
      imagePath: item.imagePath?.trim().isEmpty == true
          ? null
          : item.imagePath?.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ).toMap()
      ..remove('item_id');
    return db.insert(itemsTable, map, conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<int> updateItem(Item item) async {
    if (item.id == null) {
      throw ArgumentError('Item id required for update');
    }
    final db = await database;
    final map = item.copyWith(
      name: item.name.trim(),
      description: item.description?.trim(),
      category: item.category?.trim(),
      imagePath: item.imagePath?.trim().isEmpty == true
          ? null
          : item.imagePath?.trim(),
      updatedAt: DateTime.now(),
    ).toMap()
      ..remove('item_id');
    return db.update(
      itemsTable,
      map,
      where: 'item_id = ? AND admin_id = ?',
      whereArgs: [item.id, item.adminId],
    );
  }

  Future<void> deleteItem({required int itemId, required int adminId}) async {
    final db = await database;
    await db.delete(
      itemsTable,
      where: 'item_id = ? AND admin_id = ?',
      whereArgs: [itemId, adminId],
    );
  }

  Future<void> toggleItemActive({
    required int itemId,
    required int adminId,
    required bool isActive,
  }) async {
    final db = await database;
    await db.update(
      itemsTable,
      {
        'is_active': isActive ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'item_id = ? AND admin_id = ?',
      whereArgs: [itemId, adminId],
    );
  }

  Future<List<Item>> getItems({
    required int adminId,
    bool includeInactive = true,
  }) async {
    final db = await database;
    final where = includeInactive ? 'admin_id = ?' : 'admin_id = ? AND is_active = 1';
    final maps = await db.query(
      itemsTable,
      where: where,
      whereArgs: [adminId],
      orderBy: 'datetime(created_at) DESC',
    );
    return maps.map(Item.fromMap).toList();
  }

  Future<Item?> getItemById(int itemId) async {
    final db = await database;
    final maps = await db.query(
      itemsTable,
      where: 'item_id = ?',
      whereArgs: [itemId],
      limit: 1,
    );
    if (maps.isEmpty) {
      return null;
    }
    return Item.fromMap(maps.first);
  }

  Future<int> getItemCount(int adminId) async {
    final db = await database;
    return Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM $itemsTable WHERE admin_id = ?',
          [adminId],
        )) ??
        0;
  }

  Future<int> getActiveItemCount(int adminId) async {
    final db = await database;
    return Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM $itemsTable WHERE admin_id = ? AND is_active = 1',
          [adminId],
        )) ??
        0;
  }

  Future<List<Map<String, dynamic>>> getTopItemsByRedemption(int adminId,
      {int limit = 5}) async {
    final db = await database;
    final rows = await db.rawQuery(
      '''
      SELECT i.name AS item_name, COUNT(r.redeem_id) AS total
      FROM $itemsTable i
      INNER JOIN $vouchersTable v ON v.item_id = i.item_id
      LEFT JOIN $redeemedTable r ON r.voucher_id = v.voucher_id
                                    AND r.redeem_status = 'Confirmed'
      WHERE i.admin_id = ?
      GROUP BY i.item_id
      ORDER BY total DESC
      LIMIT ?
      ''',
      [adminId, limit],
    );
    return rows;
  }

  // User management
  Future<List<AppUser>> getUsers({bool includeInactive = true}) async {
    final db = await database;
    final maps = await db.query(
      usersTable,
      where: includeInactive ? null : 'is_active = 1',
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return maps.map(AppUser.fromMap).toList();
  }

  Future<void> setUserActiveStatus({
    required int userId,
    required bool isActive,
  }) async {
    final db = await database;
    await db.update(
      usersTable,
      {'is_active': isActive ? 1 : 0},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<int> getTotalUsers({bool onlyActive = false}) async {
    final db = await database;
    final query = onlyActive
        ? 'SELECT COUNT(*) FROM $usersTable WHERE is_active = 1'
        : 'SELECT COUNT(*) FROM $usersTable';
    return Sqflite.firstIntValue(await db.rawQuery(query)) ?? 0;
  }

  Future<Map<int, int>> getRedeemedCountByUser() async {
    final db = await database;
    final rows = await db.rawQuery(
      '''
      SELECT user_id, COUNT(*) AS total
      FROM $redeemedTable
      WHERE redeem_status = 'Confirmed'
      GROUP BY user_id
      ''',
    );
    final Map<int, int> result = {};
    for (final row in rows) {
      final userId = row['user_id'] as int?;
      final total = (row['total'] as num?)?.toInt() ?? 0;
      if (userId != null) {
        result[userId] = total;
      }
    }
    return result;
  }

  // Shop operations
  Future<int> insertShop(Shop shop) async {
    final db = await database;
    final map = shop.toMap()..remove('shop_id');
    return db.insert(shopsTable, map);
  }

  Future<int> updateShop(Shop shop) async {
    if (shop.id == null) {
      throw ArgumentError('Shop id required for update.');
    }
    final db = await database;
    final map = shop.toMap()
      ..remove('shop_id')
      ..remove('admin_id');
    return db.update(
      shopsTable,
      map,
      where: 'shop_id = ? AND admin_id = ?',
      whereArgs: [shop.id, shop.adminId],
    );
  }

  Future<int> deleteShop({required int shopId, required int adminId}) async {
    final db = await database;
    return db.delete(
      shopsTable,
      where: 'shop_id = ? AND admin_id = ?',
      whereArgs: [shopId, adminId],
    );
  }

  Future<List<Shop>> getShops(int adminId) async {
    final db = await database;
    final maps = await db.query(
      shopsTable,
      where: 'admin_id = ?',
      whereArgs: [adminId],
      orderBy: 'shop_name COLLATE NOCASE',
    );
    return maps.map(Shop.fromMap).toList();
  }

  Future<Shop?> getShopById(int shopId) async {
    final db = await database;
    final maps = await db.query(
      shopsTable,
      where: 'shop_id = ?',
      whereArgs: [shopId],
      limit: 1,
    );
    if (maps.isEmpty) {
      return null;
    }
    return Shop.fromMap(maps.first);
  }

  Future<int> insertVoucher(Voucher voucher) async {
    final db = await database;
    final trimmedGallery = voucher.gallery
        .map((path) => path.trim())
        .where((path) => path.isNotEmpty)
        .toList();
    final baseCover = voucher.imagePath?.trim().isEmpty == true
        ? null
        : voucher.imagePath?.trim();
    final sanitized = voucher.copyWith(
      code: voucher.code.toUpperCase(),
      contactName: voucher.contactName?.trim().isEmpty == true
          ? null
          : voucher.contactName!.trim(),
      contactPhone: voucher.contactPhone?.trim().isEmpty == true
          ? null
          : voucher.contactPhone!.trim(),
      gallery: trimmedGallery,
      imagePath: trimmedGallery.isNotEmpty ? trimmedGallery.first : baseCover,
    );

    return db.transaction<int>((txn) async {
      final map = sanitized.toMap()..remove('voucher_id');
      final id = await txn.insert(
        vouchersTable,
        map,
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      await _replaceVoucherImagesInternal(txn, id, sanitized.gallery);
      return id;
    });
  }

  Future<int> updateVoucher(Voucher voucher) async {
    if (voucher.id == null) {
      throw ArgumentError('Voucher id is required for update.');
    }
    final db = await database;
    final trimmedGallery = voucher.gallery
        .map((path) => path.trim())
        .where((path) => path.isNotEmpty)
        .toList();
    final baseCover = voucher.imagePath?.trim().isEmpty == true
        ? null
        : voucher.imagePath?.trim();
    final sanitized = voucher.copyWith(
      code: voucher.code.toUpperCase(),
      contactName: voucher.contactName?.trim().isEmpty == true
          ? null
          : voucher.contactName!.trim(),
      contactPhone: voucher.contactPhone?.trim().isEmpty == true
          ? null
          : voucher.contactPhone!.trim(),
      gallery: trimmedGallery,
      imagePath: trimmedGallery.isNotEmpty ? trimmedGallery.first : baseCover,
    );

    return db.transaction<int>((txn) async {
      final map = sanitized.toMap()
        ..remove('voucher_id')
        ..remove('admin_id');
      final result = await txn.update(
        vouchersTable,
        map,
        where: 'voucher_id = ? AND admin_id = ?',
        whereArgs: [voucher.id, voucher.adminId],
      );
      await _replaceVoucherImagesInternal(txn, voucher.id!, sanitized.gallery);
      return result;
    });
  }

  Future<int> deleteVoucher({required int voucherId, required int adminId}) async {
    final db = await database;
    return db.delete(
      vouchersTable,
      where: 'voucher_id = ? AND admin_id = ?',
      whereArgs: [voucherId, adminId],
    );
  }

  Future<List<Voucher>> getVouchers({
    String? status,
    String? query,
    int? adminId,
    String? shopName,
    double? minDiscount,
    double? maxDiscount,
    double? minPrice,
    double? maxPrice,
    DateTime? expiryFrom,
    DateTime? expiryTo,
    String sortBy = 'default',
    int? userIdForFavorites,
    bool favoritesOnly = false,
    int? limit,
    List<String>? categories,
  }) async {
    final db = await database;

    final filters = <String>[];
    final args = <dynamic>[];

    if (adminId != null) {
      filters.add('admin_id = ?');
      args.add(adminId);
    }

    if (status != null) {
      filters.add('status = ?');
      args.add(status);
    }

    if (query != null && query.isNotEmpty) {
      filters.add(
          '(LOWER(name) LIKE ? OR LOWER(code) LIKE ? OR LOWER(shop_name) LIKE ?)');
      final q = '%${query.toLowerCase()}%';
      args.addAll([q, q, q]);
    }

    if (shopName != null && shopName.trim().isNotEmpty) {
      filters.add('LOWER(shop_name) LIKE ?');
      args.add('%${shopName.toLowerCase()}%');
    }

    const discountExpression =
        "CASE WHEN discount_type = 'percentage' THEN discount_value "
        "ELSE ((original_price - discounted_price) / NULLIF(original_price,0)) * 100 END";

    if (minDiscount != null) {
      filters.add('($discountExpression) >= ?');
      args.add(minDiscount);
    }

    if (maxDiscount != null) {
      filters.add('($discountExpression) <= ?');
      args.add(maxDiscount);
    }

    if (minPrice != null) {
      filters.add('discounted_price >= ?');
      args.add(minPrice);
    }

    if (maxPrice != null) {
      filters.add('discounted_price <= ?');
      args.add(maxPrice);
    }

    if (expiryFrom != null) {
      filters.add('date(expiry_date) >= date(?)');
      args.add(expiryFrom.toIso8601String());
    }

    if (expiryTo != null) {
      filters.add('date(expiry_date) <= date(?)');
      args.add(expiryTo.toIso8601String());
    }

    if (favoritesOnly && userIdForFavorites != null) {
      filters.add(
        'voucher_id IN (SELECT voucher_id FROM $favoriteVouchersTable WHERE user_id = ?)',
      );
      args.add(userIdForFavorites);
    }

    if (categories != null && categories.isNotEmpty) {
      final placeholders = List.filled(categories.length, '?').join(',');
      filters.add(
          'item_id IN (SELECT item_id FROM $itemsTable WHERE LOWER(category) IN ($placeholders))');
      args.addAll(categories.map((category) => category.toLowerCase()));
    }

    String? orderBy;
    switch (sortBy) {
      case 'newest':
        orderBy = 'voucher_id DESC';
        break;
      case 'highest_discount':
        orderBy = '($discountExpression) DESC';
        break;
      case 'expiring_soon':
        orderBy = 'expiry_date ASC';
        break;
      case 'price_low_high':
        orderBy = 'discounted_price ASC';
        break;
      case 'price_high_low':
        orderBy = 'discounted_price DESC';
        break;
      default:
        orderBy = adminId != null ? 'expiry_date ASC' : 'voucher_id DESC';
        break;
    }

    final results = await db.query(
      vouchersTable,
      where: filters.isEmpty ? null : filters.join(' AND '),
      whereArgs: filters.isEmpty ? null : args,
      orderBy: orderBy,
      limit: limit,
    );

    final vouchers = results.map(Voucher.fromMap).toList();
    await _hydrateVoucherImages(vouchers);
    await _hydrateVoucherCategories(vouchers);
    final now = DateTime.now();
    var requiresRefresh = false;

    for (var i = 0; i < vouchers.length; i++) {
      final voucher = vouchers[i];
      if (voucher.status == 'active' && voucher.expiryDate.isBefore(now)) {
        final updated = voucher.copyWith(status: 'expired');
        await updateVoucher(updated);
        vouchers[i] = updated;
        requiresRefresh = true;
      }
    }

    if (requiresRefresh) {
      return getVouchers(
        status: status,
        query: query,
        adminId: adminId,
        shopName: shopName,
        minDiscount: minDiscount,
        maxDiscount: maxDiscount,
        minPrice: minPrice,
        maxPrice: maxPrice,
        expiryFrom: expiryFrom,
        expiryTo: expiryTo,
        sortBy: sortBy,
        userIdForFavorites: userIdForFavorites,
        favoritesOnly: favoritesOnly,
        limit: limit,
        categories: categories,
      );
    }

    return vouchers;
  }

  Future<String?> redeemVoucher({
    required int userId,
    required Voucher voucher,
  }) async {
    final db = await database;

    if (voucher.id == null) {
      throw ArgumentError('Voucher must have an id before redemption.');
    }

    final usageCount = Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM $redeemedTable WHERE voucher_id = ?',
            [voucher.id],
          ),
        ) ??
        0;

    if (usageCount >= voucher.usageLimit) {
      return 'This voucher has reached its usage limit.';
    }

    await db.insert(
      redeemedTable,
      RedeemedVoucher(
        userId: userId,
        voucherId: voucher.id!,
        dateRedeemed: DateTime.now(),
      ).toMap(),
    );

    return null;
  }

  Future<List<RedeemedVoucherDetail>> getRedeemedVouchers({
    int? userId,
    int? adminId,
  }) async {
    final db = await database;

    final args = <dynamic>[];
    final conditions = <String>[];

    if (userId != null) {
      conditions.add('r.user_id = ?');
      args.add(userId);
    }

    if (adminId != null) {
      conditions.add('v.admin_id = ?');
      args.add(adminId);
    }

    final buffer = StringBuffer('''
      SELECT r.redeem_id, r.user_id, v.voucher_id, v.name AS voucher_name, v.code AS voucher_code,
             v.discount_value AS discount_value, u.name AS user_name,
             v.shop_name AS shop_name, v.shop_address AS shop_address,
             v.original_price AS original_price, v.discounted_price AS discounted_price,
             r.date_redeemed, r.redeem_status, r.redeem_note, r.redeemed_by
      FROM $redeemedTable r
      INNER JOIN $vouchersTable v ON r.voucher_id = v.voucher_id
      INNER JOIN $usersTable u ON r.user_id = u.user_id
    ''');

    if (conditions.isNotEmpty) {
      buffer.write(' WHERE ');
      buffer.write(conditions.join(' AND '));
    }

    buffer.write(' ORDER BY r.date_redeemed DESC');

    final maps = await db.rawQuery(buffer.toString(), args);

    return maps
        .map(
          (map) => RedeemedVoucherDetail(
            id: map['redeem_id'] as int?,
            userId: (map['user_id'] as num).toInt(),
            voucherId: (map['voucher_id'] as num).toInt(),
            voucherName: map['voucher_name'] as String,
            voucherCode: map['voucher_code'] as String,
            discountValue: (map['discount_value'] as num).toDouble(),
            userName: map['user_name'] as String,
            shopName: map['shop_name'] as String,
            shopAddress: map['shop_address'] as String,
            dateRedeemed: DateTime.parse(map['date_redeemed'] as String),
            status: map['redeem_status'] as String? ?? 'Pending',
            note: map['redeem_note'] as String?,
            redeemedBy: map['redeemed_by'] as String?,
            originalPrice: (map['original_price'] as num).toDouble(),
            discountedPrice: (map['discounted_price'] as num).toDouble(),
          ),
        )
        .toList();
  }

  Future<Map<String, dynamic>> getAdminAnalytics(int adminId) async {
    final db = await database;

    final totalVouchers = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM $vouchersTable WHERE admin_id = ?',
          [adminId],
        )) ??
        0;

    final totalRedeemed = Sqflite.firstIntValue(await db.rawQuery(
          '''
          SELECT COUNT(*)
          FROM $redeemedTable r
          INNER JOIN $vouchersTable v ON r.voucher_id = v.voucher_id
          WHERE v.admin_id = ? AND r.redeem_status = 'Confirmed'
          ''',
          [adminId],
        )) ??
        0;

    final mostRedeemed = await db.rawQuery(
      '''
      SELECT v.name, COUNT(r.redeem_id) AS total
      FROM $vouchersTable v
      LEFT JOIN $redeemedTable r
        ON v.voucher_id = r.voucher_id AND r.redeem_status = 'Confirmed'
      WHERE v.admin_id = ?
      GROUP BY v.voucher_id
      ORDER BY total DESC
      LIMIT 5
      ''',
      [adminId],
    );

    final avgRating = await db.rawQuery(
      '''
      SELECT AVG(f.rating) AS rating
      FROM $feedbackTable f
      INNER JOIN $vouchersTable v ON f.voucher_id = v.voucher_id
      WHERE v.admin_id = ?
      ''',
      [adminId],
    );

    Map<String, dynamic>? mostRedeemedMap;
    final topRedeemedList = mostRedeemed
        .map(
          (row) => {
            'name': row['name'] as String? ?? 'Unknown voucher',
            'total': (row['total'] as num?)?.toInt() ?? 0,
          },
        )
        .where((entry) => entry['total'] as int > 0)
        .toList();

    if (topRedeemedList.isNotEmpty) {
      mostRedeemedMap = topRedeemedList.first;
    }

    return {
      'totalVouchers': totalVouchers,
      'totalRedeemed': totalRedeemed,
      'mostRedeemed': mostRedeemedMap,
      'topRedeemed': topRedeemedList,
      'averageRating':
          avgRating.isEmpty || avgRating.first['rating'] == null
              ? 0.0
              : (avgRating.first['rating'] as num).toDouble(),
    };
  }

  Future<void> confirmRedemption({
    required int redeemId,
    required String redeemedBy,
    String? note,
  }) async {
    final db = await database;
    await db.update(
      redeemedTable,
      {
        'redeem_status': 'Confirmed',
        'redeem_note': note,
        'redeemed_by': redeemedBy,
      },
      where: 'redeem_id = ?',
      whereArgs: [redeemId],
    );
  }

  Future<bool> hasUserSubmittedFeedback({
    required int userId,
    required int voucherId,
  }) async {
    final db = await database;
    final count = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM $feedbackTable WHERE user_id = ? AND voucher_id = ?',
          [userId, voucherId],
        )) ??
        0;
    return count > 0;
  }

  Future<void> insertFeedback(FeedbackEntry entry) async {
    final db = await database;
    await db.insert(
      feedbackTable,
      entry.toMap()..remove('feedback_id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Promotions
  Future<int> insertPromotion(Promotion promotion) async {
    final db = await database;
    final trimmedGallery = promotion.gallery
        .map((path) => path.trim())
        .where((path) => path.isNotEmpty)
        .toList();
    final sanitizedVoucherIds = promotion.voucherIds
        .where((id) => id > 0)
        .toSet()
        .toList();
    final baseCover = promotion.imagePath?.trim().isEmpty == true
        ? null
        : promotion.imagePath?.trim();
    final payload = promotion.copyWith(
      title: promotion.title.trim(),
      description: promotion.description.trim(),
      shopName: promotion.shopName.trim(),
      shopAddress: promotion.shopAddress.trim(),
      contactName: promotion.contactName?.trim().isEmpty == true
          ? null
          : promotion.contactName!.trim(),
      contactPhone: promotion.contactPhone?.trim().isEmpty == true
          ? null
          : promotion.contactPhone!.trim(),
      gallery: trimmedGallery,
      imagePath: trimmedGallery.isNotEmpty ? trimmedGallery.first : baseCover,
      voucherIds: sanitizedVoucherIds,
    );
    return db.transaction<int>((txn) async {
      final map = payload.toMap()..remove('promotion_id');
      final id = await txn.insert(
        promotionsTable,
        map,
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      await _replacePromotionImagesInternal(txn, id, payload.gallery);
      await _replacePromotionVouchersInternal(txn, id, payload.voucherIds);
      return id;
    });
  }

  Future<int> updatePromotion(Promotion promotion) async {
    if (promotion.id == null) {
      throw ArgumentError('Promotion id required for update');
    }
    final db = await database;
    final trimmedGallery = promotion.gallery
        .map((path) => path.trim())
        .where((path) => path.isNotEmpty)
        .toList();
    final sanitizedVoucherIds = promotion.voucherIds
        .where((id) => id > 0)
        .toSet()
        .toList();
    final baseCover = promotion.imagePath?.trim().isEmpty == true
        ? null
        : promotion.imagePath?.trim();
    final mapPayload = promotion.copyWith(
      title: promotion.title.trim(),
      description: promotion.description.trim(),
      shopName: promotion.shopName.trim(),
      shopAddress: promotion.shopAddress.trim(),
      contactName: promotion.contactName?.trim().isEmpty == true
          ? null
          : promotion.contactName!.trim(),
      contactPhone: promotion.contactPhone?.trim().isEmpty == true
          ? null
          : promotion.contactPhone!.trim(),
      gallery: trimmedGallery,
      imagePath: trimmedGallery.isNotEmpty
          ? trimmedGallery.first
          : baseCover,
      voucherIds: sanitizedVoucherIds,
    ).toMap();
    mapPayload.remove('promotion_id');
    return db.transaction<int>((txn) async {
      final result = await txn.update(
        promotionsTable,
        mapPayload,
        where: 'promotion_id = ? AND admin_id = ?',
        whereArgs: [promotion.id, promotion.adminId],
      );
      await _replacePromotionImagesInternal(txn, promotion.id!, trimmedGallery);
      await _replacePromotionVouchersInternal(txn, promotion.id!, sanitizedVoucherIds);
      return result;
    });
  }

  Future<int> deletePromotion({required int promotionId, required int adminId}) async {
    final db = await database;
    return db.delete(
      promotionsTable,
      where: 'promotion_id = ? AND admin_id = ?',
      whereArgs: [promotionId, adminId],
    );
  }

  Future<List<Promotion>> getPromotions({
    int? adminId,
    bool includeExpired = true,
    String sortBy = 'start_date',
    bool? showOnHome,
    bool? showOnVouchers,
  }) async {
    final db = await database;
    final filters = <String>[];
    final args = <dynamic>[];
    if (adminId != null) {
      filters.add('admin_id = ?');
      args.add(adminId);
    }
    if (!includeExpired) {
      filters.add('date(end_date) >= date(?)');
      args.add(DateTime.now().toIso8601String());
    }
    if (showOnHome != null) {
      filters.add('show_on_home = ?');
      args.add(showOnHome ? 1 : 0);
    }
    if (showOnVouchers != null) {
      filters.add('show_on_vouchers = ?');
      args.add(showOnVouchers ? 1 : 0);
    }

    String orderBy;
    switch (sortBy) {
      case 'expiring_soon':
        orderBy = 'end_date ASC';
        break;
      case 'recent':
        orderBy = 'promotion_id DESC';
        break;
      default:
        orderBy = 'start_date ASC';
    }

    final maps = await db.query(
      promotionsTable,
      where: filters.isEmpty ? null : filters.join(' AND '),
      whereArgs: filters.isEmpty ? null : args,
      orderBy: orderBy,
    );

    final promotions = maps.map(Promotion.fromMap).toList();
    await _hydratePromotionImages(promotions);
    await _hydratePromotionAssociations(promotions);
    return promotions;
  }

  Future<List<Promotion>> getActivePromotions({
    bool? showOnHome,
    bool? showOnVouchers,
  }) async {
    final now = DateTime.now();
    final promotions = await getPromotions(
      includeExpired: false,
      sortBy: 'start_date',
      showOnHome: showOnHome,
      showOnVouchers: showOnVouchers,
    );

    // getPromotions already hydrates images/associations but ensures date filter includes only those currently active
    return promotions
        .where((promotion) =>
            promotion.startDate.isBefore(now) ||
            promotion.startDate.isAtSameMomentAs(now))
        .toList();
  }

  Future<Map<String, int>> getPromotionAnalytics(int adminId) async {
    final db = await database;
    final nowIso = DateTime.now().toIso8601String();

    final total = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM $promotionsTable WHERE admin_id = ?',
          [adminId],
        )) ??
        0;
    final active = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM $promotionsTable WHERE admin_id = ? AND date(start_date) <= date(?) AND date(end_date) >= date(?)',
          [adminId, nowIso, nowIso],
        )) ??
        0;
    final upcoming = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM $promotionsTable WHERE admin_id = ? AND date(start_date) > date(?)',
          [adminId, nowIso],
        )) ??
        0;
    final expired = total - active - upcoming;

    return {
      'total': total,
      'active': active,
      'upcoming': upcoming,
      'expired': expired < 0 ? 0 : expired,
    };
  }

  Future<Map<int, Map<String, dynamic>>> getPromotionPerformance(
    int adminId,
  ) async {
    final db = await database;
    final rows = await db.rawQuery(
      '''
      SELECT p.promotion_id,
             p.impressions,
             p.clicks,
             COUNT(DISTINCT pv.voucher_id) AS linked_vouchers,
             COALESCE(SUM(CASE WHEN r.redeem_status = 'Confirmed' THEN 1 ELSE 0 END), 0) AS confirmed_redemptions
      FROM $promotionsTable p
      LEFT JOIN $promotionVouchersTable pv ON pv.promotion_id = p.promotion_id
      LEFT JOIN $vouchersTable v ON v.voucher_id = pv.voucher_id
      LEFT JOIN $redeemedTable r ON r.voucher_id = v.voucher_id AND r.redeem_status = 'Confirmed'
      WHERE p.admin_id = ?
      GROUP BY p.promotion_id
      ''',
      [adminId],
    );

    final performance = <int, Map<String, dynamic>>{};
    for (final row in rows) {
      final promotionId = (row['promotion_id'] as num).toInt();
      final impressions = (row['impressions'] as num?)?.toInt() ?? 0;
      final clicks = (row['clicks'] as num?)?.toInt() ?? 0;
      final linked = (row['linked_vouchers'] as num?)?.toInt() ?? 0;
      final redemptions = (row['confirmed_redemptions'] as num?)?.toInt() ?? 0;
      final engagementRate = impressions == 0 ? 0.0 : clicks / impressions;
      performance[promotionId] = {
        'impressions': impressions,
        'clicks': clicks,
        'linkedVouchers': linked,
        'confirmedRedemptions': redemptions,
        'engagementRate': engagementRate,
      };
    }
    return performance;
  }

  Future<void> recordPromotionImpression(int promotionId) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE $promotionsTable SET impressions = impressions + 1 WHERE promotion_id = ?',
      [promotionId],
    );
  }

  Future<void> recordPromotionClick(int promotionId) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE $promotionsTable SET clicks = clicks + 1 WHERE promotion_id = ?',
      [promotionId],
    );
  }

  // Promotion likes/dislikes methods
  Future<void> togglePromotionLike({
    required int promotionId,
    required int userId,
    required bool isLike,
  }) async {
    final db = await database;
    final existing = await db.query(
      promotionLikesTable,
      where: 'promotion_id = ? AND user_id = ?',
      whereArgs: [promotionId, userId],
    );

    if (existing.isEmpty) {
      await db.insert(
        promotionLikesTable,
        {
          'promotion_id': promotionId,
          'user_id': userId,
          'is_like': isLike ? 1 : 0,
          'created_at': DateTime.now().toIso8601String(),
        },
      );
    } else {
      final currentLike = existing.first['is_like'] as int;
      if (currentLike == (isLike ? 1 : 0)) {
        // Remove like/dislike if clicking the same button
        await db.delete(
          promotionLikesTable,
          where: 'promotion_id = ? AND user_id = ?',
          whereArgs: [promotionId, userId],
        );
      } else {
        // Toggle between like and dislike
        await db.update(
          promotionLikesTable,
          {
            'is_like': isLike ? 1 : 0,
            'created_at': DateTime.now().toIso8601String(),
          },
          where: 'promotion_id = ? AND user_id = ?',
          whereArgs: [promotionId, userId],
        );
      }
    }
  }

  Future<Map<String, dynamic>> getPromotionLikesDislikes(int promotionId) async {
    final db = await database;
    final likes = Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM $promotionLikesTable WHERE promotion_id = ? AND is_like = 1',
            [promotionId],
          ),
        ) ??
        0;
    final dislikes = Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM $promotionLikesTable WHERE promotion_id = ? AND is_like = 0',
            [promotionId],
          ),
        ) ??
        0;
    return {'likes': likes, 'dislikes': dislikes};
  }

  Future<int?> getUserPromotionReaction({
    required int promotionId,
    required int userId,
  }) async {
    final db = await database;
    final result = await db.query(
      promotionLikesTable,
      where: 'promotion_id = ? AND user_id = ?',
      whereArgs: [promotionId, userId],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return result.first['is_like'] as int?;
  }

  // Promotion comments methods
  Future<int> addPromotionComment({
    required int promotionId,
    required int userId,
    required String comment,
  }) async {
    final db = await database;
    return await db.insert(
      promotionCommentsTable,
      {
        'promotion_id': promotionId,
        'user_id': userId,
        'comment': comment,
        'created_at': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<List<Map<String, dynamic>>> getPromotionComments(int promotionId) async {
    final db = await database;
    return await db.rawQuery(
      '''
      SELECT c.comment_id, c.promotion_id, c.user_id, c.comment, c.created_at,
             u.name AS user_name
      FROM $promotionCommentsTable c
      INNER JOIN $usersTable u ON c.user_id = u.user_id
      WHERE c.promotion_id = ?
      ORDER BY c.created_at DESC
      ''',
      [promotionId],
    );
  }

  Future<int> getPromotionCommentCount(int promotionId) async {
    final db = await database;
    return Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM $promotionCommentsTable WHERE promotion_id = ?',
            [promotionId],
          ),
        ) ??
        0;
  }

  Future<List<FeedbackEntry>> getFeedbackForVoucher(int voucherId) async {
    final db = await database;
    final maps = await db.rawQuery(
      '''
      SELECT f.feedback_id, f.user_id, f.voucher_id, f.rating, f.comment, f.date,
             u.name AS user_name
      FROM $feedbackTable f
      INNER JOIN $usersTable u ON f.user_id = u.user_id
      WHERE f.voucher_id = ?
      ORDER BY f.date DESC
      ''',
      [voucherId],
    );
    return maps.map(FeedbackEntry.fromMap).toList();
  }

  Future<List<Map<String, dynamic>>> getAllFeedback({required int adminId}) async {
    final db = await database;
    return db.rawQuery(
      '''
      SELECT f.feedback_id, f.rating, f.comment, f.date,
             v.name AS voucher_name, u.name AS user_name
      FROM $feedbackTable f
      INNER JOIN $vouchersTable v ON f.voucher_id = v.voucher_id
      INNER JOIN $usersTable u ON f.user_id = u.user_id
      WHERE v.admin_id = ?
      ORDER BY datetime(f.date) DESC
      ''',
      [adminId],
    );
  }

  Future<Map<String, dynamic>> getAdminDashboardSummary(int adminId) async {
    final db = await database;
    final nowIso = DateTime.now().toIso8601String();

    final totalUsers = await getTotalUsers();
    final activeVouchers = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM $vouchersTable WHERE admin_id = ? AND status = "active" AND date(expiry_date) >= date(?)',
          [adminId, nowIso],
        )) ??
        0;
    final activePromotions = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM $promotionsTable WHERE admin_id = ? AND date(start_date) <= date(?) AND date(end_date) >= date(?)',
          [adminId, nowIso, nowIso],
        )) ??
        0;
    final redemptionCount = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM $redeemedTable r INNER JOIN $vouchersTable v ON r.voucher_id = v.voucher_id WHERE v.admin_id = ? AND r.redeem_status = "Confirmed"',
          [adminId],
        )) ??
        0;

    final topShops = await db.rawQuery(
      '''
      SELECT v.shop_name, COUNT(r.redeem_id) AS total
      FROM $vouchersTable v
      LEFT JOIN $redeemedTable r
        ON r.voucher_id = v.voucher_id AND r.redeem_status = 'Confirmed'
      WHERE v.admin_id = ?
      GROUP BY v.shop_name
      ORDER BY total DESC
      LIMIT 3
      ''',
      [adminId],
    );

    final revenueSaved = Sqflite.firstIntValue(await db.rawQuery(
          '''
          SELECT ROUND(SUM(v.original_price - v.discounted_price))
          FROM $redeemedTable r
          INNER JOIN $vouchersTable v ON r.voucher_id = v.voucher_id
          WHERE v.admin_id = ? AND r.redeem_status = 'Confirmed'
          ''',
          [adminId],
        )) ??
        0;

    return {
      'totalUsers': totalUsers,
      'activeVouchers': activeVouchers,
      'activePromotions': activePromotions,
      'redemptionCount': redemptionCount,
      'topShops': topShops,
      'revenueSaved': revenueSaved,
    };
  }

  Future<Map<String, List<Map<String, dynamic>>>> getVoucherActivityTrend(
      int adminId) async {
    final db = await database;

    Future<List<Map<String, dynamic>>> queryTrend(
      String strftimeFormat,
      int limit,
    ) async {
      final rows = await db.rawQuery(
        '''
        SELECT strftime('$strftimeFormat', r.date_redeemed) AS label,
               COUNT(r.redeem_id) AS total
        FROM $redeemedTable r
        INNER JOIN $vouchersTable v ON r.voucher_id = v.voucher_id
        WHERE v.admin_id = ?
        GROUP BY label
        ORDER BY label DESC
        LIMIT ?
        ''',
        [adminId, limit],
      );
      return rows.reversed
          .map((row) => {
                'label': row['label'] as String,
                'total': (row['total'] as num).toInt(),
              })
          .toList();
    }

    final daily = await queryTrend('%Y-%m-%d', 7);
    final weekly = await queryTrend('%Y-W%W', 8);
    final monthly = await queryTrend('%Y-%m', 6);

    return {
      'daily': daily,
      'weekly': weekly,
      'monthly': monthly,
    };
  }

  Future<void> _replaceVoucherImagesInternal(
    Transaction txn,
    int voucherId,
    List<String> images,
  ) async {
    await txn.delete(
      voucherImagesTable,
      where: 'voucher_id = ?',
      whereArgs: [voucherId],
    );
    for (final path in images) {
      await txn.insert(voucherImagesTable, {
        'voucher_id': voucherId,
        'image_path': path,
      });
    }
  }

  Future<void> _replacePromotionImagesInternal(
    Transaction txn,
    int promotionId,
    List<String> images,
  ) async {
    await txn.delete(
      promotionImagesTable,
      where: 'promotion_id = ?',
      whereArgs: [promotionId],
    );
    for (final path in images) {
      await txn.insert(promotionImagesTable, {
        'promotion_id': promotionId,
        'image_path': path,
      });
    }
  }

  Future<void> _replacePromotionVouchersInternal(
    Transaction txn,
    int promotionId,
    List<int> voucherIds,
  ) async {
    await txn.delete(
      promotionVouchersTable,
      where: 'promotion_id = ?',
      whereArgs: [promotionId],
    );
    if (voucherIds.isEmpty) {
      return;
    }
    for (final voucherId in voucherIds) {
      await txn.insert(
        promotionVouchersTable,
        {
          'promotion_id': promotionId,
          'voucher_id': voucherId,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<void> _hydrateVoucherImages(List<Voucher> vouchers) async {
    if (vouchers.isEmpty) return;
    final ids = vouchers.where((v) => v.id != null).map((v) => v.id!).toList();
    if (ids.isEmpty) return;
    final db = await database;
    final placeholders = List.filled(ids.length, '?').join(',');
    final rows = await db.query(
      voucherImagesTable,
      where: 'voucher_id IN ($placeholders)',
      whereArgs: ids,
      orderBy: 'voucher_id ASC, voucher_image_id ASC',
    );
    final Map<int, List<String>> grouped = {};
    for (final row in rows) {
      final voucherId = row['voucher_id'] as int;
      final path = row['image_path'] as String;
      grouped.putIfAbsent(voucherId, () => []).add(path);
    }
    for (var i = 0; i < vouchers.length; i++) {
      final voucher = vouchers[i];
      final gallery = grouped[voucher.id ?? -1] ?? [];
      vouchers[i] = voucher.copyWith(
        gallery: gallery,
        imagePath: gallery.isNotEmpty ? gallery.first : voucher.imagePath,
      );
    }
  }

  Future<void> _hydratePromotionImages(List<Promotion> promotions) async {
    if (promotions.isEmpty) return;
    final ids = promotions.where((p) => p.id != null).map((p) => p.id!).toList();
    if (ids.isEmpty) return;
    final db = await database;
    final placeholders = List.filled(ids.length, '?').join(',');
    final rows = await db.query(
      promotionImagesTable,
      where: 'promotion_id IN ($placeholders)',
      whereArgs: ids,
      orderBy: 'promotion_id ASC, promotion_image_id ASC',
    );
    final Map<int, List<String>> grouped = {};
    for (final row in rows) {
      final promotionId = row['promotion_id'] as int;
      final path = row['image_path'] as String;
      grouped.putIfAbsent(promotionId, () => []).add(path);
    }
    for (var i = 0; i < promotions.length; i++) {
      final promotion = promotions[i];
      final gallery = grouped[promotion.id ?? -1] ?? [];
      promotions[i] = promotion.copyWith(
        gallery: gallery,
        imagePath: gallery.isNotEmpty ? gallery.first : promotion.imagePath,
      );
    }
  }

  Future<void> _hydratePromotionAssociations(List<Promotion> promotions) async {
    if (promotions.isEmpty) return;
    final ids = promotions.where((p) => p.id != null).map((p) => p.id!).toList();
    if (ids.isEmpty) return;
    final db = await database;
    final placeholders = List.filled(ids.length, '?').join(',');
    final rows = await db.rawQuery(
      '''
      SELECT p.promotion_id, v.voucher_id
      FROM $promotionVouchersTable p
      INNER JOIN $vouchersTable v ON p.voucher_id = v.voucher_id
      WHERE p.promotion_id IN ($placeholders)
      ''',
      [...ids],
    );
    final Map<int, List<int>> grouped = {};
    for (final row in rows) {
      final promotionId = row['promotion_id'] as int;
      final voucherId = row['voucher_id'] as int;
      grouped.putIfAbsent(promotionId, () => []).add(voucherId);
    }
    for (var i = 0; i < promotions.length; i++) {
      final promotion = promotions[i];
      final voucherIds = grouped[promotion.id ?? -1] ?? const <int>[];
      promotions[i] = promotion.copyWith(voucherIds: voucherIds);
    }
  }

  Future<void> _hydrateVoucherCategories(List<Voucher> vouchers) async {
    if (vouchers.isEmpty) return;
    final itemIds = vouchers
        .map((voucher) => voucher.itemId)
        .whereType<int>()
        .toSet();
    if (itemIds.isEmpty) return;
    final db = await database;
    final placeholders = List.filled(itemIds.length, '?').join(',');
    final rows = await db.query(
      itemsTable,
      columns: ['item_id', 'category', 'name'],
      where: 'item_id IN ($placeholders)',
      whereArgs: itemIds.toList(),
    );
    final metadata = <int, Map<String, String?>>{};
    for (final row in rows) {
      final itemId = row['item_id'] as int;
      metadata[itemId] = {
        'category': row['category'] as String?,
        'name': row['name'] as String?,
      };
    }
    for (var i = 0; i < vouchers.length; i++) {
      final voucher = vouchers[i];
      final itemId = voucher.itemId;
      if (itemId == null) continue;
      final data = metadata[itemId];
      if (data == null) continue;
      vouchers[i] = voucher.copyWith(
        category: data['category'],
        itemName: data['name'],
      );
    }
  }

  Future<Map<String, int>> getUserDashboardStats(int userId) async {
    final db = await database;
    final nowIso = DateTime.now().toIso8601String();
    final sevenDaysAhead = DateTime.now().add(const Duration(days: 7)).toIso8601String();

    final activeVouchers = Sqflite.firstIntValue(await db.rawQuery(
          '''
          SELECT COUNT(*)
          FROM $vouchersTable
          WHERE status = 'active' AND date(expiry_date) >= date(?)
          ''',
          [nowIso],
        )) ??
        0;

    final redeemedCount = Sqflite.firstIntValue(await db.rawQuery(
          '''
          SELECT COUNT(*)
          FROM $redeemedTable
          WHERE user_id = ? AND redeem_status = 'Confirmed'
          ''',
          [userId],
        )) ??
        0;

    final expiringSoon = Sqflite.firstIntValue(await db.rawQuery(
          '''
          SELECT COUNT(*)
          FROM $vouchersTable
          WHERE status = 'active'
            AND date(expiry_date) BETWEEN date(?) AND date(?)
          ''',
          [nowIso, sevenDaysAhead],
        )) ??
        0;

    final activePromotions = Sqflite.firstIntValue(await db.rawQuery(
          '''
          SELECT COUNT(*)
          FROM $promotionsTable
          WHERE date(start_date) <= date(?) AND date(end_date) >= date(?)
          ''',
          [nowIso, nowIso],
        )) ??
        0;

    return {
      'activeVouchers': activeVouchers,
      'redeemed': redeemedCount,
      'expiringSoon': expiringSoon,
      'activePromotions': activePromotions,
    };
  }

  Future<Set<int>> getFavoriteVoucherIds(int userId) async {
    final db = await database;
    final rows = await db.query(
      favoriteVouchersTable,
      columns: ['voucher_id'],
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return rows.map((row) => row['voucher_id'] as int).toSet();
  }

  Future<void> addFavoriteVoucher({
    required int userId,
    required int voucherId,
  }) async {
    final db = await database;
    await db.insert(
      favoriteVouchersTable,
      {
        'user_id': userId,
        'voucher_id': voucherId,
        'added_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> removeFavoriteVoucher({
    required int userId,
    required int voucherId,
  }) async {
    final db = await database;
    await db.delete(
      favoriteVouchersTable,
      where: 'user_id = ? AND voucher_id = ?',
      whereArgs: [userId, voucherId],
    );
  }

  Future<List<String>> getDistinctShops() async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT DISTINCT shop_name FROM $vouchersTable ORDER BY shop_name COLLATE NOCASE ASC',
    );
    return rows.map((row) => row['shop_name'] as String).toList();
  }

  Future<void> updateUser(AppUser user) async {
    if (user.id == null) {
      throw ArgumentError('User id is required for update');
    }
    final db = await database;
    await db.update(
      usersTable,
      {
        'name': user.name,
        'email': user.email,
        'password': user.password,
        'notifications_enabled': user.notificationsEnabled ? 1 : 0,
      },
      where: 'user_id = ?',
      whereArgs: [user.id],
    );
  }

  Future<void> setUserNotificationsEnabled({
    required int userId,
    required bool enabled,
  }) async {
    final db = await database;
    await db.update(
      usersTable,
      {'notifications_enabled': enabled ? 1 : 0},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<List<int>> getAllUserIds() async {
    final db = await database;
    final rows = await db.query(usersTable, columns: ['user_id']);
    return rows.map((row) => row['user_id'] as int).toList();
  }

  Future<void> insertNotification({
    int? userId,
    required String title,
    required String body,
    String? type,
  }) async {
    final db = await database;
    await db.insert(
      notificationsTable,
      {
        'user_id': userId,
        'title': title,
        'body': body,
        'type': type,
        'created_at': DateTime.now().toIso8601String(),
        'is_read': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertNotificationForAllUsers({
    required String title,
    required String body,
    String? type,
  }) async {
    final userIds = await getAllUserIds();
    if (userIds.isEmpty) {
      await insertNotification(title: title, body: body, type: type);
      return;
    }
    final db = await database;
    final batch = db.batch();
    final createdAt = DateTime.now().toIso8601String();
    for (final userId in userIds) {
      batch.insert(
        notificationsTable,
        {
          'user_id': userId,
          'title': title,
          'body': body,
          'type': type,
          'created_at': createdAt,
          'is_read': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<AppNotification>> getNotifications({
    int? userId,
    bool onlyUnread = false,
  }) async {
    final db = await database;
    final filters = <String>[];
    final args = <dynamic>[];
    if (userId != null) {
      filters.add('(user_id IS NULL OR user_id = ?)');
      args.add(userId);
    }
    if (onlyUnread) {
      filters.add('is_read = 0');
    }
    final rows = await db.query(
      notificationsTable,
      where: filters.isEmpty ? null : filters.join(' AND '),
      whereArgs: filters.isEmpty ? null : args,
      orderBy: 'datetime(created_at) DESC',
    );
    return rows.map(AppNotification.fromMap).toList();
  }

  Future<void> markNotificationRead(int notificationId) async {
    final db = await database;
    await db.update(
      notificationsTable,
      {'is_read': 1},
      where: 'notification_id = ?',
      whereArgs: [notificationId],
    );
  }

  Future<void> markAllNotificationsRead(int userId) async {
    final db = await database;
    await db.update(
      notificationsTable,
      {'is_read': 1},
      where: '(user_id IS NULL OR user_id = ?)',
      whereArgs: [userId],
    );
  }

  Future<Map<String, dynamic>> getAdminHomeOverview(int adminId) async {
    final db = await database;
    final now = DateTime.now();
    final nowIso = now.toIso8601String();
    final start = now.subtract(const Duration(days: 6));

    final activeVouchers = Sqflite.firstIntValue(await db.rawQuery(
          '''
          SELECT COUNT(*) FROM $vouchersTable
          WHERE admin_id = ? AND status = 'active'
          ''',
          [adminId],
        )) ??
        0;

    final runningPromotions = Sqflite.firstIntValue(await db.rawQuery(
          '''
          SELECT COUNT(*) FROM $promotionsTable
          WHERE admin_id = ? AND date(start_date) <= date(?) AND date(end_date) >= date(?)
          ''',
          [adminId, nowIso, nowIso],
        )) ??
        0;

    final redemptionCount = Sqflite.firstIntValue(await db.rawQuery(
          '''
          SELECT COUNT(*)
          FROM $redeemedTable r
          INNER JOIN $vouchersTable v ON r.voucher_id = v.voucher_id
          WHERE v.admin_id = ? AND r.redeem_status = 'Confirmed'
          ''',
          [adminId],
        )) ??
        0;

    final revenueRow = await db.rawQuery(
      '''
      SELECT SUM(
               CASE
                 WHEN v.original_price > v.discounted_price
                 THEN v.original_price - v.discounted_price
                 ELSE 0
               END
             ) AS revenue
      FROM $redeemedTable r
      INNER JOIN $vouchersTable v ON r.voucher_id = v.voucher_id
      WHERE v.admin_id = ? AND r.redeem_status = 'Confirmed'
      ''',
      [adminId],
    );
    final revenueSaved =
        (revenueRow.first['revenue'] as num?)?.toDouble() ?? 0.0;

    final userCount = await getTotalUsers(onlyActive: true);
    final itemsCount = await getItemCount(adminId);
    final activeItems = await getActiveItemCount(adminId);

    final topShops = await db.rawQuery(
      '''
      SELECT v.shop_name AS name, COUNT(r.redeem_id) AS total
      FROM $vouchersTable v
      LEFT JOIN $redeemedTable r
        ON v.voucher_id = r.voucher_id AND r.redeem_status = 'Confirmed'
      WHERE v.admin_id = ?
      GROUP BY v.shop_name
      ORDER BY total DESC
      LIMIT 5
      ''',
      [adminId],
    );

    final topItems = await db.rawQuery(
      '''
      SELECT i.name AS name, COUNT(r.redeem_id) AS total
      FROM $itemsTable i
      LEFT JOIN $vouchersTable v ON v.item_id = i.item_id
      LEFT JOIN $redeemedTable r
        ON r.voucher_id = v.voucher_id AND r.redeem_status = 'Confirmed'
      WHERE i.admin_id = ?
      GROUP BY i.item_id
      ORDER BY total DESC
      LIMIT 5
      ''',
      [adminId],
    );

    final topCategories = await db.rawQuery(
      '''
      SELECT COALESCE(i.category, 'Uncategorized') AS category,
             COUNT(r.redeem_id) AS total
      FROM $itemsTable i
      LEFT JOIN $vouchersTable v ON v.item_id = i.item_id
      LEFT JOIN $redeemedTable r
        ON r.voucher_id = v.voucher_id AND r.redeem_status = 'Confirmed'
      WHERE i.admin_id = ?
      GROUP BY category
      ORDER BY total DESC
      LIMIT 5
      ''',
      [adminId],
    );

    final redemptionRows = await db.rawQuery(
      '''
      SELECT date(r.date_redeemed) AS day
      FROM $redeemedTable r
      INNER JOIN $vouchersTable v ON r.voucher_id = v.voucher_id
      WHERE v.admin_id = ? AND r.redeem_status = 'Confirmed'
        AND date(r.date_redeemed) >= date(?,'-180 day')
        AND date(r.date_redeemed) <= date(?)
      ''',
      [adminId, nowIso, nowIso],
    );

    final dailyMap = <String, int>{};
    final weeklyMap = <String, int>{};
    final monthlyMap = <String, int>{};

    for (final row in redemptionRows) {
      final day = row['day'] as String?;
      if (day == null) continue;
      final date = DateTime.parse(day);
      final dailyKey = DateFormat('yyyy-MM-dd').format(date);
      dailyMap[dailyKey] = (dailyMap[dailyKey] ?? 0) + 1;

      final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
      final weekKey = DateFormat('yyyy-MM-dd').format(startOfWeek);
      weeklyMap[weekKey] = (weeklyMap[weekKey] ?? 0) + 1;

      final monthKey = DateFormat('yyyy-MM').format(DateTime(date.year, date.month));
      monthlyMap[monthKey] = (monthlyMap[monthKey] ?? 0) + 1;
    }

    final dailyTrend = <Map<String, dynamic>>[];
    for (int i = 0; i <= 6; i++) {
      final datePoint = start.add(Duration(days: i));
      final key = DateFormat('yyyy-MM-dd').format(datePoint);
      dailyTrend.add({
        'label': DateFormat('dd MMM').format(datePoint),
        'total': dailyMap[key] ?? 0,
      });
    }

    final weeklyTrend = <Map<String, dynamic>>[];
    final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
    for (int i = 7; i >= 0; i--) {
      final weekStart = currentWeekStart.subtract(Duration(days: 7 * i));
      final key = DateFormat('yyyy-MM-dd').format(weekStart);
      weeklyTrend.add({
        'label': DateFormat('dd MMM').format(weekStart),
        'total': weeklyMap[key] ?? 0,
      });
    }

    final monthlyTrend = <Map<String, dynamic>>[];
    for (int i = 5; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      final key = DateFormat('yyyy-MM').format(monthDate);
      monthlyTrend.add({
        'label': DateFormat('MMM yyyy').format(monthDate),
        'total': monthlyMap[key] ?? 0,
      });
    }

    return {
      'userCount': userCount,
      'activeVouchers': activeVouchers,
      'activePromotions': runningPromotions,
      'redemptionCount': redemptionCount,
      'revenueSaved': revenueSaved,
      'itemsCount': itemsCount,
      'activeItems': activeItems,
      'topShops': topShops
          .map((row) => {
                'name': row['name'] ?? 'Unknown shop',
                'total': (row['total'] as num).toInt(),
              })
          .toList(),
      'topItems': topItems
          .map((row) => {
                'name': row['name'] ?? 'Unnamed item',
                'total': (row['total'] as num).toInt(),
              })
          .toList(),
      'topCategories': topCategories
          .map((row) => {
                'name': row['category'] ?? 'Uncategorized',
                'total': (row['total'] as num).toInt(),
              })
          .toList(),
      'trendDaily': dailyTrend,
      'trendWeekly': weeklyTrend,
      'trendMonthly': monthlyTrend,
    };
  }
}

