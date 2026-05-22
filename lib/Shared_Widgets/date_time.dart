import 'package:flutter/material.dart';
import 'package:inventry_management/Shared_Widgets/scaled_container.dart';

import '../colors.dart';
import 'fonts.dart';

Widget dateTimeField({bool isTime = false, String text = "",double borderRadius = 10}) {
  return ScaledContainer(
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: MyColors.translucent,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(width: 1.25, color: MyColors.lightGrey),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            isTime ? Icons.access_time_rounded : Icons.calendar_month_rounded,
            color: Colors.grey,
          ),
          Expanded(
            child: Center(
              child: Text(
                text.isEmpty ? "Select Date" : text,
                overflow: TextOverflow.ellipsis,
                style: MyFont.semiBold(15, color: Colors.grey.shade600),
              ),
            ),
          ),
    
        ],
      ),
    ),
  );
}


Future<DateTime?> pickDate(BuildContext context, selectedDateTime,{DateTime? firstDate,DateTime? lastDate}) async {
  final pickedDate = await showDatePicker(
    context: context,
    initialDate: selectedDateTime,
    firstDate: firstDate ?? DateTime(1900),
    lastDate: lastDate ?? DateTime(2100),
  );

  if (pickedDate != null) {
    return DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      selectedDateTime.hour,
      selectedDateTime.minute,
    );
  }
  return null;
}

Future<DateTime?> pickTime(BuildContext context, selectedDateTime) async {
  final pickedTime = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(selectedDateTime),
  );

  if (pickedTime != null) {
    return DateTime(
      selectedDateTime.year,
      selectedDateTime.month,
      selectedDateTime.day,
      pickedTime.hour,
      pickedTime.minute,
    );
  }
  return null;
}

Future<DateTime?> pickDateTime(BuildContext context, DateTime selectedDateTime,{DateTime? firstDate,DateTime? lastDate}) async {


  final pickedDate = await showDatePicker(
    context: context,
    initialDate: selectedDateTime,
    firstDate: firstDate ?? DateTime(1900),
    lastDate: lastDate ?? DateTime(2100),
  );

  if (pickedDate == null) return null;

  TimeOfDay? pickedTime = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(selectedDateTime),

  );
  if (pickedTime == null) return null;


  DateTime result = DateTime(
    pickedDate.year,
    pickedDate.month,
    pickedDate.day,
    pickedTime.hour,
    pickedTime.minute,
  );

  // Cap the DateTime so it is not before firstDate or selectedDateTime
  DateTime minAllowed = firstDate ?? selectedDateTime;
  if (result.isBefore(minAllowed)) {
    result = minAllowed;
  }

  return result;
}