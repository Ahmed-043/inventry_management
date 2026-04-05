import 'dart:async';

import 'package:flutter/material.dart';
import 'package:inventry_management/Home_Page/Customers&Suppliers/person_card.dart';
import 'package:inventry_management/Home_Page/Customers&Suppliers/update_person_panel.dart';
import 'package:inventry_management/Shared_Widgets/pagination_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

import '../../Database/database.dart';
import '../../Database/person.dart';
import '../../Shared_Widgets/fonts.dart';
import '../../Shared_Widgets/topbar.dart';
import '../../colors.dart';
import 'add_new_person_panel.dart';
import 'addnew_person_button.dart';

class PersonsPage extends StatefulWidget {
  final bool isCustomer;
  const PersonsPage({super.key, this.isCustomer = true});

  @override
  State<PersonsPage> createState() => _PersonsPageState();
}

class _PersonsPageState extends State<PersonsPage> {
  bool isLoading = false;
  var cSize = personCardSize ?? 150.0;
  int page = 0;
  final int pSize = personsPerPage ?? 20;
  List<Person> persons = [];
  final FocusNode _focusNode = FocusNode();
  final TextEditingController searchController =  TextEditingController();
  Map<String, int> type = {};
  Timer? _searchTimer;
  int selectType = 0;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _loadPersons();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus(); // 🔑 grab focus after build
    });
  }

  _loadPersons() async {
    try {
      setState(() {
        isLoading = true;
      });
      if (currentDB == null) {
        debugPrint("NULL DATABASE");
        return;
      }
      final list = await getPersons(
        currentDB!,
        personType: widget.isCustomer ? 'customer' : 'supplier',
        page: page,
        pageSize: pSize,
        search: searchController.text.toString(),
        scope: selectType,
      );
      type = await getPersonsCountByType(
        currentDB!,
        personType: widget.isCustomer ? 'customer' : 'supplier',
        search: searchController.text.toString(),
      );
      isLoading = false;
      setState(() => persons = list);
    } catch (e) {
      isLoading = false;
      persons = [];
      debugPrint("Person Load Error: ${e.toString()}");
    }
  }

  @override
  void didUpdateWidget(covariant PersonsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isCustomer != widget.isCustomer) {
      _loadPersons();   // reload when switching between customer/supplier
    }
    searchController.dispose();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft && page > 0) {
            setState(() {
              page--;
              _loadPersons();
            });
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowRight &&
              persons.length == pSize) {
            setState(() {
              page++;
              _loadPersons();
            });
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Column(
        children: [
          topBar(),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child:
                      persons.isEmpty
                        ? emptyState()
                        : SingleChildScrollView(
                    physics: BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.only(top: 5, bottom: 10),
                          width: double.infinity,
                          child: Center(
                            child: Wrap(
                              spacing: 15,
                              runSpacing: 20,
                              children: List.generate(persons.length, (index) {
                                return InkWell(
                                  onDoubleTap: (){
                                    updateDialog(persons[index]);
                                  },
                                  onSecondaryTap: (){
                                    updateDialog(persons[index]);
                                  },
                                  child: SizedBox(
                                    width: cSize * 2.5,
                                    height: cSize,
                                    child: PersonCard(person: persons[index],num: index),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                        const SizedBox(height: 45),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: FloatingActionButton(
                    elevation: 0,
                    onPressed: () {
                      setState(() {
                        cSize += 25;
                        if (cSize > 250) {
                          cSize = 125;
                        }
                        debugPrint(cSize.toString());
                        personCardSize = cSize;
                        SharedPreferences.getInstance().then((prefs) {
                          prefs.setDouble('personCardSize', cSize);
                        });
                      });
                    },
                    splashColor: Colors.white.withAlpha(50),
                    backgroundColor: cSize > 225 ? MyColors.blue : MyColors.primary,
                    child: Icon(
                      Icons.photo_size_select_large_rounded,
                      color: MyColors.light,
                    ),
                  ),
                ),
                PaginationBar(
                  page: page,
                  pageSize: pSize,
                  itemCount: persons.length,
                  onPrevious: () {
                    setState(() {
                      page--;
                      _loadPersons();
                    });
                  },
                  onNext: () {
                    setState(() {
                      page++;
                      _loadPersons();
                    });
                  },
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }
  updateDialog(Person person){
    showDialog(context: context, builder: (_){
      return  Dialog(
        constraints: BoxConstraints(maxWidth: 500,maxHeight: 680,minWidth: 400, minHeight: 400),
        backgroundColor: MyColors.translucent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: SizedBox(
          //  width: MediaQuery.of(context).size.width * 0.6,
          //  height: MediaQuery.of(context).size.height * 0.8,
            child: UpdatePersonPanel(person: person, callback: (){
              setState(() {
                _loadPersons();
              });
            })
        ),
      );
    });
  }

  Widget topBar() {
    return ReusableTopBar(
      title: MediaQuery.of(context).size.width < 850 ? "" : widget.isCustomer ? "Customers" : "Suppliers",
      searchHint: 'Search (Name, Phone, Address)',
      applyBlur: false,
      actionButton: Align(
        alignment: .topLeft,
        child: AddNewPerson.addNew(
            context: context,
            isCustomer: widget.isCustomer ,
            action: AddNewPersonPanel(isCustomer: widget.isCustomer ,callback: (){
              setState(() {
                _loadPersons();
              });
            },),),
      ),
      searchController: searchController,
      onSearch: () {
        _searchTimer?.cancel();
        _searchTimer = Timer(const Duration(milliseconds: 500), () {
          _loadPersons();
        });
      },
      onClear: () {
        setState(() {
          selectType = 0;
          searchController.clear();
        });
        _loadPersons();
      },
      stockButtons: [
        {'title': 'All', 'count': type['all'] ?? 0},
        {'title': 'Pending', 'count': type['pending'] ?? 0},
        {'title': 'Major', 'count': type['major'] ?? 0},
        {'title': 'Local', 'count': type['local'] ?? 0},
      ],
      selectedIndex: selectType,
      onButtonSelect: (i) {
        setState(() {
          selectType = i;
          switch (i) {
            case 1:
              selectType = 1;
              break;
            case 2:
              selectType = 2;
              break;
            case 3:
              selectType = 3;
              break;
            default: // All
              selectType = 0;
          }
        });
        _loadPersons();
      },

    );
  }
  Widget emptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 200.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.isCustomer ? Icons.people_alt_outlined : Icons.local_shipping_outlined, size: 100, color: MyColors.grey),
            SizedBox(height: 10),
            Text(
              "No ${widget.isCustomer ? 'Customers' : 'Suppliers'} Found",
              style: MyFont.semiBold(20, color: MyColors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
