# flutter-widget-offset

一个类库，用于获取和观察 `widget` 到根布局边缘的偏移量。
此类库也适用于对话框（`showDialog`）。

A class library for obtaining and listening the offset of the widget to the edge of the root layout.
This type of library is also suitable for dialogs(`showDialog`).

<img src="https://github.com/excing/flutter_widget_offset/raw/main/example/example.gif" width="100%">

## Use `OffsetDetector`

Use `OffsetDetector` directly to get the offset of the widget to the edge of the root layout.

```dart
final OffsetDetectorController? _controller = OffsetDetectorController();

OffsetDetector(
  controller: _controller,
  onChanged: (Size size, EdgeInsets offset, EdgeInsets rootPadding) {
       print("The widget size: ${size.width}, ${size.height}");
       print(
           "The offset to edge of root(ltrb): ${offset.left}, ${offset.top}, ${offset.right}, ${offset.bottom}");
       print(
           "the root padding: ${rootPadding.left}, ${rootPadding.top}, ${rootPadding.right}, ${rootPadding.bottom}");
   },
  child: TextField(
    style: textFieldStyle,
    onChanged: (value) => _controller.notifyStateChanged(),
  ));
```

## Use `OffsetChangeObserver`

Use `OffsetChangeObserver` to observe the offset of the widget to the edge of the root layout.

```dart
class OffsetDetector extends StatefulWidget {
  OffsetDetector({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _OffsetDetectorState();
  }
}

class _OffsetDetectorState extends State<OffsetDetector>
    with WidgetsBindingObserver {
  late OffsetChangeObserver _observer;

  @override
  Widget build(BuildContext context) {
    return TextField();
  }

  void onChanged(Size size, EdgeInsets offset, EdgeInsets rootPadding) {
       print("The widget size: ${size.width}, ${size.height}");
       print(
           "The offset to edge of root(ltrb): ${offset.left}, ${offset.top}, ${offset.right}, ${offset.bottom}");
       print(
           "the root padding: ${rootPadding.left}, ${rootPadding.top}, ${rootPadding.right}, ${rootPadding.bottom}");
   }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addObserver(this);
    _observer =
        OffsetChangeObserver(context: context, onChanged: this.onChanged);
    _observer.onInitState();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    _observer.onChangeMetrics();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _observer.onChangeDependencies();
  }

  @override
  void dispose() {
    _observer.onDispose();
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }
}
```

## Example

see [widget offset change example](./example/lib/main.dart)