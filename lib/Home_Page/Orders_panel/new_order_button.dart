import 'package:flutter/material.dart';
import 'package:inventry_management/Shared_Widgets/fonts.dart';
import 'package:inventry_management/Shared_Widgets/main_ui_helper.dart';
import 'package:inventry_management/Shared_Widgets/scaled_container.dart';
import '../../colors.dart';
import 'New_Order_Page/new_order_page.dart';

class NewOrder  {
   static Widget button({required BuildContext context, bool sell = true, required VoidCallback callBack}){

    return ScaledContainer(
      child: Hero(
        tag: sell ? 'sellOrderHero' : 'buyOrderHero',
        child: SizedBox(
          height: double.infinity,
          width: 200,
         // margin: EdgeInsets.only(top:10,bottom: 5),
          child: ElevatedButton(onPressed: (){
            // Navigator.push(context, MaterialPageRoute(builder: (context) => ));
            UiHelper.pushPage(context: context, page: NewOrderPage(sell: sell,callback: callBack));
          },
              style: ElevatedButton.styleFrom(
                overlayColor: Colors.white, // 👈 ripple color
                backgroundColor: sell ? MyColors.primary : MyColors.blue,
                elevation: 0,
                enableFeedback: true,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child:
              Text(sell ? "Sell" : "Buy", style: MyFont.semiBold(20, color: MyColors.translucent))),
        ),
      ),
    );

  }
}


