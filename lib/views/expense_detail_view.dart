import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/expense.dart';
import '../providers/expense_store.dart';
import 'add_expense_view.dart';
import 'zoomable_image_view.dart';

class ExpenseDetailView extends StatefulWidget {
  final Expense expense;

  const ExpenseDetailView({
    Key? key,
    required this.expense,
  }) : super(key: key);

  @override
  State<ExpenseDetailView> createState() => _ExpenseDetailViewState();
}

class _ExpenseDetailViewState extends State<ExpenseDetailView> {
  Uint8List? _imageData;

  @override
  void initState() {
    super.initState();
    _loadReceiptImage();
  }

  Future<void> _loadReceiptImage() async {
    final store = Provider.of<ExpenseStore>(context, listen: false);
    final imageData = await store.getReceiptImage(widget.expense.id);
    if (imageData != null) {
      setState(() {
        _imageData = imageData;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<ExpenseStore>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Details'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddExpenseView(
                    expense: widget.expense,
                    isEditing: true,
                    onClose: () {
                      Navigator.pop(context); // Close AddExpenseView
                      Navigator.pop(context); // Close ExpenseDetailView
                    },
                  ),
                ),
              );
            },
            child: const Text('Edit'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Expense Details Card
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.expense.category.emoji,
                          style: const TextStyle(fontSize: 40),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.expense.name,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                widget.expense.category.name,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Amount and Date Card
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Amount'),
                        Text(
                          '${store.profile.currency.symbol}${widget.expense.amount.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Date'),
                        Text(
                          _formatDate(widget.expense.date),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Receipt Image
            if (_imageData != null) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ZoomableImageView(imageData: _imageData!),
                    ),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.all(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      _imageData!,
                      fit: BoxFit.cover,
                      height: 300,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

// Create a separate widget for the zoomable image view
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
      ),
      body: InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: Center(
          child: Image.memory(imageData),
        ),
      ),
    );
  }
} 