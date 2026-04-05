import 'package:flutter/material.dart';
import 'package:inventry_management/Database/retrieve_products.dart';
import 'package:inventry_management/Shared_Widgets/main_ui_helper.dart';
import 'package:inventry_management/colors.dart';
import 'package:intl/intl.dart';

import '../../Database/database.dart';
import '../../Shared_Widgets/fonts.dart';


class ProductCard extends StatelessWidget {
   final  Product product;
  ProductCard({super.key, required this.product });

  final formatter = NumberFormat('#,##0');

  @override
  Widget build(BuildContext context) {
    if(tileUi){
      return productCard();
    }else {
      return LayoutBuilder(builder: (context, c) {
        double height = c.maxHeight;
        return Container(
          decoration: BoxDecoration(
              color: MyColors.translucent,
              borderRadius: BorderRadius.circular(height*0.04),
              border: UiHelper.myBorder(),
              boxShadow: UiHelper.myBoxShadow()
          ),

          child: Column(
            children: [
              Expanded(
                flex: 3,
                child: product.imageData != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(height*0.038),
                  child: Image.memory(
                    product.imageData!,
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
                    double fontSize =
                        constraints.maxHeight; // 30% of container height
                    return Column(
                      children: [
                        Expanded(
                          flex: 5,
                          child: Text(
                            product.name.length > 20
                                ? '${product.name.substring(0, 20)}…'
                                : product.name,
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
                                  'Rs. ${product.totalPrice > 100000000
                                      ? product.totalPrice.toStringAsExponential(0)
                                      : formatter.format(product.totalPrice)}',
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
                                  '${product.totalWeight > 1_000_000 ? product.totalWeight.toStringAsExponential(2) : product.totalWeight.toStringAsFixed(2)} Kg',
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
                                message: 'Sold: ${NumberFormat.decimalPattern().format(product.sold)}',
                                waitDuration: Duration(milliseconds: 500),
                                child: Text(
                                  'Sold: ${product.sold > 1000000 ? product.sold.toStringAsExponential(2)
                                      : NumberFormat.decimalPattern().format(product.sold)}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: fontSize * 0.2,
                                    color: MyColors.primary,
                                  ),
                                ),
                              ),

                              Tooltip(
                                message: 'Stock: ${NumberFormat.decimalPattern().format(product.stock)}',
                                waitDuration: Duration(milliseconds: 500),
                                child: Text(
                                  'Stock: ${product.stock > 10_000_000 ? product.stock.toStringAsExponential(2) // scientific notation with 2 decimals
                                      : NumberFormat.decimalPattern().format(product.stock)}',
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
              SizedBox(height: 5),
            ],
          ),
        );
        },
      );

    }
  }
   Widget productCard() {
     return LayoutBuilder(
       builder: (context, constraints) {
         final h = constraints.maxHeight; // = 80

         return Container(
           height: 80,
           width: 380,
           decoration: BoxDecoration(
             color: MyColors.translucent,
             borderRadius: BorderRadius.circular(h*0.15),
             boxShadow: UiHelper.myBoxShadow(),
             border: UiHelper.myBorder(),
           ),
           child: Stack(
             children: [
               Row(
                 crossAxisAlignment: CrossAxisAlignment.center,
                 children: [
                   AspectRatio(
                     aspectRatio: 1,
                     child: ClipRRect(
                       borderRadius: BorderRadius.circular(h*0.15),
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
                       "Name: ${product.name}\nSKU: ${product.sku ?? "No SKU"}\nSold: ${product.sold}",
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
                               style: MyFont.semiBold(
                                 h * 0.2, // 🔹 scaled
                                 color: MyColors.darkBlue,
                               ),
                             ),
                           ),
                           SizedBox(
                             width: double.infinity,
                             child: Text(
                               'Stock: ${product.stock} ',
                               overflow: TextOverflow.ellipsis,
                               textAlign: TextAlign.start,
                               style: MyFont.semiBold(
                                 h * 0.15, // 🔹 scaled
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
                       padding: EdgeInsets.all(5),
                       child: Column(
                         children: [
                           Expanded(child: SizedBox()),
                           Expanded(
                             flex: 2,
                             child: Container(
                               width: double.infinity,
                               alignment: Alignment.center,
                               decoration: BoxDecoration(
                                 borderRadius: BorderRadius.circular(h*0.1),
                                 color: product.stock < 1
                                     ? MyColors.error
                                     : product.stock < lowStockLimit
                                     ? MyColors.primary
                                     : MyColors.success,
                               ),
                               child: Text(
                                 product.stock < 1
                                     ? "Out of Stock"
                                     : product.stock < lowStockLimit
                                     ? "Low Stock"
                                     : "In Stock",
                                 style: MyFont.semiBold(
                                   h * 0.14, // 🔹 scaled
                                   color: MyColors.translucent,
                                 ),
                               ),
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
                                   "Rs.${product.totalPrice > 9999999 ? "\n" : ''}${NumberFormat.decimalPattern().format(product.totalPrice.floor())}",
                                   style: MyFont.semiBold(
                                     h * 0.18, // 🔹 scaled
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
       },
     );
   }


}
