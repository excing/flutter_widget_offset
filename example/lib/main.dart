import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_widget_offset/flutter_widget_offset.dart';

void main() {
  runApp(MyApp());
}

/// flutter_widget_offset example application
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

/// flutter_widget_offset example application home page
class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  /// home page title
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
  bool _isAboveCursor = false;

  final EdgeInsets _textFieldContentPadding = EdgeInsets.fromLTRB(3, 8, 3, 8);
  late TextStyle _textFieldStyle;

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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Pop Window",
                          style: TextStyle(fontSize: 32),
                        ),
                        Switch(
                          value: _isAboveCursor,
                          onChanged: _onOverlayPositionChanged,
                        ),
                      ],
                    )
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
    this._isOpened = true;
  }

  void _closeSuggestionBox() {
    if (!this._isOpened) return;
    assert(this._overlayEntry != null);
    this._overlayEntry!.remove();
    this._isOpened = false;
  }

  void _updateSuggestionBox() {
    if (!this._isOpened) return;
    assert(this._overlayEntry != null);
    this._overlayEntry!.markNeedsBuild();
  }

  void _onOffsetChanged(Size size, EdgeInsets offset, EdgeInsets rootPadding) {
    _overlayEntryWidth = size.width;

    // print("offset top: ${offset.top}, offset bottom: ${offset.bottom}");
    if (120 < offset.bottom || offset.top < offset.bottom) {
      _overlayEntryDir = AxisDirection.down;
      _overlayEntryHeight = offset.bottom - 10;
      _overlayEntryY = 5;
    } else {
      _overlayEntryDir = AxisDirection.up;
      if (_isAboveCursor) {
        _overlayEntryHeight = offset.top + size.height - _courseHeight - 5;
        _overlayEntryY = -_courseHeight;
      } else {
        _overlayEntryHeight = offset.top - 5;
        _overlayEntryY = -size.height;
      }
    }

    _updateSuggestionBox();
  }

  double get _courseHeight =>
      (_textFieldStyle.fontSize ?? 16) +
      _textFieldContentPadding.bottom +
      _textFieldContentPadding.top;

  void _onOverlayPositionChanged(bool value) {
    setState(() {
      this._isAboveCursor = value;
    });
    _onOffsetChanged(
        _controller.size, _controller.offset, _controller.rootPadding);
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
    _textFieldStyle = Theme.of(context).textTheme.headline5!;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          Switch(
            value: _isAboveCursor,
            onChanged: _onOverlayPositionChanged,
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
                    style: _textFieldStyle,
                    textInputAction: TextInputAction.none,
                    decoration: InputDecoration(
                      contentPadding: _textFieldContentPadding,
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
