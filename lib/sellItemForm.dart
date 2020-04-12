import 'package:flutter/material.dart';
import 'db.dart';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:intl/intl.dart';

class SellItemForm extends StatefulWidget {
  final SaleHeaderModel saleHeader;

  SellItemForm({this.saleHeader});

  @override
  _SellItemFormState createState() => _SellItemFormState(saleHeader);
}

class _SellItemFormState extends State<SellItemForm> {
  DBHelper dbh = new DBHelper();
  final key = GlobalKey<FormState>();
  SaleHeaderModel _saleHeader;
  final _saleDetail = new SaleDetailModel();
  var _item = new ItemModel();
  var o_item = new ItemModel();
  String o_avgPurchasePrice = "", o_sellingPrice = "", o_units = "";
  final format = DateFormat("dd-MM-yyyy");
  String barcode = "";

  _SellItemFormState(this._saleHeader);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Items of Sale")),
      body: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        child: Builder(
          builder: (context) => SaleDetailsList(_saleHeader.id),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                  content: Form(
                      key: key,
                      autovalidate: true,
                      child: SingleChildScrollView(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                decoration:
                                    InputDecoration(labelText: 'Item Name'),
                                validator: (value) {
                                  value = value.trim();
                                  if (value.isEmpty) {
                                    return 'Please enter Item Name';
                                  }
                                },
                                onChanged: (value) {
                                  new DBHelper()
                                      .getItemByName(value)
                                      .then((o_i) {
                                    setState(() {
                                      o_item = o_i;
                                      print([o_item, "old item"]);
                                      barcode = o_item.barcode == null
                                          ? ""
                                          : o_item.barcode;
                                      o_avgPurchasePrice =
                                          o_item.avgPurchasePrice == null
                                              ? ""
                                              : o_item.avgPurchasePrice
                                                  .toString();
                                      o_sellingPrice =
                                          o_item.sellingPrice == null
                                              ? ""
                                              : o_item.sellingPrice.toString();
                                      o_units = o_item.units == null
                                          ? ""
                                          : o_item.units.toString();
                                    });
                                  });
                                },
                                onSaved: (value) => (_item.name = value),
                              ),
                              new Container(
                                padding: null,
                                child: new MaterialButton(
                                    padding: EdgeInsets.all(0),
                                    onPressed: scan,
                                    child: new Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        new Text("Scan Barcode"),
                                        new Text(barcode),
                                      ],
                                    )),
                              ),
                              TextFormField(
                                decoration: InputDecoration(labelText: 'Units'),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value.isEmpty) {
                                    return 'Please enter the Item quantity';
                                  }
                                },
                                onSaved: (value) =>
                                    (_item.units = double.tryParse(value)),
                              ),
                              Text("Existing Units: $o_units"),
                              TextFormField(
                                decoration: InputDecoration(
                                    labelText: 'Purchase Price'),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value.isEmpty) {
                                    return 'Please enter the Purchase Price';
                                  }
                                },
                                onSaved: (value) => (_item.avgPurchasePrice =
                                    double.tryParse(value)),
                              ),
                              Text(
                                "Average Purchase Price: $o_avgPurchasePrice",
                              ),
                              TextFormField(
                                decoration:
                                    InputDecoration(labelText: 'Selling Price'),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value.isEmpty) {
                                    return 'Please enter the Item selling price';
                                  }
                                },
                                onSaved: (value) => (_item.sellingPrice =
                                    double.tryParse(value)),
                              ),
                              Text("Selling Price: $o_sellingPrice"),
                              Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8.0, horizontal: 8.0),
                                  child: RaisedButton(
                                      onPressed: () {
                                        final form = key.currentState;
                                        if (form.validate()) {
                                          form.save();
                                          if (_item.name != null) {
                                            if (_item.name.length > 0) {
                                              print([o_item, "old item again"]);
                                              if (o_item.id > 0) {
                                                _saleDetail.itemName =
                                                    _item.name;
                                                _saleDetail.unitsSold =
                                                    _item.units;
                                                _saleDetail.saleHeaderId =
                                                    _saleHeader.id;
                                                _saleDetail.sellingPrice =
                                                    _item.sellingPrice;

                                                _item.id = o_item.id;
                                                _item.units += o_item.units;
                                                _item.avgPurchasePrice = (o_item
                                                                .units *
                                                            o_item
                                                                .avgPurchasePrice +
                                                        _item.units *
                                                            _item
                                                                .avgPurchasePrice) /
                                                    (o_item.units +
                                                        _item.units);

                                                new DBHelper()
                                                    .updateItem(_item)
                                                    .then((int id) {
                                                  new DBHelper()
                                                      .insertSaleDetail(
                                                          _saleDetail);
                                                });
                                              } else {
                                                new DBHelper()
                                                    .insertItem(_item)
                                                    .then((int id) {
                                                  _saleDetail.itemName =
                                                      _item.name;
                                                  _saleDetail.unitsSold =
                                                      _item.units;
                                                  _saleDetail.saleHeaderId =
                                                      _saleHeader.id;
                                                  _saleDetail.sellingPrice =
                                                      _item.sellingPrice;
                                                  new DBHelper()
                                                      .insertSaleDetail(
                                                          _saleDetail);
                                                });
                                              }
                                            }
                                          }
                                        }
                                      },
                                      child: Text('Save'))),
                            ]),
                      )));
            },
          );
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> refreshItems() async {
    print('refreshing Sale Details...');
    SaleDetailsList(_saleHeader.id);
  }

  Widget SaleDetailsList(int saleHeaderId) {
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

  Future scan() async {
    try {
      String barcode = await BarcodeScanner.scan();
      setState(() => this.barcode = barcode);
    } on PlatformException catch (e) {
      if (e.code == BarcodeScanner.CameraAccessDenied) {
        setState(() {
          //this.barcode = 'The user did not grant the camera permission!';
        });
      } else {
        //setState(() => this.barcode = 'Unknown error: $e');
      }
    } on FormatException {
      //setState(() => this.barcode = 'null (User returned using the "back"-button before scanning anything. Result)');
    } catch (e) {
      //setState(() => this.barcode = 'Unknown error: $e');
    }
    _item.barcode = barcode;
    new DBHelper().getItemByBarcode(barcode).then((o_item) {
      print(o_item);
      setState(() {
        o_avgPurchasePrice = o_item.avgPurchasePrice == null
            ? ""
            : o_item.avgPurchasePrice.toString();
        o_sellingPrice =
            o_item.sellingPrice == null ? "" : o_item.sellingPrice.toString();
        o_units = o_item.units == null ? "" : o_item.units.toString();
      });
    });
  }
}
