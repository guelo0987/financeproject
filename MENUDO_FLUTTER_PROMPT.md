# Menudo — Flutter Frontend Prompt
> Prompt completo para construir toda la UI de la app en Flutter.
> Pega cada sección al modelo al construir módulo por módulo.

---

## PARTE 1 — DESIGN SYSTEM (Leer primero, siempre)

```
Build the complete design system for "Menudo", a personal finance iOS app
for the Dominican Republic market. This design system must be defined as
reusable Flutter theme constants before any screen is built.

APP NAME: Menudo
PLATFORM: iOS-first Flutter (also works on Android)

═══════════════════════════════════════════
COLOR PALETTE
═══════════════════════════════════════════

Define all colors in a MenudoColors abstract class:

// Backgrounds
static const Color appBg         = Color(0xFFFFFFFF);   // Pure white — main background
static const Color cardBg        = Color(0xFF065F46);   // Emerald 800 — hero cards
static const Color cardElevated  = Color(0xFF064E3B);   // Emerald 900 — elevated cards
static const Color surfaceMuted  = Color(0xFFF0FDF4);   // Emerald 50 — subtle sections

// Text
static const Color textMain      = Color(0xFF022C22);   // Emerald 950 — primary text
static const Color textSecondary = Color(0xFF047857);   // Emerald 700 — secondary text
static const Color textMuted     = Color(0xFF6EE7B7);   // Emerald 300 — muted on dark cards
static const Color textOnDark    = Color(0xFFFFFFFF);   // White — text on green cards
static const Color textOnDarkSub = Color(0xFFA7F3D0);   // Emerald 200 at 80% — subtitles on green

// Primary accent
static const Color primary       = Color(0xFFF97316);   // Orange 500 — CTAs, highlights
static const Color primaryLight  = Color(0xFFFED7AA);   // Orange 200 — icon backgrounds
static const Color primaryDark   = Color(0xFFEA580C);   // Orange 600 — hover/pressed state
static const Color primaryGlow   = Color(0x4DF97316);   // Orange 500 at 30% — shadows/glow

// Semantic
static const Color success       = Color(0xFF059669);   // Emerald 600 — gains, income
static const Color successLight  = Color(0xFFD1FAE5);   // Emerald 100 — success bg
static const Color danger        = Color(0xFFF43F5E);   // Rose 500 — losses, debt
static const Color dangerLight   = Color(0xFFFFE4E6);   // Rose 100 — danger bg
static const Color warning       = Color(0xFFF59E0B);   // Amber 500 — alerts
static const Color warningLight  = Color(0xFFFEF3C7);   // Amber 100 — warning bg

// Borders & dividers
static const Color border        = Color(0xFFE5E7EB);   // Gray 200 — card borders
static const Color borderActive  = Color(0xFFF97316);   // Orange 500 — focused inputs
static const Color divider       = Color(0xFFF3F4F6);   // Gray 100 — list dividers

// Tab bar
static const Color tabActive     = Color(0xFF065F46);   // Emerald 800 — active tab
static const Color tabInactive   = Color(0xFF9CA3AF);   // Gray 400 — inactive tab

═══════════════════════════════════════════
TYPOGRAPHY
═══════════════════════════════════════════

Font family: SF Pro Display / SF Pro Text (use .SF UI Display via iOS system font)
Flutter: Use GoogleFonts.plusJakartaSans() as cross-platform fallback.

Define MenudoTextStyles abstract class:

// Display — hero numbers and large amounts
static TextStyle heroAmount = TextStyle(
  fontSize: 40, fontWeight: FontWeight.w700,
  letterSpacing: -1.5, color: MenudoColors.textOnDark
);

// Headlines
static TextStyle h1 = TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5);
static TextStyle h2 = TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.3);
static TextStyle h3 = TextStyle(fontSize: 18, fontWeight: FontWeight.w600);

// Body
static TextStyle bodyLarge  = TextStyle(fontSize: 16, fontWeight: FontWeight.w500);
static TextStyle bodyMedium = TextStyle(fontSize: 14, fontWeight: FontWeight.w400);
static TextStyle bodySmall  = TextStyle(fontSize: 12, fontWeight: FontWeight.w400);

// Labels
static TextStyle labelCaps = TextStyle(
  fontSize: 11, fontWeight: FontWeight.w600,
  letterSpacing: 0.8, // uppercase feel
);
static TextStyle labelBold = TextStyle(fontSize: 13, fontWeight: FontWeight.w700);
static TextStyle amountMedium = TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.5);
static TextStyle amountSmall  = TextStyle(fontSize: 14, fontWeight: FontWeight.w600);

═══════════════════════════════════════════
SPACING & GEOMETRY
═══════════════════════════════════════════

class MenudoSpacing {
  static const double xs   = 4;
  static const double sm   = 8;
  static const double md   = 12;
  static const double base = 16;
  static const double lg   = 20;
  static const double xl   = 24;
  static const double xxl  = 32;
  static const double screen = 20; // horizontal screen padding
}

class MenudoRadius {
  static const double sm     = 10;
  static const double md     = 14;
  static const double lg     = 20;
  static const double xl     = 24;
  static const double xxl    = 28;  // bottom sheets
  static const double card   = 24;  // asset cards
  static const double hero   = 28;  // hero card
  static const double pill   = 100; // pill buttons/chips
  static const double avatar = 100; // circles
}

═══════════════════════════════════════════
SHADOWS
═══════════════════════════════════════════

// Primary button shadow (orange glow)
BoxShadow primaryShadow = BoxShadow(
  color: Color(0x40F97316),
  blurRadius: 20,
  offset: Offset(0, 8),
);

// Card shadow
BoxShadow cardShadow = BoxShadow(
  color: Color(0x0F000000),
  blurRadius: 24,
  offset: Offset(0, 4),
);

// Hero card inner shadow — subtle depth
BoxShadow heroShadow = BoxShadow(
  color: Color(0x30000000),
  blurRadius: 40,
  offset: Offset(0, 12),
);

═══════════════════════════════════════════
REUSABLE COMPONENTS TO BUILD
═══════════════════════════════════════════

1. MenudoPrimaryButton — full width, orange, with orange glow shadow, scale on press
2. MenudoSecondaryButton — transparent, orange border
3. MenudoCard — white card with border and cardShadow, rounded 24px
4. MenudoHeroCard — emerald 800 background, white text, decorative elements
5. MenudoAssetRow — icon + name + subtitle + amount row with press state
6. MenudoChip — pill shaped label (success/danger/warning/neutral variants)
7. MenudoTextField — white bg, gray border, orange focus, rounded 14px
8. MenudoSegmentedControl — tabs with emerald active state
9. MenudoBottomSheet — slide-up sheet, white, top radius 28px, drag handle
10. MenudoSkeleton — shimmer loading placeholder
11. MenudoBadge — small colored indicator dot + count
12. MenudoSectionHeader — uppercase label + optional "Ver todo" orange link

═══════════════════════════════════════════
ANIMATIONS & MICRO-INTERACTIONS
═══════════════════════════════════════════

- Button press: ScaleTransition to 0.96, spring back. Duration 150ms.
- Screen entry: FadeTransition + SlideTransition from bottom (20px), 300ms ease-out
- Tab switch: AnimatedSwitcher with fade + slight vertical slide
- Amount counter: Animate numbers with CountUp effect (TweenAnimationBuilder on double)
- Bottom sheet: BottomSheet with spring animation (curves: Curves.easeOutCubic)
- Skeleton shimmer: Use shimmer package or custom AnimationController with gradient sweep
- Asset row tap: Color transition to surfaceMuted (emerald 50), 100ms
- Success state: Brief green pulse overlay (opacity animation 0→0.3→0)

═══════════════════════════════════════════
FLUTTER PACKAGES TO USE
═══════════════════════════════════════════

dependencies:
  flutter:
    sdk: flutter
  google_fonts: ^6.1.0          # Typography (Plus Jakarta Sans)
  fl_chart: ^0.66.0             # Charts (line, bar, pie/donut)
  shimmer: ^3.0.0               # Loading skeletons
  go_router: ^12.0.0            # Navigation
  flutter_animate: ^4.3.0       # Declarative animations
  intl: ^0.19.0                 # Number/date formatting (RD$ formatting)
  provider: ^6.1.0              # State management (or riverpod)
  http: ^1.2.0                  # API calls
  flutter_secure_storage: ^9.0.0 # JWT storage in iOS Keychain
  local_auth: ^2.1.8            # Face ID / Touch ID
  purchases_flutter: ^6.0.0     # RevenueCat SDK
  cached_network_image: ^3.3.0  # Avatar/image caching
  haptic_feedback: ^0.0.3       # Haptics

```

