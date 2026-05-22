import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Database/database.dart';
import 'package:window_manager/window_manager.dart';
import 'Database/database_factory.dart';
import 'Signin/welcome_page.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'Shared_Widgets/app_cursor_overlay.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Run only on desktop
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await windowManager.ensureInitialized();

    // Set up window options
    WindowOptions options = const WindowOptions(
      title: 'Odventory',
      minimumSize: Size(650, 500),
      center: true,
      backgroundColor: Colors.white,
      titleBarStyle: TitleBarStyle.normal,
    );

    windowManager.waitUntilReadyToShow(options, () async {
      await Future.delayed(const Duration(milliseconds: 100));

      // Set window state but don't show yet
      await windowManager.maximize();

      // Wait a frame for layout
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future.delayed(const Duration(milliseconds: 100));

        // Re-apply maximize and force repaint
        await windowManager.maximize();
        await windowManager.show();
        await windowManager.focus();
        WidgetsBinding.instance.scheduleWarmUpFrame();
      });
    });
  }else{
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
  }

  // Initialize FFI (works only on non-web)
  await initDatabaseFactory();
  await syncDatabases();
  loadPreferences();
  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  bool get _supportsCustomCursor {
    if (kIsWeb) return true;
    return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'ODVENTORY',
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
      builder: (context, child) {
        if (!_supportsCustomCursor || child == null) {
          return child ?? const SizedBox.shrink();
        }
        return AppCursorOverlay(
          assetPath: 'assets/images/app_cursor.png',
          size: 35.0,
          child: child,
        );
      },
    );
  }
}

Future<void> loadPreferences() async {
  final prefs = await SharedPreferences.getInstance();
  if( prefs.getInt('productsPerPage') == null ) {
    await prefs.setInt('productsPerPage', 50);
  }
  productsPerPage = prefs.getInt('productsPerPage');

  if( prefs.getInt('personsPerPage') == null ) {
    await prefs.setInt('personsPerPage', 50);
  }
  personsPerPage = prefs.getInt('personsPerPage');

  if( prefs.getInt('ordersPerPage') == null ) {
    await prefs.setInt('ordersPerPage', 50);
  }
  ordersPerPage = prefs.getInt('ordersPerPage');

  if( prefs.getInt('transactionsPerPage') == null ) {
    await prefs.setInt('transactionsPerPage', 100);
  }
  transactionsPerPage = prefs.getInt('transactionsPerPage');

  if( prefs.getDouble('cardSize') == null ) {
    await prefs.setDouble('cardSize', 300.0);
  }
  cardSize = prefs.getDouble('cardSize');

  if( prefs.getDouble('personCardSize') == null ) {
    await prefs.setDouble('personCardSize', 200.0);
  }
  personCardSize = prefs.getDouble('personCardSize');

  if(prefs.getBool('performanceMode') == null ) {
    await prefs.setBool('performanceMode', false);
  }
  performanceMode = prefs.getBool('performanceMode')!;

  if(prefs.getBool('plainUi') == null ) {
    await prefs.setBool('plainUi', false);
  }
  plainUi = prefs.getBool('plainUi')!;

  if(prefs.getBool('tileUi') == null ) {
    await prefs.setBool('tileUi', false);
  }
  tileUi = prefs.getBool('tileUi')!;

  if( prefs.getInt('backupFreq') == null ) {
    await prefs.setInt('backupFreq', 0);
  }

  if( prefs.getInt('lowStockLimit') == null ) {
    await prefs.setInt('lowStockLimit', 50);
  }
  lowStockLimit = prefs.getInt('lowStockLimit')!;

  if( prefs.getInt('sortCategory') == null ) {
    await prefs.setInt('sortCategory', 0);
  }
  sortCategory = prefs.getInt('sortCategory')!;

  if( prefs.getInt('sort') == null ) {
    await prefs.setInt('sort', 9);
  }
  sort = prefs.getInt('sort')!;


  debugPrint("Loaded preferences: pageSize=$productsPerPage, cardSize=$cardSize, PersonCardSize=$personCardSize");
}