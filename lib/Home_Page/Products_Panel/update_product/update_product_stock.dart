import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventry_management/Shared_Widgets/fonts.dart';
import 'package:inventry_management/Shared_Widgets/main_ui_helper.dart';
import 'package:inventry_management/Shared_Widgets/scaled_container.dart';
import 'package:inventry_management/colors.dart';
import 'package:flutter/cupertino.dart';
import '../../../Database/database.dart';
import 'package:flutter/services.dart';

import '../../../Database/product_stock.dart';
import '../../../Database/Reports_Data/inventory_movments.dart';
import '../../../Database/retrieve_products.dart';
import '../../../Shared_Widgets/product_selector_panel.dart';

class UpdateProductStock extends StatefulWidget {
  final int id;
  final VoidCallback onSave;
  final bool skipComponents;
  const UpdateProductStock({
    super.key,
    required this.id,
    required this.onSave,
    this.skipComponents = false,
  });

  @override
  State<UpdateProductStock> createState() => _UpdateProductStockState();
}

class _UpdateProductStockState extends State<UpdateProductStock> {
  bool showContent = false;
  late Product? product;

  final List<int> values = [
    1,
    5,
    10,
    25,
    50,
    100,
    250,
    500,
    1000,
    5000,
    10000,
    50000,
  ];

  late int selectedValue = 0;
  late int stock = 0;
  late TextEditingController stockController = TextEditingController();
  late FocusNode stockFocusNode = FocusNode();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _loadProduct();

