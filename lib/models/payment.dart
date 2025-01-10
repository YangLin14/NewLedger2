class Payment {
  final String payerId;
  final double amount;
  Map<String, double> splits;  // Make splits mutable

  Payment({
    required this.payerId,
    required this.amount,
    required this.splits,
  });

  // Add method to recalculate splits
  void recalculateEqualSplits(List<String> collaborators) {
    final splitAmount = amount / (collaborators.length + 1); // +1 for the payer
    splits = {
      'me': splitAmount,
      ...Map.fromEntries(
        collaborators.map((id) => MapEntry(id, splitAmount))
      ),
    };
  }

  // Add method to check if splits are equal
  bool get isEqualSplit {
    if (splits.isEmpty) return true;
    final firstAmount = splits.values.first;
    return splits.values.every((amount) => amount == firstAmount);
  }

  Map<String, dynamic> toJson() => {
    'payerId': payerId,
    'amount': amount,
    'splits': splits,
  };

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
    payerId: json['payerId'],
    amount: json['amount'],
    splits: Map<String, double>.from(json['splits']),
  );

  // Create an equally split payment
  factory Payment.equalSplit(String payerId, double amount, List<String> collaborators) {
    final splitAmount = amount / (collaborators.length + 1); // +1 for the payer
    return Payment(
      payerId: payerId,
      amount: amount,
      splits: Map.fromEntries(
        collaborators.map((id) => MapEntry(id, splitAmount))
      ),
    );
  }
} 