import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../utils/color_utils.dart';
import '../utils/icon_utils.dart';

// ==========================================
// MENUDO 2.0 MODELS
// ==========================================

// ── Wallet ───────────────────────────────────────
class WalletAccount {
  final int id;
  final String nombre;
  final String tipo; // "ahorro", "gasto", "deuda"
  final double saldo;
  final Color color;
  final IconData icono;

  const WalletAccount({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.saldo,
    required this.color,
    required this.icono,
  });

  factory WalletAccount.fromJson(Map<String, dynamic> json) {
    final subtipo = json['subtipo'] as String? ?? 'ahorro';
    final valorActual = (json['valor_actual'] as num).toDouble();
    return WalletAccount(
      id: (json['activo_id'] as num).toInt(),
      nombre: json['nombre'] as String,
      tipo: subtipo, // "ahorro"/"gasto"/"deuda" mapped from subtipo
      saldo: subtipo == 'deuda' ? -valorActual : valorActual,
      color: colorFromHex(json['color_hex'] as String? ?? '#4F46E5'),
      icono: iconFromKey(json['icono'] as String? ?? 'landmark'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'subtipo': tipo,
      'valor_actual': saldo.abs(),
      'color_hex': colorToHex(color),
      'icono': iconToKey(icono),
    };
  }
}

// ── Transaction ─────────────────────────────────
class MenudoTransaction {
  final int id;
  final String dateString; // "YYYY-MM-DD" e.g "2026-03-05"
  final String desc;
  final String catKey;
  final double monto;
  final String tipo; // "gasto", "ingreso", "transferencia"
  final IconData icono;
  final int? fromAccountId; // For transfers
  final int? toAccountId;   // For transfers
  final String? nota;

  const MenudoTransaction({
    required this.id,
    required this.dateString,
    required this.desc,
    required this.catKey,
    required this.monto,
    required this.tipo,
    required this.icono,
    this.fromAccountId,
    this.toAccountId,
    this.nota,
  });

  factory MenudoTransaction.fromJson(Map<String, dynamic> json, {String catKey = ''}) {
    final tipo = json['tipo'] as String;
    final rawMonto = (json['monto'] as num).toDouble();
    final monto = tipo == 'ingreso' ? rawMonto : -rawMonto;
    return MenudoTransaction(
      id: (json['transaccion_id'] as num).toInt(),
      dateString: json['fecha'] as String,
      desc: json['descripcion'] as String? ?? '',
      catKey: catKey, // Resolved externally from category slug
      monto: monto,
      tipo: tipo,
      icono: iconFromKey(json['categoria_icono'] as String? ?? 'circle'),
      fromAccountId: json['activo_id'] != null ? (json['activo_id'] as num).toInt() : null,
      toAccountId: json['activo_destino_id'] != null ? (json['activo_destino_id'] as num).toInt() : null,
      nota: json['nota'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fecha': dateString,
      'descripcion': desc,
      'monto': monto.abs(), // Always positive in DB
      'tipo': tipo,
      'nota': nota,
      if (fromAccountId != null) 'activo_id': fromAccountId,
      if (toAccountId != null) 'activo_destino_id': toAccountId,
    };
  }

  MenudoTransaction copyWith({
    String? desc,
    String? catKey,
    double? monto,
    String? tipo,
    IconData? icono,
    String? dateString,
    int? fromAccountId,
    int? toAccountId,
    String? nota,
  }) {
    return MenudoTransaction(
      id: id,
      dateString: dateString ?? this.dateString,
      desc: desc ?? this.desc,
      catKey: catKey ?? this.catKey,
      monto: monto ?? this.monto,
      tipo: tipo ?? this.tipo,
      icono: icono ?? this.icono,
      fromAccountId: fromAccountId ?? this.fromAccountId,
      toAccountId: toAccountId ?? this.toAccountId,
      nota: nota ?? this.nota,
    );
  }
}

// ── Recurring Transaction ─────────────────────
class RecurringTransaction {
  final int id;
  final String desc;
  final String catKey;
  final double monto;
  final String tipo; // "gasto", "ingreso"
  final IconData icono;
  final String frecuencia; // "mensual", "semanal", "quincenal"
  final int diaEjecucion; // Day of month or week
  final bool activo;
  final String? nota;

  const RecurringTransaction({
    required this.id,
    required this.desc,
    required this.catKey,
    required this.monto,
    required this.tipo,
    required this.icono,
    required this.frecuencia,
    required this.diaEjecucion,
    this.activo = true,
    this.nota,
  });

