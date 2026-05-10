import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';

const String _appVersion = '1.0.0';
const String _appBuildNumber = '2';
const String _appPackageId = 'com.stockmanager.app';
const int _databaseSchemaVersion = 3;
const Color _inventoryColor = Color(0xFF2563EB);
const Color _stockColor = Color(0xFF0F766E);
const Color _countColor = Color(0xFFB91C1C);
const Color _warningColor = Color(0xFFB45309);
const Color _appSeedColor = Color(0xFF0F766E);
const Color _homeBackgroundColor = Color(0xFFF4F9F8);
const Color _homeInkColor = Color(0xFF0A6F78);

void main() {
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      AppDb().logError(
        area: 'flutter',
        message: details.exceptionAsString(),
        stackTrace: details.stack,
      );
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      AppDb().logError(
          area: 'platform', message: error.toString(), stackTrace: stack);
      return true;
    };
    runApp(const StockManagerApp());
  }, (error, stack) {
    AppDb()
        .logError(area: 'zone', message: error.toString(), stackTrace: stack);
  });
}

class StockManagerApp extends StatelessWidget {
  const StockManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _appSeedColor,
      brightness: Brightness.light,
    );
    return MaterialApp(
      title: 'Stock Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: _homeBackgroundColor,
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: _homeBackgroundColor,
          foregroundColor: colorScheme.onSurface,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardTheme(
          elevation: 0,
          color: Colors.white,
          surfaceTintColor: _appSeedColor.withOpacity(0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white.withOpacity(0.92),
          elevation: 0,
          indicatorColor: _homeInkColor,
          iconTheme: MaterialStateProperty.resolveWith((states) {
            final selected = states.contains(MaterialState.selected);
            return IconThemeData(
              color: selected ? Colors.white : const Color(0xFF516174),
              size: 28,
            );
          }),
          labelTextStyle: MaterialStatePropertyAll(
            const TextStyle(
              color: Color(0xFF516174),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle:
                const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12))),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  final int initialIndex;
  const HomePage({super.key, this.initialIndex = 0});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AppDb _db = AppDb();
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _db.init();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(db: _db, openTab: (i) => setState(() => _index = i)),
      CatalogScreen(db: _db),
      PosScreen(db: _db),
      ActivityLogScreen(db: _db),
    ];
    final titles = ['Home', 'Stock', 'Sell', 'Activity'];
    return MainLayout(
      title: titles[_index],
      db: _db,
      selectedIndex: _index,
      onSelected: (i) => setState(() => _index = i),
      body: pages[_index],
    );
  }
}

class MainLayout extends StatelessWidget {
  const MainLayout({
    super.key,
    required this.title,
    required this.body,
    required this.db,
    this.selectedIndex = -1,
    this.onSelected,
    this.actions,
  });

  final String title;
  final Widget body;
  final AppDb db;
  final int selectedIndex;
  final ValueChanged<int>? onSelected;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final bool isHome = selectedIndex == 0 && !canPop;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 88,
        titleSpacing: canPop ? 0 : 24,
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: _homeInkColor),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: Row(
          children: [
            if (isHome) ...[
              const Icon(Icons.assignment_turned_in_outlined,
                  color: _homeInkColor, size: 34),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                isHome ? 'Stock Manager' : title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textScaler: TextScaler.noScaling,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: _homeInkColor,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ],
        ),
        actions: [
          if (actions != null) ...actions!,
          Padding(
            padding: const EdgeInsets.only(right: 22),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => SettingsScreen(db: db)),
                );
              },
              child: Tooltip(
                message: 'Settings',
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.78),
                    border: Border.all(color: const Color(0xFFB6C8CA)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.storefront_outlined,
                      color: Color(0xFFB6C8CA), size: 24),
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE5ECEA)),
        ),
      ),
      body: body,
      bottomNavigationBar: _HomeBottomNavigationBar(
        selectedIndex: selectedIndex,
        onSelected: (i) {
          if (onSelected != null) {
            onSelected!(i);
          } else {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => HomePage(initialIndex: i)),
              (route) => false,
            );
          }
        },
      ),
    );
  }
}

