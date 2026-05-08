import 'dart:io';

import 'package:flutter/material.dart';
import 'package:inventry_management/Signin/sign_page_redesign.dart';
import 'package:inventry_management/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../Database/backup.dart';
import '../Database/database.dart';
import '../Database/db_info.dart';
import '../Home_Page/home_page.dart';
import '../utils/shader_warmup.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Start shader warmup in parallel with app initialization
    _warmupShaders();
    _initializeApp();
  }

  /// Warm up shaders while splash screen is displayed
  Future<void> _warmupShaders() async {
    try {
      // Let the splash screen render first
      await Future.delayed(const Duration(milliseconds: 100));

      if (mounted) {
        await ShaderWarmup.warmup(context);
        debugPrint('✅ Shader warmup completed on splash screen');
      }
    } catch (e) {
      debugPrint('⚠️ Shader warmup failed: $e');
    }
  }

  Future<void> _initializeApp() async {
     await Future.delayed(const Duration(milliseconds: 1000));
      final success = await openDatabaseFromPrefs();
    if(mounted && !success){
      Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SigninPageRedsign()),
    );
    }
  }

  Future<bool> openDatabaseFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('dbPath');

    if (path == null || path.isEmpty) return false;

    final file = File(path);
    if (!await file.exists()) return false;

    try {
      currentDB?.close();
      currentDB = await openDatabase(path);

      final isValid = await validateDatabaseSchema(currentDB!);
      if (!isValid) {
        await currentDB?.close();
        currentDB = null;
        return false;
      }

      final info = await getDBInfo(currentDB!);

      // optional: auto backup check
      await checkAndBackupDatabase(currentDB!);

      gotoHomePage(path, info);
      return true;
    } catch (e) {
      await currentDB?.close();
      currentDB = null;
      return false;
    }
  }

  void gotoHomePage(String path, DBInfo? info){
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomePage(path: path, info: info),
      ),
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