  factory RecurringTransaction.fromJson(Map<String, dynamic> json, {String catKey = ''}) {
    return RecurringTransaction(
      id: (json['recurrente_id'] as num).toInt(),
      desc: json['descripcion'] as String? ?? '',
      catKey: catKey,
      monto: (json['monto'] as num).toDouble(),
      tipo: json['tipo'] as String,
      icono: iconFromKey(json['categoria_icono'] as String? ?? 'circle'),
      frecuencia: json['frecuencia'] as String,
      diaEjecucion: (json['dia_ejecucion'] as num).toInt(),
      activo: json['activo'] as bool? ?? true,
      nota: json['nota'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'descripcion': desc,
      'monto': monto.abs(),
      'tipo': tipo,
      'frecuencia': frecuencia,
      'dia_ejecucion': diaEjecucion,
      'activo': activo,
      if (nota != null) 'nota': nota,
    };
  }
}

// ── Budget Category & Member ────────────────────
class BudgetCategory {
  final String label;
  final IconData icono;
  final Color color;
  final double limite;
  double gastado;

  BudgetCategory({
    required this.label,
    required this.icono,
    required this.color,
    required this.limite,
    this.gastado = 0.0,
  });

  factory BudgetCategory.fromJson(Map<String, dynamic> json) {
    return BudgetCategory(
      label: json['nombre'] as String,
      icono: iconFromKey(json['icono'] as String? ?? 'circle'),
      color: colorFromHex(json['color_hex'] as String? ?? '#4F46E5'),
      limite: (json['limite'] as num).toDouble(),
      gastado: (json['gastado'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': label,
      'icono': iconToKey(icono),
      'color_hex': colorToHex(color),
      'limite': limite,
    };
  }
}

class BudgetMember {
  final String n; // Name
  final String i; // Initial
  final Color c;  // Color

  const BudgetMember({required this.n, required this.i, required this.c});

  factory BudgetMember.fromJson(Map<String, dynamic> json) {
    return BudgetMember(
      n: json['nombre'] as String? ?? json['n'] as String,
      i: json['iniciales'] as String? ?? json['i'] as String,
      c: colorFromHex(json['color_hex'] as String? ?? '#065F46'),
    );
  }

  Map<String, dynamic> toJson() {
    return {'nombre': n, 'iniciales': i, 'color_hex': colorToHex(c)};
  }
}

// ── Category ──────────────────────────────────────
class MenudoCategory {
  final int id;
  final String slug;       // Used as catKey throughout the app
  final String nombre;
  final String tipo;       // "gasto", "ingreso", "transferencia"
  final IconData icono;
  final Color color;
  final bool esSistema;
  final int? usuarioId;    // null = system category

  const MenudoCategory({
    required this.id,
    required this.slug,
    required this.nombre,
    required this.tipo,
    required this.icono,
    required this.color,
    required this.esSistema,
    this.usuarioId,
  });

  factory MenudoCategory.fromJson(Map<String, dynamic> json) {
    return MenudoCategory(
      id: (json['categoria_id'] as num).toInt(),
      slug: json['slug'] as String? ?? (json['nombre'] as String).toLowerCase(),
      nombre: json['nombre'] as String,
      tipo: json['tipo'] as String,
      icono: iconFromKey(json['icono'] as String? ?? 'circle'),
      color: colorFromHex(json['color_hex'] as String? ?? '#4F46E5'),
      esSistema: json['es_sistema'] as bool? ?? false,
      usuarioId: json['usuario_id'] != null ? (json['usuario_id'] as num).toInt() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoria_id': id,
      'slug': slug,
      'nombre': nombre,
      'tipo': tipo,
      'icono': iconToKey(icono),
      'color_hex': colorToHex(color),
      'es_sistema': esSistema,
      'usuario_id': usuarioId,
    };
  }
}

class MenudoBudget {
  final int id;
  final String nombre;
  final String periodo; // "mensual", "quincenal", etc
  final int diaInicio;
  final bool activo;
  final List<BudgetMember> miembros;
  final double ingresos;
  final Map<String, BudgetCategory> cats;

  const MenudoBudget({
    required this.id,
    required this.nombre,
    required this.periodo,
    required this.diaInicio,
    required this.activo,
    required this.miembros,
    required this.ingresos,
    required this.cats,
  });

  factory MenudoBudget.fromJson(Map<String, dynamic> json, {
    List<BudgetMember> miembros = const [],
    Map<String, BudgetCategory> cats = const {},
  }) {
    return MenudoBudget(
      id: (json['presupuesto_id'] as num).toInt(),
      nombre: json['nombre'] as String,
      periodo: json['periodo'] as String,
      diaInicio: (json['dia_inicio'] as num).toInt(),
      activo: json['activo'] as bool? ?? false,
      ingresos: (json['ingresos'] as num).toDouble(),
      miembros: miembros,
      cats: cats,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'periodo': periodo,
      'dia_inicio': diaInicio,
      'activo': activo,
      'ingresos': ingresos,
    };
  }
}

// ==========================================
// MOCK INIT STATE (Menudo 2.0)
// ==========================================

final List<WalletAccount> mockWallets = [
  const WalletAccount(id: 1, nombre: "BHD León — Nómina", tipo: "ahorro", saldo: 45000, color: AppColors.b5, icono: LucideIcons.landmark),
  const WalletAccount(id: 2, nombre: "Popular — Crédito", tipo: "deuda", saldo: -12500, color: AppColors.r5, icono: LucideIcons.creditCard),
  const WalletAccount(id: 3, nombre: "Efectivo",          tipo: "gasto",  saldo: 3200, color: AppColors.e6, icono: LucideIcons.banknote),
  const WalletAccount(id: 4, nombre: "Fondo Emergencia",  tipo: "ahorro", saldo: 100000, color: AppColors.a5, icono: LucideIcons.shieldAlert),
];

Map<String, BudgetCategory> _createInitCats() {
  return {
    "vivienda": BudgetCategory(label: "Vivienda", icono: LucideIcons.home, color: AppColors.e7, limite: 25000, gastado: 25000),
    "comida": BudgetCategory(label: "Comida", icono: LucideIcons.utensils, color: AppColors.o5, limite: 15000, gastado: 8500),
    "transporte": BudgetCategory(label: "Transporte", icono: LucideIcons.car, color: AppColors.p5, limite: 8000, gastado: 4200),
    "estiloVida": BudgetCategory(label: "Estilo", icono: LucideIcons.sparkles, color: AppColors.pk, limite: 12000, gastado: 6300),
  };
}

final List<MenudoBudget> mockBudgets = [
  MenudoBudget(
    id: 1,
    nombre: "Mi Mes",
    periodo: "Mensual",
    diaInicio: 1,
    activo: true,
    miembros: const [
      BudgetMember(n: "Marcos", i: "M", c: AppColors.e8),
      BudgetMember(n: "Laura", i: "L", c: AppColors.o5)
    ],
    ingresos: 95000,
    cats: _createInitCats(),
  ),
  MenudoBudget(
    id: 2,
    nombre: "Viaje a Punta Cana",
    periodo: "Único",
    diaInicio: 15,
    activo: false,
    miembros: const [BudgetMember(n: "Marcos", i: "M", c: AppColors.e8)],
    ingresos: 40000,
    cats: {
      "comida": BudgetCategory(label: "Comida", icono: LucideIcons.utensils, color: AppColors.o5, limite: 10000, gastado: 2500),
      "estiloVida": BudgetCategory(label: "Tours", icono: LucideIcons.plane, color: AppColors.b5, limite: 15000, gastado: 0),
    },
  )
];

final List<MenudoTransaction> mockTxns = [
  // Ingresos
  const MenudoTransaction(id: 10, dateString: "2026-03-01", desc: "Salario BHD León", catKey: "ingreso", monto: 85000, tipo: "ingreso", icono: LucideIcons.landmark, nota: "Nómina mensual"),
  const MenudoTransaction(id: 11, dateString: "2026-03-01", desc: "Freelance diseño web", catKey: "ingreso", monto: 10000, tipo: "ingreso", icono: LucideIcons.monitor),
  // Transferencias
  const MenudoTransaction(id: 20, dateString: "2026-03-03", desc: "Ahorro mensual", catKey: "transferencia", monto: -5000, tipo: "transferencia", icono: LucideIcons.arrowLeftRight, fromAccountId: 1, toAccountId: 4, nota: "Aporte al fondo de emergencia"),
  // Gastos
  const MenudoTransaction(id: 1, dateString: "2026-03-01", desc: "Pago alquiler", catKey: "vivienda", monto: -25000, tipo: "gasto", icono: LucideIcons.home),
  const MenudoTransaction(id: 2, dateString: "2026-03-02", desc: "Supermercado Nacional", catKey: "comida", monto: -4500, tipo: "gasto", icono: LucideIcons.shoppingCart),
  const MenudoTransaction(id: 3, dateString: "2026-03-05", desc: "Gasolina Shell", catKey: "transporte", monto: -2000, tipo: "gasto", icono: LucideIcons.fuel),
  const MenudoTransaction(id: 4, dateString: "2026-03-07", desc: "Cena en SBG", catKey: "comida", monto: -4000, tipo: "gasto", icono: LucideIcons.wine),
  const MenudoTransaction(id: 5, dateString: "2026-03-07", desc: "Uber a casa", catKey: "transporte", monto: -450, tipo: "gasto", icono: LucideIcons.car),
  const MenudoTransaction(id: 6, dateString: "2026-03-07", desc: "Netflix Múltiple", catKey: "estiloVida", monto: -750, tipo: "gasto", icono: LucideIcons.tv),
  const MenudoTransaction(id: 7, dateString: "2026-03-04", desc: "Farmacia Carol", catKey: "salud", monto: -1200, tipo: "gasto", icono: LucideIcons.pill),
  const MenudoTransaction(id: 8, dateString: "2026-03-06", desc: "Libro programación", catKey: "educacion", monto: -850, tipo: "gasto", icono: LucideIcons.bookOpen),
  const MenudoTransaction(id: 9, dateString: "2026-03-02", desc: "Spotify Premium", catKey: "entretenimiento", monto: -350, tipo: "gasto", icono: LucideIcons.music),
];

final List<RecurringTransaction> mockRecurring = [
  const RecurringTransaction(id: 1, desc: "Salario BHD León", catKey: "ingreso", monto: 85000, tipo: "ingreso", icono: LucideIcons.landmark, frecuencia: "mensual", diaEjecucion: 1, nota: "Nómina mensual automática"),
  const RecurringTransaction(id: 2, desc: "Pago alquiler", catKey: "vivienda", monto: 25000, tipo: "gasto", icono: LucideIcons.home, frecuencia: "mensual", diaEjecucion: 1),
  const RecurringTransaction(id: 3, desc: "Netflix Múltiple", catKey: "entretenimiento", monto: 750, tipo: "gasto", icono: LucideIcons.tv, frecuencia: "mensual", diaEjecucion: 7),
  const RecurringTransaction(id: 4, desc: "Spotify Premium", catKey: "entretenimiento", monto: 350, tipo: "gasto", icono: LucideIcons.music, frecuencia: "mensual", diaEjecucion: 2, activo: false),
];


// ==========================================
// LEGACY SHIMS (TO PREVENT COMPILATION ERRORS DURING REFACTOR)
// ==========================================

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

class Asset {
  final String id;
  final String name;
  final String institution;
  final AssetCategory category;
  final double currentValue;
  final double previousValue;
  final String currency;
  final List<double> sparklineData;
  final String? tickerSymbol;
  final DateTime? lastSynced;

  const Asset({
    required this.id, required this.name, required this.institution, required this.category,
    required this.currentValue, required this.previousValue, this.currency = 'DOP',
    this.sparklineData = const [], this.tickerSymbol, this.lastSynced,
  });

  double get variation => currentValue - previousValue;
  double get variationPercent => previousValue != 0 ? ((currentValue - previousValue) / previousValue) * 100 : 0;
  bool get isPositive => variation >= 0;
}

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
    required this.id, required this.description, required this.amount, required this.type,
    required this.category, required this.icon, required this.date, this.assetName,
  });
}

enum RiskLevel {
  low('Bajo', AppColors.positive), medium('Medio', AppColors.accentBright), high('Alto', AppColors.negative);
  const RiskLevel(this.label, this.color);
  final String label;
  final Color color;
}

class InvestmentInstrument {
  final String id, name, institution, type, term, currency;
  final double annualYield, minimumAmount;
  final RiskLevel risk;
  final String? description;

  const InvestmentInstrument({
    required this.id, required this.name, required this.institution, required this.type,
    required this.annualYield, required this.term, required this.minimumAmount,
    this.currency = 'DOP', required this.risk, this.description,
  });
}

class NetWorthSnapshot {
  final DateTime date;
  final double value;
  const NetWorthSnapshot({required this.date, required this.value});
}

class ExpenseCategory {
  final String name;
  final double amount;
  final double previousAmount;
  final Color color;
  final IconData icon;
  const ExpenseCategory({required this.name, required this.amount, required this.previousAmount, required this.color, required this.icon});
}
