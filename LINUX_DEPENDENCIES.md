# Linux Dependency Management

## Overview
This Flutter app now includes automatic Linux dependency checking and installation on startup. The app will automatically verify that all required packages are installed when running on a Linux system.

## Features

### Automatic Dependency Detection
When the app starts on Linux, it:
1. **Checks** if all required packages are installed using `dpkg`
2. **Identifies** any missing packages
3. **Installs** missing packages automatically using `sudo apt-get install`
4. **Logs** the process for debugging purposes

### Required Packages
The app automatically ensures these packages are installed:

- **Build Tools**
  - build-essential: C/C++ compiler and build tools
  - cmake: Build system
  - ninja-build: Build tool
  - clang: C/C++ compiler

- **Development Libraries**
  - pkg-config: Configuration tool for compiling
  - libssl-dev: OpenSSL library
  - libudev-dev: Device management library

- **GUI Framework**
  - libgtk-3-dev: GTK 3 UI framework
  - libx11-dev: X11 window system
  - libxext-dev: X11 extensions
  - libxcursor-dev: X11 cursor library
  - libxrandr-dev: X11 Xrandr extension
  - libxinerama-dev: X11 Xinerama extension
  - libxi-dev: X11 Input extension
  - libxxf86vm-dev: X11 XFree86 VM extension

- **Database & Storage**
  - libsqlite3-dev: SQLite database library

- **Audio**
  - libasound2-dev: ALSA audio library
  - libpulse-dev: PulseAudio library

## How It Works

1. **On First Run**: The app checks which packages are missing
2. **Installation**: If packages are missing, the app attempts to install them using:
   ```
   sudo apt-get update
   sudo apt-get install -y [package1] [package2] ...
   ```
3. **Logging**: All checks and installations are logged to the console (visible in `flutter run` output)
4. **Fallback**: If installation fails, the app logs the command to run manually

## Requirements

- **Sudo Access**: The app requires sudo privileges to install packages
- **apt-get**: Your system must use apt-get package manager (Debian/Ubuntu based)
- **First Run**: May prompt for sudo password on first run with missing packages

## Implementation Details

### Files Modified
- `lib/main.dart` - Added dependency check on startup
- `lib/utils/linux_dependencies.dart` - New file with dependency management logic

### Code Flow
```dart
main() 
  → WidgetsFlutterBinding.ensureInitialized()
  → LinuxDependencyManager.checkAndInstallDependencies() [if Platform.isLinux]
    → getMissingPackages()
    → installMissingPackages() [if needed]
  → Continue app initialization
```

## Console Output Example

```
[✓] Checking Linux dependencies...
[✓] All required packages are installed

// OR if packages are missing:

[!] Checking Linux dependencies...
[!] Missing packages: libpulse-dev, libasound2-dev
[*] Updating package lists...
[*] Installing packages...
[✓] Packages installed successfully
```

## Troubleshooting

### Packages still missing after app starts?
If you see warnings in the console that packages couldn't be installed:
1. Run manually: `sudo apt-get update && sudo apt-get install -y [packages]`
2. Check your internet connection
3. Verify you have sudo privileges

### App requires password on first run?
This is normal. The app is installing system packages and needs sudo privileges.

### Non-Ubuntu/Debian systems?
This feature only works on Debian/Ubuntu-based distributions with apt-get. For other Linux distributions, you may need to manually install the packages as listed above.

## Disabling Automatic Installation

If you want to disable automatic installation (for example, to manage packages manually):

Edit `lib/main.dart` and comment out:
```dart
// if (Platform.isLinux) {
//   await LinuxDependencyManager.checkAndInstallDependencies();
// }
```

Then install packages manually using the appropriate command for your distribution.

## Manual Installation (if needed)

```bash
sudo apt-get update
sudo apt-get install -y build-essential cmake ninja-build pkg-config libgtk-3-dev libsqlite3-dev libx11-dev libxext-dev libxcursor-dev libxrandr-dev libxinerama-dev libxi-dev libxxf86vm-dev libudev-dev libssl-dev libasound2-dev libpulse-dev clang
```

---

*This feature ensures your Flutter Linux app has all required dependencies without manual setup!*

