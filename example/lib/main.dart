import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_widget_offset/flutter_widget_offset.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Widget change example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Widget change example'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final ScrollController _scrollController = new ScrollController();
  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void onOffsetChanged(Size size, EdgeInsets offset, EdgeInsets rootPadding) {
    setState(() {
      _logs.add("The widget size: ${size.width}, ${size.height}");
      _logs.add(
          "The offset to edge of root(ltrb): ${offset.left}, ${offset.top}, ${offset.right}, ${offset.bottom}");
      _logs.add(
          "the root padding: ${rootPadding.left}, ${rootPadding.top}, ${rootPadding.right}, ${rootPadding.bottom}");
      _logs.add("----------------");
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Timer(
        Duration(milliseconds: 300),
        () => _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInBack));
  }

  @override
  Widget build(BuildContext context) {
    final textFieldStyle = Theme.of(context).textTheme.bodyText1;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
                child: ListView.builder(
              controller: _scrollController,
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                return Text(_logs[index]);
              },
            )),
            Padding(
              padding: EdgeInsets.fromLTRB(8, 0, 8, 3),
              child: OffsetDetector(
                  onChanged: onOffsetChanged,
                  child: TextField(
                    style: textFieldStyle,
                  )),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog<String>(
            context: context,
            builder: (BuildContext ctx) => AlertDialog(
              title: const Text('Submit comment'),
              content: OffsetDetector(
                  onChanged: onOffsetChanged,
                  child: TextField(
                    style: textFieldStyle,
                  )),
              actions: <Widget>[
                TextButton(
                  onPressed: () => _scrollToBottom(),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          );
        },
        tooltip: 'Screen rotation',
        child: Icon(Icons.insert_comment),
      ),
    );
  }
}
