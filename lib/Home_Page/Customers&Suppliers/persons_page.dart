import 'dart:async';

import 'package:flutter/material.dart';
import 'package:inventry_management/Home_Page/Customers&Suppliers/person_card.dart';
import 'package:inventry_management/Home_Page/Customers&Suppliers/update_person_panel.dart';
import 'package:inventry_management/Shared_Widgets/main_ui_helper.dart';
import 'package:inventry_management/Shared_Widgets/pagination_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

import '../../Database/database.dart';
import '../../Database/person.dart';
import '../../Shared_Widgets/app_cursor_overlay.dart';
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
  final TextEditingController searchController = TextEditingController();
  Map<String, int> type = {};
  Timer? _searchTimer;
  int selectType = 0;
  ScrollController scrollController = ScrollController();

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
      _loadPersons(); // reload when switching between customer/supplier
    }
    searchController.dispose();
  }

  @override
  void dispose() {
    // clean up resources
    _searchTimer?.cancel();
    _focusNode.dispose();
    searchController.dispose();
    scrollController.dispose();
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
      child: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            controller: scrollController,
            slivers: [
              SliverAppBar(
                floating: true,
                snap: true,
                pinned: false,
                automaticallyImplyLeading: false,
                backgroundColor: Colors.transparent,
                forceMaterialTransparency: true,
                toolbarHeight: 50,
                flexibleSpace: topBar(),
              ),
              if (persons.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: emptyState(),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 5, bottom: 10, left: 5, right: 5),
                  child: Center(
                    child: Wrap(
                      spacing: cSize / 12,
                      runSpacing: cSize / 12,
                      children: List.generate(
                        persons.length,
                        (index) => Hero(
                          tag: "person_${persons[index].id}",
                          child: SizedBox(
                            width: cSize * 2.5,
                            height: cSize,
                            child: PersonCard(
                              person: persons[index],
                              num: index,
                              onDoubleTap: () => updateDialog(persons[index]),
                              onSecondaryTap: () => updateDialog(persons[index]),
                              onPaymentSaved: () => _loadPersons(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 45)),

            ],
          ),
          Positioned(
            bottom: 10,
            right: 10,
            child: MouseRegion(
              onEnter: (_)  {
                isClickable =true;
              },
              onExit: (_) {
                isClickable = false;
              },
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
    );
  }

  updateDialog(Person person) {
    UiHelper.pushPage(
        context: context,
        opaque: false,
        barrierColor: Colors.black54,
        barrierDismissible: true,

        page: UpdatePersonPanel(
      person: person,
      callback: () {
        setState(() {
          _loadPersons();
        });
      },
    )
    );

  }

  Widget topBar() {
    return ReusableTopBar(
      title: MediaQuery.of(context).size.width < 850
          ? ""
          : widget.isCustomer
          ? "Customers"
          : "Suppliers",
      searchHint: 'Search (Name, Phone, Address)',
      applyBlur: true,
      actionButton: Align(
        alignment: .topLeft,
        child: AddNewPerson.addNew(
          context: context,
          isCustomer: widget.isCustomer,
          action: AddNewPersonPanel(
            isCustomer: widget.isCustomer,
            callback: () {
              setState(() {
                _loadPersons();
              });
            },
          ),
        ),
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
            Icon(
              widget.isCustomer
                  ? Icons.people_alt_outlined
                  : Icons.local_shipping_outlined,
              size: 100,
              color: MyColors.grey,
            ),
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
