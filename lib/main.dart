import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StockManagerApp());
}

class StockManagerApp extends StatelessWidget {
  const StockManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StockManager',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AppDb _db = AppDb();
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _db.init();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(db: _db),
      CatalogScreen(db: _db),
      IntakeScreen(db: _db),
      PosScreen(db: _db),
      AuditScreen(db: _db),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('StockManager - Phase 1')),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.inventory_2), label: 'Catalog'),
          NavigationDestination(icon: Icon(Icons.add_box), label: 'Intake'),
          NavigationDestination(icon: Icon(Icons.point_of_sale), label: 'POS'),
          NavigationDestination(icon: Icon(Icons.fact_check), label: 'Audit'),
        ],
      ),
    );
  }
}

class AppDb {
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    return init();
  }

  Future<Database> init() async {
    final dbPath = await getDatabasesPath();
    _database = await openDatabase(
      join(dbPath, 'stock_manager_v1.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('CREATE TABLE categories(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT UNIQUE)');
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
      },
    );
    return _database!;
  }

  Future<void> addCategory(String name) async {
    final db = await database;
    await db.insert('categories', {'name': name.trim()}, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<List<Map<String, dynamic>>> categories() async {
    final db = await database;
    return db.query('categories', orderBy: 'name ASC');
  }

  Future<void> addItem(Map<String, dynamic> item) async {
    final db = await database;
    await db.insert('items', item, conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<List<Map<String, dynamic>>> items() async {
    final db = await database;
    return db.rawQuery('''
      SELECT i.*, c.name as category
      FROM items i LEFT JOIN categories c ON c.id=i.category_id
      ORDER BY i.name ASC
    ''');
  }

  Future<void> intake({required int itemId, required int qty, required DateTime date, required String note}) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.rawUpdate('UPDATE items SET quantity = quantity + ? WHERE id = ?', [qty, itemId]);
      await txn.insert('stock_ledger', {
        'item_id': itemId,
        'type': 'intake',
        'quantity': qty,
        'note': note,
        'created_at': date.toIso8601String(),
      });
    });
  }

  Future<void> auditAdjust({required int itemId, required int countedQty}) async {
    final db = await database;
    await db.transaction((txn) async {
      final current = (await txn.query('items', columns: ['quantity'], where: 'id=?', whereArgs: [itemId])).first['quantity'] as int;
      final delta = countedQty - current;
      await txn.update('items', {'quantity': countedQty}, where: 'id=?', whereArgs: [itemId]);
      await txn.insert('stock_ledger', {
        'item_id': itemId,
        'type': 'audit_adjustment',
        'quantity': delta,
        'note': 'Audit correction',
        'created_at': DateTime.now().toIso8601String(),
      });
    });
  }

  Future<void> sell(List<Map<String, dynamic>> lines) async {
    final db = await database;
    await db.transaction((txn) async {
      double total = 0;
      for (final line in lines) {
        final itemId = line['item_id'] as int;
        final qty = line['qty'] as int;
        final item = (await txn.query('items', where: 'id=?', whereArgs: [itemId])).first;
        final current = item['quantity'] as int;
        if (current < qty) throw Exception('Insufficient stock for ${item['name']}');
        final price = (item['price'] as num).toDouble();
        final cost = (item['cost'] as num).toDouble();
        total += price * qty;
        await txn.rawUpdate('UPDATE items SET quantity = quantity - ? WHERE id = ?', [qty, itemId]);
        await txn.insert('stock_ledger', {
          'item_id': itemId,
          'type': 'sale',
          'quantity': -qty,
          'note': 'POS sale',
          'created_at': DateTime.now().toIso8601String(),
        });
        line['price'] = price;
        line['cost'] = cost;
      }
      final saleId = await txn.insert('sales', {'total': total, 'created_at': DateTime.now().toIso8601String()});
      for (final line in lines) {
        await txn.insert('sale_items', {'sale_id': saleId, ...line});
      }
    });
  }

  Future<Map<String, double>> pnl(DateTime from) async {
    final db = await database;
    final salesRows = await db.rawQuery('SELECT IFNULL(SUM(total),0) as revenue FROM sales WHERE created_at >= ?', [from.toIso8601String()]);
    final cogsRows = await db.rawQuery('''
      SELECT IFNULL(SUM(si.qty * si.cost),0) as cogs
      FROM sale_items si JOIN sales s ON s.id=si.sale_id
      WHERE s.created_at >= ?
    ''', [from.toIso8601String()]);
    final revenue = (salesRows.first['revenue'] as num).toDouble();
    final cogs = (cogsRows.first['cogs'] as num).toDouble();
    return {'revenue': revenue, 'cogs': cogs, 'profit': revenue - cogs};
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.db});
  final AppDb db;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([db.pnl(DateTime.now().subtract(const Duration(days: 1))), db.pnl(DateTime.now().subtract(const Duration(days: 7))), db.pnl(DateTime.now().subtract(const Duration(days: 30)))]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final values = snapshot.data as List<Map<String, double>>;
        Widget card(String title, Map<String, double> v) => Card(child: ListTile(title: Text(title), subtitle: Text('Revenue: ${v['revenue']!.toStringAsFixed(2)} | COGS: ${v['cogs']!.toStringAsFixed(2)} | Profit: ${v['profit']!.toStringAsFixed(2)}')));
        return ListView(padding: const EdgeInsets.all(16), children: [card('Daily', values[0]), card('Weekly', values[1]), card('Monthly', values[2])]);
      },
    );
  }
}

