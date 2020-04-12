import 'package:flutter/material.dart';
import 'package:stockmanager/addItemForm.dart';
import 'db.dart';
import 'package:intl/intl.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';

class AddPurchaseForm extends StatefulWidget {
  @override
  _AddPurchaseFormState createState() => _AddPurchaseFormState();
}

class _AddPurchaseFormState extends State<AddPurchaseForm> {
  final key = GlobalKey<FormState>();
  final _purchaseHeader = new PurchaseHeaderModel();
  final format = DateFormat("dd-MM-yyyy");
  final barcode = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Purchase")),
      body: Container(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
          child: Builder(
              builder: (context) => Form(
                  key: key,
                  autovalidate: true,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          decoration:
                              InputDecoration(labelText: 'Purchase From'),
                          validator: (value) {
                            value = value.trim();
                            if (value.isEmpty) {
                              return 'Please enter where your are Purchasing from';
                            } else if (value.length <= 0) {
                              return 'Please enter valid name for where your are Purchasing from';
                            } else {
                              _purchaseHeader.purchaseFrom = value;
                            }
                          },
                          onChanged: (value) {
                            setState(
                                () => _purchaseHeader.purchaseFrom = value);
                          },
                        ),
                        DateTimePickerFormField(
                          inputType: InputType.date,
                          format: DateFormat("dd-MM-yyyy"),
                          initialDate: DateTime.now(),
                          editable: false,
                          decoration: InputDecoration(
                              labelText: 'Purchase Date',
                              hasFloatingPlaceholder: false),
                          onChanged: (dt) {
                            setState(() => _purchaseHeader.purchaseDate =
                                dt == null ? "" : dt.toIso8601String());
                          },
                        ),
                        Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 16.0, horizontal: 16.0),
                            child: RaisedButton(
                                onPressed: () {
                                  final form = key.currentState;
                                  if (form.validate()) {
                                    form.save();
                                    new DBHelper()
                                        .insertPurchaseHeader(_purchaseHeader)
                                        .then((int i) {
                                      _purchaseHeader.id = i;
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) => AddItemForm(
                                                  purchaseHeader:
                                                      _purchaseHeader)));
                                    });
                                  }
                                },
                                child: Text('Save'))),
                      ])))),
    );
  }
/*
  _showDialog(BuildContext context) {
    Scaffold.of(context)
        .showSnackBar(SnackBar(content: Text('Submitting form')));
  }*/
}