    // Show the content first, then focus the text field on the next frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        stockFocusNode.requestFocus();
      });
    });
  }

  _loadProduct() async {
    product = await getProductById(currentDB!, widget.id, withoutImage: true);

    setState(() {
      stock = product!.stock;
      selectedValue = 0;
      stockController.text = stock.toString();
      showContent = true;
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    stockController.dispose();
    stockFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Hero(
        tag: 'product_${widget.id}',
        child: Material(
          color: MyColors.translucent,
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          child: SizedBox(
            height: 500,
            width: 500,
            child: showContent
                ? Column(
                    children: [
                      Container(
                        height: 50,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                          color: MyColors.primary,
                        ),
                        child: Center(
                          child: Text(
                            "Update Product Stock",
                            textAlign: TextAlign.center,
                            style: MyFont.semiBold(
                              25,
                              color: MyColors.translucent,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 5,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Column(
                            children: [
                              SizedBox(
                                height: 60,
                                width: double.infinity,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product!.name.length > 40
                                          ? '${product!.name.substring(0, 40)}…'
                                          : product!.name,
                                      style: MyFont.semiBold(
                                        20,
                                        color: MyColors.darkBlue,
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment: .spaceBetween,
                                      children: [
                                        Text(
                                          "Current Stock: ${NumberFormat.decimalPattern().format(product!.stock)} units",
                                          style: MyFont.semiBold(
                                            20,
                                            color: MyColors.darkBlue,
                                          ),
                                        ),
                                        Text(
                                          "${stock - product!.stock >= 0 ? '+' : ''}${(int.tryParse(stockController.text) ?? stock) - product!.stock}",
                                          style: MyFont.semiBold(
                                            20,
                                            color: MyColors.darkBlue,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: UiHelper.myTextField(
                                  //  label: "Stock",
                                  prefixText: "Stock. ",
                                  fontSize: 25,
                                  textType: TextInputType.number,
                                  autofocus: true,
                                  onChange: () {
                                    stock = stockController.text == ""
                                        ? 0
                                        : int.parse(stockController.text);
                                    setState((){});
                                  },
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  controller: stockController,
                                  focusNode: stockFocusNode,
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4.0,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          ScaledContainer(
                                            child: CupertinoSlidingSegmentedControl<int>(
                                              backgroundColor: MyColors.grey
                                                  .withAlpha(12),
                                              thumbColor: selectedValue == 0
                                                  ? MyColors.info
                                                  : MyColors.error,
                                              groupValue:
                                                  selectedValue, // the currently selected segment
                                              children: {
                                                0: Text(
                                                  'Add',
                                                  style: MyFont.normal(
                                                    15,
                                                    color: selectedValue == 0
                                                        ? MyColors.translucent
                                                        : MyColors.black,
                                                  ),
                                                ),
                                                1: Text(
                                                  'Remove',
                                                  style: MyFont.normal(
                                                    15,
                                                    color: selectedValue == 1
                                                        ? MyColors.translucent
                                                        : MyColors.black,
                                                  ),
                                                ),
                                              },
                                              onValueChanged: (int? value) {
                                                if (value != null) {
                                                  setState(
                                                    () => selectedValue = value,
                                                  );
                                                }
                                              },
                                            ),
                                          ),
                                          ScaledContainer(
                                            scale: 0.85,
                                            child: IconButton(
                                              onPressed: () {
                                                stock = product!.stock;
                                                stockController.text = stock
                                                    .toString();
                                                setState(() {
                                            
                                                });
                                              },
                                              icon: Icon(Icons.undo_sharp),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Expanded(
                                        child: GridView.builder(
                                          gridDelegate:
                                              SliverGridDelegateWithFixedCrossAxisCount(
                                                crossAxisCount: 4,
                                                mainAxisSpacing: 5.0,
                                                crossAxisSpacing: 5.0,
                                                childAspectRatio: 2,
                                              ),
                                          itemCount: values.length,
                                          itemBuilder: (context, index) {
                                            return InkWell(
                                              hoverColor: Colors.transparent,
                                              highlightColor:
                                                  Colors.transparent,
                                              splashColor: Colors.transparent,
                                              onTap: () {
                                                setState(() {
                                                  switch (selectedValue) {
                                                    case 0:
                                                      stock += values[index];
                                                      break;
                                                    case 1:
                                                      if (stock >=
                                                          values[index]) {
                                                        stock -= values[index];
                                                      } else {
                                                        stock = 0;
                                                      }
                                                      break;
                                                  }
                                                  stockController.text = stock
                                                      .toString();
                                                });
                                              },
                                              child: addBox(
                                                values[index],
                                                selectedValue,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 40,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: UiHelper.myButton(
                                        title: "Back",
                                        filled: false,
                                        callback: () {
                                          Navigator.pop(context);
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: UiHelper.myButton(
                                        title: "Save",
                                        filled: true,
                                        callback: () {
                                          updateStock(
                                            widget.id,
                                            int.tryParse(
                                                  stockController.text,
                                                ) ??
                                                stock,
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                    ],
                  )
                : Padding(
                    padding: const EdgeInsets.all(100.0),
                    child: UiHelper.appLogo(),
                  ),
          ),
        ),
      ),
    );
  }

  Widget addBox(int value, int op) {
    return ScaledContainer(
      child: Container(
        decoration: BoxDecoration(
          color: op == 0
              ? MyColors.info.withAlpha(20)
              : MyColors.darkRed.withAlpha(20),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: op == 0
                ? MyColors.blue.withAlpha(50)
                : MyColors.darkRed.withAlpha(50),
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            "${op == 0 ? '+' : '-'}${value.toString()}",
            style: MyFiraFont.semiBold(
              20,
              color: op == 0 ? MyColors.blue : MyColors.darkRed,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> updateStock(int id, int stock) async {
    int change = stock - product!.stock;
    Map<int, int> a = {}, b = {};
    if (change > 0) {
      a.putIfAbsent(id, () => change);
    }
    b = await getComponentStock(a, currentDB!);
    if (!widget.skipComponents && change > 0) {
      if (b.isNotEmpty) {
        await componentStockDialog(a);
        b = await getComponentStock(a, currentDB!);
        if (b.isNotEmpty) {
          return;
        } else {
          await updateAndDeductDirectComponentsOnly(a, currentDB!, productName: product?.name ?? "");
          UiHelper.showToast(context, "Stock Updated Successfully", type: 1);
        }
        close();
      } else {
        await updateAndDeductDirectComponentsOnly(a, currentDB!, productName: product?.name ?? "");
        close();
        UiHelper.showToast(context, "Stock Updated Successfully", type: 1);
      }
    } else {
      print("ELSE");
      update(id);
    }
  }

  update(int id) async {
    final db = currentDB!; // your DB getter

    // 1️⃣ Get stock before update for movement record
    final pData = await db.rawQuery('SELECT stock FROM products WHERE id = ?', [
      id,
    ]);
    final stockBefore =
        (pData.isNotEmpty ? (pData.first['stock'] as num?)?.toInt() : 0) ?? 0;
    final stockAfter = stock.toInt();

    await db.update(
      'products',
      {'stock': stock},
      where: 'id = ?',
      whereArgs: [id],
    );

    // 2️⃣ Record the manual stock adjustment movement
    final movement = InventoryMovement(
      productId: id,
      movementType: 'Stock Adjustment',
      quantityChange: stockAfter - stockBefore,
      stockBefore: stockBefore,
      stockAfter: stockAfter,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      remark: 'Manual stock update',
    );
    await insertInventoryMovement(db, movement);

    UiHelper.showToast(context, "Stock Updated Successfully", type: 1);
    close();
  }

  close() {
    Navigator.pop(context);
    widget.onSave.call();
  }

  componentStockDialog(Map<int, int> a) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.all(10),
          backgroundColor: MyColors.mainBg,
          child: SizedBox(
            width: 800,
            height: 500,
            child: ProductSelectorPanel(
              // products: products,
              idMap: a,
              select: 'S',
            ),
          ),
        );
      },
    );
  }
}