class CatalogScreen extends StatefulWidget { const CatalogScreen({super.key, required this.db}); final AppDb db; @override State<CatalogScreen> createState() => _CatalogScreenState(); }
class _CatalogScreenState extends State<CatalogScreen> {
  Future<void> _addCategory() async { final c = TextEditingController(); await showDialog(context: context, builder: (_) => AlertDialog(title: const Text('New Category'), content: TextField(controller: c), actions: [TextButton(onPressed: ()=>Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () async {await widget.db.addCategory(c.text); if(context.mounted) Navigator.pop(context); setState(() {});}, child: const Text('Save'))])); }
  Future<void> _addItem() async {
    final cats = await widget.db.categories();
    if (cats.isEmpty && mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add a category first'))); return; }
    int categoryId = cats.first['id'] as int;
    final name = TextEditingController(); final sku = TextEditingController(); final barcode = TextEditingController(); final cost = TextEditingController(); final price = TextEditingController();
    await showDialog(context: context, builder: (_) => StatefulBuilder(builder: (context, setS) => AlertDialog(title: const Text('New Item'), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [DropdownButton<int>(value: categoryId, isExpanded: true, items: cats.map((e) => DropdownMenuItem(value: e['id'] as int, child: Text(e['name'] as String))).toList(), onChanged: (v)=>setS(()=>categoryId=v!)), TextField(controller:name, decoration:const InputDecoration(labelText:'Name')), TextField(controller:sku, decoration:const InputDecoration(labelText:'SKU')), TextField(controller:barcode, decoration:const InputDecoration(labelText:'Barcode')), TextField(controller:cost, keyboardType: TextInputType.number, decoration:const InputDecoration(labelText:'Cost')), TextField(controller:price, keyboardType: TextInputType.number, decoration:const InputDecoration(labelText:'Price'))])), actions: [TextButton(onPressed: ()=>Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () async { await widget.db.addItem({'category_id': categoryId,'name':name.text.trim(),'sku':sku.text.trim(),'barcode':barcode.text.trim(),'cost':double.tryParse(cost.text) ?? 0,'price':double.tryParse(price.text) ?? 0,'quantity':0}); if(context.mounted) Navigator.pop(context); setState(() {}); }, child: const Text('Save'))])));
  }
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String,dynamic>>>(future: widget.db.items(), builder: (context,s){ if(!s.hasData) return const Center(child:CircularProgressIndicator()); final data=s.data!; return Column(children:[Padding(padding:const EdgeInsets.all(8), child: Wrap(spacing:8, children:[FilledButton.icon(onPressed:_addCategory, icon:const Icon(Icons.category), label:const Text('Category')), FilledButton.icon(onPressed:_addItem, icon:const Icon(Icons.add), label:const Text('Item'))])), Expanded(child:ListView.builder(itemCount:data.length,itemBuilder:(_,i){final it=data[i]; return ListTile(title: Text('${it['name']} (${it['quantity']})'), subtitle: Text('${it['category']} • SKU:${it['sku']} • ${it['barcode']}'), trailing: Text('\$${(it['price'] as num).toStringAsFixed(2)}'));}))]);});
  }
}