class _HomeBottomNavigationBar extends StatelessWidget {
  const _HomeBottomNavigationBar({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    const items = [
      _BottomNavSpec(Icons.grid_view_outlined, Icons.grid_view, 'Home'),
      _BottomNavSpec(Icons.inventory_2_outlined, Icons.inventory_2, 'Stock'),
      _BottomNavSpec(Icons.point_of_sale_outlined, Icons.point_of_sale, 'Sell'),
      _BottomNavSpec(Icons.history_outlined, Icons.history, 'Activity'),
    ];
    return SafeArea(
      top: false,
      child: Container(
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final hasSelection =
                selectedIndex >= 0 && selectedIndex < items.length;
            final unselectedCount =
                hasSelection ? items.length - 1 : items.length;
            final selectedWidth = hasSelection
                ? (constraints.maxWidth - 58 * unselectedCount)
                    .clamp(76.0, 112.0)
                : 0.0;
            final itemWidth = hasSelection
                ? (constraints.maxWidth - selectedWidth) / unselectedCount
                : constraints.maxWidth / items.length;
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < items.length; i++)
                  _BottomNavItem(
                    spec: items[i],
                    selected: i == selectedIndex,
                    width: i == selectedIndex && hasSelection
                        ? selectedWidth
                        : itemWidth,
                    onTap: () => onSelected(i),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BottomNavSpec {
  const _BottomNavSpec(this.icon, this.selectedIcon, this.label);

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.spec,
    required this.selected,
    required this.width,
    required this.onTap,
  });

  final _BottomNavSpec spec;
  final bool selected;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final contentColor = selected ? Colors.white : const Color(0xFF516174);
    return SizedBox(
      width: width,
      child: Center(
        child: Material(
          color: selected ? _homeInkColor : Colors.transparent,
          borderRadius: BorderRadius.circular(42),
          child: InkWell(
            borderRadius: BorderRadius.circular(42),
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: selected ? width : 58,
              height: selected ? 62 : 58,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    selected ? spec.selectedIcon : spec.icon,
                    color: contentColor,
                    size: selected ? 26 : 22,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    spec.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textScaler: TextScaler.noScaling,
                    style: TextStyle(
                      color: contentColor,
                      fontSize: selected ? 12 : 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AppDb {
  static final AppDb instance = AppDb._();

  factory AppDb() => instance;

  AppDb._();

  Database? _database;
  Future<Database>? _opening;

  Future<Database> get database async {
    if (_database != null) return _database!;
    return init();
  }

  Future<Database> init() async {
    if (_database != null) return _database!;
    if (_opening != null) return _opening!;
    _opening = _open();
    try {
      _database = await _opening;
      return _database!;
    } finally {
      _opening = null;
    }
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      p.join(dbPath, 'stock_manager_v1.db'),
      version: _databaseSchemaVersion,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createUpgradeTables(db);
        }
        if (oldVersion < 3) {
          await _createLoggingTables(db);
        }
      },
    );
  }

  Future<void> close() async {
    final db = _database;
    _database = null;
    _opening = null;
    await db?.close();
  }

  Future<void> _createTables(DatabaseExecutor db) async {
    await db.execute(
        'CREATE TABLE categories(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT UNIQUE)');
    await db.execute('''CREATE TABLE items(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      category_id INTEGER,
      name TEXT,
      sku TEXT UNIQUE,
      barcode TEXT UNIQUE,
      cost REAL,
      price REAL,
      quantity INTEGER DEFAULT 0,
      FOREIGN KEY(category_id) REFERENCES categories(id)
    )''');
    await db.execute('''CREATE TABLE stock_ledger(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      item_id INTEGER,
      type TEXT,
      quantity INTEGER,
      note TEXT,
      created_at TEXT
    )''');
    await db.execute('''CREATE TABLE sales(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      total REAL,
      created_at TEXT
    )''');
    await db.execute('''CREATE TABLE sale_items(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      sale_id INTEGER,
      item_id INTEGER,
      qty INTEGER,
      price REAL,
      cost REAL
    )''');
    await _createUpgradeTables(db);
  }

  Future<void> _createUpgradeTables(DatabaseExecutor db) async {
    await db.execute('''CREATE TABLE IF NOT EXISTS attachments(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      entity_type TEXT,
      entity_id INTEGER,
      file_path TEXT,
      created_at TEXT
    )''');
    await db.execute('''CREATE TABLE IF NOT EXISTS app_settings(
      key TEXT PRIMARY KEY,
      value TEXT
    )''');
    await _createLoggingTables(db);
  }

  Future<void> _createLoggingTables(DatabaseExecutor db) async {
    await db.execute('''CREATE TABLE IF NOT EXISTS audit_logs(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      action TEXT,
      entity_type TEXT,
      entity_id INTEGER,
      details TEXT,
      created_at TEXT
    )''');
    await db.execute('''CREATE TABLE IF NOT EXISTS error_logs(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      area TEXT,
      message TEXT,
      stack_trace TEXT,
      created_at TEXT
    )''');
  }

  Future<void> addCategory(String name) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return;
    try {
      final db = await database;
      final id = await db.insert('categories', {'name': cleanName},
          conflictAlgorithm: ConflictAlgorithm.ignore);
      await _tryAudit(
        action: 'create_category',
        entityType: 'category',
        entityId: id,
        details: {'name': cleanName},
      );
    } catch (error, stack) {
      await logError(
          area: 'database.addCategory',
          message: error.toString(),
          stackTrace: stack);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> categories() async {
    final db = await database;
    return db.query('categories', orderBy: 'name ASC');
  }

  Future<int> addItem(
      Map<String, dynamic> item, List<String> photoPaths) async {
    try {
      final db = await database;
      final itemId = await db.transaction((txn) async {
        final itemId = await txn.insert('items', item,
            conflictAlgorithm: ConflictAlgorithm.abort);
        await _insertAttachments(txn, 'item', itemId, photoPaths);
        return itemId;
      });
      await _tryAudit(
        action: 'create_item',
        entityType: 'item',
        entityId: itemId,
        details: {
          'name': item['name'],
          'sku': item['sku'],
          'barcode': item['barcode'],
          'photo_count': photoPaths.length,
        },
      );
      return itemId;
    } catch (error, stack) {
      await logError(
          area: 'database.addItem',
          message: error.toString(),
          stackTrace: stack);
      rethrow;
    }
  }

  Future<void> deleteItem(int itemId) async {
    try {
      final db = await database;
      await db.transaction((txn) async {
        await txn.delete('attachments',
            where: 'entity_type=? AND entity_id=?',
            whereArgs: ['item', itemId]);
        await txn.delete('items', where: 'id=?', whereArgs: [itemId]);
      });
      await _tryAudit(
        action: 'delete_item',
        entityType: 'item',
        entityId: itemId,
        details: {'item_id': itemId},
      );
    } catch (error, stack) {
      await logError(
          area: 'database.deleteItem',
          message: error.toString(),
          stackTrace: stack);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> items() async {
    final db = await database;
    return db.rawQuery('''
      SELECT i.*, c.name as category,
        (SELECT COUNT(*) FROM attachments a WHERE a.entity_type='item' AND a.entity_id=i.id) as photo_count
      FROM items i LEFT JOIN categories c ON c.id=i.category_id
      ORDER BY i.name ASC
    ''');
  }

  Future<void> updateItemPrice(int itemId, double newPrice) async {
    try {
      final db = await database;
      final result = await db.transaction((txn) async {
        final item = (await txn.query('items',
                columns: ['name', 'price'], where: 'id=?', whereArgs: [itemId]))
            .first;
        final oldPrice = (item['price'] as num).toDouble();
        await txn.update('items', {'price': newPrice},
            where: 'id=?', whereArgs: [itemId]);
        return {'itemName': item['name'], 'oldPrice': oldPrice};
      });
      await _tryAudit(
        action: 'update_price',
        entityType: 'item',
        entityId: itemId,
        details: {
          'item_name': result['itemName'],
          'old_price': result['oldPrice'],
          'new_price': newPrice,
        },
      );
    } catch (error, stack) {
      await logError(
          area: 'database.updateItemPrice',
          message: error.toString(),
          stackTrace: stack);
      rethrow;
    }
  }

  Future<List<String>> itemPhotoPaths(int itemId) async {
    final db = await database;
    final rows = await db.query(
      'attachments',
      columns: ['file_path'],
      where: 'entity_type=? AND entity_id=?',
      whereArgs: ['item', itemId],
      orderBy: 'created_at DESC',
    );
    return rows.map((row) => '${row['file_path']}').toList();
  }

  Future<List<Map<String, dynamic>>> itemAuditLogs(int itemId,
      {int limit = 25}) async {
    final rows = await auditLogs();
    final filtered = rows.where((row) {
      if (row['entity_type'] == 'item' && row['entity_id'] == itemId) {
        return true;
      }
      final details = _decodeAuditDetails(row['details']);
      if (details['item_id'] == itemId) return true;
      final lines = details['lines'];
      if (lines is List) {
        return lines.any((line) => line is Map && line['item_id'] == itemId);
      }
      return false;
    }).toList();
    return filtered.take(limit).toList();
  }

  Future<Map<String, int>> counts() async {
    final db = await database;
    final itemRows = await db.rawQuery(
        'SELECT COUNT(*) as count, IFNULL(SUM(quantity),0) as qty FROM items');
    final categoryRows =
        await db.rawQuery('SELECT COUNT(*) as count FROM categories');
    final lowRows = await db
        .rawQuery('SELECT COUNT(*) as count FROM items WHERE quantity <= 2');
    return {
      'items': itemRows.first['count'] as int,
      'stock': itemRows.first['qty'] as int,
      'categories': categoryRows.first['count'] as int,
      'low': lowRows.first['count'] as int,
    };
  }

  Future<void> intake({
    required int itemId,
    required int qty,
    required DateTime date,
    required String note,
    required List<String> photoPaths,
  }) async {
    if (qty <= 0) throw Exception('Quantity must be greater than zero');
    try {
      final db = await database;
      final result = await db.transaction((txn) async {
        final item = (await txn.query('items',
                columns: ['name'], where: 'id=?', whereArgs: [itemId]))
            .first;
        await txn.rawUpdate(
            'UPDATE items SET quantity = quantity + ? WHERE id = ?',
            [qty, itemId]);
        final ledgerId = await txn.insert('stock_ledger', {
          'item_id': itemId,
          'type': 'intake',
          'quantity': qty,
          'note': note.trim(),
          'created_at': date.toIso8601String(),
        });
        await _insertAttachments(txn, 'stock_intake', ledgerId, photoPaths);
        return {'ledgerId': ledgerId, 'itemName': item['name']};
      });
      await _tryAudit(
        action: 'receive_stock',
        entityType: 'stock',
        entityId: result['ledgerId'] as int,
        details: {
          'item_id': itemId,
          'item_name': result['itemName'],
          'quantity': qty,
          'date': date.toIso8601String(),
          'photo_count': photoPaths.length,
        },
      );
    } catch (error, stack) {
      await logError(
          area: 'database.intake',
          message: error.toString(),
          stackTrace: stack);
      rethrow;
    }
  }

  Future<void> auditAdjust(
      {required int itemId,
      required int countedQty,
      required String reason,
      required List<String> photoPaths}) async {
    try {
      final db = await database;
      final result = await db.transaction((txn) async {
        final item = (await txn.query('items',
                columns: ['name', 'quantity'],
                where: 'id=?',
                whereArgs: [itemId]))
            .first;
        final current = item['quantity'] as int;
        final delta = countedQty - current;
        await txn.update('items', {'quantity': countedQty},
            where: 'id=?', whereArgs: [itemId]);
        final ledgerId = await txn.insert('stock_ledger', {
          'item_id': itemId,
          'type': 'audit_adjustment',
          'quantity': delta,
          'note': reason.trim().isEmpty ? 'Count correction' : reason.trim(),
          'created_at': DateTime.now().toIso8601String(),
        });
        await _insertAttachments(txn, 'stock_count', ledgerId, photoPaths);
        return {
          'ledgerId': ledgerId,
          'previous': current,
          'delta': delta,
          'itemName': item['name']
        };
      });
      await _tryAudit(
        action: 'count_stock',
        entityType: 'stock',
        entityId: result['ledgerId'] as int,
        details: {
          'item_id': itemId,
          'item_name': result['itemName'],
          'previous_quantity': result['previous'],
          'counted_quantity': countedQty,
          'delta': result['delta'],
          'reason': reason.trim(),
          'photo_count': photoPaths.length,
        },
      );
    } catch (error, stack) {
      await logError(
          area: 'database.auditAdjust',
          message: error.toString(),
          stackTrace: stack);
      rethrow;
    }
  }

  Future<void> sell(List<Map<String, dynamic>> lines) async {
    try {
      final db = await database;
      final result = await db.transaction((txn) async {
        double total = 0;
        for (final line in lines) {
          final itemId = line['item_id'] as int;
          final qty = line['qty'] as int;
          final item =
              (await txn.query('items', where: 'id=?', whereArgs: [itemId]))
                  .first;
          final current = item['quantity'] as int;
          if (current < qty) {
            throw Exception('Not enough stock for ${item['name']}');
          }
          final price = (item['price'] as num).toDouble();
          final cost = (item['cost'] as num).toDouble();
          total += price * qty;
          await txn.rawUpdate(
              'UPDATE items SET quantity = quantity - ? WHERE id = ?',
              [qty, itemId]);
          await txn.insert('stock_ledger', {
            'item_id': itemId,
            'type': 'sale',
            'quantity': -qty,
            'note': 'POS sale',
            'created_at': DateTime.now().toIso8601String(),
          });
          line['price'] = price;
          line['cost'] = cost;
          line['name'] = item['name'];
        }
        final saleId = await txn.insert('sales',
            {'total': total, 'created_at': DateTime.now().toIso8601String()});
        for (final line in lines) {
          await txn.insert('sale_items', {
            'sale_id': saleId,
            'item_id': line['item_id'],
            'qty': line['qty'],
            'price': line['price'],
            'cost': line['cost'],
          });
        }
        return {'saleId': saleId, 'total': total};
      });
      await _tryAudit(
        action: 'create_sale',
        entityType: 'sale',
        entityId: result['saleId'] as int,
        details: {
          'total': result['total'],
          'line_count': lines.length,
          'lines': lines,
        },
      );
    } catch (error, stack) {
      await logError(
          area: 'database.sell', message: error.toString(), stackTrace: stack);
      rethrow;
    }
  }

  Future<Map<String, double>> pnl({DateTime? date}) async {
    final db = await database;
    String where = "";
    List<dynamic> args = [];
    if (date != null) {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      where = "WHERE created_at LIKE ?";
      args.add('$dateStr%');
    }

    final salesRows = await db.rawQuery(
        'SELECT IFNULL(SUM(total),0) as revenue FROM sales $where', args);

    String cogsWhere = "";
    if (date != null) {
      cogsWhere = "WHERE s.created_at LIKE ?";
    }

    final cogsRows = await db.rawQuery('''
      SELECT IFNULL(SUM(si.qty * si.cost),0) as cogs
      FROM sale_items si JOIN sales s ON s.id=si.sale_id
      $cogsWhere
    ''', args);

    final revenue = (salesRows.first['revenue'] as num).toDouble();
    final cogs = (cogsRows.first['cogs'] as num).toDouble();
    return {'revenue': revenue, 'cogs': cogs, 'profit': revenue - cogs};
  }

  Future<double> totalInvestment({DateTime? date}) async {
    final db = await database;
    if (date == null) {
      final result =
          await db.rawQuery('SELECT SUM(quantity * cost) as total FROM items');
      return (result.first['total'] as num?)?.toDouble() ?? 0.0;
    } else {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final result = await db.rawQuery('''
        SELECT SUM(sl.quantity * i.cost) as total
        FROM stock_ledger sl
        JOIN items i ON sl.item_id = i.id
        WHERE sl.type = 'intake' AND sl.created_at LIKE ?
      ''', ['$dateStr%']);
      return (result.first['total'] as num?)?.toDouble() ?? 0.0;
    }
  }

  Future<void> setStorageChoice(String value) async {
    try {
      final db = await database;
      await db.insert('app_settings', {'key': 'storage_choice', 'value': value},
          conflictAlgorithm: ConflictAlgorithm.replace);
      await _tryAudit(
        action: 'change_storage_choice',
        entityType: 'app_settings',
        entityId: null,
        details: {'storage_choice': value},
      );
    } catch (error, stack) {
      await logError(
          area: 'database.setStorageChoice',
          message: error.toString(),
          stackTrace: stack);
      rethrow;
    }
  }

  Future<String> storageChoice() async {
    final db = await database;
    final rows = await db
        .query('app_settings', where: 'key=?', whereArgs: ['storage_choice']);
    if (rows.isEmpty) return 'device';
    return rows.first['value'] as String;
  }

  Future<File> createBackupFile() async {
    final db = await database;
    final tables = [
      'categories',
      'items',
      'stock_ledger',
      'sales',
      'sale_items',
      'attachments',
      'app_settings',
      'audit_logs',
      'error_logs'
    ];
    final payload = <String, dynamic>{
      'app': 'StockManager',
      'schemaVersion': _databaseSchemaVersion,
      'appVersion': _appVersion,
      'appBuildNumber': _appBuildNumber,
      'createdAt': DateTime.now().toIso8601String(),
      'tables': <String, dynamic>{},
    };
    for (final table in tables) {
      payload['tables'][table] = await db.query(table);
    }
    final dir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(p.join(dir.path, 'backups'));
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file =
        File(p.join(backupDir.path, 'stockmanager_backup_$stamp.json'));
    await file
        .writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
    await _tryAudit(
      action: 'create_backup',
      entityType: 'backup',
      entityId: null,
      details: {'path': file.path, 'table_count': tables.length},
    );
    return file;
  }

  Future<List<String>> copyPhotos(List<XFile> files) async {
    final dir = await getApplicationDocumentsDirectory();
    final photoDir = Directory(p.join(dir.path, 'photos'));
    if (!await photoDir.exists()) {
      await photoDir.create(recursive: true);
    }
    final copied = <String>[];
    for (final file in files) {
      final source = File(file.path);
      if (!await source.exists()) continue;
      final ext =
          p.extension(file.path).isEmpty ? '.jpg' : p.extension(file.path);
      final target = File(p.join(
          photoDir.path, '${DateTime.now().microsecondsSinceEpoch}$ext'));
      await source.copy(target.path);
      copied.add(target.path);
    }
    if (copied.isNotEmpty) {
      await _tryAudit(
        action: 'copy_photos',
        entityType: 'attachment',
        entityId: null,
        details: {'photo_count': copied.length},
      );
    }
    return copied;
  }

  Future<void> logError({
    required String area,
    required String message,
    StackTrace? stackTrace,
  }) async {
    try {
      final db = await database;
      await db.insert('error_logs', {
        'area': area,
        'message': message,
        'stack_trace': stackTrace?.toString(),
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Diagnostics must never create a secondary failure path.
    }
  }

  Future<List<Map<String, dynamic>>> auditLogs({int? limit}) async {
    final db = await database;
    return db.query('audit_logs', orderBy: 'created_at DESC', limit: limit);
  }

  Future<List<Map<String, dynamic>>> recentAuditLogs({int limit = 25}) async {
    return auditLogs(limit: limit);
  }

  Future<List<Map<String, dynamic>>> searchAuditLogs(
      {String? query, DateTime? date, String? actionKeyword}) async {
    final db = await database;
    String? where;
    List<dynamic>? whereArgs;

    if (query != null && query.trim().isNotEmpty) {
      final q = '%${query.trim()}%';
      where = "(action LIKE ? OR entity_type LIKE ? OR details LIKE ?)";
      whereArgs = [q, q, q];
    }

    if (date != null) {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      const dateWhere = "created_at LIKE ?";
      final dateArg = "$dateStr%";
      if (where == null) {
        where = dateWhere;
        whereArgs = [dateArg];
      } else {
        where = "$where AND $dateWhere";
        whereArgs!.add(dateArg);
      }
    }

    if (actionKeyword != null) {
      const actionWhere = "(action LIKE ? OR entity_type LIKE ?)";
      final actionArg = "%$actionKeyword%";
      if (where == null) {
        where = actionWhere;
        whereArgs = [actionArg, actionArg];
      } else {
        where = "$where AND $actionWhere";
        whereArgs!.addAll([actionArg, actionArg]);
      }
    }

    return db.query('audit_logs',
        where: where, whereArgs: whereArgs, orderBy: 'created_at DESC');
  }

  Future<List<Map<String, dynamic>>> recentErrorLogs({int limit = 25}) async {
    final db = await database;
    return db.query('error_logs', orderBy: 'created_at DESC', limit: limit);
  }

  Future<void> _tryAudit({
    required String action,
    required String entityType,
    required int? entityId,
    required Map<String, dynamic> details,
  }) async {
    try {
      final db = await database;
      await db.insert('audit_logs', {
        'action': action,
        'entity_type': entityType,
        'entity_id': entityId,
        'details': jsonEncode(details),
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Audit logging is best-effort so the original action remains complete.
    }
  }

  Future<void> _insertAttachments(DatabaseExecutor txn, String entityType,
      int entityId, List<String> paths) async {
    for (final path in paths) {
      await txn.insert('attachments', {
        'entity_type': entityType,
        'entity_id': entityId,
        'file_path': path,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.db, required this.openTab});
  final AppDb db;
  final ValueChanged<int> openTab;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Object>>(
      future: Future.wait([
        db.counts(),
        db.recentAuditLogs(limit: 10),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final counts = snapshot.data![0] as Map<String, int>;
        final recentAuditLogs = snapshot.data![1] as List<Map<String, dynamic>>;
        final hasItems = counts['items']! > 0;
        return ListView(
          padding: EdgeInsets.zero,
          children: [
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: _HomeStatCard(
                      value: '${counts['items']}',
                      label: 'PRODUCT\nTYPES',
                      color: _homeInkColor,
                      onTap: () => _openInventorySummary(
                        context,
                        title: 'Product types',
                        filter: _InventorySummaryFilter.all,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _HomeStatCard(
                      value: '${counts['stock']}',
                      label: 'TOTAL\nITEMS',
                      color: Colors.black,
                      onTap: () => _openInventorySummary(
                        context,
                        title: 'Total items',
                        filter: _InventorySummaryFilter.inStock,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _HomeStatCard(
                      value: '${counts['low']}',
                      label: 'NEEDS\nRESTOCK',
                      color: _countColor,
                      backgroundColor: const Color(0xFFFFF5F3),
                      borderColor: const Color(0xFFF3D5D1),
                      onTap: () => _openInventorySummary(
                        context,
                        title: 'Needs restock',
                        filter: _InventorySummaryFilter.lowStock,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: _PrimaryHomeAction(
                      label: 'Check Inventory',
                      description: 'See what is in stock',
                      icon: Icons.inventory_2_outlined,
                      color: _inventoryColor,
                      textColor: Colors.white,
                      onTap: () => openTab(1),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _PrimaryHomeAction(
                      label: 'Make a Sale',
                      description: 'Record customer purchase',
                      icon: Icons.point_of_sale,
                      color: _homeInkColor,
                      textColor: Colors.white,
                      onTap: () => openTab(2),
                    ),
                  ),
                ],
              ),
            ),
            if (!hasItems) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _SetupGuide(
                  openTab: openTab,
                  onReceive: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => IntakeScreen(db: db)),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            _RecentAuditSection(
              rows: recentAuditLogs,
              onMore: () => openTab(3),
            ),
            const SizedBox(height: 40),
          ],
        );
      },
    );
  }

  void _openInventorySummary(
    BuildContext context, {
    required String title,
    required _InventorySummaryFilter filter,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InventorySummaryScreen(
          db: db,
          title: title,
          filter: filter,
        ),
      ),
    );
  }
}

class _HomeStatCard extends StatelessWidget {
  const _HomeStatCard({
    required this.value,
    required this.label,
    required this.color,
    required this.onTap,
    this.backgroundColor = Colors.white,
    this.borderColor = const Color(0xFFD9E1DF),
  });

  final String value;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 106,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                maxLines: 1,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w500,
                      height: 1,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryHomeAction extends StatelessWidget {
  const _PrimaryHomeAction({
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  final String label;
  final String description;
  final IconData icon;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.2),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 156,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black.withOpacity(0.08)),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: textColor, size: 40),
              const SizedBox(height: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      flex: 5,
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textScaler: TextScaler.noScaling,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                              height: 1.05,
                            ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Flexible(
                      flex: 4,
                      child: Text(
                        description,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textScaler: TextScaler.noScaling,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: textColor.withOpacity(0.86),
                              height: 1.08,
                            ),
                      ),
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
}

class _RecentAuditSection extends StatelessWidget {
  const _RecentAuditSection({required this.rows, required this.onMore});

  final List<Map<String, dynamic>> rows;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final visibleRows = rows.take(10).toList();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.zero,
        border: const Border.symmetric(
          horizontal: BorderSide(color: Color(0xFFD9E1DF)),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _homeInkColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.manage_history_outlined,
                    color: _homeInkColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Recent activity',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                ),
              ),
              TextButton(
                onPressed: onMore,
                child: const Text('More'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (visibleRows.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
              child: Text(
                'No audit activity yet.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF526070),
                    ),
              ),
            )
          else
            ...visibleRows.map(
              (row) => _RecentAuditTile(row: row),
            ),
        ],
      ),
    );
  }
}

class _RecentAuditTile extends StatelessWidget {
  const _RecentAuditTile({required this.row});

  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) {
    final style = _activityStyle(row['action']);
    final entity = '${row['entity_type'] ?? 'record'}';
    final entityId = row['entity_id'];
    final subtitle = [
      _formatLogDate(row['created_at']),
      if (entityId != null) '$entity #$entityId' else entity,
    ].join(' | ');
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Activity Details'),
            contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: _ActivityContent(row: row),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: style.color.withOpacity(0.12),
              foregroundColor: style.color,
              child: Icon(style.icon, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatActionName(row['action']),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF526070),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetupGuide extends StatelessWidget {
  const _SetupGuide({required this.openTab, required this.onReceive});
  final ValueChanged<int> openTab;
  final VoidCallback onReceive;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Start with three simple steps',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _StepTile(
                number: '1',
                text: 'Create one category, like Rice, Snacks, or Soap.',
                onTap: () => openTab(1)),
            _StepTile(
                number: '2',
                text: 'Add your first item with price and optional photos.',
                onTap: () => openTab(1)),
            _StepTile(
                number: '3',
                text: 'Receive opening stock so sales and counts are accurate.',
                onTap: onReceive),
          ],
        ),
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile(
      {required this.number, required this.text, required this.onTap});
  final String number;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: _appSeedColor.withOpacity(0.12),
        foregroundColor: _appSeedColor,
        child: Text(number),
      ),
      title: Text(text),
      trailing: const Icon(Icons.chevron_right, color: _appSeedColor),
      onTap: onTap,
    );
  }
}

enum _InventorySummaryFilter { all, inStock, lowStock }

class InventorySummaryScreen extends StatefulWidget {
  const InventorySummaryScreen({
    super.key,
    required this.db,
    required this.title,
    required this.filter,
  });

  final AppDb db;
  final String title;
  final _InventorySummaryFilter filter;

  @override
  State<InventorySummaryScreen> createState() => _InventorySummaryScreenState();
}

class _InventorySummaryScreenState extends State<InventorySummaryScreen> {
  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: widget.title,
      db: widget.db,
      selectedIndex: 1,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: widget.db.items(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = _filterItems(snapshot.data!);
          final totalQty = items.fold<int>(
            0,
            (sum, item) => sum + (item['quantity'] as int),
          );
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            children: [
              _InventorySummaryHeader(
                title: widget.title,
                itemCount: items.length,
                totalQty: totalQty,
                color: _summaryColor,
              ),
              const SizedBox(height: 16),
              if (items.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_emptyMessage),
                  ),
                )
              else
                ...items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 1),
                    child: _InventoryItemTile(
                      db: widget.db,
                      item: item,
                      onChanged: () => setState(() {}),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _filterItems(List<Map<String, dynamic>> items) {
    switch (widget.filter) {
      case _InventorySummaryFilter.inStock:
        return items.where((item) => (item['quantity'] as int) > 0).toList();
      case _InventorySummaryFilter.lowStock:
        return items.where((item) => (item['quantity'] as int) <= 2).toList();
      case _InventorySummaryFilter.all:
        return items;
    }
  }

  Color get _summaryColor {
    switch (widget.filter) {
      case _InventorySummaryFilter.inStock:
        return _stockColor;
      case _InventorySummaryFilter.lowStock:
        return _warningColor;
      case _InventorySummaryFilter.all:
        return _inventoryColor;
    }
  }

  String get _emptyMessage {
    switch (widget.filter) {
      case _InventorySummaryFilter.inStock:
        return 'No items currently have stock.';
      case _InventorySummaryFilter.lowStock:
        return 'No low stock items right now.';
      case _InventorySummaryFilter.all:
        return 'No items have been added yet.';
    }
  }
}

class _InventorySummaryHeader extends StatelessWidget {
  const _InventorySummaryHeader({
    required this.title,
    required this.itemCount,
    required this.totalQty,
    required this.color,
  });

  final String title;
  final int itemCount;
  final int totalQty;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      color: _softTint(color),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.14),
              foregroundColor: color,
              child: const Icon(Icons.inventory_2_outlined),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text('$itemCount items | $totalQty units in stock'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key, required this.db});
  final AppDb db;

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  String query = '';

  Future<void> _addCategory() async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Create category'),
        content: TextField(
            controller: controller,
            decoration: const InputDecoration(
                labelText: 'Category name', hintText: 'Example: Snacks')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              await widget.db.addCategory(controller.text);
              if (context.mounted) Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _addItem({String? initialBarcode}) async {
    final cats = await widget.db.categories();
    if (cats.isEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Create a category first. Example: Grocery, Drinks, Stationery.')));
      return;
    }
    int categoryId = cats.first['id'] as int;
    final name = TextEditingController();
    final sku = TextEditingController();
    final barcode = TextEditingController(text: initialBarcode);
    final cost = TextEditingController();
    final price = TextEditingController();
    final photos = <String>[];
    await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setS) => AlertDialog(
          title: const Text('Add item'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    value: categoryId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: cats
                        .map((e) => DropdownMenuItem(
                            value: e['id'] as int,
                            child: Text(e['name'] as String)))
                        .toList(),
                    onChanged: (v) => setS(() => categoryId = v!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                      controller: name,
                      decoration: const InputDecoration(
                          labelText: 'Item name',
                          hintText: 'Example: 1 kg sugar')),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: TextField(
                              controller: sku,
                              decoration: const InputDecoration(
                                  labelText: 'SKU or code'))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: TextField(
                              controller: barcode,
                              decoration:
                                  const InputDecoration(labelText: 'Barcode'))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: TextField(
                              controller: cost,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                  labelText: 'Cost price'))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: TextField(
                              controller: price,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                  labelText: 'Selling price'))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  PhotoPicker(
                    db: widget.db,
                    paths: photos,
                    onChanged: () => setS(() {}),
                    label: 'Item photos',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (name.text.trim().isEmpty) return;
                await widget.db.addItem({
                  'category_id': categoryId,
                  'name': name.text.trim(),
                  'sku': sku.text.trim().isEmpty ? null : sku.text.trim(),
                  'barcode':
                      barcode.text.trim().isEmpty ? null : barcode.text.trim(),
                  'cost': double.tryParse(cost.text) ?? 0,
                  'price': double.tryParse(price.text) ?? 0,
                  'quantity': 0,
                }, photos);
                if (context.mounted) Navigator.pop(context);
                setState(() {});
              },
              child: const Text('Save item'),
            ),
          ],
        ),
      ),
    );
  }

  void _showScanner(List<Map<String, dynamic>> allItems) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text('Scan Barcode',
                      style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: MobileScanner(
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      if (barcode.rawValue != null) {
                        final scannedValue = barcode.rawValue!;
                        Navigator.pop(context);

                        final existingItem = allItems
                            .cast<Map<String, dynamic>?>()
                            .firstWhere((e) => e?['barcode'] == scannedValue,
                                orElse: () => null);

                        if (existingItem != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'Item "${existingItem['name']}" already exists.')),
                          );
                        } else {
                          _addItem(initialBarcode: scannedValue);
                        }
                        break;
                      }
                    }
                  },
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Scan a barcode to find or add an item'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: widget.db.items(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final allItems = snapshot.data!;
        final data = allItems.where((item) {
          final q = query.toLowerCase();
          return q.isEmpty ||
              '${item['name']}'.toLowerCase().contains(q) ||
              '${item['sku']}'.toLowerCase().contains(q) ||
              '${item['barcode']}'.toLowerCase().contains(q);
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: TextField(
                decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.qr_code_scanner),
                      onPressed: () => _showScanner(allItems),
                    ),
                    labelText: 'Search items...'),
                onChanged: (value) => setState(() => query = value),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                            onPressed: _addCategory,
                            icon: const Icon(Icons.category, size: 20),
                            label: const Text('Category',
                                style: TextStyle(fontSize: 13))),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                            onPressed: _addItem,
                            icon: const Icon(Icons.add, size: 20),
                            label: const Text('Item',
                                style: TextStyle(fontSize: 13))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                            onPressed: () => Navigator.of(context)
                                .push(
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          IntakeScreen(db: widget.db)),
                                )
                                .then((_) => setState(() {})),
                            icon: const Icon(Icons.input, size: 20),
                            label: const Text('Receive',
                                style: TextStyle(fontSize: 13))),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                            onPressed: () => Navigator.of(context)
                                .push(
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          AuditScreen(db: widget.db)),
                                )
                                .then((_) => setState(() {})),
                            icon: const Icon(Icons.fact_check, size: 20),
                            label: const Text('Audit',
                                style: TextStyle(fontSize: 13))),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (data.isEmpty)
              const Expanded(
                  child: EmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'No items yet',
                      message:
                          'Create a category, then add the first product you sell.'))
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  itemCount: data.length,
                  itemBuilder: (_, i) {
                    final item = data[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 1),
                      child: _InventoryItemTile(
                        db: widget.db,
                        item: item,
                        onChanged: () => setState(() {}),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class _InventoryItemTile extends StatelessWidget {
  const _InventoryItemTile(
      {required this.db, required this.item, this.onChanged});

  final AppDb db;
  final Map<String, dynamic> item;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    final quantity = item['quantity'] as int;
    final stockColor = _stockLevelColor(quantity);
    return Card(
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: stockColor.withOpacity(0.12),
          foregroundColor: stockColor,
          child: Text('$quantity'),
        ),
        title: Text(item['name'] as String),
        subtitle: Text(
            '${item['category'] ?? 'No category'} | SKU: ${item['sku'] ?? '-'} | Barcode: ${item['barcode'] ?? '-'}'),
        onTap: () => Navigator.of(context)
            .push(
              MaterialPageRoute(
                builder: (_) => ItemDetailScreen(db: db, item: item),
              ),
            )
            .then((_) => onChanged?.call()),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('Buy: ${_money((item['cost'] as num).toDouble())}',
                style: Theme.of(context).textTheme.bodySmall),
            Text('Sell: ${_money((item['price'] as num).toDouble())}',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            if ((item['photo_count'] as int) > 0)
              Text('${item['photo_count']} photos',
                  style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

class ItemDetailScreen extends StatefulWidget {
  const ItemDetailScreen({super.key, required this.db, required this.item});
  final AppDb db;
  final Map<String, dynamic> item;

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  late Future<List<Object>> _data;
  late double _currentPrice;

  @override
  void initState() {
    super.initState();
    _currentPrice = (widget.item['price'] as num).toDouble();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _data = Future.wait([
        widget.db.itemPhotoPaths(widget.item['id'] as int),
        widget.db.itemAuditLogs(widget.item['id'] as int),
      ]);
    });
  }

  Future<void> _editPrice() async {
    final controller = TextEditingController(text: _currentPrice.toString());
    final newPrice = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Price'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'New Selling Price',
            prefixText: '₹ ',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null) {
                Navigator.pop(context, val);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (newPrice != null && newPrice != _currentPrice) {
      await widget.db.updateItemPrice(widget.item['id'] as int, newPrice);
      setState(() {
        _currentPrice = newPrice;
      });
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Price updated successfully')),
        );
      }
    }
  }

  Future<void> _deleteItem() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text(
            'Are you sure you want to delete "${widget.item['name']}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.db.deleteItem(widget.item['id'] as int);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: '${widget.item['name']}',
      db: widget.db,
      selectedIndex: 1,
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: _deleteItem,
          tooltip: 'Delete item',
        ),
      ],
      body: FutureBuilder<List<Object>>(
        future: _data,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final photos = snapshot.data![0] as List<String>;
          final logs = snapshot.data![1] as List<Map<String, dynamic>>;

          final displayItem = Map<String, dynamic>.from(widget.item);
          displayItem['price'] = _currentPrice;

          return ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              _ItemDetailHeader(
                item: displayItem,
                photos: photos,
                onEditPrice: _editPrice,
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text('Recent item activity',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              if (logs.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                          'No activity has been logged for this item yet.'),
                    ),
                  ),
                )
              else
                ...logs.map(
                  (row) => Padding(
                    padding: const EdgeInsets.only(bottom: 1),
                    child: _ActivityCard(row: row),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ItemDetailHeader extends StatelessWidget {
  const _ItemDetailHeader({
    required this.item,
    required this.photos,
    this.onEditPrice,
  });
  final Map<String, dynamic> item;
  final List<String> photos;
  final VoidCallback? onEditPrice;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (photos.isEmpty)
            Container(
              height: 210,
              width: double.infinity,
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: const Icon(Icons.photo_camera_back_outlined, size: 56),
            )
          else
            SizedBox(
              height: 230,
              child: PageView.builder(
                itemCount: photos.length,
                itemBuilder: (context, index) => Image.file(
                  File(photos[index]),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image_outlined, size: 48),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${item['name']}',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ActivityMetaChip(
                        icon: Icons.inventory_2_outlined,
                        label: '${item['quantity']} in stock'),
                    _ActivityMetaChip(
                        icon: Icons.sell_outlined,
                        label: _money((item['price'] as num).toDouble())),
                    _ActivityMetaChip(
                        icon: Icons.category_outlined,
                        label: '${item['category'] ?? 'No category'}'),
                  ],
                ),
                const SizedBox(height: 16),
                _ItemFactRow(label: 'SKU', value: '${item['sku'] ?? '-'}'),
                _ItemFactRow(
                    label: 'Barcode', value: '${item['barcode'] ?? '-'}'),
                _ItemFactRow(
                    label: 'Cost price',
                    value: _money((item['cost'] as num).toDouble())),
                _ItemFactRow(
                  label: 'Selling price',
                  value: _money((item['price'] as num).toDouble()),
                  trailing: onEditPrice != null
                      ? IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: onEditPrice,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Edit price',
                        )
                      : null,
                ),
                _ItemFactRow(
                    label: 'Photos captured', value: '${photos.length}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemFactRow extends StatelessWidget {
  const _ItemFactRow({required this.label, required this.value, this.trailing});
  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(value)),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class IntakeScreen extends StatefulWidget {
  const IntakeScreen({super.key, required this.db});
  final AppDb db;

  @override
  State<IntakeScreen> createState() => _IntakeScreenState();
}

class _IntakeScreenState extends State<IntakeScreen> {
  int? selectedItem;
  final qty = TextEditingController();
  final note = TextEditingController();
  final photos = <String>[];
  DateTime date = DateTime.now();

  @override
  void dispose() {
    qty.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: date,
    );
    if (picked != null) setState(() => date = picked);
  }

  Future<void> _saveStockEntry() async {
    try {
      await widget.db.intake(
          itemId: selectedItem!,
          qty: int.tryParse(qty.text) ?? 0,
          date: date,
          note: note.text,
          photoPaths: photos);
      qty.clear();
      note.clear();
      photos.clear();
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Stock received')));
      }
      setState(() {});
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Receive Stock',
      db: widget.db,
      selectedIndex: 1,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: widget.db.items(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final items = snapshot.data!;
          selectedItem ??= items.isNotEmpty ? items.first['id'] as int : null;
          if (items.isEmpty)
            return const EmptyState(
                icon: Icons.add_box_outlined,
                title: 'Add items first',
                message:
                    'Stock can be received after your product list is created.');
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'Use this when new goods arrive from a supplier or when you enter opening stock.',
                style: TextStyle(
                  color: Color(0xFF1F2D32),
                  fontSize: 18,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<int>(
                value: selectedItem,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Select Item'),
                items: items
                    .map((e) => DropdownMenuItem(
                        value: e['id'] as int,
                        child:
                            Text('${e['name']} (${e['quantity']} in stock)')))
                    .toList(),
                onChanged: (v) => setState(() => selectedItem = v),
              ),
              const SizedBox(height: 20),
              TextField(
                  controller: qty,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantity to Add',
                    hintText: 'Enter quantity',
                  )),
              const SizedBox(height: 20),
              TextField(
                  controller: note,
                  minLines: 3,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Note',
                    hintText: 'Supplier, invoice, etc.',
                  )),
              const SizedBox(height: 20),
              _IntakeDateCard(date: date, onChange: _pickDate),
              const SizedBox(height: 24),
              PhotoPicker(
                  db: widget.db,
                  paths: photos,
                  onChanged: () => setState(() {}),
                  label: 'Bill or Delivery Photos'),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _saveStockEntry,
                icon: const Icon(Icons.save),
                label: const Text('Save Stock Entry'),
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }
}

class _IntakeDateCard extends StatelessWidget {
  const _IntakeDateCard({required this.date, required this.onChange});

  final DateTime date;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.calendar_today),
        title: const Text('Entry Date'),
        subtitle: Text(DateFormat.yMMMMd().format(date)),
        trailing: TextButton(onPressed: onChange, child: const Text('Change')),
      ),
    );
  }
}

