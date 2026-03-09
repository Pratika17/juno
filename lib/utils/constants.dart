import 'package:flutter/material.dart';

// App Colors
class AppColors {
  static const Color primary = Color(0xFF2196F3);
  static const Color primaryVariant = Color(0xFF1976D2);
  static const Color secondary = Color(0xFFFF9800);
  static const Color secondaryVariant = Color(0xFFF57C00);
  static const Color background = Color(0xFFF5F5F5);
  static const Color error = Color(0xFFB00020);
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF757575);
}

// Text Styles
class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyText = TextStyle(
    fontSize: 16,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyTextSecondary = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
  );
}

// Enums
enum ItemCategory { idCard, phone, wallet, books, electronics, keys, other }

enum ItemType { lost, found }

enum ItemStatus { active, recovered, returned }
