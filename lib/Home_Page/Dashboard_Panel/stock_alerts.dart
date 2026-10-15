import 'package:flutter/material.dart';
import 'package:inventry_management/Database/retrieve_products.dart';
import 'package:inventry_management/Shared_Widgets/horizontal_scroll.dart';
import 'package:inventry_management/Shared_Widgets/responsive.dart';
import 'package:inventry_management/Shared_Widgets/scaled_container.dart';

import '../../Shared_Widgets/fonts.dart';
import '../../Shared_Widgets/main_ui_helper.dart';
import '../../colors.dart';
import '../Products_Panel/update_product/update_product_stock.dart';

class StockAlerts extends StatelessWidget {
  final List<Product> lowStockProducts;
  final VoidCallback onSave;
  StockAlerts({super.key, required this.lowStockProducts, required this.onSave});
  final ScrollController controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    stockUpdateDialog(Product product) {
      UiHelper.pushPage(
        context: context,
        opaque: false,
        barrierColor: Colors.black54,
        barrierDismissible: true,
        page: UpdateProductStock(
          id: product.id,
          onSave: onSave,
        ),
      );
    }

    final isPhone = context.isPhone;

    return HorizontalScroll(
      speed: 1.5,
      physics: const BouncingScrollPhysics(),
      enableOuterScroll: false,
      controller: controller,
      child: SizedBox(
        height: isPhone ? 42 : 60,
        child: ListView.builder(
          controller: controller,
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.zero,
          itemCount: lowStockProducts.length,
          itemBuilder: (context, i) {
            final p = lowStockProducts[i];
            return InkWell(
              hoverColor: Colors.transparent,
              splashColor: Colors.transparent,
              focusColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onTap: () => stockUpdateDialog(p),
              child: box(context, p),
            );
          },
        ),
      ),
    );
  }

  Widget box(BuildContext context, Product product) {
    final isPhone = context.isPhone;
    return ScaledContainer(
      child: Hero(
        tag: 'product_${product.id}',
        child: Container(
          width: isPhone ? 210 : 363,
          height: isPhone ? 38 : 74,
          padding: EdgeInsets.symmetric(horizontal: isPhone ? 8 : 16, vertical: isPhone ? 2 : 5),
          margin: EdgeInsets.symmetric(horizontal: isPhone ? 4 : 16, vertical: isPhone ? 1 : 8),
          decoration: BoxDecoration(
            color: MyColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: MyColors.error,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              (product.imageData != null)
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Image.memory(product.imageData!, fit: BoxFit.cover),
                      ),
                    )
                  : Icon(
                      Icons.warning_amber_rounded,
                      color: MyColors.error,
                      size: isPhone ? 18 : 24,
                    ),
              SizedBox(width: isPhone ? 6 : 10),
              Expanded(
                child: Text(
                  '${product.name.split(' ').first}: ${product.stock == 0 ? "Out of Stock" : "${product.stock} left"}',
                  style: MyFont.semiBold(isPhone ? 11 : 14, color: MyColors.error),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
