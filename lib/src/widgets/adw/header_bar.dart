import 'package:dbus/dbus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gsettings/gsettings.dart';
import 'package:libadwaita/src/utils/colors.dart';
import 'package:libadwaita/src/widgets/widgets.dart';
import 'package:libadwaita_core/libadwaita_core.dart';

class HeaderBarStyle {
  const HeaderBarStyle({
    this.isTransparent = false,
    this.textStyle,
    this.height = 51,
    this.autoPositionWindowButtons = true,
    this.padding = const EdgeInsets.only(left: 3, right: 5),
    this.titlebarSpace = 6,
  });

  /// If true, background color and border color
  /// will be transparent
  final bool isTransparent;

  /// Default text style applied to the child widget.
  final TextStyle? textStyle;

  /// The height of the headerbar
  final double height;

  /// Whether to automatically place the window buttons according to
  /// the Platform, defaults to true
  /// If false then it will follow the general Windows like window buttons
  /// placement
  final bool autoPositionWindowButtons;

  /// The padding inside the headerbar
  final EdgeInsets padding;

  /// The horizontal spacing before or after the window buttons
  final double titlebarSpace;
}

class AdwHeaderBar extends StatefulWidget {
  AdwHeaderBar({
    Key? key,
    this.title,
    this.start = const [],
    this.end = const [],
    this.style = const HeaderBarStyle(),
    required AdwActions actions,
    AdwControls? controls,
  })  : closeBtn = controls != null
            ? controls.closeBtn?.call(actions.onClose)
            : AdwWindowButton(
                buttonType: WindowButtonType.close,
                onPressed: actions.onClose,
              ),
        maximizeBtn = controls != null
            ? controls.maximizeBtn?.call(actions.onMaximize)
            : AdwWindowButton(
                buttonType: WindowButtonType.maximize,
                onPressed: actions.onMaximize,
              ),
        minimizeBtn = controls != null
            ? controls.minimizeBtn?.call(actions.onMinimize)
            : AdwWindowButton(
                buttonType: WindowButtonType.minimize,
                onPressed: actions.onMinimize,
              ),
        onHeaderDrag = actions.onHeaderDrag,
        onDoubleTap = actions.onDoubleTap,
        onRightClick = actions.onRightClick,
        super(key: key);

  /// The leading widget for the headerbar
  final List<Widget> start;

  /// The center widget for the headerbar
  final Widget? title;

  /// The trailing widget for the headerbar
  final List<Widget> end;

  final Widget? minimizeBtn;

  final Widget? maximizeBtn;

  final Widget? closeBtn;

  /// Called when headerbar is dragged
  final VoidCallback? onHeaderDrag;

  /// Called when headerbar is double tapped
  final VoidCallback? onDoubleTap;

  /// Called when headerbar is right clicked
  final VoidCallback? onRightClick;

  /// Default style applied to this [AdwHeaderBar] widget.
  final HeaderBarStyle style;

  @override
  State<AdwHeaderBar> createState() => _AdwHeaderBarState();
}

class _AdwHeaderBarState extends State<AdwHeaderBar> {
  bool get hasWindowControls =>
      widget.closeBtn != null ||
      widget.minimizeBtn != null ||
      widget.maximizeBtn != null;

  ValueNotifier<List<String>?> separator = ValueNotifier(null);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final platform = Theme.of(context).platform;
      if (!kIsWeb &&
          ([TargetPlatform.linux, TargetPlatform.windows, TargetPlatform.macOS]
              .contains(platform))) {
        separator = ValueNotifier(
          ['', 'minimize,maximize,close'],
        );
      }
      if (widget.style.autoPositionWindowButtons) {
        void updateSep(String order) {
          if (!mounted) return;
          separator.value = order.split(':')
            ..map<String>(
              (e) => e
                  .split(',')
                  .where(
                    (element) =>
                        element == 'close' ||
                        element == 'maximize' ||
                        element == 'minimize',
                  )
                  .join(','),
            );
        }

        if (platform == TargetPlatform.macOS) {
          updateSep('close,maximize,minimize:');
        } else if (platform == TargetPlatform.linux) {
          final schema = GSettings('org.gnome.desktop.wm.preferences');

          try {
            final buttonLayout =
                await schema.get('button-layout') as DBusString?;
            if (buttonLayout != null) {
              updateSep(buttonLayout.value);
            }
          } catch (e) {
            debugPrint('$e');
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final windowButtons = <String, Widget?>{
      'maximize': widget.maximizeBtn,
      'minimize': widget.minimizeBtn,
      'close': widget.closeBtn,
    };

    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        onSecondaryTap: widget.onRightClick,
        behavior: HitTestBehavior.translucent,
        onPanStart: (_) => widget.onHeaderDrag?.call(),
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            decoration: BoxDecoration(
              color: !widget.style.isTransparent
                  ? Theme.of(context).appBarTheme.backgroundColor
                  : null,
              border: !widget.style.isTransparent
                  ? Border(
                      top: BorderSide(color: Theme.of(context).backgroundColor),
                      bottom: BorderSide(color: context.borderColor),
                    )
                  : null,
            ),
            height: widget.style.height,
            width: double.infinity,
            child: Stack(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onDoubleTap: widget.onDoubleTap,
                ),
                ValueListenableBuilder<List<String>?>(
                  valueListenable: separator,
                  builder: (context, sep, _) => DefaultTextStyle.merge(
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ).merge(widget.style.textStyle),
                    child: NavigationToolbar(
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (hasWindowControls &&
                              sep != null &&
                              sep[0].split(',').isNotEmpty) ...[
                            SizedBox(width: widget.style.titlebarSpace),
                            for (var i in sep[0].split(','))
                              if (windowButtons[i] != null) windowButtons[i]!,
                            SizedBox(width: widget.style.titlebarSpace),
                          ],
                          ...widget.start,
                        ],
                      ),
                      middle: widget.title,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ...widget.end,
                          if (hasWindowControls &&
                              sep != null &&
                              sep[1].split(',').isNotEmpty) ...[
                            SizedBox(width: widget.style.titlebarSpace),
                            for (var i in sep[1].split(','))
                              if (windowButtons[i] != null) windowButtons[i]!,
                            SizedBox(width: widget.style.titlebarSpace),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