---

## PARTE 2 — NAVEGACIÓN Y ESTRUCTURA

```
Build the main navigation structure for Menudo Flutter app.

Use go_router for navigation. The app has two navigation zones:

ZONE 1 — AUTH FLOW (no bottom nav):
Routes:
  /splash          → SplashScreen
  /onboarding      → OnboardingScreen (3 pages)
  /auth/register   → RegisterScreen
  /auth/login      → LoginScreen

ZONE 2 — MAIN APP (with bottom nav):
Shell route with persistent BottomNavigationBar.
Routes:
  /home            → HomeScreen (Dashboard)
  /activos         → ActivosScreen (Assets list)
  /registrar       → RegisterTransactionSheet (modal, not a tab destination)
  /analisis        → AnalisisScreen (Analytics)
  /perfil          → PerfilScreen (Profile)

BOTTOM NAVIGATION BAR:
Build as a custom widget MenudoBottomNav.

Style:
- Background: white
- Top border: 1px solid Color(0xFFE5E7EB)
- Height: 80px (includes safe area padding)
- 5 items: Inicio, Activos, [FAB center], Análisis, Perfil

Items:
  1. Inicio    — Icon: home (filled when active)
  2. Activos   — Icon: chart.bar (filled when active)  
  3. CENTER    — FAB: 56px orange circle with + icon, NO label, elevated with orange shadow
                 OnTap: shows RegisterTransactionSheet as modal bottom sheet
  4. Análisis  — Icon: chart.pie (filled when active)
  5. Perfil    — Icon: person.circle (filled when active)

Active state: icon color = MenudoColors.tabActive (emerald 800) + label in same color, weight 700
Inactive state: icon + label color = MenudoColors.tabInactive (gray 400), weight 500
Center FAB: always orange, always elevated, scale animation on tap

Label font size: 10px, weight 600 for active, 500 for inactive.

APP BAR PATTERN:
Most screens use a custom app bar (not Flutter's default AppBar).
Build as MenudoAppBar widget with:
- White background, no elevation
- Title: screen name in h3 style left-aligned
- Or for Home: greeting "¡Hola, [nombre]! 👋" + "Menudo" title
- Right slot: optional icon button (notifications, settings, etc.)
- Safe area aware (respects iOS status bar)
```

---

## PARTE 3 — PANTALLA HOME (Dashboard)

