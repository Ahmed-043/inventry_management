import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../../utils/google_drive_service.dart';
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
  final GoogleDriveService _googleDriveService = GoogleDriveService();
  GoogleSignInCredentials? _googleUser;
  Map<String, dynamic>? _googleProfile;
  bool _isBackingUp = false;
  String _backupStatus = "Backup to Cloud Now";
  bool _hasInternet = false;
  double _backupProgress = 0.0;

  @override
  void initState() {
    super.initState();
    loadPreferences();
    loadLogs();
    _checkGoogleStatus();
  }

  Future<void> _checkGoogleStatus() async {
    _googleUser = await _googleDriveService.getCurrentUser();
    if (_googleUser?.idToken != null) {
      _googleProfile = JwtDecoder.decode(_googleUser!.idToken!);
    }
    await _syncBackupStatus();
  }

  Future<void> _syncBackupStatus() async {
    try {
      final result = await InternetAddress.lookup('google.com').timeout(const Duration(seconds: 3));
      _hasInternet = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      _hasInternet = false;
    }

    if (backupFrequency != 0) {
      if (_googleUser != null && _hasInternet) {
        if (info?.googleBackup != 1) await updateGoogleBackup(1, silent: true);
      } else {
        if (info?.googleBackup != 0) await updateGoogleBackup(0, silent: true);
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _handleGoogleSignIn() async {
    final user = await _googleDriveService.signIn();
    setState(() {
      _googleUser = user;
      if (user?.idToken != null) {
        _googleProfile = JwtDecoder.decode(user!.idToken!);
      } else {
        _googleProfile = null;
      }
    });
    if (user != null) {
      final email = _googleProfile?['email'] ?? 'Google Account';
      if (!mounted) return;
      UiHelper.showToast(context, "Logged in as $email", type: 1);
      await _syncBackupStatus();
    } else {
      if (!mounted) return;
      UiHelper.showToast(context, "Google Login Failed", type: 2);
    }
  }

  Future<void> _handleGoogleSignOut() async {
    await _googleDriveService.signOut();
    setState(() {
      _googleUser = null;
      _googleProfile = null;
    });
    await updateGoogleBackup(0, silent: true);
    if (!mounted) return;
    UiHelper.showToast(context, "Logged out from Google",type: 3);
  }

  Future<void> _manualCloudBackup() async {
    if (_isBackingUp || info == null) return;
    
    if (_googleUser == null) {
      await _handleGoogleSignIn();
      if (_googleUser == null) return;
    }

    if (!mounted) return;
    
    setState(() {
      _isBackingUp = true;
      _backupStatus = "Starting...";
      _backupProgress = 0.05;
    });
    
    try {
      // 1. Local Database Backup (Preparation)
      setState(() {
        _backupStatus = "Preparing...";
        _backupProgress = 0.0;
      });
      final success = await backupDatabase(currentDB!, info!);
      
      if (success) {
        // 2. Cloud Upload (Progress tracked here)
        setState(() => _backupStatus = "Uploading...");
        
        final dbFile = File(currentDB!.path);
        final cloudSuccess = await _googleDriveService.uploadFile(
          dbFile,
          onProgress: (progress) {
            if (mounted) {
              setState(() => _backupProgress = progress);
            }
          },
        );
        
        if (!mounted) return;
        
        if (cloudSuccess) {
          setState(() => _backupProgress = 1.0);
          UiHelper.showToast(context, "Cloud Backup Successful!", type: 1);
          info!.lastCloudBackup = DateTime.now().millisecondsSinceEpoch;
          info!.lastBackup = DateTime.now().millisecondsSinceEpoch;
          await updateDBBackupInfo(currentDB!, info!);
          await addBackupLog(info!.dbName, true, "Manual Cloud Backup Success", type: "Cloud");
        } else {
          setState(() => _backupProgress = 0.0);
          UiHelper.showToast(context, "Cloud Upload Failed - Check Internet Connection", type: 2);
          await addBackupLog(info!.dbName, false, "Cloud Upload Failed", type: "Cloud");
        }
      } else {
        setState(() => _backupProgress = 0.0);
        if (!mounted) return;
        UiHelper.showToast(context, "Local Backup Failed - Check Disk Space and backup location", type: 2);
      }
    } catch (e) {
      setState(() => _backupProgress = 0.0);
      if (!mounted) return;
      UiHelper.showToast(context, "Backup Error: $e", type: 2);
      await addBackupLog(info?.dbName ?? "Unknown", false, "Cloud Backup Error: $e", type: "Cloud");
    } finally {
      if (mounted) {
        setState(() {
          _isBackingUp = false;
          _backupStatus = "Backup to Cloud Now";
        });
      }
    }
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

          if (info == null)
            const Center(child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ))
          else ...[
            /// Backup to Cloud Button
            SizedBox(
              width: double.infinity,
              height: 45,
              child: UiHelper.myButton(
                callback: _manualCloudBackup, 
                filled: true,
                borderRadius: 10,
                color: MyColors.primary, // Specific to this action
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                  if (_isBackingUp)
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            value: _backupProgress,
                            strokeWidth: 2,
                            color: Colors.white,
                            backgroundColor: Colors.white24,
                          ),
                        ),
                        Text(
                          '${(_backupProgress * 100).toInt()}',
                          style: MyFont.bold(12, color: Colors.white),
                        ),
                      ],
                    )
                  else
                    const Icon(Icons.cloud_outlined, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(_backupStatus, style: MyFont.normal(14, color: Colors.white)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            /// Google Account Info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha((255 * 0.5).toInt()),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: MyColors.lightGrey),
              ),
              child: Row(
                children: [
                  Icon(
                    _googleUser != null ? Icons.account_circle : Icons.account_circle_outlined,
                    color: _googleUser != null ? Colors.blue : MyColors.grey,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Builder(
                          builder: (context) {
                            String name = 'Not Logged In';
                            if (_googleUser != null) {
                              name = _googleProfile?['name'] ?? 'Google User';
                            }
                            return Text(
                              name,
                              style: MyFont.semiBold(13, color: MyColors.black),
                            );
                          },
                        ),
                        if (_googleUser != null)
                          Text(
                            _googleProfile?['email'] ?? '',
                            style: MyFont.normal(11, color: MyColors.grey),
                          ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _googleUser != null ? _handleGoogleSignOut : _handleGoogleSignIn,
                    child: Text(
                      _googleUser != null ? 'Logout' : 'Login',
                      style: MyFont.semiBold(12, color: _googleUser != null ? Colors.red : MyColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            /// Automatic Backup Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _googleUser != null && _hasInternet 
                          ? 'Automatic Backup'
                          : 'Automatic Backup (Local Only)',
                        style: MyFont.semiBold(14, color: MyColors.black)
                      ),
                      Text(
                        _googleUser != null && _hasInternet
                          ? 'Automatically save data locally and upload to Google Drive.'
                          : 'Automatically save a copy of your data on your local device.',
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Last Local: ${(info?.lastBackup ?? 0) != 0 ? DateTime.fromMillisecondsSinceEpoch(info!.lastBackup).toString().split('.')[0] : 'Never'}',
                                  style: MyFont.semiBold(11, color: MyColors.success),
                                ),
                                if (_googleUser != null && _hasInternet)
                                  Text(
                                    'Last Cloud: ${(info?.lastCloudBackup ?? 0) != 0 ? DateTime.fromMillisecondsSinceEpoch(info!.lastCloudBackup).toString().split('.')[0] : 'Never'}',
                                    style: MyFont.semiBold(11, color: Colors.blue),
                                  ),
                              ],
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
                      onChanged: (val) async {
                        if (val) {
                          await updateBackupFrequency(1); // Default to Daily
                          await _syncBackupStatus();
                        } else {
                          await updateBackupFrequency(0);
                          await updateGoogleBackup(0, silent: true);
                        }
                      },
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
          ],
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
              padding: const EdgeInsets.symmetric(horizontal: 10),
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
                                  if (log['type'] != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: log['type'] == 'Cloud' ? Colors.blue.withAlpha(30) : Colors.grey.withAlpha(30),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        log['type'],
                                        style: MyFont.bold(9, color: log['type'] == 'Cloud' ? Colors.blue : MyColors.grey),
                                      ),
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
                                        color: status == 'Success' ? MyColors.success : MyColors.error),
                                  ),
                                ],
                              ),
                              if (error.isNotEmpty)
                                Text(
                                  error,
                                  style: MyFont.normal(11, color: MyColors.grey),
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
  /// Update google backup status
  Future<void> updateGoogleBackup(int enabled, {bool silent = false}) async {
    try {
      DBInfo? dbInfo = await getDBInfo(currentDB!);
      await currentDB!.update(
        'info',
        {'googleBackup': enabled},
        where: 'db_name = ?',
        whereArgs: [dbInfo.dbName],
      );
      info = await getDBInfo(currentDB!);
      setState(() {});
      if (!silent && mounted) {
        UiHelper.showToast(context, enabled == 1 ? "Cloud Backup Enabled" : "Cloud Backup Disabled");
      }
    } catch (e) {
      debugPrint("Update Google backup failed: $e");
    }
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
      // Removed manual excel export here as per user request
      
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