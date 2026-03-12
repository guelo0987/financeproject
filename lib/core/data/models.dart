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
  final String tipo; // DB: "cuentas", "gastos", "deudas"
  final double saldo;
  final Color color;
  final IconData icono;
  final String moneda;
  final bool esDefault;
  final bool incluirEnPatrimonio;

  const WalletAccount({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.saldo,
    required this.color,
    required this.icono,
    this.moneda = 'DOP',
    this.esDefault = false,
    this.incluirEnPatrimonio = true,
  });

  factory WalletAccount.fromJson(Map<String, dynamic> json) {
    final tipoDb = json['tipo'] as String? ?? 'cuentas';
    final valorActual = (json['valor_actual'] as num).toDouble();
    return WalletAccount(
      id: (json['activo_id'] as num).toInt(),
      nombre: json['nombre'] as String,
      tipo: tipoDb,
      saldo: tipoDb == 'deudas' ? -valorActual : valorActual,
      color: colorFromHex(json['color_hex'] as String? ?? '#4F46E5'),
      icono: iconFromKey(json['icono'] as String? ?? 'landmark'),
      moneda: json['moneda'] as String? ?? 'DOP',
      esDefault: json['es_default'] as bool? ?? false,
      incluirEnPatrimonio: json['incluir_en_patrimonio'] as bool? ?? true,
    );
  }

  WalletAccount copyWith({
    int? id,
    String? nombre,
    String? tipo,
    double? saldo,
    Color? color,
    IconData? icono,
    String? moneda,
    bool? esDefault,
    bool? incluirEnPatrimonio,
  }) {
    return WalletAccount(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      tipo: tipo ?? this.tipo,
      saldo: saldo ?? this.saldo,
      color: color ?? this.color,
      icono: icono ?? this.icono,
      moneda: moneda ?? this.moneda,
      esDefault: esDefault ?? this.esDefault,
      incluirEnPatrimonio: incluirEnPatrimonio ?? this.incluirEnPatrimonio,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'tipo': tipo,
      'valor_actual': saldo.abs(),
      'color_hex': colorToHex(color),
      'icono': iconToKey(icono),
      'moneda': moneda,
      'es_default': esDefault,
      'incluir_en_patrimonio': incluirEnPatrimonio,
    };
  }
}

class TransactionWalletInfo {
  final int id;
  final String nombre;
  final String? tipo;
  final String? moneda;

  const TransactionWalletInfo({
    required this.id,
    required this.nombre,
    this.tipo,
    this.moneda,
  });

  factory TransactionWalletInfo.fromJson(Map<String, dynamic> json) {
    int? parseInt(Object? value) {
      return switch (value) {
        int data => data,
        num data => data.toInt(),
        String data => int.tryParse(data),
        _ => null,
      };
    }

    return TransactionWalletInfo(
      id: parseInt(json['id'] ?? json['activo_id'] ?? json['wallet_id']) ?? 0,
      nombre: json['nombre']?.toString() ?? '',
      tipo: json['tipo']?.toString(),
      moneda: json['moneda']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      if (tipo != null) 'tipo': tipo,
      if (moneda != null) 'moneda': moneda,
    };
  }
}

// ── Transaction ─────────────────────────────────
class MenudoTransaction {
  final int id;
  final String dateString; // "YYYY-MM-DD"
  final String desc;
  final String catKey; // slug
  final int? budgetId;
  final int? categoryId;
  final double monto;
  final String tipo; // "gasto", "ingreso", "transferencia"
  final IconData icono;
  final int? fromAccountId;
  final int? toAccountId;
  final String? nota;
  final String moneda;
  final int? usuarioId;
  final String? userName;
  final TransactionWalletInfo? fromWallet;
  final TransactionWalletInfo? toWallet;

  const MenudoTransaction({
    required this.id,
    required this.dateString,
    required this.desc,
    required this.catKey,
    this.budgetId,
    this.categoryId,
    required this.monto,
    required this.tipo,
    required this.icono,
    this.fromAccountId,
    this.toAccountId,
    this.nota,
    this.moneda = 'DOP',
    this.usuarioId,
    this.userName,
    this.fromWallet,
    this.toWallet,
  });

