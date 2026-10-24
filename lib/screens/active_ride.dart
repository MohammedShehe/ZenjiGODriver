import 'package:flutter/material.dart';
import 'package:zenjigodriver/core/app_state.dart';
import '../core/api/driver_api.dart';

import '../core/live_map.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../core/friendly_errors.dart';
import 'chat.dart';

class ActiveRideScreen extends StatefulWidget {
  const ActiveRideScreen({super.key, this.rideId});
  final String? rideId;

  @override
  State<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends State<ActiveRideScreen> {
  int stage = 0; // arriving, arrived, started, completed, done
  Map<String, dynamic>? rideData;

  @override
  void initState() {
    super.initState();
    _loadRide();
  }

  Future<void> _loadRide() async {
    final id = widget.rideId;
    if (id == null) return;
    try {
      final rows = await DriverApi.history(limit: 100);
      for (final item in rows) {
        if (item is Map) {
          final candidate = Map<String, dynamic>.from(item);
          if ('${candidate['id'] ?? candidate['rideId'] ?? candidate['ride_id']}' == id) {
            if (mounted) {
              final status = '${candidate['status'] ?? ''}'.toLowerCase();
              final restoredStage = switch (status) {
                'arriving' => 1,
                'arrived' => 2,
                'started' => 3,
                'completed' => 4,
                _ => 0,
              };
              setState(() {
                rideData = candidate;
                stage = restoredStage;
              });
            }
            break;
          }
        }
      }
    } catch (_) {}
  }

  String _rideText(List<String> keys, {String fallback = '—'}) {
    for (final key in keys) {
      final value = rideData?[key];
      if (value != null && value.toString().trim().isNotEmpty) return value.toString();
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: stage >= 4,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          toast(context, AppScope.of(context).t('Finish or cancel the active ride before leaving.', 'Maliza au ghairi safari inayoendelea kabla ya kuondoka.'));
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(stage < 2 ? AppScope.of(context).t('Pickup rider', 'Chukua abiria') : AppScope.of(context).t('Active ride', 'Safari inayoendelea')),
          actions: [
            Pill(
              stage >= 2 ? AppScope.of(context).t('IN PROGRESS', 'INAENDELEA') : 'TO PICKUP',
              color: stage >= 2 ? ZenjiColors.green : null,
            ),
            const SizedBox(width: 14),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Container(
                height: 6,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                alignment: Alignment.centerLeft,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  width: MediaQuery.sizeOf(context).width *
                      (stage == 0
                          ? .20
                          : stage == 1
                              ? .40
                              : stage == 2
                                  ? .65
                                  : stage == 3 ? .85 : 1),
                  decoration: const BoxDecoration(
                    color: ZenjiColors.green,
                    borderRadius: BorderRadius.horizontal(
                      right: Radius.circular(99),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    Builder(builder: (ctx) {
                      final s = AppScope.of(ctx);
                      return LiveDriverMap(
                        height: MediaQuery.sizeOf(ctx).height < 700 ? 240 : 300,
                        activeRideId: widget.rideId,
                        showRequests: false,
                        shareLocation: true,
                        isSwahili: s.isSwahili,
                        isDark: Theme.of(ctx).brightness == Brightness.dark,
                      );
                    }),
                    const SizedBox(height: 14),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const CircleAvatar(
                                  radius: 27,
                                  child: Icon(Icons.person, size: 30),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _rideText(['riderName', 'rider_name', 'customerName', 'customer_name'], fallback: 'Rider'),
                                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        _rideText(['riderPhone', 'rider_phone', 'customerPhone', 'customer_phone'], fallback: 'Ride #${widget.rideId ?? '—'}'),
                                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .6)),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton.filledTonal(
                                  onPressed: () => toast(
                                    context,
                                    _rideText(['riderPhone', 'rider_phone', 'customerPhone', 'customer_phone'], fallback: 'Rider phone is not available for this ride.'),
                                  ),
                                  icon: const Icon(Icons.call),
                                ),
                                const SizedBox(width: 7),
                                IconButton.filledTonal(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChatScreen(
                                        name: _rideText(['riderName', 'rider_name', 'customerName', 'customer_name'], fallback: 'Rider'),
                                        support: false,
                                      ),
                                    ),
                                  ),
                                  icon: const Icon(Icons.chat_bubble_outline),
                                ),
                              ],
                            ),
                            const Divider(height: 26),
                            KeyValueRow(AppScope.of(context).t('Pickup', 'Kuchukua'), _rideText(['pickupAddress', 'pickup_address'], fallback: 'Pickup location')),
                            KeyValueRow(AppScope.of(context).t('Drop-off', 'Kushusha'), _rideText(['destinationAddress', 'destination_address'], fallback: 'Destination')),
                            KeyValueRow(AppScope.of(context).t('Ride type', 'Aina ya safari'), _rideText(['rideType', 'ride_type'], fallback: 'Ride')),
                            KeyValueRow(AppScope.of(context).t('Est. fare', 'Nauli inayokadiriwa'), 'TZS ${_rideText(['fare', 'estimatedFare', 'estimated_fare', 'amount'], fallback: '—')}'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (stage >= 2) _fare(),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _report,
                            icon: const Icon(Icons.flag_outlined),
                            label: Text(AppScope.of(context).t('Report rider', 'Ripoti abiria')),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _support,
                            icon: const Icon(Icons.support_agent),
                            label: Text(AppScope.of(context).t('ZenjiGO support', 'Msaada wa ZenjiGO')),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (stage < 4)
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          onPressed: _cancelRide,
                          icon: const Icon(Icons.cancel_outlined),
                          label: Text(AppScope.of(context).t('Cancel ride', 'Ghairi safari')),
                          style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                        ),
                      ),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                child: LoadingButton(
                  label: _label(),
                  icon: _icon(),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.maybeOf(context);
                    if (stage == 3) {
                      final yes = await confirmDialog(
                        context,
                        title: AppScope.of(context).t('End this ride?', 'Maliza safari hii?'),
                        message:
                            'Confirm only after the rider has reached the drop-off location.',
                        confirm: AppScope.of(context).t('End ride', 'Maliza safari'),
                      );
                      if (yes != true) return;
                    }
                    try {
                      if (widget.rideId == null) throw Exception('Ride ID missing.');
                      final nextStatus = ['arriving', 'arrived', 'started', 'completed'][stage];
                      await DriverApi.status(widget.rideId!, nextStatus);
                      if (!mounted) return;
                      setState(() {
                        stage++;
                        if (rideData != null) rideData = {...rideData!, 'status': nextStatus};
                      });
                      if (stage == 4) {
                        AppScope.of(context).setActiveRideId(null);
                        _complete();
                      }
                    } catch (e) {
                      if (mounted && messenger != null) {
                        messenger.showSnackBar(
                          SnackBar(content: Text(FriendlyErrors.message(e, swahili: AppScope.of(context).isSwahili))),
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _label() => [
        AppScope.of(context).t('ON MY WAY', 'NIKO NJIANI'),
        AppScope.of(context).t('I HAVE ARRIVED', 'NIMEWASILI'),
        AppScope.of(context).t('START RIDE', 'ANZA SAFARI'),
        AppScope.of(context).t('COMPLETE RIDE', 'MALIZA SAFARI'),
        AppScope.of(context).t('RIDE COMPLETED', 'SAFARI IMEKAMILIKA'),
      ][(stage > 4 ? 4 : stage)];

  IconData _icon() => [
        Icons.navigation,
        Icons.location_on,
        Icons.play_arrow,
        Icons.stop,
        Icons.check_circle,
      ][(stage > 4 ? 4 : stage)];

  Future<void> _cancelRide() async {
    final id = widget.rideId;
    if (id == null) return;
    final yes = await confirmDialog(
      context,
      title: AppScope.of(context).t('Cancel this ride?', 'Ghairi safari hii?'),
      message: AppScope.of(context).t(
        'Only cancel if you cannot safely complete the trip.',
        'Ghairi tu ikiwa huwezi kukamilisha safari kwa usalama.',
      ),
      confirm: AppScope.of(context).t('Cancel ride', 'Ghairi safari'),
    );
    if (yes != true || !mounted) return;
    try {
      await DriverApi.status(id, 'cancelled');
      if (!mounted) return;
      AppScope.of(context).setActiveRideId(null);
      toast(context, AppScope.of(context).t('Ride cancelled.', 'Safari imeghairiwa.'));
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) toast(context, FriendlyErrors.message(e, swahili: AppScope.of(context).isSwahili));
    }
  }

  Widget _fare() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppScope.of(context).t('Fare summary', 'Muhtasari wa nauli'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 8),
            KeyValueRow('Ride ID', widget.rideId ?? '—'),
            KeyValueRow('Ride type', _rideText(['rideType', 'ride_type'], fallback: '—')),
            KeyValueRow('Status', _rideText(['status'], fallback: 'active')),
            const Divider(),
            KeyValueRow(AppScope.of(context).t('Estimated total', 'Jumla inayokadiriwa'), 'TZS ${_rideText(['fare', 'estimatedFare', 'estimated_fare', 'amount'], fallback: '—')}'),
          ],
        ),
      ),
    );
  }

  void _support() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ZenjiGO support',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 14),
              ListTile(
                leading: const Icon(Icons.chat),
                title: Text(AppScope.of(context).t('In-app chat', 'Mazungumzo katika programu')),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ChatScreen(
                        name: 'ZenjiGO Support',
                        support: true,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.call),
                title: const Text('+255 676 891 227'),
                onTap: () => toast(context, 'Contact support at +255 676 891 227.'),
              ),
              ListTile(
                leading: const Icon(Icons.email_outlined),
                title: const Text('zenjigo@support.com'),
                onTap: () => toast(context, 'Contact support at support@zenjigo.online.'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _report() {
    String reason = 'Unsafe behavior';
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(AppScope.of(context).t('Report rider', 'Ripoti abiria')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: reason,
                items: [
                  'Unsafe behavior',
                  AppScope.of(context).t('Harassment', 'Unyanyasaji'),
                  AppScope.of(context).t('Payment issue', 'Tatizo la malipo'),
                  AppScope.of(context).t('Damage / mess', 'Uharibifu / uchafu'),
                  AppScope.of(context).t('Other', 'Nyingine'),
                ]
                    .map(
                      (item) => DropdownMenuItem(
                        value: item,
                        child: Text(item),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => reason = value);
                  }
                },
                decoration: InputDecoration(labelText: AppScope.of(context).t('Reason', 'Sababu')),
              ),
              const SizedBox(height: 12),
              TextField(
                maxLines: 3,
                decoration: InputDecoration(labelText: AppScope.of(context).t('Additional details', 'Maelezo ya ziada')),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(AppScope.of(context).t('Cancel', 'Ghairi')),
            ),
            FilledButton(
              onPressed: () async {
                final ok = await confirmDialog(
                  context,
                  title: 'Submit rider report?',
                  message:
                      'Your report will be sent to ZenjiGO for review. This action should only be used for genuine concerns.',
                  confirm: 'Submit report',
                );
                if (ok == true && dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                  if (mounted) {
                    toast(context, AppScope.of(context).t('Rider report submitted successfully.', 'Ripoti ya abiria imewasilishwa kwa mafanikio.'));
                  }
                }
              },
              child: Text(AppScope.of(context).t('Continue', 'Endelea')),
            ),
          ],
        ),
      ),
    );
  }

  void _complete() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.check_circle,
          color: ZenjiColors.green,
          size: 52,
        ),
        title: Text(AppScope.of(context).t('Ride completed', 'Safari imekamilika')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppScope.of(context).t('Great job! The trip has been completed successfully.', 'Kazi nzuri! Safari imekamilika kwa mafanikio.'),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            KeyValueRow('Fare', 'TZS ${_rideText(['fare', 'estimatedFare', 'estimated_fare', 'amount'], fallback: '—')}'),
            KeyValueRow('Your share', 'TZS ${_rideText(['driverEarnings', 'driver_earnings', 'driverShare', 'driver_share'], fallback: '—')}'),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context);
            },
            child: Text(AppScope.of(context).t('Back to Home', 'Rudi Nyumbani')),
          ),
        ],
      ),
    );
  }
}
