import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventry_management/colors.dart';
import 'package:inventry_management/Shared_Widgets/main_ui_helper.dart';

import '../../Database/retrieve_products.dart';
import '../../Shared_Widgets/adder_remover_value.dart';
import '../../Shared_Widgets/blinker.dart';
import '../../Shared_Widgets/fonts.dart';
import '../../Shared_Widgets/product_selector_panel.dart';
import '../../Shared_Widgets/upload_box.dart';

import 'new_product_logic.dart';

class InputNewProduct extends StatefulWidget {
  final VoidCallback? onSave;
  const InputNewProduct({super.key, this.onSave});

  @override
  State<InputNewProduct> createState() => _InputNewProductState();
}

class _InputNewProductState extends State<InputNewProduct>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final FocusNode _focusNode = FocusNode();
  late InputNewProductController controller;

  @override
  @override
  void initState() {
    super.initState();
    controller = InputNewProductController();
    controller.loadCategories();

    controller.categoryController.addListener(() {
      if (mounted) setState(() {});
    });
  }


  @override
  void dispose() {
    controller.categoryController.removeListener(() {});
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.enter) {
          _handleSave();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            _buildHeader(),
            SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMainSection(),
                      SizedBox(height: 24),
                      Center(
                        child: Wrap(
                          crossAxisAlignment: .start,
                          alignment: .start,
                          spacing: 20,
                          runSpacing: 20,
                          children: [
                            SizedBox(width: 280, child: _buildCategoryDropdown()),
                            SizedBox(
                              width: 500,
                              child: Column(
                                crossAxisAlignment: .start,
                                children: [
                                  if (controller.compProducts.isNotEmpty) ...[
                                    Text('Components', style: MyFont.bold(16, color: MyColors.dark)),
                                    SizedBox(height: 12),
                                    _buildComponentsList(),
                                    SizedBox(height: 16),
                                  ]
                                  else _buildAddComponentsButton(),
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
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Text('Add New Product', style: MyFont.bold(24, color: MyColors.dark)),
          Spacer(),
          IconButton(
            icon: Icon(Icons.close, color: Colors.grey.shade600),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMainSection() {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 20,
        runSpacing: 20,
        children: [
          // Image Upload Section
          SizedBox(
            width: 280,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Product Image',
                  style: MyFont.bold(16, color: MyColors.dark),
                ),
                SizedBox(height: 8),
                SizedBox(
                  height: 280,
                  // decoration: BoxDecoration(
                  //   borderRadius: BorderRadius.circular(12),
                  //   border: Border.all(color: MyColors.lightGrey),
                  // ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: UploadBox(
                      image: controller.image,
                      onFileSelected: (file) =>
                          setState(() => controller.updateImage(file)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Form Fields Section
          SizedBox(
            width: 500,
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(
                  'Product Details',
                  style: MyFont.bold(16, color: MyColors.dark),
                ),
                SizedBox(height: 8),

                UiHelper.myTextField(
                  label: 'Product Name',
                  controller: controller.name,
                  hint: 'Enter product name',
                  fontSize: 15,
                ),
                SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: UiHelper.myTextField(
                        label: 'Price',
                        controller: controller.price,
                        hint: '0.00',
                        prefixText: 'Rs. ',
                        fontSize: 15,
                        textType: TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*'),
                          ),
                        ],
                        onChange: () => setState(() {}),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: UiHelper.myTextField(
                        label: 'Stock',
                        controller: controller.stock,
                        hint: '0',
                        fontSize: 15,
                        textType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: UiHelper.myTextField(
                        label: 'Weight',
                        controller: controller.weight,
                        hint: '0.00',
                        prefixText: 'Kg. ',
                        fontSize: 15,
                        textType: TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*'),
                          ),
                        ],
                        onChange: () => setState(() {}),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: UiHelper.myTextField(
                        label: 'SKU',
                        controller: controller.sku,
                        hint: 'Optional',
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                UiHelper.myTextArea(
                  label: 'Description',
                  controller: controller.desc,
                  hint: 'Enter product description',
                  maxLines: 3,
                  fontSize: 15,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Category', style: MyFont.bold(16, color: MyColors.dark)),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownMenuTheme(
                data: DropdownMenuThemeData(
                  menuStyle: MenuStyle(
                    padding: MaterialStateProperty.all(EdgeInsets.zero),

                    backgroundColor: MaterialStateProperty.all(Colors.white), // white menu background
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ), // rounded corners
                    elevation: MaterialStateProperty.all(6), // optional shadow
                  ),
                ),
                child: DropdownMenu<int>(

                  controller: controller.categoryController,
                  hintText: 'Select or type category',
                  expandedInsets: EdgeInsets.zero,
                  inputDecorationTheme: InputDecorationTheme(

                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(width: 2, color: MyColors.lightGrey),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(width: 2, color: MyColors.darkBlue),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(width: 2, color: MyColors.darkBlue),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    
                  ),
                  textStyle: MyFont.semiBold(14,color: MyColors.dark),
                  
                  onSelected: (int? value) {
                    setState(() => controller.selectCategory(value));
                  },
                  dropdownMenuEntries: controller.categories.map((category) {
                    return DropdownMenuEntry<int>(
                      value: category.id,
                      label: category.name,
                    );
                  }).toList(),
                ),
              ),
            ),
            if (controller.showAddCategoryIcon)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Material(
                  color: MyColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () async {
                      final categoryName = controller.categoryController.text
                          .trim();
                      if (categoryName.isNotEmpty) {
                        final result = await controller.addNewCategory(
                          categoryName,
                        );
                        if (result != null && mounted) {
                          UiHelper.showToast(context, result);
                          setState(() {});
                        }
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.all(10),
                      child: Icon(Icons.add, color: MyColors.success, size: 20),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildComponentsList() {
    return Container(
      constraints: BoxConstraints(maxHeight: 260),
      decoration: BoxDecoration(
        border: Border.all(color: MyColors.lightGrey, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: MyColors.lightGrey, width: 2),
              ),
              color: MyColors.translucent.withAlpha(30),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showProductPicker(),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, size: 18, color: MyColors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Add Component',
                        style: MyFont.semiBold(14, color: MyColors.blue),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: controller.compProducts.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: MyColors.lightGrey),
              itemBuilder: (_, i) =>
                  _buildComponentTile(controller.compProducts[i], i),
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildComponentTile(Product product, int index) {
    final quantity = controller.compQuantities[product.id] ?? 1;

    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Image
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: MyColors.lightGrey.withAlpha(50),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: product.imageData == null
                    ? Icon(
                        Icons.shopping_bag_outlined,
                        color: MyColors.grey,
                        size: 20,
                      )
                    : Image.memory(product.imageData!, fit: BoxFit.cover),
              ),
            ),

            SizedBox(width: 12),

            // Name
            Expanded(
              child: Text(
                product.name,
                style: MyFont.semiBold(14),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            SizedBox(width: 12),

            // Quantity
            _buildQuantityBadge(product, index, quantity),

            SizedBox(width: 12),

            // Price
            Text(
              'Rs. ${NumberFormat('#,##0.00').format(product.totalPrice)}',
              style: MyFont.semiBold(14, color: MyColors.darkBlue),
            ),

            SizedBox(width: 12),

            // Delete
            IconButton(
              constraints: BoxConstraints(),
              icon: Icon(Icons.delete_outline_rounded, color: MyColors.error, size: 18),
              onPressed: () =>
                  setState(() => controller.removeComponent(index)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityBadge(Product product, int index, int quantity) {
    return StatefulBuilder(
      builder: (context, qtState) {
        bool isHovering = false;
        Offset mousePos = Offset.zero;

        return MouseRegion(
          onHover: (e) => mousePos = e.position,
          onEnter: (_) => qtState(() => isHovering = true),
          onExit: (_) => qtState(() => isHovering = false),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () async {
              qtState(() => controller.setBlinkState(index, true));
              await _showQuantityDialog(product, quantity, mousePos);
              qtState(() => controller.setBlinkState(index, false));
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isHovering
                    ? MyColors.blue.withOpacity(0.1)
                    : MyColors.lightGrey.withAlpha(50),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isHovering ? MyColors.blue : MyColors.lightGrey,
                  width: isHovering ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Qty: $quantity',
                    style: MyFont.semiBold(13, color: MyColors.darkBlue),
                  ),
                  if (controller.blinkMap[index] ?? false) ...[
                    SizedBox(width: 2),
                    BlinkingCursor(),
                  ],
                  if (isHovering) ...[
                    SizedBox(width: 4),
                    Icon(Icons.edit, size: 12, color: MyColors.blue),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showQuantityDialog(
      Product product,
      int quantity,
      Offset pos,
      ) async {
    final size = MediaQuery.of(context).size;
    const dialogH = 220.0;
    const dialogW = 400.0;

    final top = (pos.dy + dialogH > size.height)
        ? pos.dy - dialogH-20
        : pos.dy + 20;

    final left = pos.dx.clamp(0.0, size.width - dialogW*2);

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Quantity",
      barrierColor: Colors.transparent,
      pageBuilder: (_, __, ___) => Stack(
        children: [
          Positioned(
            top: top,
            left: left,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: dialogW,
                height: dialogH,
                padding: const EdgeInsets.all(10),
                child: AdderRemoverValue(
                  value: quantity,
                  callBack: (newValue) {
                    setState(() => controller
                        .updateComponentQuantity(product.id, newValue));
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddComponentsButton() {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        border: Border.all(color: MyColors.lightGrey, width: 2),
        borderRadius: BorderRadius.circular(12),
        color: MyColors.translucent.withAlpha(30),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showProductPicker(),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline, size: 32, color: MyColors.blue),
                SizedBox(height: 8),
                Text(
                  'Add Components',
                  style: MyFont.semiBold(16, color: MyColors.blue),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    final total = controller.calculateTotals();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24,vertical: 15),
      decoration: BoxDecoration(
        color: MyColors.translucent.withAlpha(30),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        border: Border(top: BorderSide(color: MyColors.lightGrey, width: 2)),
      ),
      child: Row(
        children: [
          // Totals
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Total Price: Rs. ${total['price']!.toStringAsFixed(2)}',
                style: MyFont.semiBold(15, color: MyColors.dark),
              ),
              SizedBox(height: 4),
              Text(
                'Total Weight: ${total['weight']!.toStringAsFixed(2)} Kg',
                style: MyFont.normal(13, color: MyColors.grey),
              ),
            ],
          ),

          Spacer(),

          // Buttons
          SizedBox(
            width: 140,
            height: 50,
            child: UiHelper.myButton(
              title: 'Cancel',
              callback: () => Navigator.pop(context),
              textSize: 15,
            ),
          ),

          SizedBox(width: 12),

          SizedBox(
            width: 160,
            height: 50,
            child: UiHelper.myButton(
              title: controller.isLoading ? null : 'Save Product',
              filled: true,
              textSize: 15,
              child: controller.isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : null,
              callback: controller.isLoading ? () {} : _handleSave,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showProductPicker() async {
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: 1200,
          height: 800,
          child: ProductSelectorPanel(
            products: controller.compProducts,
            singleItem: false,
          ),
        ),
      ),
    );

    setState(() => controller.syncComponentQuantities());
  }

  Future<void> _handleSave() async {
    final error = await controller.saveProduct();

    if (!mounted) return;

    if (error != null) {
      UiHelper.showToast(context, error);
    } else {
      widget.onSave?.call();
      Navigator.pop(context);
    }
  }
}
