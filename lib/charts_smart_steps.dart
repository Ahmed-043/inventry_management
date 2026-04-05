
import 'dart:math' as Math;


double niceStep(double range, int maxTicks) {
  if (range == 0) return 1; // fallback

  // Exact step to get the requested number of intervals
  double step = range / maxTicks;

  // Round step to a "nice" number (1, 2, 5, 10 × magnitude)
  final magnitude = Math.pow(10, step.log10().floor()).toDouble();
  double residual = step / magnitude;

  if (residual <= 1)
    residual = 1;
  else if (residual <= 2)
    residual = 2;
  else if (residual <= 5)
    residual = 5;
  else
    residual = 10;
  return magnitude * residual;
}

String formatAxis(double value) {
  final v = value.abs();
  if (v >= 1e12)
    return '${(v / 1e12).toStringAsFixed(v % 1e12 == 0 ? 0 : 1)}T';
  if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(v % 1e9 == 0 ? 0 : 1)}B';
  if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(v % 1e6 == 0 ? 0 : 1)}M';
  if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(v % 1e3 == 0 ? 0 : 1)}K';
  return v.toStringAsFixed(0);
}

extension LogExtension on double {
  double log10() => Math.log(this) / Math.ln10;
}