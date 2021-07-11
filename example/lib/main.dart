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
  final OffsetDetectorController _controller = OffsetDetectorController();
  final LayerLink _layerLink = LayerLink();
  late OverlayEntry? _overlayEntry;

  double _overlayEntryWidth = 100.0;
  double _overlayEntryHeight = 100.0;
  double _overlayEntryY = double.minPositive;
  AxisDirection _overlayEntryDir = AxisDirection.down;

  bool _isOpened = false;

  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    WidgetsBinding.instance!.addPostFrameCallback((duration) {
      if (mounted) {
        _overlayEntry = OverlayEntry(
          builder: (context) {
            // print("build overlay entry, "
            //     "_overlayEntryWidth: $_overlayEntryWidth, "
            //     "_overlayEntryHeight: $_overlayEntryHeight, "
            //     "_overlayEntryY: $_overlayEntryY, "
            //     "_overlayEntryDir: $_overlayEntryDir");
            final suggestionsBox = Material(
              elevation: 2.0,
              color: Colors.yellow[200],
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: _overlayEntryHeight,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Pop Window",
                      style: TextStyle(fontSize: 32),
                    ),
                  ],
                ),
              ),
            );
            return Positioned(
                width: _overlayEntryWidth,
                child: CompositedTransformFollower(
                  link: _layerLink,
                  showWhenUnlinked: false,
                  followerAnchor: _overlayEntryDir == AxisDirection.down
                      ? Alignment.topLeft
                      : Alignment.bottomLeft,
                  targetAnchor: Alignment.bottomLeft,
                  offset: Offset(0.0, _overlayEntryY),
                  child: suggestionsBox,
                ));
          },
        );
      }
    });
  }

  void _openSuggestionBox() {
    if (this._isOpened) return;
    assert(this._overlayEntry != null);
    Overlay.of(context)!.insert(this._overlayEntry!);
    setState(() {
      this._isOpened = true;
    });
  }

  void _closeSuggestionBox() {
    if (!this._isOpened) return;
    assert(this._overlayEntry != null);
    this._overlayEntry!.remove();
    setState(() {
      this._isOpened = false;
    });
  }

  void _onOffsetChanged(Size size, EdgeInsets offset, EdgeInsets rootPadding) {
    _overlayEntryWidth = size.width;

    print("offset top: ${offset.top}, offset bottom: ${offset.bottom}");
    if (120 < offset.bottom || offset.top < offset.bottom) {
      _overlayEntryDir = AxisDirection.down;
      _overlayEntryHeight = offset.bottom - 10;
      _overlayEntryY = 5;
    } else {
      _overlayEntryDir = AxisDirection.up;
      _overlayEntryHeight = offset.top - 10;
      _overlayEntryY = -size.height - 5;
    }

    assert(_overlayEntry != null);
    _overlayEntry!.markNeedsBuild();
  }

  void _onTextChanged(String value) {
    if (value.isEmpty) {
      _closeSuggestionBox();
    } else {
      if (_isOpened) {
        _controller.notifyStateChanged();
      } else {
        _openSuggestionBox();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textFieldStyle = Theme.of(context).textTheme.headline5;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          Switch(
            value: _isOpened,
            onChanged: (value) {
              if (value)
                _openSuggestionBox();
              else
                _closeSuggestionBox();
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(3),
          child: CompositedTransformTarget(
            link: _layerLink,
            child: Container(
              child: OffsetDetector(
                  controller: _controller,
                  onChanged: _onOffsetChanged,
                  child: TextField(
                    minLines: 1,
                    maxLines: 5,
                    onChanged: _onTextChanged,
                    style: textFieldStyle,
                    textInputAction: TextInputAction.none,
                    decoration: InputDecoration(
                      hintText: "Write something",
                    ),
                  )),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
