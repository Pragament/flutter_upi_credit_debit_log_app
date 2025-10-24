import 'package:flutter_template/tag/tag_model.dart';
import 'package:flutter_template/upi/model/pay.dart';

class HomeStateModel {
  List<Accounts> accounts;
  List<Product> products;
  List<Tag> selectedTags;

  HomeStateModel({
    required this.accounts,
    required this.products,
    required this.selectedTags,
  });

  HomeStateModel copyWith({
    List<Accounts>? accounts,
    List<Product>? products,
    List<Tag>? selectedTags,
  }) =>
      HomeStateModel(
        accounts: accounts ?? this.accounts,
        products: products ?? this.products,
        selectedTags: selectedTags ?? this.selectedTags,
      );
}
