import 'package:flutter/material.dart';
import 'package:inventry_management/Database/update_product.dart';
import 'package:inventry_management/Home_Page/Products_Panel/delete_confirmation.dart';
import 'package:inventry_management/Shared_Widgets/main_ui_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../../Database/category.dart';
import '../../Database/database.dart';
import '../../colors.dart';
import '../../Shared_Widgets/fonts.dart';

class SortMenu extends StatefulWidget {
  final int currentSortCategory;
  final int currentSort;
  final onChange;
  final onSizeChange;
  final void Function(
    int newCategory,
    int newSort,
    List<DBCategory> updatedCategories,
  )
  onApply;
  final List<DBCategory> categories;
  final double cSize;
  const SortMenu({
    super.key,
    required this.currentSortCategory,
    required this.currentSort,
    required this.onApply,
    required this.categories,
    required this.onChange,
    required this.onSizeChange,
    this.cSize = 150,
  });

  @override
  State<SortMenu> createState() => _SortMenuState();
}

class _SortMenuState extends State<SortMenu> {
  late int tempSortCategory;
  late int tempSortType;
  late double cSize = widget.cSize;
  late List<DBCategory> tempCategories;
  bool productTile = tileUi;

  @override
  void initState() {
    super.initState();
    tempSortCategory = widget.currentSortCategory;
    tempSortType = widget.currentSort;
    tempCategories = List.from(widget.categories);
    tempCategories.sort((a, b) => (a.sequence ?? 0).compareTo(b.sequence ?? 0));
    cSize = widget.cSize;
  }

  // --- HARDCODED GETTERS ---

  String getSortName(int value) {
    if (value == 1 || value == 2) return 'Price';
    if (value == 3 || value == 4) return 'Stock';
    if (value == 5 || value == 6) return 'Weight';
    if (value == 7 || value == 8) return 'Name';
    if (value == 9 || value == 10) return 'ID';
    return 'ID';
  }

  String getDirection(int value) {
    if (value == 1 || value == 3 || value == 5 || value == 7 || value == 9)
      return 'Asc';
    if (value == 2 || value == 4 || value == 6 || value == 8 || value == 10)
      return 'Desc';
    return 'Asc';
  }

  // --- HARDCODED SETTER ---

