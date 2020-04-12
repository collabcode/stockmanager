import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DBHelper {
  static Database _database;

  Future<Database> get database async {
    if (_database != null) return _database;
    _database = await _initDatabase();
    return _database;
  }

  _initDatabase() async {
    return openDatabase(
      join(await getDatabasesPath(), 'Stock_database_1.db'),
      onCreate: (db, version) {
        db.execute(
            "CREATE TABLE lookup(id INTEGER PRIMARY KEY AUTOINCREMENT, lookupName TEXT, value TEXT);");
        db.execute(
            "CREATE TABLE items(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, barcode TEXT, units DOUBLE,avgPurchasePrice DOUBLE, sellingPrice DOUBLE);");
        db.execute(
            "CREATE TABLE sale_header(id INTEGER PRIMARY KEY AUTOINCREMENT, customerName TEXT, saleDate TEXT, paymentType INT, totalAmount DOUBLE, amountPaid DOUBLE, amountPending DOUBLE);");
        db.execute(
            "CREATE TABLE sale_detail(id INTEGER PRIMARY KEY AUTOINCREMENT, saleHeaderId INTEGER, itemName TEXT, unitsSold DOUBLE, sellingPrice DOUBLE);");
        db.execute(
            "CREATE TABLE purchase_header(id INTEGER PRIMARY KEY AUTOINCREMENT, purchaseName TEXT,  purchaseFrom TEXT, purchaseDate TEXT);");
        db.execute(
            "CREATE TABLE purchase_detail(id INTEGER PRIMARY KEY AUTOINCREMENT, purchaseHeaderId INTEGER, itemName TEXT,  unitsPurchased DOUBLE, purchasePrice DOUBLE);");
        db.execute(
            "INSERT INTO Lookup(LookupName, Value) VALUES ('PaymentType', 'Cash')");
        db.execute(
            "INSERT INTO Lookup(LookupName, Value) VALUES ('PaymentType', 'Card')");
        db.execute(
            "INSERT INTO Lookup(LookupName, Value) VALUES ('PaymentType', 'Payment Wallet')");
        db.execute(
            "INSERT INTO Lookup(LookupName, Value) VALUES ('PaymentType', 'Pending')");
        return true;
      },
      version: 1,
    );
  }

  Future<int> insertPurchaseHeader(PurchaseHeaderModel purchaseHeader) async {
    final Database db = await database;
    var i = await db.insert(
      'purchase_header',
      purchaseHeader.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return i;
  }

  Future<int> insertPurchaseDetail(PurchaseDetailModel purchaseDetail) async {
    final Database db = await database;
    var i = await db.insert(
      'purchase_detail',
      purchaseDetail.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print(purchaseDetail);
    return i;
  }

  Future<int> insertSaleHeader(SaleHeaderModel saleHeader) async {
    final Database db = await database;
    return await db.insert(
      'sale_header',
      saleHeader.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> insertSaleDetail(SaleDetailModel saleDetail) async {
    final Database db = await database;
    return await db.insert(
      'sale_detail',
      saleDetail.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> insertItem(ItemModel item) async {
    final Database db = await database;
    int i = await db.insert(
      'items',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print(await items());
    return i;
  }

  Future<List<ItemModel>> items() async {
    // Get a reference to the database.
    final Database db = await database;

    // Query the table for all The Dogs.
    final List<Map<String, dynamic>> maps = await db.query('items');

    // Convert the List<Map<String, dynamic> into a List<Dog>.
    return List.generate(maps.length, (i) {
      return ItemModel(
        id: maps[i]['id'],
        name: maps[i]['name'],
        barcode: maps[i]['barcode'],
        units: maps[i]['units'],
        avgPurchasePrice: maps[i]['avgPurchasePrice'],
        sellingPrice: maps[i]['sellingPrice'],
      );
    });
  }

  Future<List<SaleHeaderModel>> saleheaders() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('sale_header');
    return List.generate(maps.length, (i) {
      return SaleHeaderModel(
        id: maps[i]['id'],
        customerName: maps[i]['customerName'],
        saleDate: maps[i]['saleDate'],
        paymentType: maps[i]['paymentType'],
        totalAmount: maps[i]['totalAmount'],
        amountPaid: maps[i]['amountPaid'],
        amountPending: maps[i]['amountPending'],
      );
    });
  }

  Future<List<SaleDetailModel>> saledetails(int saleHeaderId) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('sale_detail',
        where: "saleHeaderId = ?", whereArgs: [saleHeaderId]);
    return List.generate(maps.length, (i) {
      return SaleDetailModel(
        id: maps[i]['id'],
        saleHeaderId: maps[i]['saleHeaderId'],
        itemName: maps[i]['itemName'],
        unitsSold: maps[i]['unitsSold'],
        sellingPrice: maps[i]['sellingPrice'],
      );
    });
  }

  Future<List<PurchaseHeaderModel>> purchaseheaders() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('purchase_header');
    return List.generate(maps.length, (i) {
      return PurchaseHeaderModel(
        id: maps[i]['id'],
        purchaseName: maps[i]['purchaseName'],
        purchaseFrom: maps[i]['purchaseFrom'],
        purchaseDate: maps[i]['purchaseDate'],
      );
    });
  }

  Future<List<PurchaseDetailModel>> purchasedetails(
      int purchaseHeaderId) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('purchase_detail',
        where: "purchaseHeaderId = ?", whereArgs: [purchaseHeaderId]);
    var i = List.generate(maps.length, (i) {
      return PurchaseDetailModel(
        id: maps[i]['id'],
        purchaseHeaderId: maps[i]['purchaseHeaderId'],
        itemName: maps[i]['itemName'],
        unitsPurchased: maps[i]['unitsPurchased'],
        purchasePrice: maps[i]['purchasePrice'],
      );
    });
    print(i);
    return i;
  }

  Future<ItemModel> getItemByBarcode(String barcode) async {
    final Database db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      'items',
      where: "barcode=?",
      whereArgs: [barcode],
    );

    return ItemModel(
      id: maps[0]['id'],
      name: maps[0]['name'],
      barcode: maps[0]['barcode'],
      units: maps[0]['units'],
    );
  }

  Future<ItemModel> getItemByName(String name) async {
    final Database db = await database;

    //final List<Map<String, dynamic>> maps1 = await db.query('items');
    //print(maps1);
    final List<Map<String, dynamic>> maps = await db.query(
      'items',
      where: "name=?",
      whereArgs: [name],
    );
    if (maps.isNotEmpty) {
      print(maps);
      return ItemModel(
        id: maps[0]['id'],
        name: maps[0]['name'],
        barcode: maps[0]['barcode'],
        units: maps[0]['units'],
        avgPurchasePrice: maps[0]['avgPurchasePrice'],
        sellingPrice: maps[0]['sellingPrice'],
      );
    } else
      return new ItemModel();
  }

  Future<int> updateItem(ItemModel item) async {
    final db = await database;
    int i = await db.update(
      'items',
      item.toMap(),
      where: "id = ?",
      whereArgs: [item.id],
    );
    return i;
  }
/*
  Future<void> sellItem(ItemModel item, double originalUnits, String customerName) async {
    // Get a reference to the database.
    final db = await database;
    SaleModel sale = new SaleModel();
    sale.itemId = item.id;
    sale.unitsSold = item.units;
    sale.customerName = customerName;
    item.units = originalUnits - item.units;
    await db.update(
      'items',
      item.toMap(),
      // Ensure that the Dog has a matching id.
      where: "id = ?",
      // Pass the Dog's id as a whereArg to prevent SQL injection.
      whereArgs: [item.id],
    );
    await db.insert(
      'sales',
      sale.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

  }

  Future<void> deleteItem(int id) async {
    // Get a reference to the database.
    final db = await database;

    // Remove the Dog from the database.
    await db.delete(
      'items',
      // Use a `where` clause to delete a specific dog.
      where: "id = ?",
      // Pass the Dog's id as a whereArg to prevent SQL injection.
      whereArgs: [id],
    );
  }*/
}

class ItemModel {
  int id;
  String name;
  String barcode;
  double units;
  double avgPurchasePrice;
  double sellingPrice;

  ItemModel(
      {this.id,
      this.name,
      this.barcode,
      this.units,
      this.avgPurchasePrice,
      this.sellingPrice});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'barcode': barcode,
      'units': units,
      'avgPurchasePrice': avgPurchasePrice,
      'sellingPrice': sellingPrice
    };
  }

  @override
  String toString() {
    return 'Item{id: $id, name: $name, barcode: $barcode, units: $units, avgPurchasePrice: $avgPurchasePrice, sellingPrice: $sellingPrice }';
  }
}

