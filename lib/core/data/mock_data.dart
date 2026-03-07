import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'models.dart';

/// Patrimonium — Mock data for Dominican Republic market
class MockData {
  MockData._();

  // ── Assets ─────────────────────────────────────

  static final List<Asset> assets = [
    // Cash
    Asset(
      id: 'cash-1',
      name: 'Efectivo Personal',
      institution: 'En mano',
      category: AssetCategory.cash,
      currentValue: 185000,
      previousValue: 175000,
      currency: 'DOP',
      sparklineData: [150, 160, 155, 170, 175, 185],
    ),
    // Bank Accounts
    Asset(
      id: 'bank-1',
      name: 'Cuenta de Ahorro',
      institution: 'Banco BHD León',
      category: AssetCategory.bankAccounts,
      currentValue: 1250000,
      previousValue: 1230000,
      currency: 'DOP',
      sparklineData: [1100, 1150, 1180, 1200, 1230, 1250],
    ),
    Asset(
      id: 'bank-2',
      name: 'Cuenta Corriente USD',
      institution: 'Banco Popular',
      category: AssetCategory.bankAccounts,
      currentValue: 12500,
      previousValue: 12300,
      currency: 'USD',
      sparklineData: [11000, 11500, 11800, 12000, 12300, 12500],
    ),
    // Investments
    Asset(
      id: 'inv-1',
      name: 'Cert. Financiero 12M',
      institution: 'Asociación Popular',
      category: AssetCategory.investments,
      currentValue: 500000,
      previousValue: 485000,
      currency: 'DOP',
      sparklineData: [450, 460, 470, 480, 485, 500],
    ),
    Asset(
      id: 'inv-2',
      name: 'Fondo Cerrado Capital',
      institution: 'JMMB Puesto de Bolsa',
      category: AssetCategory.investments,
      currentValue: 350000,
      previousValue: 340000,
      currency: 'DOP',
      sparklineData: [300, 310, 320, 330, 340, 350],
    ),
    Asset(
      id: 'inv-3',
      name: 'Bono Soberano RD 2028',
      institution: 'Parval',
      category: AssetCategory.investments,
      currentValue: 15000,
      previousValue: 14800,
      currency: 'USD',
      sparklineData: [13500, 14000, 14200, 14500, 14800, 15000],
    ),
    // Crypto
    Asset(
      id: 'crypto-1',
      name: 'Bitcoin',
      institution: 'Binance',
      category: AssetCategory.crypto,
      currentValue: 18500,
      previousValue: 17800,
      currency: 'USD',
      sparklineData: [15000, 16200, 17000, 16500, 17800, 18500],
      tickerSymbol: 'BTC',
      lastSynced: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    Asset(
      id: 'crypto-2',
      name: 'Ethereum',
      institution: 'Coinbase',
      category: AssetCategory.crypto,
      currentValue: 4200,
      previousValue: 4350,
      currency: 'USD',
      sparklineData: [3800, 4100, 4500, 4350, 4200, 4200],
      tickerSymbol: 'ETH',
      lastSynced: DateTime.now().subtract(const Duration(minutes: 12)),
    ),
    // Real Estate
    Asset(
      id: 'real-1',
      name: 'Apartamento Piantini',
      institution: 'Santo Domingo',
      category: AssetCategory.realEstate,
      currentValue: 8500000,
      previousValue: 8350000,
      currency: 'DOP',
      sparklineData: [7800, 8000, 8100, 8200, 8350, 8500],
    ),
    // Vehicles
    Asset(
      id: 'veh-1',
      name: 'Toyota Corolla 2023',
      institution: 'Auto personal',
      category: AssetCategory.vehicles,
      currentValue: 1850000,
      previousValue: 1900000,
      currency: 'DOP',
      sparklineData: [2100, 2050, 2000, 1950, 1900, 1850],
    ),
  ];

  // ── Net Worth calculation in DOP (using 60 DOP/USD rate) ──

  static const double usdToDop = 60.0;

  static double get totalNetWorthDOP {
    double total = 0;
    for (final asset in assets) {
      total += asset.currency == 'USD' ? asset.currentValue * usdToDop : asset.currentValue;
    }
    return total;
  }

  static double get previousNetWorthDOP {
    double total = 0;
    for (final asset in assets) {
      total += asset.currency == 'USD' ? asset.previousValue * usdToDop : asset.previousValue;
    }
    return total;
  }

  // ── Transactions ──────────────────────────────

  static List<Transaction> get recentTransactions => [
        Transaction(
          id: 'tx-1',
          description: 'Salario mensual',
          amount: 185000,
          type: TransactionType.income,
          category: 'Salario',
          icon: Icons.work,
          date: DateTime(2026, 3, 1),
          assetName: 'Banco BHD León',
        ),
        Transaction(
          id: 'tx-2',
          description: 'Dividendos Cert. Financiero',
          amount: 12500,
          type: TransactionType.income,
          category: 'Dividendos',
          icon: Icons.trending_up,
          date: DateTime(2026, 2, 28),
          assetName: 'Asociación Popular',
        ),
        Transaction(
          id: 'tx-3',
          description: 'Pago cuota apartamento',
          amount: 45000,
          type: TransactionType.expense,
          category: 'Vivienda',
          icon: Icons.home,
          date: DateTime(2026, 2, 27),
          assetName: 'Banco BHD León',
        ),
        Transaction(
          id: 'tx-4',
          description: 'Uber - Viaje al trabajo',
          amount: 450,
          type: TransactionType.expense,
          category: 'Transporte',
          icon: Icons.directions_car,
          date: DateTime(2026, 2, 27),
          assetName: 'Banco BHD León',
        ),
        Transaction(
          id: 'tx-5',
          description: 'Supermercado Nacional',
          amount: 8500,
          type: TransactionType.expense,
          category: 'Alimentación',
          icon: Icons.shopping_cart,
          date: DateTime(2026, 2, 26),
          assetName: 'Banco Popular',
        ),
        Transaction(
          id: 'tx-6',
          description: 'Transferencia Juan',
          amount: 2500,
          type: TransactionType.income,
          category: 'Otros',
          icon: Icons.swap_horiz,
          date: DateTime(2026, 2, 26),
          assetName: 'Banco Popular',
        ),
        Transaction(
          id: 'tx-7',
          description: 'Edesur - Factura Luz',
          amount: 3200,
          type: TransactionType.expense,
          category: 'Servicios',
          icon: Icons.electrical_services,
          date: DateTime(2026, 2, 25),
          assetName: 'Banco BHD León',
        ),
        Transaction(
          id: 'tx-8',
          description: 'Suscripción Netflix',
          amount: 900,
          type: TransactionType.expense,
          category: 'Entretenimiento',
          icon: Icons.movie,
          date: DateTime(2026, 2, 25),
          assetName: 'Banco Popular',
        ),
        Transaction(
          id: 'tx-9',
          description: 'Restaurante SBG',
          amount: 4500,
          type: TransactionType.expense,
          category: 'Alimentación',
          icon: Icons.restaurant,
          date: DateTime(2026, 2, 24),
          assetName: 'Banco BHD León',
        ),
        Transaction(
          id: 'tx-10',
          description: 'Venta de Cripto',
          amount: 25000,
          type: TransactionType.income,
          category: 'Inversiones',
          icon: Icons.trending_up,
          date: DateTime(2026, 2, 22),
          assetName: 'Banco BHD León',
        ),
        Transaction(
          id: 'tx-11',
          description: 'Farmacia Carol',
          amount: 1200,
          type: TransactionType.expense,
          category: 'Salud',
          icon: Icons.medical_services,
          date: DateTime(2026, 2, 22),
          assetName: 'Efectivo Personal',
        ),
        Transaction(
          id: 'tx-12',
          description: 'Gasolina',
          amount: 3000,
          type: TransactionType.expense,
          category: 'Transporte',
          icon: Icons.local_gas_station,
          date: DateTime(2026, 2, 21),
          assetName: 'Banco BHD León',
        ),
        Transaction(
          id: 'tx-13',
          description: 'Abono préstamo',
          amount: 15000,
          type: TransactionType.expense,
          category: 'Deudas',
          icon: Icons.account_balance,
          date: DateTime(2026, 2, 20),
          assetName: 'Banco Popular',
        ),
        Transaction(
          id: 'tx-14',
          description: 'Bono vacacional',
          amount: 45000,
          type: TransactionType.income,
          category: 'Salario',
          icon: Icons.work,
          date: DateTime(2026, 2, 15),
          assetName: 'Banco BHD León',
        ),
        Transaction(
          id: 'tx-15',
          description: 'Seguro médico',
          amount: 5500,
          type: TransactionType.expense,
          category: 'Salud',
          icon: Icons.health_and_safety,
          date: DateTime(2026, 2, 15),
          assetName: 'Banco Popular',
        ),
      ];

  // ── Investment Instruments ────────────────────

  static const List<InvestmentInstrument> _instrumentsData = [
    InvestmentInstrument(
      id: 'inst-1',
      name: 'Certificado Financiero',
      institution: 'Asociación Popular',
      type: 'Certificado',
      annualYield: 12.5,
      term: '12 meses',
      minimumAmount: 10000,
      currency: 'DOP',
      risk: RiskLevel.low,
      description: 'Certificado a plazo fijo con tasa garantizada',
    ),
    InvestmentInstrument(
      id: 'inst-2',
      name: 'Certificado USD',
      institution: 'Banco BHD León',
      type: 'Certificado',
      annualYield: 5.25,
      term: '6 meses',
      minimumAmount: 500,
      currency: 'USD',
      risk: RiskLevel.low,
    ),
    InvestmentInstrument(
      id: 'inst-3',
      name: 'Fondo Cerrado Inmobiliario',
      institution: 'JMMB Puesto de Bolsa',
      type: 'Fondo',
      annualYield: 14.8,
      term: '24 meses',
      minimumAmount: 50000,
      currency: 'DOP',
      risk: RiskLevel.medium,
    ),
    InvestmentInstrument(
      id: 'inst-4',
      name: 'Bono Corporativo Cemex',
      institution: 'Parval',
      type: 'Bono',
      annualYield: 9.75,
      term: '36 meses',
      minimumAmount: 100000,
      currency: 'DOP',
      risk: RiskLevel.medium,
    ),
    InvestmentInstrument(
      id: 'inst-5',
      name: 'Letra del Banco Central',
      institution: 'BCRD',
      type: 'Letra',
      annualYield: 11.0,
      term: '90 días',
      minimumAmount: 100000,
      currency: 'DOP',
      risk: RiskLevel.low,
    ),
    InvestmentInstrument(
      id: 'inst-6',
      name: 'Bono Soberano RD 2030',
      institution: 'Ministerio de Hacienda',
      type: 'Bono',
      annualYield: 7.5,
      term: '48 meses',
      minimumAmount: 5000,
      currency: 'USD',
      risk: RiskLevel.low,
    ),
    InvestmentInstrument(
      id: 'inst-7',
      name: 'Fondo de Inversión Abierto',
      institution: 'Reservas SAF',
      type: 'Fondo',
      annualYield: 10.2,
      term: 'Abierto',
      minimumAmount: 5000,
      currency: 'DOP',
      risk: RiskLevel.low,
    ),
    InvestmentInstrument(
      id: 'inst-8',
      name: 'Cert. Financiero Premium',
      institution: 'Scotia Bank RD',
      type: 'Certificado',
      annualYield: 13.0,
      term: '18 meses',
      minimumAmount: 500000,
      currency: 'DOP',
      risk: RiskLevel.low,
    ),
    InvestmentInstrument(
      id: 'inst-9',
      name: 'Fondo Cerrado de Desarrollo',
      institution: 'Valmesa',
      type: 'Fondo',
      annualYield: 16.5,
      term: '36 meses',
      minimumAmount: 250000,
      currency: 'DOP',
      risk: RiskLevel.high,
    ),
  ];

  // ── Net Worth History ─────────────────────────

  static List<NetWorthSnapshot> get netWorthHistory => [
    NetWorthSnapshot(date: DateTime(2025, 4, 1), value: 9500000),
    NetWorthSnapshot(date: DateTime(2025, 5, 1), value: 9800000),
    NetWorthSnapshot(date: DateTime(2025, 6, 1), value: 10100000),
    NetWorthSnapshot(date: DateTime(2025, 7, 1), value: 10400000),
    NetWorthSnapshot(date: DateTime(2025, 8, 1), value: 10200000),
    NetWorthSnapshot(date: DateTime(2025, 9, 1), value: 10600000),
    NetWorthSnapshot(date: DateTime(2025, 10, 1), value: 11000000),
    NetWorthSnapshot(date: DateTime(2025, 11, 1), value: 11500000),
    NetWorthSnapshot(date: DateTime(2025, 12, 1), value: 11800000),
    NetWorthSnapshot(date: DateTime(2026, 1, 1), value: 12200000),
    NetWorthSnapshot(date: DateTime(2026, 2, 1), value: 12500000),
    NetWorthSnapshot(date: DateTime(2026, 3, 1), value: 15647000),
  ];

  static List<InvestmentInstrument> get instruments => _instrumentsData;

  // ── Expense Categories ────────────────────────

  static final List<ExpenseCategory> expenseCategories = [
    ExpenseCategory(
      name: 'Vivienda',
      amount: 45000,
      previousAmount: 45000,
      color: AppColors.categoryRealEstate,
      icon: Icons.home,
    ),
    ExpenseCategory(
      name: 'Alimentación',
      amount: 28000,
      previousAmount: 25000,
      color: AppColors.positive,
      icon: Icons.restaurant,
    ),
    ExpenseCategory(
      name: 'Transporte',
      amount: 15000,
      previousAmount: 18000,
      color: AppColors.categoryVehicles,
      icon: Icons.directions_car,
    ),
    ExpenseCategory(
      name: 'Entretenimiento',
      amount: 12000,
      previousAmount: 8000,
      color: AppColors.categoryCrypto,
      icon: Icons.movie,
    ),
    ExpenseCategory(
      name: 'Salud',
      amount: 8500,
      previousAmount: 5000,
      color: AppColors.negative,
      icon: Icons.health_and_safety,
    ),
    ExpenseCategory(
      name: 'Servicios',
      amount: 7800,
      previousAmount: 7500,
      color: AppColors.categoryBankAccounts,
      icon: Icons.electrical_services,
    ),
  ];
}