  int mapNameToSortType(String name, String direction) {
    if (name == 'Price') {
      return (direction == 'Asc') ? 1 : 2;
    } else if (name == 'Stock') {
      return (direction == 'Asc') ? 3 : 4;
    } else if (name == 'Weight') {
      return (direction == 'Asc') ? 5 : 6;
    } else if (name == 'Name') {
      return (direction == 'Asc') ? 7 : 8;
    } else if (name == 'ID') {
      return (direction == 'Asc') ? 9 : 10;
    }
    return 9; // Default fallback
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 420,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: UiHelper.myDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Preferences', style: MyFont.bold(22, color: MyColors.dark)),
            const SizedBox(height: 14),

            // Category Sequence Section
            _buildSectionCard(
              title: 'Category Sequence',
              subtitle: 'Enable and reorder categories.',
              child: Column(
                children: [
                  // const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Customize sequence',
                        style: MyFont.semiBold(14, color: MyColors.dark),
                      ),
                      _buildToggleSwitch(
                        value: tempSortCategory == 1,
                        onChanged: (v) {
                          setState(() => tempSortCategory = v ? 1 : 0);
                          widget.onApply(
                            tempSortCategory,
                            tempSortType,
                            tempCategories,
                          );
                        },
                      ),
                    ],
                  ),
                  if (tempSortCategory == 1) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 160,
                      child: ReorderableListView.builder(
                        proxyDecorator:
                            (
                              Widget child,
                              int index,
                              Animation<double> animation,
                            ) {
                              return Material(
                                elevation:
                                    6, // optional, makes it float above others
                                color: Colors
                                    .white, // ✅ white background while dragging
                                borderRadius: BorderRadius.circular(
                                  12,
                                ), // ✅ rounded corners while dragging
                                child: child,
                              );
                            },
                        shrinkWrap: true,
                        itemCount: tempCategories.length,
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (newIndex > oldIndex) newIndex -= 1;
                            final item = tempCategories.removeAt(oldIndex);
                            tempCategories.insert(newIndex, item);
                            for (int i = 0; i < tempCategories.length; i++) {
                              tempCategories[i] = DBCategory(
                                id: tempCategories[i].id,
                                name: tempCategories[i].name,
                                sequence: i + 1,
                              );
                            }
                          });
                          widget.onApply(
                            tempSortCategory,
                            tempSortType,
                            tempCategories,
                          );
                        },
                        itemBuilder: (context, index) {
                          final cat = tempCategories[index];
                          return ListTile(
                            contentPadding: EdgeInsets.only(left: 8,right: 24),
                            key: ValueKey(cat.id),
                            title: Text(
                              cat.name,
                              style: MyFont.normal(14, color: MyColors.dark),
                            ),
                            leading: CircleAvatar(
                              backgroundColor: MyColors.primary.withOpacity(
                                0.1,
                              ),
                              child: Text(
                                '${index + 1}',
                                style: MyFont.semiBold(
                                  12,
                                  color: MyColors.primary,
                                ),
                              ),
                            ),
                            trailing: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.red,
                                ),
                                onPressed: () async {
                                  final deletedCat = tempCategories[index];

                                  final db =
                                      currentDB; // your Database instance
                                  if (db == null) return;

                                  // 1️⃣ Check if any product is using this category
                                  final result = await db.rawQuery(
                                    'SELECT COUNT(*) as count FROM products WHERE category = ?',
                                    [deletedCat.id],
                                  );

                                  final count =
                                      Sqflite.firstIntValue(result) ?? 0;

                                  if (count > 0) {
                                    // Category is in use
                                    UiHelper.showToast(
                                      context,
                                      'Cannot delete "${deletedCat.name}" — it is assigned to a product.',
                                    );
                                    return;
                                  }
                                  showDeleteDialog(
                                    context: context,
                                    onDeleted: () async {
                                      // 2️⃣ Safe to delete from DB
                                      await db.delete(
                                        'categories',
                                        where: 'id = ?',
                                        whereArgs: [deletedCat.id],
                                      );

                                      // 3️⃣ Remove from temp list and re-sequence
                                      setState(() {
                                        tempCategories.removeAt(index);
                                        for (
                                          int i = 0;
                                          i < tempCategories.length;
                                          i++
                                        ) {
                                          tempCategories[i] = DBCategory(
                                            id: tempCategories[i].id,
                                            name: tempCategories[i].name,
                                            sequence: i + 1,
                                          );
                                        }
                                      });
                                      widget.onApply(
                                        tempSortCategory,
                                        tempSortType,
                                        tempCategories,
                                      );
                                      UiHelper.showToast(
                                        context,
                                        'Category "${deletedCat.name}" deleted.',
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Product Sort Section
            _buildSectionCard(
              title: 'Sort Products',
              subtitle: 'How products appear in categories.',
              child: Column(
                children: [
                  // const SizedBox(height: 12),
                  _buildDropdown(
                    label: 'Sort by',
                    value: getSortName(tempSortType),
                    items: const [
                      {'value': 'ID', 'label': 'Default (ID)'},
                      {'value': 'Name', 'label': 'Name'},
                      {'value': 'Price', 'label': 'Price'},
                      {'value': 'Stock', 'label': 'Stock'},
                      {'value': 'Weight', 'label': 'Weight'},
                    ],
                    onChanged: (v) => setState(() {
                      tempSortType = mapNameToSortType(
                        v!,
                        getDirection(tempSortType),
                      );
                      widget.onApply(
                        tempSortCategory,
                        tempSortType,
                        tempCategories,
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  _buildDropdown(
                    label: 'Order',
                    value: getDirection(tempSortType),
                    items: const [
                      {'value': 'Asc', 'label': 'Ascending'},
                      {'value': 'Desc', 'label': 'Descending'},
                    ],
                    onChanged: (v) => setState(() {
                      tempSortType = mapNameToSortType(
                        getSortName(tempSortType),
                        v!,
                      );
                      widget.onApply(
                        tempSortCategory,
                        tempSortType,
                        tempCategories,
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  flex: 7,
                  child: _buildSectionCard(
                    title: 'Shape',
                    subtitle: 'Select Shape of Products',
                    child: SizedBox(
                      height: 40,
                      child: Row(
                        children: [
                          Expanded(
                            child: UiHelper.myButton(
                              callback: () async {
                                productTile = false;
                                setState(() {});
                                final prefs =
                                    await SharedPreferences.getInstance();
                                await prefs.setBool('tileUi', productTile);
                                tileUi = productTile;
                                widget.onChange.call();
                              },
                              filled: !productTile,
                              borderRadius: 12,
                              child: Icon(
                                Icons.horizontal_distribute_rounded,
                                color: productTile
                                    ? MyColors.primary
                                    : MyColors.translucent,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: UiHelper.myButton(
                              callback: () async {
                                productTile = true;
                                setState(() {});
                                final prefs =
                                    await SharedPreferences.getInstance();
                                await prefs.setBool('tileUi', productTile);
                                tileUi = productTile;
                                widget.onChange.call();
                              },
                              filled: productTile,
                              borderRadius: 12,
                              child: Icon(
                                Icons.vertical_distribute_rounded,
                                color: !productTile
                                    ? MyColors.primary
                                    : MyColors.translucent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 6,
                  child: _buildSectionCard(
                    title: 'Size',
                    subtitle: 'Change Size of Products',
                    child: SizedBox(
                      height: 40,
                      child: Row(
                        children: [
                          const Expanded(child: const SizedBox()),
                          Expanded(
                            flex: 2,
                            child: UiHelper.myButton(
                              callback: () async {
                                setState(() {
                                  cSize += 50;
                                  if (cSize > 400) cSize = 150;
                                });
                                widget.onSizeChange.call();
                              },
                              filled: true,
                              color: cSize > 350
                                  ? MyColors.blue
                                  : MyColors.primary,
                              borderRadius: 12,
                              child: Icon(
                                cSize > 350
                                    ? Icons.remove_rounded
                                    : Icons.add_rounded,
                                color: MyColors.translucent,
                              ),
                            ),
                          ),
                          const Expanded(child: const SizedBox()),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            /// Light / Dark buttons
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: MyFont.bold(16, color: MyColors.dark)),
          Text(subtitle, style: MyFont.normal(12, color: MyColors.grey)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildToggleSwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: 52,
        height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: value ? MyColors.primary : Colors.grey.shade300,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.all(3),
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<Map<String, String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: MyFont.semiBold(13, color: MyColors.dark)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(

            child: DropdownButton<String>(
              dropdownColor: Colors.white, // ✅ menu background color
              borderRadius: BorderRadius.circular(12), // ✅ rounded corners for menu
              isExpanded: true,
              value: value,
              items: items
                  .map(
                    (i) => DropdownMenuItem(
                      value: i['value'],
                      child: Text(i['label']!),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
