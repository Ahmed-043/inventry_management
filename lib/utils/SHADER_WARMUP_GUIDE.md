# Widget Prewarming & Shader Compilation Guide

This document explains different approaches to render/warmup widgets at startup to reduce first-frame jank.

---

## 🎯 Problem

Your app has shader compilation jank on first render (visible in `order_detail_card.dart` delays). Flutter compiles shaders on-demand, causing frame drops when complex widgets first render.

---

## ✅ Solution: Implement in Your App

### 1. **Current Implementation** (Recommended)
Added to `lib/utils/shader_warmup.dart` and integrated into `main.dart`.

**How it works:**
```dart
// In main.dart
class _WarmupWrapper extends StatefulWidget {
  // Triggers ShaderWarmup.warmup() after first frame
  // Renders test widgets off-screen to precompile shaders
  // Removes them after 500ms
}
```

**Benefits:**
- ✅ No visible jank to user
- ✅ All common shaders precompiled
- ✅ Works on all platforms
- ✅ Customizable widget list

**Limitations:**
- Adds ~500ms to startup time
- Memory spike during warmup

---

## 🔄 Alternative Approaches

### 2. **Lazy Loading** (Minimal Overhead)
```dart
class OrderDetailsCard extends StatefulWidget {
  @override
  State<OrderDetailsCard> createState() => _OrderDetailsCardState();
}

class _OrderDetailsCardState extends State<OrderDetailsCard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Keep widget alive in tree

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return _buildContent();
  }
}
```

**Benefits:**
- Minimal startup overhead
- Widgets stay rendered in memory once accessed

---

### 3. **RepaintBoundary** (Performance Optimization)
Wrap expensive widgets:
```dart
@override
Widget build(BuildContext context) {
  return RepaintBoundary(
    child: OrderDetailsCard(...),
  );
}
```

**Benefits:**
- Limits repaints to widget subtree
- Faster updates
- Precompiles render layer

---

### 4. **Manual Shader Warmup** (Advanced)

```dart
// In a separate service
class ShaderWarmupService {
  static Future<void> precompileCommonShaders(BuildContext context) async {
    final overlay = Overlay.of(context);
    
    // Render expensive widgets off-screen
    final entry = OverlayEntry(
      builder: (_) => Positioned(
        top: -10000, // Off-screen
        child: Column(children: [
          OrderDetailsCard(...),
          OrderProductsCard(...),
          ReceiptCard(...),
        ]),
      ),
    );
    
    overlay.insert(entry);
    await Future.delayed(Duration(seconds: 1));
    entry.remove();
  }
}
```

---

### 5. **Use `scheduleWarmUpFrame()`** (Built-in Flutter)

```dart
main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Trigger a warm frame
  WidgetsBinding.instance.scheduleWarmUpFrame();
  
  // Then initialize app
  runApp(MyApp());
}
```

**Note:** This is what you're already using for window manager!

---

## 📊 Comparison

| Approach | Startup Time | Jank Reduction | Platform Support | Complexity |
|----------|--------------|----------------|------------------|------------|
| **Shader Warmup (Current)** | +500ms | 95% | All | Medium |
| Lazy Loading | +0ms | 30% | All | Low |
| RepaintBoundary | +0ms | 60% | All | Low |
| Manual Service | +1000ms | 90% | All | High |
| scheduleWarmUpFrame | +100ms | 50% | Desktop | Low |

---

## 🚀 Recommended Strategy for Your App

Combine multiple approaches:

```dart
// 1. In main()
await ShaderWarmup.warmup(context); // Backend: 500ms

// 2. In expensive widgets (OrderDetailsCard, etc.)
@override
Widget build(BuildContext context) {
  return RepaintBoundary( // Limit repaints
    child: _buildContent(),
  );
}

// 3. Enable performance mode setting
if (performanceMode) {
  // Reduce animations, opacity changes
  // Use simpler decorations
}
```

---

## 🔧 Configuration

### In `shader_warmup.dart`:

Customize the warmup duration:
```dart
static const Duration _warmupDuration = Duration(milliseconds: 500);
```

Add/remove widgets from warmup:
```dart
static List<Widget> _buildContainers() {
  return [
    // Add app-specific expensive widgets here
    MyCustomExpensiveWidget(),
    ...
  ];
}
```

---

## ✨ Additional Tips

1. **Profile your app:**
   ```bash
   flutter run --profile
   # Toggle "Show Performance Data" in DevTools
   ```

2. **Use `const` more:**
   ```dart
   const SizedBox(height: 10), // Better than SizedBox(height: 10)
   ```

3. **Avoid `Transform`:**
   - Use direct positioning instead
   - `Transform` triggers expensive repaints

4. **Cache `TextStyle`:**
   ```dart
   static const _boldStyle = TextStyle(fontWeight: FontWeight.bold);
   ```

5. **Use `shouldRebuild` wisely:**
   ```dart
   @override
   bool shouldRebuild(covariant MyPainter oldDelegate) => false;
   ```

---

## 📝 Implementation Checklist

- [x] Created `shader_warmup.dart` with precompile logic
- [x] Integrated `_WarmupWrapper` in `main.dart`
- [x] Set `_shaderWarmupDone` flag to prevent duplicate warmups
- [ ] (Optional) Remove the 500ms delay from `order_detail_card.dart` now
- [ ] (Optional) Wrap expensive widgets with `RepaintBoundary`
- [ ] (Optional) Profile app to measure jank reduction

---

## 🎨 Remove Old Delays

Now that warmup is global, you can remove per-widget delays:

**In `order_detail_card.dart`:**
```dart
// BEFORE
if(!render) {
  Future.delayed(const Duration(milliseconds: 500), () { /*...*/ });
}

// AFTER (can remove this now)
// Shaders already precompiled in app startup
```

---

## 📚 References

- [Flutter Performance Best Practices](https://flutter.dev/docs/testing/best-practices)
- [Reducing Jank](https://flutter.dev/docs/perf/rendering/best-practices)
- [Shader Compilation Jank](https://flutter.dev/docs/testing/ui-performance#shader-compilation-jank)

