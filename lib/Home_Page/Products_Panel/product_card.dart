import 'package:flutter/material.dart';
import 'package:inventry_management/Database/retrieve_products.dart';
import 'package:inventry_management/Shared_Widgets/main_ui_helper.dart';
import 'package:inventry_management/Shared_Widgets/responsive.dart';
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

  Widget _statusPill(String text, Color bgColor, Color textColor, double factor, {String? hero}) {
    return Hero(
      tag: hero ?? "product_${widget.product.id}_low_stock",
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: (6 * factor), vertical: (2 * factor)),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            text,
            style: MyFont.bold((10 * factor).clamp(8.5, 13.0), color: textColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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

    return _statusPill(text, bgColor, textColor, factor);
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ScaledContainer(
        child: InkWell(
          onTap: widget.onTap,
          onDoubleTap: widget.onDoubleTap,
          onSecondaryTap: widget.onSecondaryTap,
          onHover: (value) => setState(() => _isHovered = value),
          borderRadius: BorderRadius.circular(tileUi ? 12 : 16),
          child: Stack(
            children: [
              Positioned.fill(
                child: Hero(
                  tag: "product_${widget.product.id}",
                  child: Container(
                    decoration: UiHelper.myDecoration(isHovered: _isHovered).copyWith(
                      borderRadius: BorderRadius.circular(tileUi ? 12 : 16),
                    ),
                  ),
                ),
              ),
              tileUi ? productTileCard() : productGridCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget productGridCard() {
    final isPhone = context.isPhone;

    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        final factor = (h / 280).clamp(0.65, 1.2);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section (70% of card height)
            Expanded(
              flex: isPhone ? 7 : 6,
              child: Container(
                margin: EdgeInsets.all(isPhone ? 4 : 8 * factor),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFE9EDF7),
                  borderRadius: BorderRadius.circular(isPhone ? 10 : 14),
                ),
                child: Hero(
                  tag: "product_${widget.product.id}_image",
                  child: Center(
                    child: widget.product.imageData != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(isPhone ? 10 : 14),
                            child: Image.memory(
                              widget.product.imageData!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              filterQuality: FilterQuality.medium,
                            ),
                          )
                        : Icon(
                            Icons.inventory_2_outlined,
                            size: isPhone ? 42 : 48 * factor,
                            color: MyColors.textSecondary.withValues(alpha: 0.5),
                          ),
                  ),
                ),
              ),
            ),
            // Info Section (30% of card height)
            Expanded(
              flex: isPhone ? 3 : 4,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isPhone ? 6 : 10 * factor,
                  2,
                  isPhone ? 6 : 10 * factor,
                  isPhone ? 4 : 8 * factor,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Row(
                      children: [
                        if (widget.product.categoryName != null && sortCategory == 0) ...[
                          Flexible(
                            child: _statusPill(
                              widget.product.categoryName!,
                              const Color(0xFFF4F7FE),
                              MyColors.sidebarSelected,
                              isPhone ? 0.8 : factor * 0.85,
                              hero: "product_${widget.product.id}_category",
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Flexible(child: _stockPill(isPhone ? 0.8 : factor * 0.85)),
                      ],
                    ),
                    Hero(
                      tag: "product_${widget.product.id}_name",
                      child: Material(
                        color: Colors.transparent,
                        child: Text(
                          widget.product.name,
                          style: MyFont.bold(isPhone ? 12 : (13 * factor).clamp(11.0, 15.0), color: MyColors.textMain),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Hero(
                          tag: "product_${widget.product.id}_price",
                          child: Material(
                            color: Colors.transparent,
                            child: Text(
                              'Rs. ${formatter.format(widget.product.totalPrice)}',
                              style: MyFont.bold(isPhone ? 12 : (13 * factor).clamp(12.0, 16.0), color: MyColors.textMain),
                            ),
                          ),
                        ),
                        if (widget.product.sku != null && !isPhone)
                          Text(
                            widget.product.sku!,
                            style: MyFont.medium(10, color: MyColors.textSecondary),
                          ),
                      ],
                    ),
                  ],
                ),
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
        final factor = (h / 80.0).clamp(0.6, 1.2);

        return Padding(
          padding: const EdgeInsets.all(6.0),
          child: Row(
            children: [
              // Image
              AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: MyColors.mainBg,
                    borderRadius: BorderRadius.circular(10 * factor),
                  ),
                  child: Hero(
                    tag: "product_${widget.product.id}_image",
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10 * factor),
                      child: widget.product.imageData != null
                          ? Image.memory(
                              widget.product.imageData!,
                              fit: BoxFit.cover,
                              filterQuality: FilterQuality.medium,
                            )
                          : Icon(
                              Icons.inventory_2_outlined,
                              size: 24 * factor,
                              color: MyColors.textSecondary.withValues(alpha: 0.5),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Details
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.product.categoryName != null && sortCategory == 0) ...[
                          Flexible(
                            child: _statusPill(
                              widget.product.categoryName!,
                              const Color(0xFFF4F7FE),
                              MyColors.sidebarSelected,
                              factor * 0.85,
                              hero: "product_${widget.product.id}_category",
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Flexible(child: _stockPill(factor * 0.85)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Flexible(
                      child: Hero(
                        tag: "product_${widget.product.id}_name",
                        child: Material(
                          color: Colors.transparent,
                          child: Text(
                            widget.product.name,
                            style: MyFont.bold((13 * factor).clamp(11.0, 15.0), color: MyColors.textMain),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                    if (widget.product.sku != null)
                      Flexible(
                        child: Hero(
                          tag: "product_${widget.product.id}_sku",
                          child: Material(
                            color: Colors.transparent,
                            child: Text(
                              widget.product.sku!,
                              style: MyFont.medium((10 * factor).clamp(9.0, 12.0), color: MyColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Price
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Hero(
                    tag: "product_${widget.product.id}_price",
                    child: Material(
                      color: Colors.transparent,
                      child: Text(
                        'Rs. ${formatter.format(widget.product.totalPrice)}',
                        style: MyFont.bold(13, color: MyColors.textMain),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
