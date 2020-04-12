import 'package:flutter/material.dart';
import 'package:stockmanager/sellItemForm.dart';
import 'db.dart';
import 'package:intl/intl.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';

class AddSaleForm extends StatefulWidget {
  @override
  _AddSaleFormState createState() => _AddSaleFormState();
}

class _AddSaleFormState extends State<AddSaleForm> {
  final key = GlobalKey<FormState>();
  final _saleHeader = new SaleHeaderModel();
  final format = DateFormat("dd-MM-yyyy");
  final barcode = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Sale")),
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
                              InputDecoration(labelText: 'Customer Name'),
                          validator: (value) {
                            value = value.trim();
                            if (value.isEmpty) {
                              return 'Please enter Customer Name';
                            } else {
                              _saleHeader.customerName = value;
                            }
                          },
                          onChanged: (value) {
                            setState(() => _saleHeader.customerName = value);
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
                            setState(() => _saleHeader.saleDate =
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
                                        .insertSaleHeader(_saleHeader)
                                        .then((int i) {
                                      _saleHeader.id = i;
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  SellItemForm(
                                                      saleHeader:
                                                          _saleHeader)));
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
