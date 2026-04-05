import 'package:flutter/material.dart';
import 'package:inventry_management/Database/orders.dart';
import '../../../Database/person.dart';
import '../../../Shared_Widgets/fonts.dart';
import '../../../Shared_Widgets/main_ui_helper.dart';
import '../../../colors.dart';
import 'choose_person.dart';

class OrderPersonCard extends StatefulWidget {
  final bool sell;
  final Person? person;
  final Order order;
  final Function(Person) onPersonSelected; // add this
  const OrderPersonCard({
    super.key,
    this.sell = true,
    this.person,
    required this.onPersonSelected,
    required this.order,
  });

  @override
  State<OrderPersonCard> createState() => _OrderPersonCardState();
}

class _OrderPersonCardState extends State<OrderPersonCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 10, right: 5),
      margin: EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: MyColors.translucent,
        borderRadius: BorderRadius.all(Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(125),
            spreadRadius: 0.5,
            blurRadius: 3,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 40,
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Person Details",
                  textAlign: TextAlign.start,
                  style: MyFont.semiBold(20, color: MyColors.darkBlue),
                ),
                SizedBox(
                  height: 30,
                  width: 100,
                  child: UiHelper.myButton(
                    title: "Select",
                    textSize: 16,
                    callback:  choosePerson,
                    filled: true,
                    color: widget.order.editable ? MyColors.info : MyColors.lightGrey,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            child: widget.person == null
                ? null
                : Container(
              padding: EdgeInsets.only(bottom: 10),
              child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 1,
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: ClipOval(
                              child: (widget.person == null)
                                  ? SizedBox()
                                  : (widget.person?.image == null)
                                  ? Container(
                                      color: MyColors.grey.withAlpha(30),
                                      child: Icon(
                                        Icons.person_rounded,
                                        size: 100,
                                      ),
                                    )
                                  : Image.memory(
                                      widget.person!.image!,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: Text(
                                  widget.person?.name ?? "",
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.start,
                                  style: MyFont.semiBold(
                                    20,
                                    color: MyColors.darkBlue,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: double.infinity,
                                child: Row(
                                  children: [
                                    (widget.person?.phone?.isEmpty ?? true) ? SizedBox(): Icon(
                                      Icons.phone_rounded,
                                      color: MyColors.info,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      widget.person?.phone ?? "",
                                      textAlign: TextAlign.start,
                                      style: MyFont.semiBold(
                                        17,
                                        color: MyColors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ),
          ),
        ],
      ),
    );
  }

  void choosePerson() async {
    if(!(widget.order.editable)){
      return;
    }
    final result = await showDialog<Person>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.zero,

          child: Container(
            width: 400,
            height: 600,
            decoration: BoxDecoration(
              color: MyColors.translucent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: ChoosePerson(
                filter: widget.sell ? 1 :2,
                person: widget.person,
            ),
          ),
        );
      },
    );

    if (result != null) {
      setState(() => widget.onPersonSelected(result));
    }
  }
}
