import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/expense.dart';
import '../providers/expense_store.dart';
import 'add_expense_view.dart';
import 'zoomable_image_view.dart';
import 'package:intl/intl.dart';

class ExpenseDetailView extends StatelessWidget {
  final Expense expense;

  const ExpenseDetailView({
    Key? key,
    required this.expense,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<ExpenseStore>(context);
    final receiptImage = expense.receiptImageId != null 
        ? store.getReceiptImage(expense.receiptImageId)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (context) => FractionallySizedBox(
                  heightFactor: 0.92,
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: AddExpenseView(
                      expense: expense,
                      isEditing: true,
                      onClose: () => Navigator.pop(context),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Expense Details Card
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          expense.category.emoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          expense.category.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${store.profile.currency.symbol}${expense.amount.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('EEEE, MMMM d, y').format(expense.date),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),

            // Receipt Image Section
            if (receiptImage != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Receipt',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                margin: const EdgeInsets.all(16),
                child: InkWell(
                  onTap: () {
                    // Show full screen receipt
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Scaffold(
                          appBar: AppBar(
                            title: const Text('Receipt'),
                          ),
                          body: Center(
                            child: InteractiveViewer(
                              minScale: 0.5,
                              maxScale: 4.0,
                              child: Image.memory(receiptImage),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      AspectRatio(
                        aspectRatio: 2/3,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            receiptImage,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Tap to view full receipt'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
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