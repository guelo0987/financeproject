import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

// ── Asset Category ──────────────────────────────

enum AssetCategory {
  cash('Cash', '💵', AppColors.categoryCash, Icons.account_balance_wallet),
  investments('Inversiones', '📈', AppColors.categoryInvestments, Icons.trending_up),
  crypto('Crypto', '₿', AppColors.categoryCrypto, Icons.currency_bitcoin),
  realEstate('Bienes Raíces', '🏠', AppColors.categoryRealEstate, Icons.home_work),
  vehicles('Vehículos', '🚗', AppColors.categoryVehicles, Icons.directions_car),
  bankAccounts('Cuentas Bancarias', '🏦', AppColors.categoryBankAccounts, Icons.account_balance);

  const AssetCategory(this.label, this.emoji, this.color, this.icon);
  final String label;
  final String emoji;
  final Color color;
  final IconData icon;
}

// ── Asset ───────────────────────────────────────

class Asset {
  final String id;
  final String name;
  final String institution;
  final AssetCategory category;
  final double currentValue;
  final double previousValue;
  final String currency; // DOP or USD
  final List<double> sparklineData;

  const Asset({
    required this.id,
    required this.name,
    required this.institution,
    required this.category,
    required this.currentValue,
    required this.previousValue,
    this.currency = 'DOP',
    this.sparklineData = const [],
  });

  double get variation => currentValue - previousValue;
  double get variationPercent =>
      previousValue != 0 ? ((currentValue - previousValue) / previousValue) * 100 : 0;
  bool get isPositive => variation >= 0;
}

// ── Transaction ─────────────────────────────────

enum TransactionType { income, expense }

class Transaction {
  final String id;
  final String description;
  final double amount;
  final TransactionType type;
  final String category;
  final IconData icon;
  final DateTime date;
  final String? assetName;

  const Transaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.type,
    required this.category,
    required this.icon,
    required this.date,
    this.assetName,
  });
}

// ── Investment Instrument ───────────────────────

enum RiskLevel {
  low('Bajo', AppColors.positive),
  medium('Medio', AppColors.accentBright),
  high('Alto', AppColors.negative);

  const RiskLevel(this.label, this.color);
  final String label;
  final Color color;
}

class InvestmentInstrument {
  final String id;
  final String name;
  final String institution;
  final String type; // Certificado, Fondo, Bono, Letra
  final double annualYield;
  final String term;
  final double minimumAmount;
  final String currency;
  final RiskLevel risk;
  final String? description;

  const InvestmentInstrument({
    required this.id,
    required this.name,
    required this.institution,
    required this.type,
    required this.annualYield,
    required this.term,
    required this.minimumAmount,
    this.currency = 'DOP',
    required this.risk,
    this.description,
  });
}

// ── Net Worth Snapshot ───────────────────────────

class NetWorthSnapshot {
  final DateTime date;
  final double value;

  const NetWorthSnapshot({required this.date, required this.value});
}

// ── Expense Category ────────────────────────────

class ExpenseCategory {
  final String name;
  final double amount;
  final double previousAmount;
  final Color color;
  final IconData icon;

  const ExpenseCategory({
    required this.name,
    required this.amount,
    required this.previousAmount,
    required this.color,
    required this.icon,
  });
}
