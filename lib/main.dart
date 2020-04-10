import 'package:flutter/material.dart';
import 'db.dart';
import 'package:flutter/cupertino.dart';

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
  void initState() {
    super.initState();
    startapp();
  }

  Widget itemList() {

      return  new FutureBuilder(
          future: dbh.items(),
          builder: (BuildContext context, AsyncSnapshot<List> snapshot) {
            if (!snapshot.hasData)
              return new Container();
            List<ItemModel> content = snapshot.data;
            return new ListView.builder(
                itemCount: content.length,
                itemBuilder: (BuildContext context, int index) {
                  ItemModel i = content[index];
                  return ListTile(
                    title: Row( mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                         new Text(i.name),
                          new Text(i.units.toString()),],
                    ),
                  );
                },
            );
          }
      );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          bottom: TabBar(
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
            Icon(Icons.directions_car),
            itemList(),
            Icon(Icons.directions_bike),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Add your onPressed code here!
          },
          child: Icon(Icons.add),
          backgroundColor: Colors.green,
        ),
      ),
    );
  }
}

startapp() async {
  var fido = ItemModel(
    id: 0,
    name: 'Fido',
    units: 35,
  );

  // Insert a dog into the database.
  await dbh.insertItem(fido);

  // Update Fido's age and save it to the database.
  fido = ItemModel(
    id: fido.id+1,
    name: fido.name,
    units: fido.units + 7,
  );
  await dbh.insertItem(fido);

  // Print Fido's updated information.
  print(await dbh.items());

}
