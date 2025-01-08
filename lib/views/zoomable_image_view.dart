import 'dart:typed_data';
import 'package:flutter/material.dart';

class ZoomableImageView extends StatelessWidget {
  final Uint8List imageData;

  const ZoomableImageView({
    Key? key,
    required this.imageData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: Center(
          child: Image.memory(
            imageData,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
} 