  factory MenudoTransaction.fromJson(
    Map<String, dynamic> json, {
    String catKey = '',
  }) {
    final tipo = json['tipo'] as String;
    final rawMonto = (json['monto'] as num).toDouble();
    // In DB monto is always positive. We sign it for UI convenience.
    final monto = tipo == 'ingreso' ? rawMonto : -rawMonto;
    final fromWalletPayload = json['wallet'] ?? json['wallet_origen'];
    final toWalletPayload = json['wallet_destino'] ?? json['to_wallet'];

    return MenudoTransaction(
      id: (json['transaccion_id'] as num).toInt(),
      dateString: json['fecha'] as String,
      desc: json['descripcion'] as String? ?? '',
      catKey: catKey,
      budgetId: json['presupuesto_id'] != null
          ? (json['presupuesto_id'] as num).toInt()
          : null,
      categoryId: json['categoria_id'] != null
          ? (json['categoria_id'] as num).toInt()
          : null,
      monto: monto,
      tipo: tipo,
      icono: iconFromKey(json['categoria_icono'] as String? ?? 'circle'),
      fromAccountId: json['activo_id'] != null
          ? (json['activo_id'] as num).toInt()
          : null,
      toAccountId: json['activo_destino_id'] != null
          ? (json['activo_destino_id'] as num).toInt()
          : null,
      nota: json['nota'] as String?,
      moneda: json['moneda'] as String? ?? 'DOP',
      usuarioId: json['usuario_id'] != null
          ? (json['usuario_id'] as num).toInt()
          : null,
      userName: json['user_name'] as String?,
      fromWallet: fromWalletPayload is Map
          ? TransactionWalletInfo.fromJson(
              Map<String, dynamic>.from(fromWalletPayload),
            )
          : null,
      toWallet: toWalletPayload is Map
          ? TransactionWalletInfo.fromJson(
              Map<String, dynamic>.from(toWalletPayload),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fecha': dateString,
      'descripcion': desc,
      'monto': monto.abs(),
      'tipo': tipo,
      'nota': nota,
      'moneda': moneda,
      if (budgetId != null) 'presupuesto_id': budgetId,
      if (fromAccountId != null) 'activo_id': fromAccountId,
      if (toAccountId != null) 'activo_destino_id': toAccountId,
      if (categoryId != null) 'categoria_id': categoryId,
      if (usuarioId != null) 'usuario_id': usuarioId,
      if (fromWallet != null) 'wallet': fromWallet!.toJson(),
      if (toWallet != null) 'wallet_destino': toWallet!.toJson(),
    };
  }

  MenudoTransaction copyWith({
    String? desc,
    String? catKey,
    int? budgetId,
    double? monto,
    String? tipo,
    IconData? icono,
    String? dateString,
    int? fromAccountId,
    int? toAccountId,
    String? nota,
    String? moneda,
    int? usuarioId,
    String? userName,
    TransactionWalletInfo? fromWallet,
    TransactionWalletInfo? toWallet,
  }) {
    return MenudoTransaction(
      id: id,
      dateString: dateString ?? this.dateString,
      desc: desc ?? this.desc,
      catKey: catKey ?? this.catKey,
      budgetId: budgetId ?? this.budgetId,
      monto: monto ?? this.monto,
      tipo: tipo ?? this.tipo,
      icono: icono ?? this.icono,
      fromAccountId: fromAccountId ?? this.fromAccountId,
      toAccountId: toAccountId ?? this.toAccountId,
      nota: nota ?? this.nota,
      moneda: moneda ?? this.moneda,
      usuarioId: usuarioId ?? this.usuarioId,
      userName: userName ?? this.userName,
      fromWallet: fromWallet ?? this.fromWallet,
      toWallet: toWallet ?? this.toWallet,
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
  final int? accountId;
  final int? presupuestoId;

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
    this.accountId,
    this.presupuestoId,
  });

  factory RecurringTransaction.fromJson(
    Map<String, dynamic> json, {
    String catKey = '',
  }) {
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
      accountId: json['activo_id'] != null
          ? (json['activo_id'] as num).toInt()
          : null,
      presupuestoId: json['presupuesto_id'] != null
          ? (json['presupuesto_id'] as num).toInt()
          : null,
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
      if (accountId != null) 'activo_id': accountId,
      if (presupuestoId != null) 'presupuesto_id': presupuestoId,
    };
  }
}

// ── Budget Category & Member ────────────────────
class BudgetCategory {
  final int? categoryId; // Link to public.categorias
  final int? parentCategoryId;
  final String? slug;
  final String? tipo;
  final String label;
  final IconData icono;
  final Color color;
  final double limite;
  double gastado;

  BudgetCategory({
    this.categoryId,
    this.parentCategoryId,
    this.slug,
    this.tipo,
    required this.label,
    required this.icono,
    required this.color,
    required this.limite,
    this.gastado = 0.0,
  });

