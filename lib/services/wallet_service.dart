import 'package:flutter/foundation.dart';

/// In-memory app-wide saldo/balance. There is no wallet API yet, so this
/// lets features like top up and cafe checkout read/deduct a shared balance.
class WalletService extends ChangeNotifier {
  WalletService._();

  static final WalletService instance = WalletService._();

  int _balance = 350000;

  int get balance => _balance;

  bool hasEnoughBalance(int amount) => _balance >= amount;

  bool deduct(int amount) {
    if (!hasEnoughBalance(amount)) return false;
    _balance -= amount;
    notifyListeners();
    return true;
  }

  void topUp(int amount) {
    _balance += amount;
    notifyListeners();
  }
}
