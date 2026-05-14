import 'package:flutter/material.dart';
import 'package:inventry_management/Database/retrieve_products.dart';
import 'package:inventry_management/Shared_Widgets/horizontal_scroll.dart';

import '../../Shared_Widgets/fonts.dart';
import '../../colors.dart';
import '../Products_Panel/update_product_stock.dart';

class StockAlerts extends StatelessWidget {
  final List<Product> lowStockProducts;
  final VoidCallback onSave;
  StockAlerts({super.key, required this.lowStockProducts,required this.onSave});
  final ScrollController controller = ScrollController();
  @override
  Widget build(BuildContext context) {
    stockUpdateDialog(Product product) {
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
              productStock: product.stock,
              name: product.name,
              onSave: onSave,
            ),
          );
        },
      );
    }

    return HorizontalScroll(
      speed: 1.5,
      enableOuterScroll: false,
      controller: controller ,
      child: SizedBox(
        height: 75, // box height (74) + vertical margins/padding
        child: ListView.builder(
          controller: controller,
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.zero,
          itemCount: lowStockProducts.length,
          itemBuilder: (context, i) {
            final p = lowStockProducts[i];
            return InkWell(
              onTap: () => stockUpdateDialog(p),
              child: box(p),
            );
          },
        ),
      ),
    );
  }


  Widget box(Product product) {
    return Container(
      width: 363,
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: MyColors.error.withAlpha(20), // #EF44441A
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: MyColors.error, // #EF4444
          width: 1,
        ),
      ),
      child: Row(
        children: [
          (product.imageData != null)
              ? ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(
                children: [
                  Center(child: Image.memory(product.imageData!)),
                  SizedBox.expand(
                    child: Container(
                      color: MyColors.error.withAlpha(50),
                    ),
                  ),
                ],
              ),
            ),
          )
              : const Icon(
            Icons.warning_amber_rounded,
            color: MyColors.error,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: MyFont.semiBold(14, color: MyColors.error),
                children: [
                  TextSpan(
                    text: product.name.split(' ').take(3).join(' '),
                    style: MyFont.semiBold(16, color: MyColors.error),
                  ),
                  if (product.stock == 0)
                    TextSpan(
                      text: ' is Out of Stock',
                      style: MyFont.semiBold(
                        16,
                        color: MyColors.error,
                      ), // size 18
                    )
                  else ...[
                    TextSpan(text: ' is low in stock\nOnly '),
                    TextSpan(
                      text: '${product.stock} units remaining.',
                      style: MyFont.bold(16, color: MyColors.error),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