  factory BudgetCategory.fromJson(Map<String, dynamic> json) {
    return BudgetCategory(
      categoryId: json['categoria_id'] != null
          ? (json['categoria_id'] as num).toInt()
          : null,
      parentCategoryId: json['categoria_padre_id'] != null
          ? (json['categoria_padre_id'] as num).toInt()
          : null,
      slug: json['slug'] as String?,
      tipo: json['tipo'] as String?,
      label: json['nombre'] as String? ?? '',
      icono: iconFromKey(json['icono'] as String? ?? 'circle'),
      color: colorFromHex(json['color_hex'] as String? ?? '#4F46E5'),
      limite: (json['limite'] as num? ?? 0).toDouble(),
      gastado: (json['gastado'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (categoryId != null) 'categoria_id': categoryId,
      if (parentCategoryId != null) 'categoria_padre_id': parentCategoryId,
      if (slug != null) 'slug': slug,
      if (tipo != null) 'tipo': tipo,
      'nombre': label,
      'icono': iconToKey(icono),
      'color_hex': colorToHex(color),
      'limite': limite,
    };
  }
}

class BudgetIncomeSource {
  final int? categoryId;
  final int? parentCategoryId;
  final String? slug;
  final String? tipo;
  final String label;
  final IconData icono;
  final Color color;
  final double planned;
  final double actual;

  const BudgetIncomeSource({
    this.categoryId,
    this.parentCategoryId,
    this.slug,
    this.tipo,
    required this.label,
    required this.icono,
    required this.color,
    required this.planned,
    this.actual = 0,
  });

  double get difference => actual - planned;

  factory BudgetIncomeSource.fromJson(Map<String, dynamic> json) {
    return BudgetIncomeSource(
      categoryId: json['categoria_id'] != null
          ? (json['categoria_id'] as num).toInt()
          : null,
      parentCategoryId: json['categoria_padre_id'] != null
          ? (json['categoria_padre_id'] as num).toInt()
          : null,
      slug: json['slug'] as String?,
      tipo: json['tipo'] as String?,
      label: json['nombre'] as String? ?? 'Ingresos',
      icono: iconFromKey(json['icono'] as String? ?? 'trendingUp'),
      color: colorFromHex(json['color_hex'] as String? ?? '#10B981'),
      planned: (json['monto_planeado'] as num? ?? 0).toDouble(),
      actual: (json['monto_actual'] as num? ?? 0).toDouble(),
    );
  }
}

class BudgetMember {
  final int? userId;
  final String n; // Name
  final String i; // Initial
  final Color c; // Color
  final String? email;
  final String? role;
  final bool isOwner;
  final DateTime? joinedAt;

  const BudgetMember({
    this.userId,
    required this.n,
    required this.i,
    required this.c,
    this.email,
    this.role,
    this.isOwner = false,
    this.joinedAt,
  });

  factory BudgetMember.fromJson(Map<String, dynamic> json) {
    final name = json['nombre'] as String? ?? json['n'] as String? ?? 'Miembro';
    final email = json['email'] as String?;
    final providedInitials =
        json['iniciales'] as String? ?? json['i'] as String?;
    final role = json['rol'] as String?;

    return BudgetMember(
      userId: json['usuario_id'] != null
          ? (json['usuario_id'] as num).toInt()
          : null,
      n: name,
      i: _budgetMemberInitials(
        providedInitials: providedInitials,
        name: name,
        email: email,
      ),
      c: colorFromHex(
        json['color_hex'] as String? ?? _budgetMemberColorHex(role),
      ),
      email: email,
      role: role,
      isOwner: json['es_propietario'] as bool? ?? false,
      joinedAt: DateTime.tryParse(json['unido_en'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (userId != null) 'usuario_id': userId,
      'nombre': n,
      'iniciales': i,
      'color_hex': colorToHex(c),
      if (email != null) 'email': email,
      if (role != null) 'rol': role,
      'es_propietario': isOwner,
      if (joinedAt != null) 'unido_en': joinedAt!.toIso8601String(),
    };
  }
}

String _budgetMemberInitials({
  required String? providedInitials,
  required String name,
  required String? email,
}) {
  final sanitized = (providedInitials ?? '').trim();
  if (sanitized.isNotEmpty) {
    return sanitized.characters.take(2).toString().toUpperCase();
  }

  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.length >= 2) {
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }
  if (parts.length == 1) {
    final end = parts.first.length < 2 ? parts.first.length : 2;
    return parts.first.substring(0, end).toUpperCase();
  }

  final emailName = email?.split('@').first.trim() ?? 'M';
  final end = emailName.length < 2 ? emailName.length : 2;
  return emailName.substring(0, end).toUpperCase();
}

String _budgetMemberColorHex(String? role) {
  switch (role) {
    case 'admin':
      return '#065F46';
    case 'miembro':
      return '#F97316';
    default:
      return '#065F46';
  }
}

// ── Category ──────────────────────────────────────
class MenudoCategory {
  final int id;
  final String slug; // Used as catKey throughout the app
  final String nombre;
  final String tipo; // "gasto", "ingreso", "transferencia"
  final IconData icono;
  final Color color;
  final bool esSistema;
  final int? usuarioId; // null = system category
  final int? categoriaParadreId; // null = this IS a parent category

  const MenudoCategory({
    required this.id,
    required this.slug,
    required this.nombre,
    this.tipo = 'gasto',
    required this.icono,
    required this.color,
    required this.esSistema,
    this.usuarioId,
    this.categoriaParadreId,
  });

  bool get esParent => categoriaParadreId == null;

  factory MenudoCategory.fromJson(Map<String, dynamic> json) {
    return MenudoCategory(
      id: (json['categoria_id'] as num).toInt(),
      slug: json['slug'] as String? ?? (json['nombre'] as String).toLowerCase(),
      nombre: json['nombre'] as String,
      tipo: json['tipo'] as String? ?? 'gasto',
      icono: iconFromKey(json['icono'] as String? ?? 'circle'),
      color: colorFromHex(json['color_hex'] as String? ?? '#4F46E5'),
      esSistema: json['es_sistema'] as bool? ?? false,
      usuarioId: json['usuario_id'] != null
          ? (json['usuario_id'] as num).toInt()
          : null,
      categoriaParadreId: json['categoria_padre_id'] != null
          ? (json['categoria_padre_id'] as num).toInt()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'slug': slug,
      'nombre': nombre,
      'tipo': tipo,
      'icono': iconToKey(icono),
      'color_hex': colorToHex(color),
      if (categoriaParadreId != null) 'categoria_padre_id': categoriaParadreId,
    };
  }
}

class MenudoBudget {
  final int id;
  final int? espacioId;
  final String nombre;
  final String periodo; // "mensual", "quincenal", "semanal", "unico"
  final int diaInicio;
  final bool activo;
  final List<BudgetMember> miembros;
  final double ingresos;
  final double ahorroObjetivo;
  final Map<String, BudgetCategory> cats;
  final List<BudgetCategory> otherExpenses;
  final Map<int, double> incomePlan;
  final List<BudgetIncomeSource> incomeSources;
  final List<BudgetIncomeSource> otherIncomeSources;
  final double? totalSpentReal;
  final double? totalIncomeActual;

  const MenudoBudget({
    required this.id,
    this.espacioId,
    required this.nombre,
    required this.periodo,
    required this.diaInicio,
    required this.activo,
    required this.miembros,
    required this.ingresos,
    this.ahorroObjetivo = 0,
    required this.cats,
    this.otherExpenses = const [],
    this.incomePlan = const {},
    this.incomeSources = const [],
    this.otherIncomeSources = const [],
    this.totalSpentReal,
    this.totalIncomeActual,
  });

  List<BudgetCategory> get spendingCategories => [
    ...cats.values,
    ...otherExpenses,
  ];

  double get totalSpent =>
      totalSpentReal ??
      spendingCategories.fold(0.0, (sum, category) => sum + category.gastado);

  double get actualIncomeTotal =>
      totalIncomeActual ??
      [
        ...incomeSources,
        ...otherIncomeSources,
      ].fold(0.0, (sum, source) => sum + source.actual);

  double get displayIncomeBase =>
      actualIncomeTotal > 0 ? actualIncomeTotal : ingresos;

  double get availableToSpend => displayIncomeBase - totalSpent;

  MenudoBudget copyWith({
    int? id,
    int? espacioId,
    bool clearEspacioId = false,
    String? nombre,
    String? periodo,
    int? diaInicio,
    bool? activo,
    List<BudgetMember>? miembros,
    double? ingresos,
    double? ahorroObjetivo,
    Map<String, BudgetCategory>? cats,
    List<BudgetCategory>? otherExpenses,
    Map<int, double>? incomePlan,
    List<BudgetIncomeSource>? incomeSources,
    List<BudgetIncomeSource>? otherIncomeSources,
    double? totalSpentReal,
    double? totalIncomeActual,
  }) {
    return MenudoBudget(
      id: id ?? this.id,
      espacioId: clearEspacioId ? null : (espacioId ?? this.espacioId),
      nombre: nombre ?? this.nombre,
      periodo: periodo ?? this.periodo,
      diaInicio: diaInicio ?? this.diaInicio,
      activo: activo ?? this.activo,
      miembros: miembros ?? this.miembros,
      ingresos: ingresos ?? this.ingresos,
      ahorroObjetivo: ahorroObjetivo ?? this.ahorroObjetivo,
      cats: cats ?? this.cats,
      otherExpenses: otherExpenses ?? this.otherExpenses,
      incomePlan: incomePlan ?? this.incomePlan,
      incomeSources: incomeSources ?? this.incomeSources,
      otherIncomeSources: otherIncomeSources ?? this.otherIncomeSources,
      totalSpentReal: totalSpentReal ?? this.totalSpentReal,
      totalIncomeActual: totalIncomeActual ?? this.totalIncomeActual,
    );
  }

  factory MenudoBudget.fromJson(
    Map<String, dynamic> json, {
    List<BudgetMember> miembros = const [],
    Map<String, BudgetCategory> cats = const {},
    List<BudgetCategory> otherExpenses = const [],
    Map<int, double> incomePlan = const {},
    List<BudgetIncomeSource> incomeSources = const [],
    List<BudgetIncomeSource> otherIncomeSources = const [],
    double? totalSpentReal,
    double? totalIncomeActual,
  }) {
    return MenudoBudget(
      id: (json['presupuesto_id'] as num).toInt(),
      espacioId: json['espacio_id'] != null
          ? (json['espacio_id'] as num).toInt()
          : null,
      nombre: json['nombre'] as String,
      periodo: json['periodo'] as String,
      diaInicio: (json['dia_inicio'] as num).toInt(),
      activo: json['activo'] as bool? ?? false,
      ingresos: (json['ingresos'] as num? ?? 0).toDouble(),
      ahorroObjetivo: (json['ahorro_objetivo'] as num? ?? 0).toDouble(),
      miembros: miembros,
      cats: cats,
      otherExpenses: otherExpenses,
      incomePlan: incomePlan,
      incomeSources: incomeSources,
      otherIncomeSources: otherIncomeSources,
      totalSpentReal: totalSpentReal,
      totalIncomeActual: totalIncomeActual,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'periodo': periodo,
      'dia_inicio': diaInicio,
      'activo': activo,
      'ingresos': ingresos,
      'ahorro_objetivo': ahorroObjetivo,
    };
  }
}

// ==========================================
// MOCK INIT STATE (Menudo 2.0)
// ==========================================

final List<WalletAccount> mockWallets = [
  const WalletAccount(
    id: 1,
    nombre: "BHD León — Nómina",
    tipo: "cuentas",
    saldo: 45000,
    color: AppColors.b5,
    icono: LucideIcons.landmark,
    moneda: 'DOP',
    esDefault: true,
  ),
  const WalletAccount(
    id: 2,
    nombre: "Popular — Crédito",
    tipo: "deudas",
    saldo: -12500,
    color: AppColors.r5,
    icono: LucideIcons.creditCard,
    moneda: 'DOP',
  ),
  const WalletAccount(
    id: 3,
    nombre: "Efectivo",
    tipo: "gastos",
    saldo: 3200,
    color: AppColors.e6,
    icono: LucideIcons.banknote,
    moneda: 'DOP',
  ),
  const WalletAccount(
    id: 4,
    nombre: "Fondo Emergencia",
    tipo: "cuentas",
    saldo: 100000,
    color: AppColors.a5,
    icono: LucideIcons.shieldAlert,
    moneda: 'DOP',
  ),
];

Map<String, BudgetCategory> _createInitCats() {
  return {
    "vivienda": BudgetCategory(
      categoryId: 1,
      label: "Vivienda",
      icono: LucideIcons.home,
      color: AppColors.e7,
      limite: 25000,
      gastado: 25000,
    ),
    "comida": BudgetCategory(
      categoryId: 2,
      label: "Comida",
      icono: LucideIcons.utensils,
      color: AppColors.o5,
      limite: 15000,
      gastado: 8500,
    ),
    "transporte": BudgetCategory(
      categoryId: 3,
      label: "Transporte",
      icono: LucideIcons.car,
      color: AppColors.p5,
      limite: 8000,
      gastado: 4200,
    ),
    "estiloVida": BudgetCategory(
      categoryId: 4,
      label: "Estilo",
      icono: LucideIcons.sparkles,
      color: AppColors.pk,
      limite: 12000,
      gastado: 6300,
    ),
  };
}

final List<MenudoBudget> mockBudgets = [
  MenudoBudget(
    id: 1,
    nombre: "Mi Mes",
    periodo: "mensual",
    diaInicio: 1,
    activo: true,
    miembros: const [
      BudgetMember(n: "Marcos", i: "M", c: AppColors.e8),
      BudgetMember(n: "Laura", i: "L", c: AppColors.o5),
    ],
    ingresos: 95000,
    ahorroObjetivo: 15000,
    cats: _createInitCats(),
  ),
  MenudoBudget(
    id: 2,
    nombre: "Viaje a Punta Cana",
    periodo: "unico",
    diaInicio: 15,
    activo: false,
    miembros: const [BudgetMember(n: "Marcos", i: "M", c: AppColors.e8)],
    ingresos: 40000,
    ahorroObjetivo: 0,
    cats: {
      "comida": BudgetCategory(
        categoryId: 2,
        label: "Comida",
        icono: LucideIcons.utensils,
        color: AppColors.o5,
        limite: 10000,
        gastado: 2500,
      ),
      "estiloVida": BudgetCategory(
        categoryId: 4,
        label: "Tours",
        icono: LucideIcons.plane,
        color: AppColors.b5,
        limite: 15000,
        gastado: 0,
      ),
    },
  ),
];

final List<MenudoTransaction> mockTxns = [
  // Ingresos
  const MenudoTransaction(
    id: 10,
    dateString: "2026-03-01",
    desc: "Salario BHD León",
    catKey: "ingreso",
    categoryId: 8,
    monto: 85000,
    tipo: "ingreso",
    icono: LucideIcons.landmark,
    nota: "Nómina mensual",
    moneda: 'DOP',
    userName: "Miguel",
  ),
  const MenudoTransaction(
    id: 11,
    dateString: "2026-03-01",
    desc: "Freelance diseño web",
    catKey: "ingreso",
    categoryId: 8,
    monto: 10000,
    tipo: "ingreso",
    icono: LucideIcons.monitor,
    moneda: 'DOP',
    userName: "Miguel",
  ),
  // Transferencias
  const MenudoTransaction(
    id: 20,
    dateString: "2026-03-03",
    desc: "Ahorro mensual",
    catKey: "transferencia",
    categoryId: 9,
    monto: -5000,
    tipo: "transferencia",
    icono: LucideIcons.arrowLeftRight,
    fromAccountId: 1,
    toAccountId: 4,
    nota: "Aporte al fondo de emergencia",
    moneda: 'DOP',
    userName: "Miguel",
  ),
  // Gastos
  const MenudoTransaction(
    id: 1,
    dateString: "2026-03-01",
    desc: "Pago alquiler",
    catKey: "vivienda",
    categoryId: 1,
    monto: -25000,
    tipo: "gasto",
    icono: LucideIcons.home,
    moneda: 'DOP',
    userName: "Miguel",
  ),
  const MenudoTransaction(
    id: 2,
    dateString: "2026-03-02",
    desc: "Supermercado Nacional",
    catKey: "comida",
    categoryId: 2,
    monto: -4500,
    tipo: "gasto",
    icono: LucideIcons.shoppingCart,
    moneda: 'DOP',
    userName: "Sarah",
  ),
  const MenudoTransaction(
    id: 3,
    dateString: "2026-03-05",
    desc: "Gasolina Shell",
    catKey: "transporte",
    categoryId: 3,
    monto: -2000,
    tipo: "gasto",
    icono: LucideIcons.fuel,
    moneda: 'DOP',
    userName: "Miguel",
  ),
  const MenudoTransaction(
    id: 4,
    dateString: "2026-03-07",
    desc: "Cena en SBG",
    catKey: "comida",
    categoryId: 2,
    monto: -4000,
    tipo: "gasto",
    icono: LucideIcons.wine,
    moneda: 'DOP',
    userName: "Sarah",
  ),
  const MenudoTransaction(
    id: 5,
    dateString: "2026-03-07",
    desc: "Uber a casa",
    catKey: "transporte",
    categoryId: 3,
    monto: -450,
    tipo: "gasto",
    icono: LucideIcons.car,
    moneda: 'DOP',
    userName: "Sarah",
  ),
  const MenudoTransaction(
    id: 6,
    dateString: "2026-03-07",
    desc: "Netflix Múltiple",
    catKey: "estiloVida",
    categoryId: 4,
    monto: -750,
    tipo: "gasto",
    icono: LucideIcons.tv,
    moneda: 'DOP',
    userName: "Miguel",
  ),
  const MenudoTransaction(
    id: 7,
    dateString: "2026-03-04",
    desc: "Farmacia Carol",
    catKey: "salud",
    categoryId: 5,
    monto: -1200,
    tipo: "gasto",
    icono: LucideIcons.pill,
    moneda: 'DOP',
    userName: "Sarah",
  ),
  const MenudoTransaction(
    id: 8,
    dateString: "2026-03-06",
    desc: "Libro programación",
    catKey: "educacion",
    categoryId: 6,
    monto: -850,
    tipo: "gasto",
    icono: LucideIcons.bookOpen,
    moneda: 'DOP',
    userName: "Miguel",
  ),
  const MenudoTransaction(
    id: 9,
    dateString: "2026-03-02",
    desc: "Spotify Premium",
    catKey: "entretenimiento",
    categoryId: 7,
    monto: -350,
    tipo: "gasto",
    icono: LucideIcons.music,
    moneda: 'DOP',
    userName: "Sarah",
  ),
];

final List<RecurringTransaction> mockRecurring = [
  const RecurringTransaction(
    id: 1,
    desc: "Salario BHD León",
    catKey: "ingreso",
    monto: 85000,
    tipo: "ingreso",
    icono: LucideIcons.landmark,
    frecuencia: "mensual",
    diaEjecucion: 1,
    nota: "Nómina mensual automática",
  ),
  const RecurringTransaction(
    id: 2,
    desc: "Pago alquiler",
    catKey: "vivienda",
    monto: 25000,
    tipo: "gasto",
    icono: LucideIcons.home,
    frecuencia: "mensual",
    diaEjecucion: 1,
  ),
  const RecurringTransaction(
    id: 3,
    desc: "Netflix Múltiple",
    catKey: "entretenimiento",
    monto: 750,
    tipo: "gasto",
    icono: LucideIcons.tv,
    frecuencia: "mensual",
    diaEjecucion: 7,
  ),
  const RecurringTransaction(
    id: 4,
    desc: "Spotify Premium",
    catKey: "entretenimiento",
    monto: 350,
    tipo: "gasto",
    icono: LucideIcons.music,
    frecuencia: "mensual",
    diaEjecucion: 2,
    activo: false,
  ),
];

// ── Mock categories (parent + subcategories) ─────────────────────────────────
// Parents: categoriaParadreId = null
// Subcategories: categoriaParadreId = parent id
final List<MenudoCategory> mockCategories = [
  // ── Parents ──────────────────────────────────────────────────────────────
  const MenudoCategory(
    id: 8,
    slug: 'ingreso',
    nombre: 'Ingresos',
    tipo: 'ingreso',
    icono: LucideIcons.trendingUp,
    color: Color(0xFF10B981),
    esSistema: true,
  ),
  const MenudoCategory(
    id: 1,
    slug: 'vivienda',
    nombre: 'Vivienda',
    icono: LucideIcons.home,
    color: Color(0xFF065F46),
    esSistema: true,
  ),
  const MenudoCategory(
    id: 2,
    slug: 'comida',
    nombre: 'Comida',
    icono: LucideIcons.utensils,
    color: Color(0xFFF97316),
    esSistema: true,
  ),
  const MenudoCategory(
    id: 3,
    slug: 'transporte',
    nombre: 'Transporte',
    icono: LucideIcons.car,
    color: Color(0xFF7C3AED),
    esSistema: true,
  ),
  const MenudoCategory(
    id: 4,
    slug: 'estiloVida',
    nombre: 'Estilo de Vida',
    icono: LucideIcons.sparkles,
    color: Color(0xFFEC4899),
    esSistema: true,
  ),
  const MenudoCategory(
    id: 5,
    slug: 'salud',
    nombre: 'Salud',
    icono: LucideIcons.pill,
    color: Color(0xFFEF4444),
    esSistema: true,
  ),
  const MenudoCategory(
    id: 6,
    slug: 'educacion',
    nombre: 'Educacion',
    icono: LucideIcons.bookOpen,
    color: Color(0xFF3B82F6),
    esSistema: true,
  ),
  const MenudoCategory(
    id: 7,
    slug: 'entretenimiento',
    nombre: 'Entretenimiento',
    icono: LucideIcons.tv,
    color: Color(0xFF8B5CF6),
    esSistema: true,
  ),
  const MenudoCategory(
    id: 9,
    slug: 'transferencia',
    nombre: 'Transferencia',
    tipo: 'transferencia',
    icono: LucideIcons.arrowLeftRight,
    color: Color(0xFF6B7280),
    esSistema: true,
  ),

  // ── Ingresos subcategories (padre=8) ────────────────────────────────────
  const MenudoCategory(
    id: 20,
    slug: 'salario',
    nombre: 'Salario',
    tipo: 'ingreso',
    icono: LucideIcons.briefcase,
    color: Color(0xFF10B981),
    esSistema: true,
    categoriaParadreId: 8,
  ),
  const MenudoCategory(
    id: 21,
    slug: 'freelance',
    nombre: 'Freelance',
    tipo: 'ingreso',
    icono: LucideIcons.laptop,
    color: Color(0xFF10B981),
    esSistema: true,
    categoriaParadreId: 8,
  ),
  const MenudoCategory(
    id: 22,
    slug: 'inversiones',
    nombre: 'Inversiones',
    tipo: 'ingreso',
    icono: LucideIcons.barChart2,
    color: Color(0xFF10B981),
    esSistema: true,
    categoriaParadreId: 8,
  ),
  const MenudoCategory(
    id: 23,
    slug: 'negocio',
    nombre: 'Negocio',
    tipo: 'ingreso',
    icono: LucideIcons.store,
    color: Color(0xFF10B981),
    esSistema: true,
    categoriaParadreId: 8,
  ),
  const MenudoCategory(
    id: 24,
    slug: 'bono',
    nombre: 'Bono',
    tipo: 'ingreso',
    icono: LucideIcons.gift,
    color: Color(0xFF10B981),
    esSistema: true,
    categoriaParadreId: 8,
  ),

  // ── Vivienda subcategories (padre=1) ────────────────────────────────────
  const MenudoCategory(
    id: 25,
    slug: 'alquiler',
    nombre: 'Alquiler',
    icono: LucideIcons.keySquare,
    color: Color(0xFF065F46),
    esSistema: true,
    categoriaParadreId: 1,
  ),
  const MenudoCategory(
    id: 26,
    slug: 'electricidad',
    nombre: 'Electricidad',
    icono: LucideIcons.zap,
    color: Color(0xFF065F46),
    esSistema: true,
    categoriaParadreId: 1,
  ),
  const MenudoCategory(
    id: 27,
    slug: 'agua',
    nombre: 'Agua',
    icono: LucideIcons.droplets,
    color: Color(0xFF065F46),
    esSistema: true,
    categoriaParadreId: 1,
  ),
  const MenudoCategory(
    id: 28,
    slug: 'internet',
    nombre: 'Internet',
    icono: LucideIcons.wifi,
    color: Color(0xFF065F46),
    esSistema: true,
    categoriaParadreId: 1,
  ),
  const MenudoCategory(
    id: 29,
    slug: 'seguros',
    nombre: 'Seguros',
    icono: LucideIcons.shield,
    color: Color(0xFF065F46),
    esSistema: true,
    categoriaParadreId: 1,
  ),
  const MenudoCategory(
    id: 30,
    slug: 'mantenimiento',
    nombre: 'Mantenimiento',
    icono: LucideIcons.wrench,
    color: Color(0xFF065F46),
    esSistema: true,
    categoriaParadreId: 1,
  ),

  // ── Comida subcategories (padre=2) ──────────────────────────────────────
  const MenudoCategory(
    id: 31,
    slug: 'restaurante',
    nombre: 'Restaurante',
    icono: LucideIcons.utensils,
    color: Color(0xFFF97316),
    esSistema: true,
    categoriaParadreId: 2,
  ),
  const MenudoCategory(
    id: 32,
    slug: 'supermercado',
    nombre: 'Supermercado',
    icono: LucideIcons.shoppingCart,
    color: Color(0xFFF97316),
    esSistema: true,
    categoriaParadreId: 2,
  ),
  const MenudoCategory(
    id: 33,
    slug: 'cafe',
    nombre: 'Café',
    icono: LucideIcons.coffee,
    color: Color(0xFFF97316),
    esSistema: true,
    categoriaParadreId: 2,
  ),
  const MenudoCategory(
    id: 34,
    slug: 'delivery',
    nombre: 'Delivery',
    icono: LucideIcons.package,
    color: Color(0xFFF97316),
    esSistema: true,
    categoriaParadreId: 2,
  ),

  // ── Transporte subcategories (padre=3) ──────────────────────────────────
  const MenudoCategory(
    id: 35,
    slug: 'gasolina',
    nombre: 'Gasolina',
    icono: LucideIcons.fuel,
    color: Color(0xFF7C3AED),
    esSistema: true,
    categoriaParadreId: 3,
  ),
  const MenudoCategory(
    id: 36,
    slug: 'taxi',
    nombre: 'Taxi / Uber',
    icono: LucideIcons.car,
    color: Color(0xFF7C3AED),
    esSistema: true,
    categoriaParadreId: 3,
  ),
  const MenudoCategory(
    id: 37,
    slug: 'transito',
    nombre: 'Tránsito',
    icono: LucideIcons.bus,
    color: Color(0xFF7C3AED),
    esSistema: true,
    categoriaParadreId: 3,
  ),
  const MenudoCategory(
    id: 38,
    slug: 'avion',
    nombre: 'Avión',
    icono: LucideIcons.plane,
    color: Color(0xFF7C3AED),
    esSistema: true,
    categoriaParadreId: 3,
  ),

  // ── Estilo de Vida subcategories (padre=4) ──────────────────────────────
  const MenudoCategory(
    id: 39,
    slug: 'ropa',
    nombre: 'Ropa',
    icono: LucideIcons.shirt,
    color: Color(0xFFEC4899),
    esSistema: true,
    categoriaParadreId: 4,
  ),
  const MenudoCategory(
    id: 40,
    slug: 'belleza',
    nombre: 'Belleza',
    icono: LucideIcons.sparkles,
    color: Color(0xFFEC4899),
    esSistema: true,
    categoriaParadreId: 4,
  ),
  const MenudoCategory(
    id: 41,
    slug: 'suscripciones',
    nombre: 'Suscripciones',
    icono: LucideIcons.creditCard,
    color: Color(0xFFEC4899),
    esSistema: true,
    categoriaParadreId: 4,
  ),
  const MenudoCategory(
    id: 42,
    slug: 'mascotas',
    nombre: 'Mascotas',
    icono: LucideIcons.heart,
    color: Color(0xFFEC4899),
    esSistema: true,
    categoriaParadreId: 4,
  ),

  // ── Salud subcategories (padre=5) ───────────────────────────────────────
  const MenudoCategory(
    id: 43,
    slug: 'farmacia',
    nombre: 'Farmacia',
    icono: LucideIcons.pill,
    color: Color(0xFFEF4444),
    esSistema: true,
    categoriaParadreId: 5,
  ),
  const MenudoCategory(
    id: 44,
    slug: 'medico',
    nombre: 'Médico',
    icono: LucideIcons.stethoscope,
    color: Color(0xFFEF4444),
    esSistema: true,
    categoriaParadreId: 5,
  ),
  const MenudoCategory(
    id: 45,
    slug: 'dentista',
    nombre: 'Dentista',
    icono: LucideIcons.smile,
    color: Color(0xFFEF4444),
    esSistema: true,
    categoriaParadreId: 5,
  ),
  const MenudoCategory(
    id: 46,
    slug: 'gimnasio',
    nombre: 'Gimnasio',
    icono: LucideIcons.dumbbell,
    color: Color(0xFFEF4444),
    esSistema: true,
    categoriaParadreId: 5,
  ),

  // ── Educacion subcategories (padre=6) ───────────────────────────────────
  const MenudoCategory(
    id: 47,
    slug: 'cursos',
    nombre: 'Cursos',
    icono: LucideIcons.monitorPlay,
    color: Color(0xFF3B82F6),
    esSistema: true,
    categoriaParadreId: 6,
  ),
  const MenudoCategory(
    id: 48,
    slug: 'libros',
    nombre: 'Libros',
    icono: LucideIcons.book,
    color: Color(0xFF3B82F6),
    esSistema: true,
    categoriaParadreId: 6,
  ),
  const MenudoCategory(
    id: 49,
    slug: 'universidad',
    nombre: 'Universidad',
    icono: LucideIcons.graduationCap,
    color: Color(0xFF3B82F6),
    esSistema: true,
    categoriaParadreId: 6,
  ),

  // ── Entretenimiento subcategories (padre=7) ─────────────────────────────
  const MenudoCategory(
    id: 50,
    slug: 'cine',
    nombre: 'Cine',
    icono: LucideIcons.film,
    color: Color(0xFF8B5CF6),
    esSistema: true,
    categoriaParadreId: 7,
  ),
  const MenudoCategory(
    id: 51,
    slug: 'concierto',
    nombre: 'Concierto',
    icono: LucideIcons.music,
    color: Color(0xFF8B5CF6),
    esSistema: true,
    categoriaParadreId: 7,
  ),
  const MenudoCategory(
    id: 52,
    slug: 'viajes',
    nombre: 'Viajes',
    icono: LucideIcons.map,
    color: Color(0xFF8B5CF6),
    esSistema: true,
    categoriaParadreId: 7,
  ),
  const MenudoCategory(
    id: 53,
    slug: 'juegos',
    nombre: 'Juegos',
    icono: LucideIcons.gamepad2,
    color: Color(0xFF8B5CF6),
    esSistema: true,
    categoriaParadreId: 7,
  ),
];

// ==========================================
// LEGACY SHIMS (TO PREVENT COMPILATION ERRORS DURING REFACTOR)
// ==========================================

enum AssetCategory {
  cash('Cash', '💵', AppColors.categoryCash, Icons.account_balance_wallet),
  investments(
    'Inversiones',
    '📈',
    AppColors.categoryInvestments,
    Icons.trending_up,
  ),
  crypto('Crypto', '₿', AppColors.categoryCrypto, Icons.currency_bitcoin),
  realEstate(
    'Bienes Raíces',
    '🏠',
    AppColors.categoryRealEstate,
    Icons.home_work,
  ),
  vehicles('Vehículos', '🚗', AppColors.categoryVehicles, Icons.directions_car),
  bankAccounts(
    'Cuentas Bancarias',
    '🏦',
    AppColors.categoryBankAccounts,
    Icons.account_balance,
  );

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
    required this.id,
    required this.name,
    required this.institution,
    required this.category,
    required this.currentValue,
    required this.previousValue,
    this.currency = 'DOP',
    this.sparklineData = const [],
    this.tickerSymbol,
    this.lastSynced,
  });

  double get variation => currentValue - previousValue;
  double get variationPercent => previousValue != 0
      ? ((currentValue - previousValue) / previousValue) * 100
      : 0;
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

enum RiskLevel {
  low('Bajo', AppColors.positive),
  medium('Medio', AppColors.accentBright),
  high('Alto', AppColors.negative);

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
  const ExpenseCategory({
    required this.name,
    required this.amount,
    required this.previousAmount,
    required this.color,
    required this.icon,
  });
}
