import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Define a class to hold form data
class FormData {
  String _merchantName;
  String _upiId;
  String _currency;
  Color _selectedColor;
  bool _createShortcut;

  FormData({
    String merchantName = '',
    String upiId = '',
    String currency = 'INR',
    Color selectedColor = Colors.blue,
    bool createShortcut = false,
  })  : _merchantName = merchantName,
        _upiId = upiId,
        _currency = currency,
        _selectedColor = selectedColor,
        _createShortcut = createShortcut;

  // Getter methods for each field
  String get merchantName => _merchantName;
  String get upiId => _upiId;
  String get currency => _currency;
  Color get selectedColor => _selectedColor;
  bool get createShortcut => _createShortcut;

  // Implementing the copyWith method
  FormData copyWith({
    String? merchantName,
    String? upiId,
    String? currency,
    Color? selectedColor,
    bool? createShortcut,
  }) {
    return FormData(
      merchantName: merchantName ?? this.merchantName,
      upiId: upiId ?? this.upiId,
      currency: currency ?? this.currency,
      selectedColor: selectedColor ?? this.selectedColor,
      createShortcut: createShortcut ?? this.createShortcut,
    );
  }
}

// Define a StateNotifier for managing form data
class FormDataNotifier extends StateNotifier<FormData> {
  FormDataNotifier() : super(FormData());

  void updateMerchantName(String name) {
    state = state.copyWith(merchantName: name);
  }

  void updateUpiId(String id) {
    state = state.copyWith(upiId: id);
  }

  void updateCurrency(String currency) {
    state = state.copyWith(currency: currency);
  }

  void updateSelectedColor(Color color) {
    state = state.copyWith(selectedColor: color);
  }

  void toggleCreateShortcut() {
    state = state.copyWith(createShortcut: !state.createShortcut);
  }

  Color getSelectedColor() {
    return state._selectedColor;
  }
  void reset() {
    state = FormData(); // Reset to default values
  }
}

// Provider for accessing FormDataNotifier
final formDataProvider = StateNotifierProvider<FormDataNotifier, FormData>(
      (ref) => FormDataNotifier(),
);