```
Build the HomeScreen for Menudo Flutter app.

This is the main screen. SingleChildScrollView with Column layout.
Background: white. Horizontal padding: 20px throughout.

═══════════════════════════════
HEADER SECTION
═══════════════════════════════

Row with space between:
LEFT:
  Column:
    Text("¡Hola, Marcos! 👋", style: bodyMedium, color: textMuted)
    Text("Menudo", style: h1, color: textMain)
RIGHT:
  Stack — CircleAvatar (40px, gray bg) with a 2px emerald border
  If unread notifications: small red dot badge top-right of avatar (8px)
  OnTap avatar → go to PerfilScreen

Bottom of header: small text "Martes, 7 de Marzo · 2026" in labelCaps, textMuted

═══════════════════════════════
HERO CARD — PATRIMONIO NETO
═══════════════════════════════

Container with:
  decoration: BoxDecoration(
    color: MenudoColors.cardBg,   // Emerald 800
    borderRadius: BorderRadius.circular(MenudoRadius.hero),
    boxShadow: [MenudoShadows.heroShadow],
  )
  padding: 24px all sides

INSIDE HERO CARD:
Top-right: decorative element — PieChart icon at 120px size, opacity 0.08, white color, 
           positioned with Positioned widget (right -20, top -20), overflow hidden

Content (relative z-index above decoration):

Row: 
  Left: Column:
    Text("PATRIMONIO TOTAL", style: labelCaps, color: textOnDarkSub)
    SizedBox(height: 4)
    Row: // The big number
      Text("RD\$", style: TextStyle(fontSize: 20, color: textOnDarkSub, fontWeight: w600))
      Text("45,230", style: heroAmount, color: textOnDark)  // animated with CountUp
      Text(".00", style: TextStyle(fontSize: 22, color: textOnDark.withOpacity(0.5)))
  Right: Nothing (or small settings gear)

SizedBox(height: 16)

Row:
  // Green growth chip
  Container(
    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(100),
    ),
    child: Row:
      Icon(ArrowUpward, size: 14, color: Color(0xFF6EE7B7))  // mint green
      Text("+12.5% este año", style: labelBold, color: Color(0xFF6EE7B7))
  )
  SizedBox(width: 8)
  Text("Buen ritmo 🔥", style: bodySmall, color: textOnDarkSub)

SizedBox(height: 20)

// Mini sparkline chart (last 6 months trend)
SizedBox(height: 48):
  fl_chart LineChart — no axes, no labels, just the curve
  Line color: white at 70% opacity
  Fill below: white at 10% opacity
  Smooth curve (isCurved: true)
  Data: placeholder values showing upward trend

═══════════════════════════════
QUICK ACTION BUTTON
═══════════════════════════════

SizedBox(height: 16)

MenudoPrimaryButton(
  label: "Registrar Gasto",
  icon: Icons.add,
  onTap: () => showModalBottomSheet(RegisterTransactionSheet),
)
// Full width, orange, with orange glow shadow
// ScaleTransition on press

═══════════════════════════════
FLUJO DEL MES CARD
═══════════════════════════════

SizedBox(height: 24)
Row: Text("Flujo del mes", h3) + TextButton("Ver análisis →", orange)

MenudoCard(
  child: Row with 3 equal columns:
  
  Column 1 — INGRESOS:
    Container(color: successLight, 4px wide, 36px height) // colored left bar
    SizedBox(width: 8)
    Column:
      Text("INGRESOS", labelCaps, textMuted)
      Text("RD\$95K", amountMedium, success)
      Text("+5% vs feb", bodySmall, success)
  
  Vertical divider (1px, gray 100)
  
  Column 2 — GASTOS:
    Same pattern, color: danger, amount: "RD\$58K"
  
  Vertical divider
  
  Column 3 — AHORRO:
    Same pattern, color: primary (orange), amount: "RD\$37K"
    Text("38.6% tasa", bodySmall, textMuted)
)

═══════════════════════════════
MIS ACTIVOS (horizontal scroll)
═══════════════════════════════

SizedBox(height: 24)
Row: Text("Mis activos", h3) + TextButton("Ver todos →", orange)
SizedBox(height: 12)

// Horizontal scroll of asset pills
SizedBox(height: 88):
  ListView.separated horizontal:
    Each AssetPill (see component below)
    Items: BHD León, Bitcoin, QQQ, Apto. Naco

ASSET PILL component:
Container(
  width: 160,
  padding: 16px,
  decoration: BoxDecoration(
    color: white,
    border: Border.all(color: MenudoColors.border),
    borderRadius: BorderRadius.circular(20),
    boxShadow: [cardShadow light],
  )
  Column:
    Row:
      CircleAvatar(radius: 16, backgroundColor: [asset type color at 20%], child: Icon)
      Spacer()
      Container(color: success/danger, padding pill): Text("+2.1%")
    SizedBox(height: 8)
    Text(asset name, bodyLarge bold)
    Text(value, amountSmall)
)

═══════════════════════════════
PRECIOS DE MERCADO
═══════════════════════════════

SizedBox(height: 24)
Row: Text("Mercado", h3) + Row(Icon(refresh, 14px, textMuted), Text("hace 3 min", bodySmall, textMuted))

MenudoCard(
  child: GridView 2x2:
  
  MarketItem:
    Row:
      Column: Text(ticker bold), Text(name muted small)
      Spacer()
      Column(crossAxis: end):
        Text(price, amountSmall bold)
        MenudoChip(change%, success/danger variant)
  
  Items:
    BTC: "$67,420" "-2.1%"
    ETH: "$3,840"  "+1.4%"  
    QQQ: "$487.32" "+0.8%"
    XAU: "$2,310"  "+0.3%"
    
  Dividers between items: thin gray lines
)

═══════════════════════════════
TASA DE CAMBIO BANNER
═══════════════════════════════

MenudoCard with orange left border (4px):
Row:
  Column:
    Text("USD / DOP", labelCaps, textMuted)
    Row: Text("60.25", h2), SizedBox(4), MenudoChip("+0.12", success variant small)
  Spacer()
  // Mini sparkline 7 days
  SizedBox(width: 80, height: 40): LineChart small orange line

Bottom of screen: SizedBox(height: 100) to clear bottom nav
```

---

## PARTE 4 — REGISTRAR TRANSACCIÓN (Bottom Sheet)

