library flutter_widget_offset;

/// All cases:
///
/// ## 2. 界面滚动
/// 在 onChangeDependencies 中监听滚动事件，
/// 计算 Widget 的新位置
///
/// ## 3. 横竖屏切换
/// ## 4. 动画过渡
/// 例如使用 [showDialog] 打开对话框，
/// 对话框从出现到完成，会有一段过渡动画，
/// 持续时间是 150ms，
/// 我们在 onChangeMetrics 中，
/// 延迟直到键盘切换或方向完全改变，
/// 才开始计算位置
///
/// ## 5. 初始化
/// 在 onInitState 中监听 addPostFrameCallback 函数，
/// 计算初始位置
///
/// ## 1. 软键盘
/// 当以后用例最终走到计算位置时，
///

import 'dart:async';

import 'package:flutter/cupertino.dart';

/// OnChanged is the method called when the widget is offset.
/// It has three parameters, [size], [offset] and [rootPadding].
///
/// The [size] is the size of the widget after it is offset.
/// The [offset] is the offset of the widget from the edge of the root layout.
/// The [rootPadding] is the padding value from the root layout to the edge of the screen.
typedef OnChanged = void Function(
  Size size,
  EdgeInsets offset,
  EdgeInsets rootPadding,
);

/// OffsetDetectorController is used to control
/// and notify the OffsetDetector widget.
class OffsetDetectorController extends ChangeNotifier {
  /// Notify [OffsetDetector] that the status of his [child] has changed.
  void notifyStateChanged() {
    notifyListeners();
  }
}

/// OffsetDetector is a widget that encapsulates [OffsetChangeObserver].
///
/// When the screen position of [child] changes,
/// such as horizontal and vertical screen switching,
/// soft keyboard display and hiding, etc.,
/// [onChanged] will be called.
///
/// This snippet will print [size], [offset], [rootPadding] when the widget is offset.
///
/// ```dart
/// Padding(
///   padding: EdgeInsets.fromLTRB(8, 0, 8, 3),
///   child: OffsetDetector(
///       onChanged: (Size size, EdgeInsets offset, EdgeInsets rootPadding) {
///           print("The widget size: ${size.width}, ${size.height}");
///           print(
///            "The offset to edge of root(ltrb): ${offset.left}, ${offset.top}, ${offset.right}, ${offset.bottom}");
///           print(
///            "the root padding: ${rootPadding.left}, ${rootPadding.top}, ${rootPadding.right}, ${rootPadding.bottom}");
///       },
///       child: TextField(
///         style: textFieldStyle,
///       )),
/// )
/// ```
class OffsetDetector extends StatefulWidget {
  /// Create a widget whose offset state needs to be observed.
  ///
  /// The [onChanged] argument must not be null.
  /// The [child] argument must not be null.
  OffsetDetector({
    Key? key,
    required this.onChanged,
    required this.child,
    OffsetDetectorController? controller,
  })  : this.controller = controller ?? OffsetDetectorController(),
        super(key: key);

  /// Callback method when offset occurs
  final OnChanged onChanged;

  /// child is the widget that needs to be observed
  final Widget child;

  /// Controller of OffsetDetector
  final OffsetDetectorController controller;

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
    return widget.child;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addObserver(this);
    _observer =
        OffsetChangeObserver(context: context, onChanged: widget.onChanged);
    _observer.onInitState();
    widget.controller.addListener(_handleChangeState);
  }

  @override
  void didUpdateWidget(covariant OffsetDetector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_handleChangeState);
      widget.controller.addListener(_handleChangeState);
    }
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

  void _handleChangeState() {
    if (mounted) {
      _observer.onChangeState();
    }
  }
}

/// OffsetChangeObserver will observe the offset status of the widget.
///
/// Use of this observer requires widget inheritance [WidgetsBindingObserver]
class OffsetChangeObserver {
  static const int _waitMetricsTimeoutMillis = 1000;

  /// Create an observer who needs to observe the offset state of the widget.
  ///
  /// The [context] argument must not be null.
  /// The [onChanged] argument must not be null.
  OffsetChangeObserver({
    required this.context,
    required this.onChanged,
  });

  /// context is the context object of the widget that needs to be observed.
  final BuildContext context;

  /// Callback method when offset occurs.
  final OnChanged onChanged;

  final Duration _resizeOnScrollRefreshRate = const Duration(milliseconds: 500);
  ScrollPosition? _scrollPosition;
  Timer? _resizeOnScrollTimer;

  bool _widgetMounted = true;
  double _boxWidth = 100.0;
  double _boxHeight = 100.0;

  /// Initialization state.
  ///
  /// It is usually called in the [State.initState] method of [State].
  void onInitState() {
    WidgetsBinding.instance!.addPostFrameCallback((duration) {
      // calculate initial suggestions list size
      this._resize();
    });
  }

  /// Called when the application's dimensions change.
  ///
  /// It is usually called in the [WidgetsBindingObserver.didChangeMetrics] method of [WidgetsBindingObserver]
  Future<void> onChangeMetrics() async {
    if (await _waitChangeMetrics()) {
      _resize();
    }
  }

