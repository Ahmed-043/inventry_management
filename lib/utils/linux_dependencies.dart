import 'dart:io';
import 'package:flutter/foundation.dart';

class LinuxDependencyManager {
  static const List<String> _requiredPackages = [
    'build-essential',
    'cmake',
    'ninja-build',
    'pkg-config',
    'libgtk-3-dev',
    'libsqlite3-dev',
    'libx11-dev',
    'libxext-dev',
    'libxcursor-dev',
    'libxrandr-dev',
    'libxinerama-dev',
    'libxi-dev',
    'libxxf86vm-dev',
    'libudev-dev',
    'libssl-dev',
    'libasound2-dev',
    'libpulse-dev',
    'clang',
  ];

  /// Check if a package is installed on the system
  static Future<bool> _isPackageInstalled(String packageName) async {
    try {
      final result = await Process.run('dpkg', ['-l'], runInShell: true);
      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        // Check if package is installed (look for "ii" status)
        final lines = output.split('\n');
        for (final line in lines) {
          if (line.contains(packageName)) {
            final parts = line.split(RegExp(r'\s+'));
            if (parts.isNotEmpty && parts[0] == 'ii') {
              return true;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking package $packageName: $e');
    }
    return false;
  }

  /// Get list of missing packages
  static Future<List<String>> getMissingPackages() async {
    if (!Platform.isLinux) return [];

    final missingPackages = <String>[];

    for (final package in _requiredPackages) {
      final isInstalled = await _isPackageInstalled(package);
      if (!isInstalled) {
        missingPackages.add(package);
      }
    }

    return missingPackages;
  }

  /// Install missing packages using apt-get (silent mode)
  static Future<bool> installMissingPackages(List<String> packages) async {
    if (packages.isEmpty) return true;

    try {
      // First update package lists
      final updateResult = await Process.run(
        'sudo',
        ['apt-get', 'update'],
        runInShell: true,
      );

      if (updateResult.exitCode != 0) {
        return false;
      }

      // Install packages
      final installResult = await Process.run(
        'sudo',
        ['apt-get', 'install', '-y', ...packages],
        runInShell: true,
      );

      return installResult.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Check and install dependencies if running on Linux (silent mode)
  static Future<void> checkAndInstallDependencies() async {
    if (!Platform.isLinux) return;

    try {
      final missingPackages = await getMissingPackages();

      // Simply run installation silently if packages are missing
      if (missingPackages.isNotEmpty) {
        await installMissingPackages(missingPackages);
      }
    } catch (e) {
      // Silently fail - app continues regardless
    }
  }

  /// Verify all packages are installed and return installation status
  static Future<Map<String, bool>> verifyAllPackages() async {
    if (!Platform.isLinux) return {};

    final verificationStatus = <String, bool>{};

    for (final package in _requiredPackages) {
      final isInstalled = await _isPackageInstalled(package);
      verificationStatus[package] = isInstalled;
    }

    return verificationStatus;
  }

  /// Get formatted verification report of all packages
  static Future<String> getVerificationReport() async {
    if (!Platform.isLinux) return 'Not running on Linux';

    final status = await verifyAllPackages();
    final buffer = StringBuffer();

    buffer.writeln('╔════════════════════════════════════════════════════════════╗');
    buffer.writeln('║          LINUX DEPENDENCIES VERIFICATION REPORT           ║');
    buffer.writeln('╚════════════════════════════════════════════════════════════╝\n');

    int installedCount = 0;
    int missingCount = 0;

    for (final entry in status.entries) {
      final package = entry.key;
      final isInstalled = entry.value;
      final statusSymbol = isInstalled ? '✓' : '✗';
      final statusText = isInstalled ? 'INSTALLED' : 'MISSING';

      buffer.writeln('$statusSymbol $package ... $statusText');

      if (isInstalled) {
        installedCount++;
      } else {
        missingCount++;
      }
    }

    buffer.writeln('\n╔════════════════════════════════════════════════════════════╗');
    buffer.writeln('║                        SUMMARY                            ║');
    buffer.writeln('╚════════════════════════════════════════════════════════════╝');
    buffer.writeln('Total Packages: ${_requiredPackages.length}');
    buffer.writeln('Installed: $installedCount');
    buffer.writeln('Missing: $missingCount');

    if (missingCount == 0) {
      buffer.writeln('\n✅ ALL PACKAGES INSTALLED! Ready to build Flutter app.\n');
    } else {
      buffer.writeln('\n⚠️ MISSING $missingCount PACKAGE(S)! Installation needed.\n');
      buffer.writeln('Run this command to install missing packages:');
      buffer.writeln('sudo apt-get install -y ${_requiredPackages.join(' ')}\n');
    }

    return buffer.toString();
  }

  /// Get formatted list of required packages with descriptions
  static String getPackageDescription() {
    return '''
Flutter Linux Required Dependencies:
- build-essential: C/C++ compiler and build tools
- cmake: Build system
- ninja-build: Build tool
- pkg-config: Configuration tool
- libgtk-3-dev: GTK 3 UI framework
- libsqlite3-dev: SQLite database library
- libx11-dev: X11 window system
- libxext-dev: X11 extensions
- libxcursor-dev: X11 cursor library
- libxrandr-dev: X11 Xrandr extension
- libxinerama-dev: X11 Xinerama extension
- libxi-dev: X11 Input extension
- libxxf86vm-dev: X11 XFree86 VM extension
- libudev-dev: Device management library
- libssl-dev: OpenSSL library
- libasound2-dev: ALSA audio library
- libpulse-dev: PulseAudio library
- clang: C/C++ compiler
''';
  }
}