```
Build RegisterTransactionSheet for Menudo Flutter app.

This is a DraggableScrollableSheet displayed as a modal.
Initial size: 0.92, min: 0.5, max: 0.95.
Background: white. Top corners: 28px radius.
Drag handle: centered gray bar 40x4px at top.

═══════════════════════════════
HEADER
═══════════════════════════════

Row:
  Text("Nueva transacción", h3, textMain) — centered
  IconButton(X, close sheet) — right aligned

═══════════════════════════════
AMOUNT DISPLAY
═══════════════════════════════

Center(
  child: Padding(top: 16, bottom: 8):
    Row(mainAxis: center):
      Text("RD\$", style: TextStyle(fontSize: 22, color: textMuted, fontWeight: w500))
      // Animated amount text — AnimatedSwitcher with slide+fade on digit change
      Text(amount == 0 ? "0" : formatAmount(amount),
           style: heroAmount.copyWith(color: textMain, fontSize: 52))
)

═══════════════════════════════
TYPE SELECTOR (GASTO/INGRESO/TRANSFERENCIA)
═══════════════════════════════

// Custom segmented control
Container(
  margin: horizontal 20px,
  padding: 4px all,
  decoration: BoxDecoration(
    color: Color(0xFFF0FDF4),  // emerald 50
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: Color(0xFFD1FAE5)),
  )
  Row with 3 options: GASTO | INGRESOS | TRANSFERENCIA
  
  Active tab:
    Container(
      color: MenudoColors.cardBg,  // emerald 800
      radius: 10px,
    )
    Text(white, weight 700, size 13)
    AnimatedContainer for smooth transition
  
  Inactive:
    Text(textMuted, weight 500, size 13)
)

═══════════════════════════════
DETAILS LIST
═══════════════════════════════

ListView of detail rows. Each separated by Divider(1px, gray 100).
Row height: 56px. Padding horizontal 20px.

ROW COMPONENT:
Row:
  // Left icon
  Container(40x40, radius 12, color: [category color at 15%]):
    Icon(SF-equivalent, size: 20, color: category color)
  SizedBox(12)
  // Label
  Column(crossAxis: start):
    Text(label, bodySmall, textMuted)
    Text(value, bodyLarge bold, textMain)
  Spacer()
  // Right content
  // If AI suggestion: MenudoChip("IA", primary variant, tiny)
  Icon(chevron_right, textMuted, size 18)

ROWS:
1. Categoría — icon + AI suggested category (animate blue shimmer sweep when AI fills it)
2. Desde — wallet/card icon + account name + swap icon (for transfer mode)  
3. Descripción — pencil icon + TextField inline, placeholder "Nota (opcional)"
4. Fecha — calendar icon + "Hoy" + left/right day navigation arrows
5. Repetir — cycle icon + "No repetir" → opens recurrence picker
6. Espacio — people icon + "Personal" → if user has shared spaces, shows selector

═══════════════════════════════
NUMERIC KEYPAD
═══════════════════════════════

// Custom keypad, no system keyboard
Container(
  color: Color(0xFFF9FAFB),  // Gray 50
  padding: EdgeInsets.all(16),
  child: GridView(
    crossAxis: 3,
    mainAxis: 4,
    childAspect: adaptive to fill space,
    children: [1,2,3,4,5,6,7,8,9,".",0,backspace]
  )
)

Each key:
Container(
  height: 56,
  decoration: BoxDecoration(
    color: white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: MenudoColors.border),
  )
  + InkWell with ripple
  + scale animation on tap (0.93 scale, 100ms)
)

Number keys: Text(number, h2 weight, textMain)
Backspace: Icon(backspace, textMuted)
Decimal: Text(".", h2, textMain)

═══════════════════════════════
SAVE BUTTON
═══════════════════════════════

Padding(horizontal: 16, bottom: 24 + MediaQuery.of(context).viewInsets.bottom):
  MenudoPrimaryButton(
    label: "GUARDAR",
    onTap: saveTransaction,
    isDisabled: amount == 0,
  )

State when amount > 0: orange, active
State when amount == 0: gray 200, disabled

═══════════════════════════════
RECURRENCE PICKER (sub-sheet)
═══════════════════════════════

When "Repetir" row is tapped, shows a nested bottom sheet with a ListView of options:
No repetir | Cada semana | Cada 2 semanas | Cada mes | Cada 2 meses | Cada año

Active option: emerald 800 background white text + checkmark right
Each item: 52px height, padding 20px horizontal
```

---

## PARTE 5 — MIS ACTIVOS

