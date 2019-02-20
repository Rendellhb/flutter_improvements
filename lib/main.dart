import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(MaterialApp(
      home: Home(),
    ));

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List _toDoList = [];

  Map<String, dynamic> _lastRemoved;
  int _lastRemovedIndex;

  TextEditingController textTaskController = TextEditingController();

  void _addToDo() {
    Map<String, dynamic> newMap = Map();
    newMap["title"] = textTaskController.text;
    textTaskController.text = "";

    newMap["ok"] = false;

    setState(() {
      _toDoList.add(newMap);
    });

    _saveData();
  }

  @override
  void initState() {
    super.initState();

    try {
      initialUpdateToDoList();
    } catch (e) {
      _saveData().then((file) {
        initialUpdateToDoList();
      });
    }
  }

  void initialUpdateToDoList() {
    _readData().then((data) {
      setState(() {
        _toDoList = json.decode(data);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Lista de tarefas"),
          backgroundColor: Colors.blueAccent,
          centerTitle: true,
        ),
        body: Column(
          children: <Widget>[_buildTopContainer(), _buildBodyList()],
        ));
  }

  Widget _buildBodyList() {
    return Expanded(
      child: ListView.builder(
          padding: EdgeInsets.only(top: 10.0),
          itemCount: _toDoList.length,
          itemBuilder: _listItem),
    );
  }

  Widget _listItem(context, index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(Icons.delete, color: Colors.white),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: checkboxListTile(index),
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = Map.from(_toDoList[index]);
          _lastRemovedIndex = index;
          _toDoList.removeAt(index);
          _saveData();
        });

        final snackBar = SnackBar(
          content: Text("Tarefa \"${_lastRemoved["title"]}\" removida!"),
          duration: Duration(seconds: 2),
          action: SnackBarAction(label: "Desfazer", onPressed: () {
            setState(() {
              _toDoList.insert(_lastRemovedIndex, _lastRemoved);
            });
          }),
        );
        Scaffold.of(context).showSnackBar(snackBar);
      },
    );
  }

  Widget checkboxListTile(int index) {
    return CheckboxListTile(
      title: Text(_toDoList[index]["title"]),
      value: _toDoList[index]["ok"],
      secondary: CircleAvatar(
        child: Icon(
          _toDoList[index]["ok"] ? Icons.check : Icons.error,
          color: _toDoList[index]["ok"] ? Colors.white : Colors.red,
        ),
      ),
      onChanged: (checked) {
        setState(() {
          _toDoList[index]["ok"] = checked;
          _saveData();
        });
      },
    );
  }

  Widget _buildTopContainer() {
    return Padding(
      padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
      child: Row(
        children: <Widget>[
          RefreshIndicator(
            onRefresh: _refresh,
            child: Expanded(
              child: TextField(
                decoration: InputDecoration(
                    labelText: "Nova tarefa",
                    labelStyle: TextStyle(color: Colors.blueAccent)),
                controller: textTaskController,
              ),
            ),
          ),
          RaisedButton(
            color: Colors.blueAccent,
            child: Text("ADD"),
            textColor: Colors.white,
            onPressed: _addToDo,
          )
        ],
      ),
    );
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_toDoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      //TODO lidar com o erro de forma melhor
      return null;
    }
  }



  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 1));

    _toDoList.sort()
  }
}