class PosScreen extends StatefulWidget {
  const PosScreen({super.key, required this.db});
  final AppDb db;

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final Map<int, int> cart = {};
  String query = '';
  int? selectedCategoryId;

  void _handleScannedBarcode(
      String barcode, List<Map<String, dynamic>> allItems) {
    final item = allItems
        .cast<Map<String, dynamic>?>()
        .firstWhere((e) => e?['barcode'] == barcode, orElse: () => null);

    if (item != null) {
      final id = item['id'] as int;
      setState(() {
        cart[id] = (cart[id] ?? 0) + 1;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${item['name']} to cart'),
          duration: const Duration(seconds: 1),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No item found with barcode: $barcode')),
      );
    }
  }

  void _showScanner(List<Map<String, dynamic>> allItems) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text('Scan Barcode',
                      style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: MobileScanner(
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      if (barcode.rawValue != null) {
                        Navigator.pop(context);
                        _handleScannedBarcode(barcode.rawValue!, allItems);
                        break;
                      }
                    }
                  },
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Position the barcode inside the camera view'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Object>>(
      future: Future.wait([
        widget.db.items(),
        widget.db.categories(),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final allItems = snapshot.data![0] as List<Map<String, dynamic>>;
        final allCategories = snapshot.data![1] as List<Map<String, dynamic>>;

        final items = allItems.where((item) {
          final q = query.toLowerCase();
          final matchesQuery = q.isEmpty ||
              '${item['name']}'.toLowerCase().contains(q) ||
              '${item['sku']}'.toLowerCase().contains(q) ||
              '${item['barcode']}'.toLowerCase().contains(q);
          final matchesCategory = selectedCategoryId == null ||
              item['category_id'] == selectedCategoryId;
          return matchesQuery && matchesCategory;
        }).toList();

        if (allItems.isEmpty)
          return const EmptyState(
              icon: Icons.point_of_sale_outlined,
              title: 'Add items first',
              message: 'Sales can be made after your item list is ready.');
        final totalQty = cart.values.fold<int>(0, (sum, qty) => sum + qty);
        final orderTotal = cart.entries.fold<double>(0, (sum, entry) {
          final item = allItems.firstWhere((i) => i['id'] == entry.key);
          return sum + (item['price'] as num).toDouble() * entry.value;
        });
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: TextField(
                decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.qr_code_scanner),
                      onPressed: () => _showScanner(allItems),
                    ),
                    labelText: 'Search item, SKU, or barcode'),
                onChanged: (value) => setState(() => query = value),
              ),
            ),
            if (allCategories.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      isSelected: selectedCategoryId == null,
                      onSelected: (selected) {
                        if (selected) setState(() => selectedCategoryId = null);
                      },
                    ),
                    ...allCategories.map((cat) {
                      final id = cat['id'] as int;
                      return Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: _FilterChip(
                          label: cat['name'] as String,
                          isSelected: selectedCategoryId == id,
                          onSelected: (selected) {
                            setState(() =>
                                selectedCategoryId = selected ? id : null);
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final item = items[i];
                  final id = item['id'] as int;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 1),
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero),
                    child: ListTile(
                      title: Text(item['name'] as String),
                      subtitle: Text(
                          '${item['quantity']} in stock | ${_money((item['price'] as num).toDouble())}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                              onPressed: () => setState(() => cart[id] =
                                  ((cart[id] ?? 0) - 1).clamp(0, 9999).toInt()),
                              icon: const Icon(Icons.remove_circle_outline)),
                          SizedBox(
                              width: 32,
                              child: Center(
                                  child: Text('${cart[id] ?? 0}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)))),
                          IconButton(
                              onPressed: () => setState(
                                  () => cart[id] = (cart[id] ?? 0) + 1),
                              icon: const Icon(Icons.add_circle_outline)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (totalQty > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Order',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: const Color(0xFF516174),
                                  fontWeight: FontWeight.w600,
                                )),
                    Text(_money(orderTotal),
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: _homeInkColor,
                                  fontWeight: FontWeight.w900,
                                )),
                  ],
                ),
              ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: FilledButton.icon(
                  onPressed: totalQty == 0
                      ? null
                      : () async {
                          final lines = cart.entries
                              .where((e) => e.value > 0)
                              .map<Map<String, dynamic>>(
                                  (e) => {'item_id': e.key, 'qty': e.value})
                              .toList();
                          try {
                            await widget.db.sell(lines);
                            setState(() => cart.clear());
                            if (context.mounted)
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Sale completed')));
                          } catch (e) {
                            if (context.mounted)
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString())));
                          }
                        },
                  icon: const Icon(Icons.shopping_cart_checkout),
                  label: Text(
                      'Checkout $totalQty Item${totalQty == 1 ? '' : 's'}'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class AuditScreen extends StatefulWidget {
  const AuditScreen({super.key, required this.db});
  final AppDb db;

  @override
  State<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends State<AuditScreen> {
  final Map<int, TextEditingController> controllers = {};
  final Map<int, TextEditingController> reasons = {};
  final Map<int, List<String>> photos = {};

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Stock Audit',
      db: widget.db,
      selectedIndex: 1,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: widget.db.items(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final items = snapshot.data!;
          if (items.isEmpty)
            return const EmptyState(
                icon: Icons.fact_check_outlined,
                title: 'No stock to count',
                message: 'Add items and stock before doing a physical count.');
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 24),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final item = items[i];
              final id = item['id'] as int;
              controllers.putIfAbsent(
                  id,
                  () => TextEditingController(
                      text: (item['quantity'] as int).toString()));
              reasons.putIfAbsent(id, () => TextEditingController());
              photos.putIfAbsent(id, () => <String>[]);
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['name'] as String,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('System quantity: ${item['quantity']}',
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                              child: TextField(
                                  controller: controllers[id],
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                      labelText: 'Physical Count'))),
                          const SizedBox(width: 12),
                          Expanded(
                              child: TextField(
                                  controller: reasons[id],
                                  decoration: const InputDecoration(
                                      labelText: 'Reason'))),
                        ],
                      ),
                      const SizedBox(height: 20),
                      PhotoPicker(
                          db: widget.db,
                          paths: photos[id]!,
                          onChanged: () => setState(() {}),
                          label: 'Count Photos'),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () async {
                            await widget.db.auditAdjust(
                              itemId: id,
                              countedQty: int.tryParse(controllers[id]!.text) ??
                                  (item['quantity'] as int),
                              reason: reasons[id]!.text,
                              photoPaths: photos[id]!,
                            );
                            photos[id]!.clear();
                            if (context.mounted)
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Count saved')));
                            setState(() {});
                          },
                          icon: const Icon(Icons.save),
                          label: const Text('Save Count'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ActivityLogScreen extends StatefulWidget {
  const ActivityLogScreen({super.key, required this.db, this.isTab = true});
  final AppDb db;
  final bool isTab;

  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  late Future<List<Map<String, dynamic>>> _logs;
  late Future<Map<String, double>> _stats;
  final _search = TextEditingController();
  DateTime? _date;
  String? _actionFilter;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _logs = widget.db.searchAuditLogs(
        query: _search.text,
        date: _date,
        actionKeyword: _actionFilter,
      );
      _stats = _fetchStats();
    });
  }

  Future<Map<String, double>> _fetchStats() async {
    final pnl = await widget.db.pnl(date: _date);
    final investment = await widget.db.totalInvestment(date: _date);
    return {
      'investment': investment,
      'profit': pnl['profit'] ?? 0,
    };
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() => _date = picked);
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  onChanged: (_) => _refresh(),
                  decoration: InputDecoration(
                    hintText: 'Search activity...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _search.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _search.clear();
                              _refresh();
                            },
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filledTonal(
                onPressed: _selectDate,
                icon: Icon(_date == null
                    ? Icons.calendar_today
                    : Icons.event_available),
                tooltip: 'Filter by date',
              ),
              if (_date != null)
                IconButton(
                  icon: const Icon(Icons.event_busy, color: Colors.red),
                  onPressed: () {
                    setState(() => _date = null);
                    _refresh();
                  },
                  tooltip: 'Clear date filter',
                ),
            ],
          ),
        ),
        FutureBuilder<Map<String, double>>(
          future: _stats,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            final stats = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      label:
                          _date == null ? 'Overall Invested' : 'Invested Today',
                      value: stats['investment']!,
                      color: _inventoryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatTile(
                      label: _date == null ? 'Overall Profit' : 'Profit Today',
                      value: stats['profit']!,
                      color: stats['profit']! >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            children: [
              _FilterChip(
                label: 'All',
                isSelected: _actionFilter == null,
                onSelected: (v) {
                  if (v) setState(() => _actionFilter = null);
                  _refresh();
                },
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Stock',
                isSelected: _actionFilter == 'stock',
                onSelected: (v) {
                  setState(() => _actionFilter = v ? 'stock' : null);
                  _refresh();
                },
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Receive',
                isSelected: _actionFilter == 'receive',
                onSelected: (v) {
                  setState(() => _actionFilter = v ? 'receive' : null);
                  _refresh();
                },
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Sale',
                isSelected: _actionFilter == 'sale',
                onSelected: (v) {
                  setState(() => _actionFilter = v ? 'sale' : null);
                  _refresh();
                },
              ),
            ],
          ),
        ),
        if (_date != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Chip(
              label: Text('Date: ${DateFormat('yMMMd').format(_date!)}'),
              onDeleted: () {
                setState(() => _date = null);
                _refresh();
              },
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _logs,
              builder: (context, snapshot) {
                final rows = snapshot.data ?? const <Map<String, dynamic>>[];
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (rows.isEmpty) {
                  return const EmptyState(
                    icon: Icons.manage_history_outlined,
                    title: 'No activity found',
                    message:
                        'Try a different search term or check another date.',
                  );
                }
                return ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) =>
                      _ActivityCard(row: rows[index]),
                );
              },
            ),
          ),
        ),
      ],
    );

    if (widget.isTab) return content;

    return MainLayout(
      title: 'Activity Log',
      db: widget.db,
      selectedIndex: -1,
      body: content,
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.row});
  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) {
    final style = _activityStyle(row['action']);
    return Card(
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 6, color: style.color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: _ActivityContent(row: row),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityContent extends StatelessWidget {
  const _ActivityContent({required this.row});
  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) {
    final style = _activityStyle(row['action']);
    final detailsMap = _decodeAuditDetails(row['details']);
    final entityId = row['entity_id'];
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: style.color.withOpacity(0.14),
              foregroundColor: style.color,
              child: Icon(style.icon, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatActionName(row['action']),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatLogDate(row['created_at']),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: style.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                style.label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: style.color,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ActivityMetaChip(
              icon: Icons.table_rows_outlined,
              label: '${row['entity_type']}',
            ),
            if (entityId != null)
              _ActivityMetaChip(
                icon: Icons.tag,
                label: '#$entityId',
              ),
          ],
        ),
        const SizedBox(height: 16),
        _buildDetailsContent(context, row['action'], detailsMap),
      ],
    );
  }

  Widget _buildDetailsContent(
      BuildContext context, String action, Map<String, dynamic> details) {
    if (details.isEmpty) {
      return Text(
        'No extra details saved.',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    if (action == 'create_sale') {
      return _SaleActivityDetails(details: details);
    }
    if (action == 'receive_stock' || action == 'count_stock') {
      return _StockActivityDetails(details: details);
    }

    if (action == 'update_price') {
      return _PriceActivityDetails(details: details);
    }

    final entries = _auditDetailEntriesFromMap(details);
    return Column(
      children: entries
          .map(
            (entry) => _ActivityDetailRow(
              label: entry.key,
              value: entry.value,
            ),
          )
          .toList(),
    );
  }
}

class _PriceActivityDetails extends StatelessWidget {
  const _PriceActivityDetails({required this.details});
  final Map<String, dynamic> details;

  @override
  Widget build(BuildContext context) {
    final name = details['item_name'];
    final oldPrice = details['old_price'];
    final newPrice = details['new_price'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (name != null) _ActivityDetailRow(label: 'Item', value: '$name'),
        if (oldPrice != null)
          _ActivityDetailRow(
            label: 'Old Price',
            value: _money((oldPrice as num).toDouble()),
          ),
        if (newPrice != null)
          _ActivityDetailRow(
            label: 'New Price',
            value: _money((newPrice as num).toDouble()),
            valueColor: Colors.orange.shade700,
          ),
      ],
    );
  }
}