```
Build ActivosScreen for Menudo Flutter app.

Full screen with CustomScrollView (SliverAppBar + SliverList).

═══════════════════════════════
SLIVER APP BAR
═══════════════════════════════

SliverAppBar(
  floating: true, snap: true,
  backgroundColor: white,
  title: Text("Mis Activos", h1)
  actions: [
    IconButton(+, orange color) → AddAssetSheet
  ]
)

═══════════════════════════════
PATRIMONIO HEADER (sliver item)
═══════════════════════════════

Padding 20px horizontal:
MenudoCard:
  Row:
    Column:
      Text("PATRIMONIO TOTAL", labelCaps, textMuted)
      Text("RD\$4,827,350", heroAmount.copyWith(color: textMain, fontSize: 32))
      Text("8 activos", bodySmall, textMuted)
    Spacer()
    // Donut mini chart (fl_chart, 72px)
    PieChart with asset type colors, no labels, hole radius 0.7

SizedBox(height: 12)

// Asset type distribution bar
Column:
  Row: (full width, 8px height, radius 4px)
    Cuentas   → blue portion
    Inversiones → purple portion
    Crypto    → orange portion
    Inmuebles → green portion
    Otros     → gray portion
  Row: legend — small dots + labels

═══════════════════════════════
FILTER ROW
═══════════════════════════════

SizedBox(height: 16)
SingleChildScrollView horizontal, no scrollbar:
  Row with filter chips, spacing 8px:
  Todos | Cuentas | Crypto | Inversiones | Inmuebles | Vehículos
  
  Each chip:
    FilterChip style:
    Active: bg=emerald 800, text=white, no border
    Inactive: bg=white, text=textMain, border=gray 200

═══════════════════════════════
ASSET GROUPS
═══════════════════════════════

For each asset type group that has items:

// Group header
Padding(horizontal 20, vertical 8):
  Row:
    Text("CUENTAS BANCARIAS", labelCaps, textMuted)
    Spacer()
    Text("RD\$1,250,000", labelBold, textMain)

// Asset items in group
ListView of MenudoAssetCard:

MENUDO ASSET CARD:
Padding(horizontal 20, bottom 12):
Container(
  padding: 16px,
  decoration: BoxDecoration(
    color: white,
    borderRadius: BorderRadius.circular(MenudoRadius.card),
    border: Border.all(color: MenudoColors.border),
    boxShadow: [cardShadow],
  )
  Row:
    // Institution icon
    Container(48x48, radius 14, color: typeColor at 15%):
      Text(institution initials, weight 700, typeColor)  // or icon
    SizedBox(12)
    // Asset info
    Expanded:
      Column(crossAxis: start):
        Text(asset name, bodyLarge bold, textMain)
        Text("Cuenta bancaria · DOP", bodySmall, textMuted)
    // Values
    Column(crossAxis: end):
      Text("RD\$850,000", amountMedium, textMain)
      if change != null:
        Text("+RD\$12,000 hoy", bodySmall, success/danger)
      if ticker:
        MenudoChip(ticker, neutral variant)
)

OnTap: navigate to AssetDetailScreen

═══════════════════════════════
ADD ASSET FAB
═══════════════════════════════

FloatingActionButton(
  backgroundColor: MenudoColors.primary,
  shape: RoundedRectangleBorder(radius: 100),
  child: Row(icon +, text "Añadir activo"),
  elevation: 4,
  // Orange glow shadow
)
Position: bottom center, above bottom nav
```

---

## PARTE 6 — ANÁLISIS

```
Build AnalisisScreen for Menudo Flutter app.

SingleChildScrollView. Horizontal padding 20px. White background.

═══════════════════════════════
HEADER + MONTH SELECTOR
═══════════════════════════════

Row:
  Text("Análisis", h1)
  Spacer()
  Container(
    decoration: BoxDecoration(color: surfaceMuted, radius: pill),
    padding: horizontal 16 vertical 8,
    child: Row:
      IconButton(chevron_left, 20px)
      Text("Marzo 2026", bodyLarge bold, textMain)
      IconButton(chevron_right, 20px)
  )

═══════════════════════════════
STATS ROW
═══════════════════════════════

Row with 3 equal MenudoCard mini cards (gap 8px):

Each StatCard:
Container(
  padding: 14px,
  decoration: border radius 16px white bordered,
):
  Text(label, labelCaps, textMuted)
  SizedBox(4)
  Text(amount, amountMedium, [success/danger/primary])
  Text(comparison, bodySmall, success) // "+5% vs feb"

Items:
  INGRESOS: "RD\$95K" success
  GASTOS:   "RD\$58K" danger  
  AHORRO:   "RD\$37K" primary

═══════════════════════════════
DONUT CHART — GASTOS
═══════════════════════════════

MenudoCard:
  // Toggle
  Row:
    Text("Distribución", h3)
    Spacer()
    MenudoSegmentedControl(["GASTOS", "INGRESOS"])

  SizedBox(height: 16)

  Stack center-aligned:
    PieChart(
      fl_chart,
      sectionsSpace: 3,
      centerSpaceRadius: 72,
      sections: categories with colors,
    )
    // Center content
    Column:
      Text(largest category name, labelCaps, textMuted)
      Text(largest category amount, amountMedium, textMain)
  
  SizedBox(height: 16)
  
  // Legend (2 column grid)
  GridView(crossAxis: 2, mainAxis: adaptive):
    LegendItem:
      Row:
        Container(12x12, radius 3, color: category color)
        SizedBox(6)
        Expanded: Text(name, bodySmall)
        Text(amount, labelBold)
        Text(percentage, bodySmall, textMuted)

═══════════════════════════════
LINE CHART — EVOLUCIÓN PATRIMONIAL
═══════════════════════════════

MenudoCard:
  Row:
    Text("Evolución patrimonial", h3)
    Spacer()
    Text("+23.4% ↑", labelBold, success)

  SizedBox(8)
  Text("Últimos 6 meses", bodySmall, textMuted)

  SizedBox(height: 16)

  SizedBox(height: 180):
    LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: month abbreviations, small gray
          leftTitles: hidden
        ),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            color: MenudoColors.primary,  // orange line
            barWidth: 3,
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [orange at 30%, orange at 0%],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            ),
            dotData: FlDotData(show: false),
            // On touch: show dot + tooltip
          )
        ]
      )
    )

═══════════════════════════════
BAR CHART — FLUJO MENSUAL
═══════════════════════════════

MenudoCard:
  Text("Flujo mensual", h3)
  SizedBox(8)
  SizedBox(height: 160):
    BarChart(
      grouped bars: ingresos (emerald) + gastos (orange) per month,
      last 6 months,
      no grid, rounded bar tops (radius 4px),
      touch: show tooltip with values
    )

═══════════════════════════════
TOP CATEGORÍAS
═══════════════════════════════

Text("En qué más gastas", h3)
SizedBox(12)

For each top 5 category:
Padding(bottom 12):
Row:
  Container(40x40, radius 12, color: category color at 15%):
    Icon(category, 20px, category color)
  SizedBox(12)
  Expanded:
    Column:
      Row: Text(name, bodyLarge bold) + Spacer() + Text(amount, amountSmall)
      SizedBox(4)
      // Progress bar
      Stack:
        Container(height: 6, radius 3, color: gray 100, full width)
        FractionallySizedBox(widthFactor: percentage):
          Container(height: 6, radius 3, color: category color)
      SizedBox(2)
      Text(percentage string, bodySmall, textMuted)
```

