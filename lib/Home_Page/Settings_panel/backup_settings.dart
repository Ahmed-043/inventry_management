import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import '../../Database/Reports_Data/export_database.dart';
import '../../Database/backup.dart';
import '../../Database/database.dart';
import '../../Database/db_info.dart';
import '../../Shared_Widgets/fonts.dart';
import '../../Shared_Widgets/main_ui_helper.dart';
import '../../colors.dart';

class DataBackup extends StatefulWidget {
  const DataBackup({super.key});

  @override
  State<DataBackup> createState() => _DataBackupState();
}

class _DataBackupState extends State<DataBackup> {
  List<String> frequency = ['Daily', 'Weekly', 'Monthly'];
  DateTime? lastBackup;
  int backupFrequency = 0;
  DBInfo? info;
  List<Map<String, dynamic>> backupLogs = [];
  bool showLogs = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadPreferences();
    loadLogs();
  }

  Future<void> loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> logs = prefs.getStringList('backup_logs') ?? [];
    backupLogs = logs.map((log) => jsonDecode(log) as Map<String, dynamic>).toList();
    setState(() {});
  }

  Future<void> loadPreferences() async {
    // Assume currentDB is your Database reference
    info = await getDBInfo(currentDB!);
    backupFrequency = info!.backupFreq; // per-DB frequency
    int lastBackupMillis = info!.lastBackup;
    if(lastBackupMillis != 0) lastBackup = DateTime.fromMillisecondsSinceEpoch(lastBackupMillis);

    setState(() {});
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      width: 500,
      //height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MyColors.translucent,
        border: UiHelper.myBorder(),
        boxShadow: UiHelper.myBoxShadow(),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Data Backup', style: MyFont.semiBold(20, color: MyColors.black)),
          const SizedBox(height: 4),
          Text(
            "Configure how your application data is backed up and stored.",
            style: MyFont.semiBold(12, color: MyColors.grey),
          ),
          const SizedBox(height: 10),

          /// Backup to Cloud Button
          SizedBox(
            width: double.infinity,
            height: 45,
            child: UiHelper.myButton(
              callback: () {
                UiHelper.showToast(context, "This option is not yet available!",type:2);
              }, // Add cloud backup logic
              filled: true,
              borderRadius: 10,
              color: MyColors.primary, // Specific to this action
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_outlined, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text('Backup to Cloud', style: MyFont.normal(14, color: Colors.white)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 25),

          /// Local Backup Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex:4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Automatic Local Backup', style: MyFont.semiBold(14, color: MyColors.black)),
                    Text(
                      'Automatically save a copy of your data on your local device.',
                      style: MyFont.semiBold(12, color: MyColors.grey),
                    ),
                    Tooltip(
                      message: info == null ? 'No backup directory set' : info!.backupDir,
                      child: InkWell(
                        onTap: () async {
                          // chose directory
                          String? path = await UiHelper.showDirectoryPicker(context, info?.backupDir);
                          if (path != null) {
                            // Ensure the last folder is 'Backup'
                            if (p.basename(path).toLowerCase() != 'backup') {
                              path = p.join(path, 'Backup');
                            }
                            // Create the folder if it doesn't exist
                            final dir = Directory(path);
                            if (!await dir.exists()) {
                              await dir.create(recursive: true);
                            }
                            updateBackupFrequency(backupFrequency, path: path);
                          }
                          setState(() {});
                        },
                        child: Text(
                          'Last Backup: ${lastBackup != null ? lastBackup!.toString() : 'Never'}',
                          style: MyFont.semiBold(12, color: MyColors.success),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(

                child: Center(
                  child: Switch(
                    value: backupFrequency != 0,
                    activeThumbColor: MyColors.translucent,
                    activeTrackColor: MyColors.primary,
                    onChanged: (val) => updateBackupFrequency(val ? 1 : 0),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),

          /// Frequency Selection
          Text('Backup Frequency', style: MyFont.semiBold(14, color: MyColors.black)),
          const SizedBox(height: 10),
          Row(
            children: List.generate(frequency.length, (i){
              bool isSelected = backupFrequency == i+1;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: SizedBox(
                  width: 90,
                  height: 40,
                  child: UiHelper.myButton(
                    callback: () => updateBackupFrequency(i+1),
                    filled: isSelected,
                    borderRadius: 8,
                    color: isSelected ? MyColors.primary : MyColors.lightGrey,
                    child: Text(
                      frequency[i],
                      style: MyFont.normal(
                        14,
                        color: isSelected ? Colors.white : MyColors.black,
                      ),
                    ),
                  ),
                ),
              );
            })



          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    showLogs = !showLogs;
                  });
                  if (showLogs) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_scrollController.hasClients) {
                        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                      }
                    });
                  }
                },
                child: Text(showLogs ? 'Hide Backup Logs' : 'View Backup Logs',
                    style: MyFont.semiBold(14, color: MyColors.primary)),
              ),
              if (showLogs && backupLogs.isNotEmpty)
                TextButton(
                  onPressed: () async {
                    await clearBackupLogs();
                    await loadLogs();
                  },
                  child: Text('Clear Logs',
                      style: MyFont.semiBold(14, color: Colors.red.shade700)),
                ),
            ],
          ),
          if (showLogs)
            Container(
              height: 200,
              width: double.infinity,
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: MyColors.lightGrey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: backupLogs.isEmpty
                  ? Center(child: Text('No logs available', style: MyFont.normal(12, color: MyColors.grey)))
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: backupLogs.length,
                      itemBuilder: (context, index) {
                        final log = backupLogs[index];
                        final DateTime dt = DateTime.parse(log['datetime']);
                        final String status = log['status'];
                        final String error = log['error'];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    log['dbName'] ?? 'Unknown DB',
                                    style: MyFont.bold(12, color: MyColors.black),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat('yyyy-MM-dd HH:mm:ss').format(dt),
                                    style: MyFont.normal(12, color: MyColors.grey),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    status,
                                    style: MyFont.semiBold(12,
                                        color: status == 'Success' ? Colors.green : Colors.red),
                                  ),
                                ],
                              ),
                              if (error.isNotEmpty)
                                Text(
                                  error,
                                  style: MyFont.normal(11, color: Colors.red.shade700),
                                ),
                              const Divider(height: 8, thickness: 0.5),
                            ],
                          ),
                        );
                      },
                    ),
            ),
        ],
      ),
    );
  }
  /// Update backup frequency for a specific DB
  Future<void> updateBackupFrequency(int freq, {String? path}) async {
    try {
      DBInfo? dbInfo = await getDBInfo(currentDB!);
      if (path != null) {
        await currentDB!.update(
          'info',
          {
            'backupFreq': freq,
            'backupDir': path
          },
          where: 'db_name = ?',
          whereArgs: [dbInfo.dbName],
        );
      } else {
        await currentDB!.update(
          'info',
          {'backupFreq': freq},
          where: 'db_name = ?',
          whereArgs: [dbInfo.dbName],
        );
      }
      info = await getDBInfo(currentDB!);
      final success = await backupDatabase(currentDB!, info!);
      await exportDatabaseToExcel(currentDB!, info!.backupDir, fileName: "${info!.dbName} Daily Backup");

      if (success) {
        info?.lastBackup = DateTime.now().millisecondsSinceEpoch;
        await updateDBBackupInfo(currentDB!, info!);
      }
      debugPrint("Backed up to: ${info?.backupDir}");
    } catch (e) {
      debugPrint("Update frequency failed: $e");
      String dbName = "Unknown";
      try {
        DBInfo? dbInfo = await getDBInfo(currentDB!);
        dbName = dbInfo.dbName;
      } catch (_) {}
      await addBackupLog(dbName, false, "Update frequency failed: $e");
    }

    await loadLogs();
    setState(() {
      backupFrequency = freq;
    });
  }


}