class PurchaseHeaderModel {
  int id;
  String purchaseName;
  String purchaseFrom;
  String purchaseDate;

  PurchaseHeaderModel(
      {this.id, this.purchaseName, this.purchaseFrom, this.purchaseDate});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'purchaseName': purchaseName,
      'purchaseFrom': purchaseFrom,
      'purchaseDate': purchaseDate,
    };
  }

  @override
  String toString() {
    return 'PurchaseHeader{id: $id, purchaseName: $purchaseName, purchaseFrom: $purchaseFrom, purchaseDate: $purchaseDate}';
  }
}

class PurchaseDetailModel {
  int id;
  int purchaseHeaderId;
  String itemName;
  double unitsPurchased;
  double purchasePrice;

  PurchaseDetailModel(
      {this.id,
      this.purchaseHeaderId,
      this.itemName,
      this.unitsPurchased,
      this.purchasePrice});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'purchaseHeaderId': purchaseHeaderId,
      'itemName': itemName,
      'unitsPurchased': unitsPurchased,
      'purchasePrice': purchasePrice
    };
  }

  @override
  String toString() {
    return 'PurchaseDetail{id: $id, purchaseHeaderId: $purchaseHeaderId, itemId: $itemName, unitsPurchased: $unitsPurchased, purchasePrice: $purchasePrice}';
  }
}

