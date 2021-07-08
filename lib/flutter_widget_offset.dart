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

// 小部件的界面偏移量发生改变
typedef OnChanged = void Function(
  Size size,
  EdgeInsets offset,
  EdgeInsets rootPadding,
);

class OffsetDetector extends StatefulWidget {
  OffsetDetector({Key? key, required this.onChanged, required this.child})
      : super(key: key);

  final OnChanged onChanged;
  final Widget child;

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

class OffsetChangeObserver {
  static const int waitMetricsTimeoutMillis = 1000;

  OffsetChangeObserver({
    required this.context,
    required this.onChanged,
  });

  final BuildContext context;
  final OnChanged onChanged;

  final Duration _resizeOnScrollRefreshRate = const Duration(milliseconds: 500);
  ScrollPosition? _scrollPosition;
  Timer? _resizeOnScrollTimer;

  bool widgetMounted = true;
  double boxWidth = 100.0;
  double boxHeight = 100.0;

  void onInitState() {
    WidgetsBinding.instance!.addPostFrameCallback((duration) {
      // calculate initial suggestions list size
      this.resize();
    });
  }

  Future<void> onChangeMetrics() async {
    if (await _waitChangeMetrics()) {
      resize();
    }
  }

  void onChangeDependencies() {
    ScrollableState? scrollableState = Scrollable.of(context);
    if (scrollableState != null) {
      // The TypeAheadField is inside a scrollable widget
      _scrollPosition = scrollableState.position;

      _scrollPosition!.removeListener(_scrollResizeListener);
      _scrollPosition!.isScrollingNotifier.addListener(_scrollResizeListener);
    }
  }

  void onDispose() {
    this.widgetMounted = false;
    _resizeOnScrollTimer?.cancel();
    _scrollPosition?.removeListener(_scrollResizeListener);
  }

  void resize() {
    // check to see if widget is still mounted
    // user may have closed the widget with the keyboard still open
    if (widgetMounted) {
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

    boxWidth = box.size.width;
    boxHeight = box.size.height;

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
        boxHeight -
        boxAbsY;
    double widgetOffsetRight =
        windowWidth - rootPadding.left - rootPadding.right - boxWidth - boxAbsX;

    onChanged(
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
        resize();
      });
    } else {
      // Scroll finished
      resize();
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
    if (widgetMounted) {
      // initial viewInsets which are before the keyboard is toggled
      EdgeInsets initial = MediaQuery.of(context).viewInsets;
      // initial MediaQuery for orientation change
      MediaQuery? initialRootMediaQuery = _findRootMediaQuery();

      int timer = 0;
      // viewInsets or MediaQuery have changed once keyboard has toggled or orientation has changed
      while (widgetMounted && timer < waitMetricsTimeoutMillis) {
        // reduce delay if showDialog ever exposes detection of animation end
        await Future.delayed(const Duration(milliseconds: 170));
        timer += 170;

        if (widgetMounted &&
            (MediaQuery.of(context).viewInsets != initial ||
                _findRootMediaQuery() != initialRootMediaQuery)) {
          return true;
        }
      }
    }

    return false;
  }
}
