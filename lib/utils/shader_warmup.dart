import 'package:flutter/material.dart';

/// Precompiles shaders and warms up the rendering pipeline.
/// Call this during app initialization to reduce first-frame jank.
class ShaderWarmup {
  static const Duration _warmupDuration = Duration(milliseconds: 1000);
  // Increased to 1000ms to allow all custom widgets to render

  /// Triggers shader warmup by rendering a series of test widgets off-screen.
  /// This forces Flutter to compile necessary shaders before the actual UI renders.
  static Future<void> warmup(BuildContext context) async {
    final overlay = Overlay.of(context);

    // Create a transparent overlay entry with test widgets
    final entry = OverlayEntry(
      builder: (_) => Positioned(
        bottom: -2000,
        left: -2000,
        width: 520,
        height: 800,
        child: SizedBox(
          width: 520,
          height: 800,
          // Render only the receipt card and the order details card with dummy data
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              _buildReceiptCard(),
              const SizedBox(height: 12),
              _buildOrderDetailsCard(),
            ],
          ),
        ),
      ),
    );

    overlay.insert(entry);

    // Let the widgets render and compile shaders (increased duration)
    await Future.delayed(_warmupDuration);

    // Remove the overlay entry
    entry.remove();
  }

  // /// Builds container widgets with various decorations
  // static List<Widget> _buildContainers() {
  //   return [
  //     Container(
  //       width: 100,
  //       height: 100,
  //       decoration: BoxDecoration(
  //         color: Colors.blue,
  //         borderRadius: BorderRadius.circular(10),
  //         boxShadow: [
  //           BoxShadow(
  //             color: Colors.grey.withAlpha(125),
  //             spreadRadius: 0.5,
  //             blurRadius: 3,
  //             offset: const Offset(0, 3),
  //           ),
  //         ],
  //       ),
  //     ),
  //     Container(
  //       width: 100,
  //       height: 100,
  //       decoration: BoxDecoration(
  //         color: Colors.red,
  //         border: Border.all(color: Colors.black, width: 2),
  //         borderRadius: BorderRadius.circular(15),
  //       ),
  //     ),
  //     Container(
  //       width: 100,
  //       height: 100,
  //       decoration: BoxDecoration(
  //         gradient: LinearGradient(
  //           colors: [Colors.blue, Colors.purple],
  //         ),
  //         borderRadius: BorderRadius.circular(10),
  //       ),
  //     ),
  //   ];
  // }
  //
  // /// Builds text widgets with various styles
  // static List<Widget> _buildTextWidgets() {
  //   return [
  //     const Text(
  //       'Warmup Text Bold',
  //       style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
  //     ),
  //     const Text(
  //       'Warmup Text Regular',
  //       style: TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
  //     ),
  //     const Text(
  //       'Warmup Text Semibold',
  //       style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
  //     ),
  //   ];
  // }
  //
  // /// Builds clipped and border-radius widgets
  // static List<Widget> _buildClippedWidgets() {
  //   return [
  //     ClipRRect(
  //       borderRadius: BorderRadius.circular(10),
  //       child: Container(
  //         width: 100,
  //         height: 100,
  //         color: Colors.green,
  //       ),
  //     ),
  //     ClipPath(
  //       clipper: _TriangleClipper(),
  //       child: Container(
  //         width: 100,
  //         height: 100,
  //         color: Colors.orange,
  //       ),
  //     ),
  //   ];
  // }
  //
  // /// Builds animated widgets
  // static List<Widget> _buildAnimatedWidgets() {
  //   return [
  //     _SimpleAnimatedWidget(),
  //     _ScaleAnimatedWidget(),
  //   ];
  // }
  //
  // /// Builds Material-specific widgets
  // static List<Widget> _buildMaterialWidgets() {
  //   return [
  //     // Material cards
  //     Card(
  //       child: Container(
  //         width: 100,
  //         height: 50,
  //         color: Colors.blue.shade100,
  //       ),
  //     ),
  //     // ElevatedButton
  //     ElevatedButton(
  //       onPressed: () {},
  //       style: ElevatedButton.styleFrom(
  //         backgroundColor: Colors.blue,
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(20),
  //         ),
  //       ),
  //       child: const Text('Button'),
  //     ),
  //     // Material with custom shape
  //     Material(
  //       color: Colors.white,
  //       child: Container(
  //         width: 80,
  //         height: 80,
  //         decoration: BoxDecoration(
  //           border: Border.all(color: Colors.blue, width: 2),
  //           borderRadius: BorderRadius.circular(10),
  //         ),
  //       ),
  //     ),
  //   ];
  // }
  //
  // /// Builds Cupertino-specific widgets (for CupertinoSlidingSegmentedControl, etc.)
  // static List<Widget> _buildCupertinoWidgets() {
  //   return [
  //     // CupertinoSlidingSegmentedControl warmup
  //     Container(
  //       width: 300,
  //       height: 40,
  //       color: Colors.white,
  //       child: CupertinoSlidingSegmentedControl<int>(
  //         backgroundColor: Colors.white,
  //         thumbColor: Colors.blue,
  //         groupValue: 0,
  //         children: const {
  //           0: Padding(
  //             padding: EdgeInsets.symmetric(horizontal: 20),
  //             child: Text('Option 1'),
  //           ),
  //           1: Padding(
  //             padding: EdgeInsets.symmetric(horizontal: 20),
  //             child: Text('Option 2'),
  //           ),
  //           2: Padding(
  //             padding: EdgeInsets.symmetric(horizontal: 20),
  //             child: Text('Option 3'),
  //           ),
  //         },
  //         onValueChanged: (_) {},
  //       ),
  //     ),
  //     // CupertinoButton
  //     CupertinoButton(
  //       onPressed: () {},
  //       child: const Text('Cupertino Button'),
  //     ),
  //     // CupertinoButton.filled
  //     CupertinoButton.filled(
  //       onPressed: () {},
  //       child: const Text('Filled Button'),
  //     ),
  //   ];
  // }
  //
  // /// Builds form widgets (TextField, OutlineInputBorder)
  // static List<Widget> _buildFormWidgets() {
  //   return [
  //     // Wrap in Material to provide required context with proper constraints
  //     Container(
  //       width: 320,
  //       child: Material(
  //         child: Column(
  //           children: [
  //             // TextField with OutlineInputBorder (used throughout your app)
  //             TextField(
  //               decoration: InputDecoration(
  //                 labelText: 'Test Input',
  //                 hintText: 'Hint text',
  //                 border: OutlineInputBorder(
  //                   borderRadius: BorderRadius.circular(10),
  //                 ),
  //                 enabledBorder: OutlineInputBorder(
  //                   borderRadius: BorderRadius.circular(10),
  //                   borderSide: const BorderSide(color: Colors.grey, width: 2),
  //                 ),
  //                 focusedBorder: OutlineInputBorder(
  //                   borderRadius: BorderRadius.circular(10),
  //                   borderSide: const BorderSide(color: Colors.blue, width: 2),
  //                 ),
  //               ),
  //             ),
  //             const SizedBox(height: 8),
  //             // TextField with prefix/suffix
  //             TextField(
  //               decoration: InputDecoration(
  //                 prefixIcon: const Icon(Icons.search),
  //                 suffixIcon: const Icon(Icons.close),
  //                 border: OutlineInputBorder(
  //                   borderRadius: BorderRadius.circular(10),
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   ];
  // }
  //
  // /// Builds button and icon widgets
  // static List<Widget> _buildButtonWidgets() {
  //   return [
  //     Container(
  //       width: 200,
  //       child: Material(
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             // IconButton
  //             IconButton(
  //               icon: const Icon(Icons.add),
  //               onPressed: () {},
  //               tooltip: 'Add',
  //             ),
  //             // IconButton with custom color
  //             IconButton(
  //               icon: const Icon(Icons.delete),
  //               onPressed: () {},
  //               color: Colors.red,
  //             ),
  //             // FloatingActionButton
  //             FloatingActionButton(
  //               onPressed: () {},
  //               child: const Icon(Icons.add),
  //             ),
  //             // InkWell
  //             InkWell(
  //               onTap: () {},
  //               child: Container(
  //                 width: 100,
  //                 height: 50,
  //                 decoration: BoxDecoration(
  //                   color: Colors.blue.shade100,
  //                   borderRadius: BorderRadius.circular(8),
  //                 ),
  //                 child: const Center(child: Text('Ink Well')),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   ];
  // }
  //
  // /// Builds scrollable widgets (GridView, ListView patterns)
  // static List<Widget> _buildScrollableWidgets() {
  //   return [
  //     Container(
  //       width: 300,
  //       child: Material(
  //         child: Column(
  //           children: [
  //             // Single GridView cell pattern (used in AdderRemoverValue)
  //             Container(
  //               width: 80,
  //               height: 50,
  //               decoration: BoxDecoration(
  //                 color: Colors.blue.shade50,
  //                 border: Border.all(color: Colors.blue),
  //                 borderRadius: BorderRadius.circular(8),
  //               ),
  //               child: const Center(child: Text('Grid Item')),
  //             ),
  //             // List tile pattern
  //             ListTile(
  //               title: const Text('List Item'),
  //               subtitle: const Text('Subtitle'),
  //               trailing: const Icon(Icons.arrow_forward),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   ];
  // }

  /// Builds a simple receipt card with dummy data
  static Widget _buildReceiptCard() {
    return SizedBox(
      width: 480,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('RECEIPT', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Mughal Auto Industries', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Date: 2026-05-06'),
                  Text('Invoice: #INV-1001'),
                ],
              ),
              const Divider(height: 20),
              // Items
              _receiptItemRow('Spark Plug', 2, 12.50),
              _receiptItemRow('Oil Filter', 1, 8.75),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Subtotal'),
                  Text('\$33.75'),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Tax'),
                  Text('\$3.37'),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('\$37.12', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Payment: Card •••• 4242'),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a compact order details card with dummy data
  static Widget _buildOrderDetailsCard() {
    return SizedBox(
      width: 480,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Order Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: const [
                  Expanded(child: Text('Order ID: ORD-2002')),
                  Text('Status: Delivered', style: TextStyle(color: Colors.green)),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Customer: John Doe'),
              const SizedBox(height: 4),
              const Text('Address: 123 Main St, Lahore'),
              const Divider(height: 18),
              // Small product list
              _orderDetailRow('Brake Pads', 4, 9.99),
              _orderDetailRow('Air Filter', 1, 15.00),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Items total'),
                  Text('\$55.96'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper for receipt item row
  static Widget _receiptItemRow(String name, int qty, double price) {
    final lineTotal = (qty * price).toStringAsFixed(2);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(child: Text(name)),
          Text('x$qty', style: const TextStyle(color: Colors.grey)),
          const SizedBox(width: 12),
          Text('\$$lineTotal'),
        ],
      ),
    );
  }

  // Helper for order details row
  static Widget _orderDetailRow(String name, int qty, double price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(child: Text(name)),
          Text('x$qty', style: const TextStyle(color: Colors.grey)),
          const SizedBox(width: 12),
          Text('\$${(qty * price).toStringAsFixed(2)}'),
        ],
      ),
    );
  }
}

