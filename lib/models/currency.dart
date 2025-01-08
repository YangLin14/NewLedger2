enum Currency {
  USD('USD', '\$', 'US Dollar', 1.0),
  TWD('TWD', 'NT\$', 'Taiwan Dollar', 31.0),
  EUR('EUR', '€', 'Euro', 0.91),
  JPY('JPY', '¥', 'Japanese Yen', 148.0),
  GBP('GBP', '£', 'British Pound', 0.79);

  final String name;
  final String symbol;
  final String fullName;
  final double fallbackRate;

  const Currency(this.name, this.symbol, this.fullName, this.fallbackRate);
} 