  /// Called when the state changes.
  ///
  /// It is usually called after the [State.setState] method
  /// or after updating the content of the widget.
  ///
  /// Please do not call it in the [State.didUpdateWidget] method.
  /// If you must do this, the [State.setState] method must not be called
  /// in the [onChanged] callback function,
  /// otherwise infinite recursion will occur.
  void onChangeState() async {
    if (!_widgetMounted) return;

    await Future.delayed(const Duration(milliseconds: 50));

    RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null || box.hasSize == false) {
      return;
    }
    if (box.size.width != _boxWidth || box.size.height != _boxHeight) {
      this._resize();
    }
  }

  /// Called when a dependency of this [State] object changes.
  ///
  /// It is usually called in the [WidgetsBindingObserver.didChangeDependencies] method of [WidgetsBindingObserver]
  void onChangeDependencies() {
    ScrollableState? scrollableState = Scrollable.of(context);
    if (scrollableState != null) {
      // The TypeAheadField is inside a scrollable widget
      _scrollPosition = scrollableState.position;

      _scrollPosition!.removeListener(_scrollResizeListener);
      _scrollPosition!.isScrollingNotifier.addListener(_scrollResizeListener);
    }
  }

  /// Called when this object is removed from the tree permanently.
  ///
  /// It is usually called in the [State.dispose] method of [State].
  void onDispose() {
    this._widgetMounted = false;
    _resizeOnScrollTimer?.cancel();
    _scrollPosition?.removeListener(_scrollResizeListener);
  }

  void _resize() {
    // check to see if widget is still mounted
    // user may have closed the widget with the keyboard still open
    if (_widgetMounted) {
      _adjustMaxHeightAndOrientation();
    }
  }

  // See if there's enough room in the desired direction for the overlay to display
  // correctly. If not, try the opposite direction if things look more roomy there
  void _adjustMaxHeightAndOrientation() {
    RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null || box.hasSize == false) {
      return;
    }

    _boxWidth = box.size.width;
    _boxHeight = box.size.height;

    Offset boxGlobalOffset = box.localToGlobal(Offset.zero);
    // left of widget box
    double boxAbsX = boxGlobalOffset.dx;
    // top of widget box
    double boxAbsY = boxGlobalOffset.dy;

    // width of window
    double windowWidth = MediaQuery.of(context).size.width;
    // height of window
    double windowHeight = MediaQuery.of(context).size.height;

    // we need to find the root MediaQuery for the unsafe area height
    // we cannot use BuildContext.ancestorWidgetOfExactType because
    // widgets like SafeArea creates a new MediaQuery with the padding removed
    MediaQuery rootMediaQuery = _findRootMediaQuery()!;

    // height of keyboard
    double keyboardHeight = rootMediaQuery.data.viewInsets.bottom;
    // recalculate keyboard absolute y value
    double keyboardAbsY = windowHeight - keyboardHeight;

    EdgeInsets rootPadding = rootMediaQuery.data.padding;
    double unsafeUpAreaHeight = rootPadding.top;
    double unsafeDownAreaHeight = keyboardHeight == 0 ? rootPadding.bottom : 0;

    double widgetOffsetTop = boxAbsY > keyboardAbsY
        ? keyboardAbsY - unsafeUpAreaHeight
        : boxAbsY - unsafeUpAreaHeight;
    double widgetOffsetLeft = boxAbsX - rootPadding.left;
    double widgetOffsetBottom = windowHeight -
        keyboardHeight -
        unsafeDownAreaHeight -
        _boxHeight -
        boxAbsY;
    double widgetOffsetRight = windowWidth -
        rootPadding.left -
        rootPadding.right -
        _boxWidth -
        boxAbsX;

    this.onChanged(
        box.size,
        EdgeInsets.fromLTRB(widgetOffsetLeft, widgetOffsetTop,
            widgetOffsetRight, widgetOffsetBottom),
        rootPadding);
  }

  void _scrollResizeListener() {
    bool isScrolling = _scrollPosition!.isScrollingNotifier.value;
    _resizeOnScrollTimer?.cancel();
    if (isScrolling) {
      // Scroll started
      _resizeOnScrollTimer =
          Timer.periodic(_resizeOnScrollRefreshRate, (timer) {
        _resize();
      });
    } else {
      // Scroll finished
      _resize();
    }
  }

  MediaQuery? _findRootMediaQuery() {
    MediaQuery? rootMediaQuery;
    context.visitAncestorElements((element) {
      if (element.widget is MediaQuery) {
        rootMediaQuery = element.widget as MediaQuery;
      }
      return true;
    });

    return rootMediaQuery;
  }

  /// Delays until the keyboard has toggled or the orientation has fully changed
  Future<bool> _waitChangeMetrics() async {
    if (_widgetMounted) {
      // initial viewInsets which are before the keyboard is toggled
      EdgeInsets initial = MediaQuery.of(context).viewInsets;
      // initial MediaQuery for orientation change
      MediaQuery? initialRootMediaQuery = _findRootMediaQuery();

      int timer = 0;
      // viewInsets or MediaQuery have changed once keyboard has toggled or orientation has changed
      while (_widgetMounted && timer < _waitMetricsTimeoutMillis) {
        // reduce delay if showDialog ever exposes detection of animation end
        await Future.delayed(const Duration(milliseconds: 170));
        timer += 170;

        if (_widgetMounted &&
            (MediaQuery.of(context).viewInsets != initial ||
                _findRootMediaQuery() != initialRootMediaQuery)) {
          return true;
        }
      }
    }

    return false;
  }
}