class LookupModel {
  int id;
  String lookupName;
  String value;

  LookupModel({this.id, this.lookupName, this.value});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lookupName': lookupName,
      'value': value,
    };
  }

  @override
  String toString() {
    return 'Lookup{id: $id, lookupName: $lookupName, value: $value }';
  }
}

class SaleHeaderModel {
  int id;
  String customerName;
  String saleDate;
  String paymentType;
  double totalAmount;
  double amountPaid;
  double amountPending;

  SaleHeaderModel(
      {this.id,
      this.customerName,
      this.saleDate,
      this.paymentType,
      this.totalAmount,
      this.amountPaid,
      this.amountPending});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerName': customerName,
      'saleDate': saleDate,
      'paymentType': paymentType,
      'totalAmount': totalAmount,
      'amountPaid': amountPaid,
      'amountPending': amountPending,
    };
  }

  @override
  String toString() {
    return 'SaleHeader{id: $id, customerName: $customerName, saleDate: $saleDate, paymentType: $paymentType, totalAmount: $totalAmount, amountPaid: $amountPaid, amountPending: $amountPending }';
  }
}

class SaleDetailModel {
  int id;
  int saleHeaderId;
  String itemName;
  double unitsSold;
  double sellingPrice;

  SaleDetailModel(
      {this.id,
      this.saleHeaderId,
      this.itemName,
      this.unitsSold,
      this.sellingPrice});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'saleHeaderId': saleHeaderId,
      'itemName': itemName,
      'unitsSold': unitsSold,
      'sellingPrice': sellingPrice
    };
  }

  @override
  String toString() {
    return 'SaleDetail{id: $id, saleHeaderId: $saleHeaderId, itemName: $itemName, unitsSold: $unitsSold, sellingPrice: $sellingPrice}';
  }
}
