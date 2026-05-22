import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventry_management/Shared_Widgets/main_ui_helper.dart';
import 'package:inventry_management/colors.dart';

import '../../Database/person.dart';
import '../../Shared_Widgets/fonts.dart';

class PersonCard extends StatefulWidget {
  final Person person;
  final int num;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onSecondaryTap;
  final Color? splashColor;
  final Color? hoverColor;

  const PersonCard({
    super.key,
    required this.person,
    this.num = 0,
    this.onTap,
    this.onDoubleTap,
    this.onSecondaryTap,
    this.splashColor,
    this.hoverColor,
  });

  @override
  State<PersonCard> createState() => _PersonCardState();
}

class _PersonCardState extends State<PersonCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..scale(_isHovered ? 1.03 : 1.0),
        transformAlignment: Alignment.center,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onDoubleTap: widget.onDoubleTap,
            onSecondaryTap: widget.onSecondaryTap,
            splashColor: widget.splashColor ?? MyColors.primary.withOpacity(0.1),
            hoverColor: widget.hoverColor ?? MyColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(15),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: UiHelper.myDecoration(isHovered: _isHovered).copyWith(
                borderRadius: BorderRadius.circular(15),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  double width = (constraints.maxWidth / (3.5)).floorToDouble();
                  return Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Padding(
                          padding: EdgeInsets.only(left: width * 0.1),
                          child: Center(
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: Tooltip(
                                waitDuration: const Duration(seconds: 1),
                                message: 'Address: ${widget.person.address}',
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: MyColors
                                        .palette[widget.num % MyColors.palette.length]
                                        .withAlpha(30),
                                  ),
                                  child: widget.person.image != null
                                      ? ClipOval(
                                          child: Image.memory(
                                            widget.person.image!,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : Icon(
                                          Icons.person,
                                          size: width,
                                          color: MyColors
                                              .palette[widget.num % MyColors.palette.length]
                                              .withAlpha(150),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: EdgeInsets.only(left: width * 0.1),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 1,
                                child: Container(),
                              ),
                              SizedBox(
                                width: double.infinity,
                                child: Text(
                                  widget.person.name,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.left,
                                  style: MyFont.semiBold(
                                    width * 0.20,
                                    color: MyColors.darkBlue,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(
                                    Icons.phone,
                                    size: width * 0.15,
                                    color: MyColors.info,
                                  ),
                                  SizedBox(width: width * 0.05),
                                  Expanded(
                                    child: Text(
                                      widget.person.phone != null && widget.person.phone!.length > 4
                                          ? '${widget.person.phone!.substring(0, 4)}-${widget.person.phone!.substring(4)}'
                                          : widget.person.phone ?? '',
                                      overflow: TextOverflow.ellipsis,
                                      softWrap: false,
                                      style: MyFont.semiBold(
                                        width * 0.15,
                                        color: MyColors.grey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Icon(
                                    Icons.email,
                                    size: width * 0.15,
                                    color: MyColors.info,
                                  ),
                                  SizedBox(width: width * 0.05),
                                  Expanded(
                                    child: Tooltip(
                                      waitDuration: const Duration(seconds: 1),
                                      message: widget.person.email.toString(),
                                      child: Text(
                                        widget.person.email.toString(),
                                        overflow: TextOverflow.ellipsis,
                                        softWrap: false,
                                        style: MyFont.semiBold(
                                          width * 0.12,
                                          color: MyColors.grey,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: width * 0.05),
                              Expanded(
                                child: Row(
                                  children: [
                                    Tooltip(
                                      waitDuration: const Duration(seconds: 1),
                                      message: widget.person.payment > 0 ? 'Receivable' : widget.person.payment == 0 ? '' : 'Payable',
                                      child: Row(
                                        children: [
                                          Text(
                                            "Rs. ${NumberFormat.decimalPattern().format(widget.person.payment)}",
                                            textAlign: TextAlign.center,
                                            style: MyFont.bold(
                                              width * 0.15,
                                              color: widget.person.payment > 0 ? MyColors.success : widget.person.payment == 0 ? MyColors.grey : MyColors.error,
                                            ),
                                          ),
                                          Icon(
                                            widget.person.payment > 0 ? Icons.keyboard_double_arrow_up_rounded : widget.person.payment == 0 ? Icons.arrow_drop_up_rounded : Icons.keyboard_double_arrow_down_rounded,
                                            size: width * 0.15,
                                            color: widget.person.payment > 0 ? MyColors.success : widget.person.payment == 0 ? MyColors.grey : MyColors.error,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(child: SizedBox()),
                                  ],
                                ),
                              ),
                              Expanded(flex: 1, child: Container()),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
