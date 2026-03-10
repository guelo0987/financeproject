import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/data/mock_data.dart';
import '../../../core/data/models.dart';
import '../../../shared/widgets/glass_card.dart';

class InvestScreen extends StatefulWidget {
  const InvestScreen({super.key});

  @override
  State<InvestScreen> createState() => _InvestScreenState();
}

class _InvestScreenState extends State<InvestScreen> {
  String _selectedFilter = 'Todos';
  String _selectedCurrency = 'Todos';

  static const _filters = ['Todos', 'Certificado', 'Fondo', 'Bono', 'Letra'];
  static const _currencies = ['Todos', 'DOP', 'USD'];

  List<InvestmentInstrument> get _filteredInstruments {
    return MockData.instruments.where((inst) {
      final matchType =
          _selectedFilter == 'Todos' || inst.type == _selectedFilter;
      final matchCurrency =
          _selectedCurrency == 'Todos' || inst.currency == _selectedCurrency;
      return matchType && matchCurrency;
    }).toList();
  }

  void _showCalculator(InvestmentInstrument instrument) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _YieldCalculatorSheet(instrument: instrument),
    );
  }

  @override
  Widget build(BuildContext context) {
    final instruments = _filteredInstruments;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Invertir', style: AppTextStyles.displaySmall),
                    const SizedBox(height: 4),
                    Text(
                      'Oportunidades del mercado dominicano',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms),
            ),

            // ── Type Filters ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 38,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _filters.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final filter = _filters[index];
                          final isSelected = _selectedFilter == filter;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _selectedFilter = filter),
                            child: AnimatedContainer(
                              duration: AppConstants.animFast,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.accentSurface
                                    : AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.accent
                                      : AppColors.cardBorder,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  filter,
                                  style: AppTextStyles.labelMedium.copyWith(
                                    color: isSelected
                                        ? AppColors.accent
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Currency filter
                    Row(
                      children: _currencies.map((c) {
                        final isSelected = _selectedCurrency == c;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedCurrency = c),
                            child: AnimatedContainer(
                              duration: AppConstants.animFast,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.surfaceLight
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.textSecondary
                                      : AppColors.cardBorder,
                                ),
                              ),
                              child: Text(
                                c,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: isSelected
                                      ? AppColors.textPrimary
                                      : AppColors.textTertiary,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
            ),

            // ── Instrument Cards ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final instrument = instruments[index];
                  return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _InstrumentCard(
                          instrument: instrument,
                          onCalculate: () => _showCalculator(instrument),
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: (150 + 80 * index).ms)
                      .slideY(begin: 0.05);
                }, childCount: instruments.length),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Instrument Card ─────────────────────────────

class _InstrumentCard extends StatelessWidget {
  final InvestmentInstrument instrument;
  final VoidCallback onCalculate;

  const _InstrumentCard({required this.instrument, required this.onCalculate});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0', 'en_US');

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            instrument.type,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: instrument.risk.color.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            instrument.risk.label,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: instrument.risk.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(instrument.name, style: AppTextStyles.headlineSmall),
                    const SizedBox(height: 2),
                    Text(
                      instrument.institution,
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              // Yield badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accent.withValues(alpha: 0.2),
                      AppColors.accentBright.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '${instrument.annualYield}%',
                      style: AppTextStyles.cardValue.copyWith(
                        color: AppColors.accentBright,
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      'anual',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Details row
          Row(
            children: [
              _DetailChip(label: 'Plazo', value: instrument.term),
              const SizedBox(width: 12),
              _DetailChip(
                label: 'Mínimo',
                value:
                    '${instrument.currency} ${formatter.format(instrument.minimumAmount)}',
              ),
              const SizedBox(width: 12),
              _DetailChip(label: 'Moneda', value: instrument.currency),
            ],
          ),
          const SizedBox(height: 12),
          // Calculator button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onCalculate,
              icon: const Icon(Icons.calculate_outlined, size: 18),
              label: const Text('¿Cuánto ganaría?'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.accentDim),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final String label;
  final String value;

  const _DetailChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.labelSmall),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Yield Calculator Bottom Sheet ────────────────

class _YieldCalculatorSheet extends StatefulWidget {
  final InvestmentInstrument instrument;

  const _YieldCalculatorSheet({required this.instrument});

  @override
  State<_YieldCalculatorSheet> createState() => _YieldCalculatorSheetState();
}

class _YieldCalculatorSheetState extends State<_YieldCalculatorSheet> {
  final _controller = TextEditingController(text: '100000');

  double get _amount =>
      double.tryParse(_controller.text.replaceAll(',', '')) ?? 0;
  double get _yearlyReturn => _amount * (widget.instrument.annualYield / 100);
  double get _monthlyReturn => _yearlyReturn / 12;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    final prefix = widget.instrument.currency == 'USD' ? '\$' : 'RD\$';

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textTertiary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Calculadora de Rendimiento',
            style: AppTextStyles.headlineLarge,
          ),
          const SizedBox(height: 4),
          Text(widget.instrument.name, style: AppTextStyles.bodyMedium),
          const SizedBox(height: 20),
          Text('MONTO A INVERTIR ($prefix)', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            style: AppTextStyles.cardValue.copyWith(fontSize: 22),
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.attach_money, color: AppColors.accent),
            ),
          ),
          const SizedBox(height: 20),
          GlassCard(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Rendimiento anual', style: AppTextStyles.bodyMedium),
                    Text(
                      '$prefix ${formatter.format(_yearlyReturn)}',
                      style: AppTextStyles.cardValue.copyWith(
                        color: AppColors.positive,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rendimiento mensual',
                      style: AppTextStyles.bodyMedium,
                    ),
                    Text(
                      '$prefix ${formatter.format(_monthlyReturn)}',
                      style: AppTextStyles.cardValue.copyWith(
                        color: AppColors.positive,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Tasa', style: AppTextStyles.bodyMedium),
                    Text(
                      '${widget.instrument.annualYield}% anual',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.accentBright,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
