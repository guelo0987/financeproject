import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/menudo_card.dart';
import '../../../shared/widgets/menudo_button.dart';
import '../../../shared/widgets/menudo_chip.dart';


class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MenudoColors.appBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              _buildHeroCard(),
              const SizedBox(height: 16),
              MenudoPrimaryButton(
                label: 'Registrar Gasto',
                icon: Icons.add,
                onTap: () {
                  context.push('/quick-log'); // Open QuickLog screen for now
                },
              ),
              const SizedBox(height: 24),
              _buildFlujoDelMes(context),
              const SizedBox(height: 24),
              _buildMisActivos(context),
              const SizedBox(height: 24),
              _buildMercado(context),
              const SizedBox(height: 24),
              _buildTasaCambio(),
              const SizedBox(height: 100), // Clear bottom nav
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('¡Hola, Marcos! 👋', style: MenudoTextStyles.bodyMedium.copyWith(color: MenudoColors.textMuted)),
                const SizedBox(height: 4),
                // Allow space switching
                GestureDetector(
                  onTap: () {
                    // Placeholder for Space Switcher Bottom Sheet
                  },
                  child: Row(
                    children: [
                      Text('Menudo', style: MenudoTextStyles.h1),
                      const Icon(Icons.keyboard_arrow_down_rounded, color: MenudoColors.textMuted),
                    ],
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () => context.go('/settings'),
              child: Stack(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: MenudoColors.cardBg, width: 2),
                      color: MenudoColors.divider,
                    ),
                    child: const Center(child: Icon(Icons.person, color: MenudoColors.textSecondary, size: 24)),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: MenudoColors.danger,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Martes, 7 de Marzo · 2026'.toUpperCase(), style: MenudoTextStyles.labelCaps.copyWith(color: MenudoColors.textMuted)),
      ],
    );
  }

  Widget _buildHeroCard() {
    return MenudoHeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PATRIMONIO TOTAL', style: MenudoTextStyles.labelCaps.copyWith(color: MenudoColors.textOnDarkSub)),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('RD\$', style: TextStyle(fontSize: 20, color: MenudoColors.textOnDarkSub, fontWeight: FontWeight.w600)),
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: 45230),
                        duration: const Duration(milliseconds: 1500),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Text(
                            value.toStringAsFixed(0).replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ','),
                            style: MenudoTextStyles.heroAmount,
                          );
                        },
                      ),
                      Text('.00', style: TextStyle(fontSize: 22, color: MenudoColors.textOnDark.withValues(alpha: 0.5))),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome, color: MenudoColors.textOnDarkSub, size: 20),
              ).animate().rotate(duration: 2.seconds, curve: Curves.easeInOut), // Smart assistant hook
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_upward, size: 14, color: Color(0xFF6EE7B7)),
                    const SizedBox(width: 4),
                    Text('+12.5% este año', style: MenudoTextStyles.labelBold.copyWith(color: const Color(0xFF6EE7B7))),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text('Buen ritmo 🔥', style: MenudoTextStyles.bodySmall.copyWith(color: MenudoColors.textOnDarkSub)),
            ],
          ),
          const SizedBox(height: 48),
          SizedBox(
            height: 40,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 1),
                      FlSpot(1, 1.5),
                      FlSpot(2, 1.4),
                      FlSpot(3, 3.4),
                      FlSpot(4, 2),
                      FlSpot(5, 4),
                      FlSpot(6, 5),
                    ],
                    isCurved: true,
                    color: Colors.white.withValues(alpha: 0.7),
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.05);
  }

  Widget _buildFlujoDelMes(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Flujo del mes', style: MenudoTextStyles.h3),
            TextButton(
              onPressed: () => context.go('/insights'),
              child: const Row(
                children: [
                  Text('Ver análisis ', style: TextStyle(color: MenudoColors.primary, fontWeight: FontWeight.bold)),
                  Icon(Icons.arrow_forward_rounded, size: 16, color: MenudoColors.primary),
                ],
              ),
            )
          ],
        ),
        MenudoCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildFlujoCol('INGRESOS', 'RD\$95K', '+5% vs feb', MenudoColors.successLight, MenudoColors.success, true),
              Container(width: 1, height: 40, color: MenudoColors.divider),
              _buildFlujoCol('GASTOS', 'RD\$58K', '-2% vs feb', MenudoColors.dangerLight, MenudoColors.danger, true),
              Container(width: 1, height: 40, color: MenudoColors.divider),
              _buildFlujoCol('AHORRO', 'RD\$37K', '38.6% tasa', MenudoColors.primaryLight, MenudoColors.primary, false),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildFlujoCol(String label, String amount, String sub, Color bgColor, Color mainColor, bool showSubColor) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 4, height: 36, decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: MenudoTextStyles.labelCaps.copyWith(color: MenudoColors.textMuted, fontSize: 10)),
                const SizedBox(height: 2),
                Text(amount, style: MenudoTextStyles.amountMedium.copyWith(color: mainColor)),
                const SizedBox(height: 2),
                Text(sub, style: MenudoTextStyles.bodySmall.copyWith(color: showSubColor ? mainColor : MenudoColors.textMuted, fontSize: 10), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMisActivos(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Mis activos', style: MenudoTextStyles.h3),
            TextButton(
              onPressed: () => context.go('/assets'),
              child: const Row(
                children: [
                  Text('Ver todos ', style: TextStyle(color: MenudoColors.primary, fontWeight: FontWeight.bold)),
                  Icon(Icons.arrow_forward_rounded, size: 16, color: MenudoColors.primary),
                ],
              ),
            )
          ],
        ),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildAssetPill(Icons.account_balance, 'BHD León', 'RD\$850,000', MenudoColors.successLight, MenudoColors.success, '+2.1%'),
              const SizedBox(width: 12),
              _buildAssetPill(Icons.currency_bitcoin, 'Bitcoin', '\$67,420', MenudoColors.primaryLight, MenudoColors.primary, '+4.3%'),
              const SizedBox(width: 12),
              _buildAssetPill(Icons.trending_up, 'QQQ', '\$487.32', MenudoColors.warningLight, MenudoColors.warning, '+0.8%'),
              const SizedBox(width: 12),
              _buildAssetPill(Icons.home, 'Apto. Naco', '\$125,000', MenudoColors.cardBg.withValues(alpha: 0.1), MenudoColors.cardBg, '+0.0%'),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildAssetPill(IconData icon, String name, String value, Color bgColor, Color fgColor, String change) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: MenudoColors.border),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(radius: 16, backgroundColor: bgColor, child: Icon(icon, size: 18, color: fgColor)),
              MenudoChip(change, variant: MenudoChipVariant.success, isSmall: true),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: MenudoTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(value, style: MenudoTextStyles.amountSmall),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMercado(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Mercado', style: MenudoTextStyles.h3),
            const SizedBox(width: 8),
            const Icon(Icons.refresh, size: 12, color: MenudoColors.textMuted),
            const SizedBox(width: 4),
            Text('hace 3 min', style: MenudoTextStyles.bodySmall.copyWith(color: MenudoColors.textMuted, fontSize: 10)),
          ],
        ),
        const SizedBox(height: 12),
        MenudoCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _buildMarketItem('BTC', 'Bitcoin', '\$67,420.50', '-2.1%', false),
              const Divider(color: MenudoColors.divider, height: 1),
              _buildMarketItem('ETH', 'Ethereum', '\$3,840.10', '+1.4%', true),
              const Divider(color: MenudoColors.divider, height: 1),
              _buildMarketItem('QQQ', 'Invesco QQQ', '\$487.32', '+0.8%', true),
              const Divider(color: MenudoColors.divider, height: 1),
              _buildMarketItem('XAU', 'Oro Gld', '\$2,310.00', '+0.3%', true),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildMarketItem(String ticker, String name, String price, String change, bool isUp) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              SizedBox(
                width: 40,
                child: Text(ticker, style: MenudoTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Text(name, style: MenudoTextStyles.bodyMedium.copyWith(color: MenudoColors.textMuted)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(price, style: MenudoTextStyles.amountSmall.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              MenudoChip(change, variant: isUp ? MenudoChipVariant.success : MenudoChipVariant.danger, isSmall: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTasaCambio() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: const Border(left: BorderSide(color: MenudoColors.primary, width: 4)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('USD / DOP', style: MenudoTextStyles.labelCaps.copyWith(color: MenudoColors.textMuted)),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('60.25', style: MenudoTextStyles.h2),
                  const SizedBox(width: 8),
                  const MenudoChip('+0.12', variant: MenudoChipVariant.success, isSmall: true),
                ],
              ),
            ],
          ),
          SizedBox(
            width: 80,
            height: 40,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 59.8), FlSpot(1, 59.9), FlSpot(2, 60.0), FlSpot(3, 60.15), FlSpot(4, 60.25),
                    ],
                    isCurved: true,
                    color: MenudoColors.primary,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    ).animate().fadeIn(delay: 500.ms);
  }
}
