## 🎯 Optional Optimization: Remove Per-Widget Delays

Now that shader warmup happens globally at app startup, you can remove the 500ms delays from individual widgets.

### Before (old approach in `order_detail_card.dart`):
```dart
if(!render) {
  Future.delayed(const Duration(milliseconds: 500), () {
    if (mounted) {
      setState(() {
        render = true;
      });
    }
  });
}
```

### After (with global warmup):
```dart
// Warmup already done at app startup
// Can render immediately
bool render = true; // Just set to true
```

---

## ✅ Migration Steps

1. **Update `order_detail_card.dart`:**
   ```dart
   // Remove the oldrendering delay logic
   // Simplify to just use a flag or remove the render check entirely
   
   // OPTION A: Just set render=true (simpler)
   @override
   Widget build(BuildContext context) {
     return Container(...);
     // No conditional rendering needed
   }
   
   // OPTION B: Keep flag but don't delay (still works)
   bool render = true;
   @override
   Widget build(BuildContext context) {
     return render ? Column(...) : SizedBox(height: 466);
   }
   ```

2. **Apply to all widgets with similar delays:**
   - Search for `Future.delayed` in order-related widgets
   - Verify they're rendering delays
   - Remove them if they use the same pattern

3. **Test on different devices:**
   - Low-end device: Run `flutter run --profile`
   - High-end device: Should see ~0ms first-frame jank

---

## 📊 Expected Improvement

| Metric | Before | After |
|--------|--------|-------|
| First-frame delay | 500ms | ~0ms per widget |
| Global app delay | +500ms warmup + individual delays | +500ms warmup only |
| Jank on complex pages | High | Low |
| User experience | Wait for SplashScreen, then jank | Smooth transition |

---

## 🧪 How to Test

```bash
# 1. Build and run in profile mode
flutter run --profile

# 2. In Flutter DevTools, check "Show Performance Data" (top-right)
# Look for:
# - First frame time
# - Frame rate drops

# 3. Before/After comparison
# BEFORE: See jank spike when OrderDetailsCard first renders
# AFTER: Smooth 60fps throughout
```

---

## 📝 Recommended Actions

- [x] Global shader warmup implemented
- [ ] (Optional) Remove 500ms delay from `order_detail_card.dart`
- [ ] (Optional) Remove 500ms delay from other widgets
- [ ] Test on target devices
- [ ] Profile and measure jank reduction
- [ ] Document in release notes: "Improved first-frame performance with shader precompilation"

