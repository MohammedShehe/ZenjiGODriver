import 'package:flutter/material.dart';
import 'package:zenjigodriver/core/app_state.dart';

import '../core/mock_map.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import 'chat.dart';

class ActiveRideScreen extends StatefulWidget {
  const ActiveRideScreen({super.key});

  @override
  State<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends State<ActiveRideScreen> {
  int stage = 0; // 0 pickup, 1 arrived, 2 riding, 3 done

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: stage == 3,
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
              stage == 2 ? AppScope.of(context).t('IN PROGRESS', 'INAENDELEA') : 'TO PICKUP',
              color: stage == 2 ? ZenjiColors.green : null,
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
                          ? .25
                          : stage == 1
                              ? .45
                              : stage == 2
                                  ? .78
                                  : 1),
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
                    const MockMap(height: 300, active: true, showRequests: false),
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
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Asha Salim',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.star,
                                            color: Colors.amber,
                                            size: 17,
                                          ),
                                          Text(' 4.8 • 126 rides'),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton.filledTonal(
                                  onPressed: () => toast(
                                    context,
                                    AppScope.of(context).t('Calling rider', 'Inampigia abiria') + ': +255 777 123 456',
                                  ),
                                  icon: const Icon(Icons.call),
                                ),
                                const SizedBox(width: 7),
                                IconButton.filledTonal(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ChatScreen(
                                        name: 'Asha Salim',
                                        support: false,
                                      ),
                                    ),
                                  ),
                                  icon: const Icon(Icons.chat_bubble_outline),
                                ),
                              ],
                            ),
                            const Divider(height: 26),
                            KeyValueRow(AppScope.of(context).t('Pickup', 'Kuchukua'), 'Darajani Market'),
                            KeyValueRow(AppScope.of(context).t('Drop-off', 'Kushusha'), 'Zanzibar Airport'),
                            KeyValueRow(AppScope.of(context).t('Distance', 'Umbali'), '9.4 km'),
                            KeyValueRow(AppScope.of(context).t('Est. fare', 'Nauli inayokadiriwa'), 'TZS 18,500'),
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
                            label: const Text('Report rider'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _support,
                            icon: const Icon(Icons.support_agent),
                            label: const Text('ZenjiGO support'),
                          ),
                        ),
                      ],
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
                    if (stage == 2) {
                      final yes = await confirmDialog(
                        context,
                        title: AppScope.of(context).t('End this ride?', 'Maliza safari hii?'),
                        message:
                            'Confirm only after the rider has reached the drop-off location.',
                        confirm: AppScope.of(context).t('End ride', 'Maliza safari'),
                      );
                      if (yes != true) return;
                    }
                    await fakeDelay();
                    if (!mounted) return;
                    if (stage < 3) setState(() => stage++);
                    if (stage == 3) _complete();
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
        'I HAVE ARRIVED',
        'START RIDE',
        AppScope.of(context).t('END RIDE', 'MALIZA SAFARI'),
        AppScope.of(context).t('RIDE COMPLETED', 'SAFARI IMEKAMILIKA'),
      ][stage];

  IconData _icon() => [
        Icons.location_on,
        Icons.play_arrow,
        Icons.stop,
        Icons.check_circle,
      ][stage];

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
            const KeyValueRow('Base fare', 'TZS 4,000'),
            const KeyValueRow('Distance fare', 'TZS 12,500'),
            const KeyValueRow('Time / extras', 'TZS 2,000'),
            const Divider(),
            KeyValueRow(AppScope.of(context).t('Estimated total', 'Jumla inayokadiriwa'), 'TZS 18,500'),
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
                title: const Text('In-app chat'),
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
                onTap: () => toast(context, 'Phone dialer integration point'),
              ),
              ListTile(
                leading: const Icon(Icons.email_outlined),
                title: const Text('zenjigo@support.com'),
                onTap: () => toast(context, 'Email integration point'),
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
          title: const Text('Report rider'),
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
              child: const Text('Continue'),
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
        title: const Text('Ride completed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppScope.of(context).t('Great job! The trip has been completed successfully.', 'Kazi nzuri! Safari imekamilika kwa mafanikio.'),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            KeyValueRow('Fare', 'TZS 18,500'),
            KeyValueRow('Your share', 'TZS 14,800'),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context);
            },
            child: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }
}
