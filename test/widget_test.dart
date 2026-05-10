// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:stockmanager/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUp(() async {
    final dbPath = await getDatabasesPath();
    await databaseFactory.deleteDatabase('$dbPath/stock_manager_v1.db');
  });

  tearDown(() async {
    await AppDb().close();
    final dbPath = await getDatabasesPath();
    await databaseFactory.deleteDatabase('$dbPath/stock_manager_v1.db');
  });

  testWidgets('StockManager app shows the main shell',
      (WidgetTester tester) async {
    await tester.pumpWidget(const StockManagerApp());
    await _drainDatabaseWork(tester);

    expect(find.text('Stock Manager'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Stock'), findsOneWidget);
    expect(find.text('Sell'), findsOneWidget);
    expect(find.text('Activity'), findsOneWidget);
    expect(find.text('Storage'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await _drainDatabaseWork(tester);
  });

  testWidgets('settings screen contains storage and app information sections',
      (WidgetTester tester) async {
    await tester.pumpWidget(const StockManagerApp());
    await _drainDatabaseWork(tester);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pump();
    await _drainDatabaseWork(tester);

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Storage and backup'), findsOneWidget);
    await tester.tap(find.text('Storage and backup'));
    await tester.pumpAndSettle();
    expect(find.text('App information'), findsOneWidget);

    await tester.tap(find.text('App information'));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Version'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await _drainDatabaseWork(tester);
  });

  test('audit log records data changes with timestamps and details', () async {
    final db = AppDb();
    await db.init();
    final suffix = DateTime.now().microsecondsSinceEpoch;
    await db.addCategory('Audit $suffix');

    final logs = await db.auditLogs();
    final latest = logs.first;

    expect(latest['action'], 'create_category');
    expect(latest['created_at'], isNotNull);
    expect('${latest['details']}', contains('Audit $suffix'));
  });

  test('selling an item stores price and cost without type errors', () async {
    final db = AppDb();
    await db.init();
    final suffix = DateTime.now().microsecondsSinceEpoch;
    final categoryName = 'Grocery $suffix';
    await db.addCategory(categoryName);
    final categoryId = (await db.categories())
        .firstWhere((row) => row['name'] == categoryName)['id'] as int;
    final itemId = await db.addItem({
      'category_id': categoryId,
      'name': 'Sugar $suffix',
      'sku': 'SUGAR-$suffix',
      'barcode': '1001-$suffix',
      'cost': 30.5,
      'price': 42.75,
      'quantity': 0,
    }, []);

    await db.intake(
      itemId: itemId,
      qty: 3,
      date: DateTime.now(),
      note: 'opening stock',
      photoPaths: [],
    );

    await db.sell([
      {'item_id': itemId, 'qty': 1}
    ]);

    final items = await db.items();
    final item = items.firstWhere((row) => row['id'] == itemId);
    expect(item['quantity'], 2);

    final auditLogs = await db.recentAuditLogs();
    expect(auditLogs.any((row) => row['action'] == 'create_sale'), isTrue);
  });

  test('error logs can be recorded for troubleshooting', () async {
    final db = AppDb();
    await db.init();

    await db.logError(
      area: 'test',
      message: 'Example failure',
      stackTrace: StackTrace.current,
    );

    final errorLogs = await db.recentErrorLogs();
    expect(errorLogs.first['area'], 'test');
    expect(errorLogs.first['message'], 'Example failure');
  });
}

Future<void> _drainDatabaseWork(WidgetTester tester) async {
  await tester.runAsync(() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
  });
  await tester.pump();
}