/// Simple animated opacity widget for warmup
class _SimpleAnimatedWidget extends StatefulWidget {
  @override
  State<_SimpleAnimatedWidget> createState() => _SimpleAnimatedWidgetState();
}

class _SimpleAnimatedWidgetState extends State<_SimpleAnimatedWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 50,
        height: 50,
        color: Colors.blue,
      ),
    );
  }
}

/// Scale animated widget for warmup
class _ScaleAnimatedWidget extends StatefulWidget {
  @override
  State<_ScaleAnimatedWidget> createState() => _ScaleAnimatedWidgetState();
}

class _ScaleAnimatedWidgetState extends State<_ScaleAnimatedWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _controller,
      child: Container(
        width: 50,
        height: 50,
        color: Colors.red,
      ),
    );
  }
}

/// Custom triangle clipper
// class _TriangleClipper extends CustomClipper<Path> {
//   @override
//   Path getClip(Size size) {
//     final path = Path();
//     path.moveTo(size.width / 2, 0);
//     path.lineTo(size.width, size.height);
//     path.lineTo(0, size.height);
//     path.close();
//     return path;
//   }
//
//   @override
//   bool shouldReclip(CustomClipper<Path> oldClipper) => false;
// }

/// Alternative: Configure shader warmup with CustomPaint
class CustomShaderWarmup extends CustomPaint {
  CustomShaderWarmup({super.key})
      : super(
          painter: _WarmupPainter(),
        );
}

class _WarmupPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Draw various shapes to trigger shader compilation
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    // Draw rectangles with various strokes
    canvas.drawRect(Rect.fromLTWH(0, 0, 100, 100), paint);
    canvas.drawRect(Rect.fromLTWH(10, 10, 80, 80),
        paint..style = PaintingStyle.stroke..strokeWidth = 2);

    // Draw circles
    canvas.drawCircle(const Offset(50, 50), 30, paint..style = PaintingStyle.fill);

    // Draw paths with curves
    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(50, 100, 100, 0)
      ..lineTo(100, 100)
      ..close();
    canvas.drawPath(path, paint);

    // Draw with gradient
    final gradientPaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.red, Colors.blue],
      ).createShader(Rect.fromLTWH(0, 0, 100, 100));
    canvas.drawRect(Rect.fromLTWH(0, 0, 100, 100), gradientPaint);
  }

  @override
  bool shouldRepaint(_WarmupPainter oldDelegate) => false;
}

