import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inventry_management/Shared_Widgets/fonts.dart';
import 'package:inventry_management/Shared_Widgets/scaled_container.dart';
import '../Database/database.dart';
import '../colors.dart';
import 'package:pdf/widgets.dart' as pw;

class _ToastRequest {
  const _ToastRequest(this.message, this.type);

  final String message;
  final int type;
}

class _ToastVisuals {
  const _ToastVisuals({
    required this.message,
    required this.backgroundColorValue,
    required this.textColorValue,
  });

  final String message;
  final int backgroundColorValue;
  final int textColorValue;
}

_ToastVisuals _resolveToastVisuals(_ToastRequest request) {
  switch (request.type) {
    case 1: // success
      return _ToastVisuals(
        message: request.message,
        backgroundColorValue: MyColors.success.toARGB32(),
        textColorValue: MyColors.translucent.toARGB32(),
      );
    case 2: // warning
      return _ToastVisuals(
        message: request.message,
        backgroundColorValue: MyColors.warning.toARGB32(),
        textColorValue: MyColors.dark.toARGB32(),
      );
    case 3: // error
      return _ToastVisuals(
        message: request.message,
        backgroundColorValue: MyColors.error.toARGB32(),
        textColorValue: MyColors.translucent.toARGB32(),
      );
    case 0:
    default:
      return _ToastVisuals(
        message: request.message,
        backgroundColorValue: MyColors.grey.toARGB32(),
        textColorValue: MyColors.translucent.toARGB32(),
      );
  }
}

class _AnimatedToast extends StatefulWidget {
  const _AnimatedToast({
    required this.message,
    required this.backgroundColor,
    required this.textColor,
    required this.onDismissed,
  });

  final String message;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onDismissed;

  @override
  State<_AnimatedToast> createState() => _AnimatedToastState();
}

