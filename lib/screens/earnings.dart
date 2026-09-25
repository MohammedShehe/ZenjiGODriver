import 'package:flutter/material.dart';
import 'package:zenjigodriver/core/app_state.dart';

import '../core/theme.dart';
import '../core/widgets.dart';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  AppScope.of(context).t('Earnings & Wallet', 'Mapato na Pochi'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              IconButton.filledTonal(
                onPressed: () => _history(context),
                icon: const Icon(Icons.history),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppScope.of(context).t('Available balance', 'Salio linalopatikana'),
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: .62),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'TZS 184,500',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 16),
                  LoadingButton(
                    label: 'Withdraw funds',
                    icon: Icons.account_balance_wallet_outlined,
                    onPressed: () async {
                      await fakeDelay(300);
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WithdrawScreen(),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _summary(context, AppScope.of(context).t('Today', 'Leo'), '48,500', '7 rides')),
              const SizedBox(width: 10),
              Expanded(
                child: _summary(context, AppScope.of(context).t('This week', 'Wiki hii'), '268,000', '39 rides'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const SectionTitle('Weekly earnings'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  SizedBox(
                    height: 180,
                    child: CustomPaint(
                      painter: EarningsChartPainter(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text('Mon'),
                      Text('Tue'),
                      Text('Wed'),
                      Text('Thu'),
                      Text('Fri'),
                      Text('Sat'),
                      Text('Sun'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          SectionTitle(AppScope.of(context).t('Commission breakdown', 'Mgawanyo wa kamisheni')),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _share(
                          context,
                          AppScope.of(context).t('Driver share', 'Sehemu ya dereva'),
                          '80%',
                          'TZS 214,400',
                          ZenjiColors.green,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _share(
                          context,
                          'ZenjiGO',
                          '20%',
                          'TZS 53,600',
                          Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: .8,
                      minHeight: 12,
                      color: ZenjiColors.green,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .secondary
                          .withValues(alpha: .22),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          SectionTitle(AppScope.of(context).t('Bonus & incentives', 'Bonasi na motisha')),
          _incentive(
            context,
            'Weekend streak',
            'Complete 12 rides Fri–Sun',
            '8 / 12',
            'TZS 25,000',
            .67,
          ),
          _incentive(
            context,
            'High rating bonus',
            'Maintain 4.8+ rating this week',
            '4.9 rating',
            'TZS 10,000',
            .92,
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }

  Widget _summary(
    BuildContext context,
    String label,
    String amount,
    String rides,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .6),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'TZS $amount',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
            ),
            Text(rides, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _share(
    BuildContext context,
    String label,
    String percent,
    String amount,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          Text(
            percent,
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(
            amount,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _incentive(
    BuildContext context,
    String title,
    String subtitle,
    String progress,
    String reward,
    double value,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                Pill(reward, color: ZenjiColors.darkHighlight),
              ],
            ),
            const SizedBox(height: 4),
            Text(subtitle),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: value,
              minHeight: 8,
              borderRadius: BorderRadius.circular(99),
            ),
            const SizedBox(height: 6),
            Text(
              progress,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  void _history(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .72,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Wallet history',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 12),
            ...[
              'Ride #ZG1028 • +TZS 14,800',
              'Ride #ZG1027 • +TZS 9,600',
              'Weekend bonus • +TZS 25,000',
              'Withdrawal • -TZS 100,000',
            ].map(
              (entry) => ListTile(
                leading: CircleAvatar(
                  child: Icon(
                    entry.contains('Withdrawal')
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                  ),
                ),
                title: Text(
                  entry,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text('18 Sep 2026 • Completed'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  String method = 'M-Pesa';
  final formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Withdraw funds')),
      body: ResponsivePage(
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppScope.of(context).t('Choose payout method', 'Chagua njia ya malipo'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: method,
                items: ['M-Pesa', 'YAS', AppScope.of(context).t('Bank transfer', 'Uhamisho wa benki')]
                    .map(
                      (item) => DropdownMenuItem(
                        value: item,
                        child: Text(item),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => method = value);
                },
                decoration: InputDecoration(
                  labelText: AppScope.of(context).t('Payout method', 'Njia ya malipo'),
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
              ),
              const SizedBox(height: 14),
              if (method != AppScope.of(context).t('Bank transfer', 'Uhamisho wa benki')) ...[
                _field(
                  AppScope.of(context).t('Phone number', 'Namba ya simu'),
                  'e.g. +255 7XX XXX XXX',
                  Icons.phone_outlined,
                ),
                const SizedBox(height: 14),
                _field(
                  AppScope.of(context).t('Account holder name', 'Jina la mmiliki wa akaunti'),
                  AppScope.of(context).t('Name registered on mobile money', 'Jina lililosajiliwa kwenye pesa za simu'),
                  Icons.person_outline,
                ),
              ] else ...[
                _field(AppScope.of(context).t('Bank name', 'Jina la benki'), 'e.g. CRDB Bank', Icons.account_balance),
                const SizedBox(height: 14),
                _field(AppScope.of(context).t('Account number', 'Namba ya akaunti'), 'Bank account number', Icons.numbers),
                const SizedBox(height: 14),
                _field(
                  AppScope.of(context).t('Account holder name', 'Jina la mmiliki wa akaunti'),
                  AppScope.of(context).t('Full legal name', 'Jina kamili la kisheria'),
                  Icons.person_outline,
                ),
                const SizedBox(height: 14),
                _field(
                  'Branch / SWIFT (optional)',
                  'Optional routing information',
                  Icons.route,
                  required: false,
                ),
              ],
              const SizedBox(height: 14),
              _field(
                AppScope.of(context).t('Amount (TZS)', 'Kiasi (TZS)'),
                AppScope.of(context).t('Minimum TZS 10,000', 'Kiwango cha chini TZS 10,000'),
                Icons.attach_money,
              ),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      KeyValueRow(AppScope.of(context).t('Available', 'Linapatikana'), 'TZS 184,500'),
                      KeyValueRow('Withdrawal fee', 'TZS 1,000'),
                      KeyValueRow(AppScope.of(context).t('Processing', 'Inachakatwa'), 'Usually same day'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              LoadingButton(
                label: AppScope.of(context).t('Review withdrawal', 'Kagua uondoaji'),
                icon: Icons.arrow_forward,
                onPressed: () async {
                  if (!(formKey.currentState?.validate() ?? false)) return;
                  await fakeDelay();
                  if (!context.mounted) return;
                  final yes = await confirmDialog(
                    context,
                    title: AppScope.of(context).t('Confirm withdrawal', 'Thibitisha uondoaji'),
                    message:
                        'Send the requested amount using $method? Verify the payout details before confirming.',
                    confirm: AppScope.of(context).t('Withdraw', 'Toa'),
                  );
                  if (yes == true && context.mounted) {
                    toast(context, 'Withdrawal request submitted successfully.');
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    String hint,
    IconData icon, {
    bool required = true,
  }) {
    return TextFormField(
      validator: (value) => required && (value == null || value.trim().isEmpty)
          ? '$label is required'
          : null,
      keyboardType: label.contains('number') || label.contains('Amount')
          ? TextInputType.number
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
      ),
    );
  }
}

class EarningsChartPainter extends CustomPainter {
  final Color color;
  EarningsChartPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final values = [.35, .52, .44, .72, .63, .9, .78];
    final grid = Paint()
      ..color = Colors.grey.withValues(alpha: .14)
      ..strokeWidth = 1;

    for (var i = 0; i < 4; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final width = size.width / values.length;
    for (var i = 0; i < values.length; i++) {
      final height = size.height * values[i];
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(i * width + 8, size.height - height, width - 16, height),
        const Radius.circular(8),
      );
      canvas.drawRRect(
        rect,
        Paint()..color = color.withValues(alpha: .85),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
