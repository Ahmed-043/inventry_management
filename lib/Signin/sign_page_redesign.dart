import 'dart:io';

import 'package:flutter/material.dart';
import 'package:inventry_management/Home_Page/Products_Panel/delete_confirmation.dart';
import 'package:inventry_management/Shared_Widgets/fonts.dart';
import 'package:inventry_management/Shared_Widgets/main_ui_helper.dart';
import 'package:inventry_management/colors.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../Database/backup.dart';
import '../Database/database.dart';
import '../Database/db_info.dart';
import '../Home_Page/home_page.dart';
import 'create_new_database.dart';
import 'import_database.dart';

class SigninPageRedsign extends StatefulWidget {
  const SigninPageRedsign({super.key});

  @override
  State<SigninPageRedsign> createState() => _SigninPageRedsignState();
}

class _SigninPageRedsignState extends State<SigninPageRedsign> {
  List<String> paths = [];
  bool compress = false;

  @override
  initState() {
    super.initState();
    _loadPaths();

  }

  Future<void> _loadPaths() async {
    currentDB?.close();
    currentDB = null;
    List<String> dbs = await getDbPaths();
    setState(() {
      paths = dbs;
    });
    bool opened = await openDatabaseFromPrefs();
    if(!opened){

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


  @override
  Widget build(BuildContext context) {
    compress = MediaQuery.of(context).size.width < 900 ? true : false;
    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: Container(
            width: compress ? 480: 900,
            height: compress ? double.infinity :700,
            decoration: BoxDecoration(
              color: MyColors.translucent,
              borderRadius: BorderRadius.all(Radius.circular(30)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((255 * 0.2).toInt()),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(30)),
              child: SingleChildScrollView(
                child: Wrap(
                  //crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.center,
                  children: [
                    SizedBox(
                      height: 150,
                      width: double.infinity,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Welcome to ODVENTORY",
                            textAlign: TextAlign.center,
                            style: MyFiraFont.medium(compress ? 40 :50, color: MyColors.darkBlue),
                          ),
                          Container(color: MyColors.info, width: 500, height: 3),
                          Text(
                            "Choose a database to get started",
                            textAlign: TextAlign.center,
                            style: MyFiraFont.medium(20, color: MyColors.grey),
                          ),
                        ],
                      ),
                    ),
                    Center(
                      child: Wrap(
                        //crossAxisAlignment: WrapCrossAlignment.start,
                        alignment: WrapAlignment.center,
                        children: [
                          SizedBox(width: 450,height: 500,child: createCard()),
                          SizedBox(width: 450,height: 500,child: selectionCard()),
                        ],
                      ),
                    ),
                    Text("Need Help! Visit our support page",style: MyFiraFont.medium(20, color: MyColors.grey),)

                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget selectionCard() {
    return SizedBox(
      child: Center(
        child: Container(
          margin: EdgeInsets.only(top: 20, bottom: 20, left: 10, right: 20),
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: MyColors.translucent,
            borderRadius: BorderRadius.all(Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((255 * 0.2).toInt()),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    Text(
                      "Open Existing Database",
                      style: MyFiraFont.medium(25, color: MyColors.darkBlue),
                    ),
                    Container(color: MyColors.primary, width: 250, height: 3),
                  ],
                ),
              ),
              Expanded(
                flex: 7,
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  child: Column(
                    children: List.generate(paths.length, (index) {
                      String dbName = p.basenameWithoutExtension(
                        paths[index],
                      );
                      return Container(
                        width: double.infinity,
                        margin: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 5,
                        ),
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(
                            Radius.circular(20),
                          ),
                          border: Border.all(
                            color: MyColors.primary,
                            width: 2.0,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Material(

                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              openUserDatabase(paths[index]);
                            },
                            onLongPress: (){
                                showDeleteDialog(context: context,
                                    message: '\n$dbName',
                                    onDeleted: () async {
                                      await removeDbPath(paths[index]);
                                      _loadPaths();
                                    });
                            },
                            splashColor: MyColors.primary.withAlpha(50),
                            splashFactory: InkRipple.splashFactory,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                children: [
                                  ClipOval(
                                    child: Container(
                                      width: 60,
                                      height: 60,
                                      color: MyColors.primary.withAlpha(30),
                                      child: Icon(
                                        Icons.inventory_2_outlined,
                                        size: 35,
                                        color: MyColors.primary,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          dbName,
                                          style: MyFont.semiBold(
                                            20,
                                            color: MyColors.primary,
                                          ),
                                        ),
                                        Flexible(
                                          child: Text(
                                            paths[index],
                                            overflow: TextOverflow.ellipsis,
                                            softWrap: false,
                                            style: MyFont.semiBold(
                                              10,
                                              color: MyColors.grey,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget createCard() {
    return SizedBox(
      child: Center(
        child: Container(
          margin: EdgeInsets.only(top: 20, bottom: 20, left: 20, right: 10),
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: MyColors.translucent,
            borderRadius: BorderRadius.all(Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((255 * 0.2).toInt()),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    Text(
                      "Create New Database",
                      style: MyFiraFont.medium(25, color: MyColors.darkBlue),
                    ),
                    Container(color: MyColors.info, width: 230, height: 3),
                    Text(
                      "Fresh start with a new inventory",
                      style: MyFiraFont.medium(17, color: MyColors.grey),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        width: double.infinity,
                        height: 70,
                        child: UiHelper.elevatedIconButton(
                          callBack: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (BuildContext context) {
                                return CreateNewDatabase(callback: (){
                                  setState(() {
                                    _loadPaths();
                                  });
                                },);
                              },
                            );

                          },
                          color: MyColors.info,
                          icon: Icon(Icons.add, size: 50, color: Colors.white),
                          label: Text(
                            "Create Local Database",
                            style: MyFiraSFont.semiBold(
                              20,
                              color: MyColors.translucent,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        width: double.infinity,
                        height: 70,
                        child: UiHelper.elevatedIconButton(
                          callBack: () {},
                          color: MyColors.error,
                          icon: Icon(
                            Icons.network_locked_rounded,
                            size: 40,
                            color: Colors.white,
                          ),
                          label: Text(
                            "Create Online Database",
                            style: MyFiraSFont.semiBold(
                              20,
                              color: MyColors.translucent,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        width: double.infinity,
                        height: 70,
                        child: UiHelper.elevatedIconButton(
                          callBack: () {},
                          color: MyColors.success,
                          icon: Icon(
                            Icons.g_mobiledata_rounded,
                            size: 60,
                            color: Colors.white,
                          ),
                          label: Text(
                            "Create Google Database",
                            style: MyFiraSFont.semiBold(
                              20,
                              color: MyColors.translucent,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 50,
                        width: 300,
                        child: UiHelper.elevatedIconButton(
                          callBack: () {
                            importDatabase(context,callBack: (){
                              setState(() {
                                _loadPaths();
                              });
                            });
                          },
                          icon: Icon(
                            Icons.folder_copy_rounded,
                            size: 30,
                            color: Colors.grey,
                          ),
                          label: Text(
                            "Import From Device",
                            style: MyFiraSFont.semiBold(
                              20,
                              color: MyColors.grey,
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
        ),
      ),
    );
  }

  Future<void> openUserDatabase(String path) async {
    if (await File(path).exists()) {
      try{
        final pref = await SharedPreferences.getInstance();
        currentDB?.close();
        currentDB = null;
        currentDB = await openDatabase(path);

        if (await validateDatabaseSchema(currentDB!)) {
          DBInfo? info = await getDBInfo(currentDB!);
          debugPrint('${info.image?.lengthInBytes}');

          checkAndBackupDatabase(currentDB!);
          pref.setString('dbPath', path);
          gotoHomePage(path, info);
        } else {
          repairDialog();
        }
      } catch(e){
        UiHelper.showToast(context, e.toString());
      }
    } else {
      warning("File does not exist");
    }
  }

  void gotoHomePage(String path, DBInfo? info){

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HomePage(path: path, info: info),
      ),
    );
  }
  void repairDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Invalid Database"),
          content: Text(
            "The selected database does not match the required schema. Please select a valid database.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("OK"),
            ),
            TextButton(
              onPressed: () {
                try {
                  ensureDatabaseSchema(currentDB!);
                } catch (e) {
                  debugPrint("Error repairing database: $e");
                  warning("Error repairing database");
                }
                Navigator.pop(context);
              },
              child: Text("Repair"),
            ),
          ],
        );
      },
    );
  }
  void warning(String message){
    UiHelper.showToast(context, message);
    // ScaffoldMessenger.of(
    //   context,
    // ).showSnackBar(SnackBar(content: Text(message)));
  }


}
