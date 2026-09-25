import 'dart:io';
import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

class GoogleDriveService {
  static final GoogleDriveService _instance = GoogleDriveService._internal();
  factory GoogleDriveService() => _instance;
  GoogleDriveService._internal();

  // IMPORTANT: For Windows/Desktop, you MUST use a "Web Application" client ID 
  // and Client Secret from the Google Cloud Console.
  // Add http://localhost:8000 to Authorized redirect URIs.
  static const String _clientId = String.fromEnvironment('GOOGLE_CLIENT_ID');
  static const String _clientSecret = String.fromEnvironment('GOOGLE_CLIENT_SECRET');

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    params: GoogleSignInParams(
      clientId: _clientId,
      clientSecret: _clientSecret,
      scopes: [
        drive.DriveApi.driveFileScope,
        'openid',
        'email',
        'profile',
      ],
      redirectPort: 8000,
    ),
  );

  GoogleSignInCredentials? _currentUser;
  drive.DriveApi? _driveApi;

  Future<GoogleSignInCredentials?> signIn() async {
    try {
      _currentUser = await _googleSignIn.signIn();
      if (_currentUser != null) {
        final authClient = await _googleSignIn.authenticatedClient;
        if (authClient != null) {
          _driveApi = drive.DriveApi(authClient);
        }
      }
      return _currentUser;
    } catch (error) {
      print('Google Sign-In Error: $error');
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
    _driveApi = null;
  }

  Future<bool> isSignedIn() async {
    final user = await getCurrentUser();
    return user != null;
  }

  Future<GoogleSignInCredentials?> getCurrentUser() async {
    if (_currentUser == null) {
      try {
        _currentUser = await _googleSignIn.silentSignIn();
        if (_currentUser != null) {
          final authClient = await _googleSignIn.authenticatedClient;
          if (authClient != null) {
            _driveApi = drive.DriveApi(authClient);
          }
        }
      } catch (e) {
        print('Silent Sign-In Error: $e');
      }
    }
    return _currentUser;
  }

  Future<String?> _getFolderId(String folderName) async {
    if (_driveApi == null) {
      await getCurrentUser();
      if (_driveApi == null) return null;
    }

    final query = "name = '$folderName' and mimeType = 'application/vnd.google-apps.folder' and trashed = false";
    final folderList = await _driveApi!.files.list(q: query);

    if (folderList.files != null && folderList.files!.isNotEmpty) {
      return folderList.files!.first.id;
    }

    // Create folder if not exists
    final folder = drive.File()
      ..name = folderName
      ..mimeType = 'application/vnd.google-apps.folder';
    
    final createdFolder = await _driveApi!.files.create(folder);
    return createdFolder.id;
  }

  Future<bool> uploadFile(
    File file, {
    String folderName = 'ODVENTORY_Backups',
    Function(double)? onProgress,
  }) async {
    try {
      if (_driveApi == null) {
        await getCurrentUser();
        if (_driveApi == null) return false;
      }

      final folderId = await _getFolderId(folderName);
      if (folderId == null) return false;

      final fileName = p.basename(file.path);
      final totalBytes = await file.length();
      int uploadedBytes = 0;

      // Create a progress-tracking stream
      final uploadStream = file.openRead().map((chunk) {
        uploadedBytes += chunk.length;
        if (onProgress != null) {
          onProgress(uploadedBytes / totalBytes);
        }
        return chunk;
      });

      final media = drive.Media(uploadStream, totalBytes);
      final driveFile = drive.File()
        ..name = fileName
        ..parents = [folderId];

      // Check if file already exists in the folder
      final query = "name = '$fileName' and '$folderId' in parents and trashed = false";
      final fileList = await _driveApi!.files.list(q: query);

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        // Update existing file
        final existingFileId = fileList.files!.first.id!;
        await _driveApi!.files.update(drive.File(), existingFileId, uploadMedia: media);
      } else {
        // Create new file
        await _driveApi!.files.create(driveFile, uploadMedia: media);
      }

      return true;
    } catch (e) {
      print('Google Drive Upload Error: $e');
      return false;
    }
  }
}
