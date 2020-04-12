import 'package:flutter/material.dart';
import 'package:stockmanager/addPurchaseForm.dart';
import 'package:stockmanager/sellItemForm.dart';
import 'db.dart';
import 'addItemForm.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

DBHelper dbh;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  dbh = new DBHelper();
  runApp(MaterialApp(debugShowCheckedModeBanner: false, home: MyHome()));
}

class MyHome extends StatefulWidget {
  @override
  MyHomeState createState() {
    return MyHomeState();
  }
}

class MyHomeState extends State<MyHome> {
  @override
  //final _formKey = GlobalKey();
  int indexTab = 0;

  void initState() {
    super.initState();
    //startapp();
  }

  Widget saleList() {
    return new FutureBuilder(
        future: dbh.saleheaders(),
        builder: (BuildContext context, AsyncSnapshot<List> snapshot) {
          if (!snapshot.hasData) return new Container();
          List<SaleHeaderModel> content = snapshot.data;
          return new RefreshIndicator(
            child: new ListView.builder(
              itemCount: content.length,
              itemBuilder: (BuildContext context, int index) {
                SaleHeaderModel i = content[index];
                return ListTile(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      new Text(i.customerName == null ? '' : i.customerName),
                      new Text(i.totalAmount == null
                          ? ''
                          : i.totalAmount.toString()),
                    ],
                  ),
                );
              },
            ),
            onRefresh: refreshSales,
          );
        });
  }

  Future<void> refreshSales() async {
    print('refreshing list Sales...');
    saleList();
  }

  Widget purchaseDetailsList(int purchaseHeaderId) {
    return new FutureBuilder(
        future: dbh.purchasedetails(purchaseHeaderId),
        builder: (BuildContext context, AsyncSnapshot<List> snapshot) {
          if (!snapshot.hasData) return new Container();
          List<PurchaseDetailModel> content = snapshot.data;
          return new RefreshIndicator(
            child: new ListView.builder(
              itemCount: content.length,
              itemBuilder: (BuildContext context, int index) {
                PurchaseDetailModel i = content[index];
                return ListTile(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      new Text(i.itemName == null ? '' : i.itemName.toString()),
                      new Text(i.unitsPurchased == null
                          ? ''
                          : i.unitsPurchased.toString()),
                    ],
                  ),
                );
              },
            ),
            onRefresh: refreshItems,
          );
        });
  }

  Widget purchaseHeaderList() {
    return new FutureBuilder(
        future: dbh.purchaseheaders(),
        builder: (BuildContext context, AsyncSnapshot<List> snapshot) {
          if (!snapshot.hasData) return new Container();
          List<PurchaseHeaderModel> content = snapshot.data;
          return new RefreshIndicator(
            child: new ListView.builder(
              itemCount: content.length,
              itemBuilder: (BuildContext context, int index) {
                PurchaseHeaderModel i = content[index];
                return ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => AddItemForm(
                                purchaseHeader: i,
                              )),
                    );
                  },
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      new Text(i.purchaseFrom == null ? '' : i.purchaseFrom),
                      new Text(i.purchaseDate == null
                          ? ''
                          : DateFormat("dd-MM-yyyy")
                              .format(DateTime.parse(i.purchaseDate))
                              .toString()),
                    ],
                  ),
                );
              },
            ),
            onRefresh: refreshItems,
          );
        });
  }

  Future<void> refreshSaleDetails(int saleHeaderId) async {
    print('refreshing Sale Details...');
    saleDetailsList(saleHeaderId);
  }

  Widget saleDetailsList(int saleHeaderId) {
    return new FutureBuilder(
        future: dbh.saledetails(saleHeaderId),
        builder: (BuildContext context, AsyncSnapshot<List> snapshot) {
          if (!snapshot.hasData) return new Container();
          List<SaleDetailModel> content = snapshot.data;
          return new RefreshIndicator(
            child: new ListView.builder(
              itemCount: content.length,
              itemBuilder: (BuildContext context, int index) {
                SaleDetailModel i = content[index];
                return ListTile(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      new Text(i.itemName == null ? '' : i.itemName.toString()),
                      new Text(
                          i.unitsSold == null ? '' : i.unitsSold.toString()),
                    ],
                  ),
                );
              },
            ),
            onRefresh: null,
          );
        });
  }

  Future<void> refreshSaleHeaders() async {
    print('refreshing Sale Header...');
    saleList();
  }

  Widget saleHeaderList() {
    return new FutureBuilder(
        future: dbh.saleheaders(),
        builder: (BuildContext context, AsyncSnapshot<List> snapshot) {
          if (!snapshot.hasData) return new Container();
          List<SaleHeaderModel> content = snapshot.data;
          return new RefreshIndicator(
            child: new ListView.builder(
              itemCount: content.length,
              itemBuilder: (BuildContext context, int index) {
                SaleHeaderModel i = content[index];
                return ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => SellItemForm(
                                saleHeader: i,
                              )),
                    );
                  },
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      new Text(i.customerName == null ? '' : i.customerName),
                      new Text(i.saleDate == null
                          ? ''
                          : DateFormat("dd-MM-yyyy")
                              .format(DateTime.parse(i.saleDate))
                              .toString()),
                    ],
                  ),
                );
              },
            ),
            onRefresh: null,
          );
        });
  }

  Widget itemList() {
    return new FutureBuilder(
        future: dbh.items(),
        builder: (BuildContext context, AsyncSnapshot<List> snapshot) {
          if (!snapshot.hasData) return new Container();
          List<ItemModel> content = snapshot.data;
          return new RefreshIndicator(
            child: new ListView.builder(
              itemCount: content.length,
              itemBuilder: (BuildContext context, int index) {
                ItemModel i = content[index];
                return ListTile(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      new Text(i.name == null ? '' : i.name),
                      new Text(i.units == null ? '' : i.units.toString()),
                    ],
                  ),
                );
              },
            ),
            onRefresh: refreshItems,
          );
        });
  }

  Future<void> refreshItems() async {
    print('refreshing list items...');
    itemList();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          bottom: TabBar(
            onTap: (index) {
              setState(() {
                indexTab = index;
              });
            },
            tabs: [
              Tab(icon: Icon(Icons.home)),
              Tab(icon: Icon(Icons.storage)),
              Tab(icon: Icon(Icons.shopping_cart)),
            ],
          ),
          title: Text('Stock Manager'),
        ),
        body: TabBarView(
          children: [
            itemList(),
            purchaseHeaderList(),
            saleList(),
          ],
        ),
        floatingActionButton: indexTab == 1
            ? FloatingActionButton(
                onPressed: () {
                  // Add your onPressed code here!
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => AddPurchaseForm()));
                },
                child: Icon(Icons.add),
                backgroundColor: Colors.green,
              )
            : indexTab == 2
                ? FloatingActionButton(
                    onPressed: () {
                      // Add your onPressed code here!
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SellItemForm()));
                    },
                    child: Icon(Icons.add),
                    backgroundColor: Colors.green,
                  )
                : null,
      ),
    );
  }
}

startapp() async {
  var fido = ItemModel(
    name: 'Fido',
    units: 35,
  );

  // Insert a dog into the database.
  await dbh.insertItem(fido);

  // Update Fido's age and save it to the database.
  fido = ItemModel(
    name: fido.name,
    units: fido.units + 7,
  );
  await dbh.insertItem(fido);

  // Print Fido's updated information.
  print(await dbh.items());
}
