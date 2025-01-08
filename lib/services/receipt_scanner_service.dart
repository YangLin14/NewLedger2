import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class ReceiptScannerService {
  final textRecognizer = TextRecognizer();
  final imagePicker = ImagePicker();

  Future<Map<String, dynamic>?> scanReceipt() async {
    try {
      final XFile? image = await imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (image == null) return null;

      final inputImage = InputImage.fromFile(File(image.path));
      final recognizedText = await textRecognizer.processImage(inputImage);

      // Extract amount (looking for currency symbols and numbers)
      final amountRegex = RegExp(r'(?:[\$€£¥])\s*(\d+(?:\.\d{2})?)');
      final amountMatch = amountRegex.firstMatch(recognizedText.text);
      double? amount = amountMatch != null 
          ? double.tryParse(amountMatch.group(1) ?? '')
          : null;

      // Extract potential expense name (first line or prominent text)
      String? name;
      if (recognizedText.blocks.isNotEmpty) {
        name = recognizedText.blocks.first.text.split('\n').first;
      }

      return {
        'amount': amount,
        'name': name,
        'fullText': recognizedText.text,
      };
    } catch (e) {
      print('Error scanning receipt: $e');
      return null;
    } finally {
      textRecognizer.close();
    }
  }
} 