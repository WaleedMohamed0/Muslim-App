/// Pure calculation rules for the annual money zakat estimate.
enum NisabStandard { gold, silver }

class ZakatInputs {
  const ZakatInputs({
    required this.cash,
    required this.goldGrams,
    required this.goldPrice,
    required this.silverGrams,
    required this.silverPrice,
    required this.investments,
    required this.receivables,
    required this.liabilities,
    required this.nisabStandard,
    required this.hawlComplete,
  });

  final double cash, goldGrams, goldPrice, silverGrams, silverPrice;
  final double investments, receivables, liabilities;
  final NisabStandard nisabStandard;
  final bool hawlComplete;
}

class ZakatResult {
  const ZakatResult({
    required this.totalAssets,
    required this.liabilities,
    required this.netWealth,
    required this.nisabValue,
    required this.reachedNisab,
    required this.zakatDue,
  });

  final double totalAssets, liabilities, netWealth, nisabValue, zakatDue;
  final bool reachedNisab;
  bool get isDue => reachedNisab && zakatDue > 0;
}

ZakatResult calculateZakat(ZakatInputs input) {
  final goldValue = input.goldGrams * input.goldPrice;
  final silverValue = input.silverGrams * input.silverPrice;
  final assets = input.cash + goldValue + silverValue + input.investments + input.receivables;
  final net = (assets - input.liabilities).clamp(0.0, double.infinity);
  final nisab = input.nisabStandard == NisabStandard.gold
      ? 85 * input.goldPrice
      : 595 * input.silverPrice;
  final reached = nisab > 0 && net >= nisab;
  return ZakatResult(
    totalAssets: assets,
    liabilities: input.liabilities,
    netWealth: net,
    nisabValue: nisab,
    reachedNisab: reached,
    zakatDue: reached && input.hawlComplete ? net * .025 : 0,
  );
}
