import 'package:flutter/material.dart';
import 'package:inventry_management/Database/orders.dart';
import '../../../../Database/person.dart';
import '../../../../Shared_Widgets/fonts.dart';
import '../../../../Shared_Widgets/main_ui_helper.dart';
import '../../../../colors.dart';
import '../dialogs/choose_person.dart';

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
    return Hero(
      tag: "person_card",
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.only(left: 10, right: 5),
          margin: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            color: MyColors.translucent,
            borderRadius: const BorderRadius.all(Radius.circular(20)),
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
              _buildHeader(),
              _buildPersonBody(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SizedBox(
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
              callback: choosePerson,
              filled: true,
              color: widget.order.editable ? MyColors.info : MyColors.lightGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonBody() {
    final person = widget.person;
    if (person == null) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 1,
            child: AspectRatio(
              aspectRatio: 1,
              child: ClipOval(child: _buildAvatar(person)),
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
                    person.name,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.start,
                    style: MyFont.semiBold(20, color: MyColors.darkBlue),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: Row(
                    children: [
                      if (person.phone?.isNotEmpty ?? false)
                        Icon(
                          Icons.phone_rounded,
                          color: MyColors.info,
                          size: 20,
                        ),
                      if (person.phone?.isNotEmpty ?? false)
                        const SizedBox(width: 5),
                      Text(
                        person.phone ?? "",
                        textAlign: TextAlign.start,
                        style: MyFont.semiBold(17, color: MyColors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(Person person) {
    if (person.image == null) {
      return Container(
        color: MyColors.grey.withAlpha(30),
        child: const Icon(Icons.person_rounded, size: 100),
      );
    }
    return Image.memory(person.image!, fit: BoxFit.cover);
  }

  Future<void> choosePerson() async {
    if (!(widget.order.editable)) {
      return;
    }
    final selectedPerson = await UiHelper.pushPage<Person?>(
      context: context,
        opaque: false,
        barrierDismissible: true,
        page: Center(
          child: Material(
            color: Colors.transparent,
            child: Hero(
              tag: "person_card",
              child: Container(
                width: 400,
                height: 600,
                decoration: UiHelper.myDecoration(),
                child: ChoosePerson(
                  filter: widget.sell ? 1 : 2,
                  person: widget.person,
                ),
              ),
            ),
          ),
        ),
    );

    if (!mounted || selectedPerson == null) {
      return;
    }

    widget.onPersonSelected(selectedPerson);

  }
}
