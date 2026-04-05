import 'package:flutter/material.dart';
import 'package:inventry_management/colors.dart';

class User {

  static Widget userCard({required String title,required VoidCallback callBack}) {
    return SizedBox(
      width: 200,
      height: 250,
      child: ElevatedButton(
        onPressed: callBack,

        style: ElevatedButton.styleFrom(
          // minimumSize: Size(200, 250),
          // maximumSize: Size(200, 250),
          backgroundColor: Colors.white,
          side: BorderSide(color: MyColors.primary, width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          padding: EdgeInsets.all(20),
        ),
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                height: 150,
                width: 150,
                decoration: BoxDecoration(
                  color: MyColors.primary.withAlpha((255*0.1).toInt()),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: MyColors.primary,
                  size: 100,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Center(
                child: Text(
                  title,
                  style: TextStyle(
                    color: MyColors.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget newCard({required String title,required IconData icon,Color? mColor,required VoidCallback callback}) {
    return ElevatedButton(onPressed: callback,
      style: ElevatedButton.styleFrom(
        minimumSize: Size(250, 80),
        maximumSize: Size(250, 80),
        backgroundColor: mColor ?? Colors.white,
        side: BorderSide(color: mColor ?? MyColors.primary, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
        padding: EdgeInsets.all(20),
      ),
      child: Text(title,
        style: TextStyle(fontSize: 20,color: mColor ==null? MyColors.primary: Colors.white),),


    );

  }

}
