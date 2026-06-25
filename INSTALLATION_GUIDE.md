# Linux Package Verification & Installation Guide

## 📋 How It Works Now

Your Flutter app now has a **silent** package checker:
- ✅ Automatically checks/installs packages on app startup (NO debug output)
- ✅ Runs only on Linux (safe on other platforms)
- ✅ No cluttering of app debug console
- ✅ App runs normally regardless of package installation status

## 🔧 To Check Installation Status in Terminal

Use the provided shell script to verify all packages are installed:

```bash
cd ~/StudioProjects/inventry_management
./check_dependencies.sh
```

This will show you:
- ✓ Which packages are INSTALLED
- ✗ Which packages are MISSING
- Summary of installation status
- Command to install missing packages

## 📦 To Install Missing Packages Manually

If the script shows missing packages, run:

```bash
sudo apt-get update && sudo apt-get install -y libssl-dev
```

Or for all packages at once:

```bash
sudo apt-get update && sudo apt-get install -y \
    build-essential cmake ninja-build pkg-config \
    libgtk-3-dev libsqlite3-dev libx11-dev libxext-dev \
    libxcursor-dev libxrandr-dev libxinerama-dev libxi-dev \
    libxxf86vm-dev libudev-dev libssl-dev libasound2-dev \
    libpulse-dev clang
```

## 🚀 Quick Start

### First Time Setup
```bash
# 1. Check current status
./check_dependencies.sh

# 2. Install any missing packages (if shown)
sudo apt-get update && sudo apt-get install -y [missing-packages]

# 3. Verify all are installed
./check_dependencies.sh

# 4. Build your app (clean first for fresh build)
flutter clean
flutter pub get
flutter run -d linux
```

### Subsequent Runs
```bash
flutter run -d linux
```

The app will silently check and install packages if needed (may prompt for sudo password).

## 📝 Current Status

Run this to see current installation:
```bash
./check_dependencies.sh
```

## 🎯 Key Points

- **Silent**: No debug spam in Flutter console
- **Automatic**: App checks on startup
- **Manual Check**: Use `./check_dependencies.sh` anytime
- **No Impact**: App runs even if packages can't install
- **Clean**: Only installs on Linux (safe on Windows/Mac)

## 📂 Files

- `check_dependencies.sh` - Shell script to verify packages (run manually in terminal)
- `lib/utils/linux_dependencies.dart` - App code that checks/installs silently
- `lib/main.dart` - Integrated to call the checker on startup

---

**Done!** Your app now handles Linux dependencies cleanly without cluttering the debug console. 🎉

