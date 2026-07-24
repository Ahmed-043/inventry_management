import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inventry_management/Home_Page/Products_Panel/sort_menu.dart';
import 'package:inventry_management/Shared_Widgets/scaled_container.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inventry_management/Home_Page/Products_Panel/product_card.dart';
import 'package:inventry_management/Home_Page/Products_Panel/update_product/update_product_stock.dart';
import 'package:inventry_management/Home_Page/Products_Panel/update_product/update_product_panel.dart';
import 'package:inventry_management/Shared_Widgets/pagination_bar.dart';
import 'package:inventry_management/Shared_Widgets/topbar.dart';
import 'package:inventry_management/Shared_Widgets/fonts.dart';
import 'package:inventry_management/colors.dart';
import 'package:inventry_management/Home_Page/Products_Panel/add_new_product_button.dart';
import '../../Database/category.dart';
import '../../Database/database.dart';
import '../../Database/retrieve_products.dart';
import '../../Shared_Widgets/app_cursor_overlay.dart';
import '../../Shared_Widgets/main_ui_helper.dart';
import 'add_new_product_panel.dart';

class StockDashboard extends StatefulWidget {
  const StockDashboard({super.key});

  @override
  State<StockDashboard> createState() => _StockDashboardState();
}

class _StockDashboardState extends State<StockDashboard> {
  var cSize = cardSize ?? 300.0;
  List<Product> products = [];
  int page = 0;
  bool isLoading = false, active = true, _isTopBarHovered = false;
  final FocusNode _focusNode = FocusNode();
  final int pSize = productsPerPage ?? 20;
  TextEditingController searchController = TextEditingController();
  Map<String, int> stocks = {};
  int selectStock = 0, lowerLimit = 0;
  int? upperLimit;
  Timer? _searchTimer;
  ScrollController scrollController = ScrollController();
  Map<int, String> _categoryNames = {}; // id -> name
  List<DBCategory> categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategoryNames().then((_) => _loadProducts());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    searchController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCategoryNames() async {
    if (currentDB == null) return;

    final result = await currentDB!.query(
      'categories',
      orderBy: 'sequence ASC, name ASC',
    );

    setState(() {
      categories = result.map((row) => DBCategory.fromMap(row)).toList();
      _categoryNames = {
        for (var row in result) row['id'] as int: row['name'] as String,
      };
    });
  }

  _loadStockInfo() async {
    stocks = await getStockSummary(lowStockLimit, currentDB!);
  }

  Future<void> _loadProducts() async {
    isLoading = true;
    if (currentDB == null) return;

    try {
      await _loadStockInfo();

      final list = await getProductsPage(
        currentDB!,
        page,
        pSize,
        false,
        search: searchController.text.trim(),
        isLowStock: selectStock == 2 ? true : (selectStock == 3 ? false : null),
        isInStock: selectStock == 1 ? true : null,
        globalLowStockLimit: lowStockLimit,
        sortMode: sort,
        categorySortMode: sortCategory,
        active: active,
      );

      for (var p in list) {
        if (p.category != null && p.category != 0) {
          p.categoryName = _categoryNames[p.category];
        }
      }

      setState(() => products = list);
    } catch (e, st) {
      debugPrint("Error loading products: $e\n$st");
      products = [];
    } finally {
      setState(() => isLoading = false);
    }
  }

  Map<int?, List<Product>> _groupProductsByCategory(List<Product> list) {
    final Map<int?, List<Product>> grouped = {};
    for (final p in list) {
      final key = (p.category == 0) ? null : p.category;
      grouped.putIfAbsent(key, () => []).add(p);
    }
    return grouped;
  }