---

## PARTE 7 — ESPACIOS COMPARTIDOS

```
Build EspaciosScreen for Menudo Flutter app.

Full screen, white background. Accessible from Perfil or dedicated tab.

═══════════════════════════════
EMPTY STATE
═══════════════════════════════

If no spaces:
Center column:
  // Illustration — two overlapping circles
  Stack(width: 120, height: 90):
    Circle(80px, color: emerald 800 at 20%)
    Positioned(left: 30): Circle(80px, color: primary at 20%)
  
  SizedBox(24)
  Text("Presupuestos compartidos", h2, textMain, textAlign: center)
  SizedBox(8)
  Text(
    "Planifica las finanzas de tu hogar,\nnegocio o grupo. Todos ven lo mismo.",
    bodyMedium, textMuted, textAlign: center
  )
  SizedBox(32)
  MenudoPrimaryButton("Crear espacio")
  SizedBox(16)
  TextButton("¿Tienes una invitación?", orange)

═══════════════════════════════
SPACE CARD (when spaces exist)
═══════════════════════════════

For each space:
MenudoCard(padding: 20):
  Row:
    // Space icon
    Container(48x48, radius 14, color: emerald 800 at 10%):
      Text(space emoji or initial, fontSize: 24)
    SizedBox(12)
    Column:
      Text(space name, h3, textMain)     // "Hogar"
      Text("2 miembros", bodySmall, textMuted)
    Spacer()
    // Member avatars stack
    SizedBox(width: 56, height: 32):
      Positioned(left: 0): CircleAvatar(28, emerald 800, "C")
      Positioned(left: 18): CircleAvatar(28, orange, "M")
  
  SizedBox(16)
  
  // Stats row
  Row (spaced evenly):
    StatColumn("INGRESOS", "RD\$95K", success)
    Divider vertical
    StatColumn("GASTOS", "RD\$58K", danger)
    Divider vertical
    StatColumn("RESTANTE", "RD\$37K", primary)
  
  SizedBox(16)
  
  // Contribution bar
  Text("Contribuciones", labelCaps, textMuted)
  SizedBox(6)
  Container(height: 8, radius: 4):
    Row:
      Flexible(flex: 62): Container(color: emerald 800)
      Flexible(flex: 38): Container(color: orange)
  Row:
    Text("Carlos 62%", bodySmall, textMuted)
    Spacer()
    Text("María 38%", bodySmall, textMuted)
  
  SizedBox(12)
  Row:
    Spacer()
    TextButton("Ver detalle →", orange)

═══════════════════════════════
SETTLE UP CARD
═══════════════════════════════

If balances uneven:
Container(
  decoration: BoxDecoration(
    color: warningLight,
    borderRadius: BorderRadius.circular(20),
    border: Border(left: BorderSide(color: warning, width: 4)),
  )
  padding: 16px,
):
  Row:
    Icon(account_balance_wallet, warning)
    SizedBox(8)
    Text("Liquidar cuentas", h3, textMain)
  SizedBox(8)
  Text("María le debe a Carlos: RD\$12,450", bodyMedium, textMain)
  TextButton("Ver cálculo completo →", orange)

═══════════════════════════════
INVITE CARD (pending)
═══════════════════════════════

Container(
  decoration: BoxDecoration(
    border: Border.all(color: gray 200, width: 1.5, style: BorderStyle.dashed? — use custom painter),
    borderRadius: BorderRadius.circular(20),
  )
):
  Row: mail icon + "Invitación pendiente de" + email
  Row: TextButton("Aceptar", success) + TextButton("Rechazar", danger)
```

---

## PARTE 8 — PERFIL Y SUSCRIPCIÓN

