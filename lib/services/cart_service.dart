import 'package:flutter/foundation.dart';

class CartItem {
  final String name;
  final int price;
  int quantity;

  CartItem({required this.name, required this.price, this.quantity = 1});

  int get subtotal => price * quantity;
}

/// App-wide cart used by the cafe menu: add items, review them, then check
/// out against [WalletService].
class CartService extends ChangeNotifier {
  CartService._();

  static final CartService instance = CartService._();

  static const List<String> branches = ["P.Aim", "Dansen"];

  final List<CartItem> _items = [];

  String tableNumber = "";
  String? branch;

  List<CartItem> get items => List.unmodifiable(_items);

  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);

  int get totalPrice => _items.fold(0, (sum, item) => sum + item.subtotal);

  bool get isEmpty => _items.isEmpty;

  void setTableNumber(String value) {
    tableNumber = value;
    notifyListeners();
  }

  void setBranch(String value) {
    branch = value;
    notifyListeners();
  }

  CartItem? _find(String name) {
    for (final item in _items) {
      if (item.name == name) return item;
    }
    return null;
  }

  void addItem(String name, int price) {
    final existing = _find(name);
    if (existing != null) {
      existing.quantity++;
    } else {
      _items.add(CartItem(name: name, price: price));
    }
    notifyListeners();
  }

  void incrementItem(String name) {
    final existing = _find(name);
    if (existing == null) return;
    existing.quantity++;
    notifyListeners();
  }

  void decrementItem(String name) {
    final existing = _find(name);
    if (existing == null) return;
    if (existing.quantity <= 1) {
      _items.remove(existing);
    } else {
      existing.quantity--;
    }
    notifyListeners();
  }

  void removeItem(String name) {
    _items.removeWhere((i) => i.name == name);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    tableNumber = "";
    branch = null;
    notifyListeners();
  }
}
