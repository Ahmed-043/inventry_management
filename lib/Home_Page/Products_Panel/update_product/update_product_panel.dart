import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventry_management/Database/database.dart';
import 'package:inventry_management/Home_Page/Products_Panel/update_product/update_product_ctrl.dart';
import 'package:inventry_management/Shared_Widgets/app_cursor_overlay.dart';
import 'package:inventry_management/Shared_Widgets/scaled_container.dart';
import 'package:inventry_management/colors.dart';
import 'package:inventry_management/Shared_Widgets/main_ui_helper.dart';

import '../../../Database/retrieve_products.dart';
import '../../../Shared_Widgets/fonts.dart';
import '../../../Shared_Widgets/blinker.dart';
import '../../../Shared_Widgets/adder_remover_value.dart';
import '../../../Shared_Widgets/product_selector_panel.dart';
import '../../../Shared_Widgets/upload_box.dart';
import '../delete_confirmation.dart';

class UpdateProductDialog extends StatefulWidget {
  final Product product;
  final VoidCallback callBack;
  const UpdateProductDialog({super.key,required this.product, required this.callBack});

  @override
  State<UpdateProductDialog> createState() => UpdateProductDialogState();
}

class UpdateProductDialogState extends State<UpdateProductDialog> {
  bool showContent = true;
  final FocusNode _focusNode = FocusNode();
  late UpdateProductController controller;

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 0), () {showContent = true;});
    controller = UpdateProductController(
      widget.product,
    );
    // listen to controller async updates (categories/components)
    controller.addListener(_onControllerChanged);

  }

  @override
  void dispose() {
    controller.categoryController.removeListener(() {});
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool larger = controller.compProducts.length > 2;
    final constraints = const BoxConstraints(
      maxWidth: 850,
      maxHeight: 780,
      minWidth: 400,
    );
    final height = larger ? 780.0 : 700.0;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Body Hero (Background)
            Hero(
              tag: 'product_${widget.product.id}',
              child: Container(
                constraints: constraints,
                height: height,
                decoration: BoxDecoration(
                  color: MyColors.translucent,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            // Dialog Content (Siblings to Body Hero)
            Container(
              constraints: constraints,
              height: height,
              child: showContent
                  ? KeyboardListener(
                focusNode: _focusNode,
                autofocus: true,
                onKeyEvent: (event) {
                  if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
                    _handleUpdate();
                  }
                },
                child: Column(
                  children: [
                    _buildHeader(),
                    SizedBox(height: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(24, 0, 24, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildMainSection(),
                              SizedBox(height: 10),
                              Center(
                                child: Wrap(
                                  crossAxisAlignment: .start,
                                  alignment: .center,
                                  spacing: 20,
                                  runSpacing: 20,
                                  children: [
                                    SizedBox(width: 280, child: _buildCategorySection()),
                                    SizedBox(
                                      width: 500,
                                      height: larger ? 300 : 200,
                                      child: _buildComponentsSection(),
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
              ) : SizedBox(
                width: 850,height: 680,
                child: Padding(
                  padding: const EdgeInsets.all(100.0),
                  child: UiHelper.appLogo(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Text('Update Product', style: MyFont.bold(24, color: MyColors.dark)),
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
        crossAxisAlignment: .start,
        alignment: .center,
        spacing: 20,
        runSpacing: 20,
        children: [
          // Image Upload Section
          SizedBox(
            width: 280,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Product Image', style: MyFont.bold(16, color: MyColors.dark)),
                SizedBox(height: 8),
                Container(
                  height: 280,
                  clipBehavior: Clip.none,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                   // border: Border.all(color: MyColors.lightGrey),
                  ),
                  child: UploadBox(
                    image: controller.image,
                    heroTag: "product_${widget.product.id}_image",
                    onFileSelected: (file) => setState(() => controller.updateImage(file)),
                  ),
                ),
              ],
            ),
          ),

          // Form Fields Section
          SizedBox(
            width:500,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Product Details', style: MyFont.bold(16, color: MyColors.dark)),
                SizedBox(height: 8),

                Hero(
                  tag: "product_${widget.product.id}_name",
                  child: Material(
                    color: Colors.transparent,
                    child: UiHelper.myTextField(
                      label: 'Product Name',
                      controller: controller.name,
                      hint: 'Enter product name',
                      fontSize: 15,
                    ),
                  ),
                ),
                SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: Hero(
                        tag: "product_${widget.product.id}_price",
                        child: Material(
                          color: Colors.transparent,
                          child: UiHelper.myTextField(
                            label: 'Price',
                            controller: controller.price,
                            hint: '0.00',
                            prefixText: 'Rs. ',
                            fontSize: 15,
                            textType: TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                            ],
                            onChange: () => setState(() {}),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Hero(
                        tag: "product_${widget.product.id}_stock",
                        child: Material(
                          color: Colors.transparent,
                          child: UiHelper.myTextField(
                            label: 'Stock',
                            controller: controller.stock,
                            hint: '0',
                            fontSize: 15,
                            textType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          ),
                        ),
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
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                        ],
                        onChange: () => setState(() {}),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Hero(
                        tag: "product_${widget.product.id}_sku",
                        child: Material(
                          color: Colors.transparent,
                          child: UiHelper.myTextField(
                            label: 'SKU',
                            controller: TextEditingController(text: widget.product.sku),
                            hint: 'SKU',
                            fontSize: 15,
                            readOnly: true,
                          ),
                        ),
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

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Hero(
          tag: "product_${widget.product.id}_category",
          child: Material(
            color: Colors.transparent,
            child: Container(
              height: 50,
              padding: const EdgeInsets.only(left: 16,top: 6,bottom: 6,right: 3),
              decoration: UiHelper.myDecoration(),
              child: Row(
                children: [
                  Text('Category', style: MyFont.bold(16, color: MyColors.dark)),
                  SizedBox(width: 12),

                  Expanded(
                    child: MouseRegion(
                      onEnter: (e) => isClickable = true,
                      onExit: (e) => isClickable = false,

                      child: DropdownMenuTheme(
                        data: DropdownMenuThemeData(
                          menuStyle: MenuStyle(
                            padding: WidgetStateProperty.all(EdgeInsets.zero),

                            backgroundColor: WidgetStateProperty.all(Colors.white), // white menu background
                            shape: WidgetStateProperty.all(
                              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ), // rounded corners
                            elevation: WidgetStateProperty.all(6), // optional shadow
                          ),
                        ),
                        child: DropdownMenu<int>(
                          controller: controller.categoryController,
                          hintText: 'Select or type category',
                          expandedInsets: EdgeInsets.zero,
                          showTrailingIcon: false,
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
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(width: 2, color: MyColors.darkBlue),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                          ),
                          textStyle: MyFont.semiBold(14, color: MyColors.dark),
                          textAlign: TextAlign.center,
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
                  ),
                  // This is the part that adds the "Add Category" icon
                  if (controller.showAddCategoryIcon)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Material(
                        color: MyColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () async {
                            final categoryName = controller.categoryController.text.trim();
                            if (categoryName.isNotEmpty) {
                              final result = await controller.addNewCategory(categoryName);
                              if (result != null && mounted) {
                                UiHelper.showToast(context, result,type: 1);
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
            ),
          ),
        ),
        SizedBox(height: 10),
        MouseRegion(
          onEnter: (e) => isClickable = true,
          onExit: (e) => isClickable = false,
          child: Container(
            height: 50,
            decoration: UiHelper.myDecoration(),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),

              child: Material(
                color: Colors.transparent,

                child: InkWell(
                  onTap: () => _handleActiveToggle(!controller.isActive),
                   hoverColor: Colors.transparent,
                   splashColor: MyColors.primary.withAlpha(50),
                   highlightColor: Colors.transparent,
                  focusColor: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Text('Active', style: MyFont.bold(16, color: MyColors.dark)),
                        Spacer(),
                        Transform.scale(
                          scale: 0.85,
                          child: Switch(
                            value: controller.isActive,
                            activeTrackColor: MyColors.primary,
                            activeColor: MyColors.translucent,
                            onChanged: _handleActiveToggle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.only(left: 16,top: 6,bottom: 6,right: 16),
          decoration: UiHelper.myDecoration(),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: .spaceBetween,
                children: [
                  Text('Low Stock Limit', style: MyFont.bold(16, color: MyColors.dark)),
                  Transform.scale(
                    scale: 0.85,
                    child: Switch(
                      value: (int.parse(controller.lowStock.text) > -1),
                      activeTrackColor: MyColors.primary,
                      activeColor: MyColors.translucent,
                      onChanged: (e){
                        print(e);
                        if(e){
                          setState(() => controller.lowStock.text = '$lowStockLimit');
                        }else{
                          setState(() => controller.lowStock.text = '-1');
                        }
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6),
              if((int.parse(controller.lowStock.text) > -1))
              SizedBox(
                width: double.infinity,
                height: 40,
                child: UiHelper.myTextField(
                  label: 'Low Stock',
                  controller: controller.lowStock,
                  hint: '-1',
                  fontSize: 15,
                  textType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^-?\d*')),
                  ],
                ),
              ),

            ],
          ),
        ),
      ],
    );
  }


  Widget _buildComponentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Components', style: MyFont.bold(16, color: MyColors.dark)),
            _buildAddComponentButton(),
          ],
        ),
        SizedBox(height: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: MyColors.lightGrey, width: 2),
              borderRadius: BorderRadius.circular(12),
              color: MyColors.lightGrey.withAlpha(20),
            ),
            child: controller.compProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('No Components', style: MyFont.semiBold(15, color: MyColors.grey)),
                        SizedBox(height: 4),
                        Text('This product has no sub-components', style: MyFont.normal(13, color: MyColors.grey.withAlpha(180))),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      // List
                      Expanded(
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          itemCount: controller.compProducts.length,
                          separatorBuilder: (_, __) => Divider(height: 1, color: MyColors.lightGrey),
                          itemBuilder: (_, i) => _buildComponentTile(controller.compProducts[i], i),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddComponentButton() {
    return ScaledContainer(
      child: InkWell(
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        splashColor: Colors.transparent,
        onTap: () async {
          final List<Product>? result = await showDialog<List<Product>>(
            context: context,
            builder: (context) => Dialog(
              insetPadding: EdgeInsets.all(10),
              backgroundColor: MyColors.mainBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                width: 1200,
                height: 800,
                padding: EdgeInsets.all(16),
                child: ProductSelectorPanel(
                  products: controller.compProducts,
                  allowedIds: controller.availableProducts.map((p) => p.id).toList(),
                  select: 'P',
                ),
              ),
            ),
          );

          if (result != null) {
            setState(() {
              controller.updateComponentsFromList(result);
            });
          }else{
            setState(() {});
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: MyColors.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: MyColors.primary.withAlpha(50)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, size: 18, color: MyColors.primary),
              SizedBox(width: 4),
              Text('Add Components', style: MyFont.semiBold(13, color: MyColors.primary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComponentTile(Product product, int index) {
    
    final quantity = controller.compQuantities[product.id] ?? 0;

    return Container(
      key: ValueKey('comp_${product.id}'),
      color: Colors.transparent,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Number
          SizedBox(
            width: 30,
            child: Text('${index + 1}', style: MyFont.bold(13, color: MyColors.blue)),
          ),

          // Image
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: MyColors.lightGrey.withAlpha(50),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: product.imageData == null
                  ? Icon(Icons.shopping_bag_outlined, color: MyColors.grey, size: 20)
                  : Image.memory(product.imageData!, fit: BoxFit.cover),
            ),
          ),

          SizedBox(width: 12),

          // Name
          Expanded(
            flex: 2,
            child: Text(
              product.name,
              style: MyFont.semiBold(14),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Quantity Control
          SizedBox(
            child: Center(
              child: _buildQuantityBadge(product, index, quantity),
            ),
          ),

          SizedBox(width: 12),

          // Price
          Expanded(

            child: SizedBox(
              width: 100,
              child: Text(
                'Rs. ${NumberFormat('#,##0.00').format(product.totalPrice * quantity)}',
                style: MyFont.semiBold(14, color: MyColors.darkBlue),
                textAlign: TextAlign.end,
              ),
            ),
          ),

          SizedBox(width: 12),

          // Delete Button
          SizedBox(
            width: 28,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(Icons.delete_outline, color: MyColors.error, size: 20),
              onPressed: () => controller.deleteComponent(product.id),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildQuantityBadge(Product product, int index, int quantity) {
    return StatefulBuilder(
      builder: (context, qtState) {
        Offset mousePos = Offset.zero;

        return MouseRegion(
          onHover: (e) => mousePos = e.position,
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () async {
              qtState(() => controller.setBlinkState(product.id, true));
              await _showQuantityDialog(product, quantity, mousePos);
              qtState(() => controller.setBlinkState(product.id, false));
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: MyColors.lightGrey.withAlpha(50),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: MyColors.lightGrey,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Qty: $quantity',
                    style: MyFont.semiBold(13, color: MyColors.darkBlue),
                  ),
                  if (controller.blinkMap[product.id] ?? false) ...[
                    SizedBox(width: 2),
                    BlinkingCursor(),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showQuantityDialog(Product product, int currentQty, Offset tapPosition) async {
    final screenSize = MediaQuery.of(context).size;
    const dialogWidth = 400.0;
    const dialogHeight = 200.0;

    double left = tapPosition.dx - (dialogWidth / 2);
    double top = tapPosition.dy + 20;

    if (top + dialogHeight > screenSize.height) {
      top = tapPosition.dy - dialogHeight - 20;
    }

    left = left.clamp(10.0, screenSize.width - dialogWidth - 10.0);

    await showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (_) => Stack(
        children: [
          Positioned(
            left: left,
            top: top,
            child: SizedBox(
              width: dialogWidth,
              height: dialogHeight,
              child: AdderRemoverValue(
                value: currentQty,
                minValue: 1,
                callBack: (newValue) {
                  controller.updateComponentQuantity(product.id, newValue);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final total = controller.calculateTotals();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 24,vertical: 14),
      decoration: BoxDecoration(
        color: MyColors.translucent.withAlpha(30),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        border: Border(top: BorderSide(color: MyColors.lightGrey, width: 2)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runAlignment: .center,
        crossAxisAlignment: .center,
        spacing: 10,
        runSpacing: 10,
        children: [
          // Totals
          SizedBox(
            width: 200,
            child: Column(
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
          ),

          // Buttons
          SizedBox(
            width: 450,
            child: Row(
              mainAxisAlignment: .end,
              children: [
                SizedBox(
                  width: 120,
                  height: 50,
                  child: UiHelper.myButton(
                    title: 'Delete',
                    filled: true,
                    color: MyColors.error,
                    textSize: 15,
                    callback: () => _handleDelete(),
                  ),
                ),

                SizedBox(width: 12),

                SizedBox(
                  width: 120,
                  height: 50,
                  child: UiHelper.myButton(
                    title: 'Close',
                    callback: () => Navigator.pop(context),
                    textSize: 15,
                  ),
                ),

                SizedBox(width: 12),

                SizedBox(
                  width: 140,
                  height: 50,
                  child: UiHelper.myButton(
                    title: controller.isLoading ? null : 'Save',
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
                    callback: controller.isLoading ? () {} : _handleUpdate,
                  ),
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }

  Future<void> _handleActiveToggle(bool value) async {
    if (!value) {
      final canDisable = await controller.canDelete();
      if (!mounted) return;
      if (!canDisable) {
        final parents = await controller.getParentProducts();
        UiHelper.showToast(
          context,
          "Cannot deactivate product\nComponent of: $parents",
          type: 2,
        );
        return;
      }
    }
    setState(() => controller.isActive = value);
  }

  Future<void> _handleUpdate() async {
    final error = await controller.updateProductData();

    if (!mounted) return;

    if (error != null) {
      UiHelper.showToast(context, error,type: 3);
    } else {
      UiHelper.showToast(context, "Product Updated",type: 1);
      Navigator.pop(context);
      await Future.delayed(const Duration(milliseconds: 500));
      widget.callBack();

    }
  }

  Future<void> _handleDelete() async {
    final canDelete = await controller.canDelete();

    if (!mounted) return;

    if (canDelete) {
      showDeleteDialog(
        context: context,
        onDeleted: () async {
          await controller.deleteProductData();
          widget.callBack();
          Navigator.pop(context);
        },
      );
    } else {
      final parents = await controller.getParentProducts();
      UiHelper.showToast(
        context,
        "Product cannot be deleted\nComponent of: $parents",
        type: 2,
      );
    }
  }
}