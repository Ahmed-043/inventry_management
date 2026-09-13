import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventry_management/Shared_Widgets/scaled_container.dart';
import 'package:inventry_management/colors.dart';
import '../../Database/person.dart';
import '../../Shared_Widgets/fonts.dart';
import 'person_payment_dialog.dart';

class PersonCard extends StatefulWidget {
  final Person person;
  final int num;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onSecondaryTap;
  final VoidCallback? onPaymentSaved;
  final Color? splashColor;
  final Color? hoverColor;

  const PersonCard({
    super.key,
    required this.person,
    this.num = 0,
    this.onTap,
    this.onDoubleTap,
    this.onSecondaryTap,
    this.onPaymentSaved,
    this.splashColor,
    this.hoverColor,
  });

  @override
  State<PersonCard> createState() => _PersonCardState();
}

class _PersonCardState extends State<PersonCard> {
  String _getInitials(String name) {
    if (name.isEmpty) return '';
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final avatarColor = MyColors.palette[widget.num % MyColors.palette.length];

    return ScaledContainer(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onSecondaryTap: widget.onSecondaryTap,
            onTapDown: (TapDownDetails details) async {
              final tapPosition = details.globalPosition;
              final screenSize = MediaQuery.of(context).size;
              const double dialogWidth = 350;
              const double dialogHeight = 180;

              double left = (tapPosition.dx - 100).clamp(10.0, screenSize.width - dialogWidth - 10.0);
              double top = tapPosition.dy;

              if (top + dialogHeight > screenSize.height) {
                top = tapPosition.dy - dialogHeight + 50;
              }
              top = top.clamp(10.0, screenSize.height - dialogHeight - 10.0);

              await PersonPaymentDialog.show(
                context: context,
                person: widget.person,
                left: left,
                top: top,
                onPaymentSaved: widget.onPaymentSaved,
              );
            },
            splashColor: widget.splashColor ?? MyColors.primary.withOpacity(0.1),
            hoverColor: widget.hoverColor ?? MyColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(15),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final h = constraints.maxHeight;
                final factor = (h / 167.0).clamp(0.6, 2.0);

                return Padding(
                  padding: EdgeInsets.all(15.0 * factor),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Avatar, Name, Phone
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 50 * factor,
                            height: 50 * factor,
                            decoration: BoxDecoration(
                              color: avatarColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: widget.person.image != null
                                ? ClipOval(
                                    child: Image.memory(
                                      widget.person.image!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      _getInitials(widget.person.name),
                                      style: MyFont.bold(18 * factor, color: avatarColor),
                                    ),
                                  ),
                          ),
                          SizedBox(width: 12 * factor),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.person.name,
                                  style: MyFont.bold(16 * factor, color: MyColors.darkBlue),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (widget.person.phone != null && widget.person.phone!.isNotEmpty)
                                  Text(
                                    widget.person.phone!,
                                    style: MyFont.normal(13 * factor, color: MyColors.grey),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8 * factor),
                      // Email
                      if (widget.person.email != null && widget.person.email!.isNotEmpty)
                        Text(
                          widget.person.email!,
                          style: MyFont.normal(13 * factor, color: MyColors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const Spacer(),
                      // Bottom Info: Total Purchase & Outstanding
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                  Text(
                                    'PENDING RECEIVABLE',
                                    style: MyFont.bold(10 * factor, color: MyColors.textSecondary),
                                  ),
                                  SizedBox(height: 4 * factor),
                                  Text(
                                    NumberFormat.simpleCurrency(name: 'Rs. ', decimalDigits: 0).format(widget.person.incoming),
                                    style: MyFont.bold(15 * factor,
                                        color: MyColors.success),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'PENDING PAYMENT',
                                    style: MyFont.bold(10 * factor, color: MyColors.textSecondary),
                                  ),
                                  SizedBox(height: 4 * factor),
                                  Text(
                                    NumberFormat.simpleCurrency(name: 'Rs. ', decimalDigits: 0).format(widget.person.outgoing),
                                    style: MyFont.bold(15 * factor,
                                      color:  MyColors.error),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
    );
  }
}