class _AnimatedToastState extends State<_AnimatedToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _controller.forward();
    Future.delayed(const Duration(seconds: 4), _dismiss);
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    await _controller.reverse();
    if (mounted) {
      widget.onDismissed();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 20,
      child: SafeArea(
        minimum: const EdgeInsets.symmetric(horizontal: 16),
        child: IgnorePointer(
          ignoring: true,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _offsetAnimation,
              child: Material(
                color: Colors.transparent,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: widget.backgroundColor,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Text(
                      widget.message,
                      style: TextStyle(color: widget.textColor),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class UiHelper {
  static Widget myTextField({
    String? label,
    required TextEditingController controller,
    String? hint,
    String? prefixText = '',
    bool readOnly = false,
    bool autofocus = false,
    VoidCallback? onTap,
    double fontSize = 17,
    double borderRadius = 10,
    TextInputType? textType,
    List<TextInputFormatter>? inputFormatters,
    VoidCallback? onChange,
    FocusNode? focusNode,
    Widget? suffix,
    Widget? prefix,
    EdgeInsets? padding,
  }) {
    return TextField(
      autofocus: autofocus,
      onTap: onTap,
      readOnly: readOnly,
      controller: controller,
      keyboardType: textType,
      inputFormatters: inputFormatters,
      onChanged: (_) => onChange?.call(),

      focusNode: focusNode,
      style: MyFont.normal(fontSize, color: MyColors.darkBlue),
      cursorColor: MyColors.darkBlue,
      textAlignVertical: TextAlignVertical.center,
      //TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        prefixText: '$prefixText',
        suffixIcon: suffix,
        contentPadding: padding,
        prefixIcon: prefix,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(width: 2, color: MyColors.lightGrey),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(width: 2, color: MyColors.darkBlue),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius + 10),
          borderSide: BorderSide(width: 2, color: MyColors.darkBlue),
        ),
        labelText: label,
        labelStyle: MyFont.semiBold(
          fontSize,
          color: MyColors.darkBlue.withAlpha(230),
        ),
        //TextStyle(fontSize:fontSize, color: MyColors.darkBlue.withAlpha(230),fontWeight: FontWeight.w600),
        hint: hint == null
            ? null
            : Text(hint, style: MyFont.normal(fontSize, color: MyColors.grey)),
      ),
    );
  }

  static Widget myTextArea({
    required TextEditingController controller,
    String? label,
    int? maxLines,
    bool readOnly = false,
    TextInputType textType = TextInputType.multiline,
    String hint = '',
    double fontSize = 15,
    VoidCallback? onChanged,
    VoidCallback? onTap,
    double borderRadius =15,
    FocusNode? focusNode,
  }) {
    return TextField(
      maxLines: maxLines,
      controller: controller, // expands as you type
      keyboardType: textType,
      onChanged: (_) => onChanged?.call(),
      focusNode: focusNode,
      readOnly: readOnly,
      onTap: onTap,
      style: MyFont.normal(fontSize),
      cursorColor: MyColors.darkBlue,
      decoration: InputDecoration(
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(width: 2, color: MyColors.lightGrey),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(width: 2, color: MyColors.darkBlue),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius+10),
          borderSide: BorderSide(width: 2, color: MyColors.darkBlue),
        ),
        labelText: label,
        labelStyle: MyFont.semiBold(fontSize, color: MyColors.darkBlue),
        hint: Text(hint, style: MyFont.normal(fontSize, color: MyColors.grey)),
        //TextStyle(fontSize: 20, color: MyColors.darkBlue),
      ),
    );
  }

  static Widget myButton({
    String? title,
    required VoidCallback callback,
    VoidCallback? rightClick,
    double textSize = 20,
    bool filled = false,
    Color? color,
    Widget? child,
    double borderRadius = 20,
    double? elevation,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
  }) {
    return Material(
      color: Colors.transparent,
      child: ScaledContainer(
        child: GestureDetector(
          onSecondaryTap: rightClick,
          behavior: HitTestBehavior.opaque,

          child: ElevatedButton(
            onPressed: callback,
            style: ElevatedButton.styleFrom(
              padding: padding, // removes internal padding

              backgroundColor: filled
                  ? color ?? MyColors.primary
                  : MyColors.translucent,
              overlayColor: filled
                  ? MyColors.translucent.withAlpha(30)
                  : color ?? MyColors.primary.withAlpha(20), // splash color
              elevation: elevation,
              enableFeedback: true,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                side: BorderSide(color: color ?? MyColors.primary,width: 0.5),
              ),
            ),
            child: Center(
              child: (child == null)
                  ? Text(
                      title ?? '',
                      overflow: TextOverflow.ellipsis,
                      style: MyFont.semiBold(
                        textSize,
                        color: filled
                            ? MyColors.translucent
                            : color ?? MyColors.primary,
                      ),
                    )
                  : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      child,
                      if (title != null )SizedBox(width: 10),
                      if (title != null)
                        Text(
                          title,
                          overflow: TextOverflow.ellipsis,
                          style: MyFont.semiBold(
                            textSize,
                            color: filled
                                ? MyColors.translucent
                                : color ?? MyColors.primary,
                          ),
                        ),
                    ],
                  ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget mySelectableButton({
    required String title,
    required bool isSelected, // 🔹 controls pressed/highlighted state
    required VoidCallback onPressed,
    double textSize = 15,
    bool list = false,
  }) {
    final bgColor = isSelected
        ? MyColors.primary
        : Colors.grey.withAlpha(50); // unselected: grey
    final textColor = isSelected ? MyColors.translucent : MyColors.darkBlue;

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        overlayColor: Colors.transparent, // 🚫 disables hover + ripple
        shadowColor: Colors.transparent, // removes shadow flicker
        elevation: 0,
        backgroundColor: bgColor,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: MyFont.semiBold(textSize, color: textColor),
          ),
          if(list)
            Icon(Icons.keyboard_arrow_down, color: textColor)
        ],
      ),
    );
  }

  static Widget myFilePicker({
    required VoidCallback callBack,
    Color color = MyColors.light,
    Widget? child,
  }) {
    return ElevatedButton(
      onPressed: callBack,
      style: ElevatedButton.styleFrom(
        elevation: 4,
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      child: child ?? Icon(Icons.file_open, color: MyColors.primary),
    );
  }

  static Widget mySearchBar({
    required TextEditingController controller,
    double fontSize = 20,
    String hint = 'Search',
    required VoidCallback onChange,
    VoidCallback? onPressed,
    VoidCallback? onCancel,
    bool readOnly = false,
  }) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return TextField(
          enabled: !readOnly,
          controller: controller,
          onChanged: (_) => onChange.call(),
          style: MyFont.semiBold(fontSize, color: MyColors.grey),
          cursorColor: MyColors.primary,
          decoration: InputDecoration(
            isDense: true,

            prefixIcon: IconButton(
              icon: Icon(Icons.search_rounded,color: MyColors.grey, size: 25),
              onPressed: onPressed,
            ),
            suffixIcon: value.text.isNotEmpty
                ? IconButton(
              icon: Icon(Icons.close_rounded, size: 25),
              color: MyColors.grey,
              onPressed: onCancel,
            )
                : null,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(width: 1.7, color: MyColors.lightGrey),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(width: 1.7, color: MyColors.lightGrey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(width: 2, color: MyColors.grey),
            ),
            hintText: hint,
            hintStyle: MyFont.normal(fontSize, color: MyColors.grey),
          ),
        );
      },
    );
  }


  static Widget componentWidget({
    int? id,
    number,
    String? name,
    String? sku,
    Uint8List? image,
    required VoidCallback add,
    sub,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: MyColors.transparent,
        borderRadius: BorderRadius.all(Radius.circular(15)),
      ),
      margin: EdgeInsets.all(6),
      width: double.infinity,
      // color: MyColors.translucent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: image != null
                  ? Image.memory(image, fit: BoxFit.contain)
                  : Icon(Icons.image_not_supported, size: 100),
            ),
          ),
          myContainer(title: sku ?? name ?? ''),

          SizedBox(
            width: double.infinity,
            height: 30,

            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  flex: 1,
                  child: InkWell(
                    onTap: sub,
                    child: Icon(Icons.remove, color: MyColors.error),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    height: double.infinity,
                    child: Text(
                      number.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: MyColors.blue,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: InkWell(
                    onTap: add,
                    child: Icon(Icons.add, color: MyColors.success),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget myContainer({
    Widget? child,
    String title = '',
    double? width,
    double? height,
  }) {
    return SizedBox(
      height: height ?? 30,
      width: width,
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child:
            child ??
            Align(
              alignment: Alignment.centerLeft,
              child: Center(
                child: Text(
                  title,
                  //textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: MyColors.blue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
      ),
    );
  }

  static Widget elevatedIconButton({
    required VoidCallback callBack,
    Color? color,
    required Icon icon,
    required Text label,
  }) {
    return ElevatedButton.icon(
      onPressed: callBack,
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? MyColors.translucent,
        overlayColor: color == null ? MyColors.blue : MyColors.translucent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: color ?? MyColors.grey),
        ),
      ),
      icon: icon,
      label: label,
    );
  }

  static Widget waterMark({String text = 'Odventory', int? repeat}) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final height = constraints.maxHeight;
          final repeats =
              repeat ?? (height / 200).round(); // prevent infinity or 0

          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: .center,
            children: List.generate(
              repeats,
              (_) => SizedBox(
                child: Center(
                  child: Transform.rotate(
                    angle: -0.785398, // 45 degrees
                    child: Text(
                      text,
                      textAlign: TextAlign.center,
                      style: MyFiraFont.bold(
                        35,
                        color: Colors.black.withAlpha((255 * 0.04).toInt()),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static pw.Widget pdfWaterMark({String text = 'Odventory', int? repeat}) {
    return pw.LayoutBuilder(
      builder: (context, constraints) {
        final height =
            constraints?.maxHeight ?? 600; // use 800 or any default page height
        final repeats = repeat ?? (height / 100).round().clamp(1, 10);

        // Light gray (similar to black with 5% opacity)
        //final watermarkColor = pdf.PdfColor(0.90, 0.9, 0.9); // light gray

        return pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: List.generate(
            repeats,
            (_) => pw.Center(
              child: pw.Transform.rotate(
                angle: 0.785398, // 45 degrees
                child: pw.Opacity(
                  opacity: 0.06,
                  child: pw.Text(
                    text,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      // color: watermarkColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  static void showToast(BuildContext context, String message, {int type=0}) {
    _showToast(context, message, type);
  }

  static Future<void> _showToast(BuildContext context, String message, int type) async {
    final overlay = Overlay.of(context);
    final visuals = await compute(_resolveToastVisuals, _ToastRequest(message, type));

    if (!context.mounted) return;

    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (_) => _AnimatedToast(
        message: visuals.message,
        backgroundColor: Color(visuals.backgroundColorValue),
        textColor: Color(visuals.textColorValue),
        onDismissed: () {
          if (overlayEntry.mounted) {
            overlayEntry.remove();
          }
        },
      ),
    );

    overlay.insert(overlayEntry);
  }
  
  
  static BoxBorder myBorder(){
    return BoxBorder.all(color: plainUi ? MyColors.lightGrey : Colors.transparent, width: plainUi ? 1.5 : 0);
  }
  static List<BoxShadow> myBoxShadow(){
    return [
    if(!plainUi)
    BoxShadow(
    color: Colors.grey.withAlpha(100),
    spreadRadius: 0.5,
    blurRadius: 3,
    offset: const Offset(-1, 1),
    ),
    ];
  }
  static BoxDecoration myDecoration({bool isHovered = false}) {
    return BoxDecoration(
      border: myBorder(),
      boxShadow: [
        if (!plainUi)
          BoxShadow(
            color: Colors.grey.withAlpha(isHovered ? 150 : 100),
            spreadRadius: isHovered ? 1.0 : 0.5,
            blurRadius: isHovered ? 6 : 4,
            offset: const Offset(-1, 1),
          ),
      ],
      borderRadius: BorderRadius.circular(16),
      color: MyColors.translucent,
    );
  }
  static Future<T?> pushPage<T>({required BuildContext context, required Widget page, bool opaque = true, Color barrierColor = Colors.black54, bool barrierDismissible = false}){
    if(performanceMode){
      return Navigator.of(context).push<T>(
        PageRouteBuilder(
          barrierDismissible: barrierDismissible,
          opaque: opaque,
          barrierColor: barrierColor,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
        ),
      );
    }else {
      return Navigator.of(context).push<T>(
        PageRouteBuilder(
          opaque: opaque,
          barrierColor: barrierColor,
          barrierDismissible: barrierDismissible,
          transitionDuration: const Duration(milliseconds: 500), // slower transition
          reverseTransitionDuration: const Duration(milliseconds: 500), // pop
          pageBuilder: (context, animation, secondaryAnimation) =>page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      );
    }
  }

  static Future<String?> showDirectoryPicker(BuildContext context, String? initialPath) async {
    try {
      String? selectedDir = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Backup Directory',
        initialDirectory: initialPath, // can be null
      );
      if (selectedDir == null) {
        // User canceled the picker
        return null;
      }
      if(context.mounted){
        UiHelper.showToast(context, 'Backup Folder Changed',type:1);
      }
      return selectedDir;
    } catch (e) {
      // Handle errors
      if(context.mounted) {
        return showDirectoryPicker(context, null);
      }
      return null;
    }
  }
  static Widget appLogo({String path = 'assets/images/app_logo.png'}){
    return  Image.asset(
      path,
      opacity: const AlwaysStoppedAnimation<double>(0.35),
    );
  }
}
