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

  Widget _statusPill(String text, Color bgColor, Color textColor,double factor) {
    return Hero(
      tag: "product_${widget.product.id}_low_stock",
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding:  EdgeInsets.symmetric(horizontal: (12 * factor), vertical: (4* factor) ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            text,
            style: MyFont.bold(12 * factor, color: textColor),
          ),
        ),
      ),
    );
  }

  Widget _stockPill(double factor) {
    Color bgColor;
    Color textColor;
    String text;

    final effectiveLowStock = widget.product.lowStock == -1 ? lowStockLimit : widget.product.lowStock;

    if (widget.product.lowStock == widget.product.stock) {
      text = "In Stock";
      bgColor = const Color(0xFFE6FAF5);
      textColor = const Color(0xFF01B574);
    } else if (widget.product.stock < 1) {
      text = "Out Of Stock";
      bgColor = const Color(0xFFFEEFEF);
      textColor = const Color(0xFFEE5D50);
    } else if (widget.product.stock < effectiveLowStock) {
      text = "Low Stock";
      bgColor = const Color(0xFFFFF8ED);
      textColor = const Color(0xFFFFB547);
    } else {
      text = "In Stock";
      bgColor = const Color(0xFFE6FAF5);
      textColor = const Color(0xFF01B574);
    }

    return _statusPill(text, bgColor, textColor,factor);
  }

  @override
  Widget build(BuildContext context) {
    return ScaledContainer(
      child: InkWell(
        onTap: widget.onTap,
        onDoubleTap: widget.onDoubleTap,
        onSecondaryTap: widget.onSecondaryTap,
        onHover: (value) => setState(() => _isHovered = value),
        borderRadius: BorderRadius.circular(tileUi ? 12 : 20),
        child: Stack(
          children: [
            // Body Hero (Background)
            Positioned.fill(
              child: Hero(
                tag: "product_${widget.product.id}",
                child: Container(
                  decoration: UiHelper.myDecoration(isHovered: _isHovered).copyWith(
                    borderRadius: BorderRadius.circular(tileUi ? 12 : 20),
                  ),
                ),
              ),
            ),
            // Content (including Image Hero)
            tileUi ? productTileCard() : productGridCard(),
          ],
        ),
      ),
    );
  }

  Widget productGridCard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        final w = constraints.maxWidth;
        final factor = (h / 300).clamp(0.4, 1.5);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Expanded(
              flex: 6,
              child: Container(
                margin: EdgeInsets.all(12 * factor),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFE9EDF7),
                  borderRadius: BorderRadius.circular(16 * factor),
                ),
                child: Stack(
                  children: [
                    Hero(
                      tag: "product_${widget.product.id}_image",

                      child: Center(
                        child: widget.product.imageData != null
                            ? ClipRRect(
                              borderRadius: BorderRadius.circular(16 * factor),
                              child: Image.memory(
                                widget.product.imageData!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            )
                            : Icon(Icons.inventory_2_outlined,
                                size: 48 * factor,
                                color: MyColors.textSecondary.withOpacity(0.5)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Info Section
            Padding(
              padding: EdgeInsets.fromLTRB(16 * factor, 0, 16 * factor, 16 * factor),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      if (widget.product.categoryName != null && sortCategory == 0)
                        ...[
                          Hero(
                            tag: "product_${widget.product.id}_category",
                            child: _statusPill(
                                widget.product.categoryName!,
                                const Color(0xFFF4F7FE),
                                MyColors.sidebarSelected,
                                factor
                            ),
                          ),
                        const SizedBox(width: 8),
                        ],

                      _stockPill(factor),
                    ],
                  ),
                  SizedBox(height: 12 * factor),
                  Hero(
                    tag: "product_${widget.product.id}_name",
                    child: Material(
                      color: Colors.transparent,
                      child: Text(
                        widget.product.name,
                        style: MyFont.bold(16 * factor, color: MyColors.textMain),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  Hero(
                    tag: "product_${widget.product.id}_sku",
                    child: Material(
                      color: Colors.transparent,
                      child: Text(
                        widget.product.sku ?? "No SKU",
                        style: MyFont.medium(12 * factor, color: MyColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  SizedBox(height: 16 * factor),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Hero(
                        tag: "product_${widget.product.id}_price",
                        child: Material(
                          color: Colors.transparent,
                          child: Text(
                            'Rs. ${formatter.format(widget.product.totalPrice)}',
                            style: MyFont.bold(14 * factor, color: MyColors.textMain),
                          ),
                        ),
                      ),
                      Hero(
                        tag: "product_${widget.product.id}_stock",
                        child: Material(
                          color: Colors.transparent,
                          child: Text(
                            'Stk: ${widget.product.stock}',
                            style: MyFont.bold(14 * factor, color: MyColors.textSecondary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget productTileCard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        final factor = (h / 300).clamp(0.8, 2.0);

        return Row(
          children: [
            // Image
            Padding(
              padding: EdgeInsets.all(8.0 * factor),
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: MyColors.mainBg,
                    borderRadius: BorderRadius.circular(12 * factor),
                  ),
                  child: Hero(
                    tag: "product_${widget.product.id}_image",
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12 * factor),
                      child: widget.product.imageData != null
                          ? Image.memory(widget.product.imageData!,
                              fit: BoxFit.cover)
                          : Icon(Icons.inventory_2_outlined,
                              size: h * 0.4, color: MyColors.textSecondary.withOpacity(0.5)),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 8 * factor),
            // Details
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(child: _stockPill(factor)),
                    ],
                  ),
                  SizedBox(height: 4 * factor),
                  Hero(
                    tag: "product_${widget.product.id}_name",
                    child: Material(
                      color: Colors.transparent,
                      child: Text(
                        widget.product.name,
                        style: MyFont.bold(h * 0.18, color: MyColors.textMain),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),

                  if(widget.product.sku != null)
                  Hero(
                    tag: "product_${widget.product.id}_sku",
                    child: Material(
                      color: Colors.transparent,
                      child: Text(
                        widget.product.sku!,
                        style: MyFont.medium(h * 0.16, color: MyColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Price & Stock
            Padding(
              padding: EdgeInsets.only(right: 16.0 * factor),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Hero(
                    tag: "product_${widget.product.id}_price",
                    child: Material(
                      color: Colors.transparent,
                      child: Text(
                        'Rs. ${formatter.format(widget.product.totalPrice)}',
                        style: MyFont.bold(h * 0.22, color: MyColors.textMain),
                      ),
                    ),
                  ),
                  Hero(
                    tag: "product_${widget.product.id}_stock",
                    child: Material(
                      color: Colors.transparent,
                      child: Text(
                        'Stk: ${widget.product.stock}',
                        style: MyFont.bold(h * 0.18, color: MyColors.textSecondary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
