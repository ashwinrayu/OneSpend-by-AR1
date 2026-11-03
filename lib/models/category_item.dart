import 'package:flutter/material.dart';

class CategoryItem {
  final String id;
  final String name;
  final String iconName;
  final String hexColor;
  final bool isExpense;

  const CategoryItem({
    required this.id,
    required this.name,
    required this.iconName,
    required this.hexColor,
    this.isExpense = true,
  });

  Color get color {
    final hexCode = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }

  IconData get iconData {
    switch (iconName) {
      case 'fastfood':
      case 'food':
        return Icons.fastfood_rounded;
      case 'receipt':
      case 'bills':
        return Icons.receipt_long_rounded;
      case 'shopping_bag':
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'directions_car':
      case 'travel':
        return Icons.directions_car_rounded;
      case 'movie':
      case 'entertainment':
        return Icons.movie_filter_rounded;
      case 'health':
      case 'medical_services':
        return Icons.medical_services_rounded;
      case 'attach_money':
      case 'salary':
        return Icons.payments_rounded;
      case 'category':
      default:
        return Icons.category_rounded;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconName': iconName,
      'hexColor': hexColor,
      'isExpense': isExpense ? 1 : 0,
    };
  }

  factory CategoryItem.fromMap(Map<String, dynamic> map) {
    return CategoryItem(
      id: map['id'] as String,
      name: map['name'] as String,
      iconName: map['iconName'] as String,
      hexColor: map['hexColor'] as String,
      isExpense: (map['isExpense'] as int?) == 1,
    );
  }

  CategoryItem copyWith({
    String? id,
    String? name,
    String? iconName,
    String? hexColor,
    bool? isExpense,
  }) {
    return CategoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      hexColor: hexColor ?? this.hexColor,
      isExpense: isExpense ?? this.isExpense,
    );
  }
}

