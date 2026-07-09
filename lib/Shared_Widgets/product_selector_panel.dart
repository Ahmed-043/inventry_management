import "dart:async";

import "package:flutter/material.dart";
import 'package:flutter/cupertino.dart';
import "package:intl/intl.dart";
import "package:inventry_management/Shared_Widgets/main_ui_helper.dart";
import "package:inventry_management/Shared_Widgets/pagination_bar.dart";
import 'package:flutter/services.dart';

import "../Database/database.dart";
import "../Database/order_items.dart";
import "../Database/product_stock.dart";
import "../Database/retrieve_products.dart";
import "../Home_Page/Products_Panel/update_product/update_product_stock.dart";
import "../colors.dart";
import "fonts.dart";

class ProductSelectorPanel extends StatefulWidget {
  final List<Product> products;
  final List<int> productIndexes;
  final List<OrderItem> orderItems;
  final Map<int,int> idMap;
  late final String select;
  final bool singleItem;
  final String? search;
  final List<int>? allowedIds;
  ProductSelectorPanel({
    super.key,
    List<Product>? products,
    List<OrderItem>? orderItems,
    List<int>? productIndexes,
    Map<int,int>? idMap,
    this.singleItem = false,
    this.select = 'P',
    this.search = '',
    this.allowedIds,
  }): products = products ?? [],
        orderItems = orderItems ?? [],
        productIndexes = productIndexes ?? [],
        idMap = idMap ?? {};


  @override
  State<ProductSelectorPanel> createState() => _ProductSelectorPanelState();
}

