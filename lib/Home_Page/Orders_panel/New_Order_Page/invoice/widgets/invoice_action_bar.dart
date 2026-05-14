import 'package:flutter/material.dart';
import '../../../../../Shared_Widgets/main_ui_helper.dart';
import '../../../../../colors.dart';

class InvoiceActionBar extends StatelessWidget {
  final bool showConfirm;
  final bool isLoading;
  final bool isSharing;
  final String confirmTitle;
  final VoidCallback onConfirm;
  final VoidCallback onShare;
  final VoidCallback onSavePdf;
  final VoidCallback onSaveImage;

  const InvoiceActionBar({
    super.key,
    required this.showConfirm,
    required this.isLoading,
    required this.isSharing,
    required this.confirmTitle,
    required this.onConfirm,
    required this.onShare,
    required this.onSavePdf,
    required this.onSaveImage,
  });

  @override
  Widget build(BuildContext context) {
    if (showConfirm) {
      return UiHelper.myButton(
        callback: onConfirm,
        title: confirmTitle,
        child: isLoading
            ? const SizedBox(
                height: 30,
                width: 30,
                child: CircularProgressIndicator(
                  color: MyColors.translucent,
                ),
              )
            : null,
        color: MyColors.info,
        filled: true,
      );
    }

    return Row(
      children: [
        Expanded(
          child: UiHelper.myButton(
            callback: onShare,
            title: "Share Receipt",
            child: isSharing
                ? const SizedBox(
                    width: 25,
                    height: 25,
                    child: CircularProgressIndicator(
                      color: MyColors.info,
                      strokeWidth: 3,
                      strokeCap: StrokeCap.round,
                    ),
                  )
                : const Icon(
                    Icons.share_rounded,
                    size: 25,
                    color: MyColors.info,
                  ),
            color: MyColors.info,
            borderRadius: 15,
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: UiHelper.myButton(
            rightClick: onSaveImage,
            callback: onSavePdf,
            title: "Save as PDF",
            child: const Icon(
              Icons.picture_as_pdf,
              size: 25,
              color: MyColors.translucent,
            ),
            filled: true,
            color: MyColors.info,
            borderRadius: 15,
          ),
        ),
      ],
    );
  }
}

