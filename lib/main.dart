import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inventry_management/Home_Page/sidebar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Database/database.dart';
import 'package:window_manager/window_manager.dart';
import 'Database/database_factory.dart';
import 'Signin/welcome_page.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'Shared_Widgets/app_cursor_overlay.dart';
import 'Shared_Widgets/window_title_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'utils/linux_dependencies.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final ValueNotifier<double> uiScaleNotifier = ValueNotifier<double>(1.0);
final ValueNotifier<bool> performanceModeNotifier = ValueNotifier<bool>(false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check and install Linux dependencies
  if (Platform.isLinux) {
    await LinuxDependencyManager.checkAndInstallDependencies();
  }

  // Run only on desktop
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await windowManager.ensureInitialized();

    // Set up window options
    WindowOptions options = const WindowOptions(
      title: 'Odventory',
      minimumSize: Size(650, 500),
      center: true,
      backgroundColor: Colors.white,
      titleBarStyle: TitleBarStyle.hidden,
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
  Widget app = const ProviderScope(child: MyApp());
  if (Platform.isWindows) {
    app = ExcludeSemantics(child: app);
  }
  runApp(app);
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  bool get _supportsCustomCursor {
    if (kIsWeb) return true;
    return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: uiScaleNotifier,
      builder: (context, scale, _) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'ODVENTORY',
          debugShowCheckedModeBanner: false,
          home: SplashScreen(),
          builder: (context, child) {
            if (child == null) return const SizedBox.shrink();

            final mediaQuery = MediaQuery.of(context);
            final realSize = mediaQuery.size;

            Widget scaledApp = Column(
              children: [
                if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS))
                  const WindowTitleBar(),
                Expanded(
                  child: SizedBox(
                    width: realSize.width,
                    height: realSize.height - ( (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) ? 32 : 0),
                    child: OverflowBox(
                      alignment: Alignment.topLeft,
                      minWidth: realSize.width / scale,
                      maxWidth: realSize.width / scale,
                      minHeight: (realSize.height - ( (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) ? 32 : 0)) / scale,
                      maxHeight: (realSize.height - ( (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) ? 32 : 0)) / scale,
                      child: Transform.scale(
                        scale: scale,
                        alignment: Alignment.topLeft,
                        child: MediaQuery(
                          data: mediaQuery.copyWith(
                            size: Size(realSize.width / scale, (realSize.height - ( (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) ? 32 : 0)) / scale),
                            devicePixelRatio: mediaQuery.devicePixelRatio * scale,
                          ),
                          child: child,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );

            if (!_supportsCustomCursor) {
              return scaledApp;
            }

            return ValueListenableBuilder<bool>(
              valueListenable: performanceModeNotifier,
              builder: (context, perfMode, _) {
                return AppCursorOverlay(
                  assetPath: 'assets/images/app_cursor.png',
                  clickCursorAssetPath: 'assets/images/hand_cursor.png',
                  textCursorAssetPath: 'assets/images/text_cursor.png',
                  size: 35.0,
                  child: scaledApp,
                );
              },
            );
          },
        );
      },
    );
  }
}

Future<void> loadPreferences() async {
  final prefs = await SharedPreferences.getInstance();
  if( prefs.getInt('productsPerPage') == null ) {
    await prefs.setInt('productsPerPage', 1000);
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
  performanceModeNotifier.value = performanceMode;

  if(prefs.getBool('plainUi') == null ) {
    await prefs.setBool('plainUi', false);
  }
  plainUi = false; //prefs.getBool('plainUi')!;

  if(prefs.getBool('tileUi') == null ) {
    await prefs.setBool('tileUi', false);
  }
  tileUi = prefs.getBool('tileUi')!;

  if(prefs.getBool('collapseSidebar') == null ) {
    await prefs.setBool('collapseSidebar', false);
  }
  collapseSideBar = prefs.getBool('collapseSidebar')!;

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

  hideDashboard = prefs.getBool('hideDashboard') ?? false;
  hideProducts = prefs.getBool('hideProducts') ?? false;
  hideCustomers = prefs.getBool('hideCustomers') ?? false;
  hideSuppliers = prefs.getBool('hideSuppliers') ?? false;
  hideOrders = prefs.getBool('hideOrders') ?? false;
  hideTransactions = prefs.getBool('hideTransactions') ?? false;
  hideReports = prefs.getBool('hideReports') ?? false;
  hideSettings = false;

  uiScale = prefs.getDouble('uiScale') ?? 1;
  uiScaleNotifier.value = uiScale;

  debugPrint("Loaded preferences: pageSize=$productsPerPage, cardSize=$cardSize, PersonCardSize=$personCardSize");
}