class _ProductSelectorPanelState extends State<ProductSelectorPanel> {
  bool isRegistered = true, inStock = true;
  List<Product> products = [];
  Map<int,int> stock = {};
  int page = 0;
  bool isLoading = false;
  final int pSize = productsPerPage ?? 20;
  Timer? _searchTimer;
  final FocusNode _searchFocus = FocusNode();
  late TextEditingController searchController = TextEditingController(text: widget.search);
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocus.requestFocus();
    });
    if(!(widget.select == 'P' || widget.select == 'O' || widget.select == 'I' || widget.select == 's' || widget.select == 'S')){
      widget.select = 'P';
    }else if(widget.select =='s' || widget.select == 'S'){
      inStock = false;
    }
    _loadProducts();
  }

  @override
  dispose() {
    searchController.dispose();
    _searchFocus.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    isLoading = true;
    if (currentDB == null) {
      debugPrint("NULL DATABASE");
      return;
    }
    try {

      List<Product> list;
      if(widget.select == 's'){
         stock = await getRequiredStockOnlyProducts(widget.idMap, currentDB!);
        List<int> ids = stock.keys.toList();
        list = await getProductsByIds(ids,currentDB!,withoutImage: performanceMode);
      }else if(widget.select == 'S'){
        stock = await getComponentStock(widget.idMap, currentDB!);
        List<int> ids = stock.keys.toList();
        list = await getProductsByIds(ids,currentDB!,withoutImage: performanceMode);
      }
      else {
        list = await getProductsPage(
          currentDB!,
          page,
          pSize,
          performanceMode,
          search: searchController.text.trim().toString(),
          IDS: widget.allowedIds,
        );
      }
      setState(() => products = list);
      isLoading = false;
    } catch (e, st) {
      debugPrint("Error loading products: $e\n$st");
      products = [];
      isLoading = false;
    }
    isLoading = false;
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: (KeyEvent event) {
        if (_searchFocus.hasFocus || widget.select == 's') return; // ✅ Skip if TextField is focused

        if (event is KeyDownEvent && event.character != null) {
          searchController.text += event.character!;
          _searchTimer?.cancel();
          _searchTimer = Timer(
            const Duration(milliseconds: 500),
            _loadProducts,
          );
        } else if (event.logicalKey == LogicalKeyboardKey.backspace &&
            event is KeyDownEvent) {
          if (searchController.text.isNotEmpty) {
            searchController.text = searchController.text.substring(
              0,
              searchController.text.length - 1,
            );
            _searchTimer?.cancel();
            _searchTimer = Timer(
              const Duration(milliseconds: 500),
              _loadProducts,
            );
          }
        }
      },

      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10),
           margin: EdgeInsets.only(bottom: 5),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      (widget.select == 's') ? 'Missing Stock Products': widget.select == 'S' ?'Missing Components':  'Select Products',
                      style: MyFont.semiBold(25),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                if(!(widget.select == 's'|| widget.select == 'S')) SizedBox(
                  // color: Colors.green,
                  width: 600,
                  child: CupertinoSlidingSegmentedControl<bool>(
                    backgroundColor: MyColors.grey.withAlpha(12),
                    thumbColor: isRegistered ? MyColors.info : MyColors.error,
                    groupValue: isRegistered, // the currently selected segment
                    children: {
                      true: Text(
                        'Registered',
                        style: MyFont.normal(
                          15,
                          color: isRegistered
                              ? MyColors.translucent
                              : MyColors.black,
                        ),
                      ),
                      false: Text(
                        'Anonymous',
                        style: MyFont.normal(
                          15,
                          color: isRegistered
                              ? MyColors.black
                              : MyColors.translucent,
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
              ],
            ),
          ),
          isRegistered
              ? Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      children: [
                       if(!(widget.select == 's'|| widget.select == 'S')) SizedBox(
                          height: 50,
                          child: TextField(
                            focusNode: _searchFocus,
                            autofocus: true,
                            controller: searchController,
                            onChanged: (e) {
                              _searchTimer?.cancel();
                              _searchTimer = Timer(
                                const Duration(milliseconds: 500),
                                () {
                                  _loadProducts();
                                },
                              );
                            },
                            style: MyFont.semiBold(
                              20,
                              color: MyColors.darkBlue,
                            ),
                            decoration: InputDecoration(
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                color: MyColors.darkBlue,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide(
                                  width: 2,
                                  color: Colors.grey,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide(
                                  width: 2,
                                  color: MyColors.darkBlue,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide(
                                  width: 2,
                                  color: MyColors.darkBlue,
                                ),
                              ),
                              labelStyle: MyFont.semiBold(
                                20,
                                color: MyColors.darkBlue.withAlpha(230),
                              ),
                              hint: Text(
                                "Search (Name, SKU, Description)",
                                style: MyFont.normal(20, color: MyColors.grey),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          height: 25,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Product Details", style: MyFont.normal(15)),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    'In Stock only',
                                    style: MyFont.normal(12),
                                  ),
                                  Checkbox(
                                    overlayColor: WidgetStateProperty.all(
                                      Colors.transparent,
                                    ), // no hover effect
                                    value: inStock, // bool variable (true/false)
                                    onChanged: (bool? value) {
                                      // callback when user taps
                                      setState(() {
                                        inStock = value!;
                                        _loadProducts();
                                      });
                                    },
                                    activeColor: Colors
                                        .blue, // (optional) color when checked
                                    checkColor:
                                        Colors.white, // (optional) tick color
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Stack(
                            children: [
                              Align(
                                alignment: Alignment.topCenter,
                                child: isLoading
                                    ? CircularProgressIndicator()
                                    : products.isEmpty
                                    ? emptyState()
                                    : GridView.builder(
                                        padding: EdgeInsets.zero,
                                        physics: const BouncingScrollPhysics(),
                                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                                          maxCrossAxisExtent: 400,
                                          mainAxisSpacing: 10,
                                          crossAxisSpacing: 10,
                                          childAspectRatio: 380 / 80,
                                        ),
                                        itemCount: products.where((p) => !inStock || p.stock >= 1).length,
                                        itemBuilder: (context, index) {
                                          final visible = products.where((p) => !inStock || p.stock >= 1).toList();
                                          final p = visible[index];
                                          return InkWell(
                                            onTap: () {
                                              toggleSelection(p);
                                              debugPrint(
                                                "Selected Products: ${widget.products.map((e) => e.id).toList()}",
                                              );
                                              debugPrint(
                                                "Selected Orders: ${widget.orderItems.map((e) => e.productId).toList()}",
                                              );
                                              debugPrint(
                                                "Selected Id: ${widget.productIndexes.map((e) => e).toList()}",
                                              );
                                            },
                                            child: productCard(p),
                                          );
                                        },
                                      ),
                              ),
                              if (!(page==0 && products.length < pSize))
                              PaginationBar(
                                page: page,
                                pageSize: pSize,
                                itemCount: products.length,
                                onPrevious: () {
                                  setState(() {
                                    page--;
                                    _loadProducts();
                                  });
                                },
                                onNext: () {
                                  setState(() {
                                    page++;
                                    _loadProducts();
                                  });
                                },
                              ),
                              if( !(widget.select == 's' ||widget.select == 'S' ))
                              Align(
                                alignment: Alignment.bottomRight,
                                child: SizedBox(
                                  width: 170,
                                  height: 50,
                                  child: UiHelper.myButton(
                                    callback: () {
                                      Navigator.pop(context, widget.products);
                                    },
                                    filled: true,
                                    borderRadius: 25,
                                    title:
                                        "Add Products",
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Placeholder(),
          Container(height: 10),
        ],
      ),
    );
  }

  Widget productCard(Product product) {
    bool highlight = false;
    if(widget.select == 'P') {
       if (widget.products.any((p) => p.id == product.id)) {
         highlight = true;
       }
    }
    else if(widget.select == 'O') {
      if (widget.orderItems.any((p) => p.productId == product.id)) {
        highlight = true;
      }
    }
   else if(widget.select == 'I') {
      if (widget.productIndexes.any((p) => p == product.id)) {
        highlight = true;
      }
    }

    return Container(
      height: 80,
      width: 380,
      decoration: BoxDecoration(
        color: MyColors.translucent,
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

          if(highlight)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(color: MyColors.success.withAlpha(100)),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: product.imageData != null
                      ? Image.memory(product.imageData!, fit: BoxFit.cover)
                      : Container(
                          color: MyColors.grey.withAlpha(30),
                          child: Icon(Icons.browser_not_supported_rounded),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: Tooltip(
                  waitDuration: Duration(milliseconds: 500),
                  message:
                      "Name: ${product.name}\nSKU: ${product.sku ?? " No SKU"}\nStock: ${product.stock}",
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: Text(
                          product.name,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.start,
                          style: MyFont.semiBold(20, color: MyColors.darkBlue),
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: Text(
                          'SKU: ${product.sku ?? " No SKU"} ',
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.start,
                          style: MyFont.semiBold(12, color: MyColors.darkBlue),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                //color: Colors.grey,
                width: 100,
                child: Padding(
                  padding: EdgeInsets.all(5),
                  child: Column(
                    children: [
                      Expanded(child: SizedBox()),
                      Expanded(
                        flex: 2,
                        child: UiHelper.myButton(
                          callback: () {
                            stockUpdateDialog(product);
                          },
                          title: product.stock < 1
                              ? "Out of Stock"
                              : product.stock < lowStockLimit
                              ? "Low Stock"
                              : "In Stock",
                          filled: true,
                          color: product.stock < 1
                              ? MyColors.error
                              : product.stock < lowStockLimit
                              ? MyColors.primary
                              : MyColors.success,
                          textSize: 14,
                          borderRadius: 5,
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Center(
                          child: Tooltip(
                            waitDuration: Duration(milliseconds: 500),
                            message:
                                "Price: ${NumberFormat.decimalPattern().format(product.totalPrice)}",
                            child: Text(
                              (widget.select == 's' || widget.select == 'S')
                                  ?"Req ${stock[product.id]}"
                                  :"Rs.${product.totalPrice > 9999999 ? "\n" : ''}${NumberFormat.decimalPattern().format(product.totalPrice.floor())}",
                              style: MyFont.semiBold(
                                16,
                                color: MyColors.darkBlue,
                              ).copyWith(height: 1.0),
                              overflow: TextOverflow.ellipsis,
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
        ],
      ),
    );
  }

  stockUpdateDialog(Product product) {
    bool skipComponents =  false;//(widget.select == 'S') ? true : false;
    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          constraints: BoxConstraints(
            maxWidth: 500,
            maxHeight: 500,
            minWidth: 400,
            minHeight: 400,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: UpdateProductStock(
            id: product.id,
            skipComponents: skipComponents,
            onSave: () {
              setState(() {
                _loadProducts();
              });
            },
          ),
        );
      },
    );
  }

  void toggleSelection(Product product) {
    if(widget.select == "s"){
      return;
    }
    final existsP = widget.products.any((p) => p.id == product.id);
    if (existsP) {
      widget.products.removeWhere((p) => p.id == product.id);
    } else {
      widget.products.add(product);
    }

    final existsI = widget.productIndexes.any((p) => p == product.id);
    if (existsI) {
      widget.productIndexes.removeWhere((p) => p == product.id);
    } else {
      widget.productIndexes.add(product.id);
    }
    final existsO = widget.orderItems.any((p) => p.productId == product.id);
    if (existsO) {
      widget.orderItems.removeWhere((p) => p.productId == product.id);
    } else {
      widget.orderItems.add(OrderItem(
        productId: product.id,
        name: product.name,
        sku: product.sku,
        price: product.totalPrice,
        weight: product.totalWeight,
        quantity: 1,
        image: product.imageData,
        discount: 0,
        tax: 0,
      ));
    }
    if (widget.singleItem) Navigator.pop(context);
    setState(() {});
  }

  Widget emptyState() {
    if(widget.select == 's'|| widget.select == 'S'){
      Navigator.pop(context);
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_rounded, size: 100, color: MyColors.grey),
          SizedBox(height: 10),
          Text(
            "No Products Found",
            style: MyFont.semiBold(20, color: MyColors.grey),
          ),
        ],
      ),
    );
  }
}