```
Build PerfilScreen for Menudo Flutter app.

SingleChildScrollView. Padding top: safe area + 16px.

═══════════════════════════════
USER HERO CARD
═══════════════════════════════

MenudoCard(padding: 20):
  Row:
    // Avatar
    CircleAvatar(
      radius: 32,
      backgroundColor: MenudoColors.cardBg,
      child: Text(initials, TextStyle(color: white, fontSize: 22, fontWeight: w700))
    )
    SizedBox(16)
    Expanded:
      Column:
        Text(user name, h2, textMain)
        Text(email, bodyMedium, textMuted)
    IconButton(edit icon, primary color) → EditProfileSheet
  
  SizedBox(16)
  
  // Subscription badge
  Container(
    padding: horizontal 14 vertical 8,
    decoration: BoxDecoration(
      color: isActive ? successLight : warningLight,
      borderRadius: BorderRadius.circular(100),
      border: Border.all(color: isActive ? success : warning),
    )
    Row:
      Icon(isActive ? star : timer, 16px, isActive ? success : warning)
      SizedBox(6)
      Text(isActive ? "PRO ACTIVO" : "PRUEBA · 3 días restantes",
           labelBold, isActive ? success : warning)
  )

═══════════════════════════════
META FINANCIERA CARD
═══════════════════════════════

MenudoCard:
  Row:
    Icon(flag, primary, 20px)
    SizedBox(8)
    Text("Mi meta", h3, textMain)
    Spacer()
    TextButton("Editar", orange)
  
  SizedBox(12)
  Text("Alcanzar RD\$10M para 2028", bodyLarge, textMain)
  SizedBox(12)
  
  // Progress bar
  Stack:
    Container(height: 8, radius: 4, color: gray 100, full width)
    FractionallySizedBox(widthFactor: 0.48):
      Container(height: 8, radius: 4, color: primary)
  SizedBox(6)
  Row:
    Text("RD\$4.8M de RD\$10M", bodySmall, textMuted)
    Spacer()
    Text("48%", labelBold, primary)

═══════════════════════════════
SETTINGS LIST
═══════════════════════════════

SizedBox(24)

For each section, use a settings group pattern:

SECTION HEADER:
Padding(horizontal 4, bottom 8):
  Text(section label, labelCaps, textMuted)

SETTINGS CARD (group of rows in one rounded container):
Container(
  decoration: BoxDecoration(color: white, borderRadius: 20px, border: gray),
):
  ListView of SettingsRow (no ScrollView, shrinkWrap):
  Between rows: Divider(0.5px, indent: 56px)

SETTINGS ROW:
ListTile(
  leading: Container(36x36, radius 10, color: [section color at 15%]):
    Icon(icon, [section color], 18px)
  title: Text(label, bodyLarge, textMain)
  trailing: isToggle ? Switch(activeColor: primary) : Icon(chevron_right, textMuted)
  onTap: action
)

SECTIONS:

"CUENTA" (blue icons):
  Cambiar contraseña → chevron
  Moneda principal: "RD$" → chevron → CurrencySheet
  Notificaciones → chevron → NotificationsScreen
  Exportar datos → chevron

"SUSCRIPCIÓN" (orange/gold icons):
  Plan: "Mensual · $5 USD" → chevron
  Próxima factura: "6 Apr 2026" (static, no chevron)
  Gestionar suscripción → chevron → RevenueCat flow

"SOPORTE" (gray icons):
  Centro de ayuda → chevron (launches URL)
  Enviar comentarios → chevron
  Versión 1.0.0 (no chevron, gray)

"PELIGRO" (red icons):
  Cerrar sesión → TextButton red, centered, no icon
  Eliminar cuenta → TextButton lighter red, smaller

═══════════════════════════════
UPGRADE BANNER (trial users only)
═══════════════════════════════

Shown BEFORE settings sections if user is on trial:

Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [Color(0xFF065F46), Color(0xFF047857)],  // emerald gradient
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(24),
  )
  padding: 20px,
):
  Row:
    Column:
      Text("✦ Activa tu plan", h3, white)
      SizedBox(4)
      Text("Quedan 3 días de prueba.", bodyMedium, textOnDarkSub)
    SizedBox(16)
    Container(
      padding: horizontal 16 vertical 10,
      decoration: BoxDecoration(color: primary, radius: 12px),
    ):
      Text("Activar", labelBold, white)
```

---

## PARTE 9 — ALERTAS

```
Build AlertasScreen for Menudo Flutter app.

Full screen. ListView of alert items.

═══════════════════════════════
HEADER
═══════════════════════════════

Row:
  Text("Alertas", h1)
  Spacer()
  TextButton("Marcar todo leído", orange, small)

SizedBox(16)

// Filter chips
SingleChildScrollView horizontal:
  Todos | IA Insights | Mercado | Metas | Sistema

═══════════════════════════════
ALERT ITEM
═══════════════════════════════

AlertItem widget:
Container(
  margin: EdgeInsets.only(bottom: 12),
  padding: 16px,
  decoration: BoxDecoration(
    color: isUnread ? primaryLight.withOpacity(0.3) : white,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: isUnread ? primary.withOpacity(0.3) : border),
  )
  Row:
    // Icon
    Container(44x44, radius 12, color: alertTypeColor at 15%):
      Icon(alertTypeIcon, alertTypeColor, 22px)
    SizedBox(12)
    Expanded:
      Column(crossAxis: start):
        Row:
          Expanded: Text(title, bodyLarge bold, textMain)
          // Unread dot
          if isUnread: Container(8x8, circle, primary)
        SizedBox(4)
        Text(body, bodyMedium, textSecondary, maxLines: 2, overflow: ellipsis)
        SizedBox(6)
        Row:
          Text(timeAgo, bodySmall, textMuted)
          if hasCTA: ... [CTA chip button]
)

ALERT TYPE → COLOR + ICON:
  ia_insight      → primary (orange) + auto_awesome
  mercado         → success (green) / danger (red) depending on direction + trending_up/down
  meta_progreso   → warning (amber) + emoji_events
  suscripcion     → warning (amber) + workspace_premium
  tasa_cambio     → purple (Color(0xFF7C3AED)) + currency_exchange

INLINE CTA (for suscripcion type):
  TextButton style pill:
  Container(
    padding: horizontal 12 vertical 6,
    decoration: BoxDecoration(color: primary at 15%, radius: 100px),
  ):
  Text("Activar plan", labelBold, primary)

PROGRESS BAR (for meta_progreso type):
  Below body text:
  LinearProgressIndicator(
    value: 0.48,
    backgroundColor: gray 100,
    valueColor: AlwaysStoppedAnimation(warning),
    borderRadius: BorderRadius.circular(4),
  )

═══════════════════════════════
EMPTY STATE
═══════════════════════════════

Center:
  Icon(notifications_none, 64px, gray 300)
  SizedBox(16)
  Text("Todo en orden", h2, textMain)
  SizedBox(8)
  Text("No tienes alertas nuevas.\nTe avisaremos cuando algo importante ocurra.",
       bodyMedium, textMuted, textAlign: center)
```

---

## PARTE 10 — ONBOARDING

