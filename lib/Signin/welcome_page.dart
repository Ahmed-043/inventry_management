import 'dart:io';

import 'package:flutter/material.dart';
import 'package:inventry_management/Signin/sign_page_redesign.dart';
import 'package:inventry_management/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../Database/backup.dart';
import '../Database/database.dart';
import '../Database/db_info.dart';
import '../Home_Page/home_page.dart'; // For your custom colors

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
     await Future.delayed(const Duration(milliseconds: 1000));

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SigninPageRedsign()),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.translucent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Hero(
              tag: 'app_logo', // Unique tag for the Hero animation
              child: Container(
                width: 1000,
                height: 300,
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                 // shape: BoxShape.circle,
                ),
                child: Image.asset('assets/images/odventory_logo.png')
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: 500,
              child: LinearProgressIndicator(
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(MyColors.primary),
              ),
            )
          ],
        ),
      ),
    );
  }
}