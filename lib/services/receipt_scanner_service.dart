import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

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
      final text = recognizedText.text;
      final lines = text.split('\n');

      print('\n-------- SCANNED TEXT --------');
      print(text);
      print('----------------------------\n');

      // Store name extraction
      String? name;
      for (int i = 0; i < lines.length - 1; i++) {
        if (_isStreetAddress(lines[i])) {
          if (i > 0 && _isValidStoreName(lines[i - 1])) {
            name = _cleanStoreName(lines[i - 1]);
            print('Found store name before address: $name');
            print('Address line: ${lines[i]}');
          } else {
            name = _cleanStoreName(lines[i]);
            print('Using address as store name: $name');
          }
          break;
        }
      }

      if (name == null) {
        for (final line in lines) {
          if (_isValidStoreName(line)) {
            name = _cleanStoreName(line);
            print('Found store name from first valid line: $name');
            break;
          }
        }
      }

      // Amount extraction - find total by validating differences
      double? amount;
      print('\nLooking for dollar amounts...');

      // Collect all dollar amounts
      List<double> allAmounts = [];
      for (final line in lines) {
        final amounts = RegExp(r'\$\s*(\d+(?:\.\d{2})?)')
            .allMatches(line)
            .map((match) => double.tryParse(match.group(1) ?? '') ?? 0.0)
            .where((value) => value > 0.0);
        allAmounts.addAll(amounts);
      }

      // Sort amounts in descending order
      allAmounts.sort((a, b) => b.compareTo(a));

      print('All dollar amounts found (descending):');
      for (var amt in allAmounts) {
        print('\$$amt');
      }

      if (allAmounts.length >= 2) {
        final largest = allAmounts[0];
        final secondLargest = allAmounts[1];
        final difference = largest - secondLargest;
        
        print('\nTesting largest amount: \$$largest');
        print('Second largest: \$$secondLargest');
        print('Difference: \$$difference');

        // Check if difference matches any other amount
        if (allAmounts.any((amt) => 
            amt != largest && 
            amt != secondLargest && 
            (amt - difference).abs() < 0.01)) {
          amount = largest;
          print('Found matching difference. Using largest amount: \$$amount');
        } else {
          // Try with second largest as potential total
          for (int i = 2; i < allAmounts.length; i++) {
            final difference2 = secondLargest - allAmounts[i];
            print('\nTrying second largest: \$$secondLargest');
            print('Testing against: \$${allAmounts[i]}');
            print('Difference: \$$difference2');
            
            if (allAmounts.any((amt) => 
                amt != secondLargest && 
                amt != allAmounts[i] && 
                (amt - difference2).abs() < 0.01)) {
              amount = secondLargest;
              print('Found matching difference using second largest. Using: \$$amount');
              break;
            }
          }
        }
      }

      if (amount == null && allAmounts.isNotEmpty) {
        print('\nNo matching differences found. Defaulting to largest amount.');
        amount = allAmounts[0];
      }

      // Extract date
      DateTime? date;
      print('\nLooking for date...');
      final datePatterns = [
        r'\b\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\b',  // MM/DD/YYYY or MM-DD-YYYY
        r'\b[A-Za-z]+\s+\d{1,2},\s+\d{4}\b',    // Month DD, YYYY
      ];

      for (final line in lines) {
        for (final pattern in datePatterns) {
          final match = RegExp(pattern).firstMatch(line);
          if (match != null) {
            final dateStr = match.group(0)!;
            date = _parseDate(dateStr);
            if (date != null) {
              print('Found date: ${DateFormat('yyyy-MM-dd').format(date)}');
              break;
            }
          }
        }
        if (date != null) break;
      }

      if (date == null) {
        print('No date found, using current date');
        date = DateTime.now();
      }

      print('\n-------- SCAN RESULTS --------');
      print('Store Name: ${name ?? "Not found"}');
      print('Amount: ${amount != null ? "\$$amount" : "Not found"}');
      print('----------------------------\n');

      final imageBytes = await image.readAsBytes();

      return {
        'amount': amount,
        'name': name,
        'date': date,
        'fullText': text,
        'imageData': imageBytes,
      };
    } catch (e) {
      print('Error scanning receipt: $e');
      return null;
    } finally {
      textRecognizer.close();
    }
  }

  bool _isValidStoreName(String line) {
    final trimmed = line.trim();
    
    // Basic validation
    if (trimmed.length < 2) return false;
    if (RegExp(r'^\d+$').hasMatch(trimmed)) return false;
    if (RegExp(r'^\d{1,2}[/-]\d{1,2}[/-]\d{2,4}$').hasMatch(trimmed)) return false;
    
    // Exclude common receipt words and payment-related terms
    final excludedTerms = RegExp(
      r'^(TOTAL|SUBTOTAL|TAX|TIP|CASH|CREDIT|DEBIT|PAYMENT|BALANCE|DUE|PAID|RECEIPT|ORDER|INVOICE|MERCHANT|CUSTOMER|SERVER|TABLE|GUEST|CHECK|TERMINAL|TRANSACTION)$',
      caseSensitive: false,
    );
    
    // Exclude lines that are just times
    if (RegExp(r'^\d{1,2}:\d{2}(\s?[AaPp][Mm])?$').hasMatch(trimmed)) return false;
    
    // Exclude lines that are just amounts
    if (RegExp(r'^\$?\d+\.\d{2}$').hasMatch(trimmed)) return false;
    
    // Check if the line contains excluded terms
    if (excludedTerms.hasMatch(trimmed)) return false;
    
    return true;
  }

  String _cleanStoreName(String name) {
    var cleaned = name.trim()
        // Remove common receipt header words
        .replaceAll(RegExp(r'(RECEIPT|INVOICE|ORDER|#\d+)'), '')
        // Remove store numbers/IDs
        .replaceAll(RegExp(r'STORE\s*#?\d+'), '')
        // Remove multiple spaces
        .replaceAll(RegExp(r'\s+'), ' ')
        // Remove any trailing numbers or special characters
        .replaceAll(RegExp(r'[#\d]+$'), '')
        .trim();

    // Convert to Title Case but preserve common abbreviations
    cleaned = cleaned.split(' ').map((word) {
      // Keep common abbreviations in uppercase
      if (RegExp(r'^(LLC|INC|LTD|CO|CORP)$', caseSensitive: false).hasMatch(word)) {
        return word.toUpperCase();
      }
      // Convert other words to title case
      return word.isNotEmpty 
          ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
          : '';
    }).join(' ');

    return cleaned;
  }

  DateTime? _parseDate(String dateStr) {
    // Try different date formats
    final formats = [
      'MM/dd/yyyy',
      'MM-dd-yyyy',
      'MMMM d, yyyy',
      'MM/dd/yy',
      'yyyy-MM-dd',
    ];

    // Normalize 2-digit years to 4-digit years
    if (RegExp(r'\d{1,2}/\d{1,2}/\d{2}$').hasMatch(dateStr)) {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        final year = int.tryParse(parts[2]);
        if (year != null && year < 100) {
          dateStr = '${parts[0]}/${parts[1]}/20${parts[2]}';
        }
      }
    }

    for (final format in formats) {
      try {
        return DateFormat(format).parse(dateStr);
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  bool _isStreetAddress(String line) {
    // Common street suffixes
    final streetSuffixes = RegExp(
      r'\b(ST|STREET|AVE|AVENUE|BLVD|BOULEVARD|RD|ROAD|LN|LANE|DR|DRIVE|CT|COURT|CIRCLE|CIR|WAY|PL|PLACE|SQ|SQUARE)\b',
      caseSensitive: false,
    );

    // Street number patterns
    final streetNumber = RegExp(r'\b\d+\s');

    // Check for common address patterns
    return (streetSuffixes.hasMatch(line.toUpperCase()) && streetNumber.hasMatch(line)) ||
           (line.contains(',') && RegExp(r'\b[A-Z]{2}\b').hasMatch(line.toUpperCase()) && RegExp(r'\d{5}').hasMatch(line));
  }
} 