```
Build the OnboardingFlow for Menudo Flutter app.

═══════════════════════════════
SPLASH SCREEN
═══════════════════════════════

Full screen, white background.
Center column:
  
  // Logo animation — fade in + scale from 0.8 to 1.0, 600ms
  // Logo: stylized "M" mark made of two overlapping emerald shapes
  CustomPaint or SVG:
    Two overlapping rounded rectangles at angle → forms "M"
    Left rect: MenudoColors.cardBg (emerald 800)
    Right rect: MenudoColors.primary (orange)
    Overlap: blended
    Size: 72x72px
  
  SizedBox(16)
  Text("Menudo", style: TextStyle(fontSize: 32, fontWeight: w700, color: textMain, letterSpacing: -1))
  SizedBox(8)
  Text("Tu patrimonio. Todo en un lugar.", bodyMedium, textMuted)

After 2.5s: fade out → OnboardingScreen

═══════════════════════════════
ONBOARDING PAGES (3 pages)
═══════════════════════════════

PageView with 3 pages. Each full screen white.

Bottom fixed section (all pages):
  // Page indicators
  Row(center): 3 dots, active = 10px wide pill emerald, inactive = 6px circle gray
  SizedBox(16)
  // Next/Final button
  MenudoPrimaryButton(label: page < 2 ? "Siguiente" : "Comenzar gratis")
  SizedBox(12)
  if page == 2:
    TextButton("Ya tengo cuenta — Iniciar sesión", textMuted)

PAGE 1 — PATRIMONIO:
Top 50%: Large illustration area (lottie or custom paint)
  Illustration: simple geometric — circles representing coins/assets stacking up
  Colors: emerald + orange + white
Bottom 50%:
  Text("Todo tu dinero,\nen un solo lugar.", h1, textMain)
  SizedBox(12)
  Text("Cuentas, crypto, inversiones y más.", bodyLarge, textMuted)

PAGE 2 — ANÁLISIS:
Top: Chart illustration (bars going up, emerald color)
Text("Entiende en qué\ngastas tu dinero.")
Subtitle: "Análisis inteligente con IA incluida."

PAGE 3 — COMPARTIR:
Top: Two circles overlapping illustration
Text("Planifica con\ntu familia o pareja.")
Subtitle: "Espacios compartidos en tiempo real."

═══════════════════════════════
REGISTER SCREEN
═══════════════════════════════

Full screen or bottom sheet (90% height).
White background.

Title: Text("Crear cuenta", h1, textMain) — top of form
SizedBox(8)
Text("5 días gratis, luego $5 USD/mes", bodyMedium, success)
SizedBox(32)

Form fields (gap 16px between):
MenudoTextField(label: "Nombre completo", hint: "Carlos Rodríguez", keyboardType: name)
MenudoTextField(label: "Correo electrónico", hint: "carlos@email.com", keyboardType: email)
MenudoTextField(label: "Contraseña", hint: "Mínimo 8 caracteres", obscureText: true, 
                trailing: show/hide toggle)

SizedBox(16)

// Currency selector
Text("Moneda principal", bodyMedium, textMuted)
SizedBox(8)
Row:
  CurrencyOption("RD$", isSelected, onTap)  // left option
  SizedBox(12)
  CurrencyOption("US$", !isSelected, onTap) // right option

CurrencyOption:
Container(
  padding: all 16,
  flex: 1,
  decoration: BoxDecoration(
    color: isSelected ? emerald 800 at 10% : white,
    border: Border.all(color: isSelected ? emerald 800 : gray 200, width: isSelected ? 2 : 1),
    borderRadius: BorderRadius.circular(16),
  )
  Row: Icon + Text(currency) + if selected: Icon(check, emerald)
)

SizedBox(32)
MenudoPrimaryButton("Crear mi cuenta")
SizedBox(16)

// Divider with text
Row: Divider + Text("o continúa con") + Divider

SizedBox(16)
AppleSignInButton() — use sign_in_with_apple package, standard black Apple button
```

---

## NOTAS FINALES PARA EL DESARROLLADOR

```
ESTRUCTURA DE CARPETAS RECOMENDADA:
lib/
├── main.dart
├── core/
│   ├── theme/
│   │   ├── colors.dart        ← MenudoColors
│   │   ├── typography.dart    ← MenudoTextStyles
│   │   ├── spacing.dart       ← MenudoSpacing, MenudoRadius
│   │   └── shadows.dart       ← MenudoShadows
│   ├── widgets/
│   │   ├── menudo_button.dart
│   │   ├── menudo_card.dart
│   │   ├── menudo_chip.dart
│   │   ├── menudo_text_field.dart
│   │   ├── menudo_skeleton.dart
│   │   └── menudo_bottom_nav.dart
│   └── utils/
│       └── formatters.dart    ← RD$ number formatting
├── features/
│   ├── auth/
│   ├── home/
│   ├── activos/
│   ├── transacciones/
│   ├── analisis/
│   ├── espacios/
│   ├── alertas/
│   └── perfil/
└── router.dart

FORMATEO DE MONEDA:
// Use intl package
final rdFormat = NumberFormat.currency(locale: 'es_DO', symbol: 'RD\$', decimalDigits: 0);
final usdFormat = NumberFormat.currency(locale: 'en_US', symbol: 'US\$', decimalDigits: 2);

RD$1,234,567    // thousands separator: comma
US$1,234.56     // standard US format

SAFE AREA:
Always wrap screens in SafeArea(). 
Bottom content should use MediaQuery.of(context).padding.bottom for proper iPhone home bar clearance.

HAPTIC FEEDBACK:
- Transaction saved: HapticFeedback.mediumImpact()
- Tab change: HapticFeedback.selectionClick()
- Error: HapticFeedback.vibrate()
- Button press: HapticFeedback.lightImpact()

LOADING PATTERN:
Never use CircularProgressIndicator. Always use skeleton screens.
Build MenudoSkeleton as Container with shimmer animation.

THEME DATA:
ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF065F46)),
  scaffoldBackgroundColor: MenudoColors.appBg,
  appBarTheme: AppBarTheme(backgroundColor: Colors.white, elevation: 0),
  fontFamily: 'Plus Jakarta Sans',  // via google_fonts
)
```
