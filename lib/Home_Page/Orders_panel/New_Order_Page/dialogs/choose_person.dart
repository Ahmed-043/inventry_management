import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inventry_management/Shared_Widgets/fonts.dart';
import 'package:inventry_management/Shared_Widgets/main_ui_helper.dart';
import 'package:inventry_management/Shared_Widgets/sliding_segment_control.dart';
import '../../../../Database/database.dart';
import '../../../../Database/orders.dart';
import '../../../../Database/person.dart';
import '../../../../colors.dart';
import 'package:flutter/cupertino.dart';

class ChoosePerson extends StatefulWidget {
  final int filter;
  final Person? person;
  const ChoosePerson({super.key, this.filter = 0, this.person});

  @override
  State<ChoosePerson> createState() => _ChoosePersonState();
}

class _ChoosePersonState extends State<ChoosePerson> {
  TextEditingController searchController = TextEditingController();
  bool isLoading = false;
  List<Person> persons = [];
  int selected = 0;
  bool isRegistered = true;
  late int filter = widget.filter;
  final List<String> filters = const ["All", "Customers", "Suppliers"];

  @override
  void initState() {
    _loadPersons();
    if (widget.person != null) {
      selected = widget.person!.id ?? 0;
    }
    super.initState();
  }

  _loadPersons() async {
    try {
      isLoading = true;
      if (currentDB == null) {
        debugPrint("NULL DATABASE");
        return;
      }
      final list = await getAllPersons(
        currentDB!,
        search: searchController.text,
        filter: filter,
      ); // 0 all, i customer, 2 suppliers
      isLoading = true;
      setState(() {
        isLoading = false;
        persons = list;
      });
    } catch (e) {
      isLoading = true;
      persons = [];
      debugPrint("Person Load Error: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        if (isRegistered) _buildRegisteredSection() else _buildAnonymousSection(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SizedBox(
      height: 80,
      child: Stack(
        children: [
          const Positioned(
            left: 10,
            top: 5,
            child: Text("Select Person", style: TextStyle(fontSize: 25, fontWeight: FontWeight.w600)),
          ),
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.close_rounded),
            ),
          ),
          Positioned(
            bottom: 5,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: CupertinoSlidingSegmentedControl<bool>(
                backgroundColor: MyColors.grey.withAlpha(12),
                thumbColor: isRegistered ? MyColors.info : MyColors.error,
                groupValue: isRegistered,
                children: {
                  true: Text(
                    'Registered',
                    style: MyFont.normal(
                      15,
                      color: isRegistered ? MyColors.translucent : MyColors.black,
                    ),
                  ),
                  false: Text(
                    'Anonymous',
                    style: MyFont.normal(
                      15,
                      color: isRegistered ? MyColors.black : MyColors.translucent,
                    ),
                  ),
                },
                onValueChanged: (bool? value) {
                  if (value != null) {
                    setState(() => isRegistered = value);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisteredSection() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: [
            SizedBox(
              height: 50,
              child: UiHelper.myTextField(
                hint: "Search....",
                borderRadius: 20,
                controller: searchController,
                onChange: () {
                  _loadPersons();
                },
              ),
            ),
            _buildFilterRow(),
            Expanded(child: _buildPersonList()),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Person Details", style: MyFont.normal(15)),
          SizedBox(
            width: 225,
            child: StatusSegmentedControl(
              key: const ValueKey('person_filter_segment'),
              selected: filters[filter],
              fontSize: 12,
              options: const [
                TwoValue(first: "All", second: MyColors.info),
                TwoValue(first: "Customers", second: MyColors.success),
                TwoValue(first: "Suppliers", second: MyColors.primary),
              ],
              onChanged: (e) {
                if (e == "All") {
                  filter = 0;
                } else if (e == "Customers") {
                  filter = 1;
                } else {
                  filter = 2;
                }
                _loadPersons();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonList() {
    return ListView.builder(
      scrollDirection: Axis.vertical,
      physics: const BouncingScrollPhysics(),
      itemCount: persons.length,
      itemBuilder: (context, index) {
        return InkWell(
          onTap: () {
            Navigator.pop(context, persons[index]);
          },
          child: personCard(persons[index]),
        );
      },
    );
  }

  Widget _buildAnonymousSection() {
    return anonymousPerson();
  }

  Widget personCard(Person person) {
    return Container(
      height: 70,
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      decoration: BoxDecoration(
        color:  MyColors.translucent,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: MyColors.grey.withAlpha(50),
            blurRadius: 3,
            offset: Offset(0, 2),
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: Stack(
        children: [
          if(person.id == selected)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(

                  color: MyColors.success.withAlpha(100)),
            ),
          Padding(
            padding: const EdgeInsets.all(5),
            child: SizedBox(
              height: 60,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: ClipOval(
                      child: person.image != null
                          ? Image.memory(person.image!, fit: BoxFit.cover)
                          : Icon(Icons.person_rounded),
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
                          child: Text(
                            person.phone ?? "",
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.start,
                            style: MyFont.semiBold(10, color: MyColors.darkBlue),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    //color: Colors.grey,
                    width: 80,
                    child: Center(
                      child: Text(
                        person.personType,
                        style: MyFont.semiBold(
                          17,
                          color: person.personType == 'customer'
                              ? MyColors.success
                              : MyColors.primary,
                        ),
                      ),
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

  Widget anonymousPerson() {
    TextEditingController nameCtrl = TextEditingController();
    TextEditingController phoneCtrl = TextEditingController();
    TextEditingController addressCtrl = TextEditingController();

    return Container(
      height: 300,
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 20),
      decoration: BoxDecoration(
        color: MyColors.translucent,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: MyColors.grey.withAlpha(50), blurRadius: 8),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          UiHelper.myTextField(
            label: "Name",
            hint: 'Alex',
            controller: nameCtrl,
          ),
          UiHelper.myTextField(
            label: "Phone",
            hint: '+92 000 000 0000',
            controller: phoneCtrl,
            textType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\+?\d*')),
              LengthLimitingTextInputFormatter(15),
            ],
          ),
          UiHelper.myTextArea(
            label: "Address",
            hint: 'Town,City,Country',
            controller: addressCtrl,
            maxLines: 3,
          ),
          UiHelper.myButton(
            title: 'Use Anonymous',
            filled: true,
            color: MyColors.info,
            callback: () {
              final person = Person(
                id: 0,
                name: nameCtrl.text,
                phone: phoneCtrl.text,
                address: addressCtrl.text,
                email: null,
                payment: 0.0,
                image: null,
                type: "local",
                personType: "customer",
              );
              Navigator.pop(context, person);
            },
          ),
        ],
      ),
    );
  }
}