  List<Widget> _buildCategorySections() {
    final grouped = _groupProductsByCategory(products);
    final List<Widget> slivers = [];

    for (var entry in grouped.entries) {
      final catId = entry.key;
      final items = entry.value;

      final title = catId == null
          ? "Other"
          : _categoryNames[catId] ?? "Category $catId";

      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              title,
              style: MyFont.bold(
                cSize > 200 ? 24 : 20,
                color: MyColors.blue,
              ),
            ),
          ),
        ),
      );

      final size = (Platform.isAndroid || Platform.isIOS) ? cSize / 1.7 : cSize;
      final tileWidth = tileUi ? size * 1.6 : size * 0.85;
      final tileHeight = tileUi ? size * 0.4 : size * 1.2;
      final childAspect = tileWidth / tileHeight;

      slivers.add(
        SliverGrid(
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: tileWidth,
            mainAxisSpacing: 15,
            crossAxisSpacing: 15,
            childAspectRatio: childAspect,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final product = items[index];
              return _ProductGridItem(
                product: product,
                tileWidth: tileWidth,
                tileHeight: tileHeight,
                onTap: () => stockUpdateDialog(product),
                onSecondaryTap: () => updateDialog(product),
                showHoverEffect: true,
              );
            },
            childCount: items.length,
          ),
        ),
      );

      slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 25)));
    }
    return slivers;
  }

  Widget _buildSliverGrid() {
    final size = (Platform.isAndroid || Platform.isIOS) ? cSize / 1.7 : cSize;
    final tileWidth = tileUi ? size * 1.5 : size * 0.85;
    final tileHeight = tileUi ? size * 0.4 : size * 1.2;
    final childAspect = tileWidth / tileHeight;

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: tileWidth,
        mainAxisSpacing: cSize / 17,
        crossAxisSpacing: cSize / 17,
        childAspectRatio: childAspect,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final product = products[index];
          return _ProductGridItem(
            product: product,
            tileWidth: tileWidth,
            tileHeight: tileHeight,
            onTap: () => stockUpdateDialog(product),
            onSecondaryTap: () => updateDialog(product),
            showHoverEffect: false,
          );
        },
        childCount: products.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool compress = MediaQuery.of(context).size.width < 600;
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft && page > 0) {
            setState(() {
              page--;
              _loadProducts();
            });
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowRight &&
              products.length == pSize) {
            setState(() {
              page++;
              _loadProducts();
            });
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Stack(
        clipBehavior: Clip.none, // 🔑 Allows slivers to overflow the page Stack
        children: [
          CustomScrollView(
            controller: scrollController,
            physics: _isTopBarHovered
                ? const NeverScrollableScrollPhysics()
                : const BouncingScrollPhysics(),
            clipBehavior:
                Clip.none, // 🔑 Allows slivers to overflow the Viewport
            slivers: [
              SliverAppBar(
                floating: true,
                snap: true,
                pinned: performanceMode,
                automaticallyImplyLeading: false,
                backgroundColor: MyColors.mainBg,
                forceMaterialTransparency: true,
                toolbarHeight: 120,
                flexibleSpace: MouseRegion(
                  onEnter: (_) => setState(() => _isTopBarHovered = true),
                  onExit: (_) => setState(() => _isTopBarHovered = false),
                  child: topBar(),
                ),
              ),
              if (products.isEmpty)
                SliverFillRemaining(hasScrollBody: false, child: emptyState()),
              if (sortCategory == 1 || sortCategory == 2)
                ..._buildCategorySections()
              else
                _buildSliverGrid(),
              const SliverToBoxAdapter(child: SizedBox(height: 45)),
            ],
          ),
          Positioned(
            bottom: 10,
            right: 10,
            child: Builder(
              builder: (context) => MouseRegion(
                onEnter: (_) {
                  isClickable = true;
                },
                onExit: (_) {
                  isClickable = false;
                },
                child: FloatingActionButton(
                  heroTag: null,
                  elevation: 0,
                  backgroundColor: MyColors.primary,
                  child: Icon(Icons.sort, color: MyColors.light),
                  onPressed: () async {
                    await _loadCategoryNames();
                    if (mounted) {
                      showGeneralDialog(
                        context: context,
                        barrierColor: Colors.transparent,
                        barrierDismissible: true,
                        barrierLabel: 'SortMenu',
                        transitionDuration: const Duration(milliseconds: 300),
                        pageBuilder: (context, animation, secondaryAnimation) {
                          double dragX = 0;
                          double dragY = 0;
                          bool isDragging = false;
                          return StatefulBuilder(
                            builder: (context, setStateDialog) {
                              return Stack(
                                children: [
                                  AnimatedPositioned(
                                    duration: isDragging
                                        ? Duration.zero
                                        : const Duration(milliseconds: 200),
                                    curve: Curves.easeOut,
                                    right: 4 - dragX,
                                    bottom: 4 - dragY,
                                    child: GestureDetector(
                                      onPanStart: (_) => setStateDialog(
                                        () => isDragging = true,
                                      ),
                                      onPanUpdate: (details) {
                                        setStateDialog(() {
                                          dragX += details.delta.dx;
                                          dragY += details.delta.dy;
                                          if (dragX < 0) dragX = 0;
                                          if (dragY < 0) dragY = 0;
                                        });
                                      },
                                      onPanEnd: (details) {
                                        setStateDialog(
                                          () => isDragging = false,
                                        );
                                        if (dragX > 120 ||
                                            dragY > 120 ||
                                            details
                                                    .velocity
                                                    .pixelsPerSecond
                                                    .dx >
                                                500 ||
                                            details
                                                    .velocity
                                                    .pixelsPerSecond
                                                    .dy >
                                                500) {
                                          Navigator.of(context).pop();
                                        } else {
                                          setStateDialog(() {
                                            dragX = 0;
                                            dragY = 0;
                                          });
                                        }
                                      },
                                      child: SingleChildScrollView(
                                        physics: const BouncingScrollPhysics(),
                                        child: SortMenu(
                                          categories: categories,
                                          currentSortCategory: sortCategory,
                                          currentSort: sort,
                                          cSize: cSize,
                                          onChange: () => setState(() {}),
                                          onSizeChange: () {
                                            setState(() {
                                              cSize += 50;
                                              if (cSize > 400) cSize = 150;
                                              cardSize = cSize;
                                              SharedPreferences.getInstance()
                                                  .then(
                                                    (prefs) => prefs.setDouble(
                                                      'cardSize',
                                                      cSize,
                                                    ),
                                                  );
                                            });
                                          },
                                          onApply:
                                              (
                                                newCategory,
                                                newSort,
                                                updatedCategories,
                                              ) async {
                                                categories = updatedCategories;
                                                await updateAllSequences(
                                                  currentDB!,
                                                  categories,
                                                );

                                                setState(() {
                                                  sortCategory = newCategory;
                                                  sort = newSort;
                                                  SharedPreferences.getInstance()
                                                      .then((prefs) {
                                                        prefs.setInt(
                                                          'sortCategory',
                                                          sortCategory,
                                                        );
                                                        prefs.setInt(
                                                          'sort',
                                                          sort,
                                                        );
                                                      });
                                                  _loadProducts();
                                                });
                                              },
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        transitionBuilder:
                            (context, animation, secondaryAnimation, child) {
                              return SlideTransition(
                                position:
                                    Tween<Offset>(
                                      begin: const Offset(1, 0),
                                      end: Offset.zero,
                                    ).animate(
                                      CurvedAnimation(
                                        parent: animation,
                                        curve: Curves.easeOut,
                                      ),
                                    ),
                                child: ScaleTransition(
                                  scale: animation,
                                  child: child,
                                ),
                              );
                            },
                      );
                    }
                  },
                ),
              ),
            ),
          ),

          PaginationBar(
            page: page,
            pageSize: pSize,
            itemCount: products.length,
            scrollController: scrollController,
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
        ],
      ),
    );
  }

  Widget topBar() {
    return Container(
      color: MyColors.mainBg,
      padding: const EdgeInsets.only(top: 12,right: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Products",
                style: MyFont.bold(24, color: MyColors.textMain),
              ),
              Row(
                children: [
                  AddNewProduct.addNew(
                    context: context,
                    action: InputNewProduct(onSave: (){
                      _loadProducts();
                      _loadCategoryNames();
                    }),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(
                      Icons.notifications_none_rounded,
                      color: MyColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: MouseRegion(
                    onEnter: (_){
                      isTextCursor = true;
                    },
                    onExit: (_){
                      isTextCursor = false;
                    },
                    child: TextField(
                      controller: searchController,
                      onChanged: (_) {
                        _searchTimer?.cancel();
                        _searchTimer = Timer(
                          const Duration(milliseconds: 500),
                          () {
                            _loadProducts();
                          },
                        );
                      },
                      style: MyFont.medium(14, color: MyColors.textMain),
                      decoration: InputDecoration(
                        hintText: 'Search (Name, SKU, Description)',
                        hintStyle: MyFont.medium(
                          14,
                          color: MyColors.textSecondary,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: MyColors.textSecondary,
                          size: 20,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _statusFilterChip('All', 0),
                    _statusFilterChip('In Stock', 1),
                    _statusFilterChip('Low Stock', 2),
                    _statusFilterChip('Out of Stock', 3),
                    _statusFilterChip('Inactive', 4),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusFilterChip(String label, int index) {
    bool isSelected = selectStock == index;
    return Padding(
      padding: MediaQuery.of(context).size.width > 800
          ? const EdgeInsets.symmetric(horizontal: 4.0)
          : const EdgeInsets.symmetric(horizontal: 0.0),
      child: ScaledContainer(
        scale: 0.9,
        child: InkWell(
          hoverColor: Colors.transparent,
          splashColor: MyColors.sidebarSelected.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            setState(() {
              selectStock = index;
              switch (index) {
                case 1:
                  upperLimit = null;
                  lowerLimit = lowStockLimit;
                  active = true;
                  break;
                case 2:
                  upperLimit = lowStockLimit - 1;
                  lowerLimit = 1;
                  active = true;
                  break;
                case 3:
                  upperLimit = 0;
                  lowerLimit = 0;
                  active = true;
                  break;
                case 4:
                  upperLimit = null;
                  lowerLimit = 0;
                  active = false;
                  break;
                default:
                  upperLimit = null;
                  lowerLimit = 0;
                  active = true;
                  searchController.text = '';
              }
            });
            _loadProducts();
          },
          child: Container(

            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? MyColors.sidebarSelected : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: isSelected
                  ? null
                  : Border.all(color: MyColors.textSecondary.withOpacity(0.2)),
            ),
            child: Text(
              label,
              style: MyFont.bold(
                14,
                color: isSelected ? Colors.white : MyColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_rounded, size: 100, color: MyColors.grey),
          const SizedBox(height: 10),
          Text(
            "No Products Found",
            style: MyFont.semiBold(20, color: MyColors.grey),
          ),
        ],
      ),
    );
  }

  updateDialog(Product product) {
    UiHelper.pushPage(
      context: context,
      opaque: false,
      barrierColor: Colors.black54,
      barrierDismissible: true,

      page: UpdateProductDialog(
        product: product,
        callBack: () {
          _loadProducts();
          _loadCategoryNames();
        },
      ),
    );
  }

  stockUpdateDialog(Product product) {
    UiHelper.pushPage(
      context: context,
      opaque: false,
      barrierColor: Colors.black54,
      barrierDismissible: true,

      page: UpdateProductStock(
        id: product.id,
        onSave: () {
          _loadProducts();
          setState(() {});
        },
      ),
    );
  }
}

class _ProductGridItem extends StatefulWidget {
  final Product product;
  final double tileWidth;
  final double tileHeight;
  final VoidCallback onTap;
  final VoidCallback onSecondaryTap;
  final bool showHoverEffect;

  const _ProductGridItem({
    required this.product,
    required this.tileWidth,
    required this.tileHeight,
    required this.onTap,
    required this.onSecondaryTap,
    this.showHoverEffect = false,
  });

  @override
  State<_ProductGridItem> createState() => _ProductGridItemState();
}

class _ProductGridItemState extends State<_ProductGridItem> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    Widget card = ProductCard(product: widget.product);

    if (widget.showHoverEffect) {
      card = MouseRegion(
        onEnter: (_) => setState(() => isHovered = true),
        onExit: (_) => setState(() => isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          transform: Matrix4.identity()..scale(isHovered ? 1.03 : 1.0),
          transformAlignment: Alignment.center,
          child: card,
        ),
      );
    }

    return SizedBox(
      width: widget.tileWidth,
      height: widget.tileHeight,
      child: InkWell(
        hoverColor: Colors.transparent,
        onTap: widget.onTap,
        onSecondaryTap: widget.onSecondaryTap,
        child: Material(
          color: Colors.transparent,
          child: card,
        ),
      ),
    );
  }
}