class IntakeScreen extends StatefulWidget { const IntakeScreen({super.key, required this.db}); final AppDb db; @override State<IntakeScreen> createState()=>_IntakeScreenState(); }
class _IntakeScreenState extends State<IntakeScreen> { int? selectedItem; final qty=TextEditingController(); final note=TextEditingController(); DateTime date=DateTime.now();
  @override Widget build(BuildContext context){ return FutureBuilder<List<Map<String,dynamic>>>(future: widget.db.items(), builder:(context,s){ if(!s.hasData) return const Center(child:CircularProgressIndicator()); final items=s.data!; selectedItem ??= items.isNotEmpty ? items.first['id'] as int : null; if(items.isEmpty) return const Center(child:Text('Add items first')); return Padding(padding:const EdgeInsets.all(16), child:Column(children:[DropdownButton<int>(value:selectedItem, isExpanded:true, items:items.map((e)=>DropdownMenuItem(value:e['id'] as int, child:Text(e['name'] as String))).toList(), onChanged:(v)=>setState(()=>selectedItem=v)), TextField(controller:qty, keyboardType:TextInputType.number, decoration:const InputDecoration(labelText:'Quantity (single or bulk)')), TextField(controller:note, decoration:const InputDecoration(labelText:'Note')), const SizedBox(height:12), Row(children:[Text('Date: ${DateFormat.yMd().format(date)}'), const Spacer(), TextButton(onPressed:() async {final picked=await showDatePicker(context:context, firstDate:DateTime(2020), lastDate:DateTime(2100), initialDate:date); if(picked!=null) setState(()=>date=picked);}, child:const Text('Pick'))]), FilledButton(onPressed:() async {await widget.db.intake(itemId:selectedItem!, qty:int.tryParse(qty.text) ?? 0, date:date, note:note.text); if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Stock updated')));}, child:const Text('Add Stock'))]));}); }
}

class PosScreen extends StatefulWidget { const PosScreen({super.key, required this.db}); final AppDb db; @override State<PosScreen> createState()=>_PosScreenState(); }
class _PosScreenState extends State<PosScreen> { final Map<int,int> cart={};
  @override Widget build(BuildContext context){ return FutureBuilder<List<Map<String,dynamic>>>(future: widget.db.items(), builder:(context,s){ if(!s.hasData) return const Center(child:CircularProgressIndicator()); final items=s.data!; return Column(children:[Expanded(child:ListView.builder(itemCount:items.length,itemBuilder:(_,i){ final it=items[i]; final id=it['id'] as int; return ListTile(title:Text('${it['name']} (${it['quantity']} in stock)'), subtitle:Text('Barcode: ${it['barcode']}'), trailing:Row(mainAxisSize:MainAxisSize.min, children:[IconButton(onPressed:(){ if((cart[id]??0)>0) setState(()=>cart[id]=cart[id]!-1);}, icon:const Icon(Icons.remove)), Text('${cart[id]??0}'), IconButton(onPressed:(){ setState(()=>cart[id]=(cart[id]??0)+1);}, icon:const Icon(Icons.add))]));})), Padding(padding:const EdgeInsets.all(12), child:FilledButton.icon(onPressed:() async { final lines=cart.entries.where((e)=>e.value>0).map((e)=>{'item_id':e.key,'qty':e.value}).toList(); if(lines.isEmpty) return; try{ await widget.db.sell(lines); setState(()=>cart.clear()); if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Sale completed')));} catch(e){ if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));} }, icon:const Icon(Icons.shopping_cart_checkout), label:const Text('Checkout')))]);}); }
}

class AuditScreen extends StatefulWidget { const AuditScreen({super.key, required this.db}); final AppDb db; @override State<AuditScreen> createState()=>_AuditScreenState(); }
class _AuditScreenState extends State<AuditScreen> { final Map<int,TextEditingController> controllers={};
  @override Widget build(BuildContext context){ return FutureBuilder<List<Map<String,dynamic>>>(future: widget.db.items(), builder:(context,s){ if(!s.hasData) return const Center(child:CircularProgressIndicator()); final items=s.data!; if(items.isEmpty) return const Center(child:Text('No items to audit')); return ListView.builder(itemCount:items.length, itemBuilder:(_,i){ final it=items[i]; final id=it['id'] as int; controllers.putIfAbsent(id, ()=>TextEditingController(text:(it['quantity'] as int).toString())); return Card(child:ListTile(title:Text(it['name'] as String), subtitle:Text('System qty: ${it['quantity']}'), trailing:SizedBox(width:160, child:Row(children:[Expanded(child:TextField(controller:controllers[id], keyboardType:TextInputType.number, decoration:const InputDecoration(labelText:'Counted'))), IconButton(onPressed:() async {await widget.db.auditAdjust(itemId:id, countedQty:int.tryParse(controllers[id]!.text) ?? (it['quantity'] as int)); if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Adjusted'))); setState(() {});}, icon:const Icon(Icons.save))]))));});}); }
}
