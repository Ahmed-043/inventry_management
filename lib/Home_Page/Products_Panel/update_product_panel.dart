import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventry_management/Home_Page/Products_Panel/update_product_ctrl.dart';
import 'package:inventry_management/colors.dart';
import 'package:inventry_management/Shared_Widgets/main_ui_helper.dart';

import '../../Database/retrieve_products.dart';
import '../../Shared_Widgets/fonts.dart';
import '../../Shared_Widgets/upload_box.dart';
import 'delete_confirmation.dart';

class UpdateProduct extends StatefulWidget {
  final Product product;
  final VoidCallback callBack;
  const UpdateProduct({
    super.key,
    required this.product,
    required this.callBack,
  });

  @override
  State<UpdateProduct> createState() => _UpdateProductState();
}

class _UpdateProductState extends State<UpdateProduct> {
  final FocusNode _focusNode = FocusNode();
  late UpdateProductController controller;

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
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
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
          _handleUpdate();
        }
      },
      child: Container(
        width: 1100,
        height: 700,
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
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
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
                              child: controller.compProducts.isNotEmpty
                                  ? _buildComponentsSection()
                                  : _buildNoComponentsPlaceholder(),
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
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: MyColors.lightGrey),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: UploadBox(
                      image: controller.image,
                      onFileSelected: (file) => setState(() => controller.updateImage(file)),
                    ),
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
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
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
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                        ],
                        onChange: () => setState(() {}),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: UiHelper.myTextField(
                        label: 'SKU',
                        controller: TextEditingController(text: widget.product.sku),
                        hint: 'SKU',
                        fontSize: 15,
                        readOnly: true,
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
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  textStyle: MyFont.semiBold(14, color: MyColors.dark),
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
            // This is the part that adds the "Add Category" icon
            if (controller.showAddCategoryIcon)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Material(
                  color: MyColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () async {
                      final categoryName = controller.categoryController.text.trim();
                      if (categoryName.isNotEmpty) {
                        final result = await controller.addNewCategory(categoryName);
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


  Widget _buildComponentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Components', style: MyFont.bold(16, color: MyColors.dark)),
        SizedBox(height: 12),
        Container(
          constraints: BoxConstraints(maxHeight: 260),
          decoration: BoxDecoration(
            border: Border.all(color: MyColors.lightGrey, width: 2),
            borderRadius: BorderRadius.circular(12),
            color: MyColors.lightGrey.withAlpha(20),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: MyColors.lightGrey, width: 2)),
                  color: MyColors.translucent.withAlpha(50),
                ),
                child: Row(
                  children: [
                    SizedBox(width: 30),
                    SizedBox(width: 40),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text('Name', style: MyFont.semiBold(13, color: MyColors.dark)),
                    ),
                    SizedBox(width: 60, child: Center(child: Text('Qty', style: MyFont.semiBold(13, color: MyColors.dark)))),
                    SizedBox(width: 12),
                    SizedBox(width: 100, child: Text('Price', style: MyFont.semiBold(13, color: MyColors.dark), textAlign: TextAlign.end)),
                    SizedBox(width: 12),
                  ],
                ),
              ),

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
      ],
    );
  }

  Widget _buildComponentTile(Product product, int index) {
    final quantity = controller.compQuantities[product.id] ?? 1;

    return Container(
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
            child: Text(
              product.name,
              style: MyFont.semiBold(14),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Quantity
          SizedBox(
            width: 60,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: MyColors.blue.withAlpha(30),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: MyColors.blue.withAlpha(100)),
                ),
                child: Text(
                  '$quantity',
                  style: MyFont.semiBold(13, color: MyColors.darkBlue),
                ),
              ),
            ),
          ),

          SizedBox(width: 12),

          // Price
          SizedBox(
            width: 100,
            child: Text(
              'Rs. ${NumberFormat('#,##0.00').format(product.totalPrice)}',
              style: MyFont.semiBold(14, color: MyColors.darkBlue),
              textAlign: TextAlign.end,
            ),
          ),

          SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _buildNoComponentsPlaceholder() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Components', style: MyFont.bold(16, color: MyColors.dark)),
        SizedBox(height: 12),
        Container(
          height: 100,
          decoration: BoxDecoration(
            border: Border.all(color: MyColors.lightGrey, width: 2),
            borderRadius: BorderRadius.circular(12),
            color: MyColors.lightGrey.withAlpha(10),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'No Components',
                  style: MyFont.semiBold(15, color: MyColors.grey),
                ),
                SizedBox(height: 4),
                Text(
                  'This product has no sub-components',
                  style: MyFont.normal(13, color: MyColors.grey.withAlpha(180)),
                ),
              ],
            ),
          ),
        ),
      ],
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

  Future<void> _handleUpdate() async {
    final error = await controller.updateProductData();

    if (!mounted) return;

    if (error != null) {
      UiHelper.showToast(context, error);
    } else {
      widget.callBack();
      Navigator.pop(context);
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
      );
    }
  }
}