class _SaleActivityDetails extends StatelessWidget {
  const _SaleActivityDetails({required this.details});
  final Map<String, dynamic> details;

  @override
  Widget build(BuildContext context) {
    final total = details['total'];
    final lines = details['lines'] as List?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (total != null)
          _ActivityDetailRow(
            label: 'Total Amount',
            value: _money((total as num).toDouble()),
            valueColor: Colors.green.shade700,
          ),
        if (lines != null && lines.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Items sold:', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          ...lines.map((line) {
            final name = line['name'] ?? 'Item #${line['item_id']}';
            final qty = line['qty'];
            final price = line['price'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• $qty x $name @ ${_money((price as num).toDouble())}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }),
        ],
      ],
    );
  }
}

class _StockActivityDetails extends StatelessWidget {
  const _StockActivityDetails({required this.details});
  final Map<String, dynamic> details;

  @override
  Widget build(BuildContext context) {
    final name = details['item_name'] ??
        (details['item_id'] != null ? 'Item #${details['item_id']}' : null);
    final qty = details['quantity'] ?? details['counted_quantity'];
    final delta = details['delta'];
    final reason = details['reason'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (name != null) _ActivityDetailRow(label: 'Item', value: name),
        if (qty != null) _ActivityDetailRow(label: 'Quantity', value: '$qty'),
        if (delta != null)
          _ActivityDetailRow(
            label: 'Adjustment',
            value: delta > 0 ? '+$delta' : '$delta',
            valueColor: (delta as num) >= 0 ? Colors.green : Colors.red,
          ),
        if (reason != null && '$reason'.isNotEmpty)
          _ActivityDetailRow(label: 'Reason', value: '$reason'),
      ],
    );
  }
}

