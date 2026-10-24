import 'package:flutter/material.dart';
import '../core/api/driver_api.dart';
import '../core/app_state.dart';
import '../core/theme.dart';
import '../core/widgets.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});
  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  bool loading = true;
  String? error;
  Map<String, dynamic> finance = {};
  Map<String, dynamic> earnings = {};
  List<dynamic> rides = [];
  List<dynamic> settlements = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  num _n(Map m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v is num) return v;
      if (v != null) return num.tryParse(v.toString()) ?? 0;
    }
    return 0;
  }

  String _money(num v) => v.toStringAsFixed(v == v.roundToDouble() ? 0 : 2);
  String _date(dynamic v) {
    if (v == null) return '—';
    final d = DateTime.tryParse(v.toString());
    return d == null ? v.toString() : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<void> _load() async {
    if (mounted) setState(() { loading = true; error = null; });
    try {
      final results = await Future.wait([
        DriverApi.finance(),
        DriverApi.earnings(),
        DriverApi.history(limit: 30),
        DriverApi.settlements(),
      ]);
      if (!mounted) return;
      setState(() {
        finance = Map<String, dynamic>.from(results[0] as Map);
        earnings = Map<String, dynamic>.from(results[1] as Map);
        rides = List<dynamic>.from(results[2] as List);
        settlements = List<dynamic>.from(results[3] as List);
        loading = false;
      });
      AppScope.of(context).refreshFinance();
    } catch (e) {
      if (mounted) setState(() { error = e.toString().replaceFirst('Exception: ', ''); loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final stateFinance = s.finance ?? {};
    final f = finance.isNotEmpty ? finance : stateFinance;
    final profile = s.profile ?? <String, dynamic>{};
    final balance = _n(profile, ['total_earnings', 'totalEarnings', 'available_balance', 'availableBalance']);
    final total = _n(earnings, ['total', 'totalEarnings']);
    final owed = _n(f, ['commission_owed', 'commissionOwed']);
    final gross = _n(f, ['gross_since_settlement', 'grossSinceSettlement']);
    final blocked = f['blocked'] == true || f['blocked'] == 1;
    final autopay = f['autopay_enabled'] == true || f['autopay_enabled'] == 1 || f['autopayEnabled'] == true;
    final days = (earnings['days'] is List) ? List<dynamic>.from(earnings['days']) : <dynamic>[];

    return SafeArea(child: RefreshIndicator(
      onRefresh: _load,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        Row(children: [
          Expanded(child: Text(s.t('Earnings & Wallet', 'Mapato na Pochi'),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900))),
          IconButton.filledTonal(onPressed: () => _showHistory(context), icon: const Icon(Icons.history)),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ]),
        if (loading) const LinearProgressIndicator(),
        if (error != null) Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.cloud_off_outlined), const SizedBox(height: 8),
          Text(error!, style: const TextStyle(fontWeight: FontWeight.w700)),
          Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Retry'))),
        ]))),
        Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s.t('Available balance / lifetime earnings', 'Salio / mapato ya jumla'), style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .65))),
          const SizedBox(height: 6),
          Text('TZS ${_money(balance)}', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text('Last 30 days: TZS ${_money(total)}'),
          const SizedBox(height: 14),
          LoadingButton(label: s.t('Request payout', 'Omba malipo'), icon: Icons.account_balance_wallet_outlined,
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WithdrawScreen())).then((_) => _load())),
        ]))),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [const Icon(Icons.account_balance_outlined), const SizedBox(width: 8), const Expanded(child: Text('ZenjiGO settlement', style: TextStyle(fontWeight: FontWeight.w900))), if (blocked) const Pill('RESTRICTED')]),
          const SizedBox(height: 8),
          _kv('Gross since settlement', 'TZS ${_money(gross)}'),
          _kv('Commission owed', 'TZS ${_money(owed)}'),
          _kv('Commission rate', '${_money(_n(f, ['commissionRate', 'commission_rate']))}%'),
          _kv('Autopay', autopay ? 'ON' : 'OFF'),
          if (f['threshold'] != null) _kv('Settlement threshold', 'TZS ${_money(_n(f, ['threshold']))}'),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            OutlinedButton(onPressed: loading ? null : () async {
              try {
                final r = await DriverApi.settle();
                await _load();
                if (context.mounted) toast(context, (r['message'] ?? 'Settlement request submitted. Follow provider status for confirmation.').toString());
              } catch (e) { if (context.mounted) toast(context, e.toString().replaceFirst('Exception: ', '')); }
            }, child: const Text('Settle now')),
            FilledButton.tonal(onPressed: loading ? null : () async {
              try {
                if (autopay) {
                  await DriverApi.autopay(enabled: false);
                  await _load();
                  if (context.mounted) toast(context, 'Autopay disabled');
                  return;
                }
                final phoneCtrl = TextEditingController(text: (AppScope.of(context).profile?['phone'] ?? '').toString());
                final phone = await showDialog<String>(
                  context: context,
                  builder: (d) => AlertDialog(
                    title: const Text('Enable autopay'),
                    content: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text('Enter the mobile-money number that will authorize commission settlements. A provider mandate/token is created for this number.'),
                      const SizedBox(height: 12),
                      TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Mobile money phone', prefixIcon: Icon(Icons.phone_android))),
                    ]),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
                      FilledButton(onPressed: () => Navigator.pop(d, phoneCtrl.text.trim()), child: const Text('Continue')),
                    ],
                  ),
                );
                if (phone == null || phone.isEmpty) return;
                final method = await DriverApi.addPaymentMethod({
                  'provider': 'momo',
                  'methodType': 'momo',
                  'providerToken': 'momo:$phone',
                  'phone': phone,
                  'accountLabel': 'Autopay $phone',
                  'maskedAccount': phone.length > 4 ? '****${phone.substring(phone.length - 4)}' : phone,
                  'isAutopayDefault': true,
                });
                final token = (method['provider_token'] ?? method['providerToken'] ?? 'momo:$phone').toString();
                await DriverApi.autopay(enabled: true, provider: 'momo', providerToken: token);
                await _load();
                if (context.mounted) toast(context, 'Autopay enabled for $phone');
              } catch (e) { if (context.mounted) toast(context, e.toString().replaceFirst('Exception: ', '')); }
            }, child: Text(autopay ? 'Disable autopay' : 'Enable autopay')),
          ]),
        ]))),
        SectionTitle(s.t('Earnings by day', 'Mapato kwa siku')),
        if (days.isEmpty && !loading) const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No earnings recorded for this period.'))),
        ...days.map((row) {
          final d = Map<String, dynamic>.from(row as Map);
          return Card(child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.payments_outlined)),
            title: Text(_date(d['day']), style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text('${d['rides'] ?? 0} completed rides · gross TZS ${_money(_n(d, ['gross']))}'),
            trailing: Text('TZS ${_money(_n(d, ['driver_share', 'driverShare']))}', style: const TextStyle(fontWeight: FontWeight.w900)),
          ));
        }),
        SectionTitle(s.t('Recent completed rides', 'Safari zilizokamilika hivi karibuni')),
        if (rides.isEmpty && !loading) const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No rides returned by the server.'))),
        ...rides.take(10).map((row) {
          final r = Map<String, dynamic>.from(row as Map);
          final status = (r['status'] ?? '—').toString();
          final amount = _n(r, ['final_fare', 'finalFare', 'estimated_fare', 'estimatedFare']);
          return Card(child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.route_outlined)),
            title: Text((r['ride_code'] ?? r['rideCode'] ?? 'Ride ${r['id'] ?? ''}').toString(), style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text('${r['pickup_address'] ?? r['pickupAddress'] ?? '—'} → ${r['destination_address'] ?? r['destinationAddress'] ?? '—'}\n${_date(r['completed_at'] ?? r['completedAt'] ?? r['created_at'])} · $status'),
            isThreeLine: true,
            trailing: Text('TZS ${_money(amount)}', style: const TextStyle(fontWeight: FontWeight.w800)),
          ));
        }),
        const SizedBox(height: 16),
      ]),
    ));
  }

  Widget _kv(String label, String value) => Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(children: [
    Expanded(child: Text(label)), Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
  ]));

  void _showHistory(BuildContext context) {
    showModalBottomSheet<void>(context: context, isScrollControlled: true, builder: (ctx) => DraggableScrollableSheet(
      expand: false, initialChildSize: .72, builder: (ctx, controller) => ListView(controller: controller, padding: const EdgeInsets.all(18), children: [
        Text('Settlement history', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        if (settlements.isEmpty) const Text('No settlement records returned by the server.'),
        ...settlements.map((item) {
          final r = Map<String, dynamic>.from(item as Map);
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.receipt_long_outlined)),
            title: Text('Settlement ${r['id'] ?? ''} · TZS ${r['amount'] ?? r['commission_amount'] ?? '—'}'),
            subtitle: Text('${r['status'] ?? '—'} · ${r['createdAt'] ?? r['created_at'] ?? ''}'),
          );
        }),
      ]),
    ));
  }
}

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});
  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final key = GlobalKey<FormState>();
  final amount = TextEditingController();
  final account = TextEditingController();
  final phone = TextEditingController();
  String method = 'M-Pesa';
  bool submitting = false;

  @override
  void dispose() { amount.dispose(); account.dispose(); phone.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final f = app.finance ?? {};
    final p = app.profile ?? {};
    final available = (p['total_earnings'] ?? p['totalEarnings'] ?? p['available_balance'] ?? p['availableBalance'] ?? 0).toString();
    return Scaffold(
      appBar: AppBar(title: const Text('Request payout')),
      body: ResponsivePage(child: Form(key: key, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Card(child: ListTile(title: const Text('Server-reported balance'), subtitle: Text('TZS $available'))),
        const SizedBox(height: 12),
        TextFormField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Amount (TZS)'),
          validator: (v) { final n = num.tryParse((v ?? '').trim()); if (n == null || n <= 0) return 'Enter a valid amount'; if (n > (num.tryParse(available) ?? 0)) return 'Amount exceeds the displayed balance'; return null; }),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(value: method, decoration: const InputDecoration(labelText: 'Payout method'),
          items: const [DropdownMenuItem(value: 'M-Pesa', child: Text('M-Pesa / mobile money')), DropdownMenuItem(value: 'Bank', child: Text('Bank transfer'))],
          onChanged: (v) => setState(() => method = v ?? method)),
        const SizedBox(height: 12),
        TextFormField(controller: phone, decoration: const InputDecoration(labelText: 'Mobile money phone (if applicable)')),
        const SizedBox(height: 12),
        TextFormField(controller: account, decoration: const InputDecoration(labelText: 'Account / bank details')),
        const SizedBox(height: 18),
        LoadingButton(label: submitting ? 'Submitting…' : 'Submit payout request', icon: Icons.send_outlined, onPressed: submitting ? null : () async {
          if (!(key.currentState?.validate() ?? false)) return;
          setState(() => submitting = true);
          try {
            final result = await DriverApi.requestPayout(
              amount: double.parse(amount.text.trim()),
              method: method,
              accountDetails: {'phone': phone.text.trim(), 'account': account.text.trim()},
            );
            if (!context.mounted) return;
            toast(context, 'Payout request ${result['id'] ?? ''} submitted. Status: ${result['status'] ?? 'pending'}.');
            Navigator.pop(context);
          } catch (e) {
            if (context.mounted) toast(context, e.toString().replaceFirst('Exception: ', ''));
          } finally { if (mounted) setState(() => submitting = false); }
        }),
      ]))),
    );
  }
}
