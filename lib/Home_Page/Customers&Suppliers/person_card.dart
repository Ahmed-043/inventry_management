import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventry_management/Shared_Widgets/main_ui_helper.dart';
import 'package:inventry_management/colors.dart';

import '../../Database/person.dart';
import '../../Shared_Widgets/fonts.dart';

class PersonCard extends StatelessWidget {
  final Person person;
  final int num;
  const PersonCard({super.key, required this.person, this.num = 0});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double width = (constraints.maxWidth / (3.5)).floorToDouble();
        // double height = constraints.maxHeight;
        return Container(
          decoration: BoxDecoration(
            color: MyColors.translucent,
            borderRadius: BorderRadius.circular(15),
            border: UiHelper.myBorder(),
            boxShadow: UiHelper.myBoxShadow(),

          ),
          child: Row(
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
                        message: 'Address: ${person.address}',
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: MyColors
                                .palette[num % MyColors.palette.length]
                                .withAlpha(30),
                          ),
                          child: person.image != null
                              ? ClipOval(
                                  child: Image.memory(
                                    person.image!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Icon(
                                  Icons.person,
                                  size: width,
                                  color: MyColors
                                      .palette[num % MyColors.palette.length]
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
                  //color: Colors.green
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 1,
                        child: Container(
                          // color: Colors.green
                        ),
                      ),
                      SizedBox(
                        //color: Colors.red,
                        width: double.infinity,
                        child: Text(
                          person.name,
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
                              person.phone != null && person.phone!.length > 4
                                  ? '${person.phone!.substring(0, 4)}-${person.phone!.substring(4)}'
                                  : person.phone ?? '',
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
                              message: person.email.toString(),
                              child: Text(
                                person.email.toString(),
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
                      SizedBox(height: width*0.05),
                      Expanded(

                        child: Row(
                          children: [
                            Tooltip(
                              waitDuration: const Duration(seconds: 1),
                              message: person.payment > 0 ? 'Receivable' : person.payment == 0 ? '' : 'Payable',
                              child: Row(
                                children: [
                                  Text( "Rs. ${NumberFormat.decimalPattern().format(person.payment)}",
                                    textAlign: TextAlign.center,
                                    style: MyFont.bold(
                                      width * 0.15,
                                      color: person.payment > 0 ? MyColors.success : person.payment == 0 ? MyColors.grey : MyColors.error,
                                    ),
                                  ),
                                  Icon(
                                    person.payment > 0 ? Icons.keyboard_double_arrow_up_rounded :  person.payment == 0 ? Icons.arrow_drop_up_rounded : Icons.keyboard_double_arrow_down_rounded,
                                    size: width * 0.15,
                                    color: person.payment > 0 ? MyColors.success : person.payment == 0 ? MyColors.grey : MyColors.error,
                                  ),
                                ],
                              ),
                            ),
                            Expanded(child: SizedBox()),
                          ],
                        ),
                      ),

                      Expanded(flex: 1, child: Container(),),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