class _ActivityMetaChip extends StatelessWidget {
  const _ActivityMetaChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _ActivityDetailRow extends StatelessWidget {
  const _ActivityDetailRow(
      {required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: valueColor,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityStyle {
  const _ActivityStyle({
    required this.color,
    required this.icon,
    required this.label,
  });

  final Color color;
  final IconData icon;
  final String label;
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.db});
  final AppDb db;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String choice = 'device';
  File? lastBackup;

  @override
  void initState() {
    super.initState();
    widget.db.storageChoice().then((value) {
      if (mounted) setState(() => choice = value);
    });
  }

  Future<void> _setChoice(String value) async {
    try {
      await widget.db.setStorageChoice(value);
      setState(() => choice = value);
    } catch (error, stack) {
      await widget.db.logError(
          area: 'storage.setChoice',
          message: error.toString(),
          stackTrace: stack);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _createBackup({required bool share}) async {
    try {
      final file = await widget.db.createBackupFile();
      setState(() => lastBackup = file);
      if (share) {
        await Share.shareXFiles([XFile(file.path)],
            text: 'StockManager backup');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Backup saved: ${file.path}')));
      }
    } catch (error, stack) {
      await widget.db.logError(
          area: 'storage.createBackup',
          message: error.toString(),
          stackTrace: stack);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Settings',
      db: widget.db,
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _SettingsSection(
            icon: Icons.backup_outlined,
            title: 'Storage and backup',
            subtitle: 'Choose backup storage, create backups, and share files.',
            initiallyExpanded: true,
            children: [
              const Text(
                  'Your store data stays on this device unless you export or share a backup.'),
              const SizedBox(height: 16),
              Card(
                child: RadioListTile<String>(
                  value: 'device',
                  groupValue: choice,
                  onChanged: (value) => _setChoice(value!),
                  title: const Text('This device'),
                  subtitle: const Text(
                      'Save backups inside the app documents folder. Works without internet.'),
                  secondary: const Icon(Icons.phone_android),
                ),
              ),
              Card(
                child: RadioListTile<String>(
                  value: 'google_drive',
                  groupValue: choice,
                  onChanged: (value) => _setChoice(value!),
                  title: const Text('Google Drive or another app'),
                  subtitle: const Text(
                      'Use the share screen to send a backup to Drive, WhatsApp, email, or files.'),
                  secondary: const Icon(Icons.add_to_drive),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _createBackup(share: false),
                  icon: const Icon(Icons.save_alt),
                  label: const Text('Create device backup'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _createBackup(share: true),
                  icon: const Icon(Icons.ios_share),
                  label: const Text('Share backup file'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              if (lastBackup != null) ...[
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: const Text('Latest backup'),
                    subtitle: Text(lastBackup!.path),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            icon: Icons.info_outline,
            title: 'App information',
            subtitle: 'Version and local database details.',
            children: const [
              _AppInfoTile(label: 'App name', value: 'Stock Manager'),
              _AppInfoTile(label: 'Package ID', value: _appPackageId),
              _AppInfoTile(label: 'Version', value: _appVersion),
              _AppInfoTile(label: 'Build', value: _appBuildNumber),
              _AppInfoTile(
                  label: 'Database schema', value: '$_databaseSchemaVersion'),
              _AppInfoTile(
                  label: 'Storage model', value: 'Offline-first SQLite'),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            icon: Icons.manage_history_outlined,
            title: 'Troubleshooting',
            subtitle: 'View recent error logs.',
            children: [
              _LogSection(
                title: 'Recent errors',
                emptyMessage: 'No errors logged.',
                future: widget.db.recentErrorLogs(limit: 10),
                icon: Icons.bug_report_outlined,
                titleBuilder: (row) => '${row['area']}',
                subtitleBuilder: (row) =>
                    '${_formatLogDate(row['created_at'])} | ${row['message']}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
    this.initiallyExpanded = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: children,
      ),
    );
  }
}

class _AppInfoTile extends StatelessWidget {
  const _AppInfoTile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: Text(value, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

class _LogSection extends StatelessWidget {
  const _LogSection({
    required this.title,
    required this.emptyMessage,
    required this.future,
    required this.icon,
    required this.titleBuilder,
    required this.subtitleBuilder,
  });

  final String title;
  final String emptyMessage;
  final Future<List<Map<String, dynamic>>> future;
  final IconData icon;
  final String Function(Map<String, dynamic> row) titleBuilder;
  final String Function(Map<String, dynamic> row) subtitleBuilder;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        final rows = snapshot.data ?? const <Map<String, dynamic>>[];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon),
                    const SizedBox(width: 8),
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 8),
                if (!snapshot.hasData)
                  const LinearProgressIndicator()
                else if (rows.isEmpty)
                  Text(emptyMessage)
                else
                  ...rows.map(
                    (row) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(titleBuilder(row)),
                      subtitle: Text(
                        subtitleBuilder(row),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class PhotoPicker extends StatelessWidget {
  const PhotoPicker(
      {super.key,
      required this.db,
      required this.paths,
      required this.onChanged,
      required this.label});
  final AppDb db;
  final List<String> paths;
  final VoidCallback onChanged;
  final String label;

  Future<void> _pick(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = source == ImageSource.camera
          ? await picker.pickImage(source: source, imageQuality: 80)
          : null;
      final copied =
          picked == null ? <String>[] : await db.copyPhotos([picked]);
      paths.addAll(copied);
      onChanged();
    } catch (error, stack) {
      await db.logError(
          area: 'photos.pick', message: error.toString(), stackTrace: stack);
    }
  }

  Future<void> _pickMany() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickMultiImage(imageQuality: 80);
      final copied = await db.copyPhotos(picked);
      paths.addAll(copied);
      onChanged();
    } catch (error, stack) {
      await db.logError(
          area: 'photos.pickMany',
          message: error.toString(),
          stackTrace: stack);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
                child:
                    Text(label, style: Theme.of(context).textTheme.titleSmall)),
            TextButton.icon(
                onPressed: _pickMany,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Gallery')),
            TextButton.icon(
                onPressed: () => _pick(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Camera')),
          ],
        ),
        if (paths.isNotEmpty)
          SizedBox(
            height: 78,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: paths.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(File(paths[i]),
                        width: 78, height: 78, fit: BoxFit.cover),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: IconButton.filledTonal(
                      constraints:
                          const BoxConstraints.tightFor(width: 32, height: 32),
                      padding: EdgeInsets.zero,
                      iconSize: 18,
                      onPressed: () {
                        paths.removeAt(i);
                        onChanged();
                      },
                      icon: const Icon(Icons.close),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Text(
              'Optional. Add one or more photos for proof, product identity, or invoices.',
              style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  final String label;
  final bool isSelected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: _homeInkColor.withOpacity(0.2),
      checkmarkColor: _homeInkColor,
      labelStyle: TextStyle(
        color: isSelected ? _homeInkColor : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile(
      {required this.label, required this.value, required this.color});
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            _money(value),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState(
      {super.key,
      required this.icon,
      required this.title,
      required this.message});
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52),
            const SizedBox(height: 12),
            Text(title,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

String _money(double value) =>
    NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(value);

Color _softTint(Color color) => Color.alphaBlend(
      color.withOpacity(0.08),
      Colors.white,
    );

Color _stockLevelColor(int quantity) {
  if (quantity <= 0) return _countColor;
  if (quantity <= 2) return _warningColor;
  return _stockColor;
}

String _formatLogDate(Object? value) {
  final parsed = DateTime.tryParse('$value');
  if (parsed == null) return '$value';
  return DateFormat('MMM d, h:mm a').format(parsed);
}

String _formatActionName(Object? value) {
  final text = '$value'.replaceAll('_', ' ').trim();
  if (text.isEmpty) return 'Data change';
  return text
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

_ActivityStyle _activityStyle(Object? value) {
  final action = '$value'.toLowerCase();
  if (action.contains('sale')) {
    return const _ActivityStyle(
      color: Colors.green,
      icon: Icons.point_of_sale,
      label: 'Sale',
    );
  }
  if (action.contains('count') || action.contains('adjust')) {
    return const _ActivityStyle(
      color: Colors.red,
      icon: Icons.fact_check,
      label: 'Count change',
    );
  }
  if (action.contains('receive') ||
      action.contains('intake') ||
      action.contains('stock')) {
    return const _ActivityStyle(
      color: Colors.blue,
      icon: Icons.add_box,
      label: 'Stock',
    );
  }
  if (action.contains('price')) {
    return const _ActivityStyle(
      color: Colors.orange,
      icon: Icons.sell,
      label: 'Price change',
    );
  }
  if (action.contains('item')) {
    return const _ActivityStyle(
      color: Colors.deepOrange,
      icon: Icons.inventory_2,
      label: 'Item',
    );
  }
  if (action.contains('category')) {
    return const _ActivityStyle(
      color: Colors.purple,
      icon: Icons.category,
      label: 'Category',
    );
  }
  if (action.contains('setting')) {
    return const _ActivityStyle(
      color: Colors.teal,
      icon: Icons.settings,
      label: 'Setting',
    );
  }
  if (action.contains('reset')) {
    return const _ActivityStyle(
      color: Colors.blueGrey,
      icon: Icons.restart_alt,
      label: 'Reset',
    );
  }
  return const _ActivityStyle(
    color: Colors.grey,
    icon: Icons.history,
    label: 'Activity',
  );
}

List<MapEntry<String, String>> _auditDetailEntriesFromMap(
    Map<String, dynamic> decoded) {
  // Filter out internal IDs if more descriptive names are present
  final keys = decoded.keys.toSet();
  final toRemove = <String>{};
  if (keys.contains('item_name')) toRemove.add('item_id');
  if (keys.contains('category_name')) toRemove.add('category_id');

  final filtered = Map<String, dynamic>.from(decoded)
    ..removeWhere((k, v) => toRemove.contains(k));

  return filtered.entries
      .expand((entry) => _detailEntriesForValue(
            _formatDetailLabel(entry.key),
            entry.value,
          ))
      .where((entry) => entry.value.trim().isNotEmpty)
      .toList();
}

Map<String, dynamic> _decodeAuditDetails(Object? value) {
  if (value == null || '$value'.trim().isEmpty) return const {};
  try {
    final decoded = jsonDecode('$value');
    return decoded is Map<String, dynamic> ? decoded : const {};
  } catch (_) {
    return const {};
  }
}

String _formatDetailLabel(Object? value) {
  final text = '$value'.replaceAll('_', ' ').trim();
  if (text.isEmpty) return 'Detail';
  return text
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

List<MapEntry<String, String>> _detailEntriesForValue(
    String label, Object? value) {
  if (value is Map) {
    final keys = value.keys.map((e) => '$e').toSet();
    final toSkip = <String>{};
    if (keys.contains('name')) toSkip.add('item_id');

    return value.entries
        .where((e) => !toSkip.contains(e.key))
        .expand(
          (entry) => _detailEntriesForValue(
            '$label ${_formatDetailLabel(entry.key)}',
            entry.value,
          ),
        )
        .toList();
  }
  if (value is List) {
    if (value.isEmpty) return [MapEntry(label, 'None')];
    final itemLabel = _singularDetailLabel(label);
    return value.asMap().entries.expand((entry) {
      final indexLabel =
          value.length == 1 ? itemLabel : '$itemLabel ${entry.key + 1}';
      final item = entry.value;
      if (item is Map) {
        final keys = item.keys.map((e) => '$e').toSet();
        final toSkip = <String>{};
        if (keys.contains('name')) toSkip.add('item_id');

        return item.entries.where((e) => !toSkip.contains(e.key)).expand(
              (field) => _detailEntriesForValue(
                '$indexLabel ${_formatDetailLabel(field.key)}',
                field.value,
              ),
            );
      }
      return _detailEntriesForValue(indexLabel, item);
    }).toList();
  }
  return [MapEntry(label, _formatDetailValue(value))];
}

String _singularDetailLabel(String label) {
  if (label.endsWith('ies')) {
    return '${label.substring(0, label.length - 3)}y';
  }
  if (label.endsWith('s') && label.length > 1) {
    return label.substring(0, label.length - 1);
  }
  return label;
}

String _formatDetailValue(Object? value) {
  if (value == null) return '';
  if (value is num && value is! int) {
    return value.toStringAsFixed(2);
  }
  final parsedDate = DateTime.tryParse('$value');
  if (parsedDate != null) return _formatLogDate(value);
  return '$value';
}
