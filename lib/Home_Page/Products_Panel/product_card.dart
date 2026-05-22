import 'package:flutter/material.dart';
import 'package:inventry_management/Database/retrieve_products.dart';
import 'package:inventry_management/Shared_Widgets/main_ui_helper.dart';
import 'package:inventry_management/Shared_Widgets/scaled_container.dart';
import 'package:inventry_management/colors.dart';
import 'package:intl/intl.dart';

import '../../Database/database.dart';
import '../../Shared_Widgets/fonts.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onSecondaryTap;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onDoubleTap,
    this.onSecondaryTap,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  final formatter = NumberFormat('#,##0');
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return ScaledContainer(
      child: InkWell(
        onTap: widget.onTap,
        onDoubleTap: widget.onDoubleTap,
        onSecondaryTap: widget.onSecondaryTap,

        borderRadius: BorderRadius.circular(tileUi ? 12 : 16),
        child: Container(
          decoration: UiHelper.myDecoration(isHovered: _isHovered).copyWith(
            borderRadius: tileUi ? BorderRadius.circular(12) : null,
          ),
          child: tileUi ? productTileCard() : productGridCard(),
        ),
      ),
    );
  }
  Widget productGridCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: widget.product.imageData != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.memory(
                widget.product.imageData!,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            )
                : Icon(Icons.image_not_supported, size: 50),
          ),
          Expanded(
            flex: 1,
            child: LayoutBuilder(
              builder: (context, constraints) {
                double fontSize = constraints.maxHeight;
                return Column(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Text(
                        widget.product.name.length > 20
                            ? '${widget.product.name.substring(0, 20)}…'
                            : widget.product.name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: fontSize * 0.25,
                          color: MyColors.darkBlue,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: Text(
                              'Rs. ${widget.product.totalPrice > 100000000 ? widget.product.totalPrice.toStringAsExponential(0) : formatter.format(widget.product.totalPrice)}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: fontSize * 0.2,
                                color: MyColors.blue,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${widget.product.totalWeight > 1000000 ? widget.product.totalWeight.toStringAsExponential(2) : widget.product.totalWeight.toStringAsFixed(2)} Kg',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: fontSize * 0.18,
                                color: MyColors.dark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Tooltip(
                            message: 'Sold: ${NumberFormat.decimalPattern().format(widget.product.sold)}',
                            waitDuration: const Duration(milliseconds: 500),
                            child: Text(
                              'Sold: ${widget.product.sold > 1000000 ? widget.product.sold.toStringAsExponential(2) : NumberFormat.decimalPattern().format(widget.product.sold)}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: fontSize * 0.2,
                                color: MyColors.primary,
                              ),
                            ),
                          ),
                          Tooltip(
                            message: 'Stock: ${NumberFormat.decimalPattern().format(widget.product.stock)}',
                            waitDuration: const Duration(milliseconds: 500),
                            child: Text(
                              'Stock: ${widget.product.stock > 10000000 ? widget.product.stock.toStringAsExponential(2) : NumberFormat.decimalPattern().format(widget.product.stock)}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: fontSize * 0.2,
                                color: MyColors.success,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 5),
        ],
      ),
    );
  }

  Widget productTileCard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;

        return Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Align(
                    alignment: .topLeft,
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: widget.product.imageData != null
                            ? Image.memory(widget.product.imageData!, fit: BoxFit.cover)
                            : Container(
                                color: MyColors.grey.withAlpha(30),
                                child: const Icon(Icons.browser_not_supported_rounded),
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: Tooltip(
                    waitDuration: const Duration(milliseconds: 500),
                    message: "Name: ${widget.product.name}\nSKU: ${widget.product.sku ?? "No SKU"}\nSold: ${widget.product.sold}",
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            widget.product.name,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.start,
                            style: MyFont.semiBold(
                              h * 0.2,
                              color: MyColors.darkBlue,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            'Stock: ${widget.product.stock} ',
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.start,
                            style: MyFont.semiBold(
                              h * 0.15,
                              color: MyColors.darkBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Column(
                      children: [
                        const Expanded(child: SizedBox()),
                        Expanded(
                          flex: 2,
                          child: Container(
                            width: double.infinity,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(h * 0.1),
                              color: widget.product.stock < 1
                                  ? MyColors.error
                                  : widget.product.stock < lowStockLimit
                                      ? MyColors.primary
                                      : MyColors.success,
                            ),
                            child: Text(
                              widget.product.stock < 1
                                  ? "Out of Stock"
                                  : widget.product.stock < lowStockLimit
                                      ? "Low Stock"
                                      : "In Stock",
                              style: MyFont.semiBold(
                                h * 0.14,
                                color: MyColors.translucent,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Center(
                            child: Tooltip(
                              waitDuration: const Duration(milliseconds: 500),
                              message: "Price: ${NumberFormat.decimalPattern().format(widget.product.totalPrice)}",
                              child: Text(
                                "Rs.${widget.product.totalPrice > 9999999 ? "\n" : ''}${NumberFormat.decimalPattern().format(widget.product.totalPrice.floor())}",
                                style: MyFont.semiBold(
                                  h * 0.18,
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
        );
      },
    );
  }
}
