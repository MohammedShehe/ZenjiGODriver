import 'dart:async';
import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/api/driver_api.dart';
import '../core/live_map.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import 'active_ride.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _lastPromptedRequestId;
  bool _prompting = false;
  Timer? _requestTimer;

  @override
  void initState() {
    super.initState();
    _requestTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted) return;
      final state = AppScope.of(context);
      if (state.online && !_prompting) _showRideRequest();
    });
  }

  @override
  void dispose() {
    _requestTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final isNarrow = MediaQuery.sizeOf(context).width < 360;

    return SafeArea(
      child: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(isNarrow ? 12 : 18, 12, isNarrow ? 12 : 18, 10),
                child: Row(
                  children: [
                    const CircleAvatar(radius: 23, child: Icon(Icons.person)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${state.t('Welcome', 'Karibu')}, ${state.displayName}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            state.online
                                ? state.t('You are available for rides', 'Uko tayari kwa safari')
                                : state.t('Go online to receive rides', 'Nenda mtandaoni kupokea safari'),
                            style: TextStyle(
                              fontSize: 12,
                              color: state.online
                                  ? ZenjiColors.green
                                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: .56),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(10, 4, 4, 4),
                        decoration: BoxDecoration(
                          color: (state.online
                                  ? ZenjiColors.green
                                  : Theme.of(context).colorScheme.onSurface)
                              .withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              state.online
                                  ? state.t('ONLINE', 'MTANDAONI')
                                  : state.t('OFFLINE', 'NJE YA MTANDAO'),
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: isNarrow ? 9 : 11,
                                color: state.online ? ZenjiColors.green : null,
                              ),
                            ),
                            Switch(
                              value: state.online,
                              onChanged: (value) async {
                                final messenger = ScaffoldMessenger.maybeOf(context);
                                try {
                                  await state.setOnlineRemote(value);
                                  if (value) _showRideRequest();
                                } catch (e) {
                                  if (mounted && messenger != null) {
                                    messenger.showSnackBar(
                                      SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                                    );
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(isNarrow ? 12 : 18, 0, isNarrow ? 12 : 18, 20),
                  children: [
                    LiveDriverMap(
                      height: MediaQuery.sizeOf(context).height < 700 ? 260 : 390,
                      showRequests: state.online,
                      shareLocation: state.online,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _stat(Icons.payments_outlined, state.t('Today', 'Leo'), 'TZS ${state.finance?['todayEarnings'] ?? state.finance?['today_earnings'] ?? 0}')),
                        const SizedBox(width: 8),
                        Expanded(child: _stat(Icons.route_outlined, state.t('Trips', 'Safari'), '${state.finance?['todayTrips'] ?? state.finance?['today_trips'] ?? 0}')),
                        const SizedBox(width: 8),
                        Expanded(child: _stat(Icons.star_rounded, state.t('Rating', 'Ukadiriaji'), '${state.profile?['rating'] ?? '—'}')),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SectionTitle(state.t('Nearby activity', 'Shughuli za karibu')),
                    Card(
                      child: state.online
                          ? ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0x2234A853),
                                child: Icon(Icons.radar, color: ZenjiColors.green),
                              ),
                              title: Text(
                                state.t('Searching for nearby riders', 'Inatafuta abiria wa karibu'),
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                              subtitle: Text(
                                state.t(
                                  'Stay online. New requests will appear automatically.',
                                  'Kaa mtandaoni. Maombi mapya yataonekana moja kwa moja.',
                                ),
                              ),
                              trailing: const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.power_settings_new),
                              ),
                              title: Text(
                                state.t('You are offline', 'Uko nje ya mtandao'),
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                              subtitle: Text(
                                state.t(
                                  'Turn on Online mode to receive ride requests.',
                                  'Washa hali ya Mtandaoni kupokea maombi ya safari.',
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!state.online)
            Positioned(
              left: isNarrow ? 20 : 34,
              right: isNarrow ? 20 : 34,
              bottom: 24,
              child: ElevatedButton.icon(
                onPressed: () => state.setOnline(true),
                icon: const Icon(Icons.power_settings_new),
                label: Text(state.t('GO ONLINE', 'NENDA MTANDAONI')),
              ),
            ),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String label, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13), overflow: TextOverflow.ellipsis),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .55),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRideRequest() async {
    if (_prompting || !mounted || !AppScope.of(context).online) return;
    _prompting = true;
    final state = AppScope.of(context);
    Map<String,dynamic> request={};
    try {
      final result=await DriverApi.requests();
      if(result['restricted']==true){
        if(mounted) _showSettlementRequired(result);
        return;
      }
      final raw = result['requests'] ?? result['data'] ?? [];
      final list = raw is List ? raw : <dynamic>[];
      if(list.isEmpty) return;
      final next = list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).firstWhere(
        (r) => '${r['id'] ?? ''}' != (_lastPromptedRequestId ?? ''),
        orElse: () => <String, dynamic>{},
      );
      if (next.isEmpty) return;
      request = next;
      _lastPromptedRequestId = '${request['id'] ?? ''}';
    } catch(e) { if(mounted) toast(context,e.toString().replaceFirst('Exception: ','')); return; }
    finally { _prompting = false; }
    if(!mounted) return;
    final pickup=request['pickupAddress'] ?? request['pickup_address'] ?? 'Nearby pickup';
    final drop=request['destinationAddress'] ?? request['destination_address'] ?? 'Destination';
    final fare=(request['fare'] ?? request['estimatedFare'] ?? request['estimated_fare'] ?? 0).toString();

    _prompting = true;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                14,
                16,
                20 + MediaQuery.viewInsetsOf(sheetContext).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: .35),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Pill(
                        state.t('NEW RIDE', 'SAFARI MPYA'),
                        color: ZenjiColors.green,
                        icon: Icons.notifications_active,
                      ),
                      const Spacer(),
                      Text(
                        'Ride #${request['id'] ?? '—'}',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Theme.of(sheetContext).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.t('Ride request', 'Ombi la safari'),
                    style: Theme.of(sheetContext).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 16),
                  _route(Icons.trip_origin, state.t('Pickup', 'Kuchukua'), pickup),
                  _route(
                    Icons.location_on,
                    state.t('Drop-off', 'Kushusha'),
                    drop,
                  ),
                  const Divider(height: 28),
                  Row(
                    children: [
                      Expanded(child: _info(state.t('Estimated fare', 'Nauli inayokadiriwa'), 'TZS $fare')),
                      Expanded(child: _info(state.t('Ride type', 'Aina ya safari'), '${request['rideType'] ?? request['ride_type'] ?? '—'}')),
                      Expanded(child: _info(state.t('Status', 'Hali'), '${request['status'] ?? 'Requested'}')),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: LoadingButton(
                          label: state.t('Dismiss', 'Funga'),
                          outline: true,
                          onPressed: () async {
                            if (sheetContext.mounted) Navigator.pop(sheetContext);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: LoadingButton(
                          label: state.t('Accept', 'Kubali'),
                          icon: Icons.check,
                          onPressed: () async {
                            try {
                              final rideId = request['id'].toString();
                              await DriverApi.accept(rideId);
                              AppScope.of(context).setActiveRideId(rideId);
                              if (sheetContext.mounted) Navigator.pop(sheetContext);
                              if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => ActiveRideScreen(rideId: rideId)));
                            } catch(e) {
                              if(sheetContext.mounted) Navigator.pop(sheetContext);
                              if(mounted) toast(context,e.toString().replaceFirst('Exception: ',''));
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    _prompting = false;
  }

  void _showSettlementRequired(Map<String, dynamic> data) {
    final appScope = AppScope.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    showDialog(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Settlement required'),
        content: Text(
          'You have reached the TZS ${data['threshold'] ?? 60000} earning threshold. Amount owed to ZenjiGO: TZS ${data['commissionOwed'] ?? 0}. Settle the balance before accepting new rides. Nearby requests remain anonymized.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Close')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(d);
              try {
                await DriverApi.settle();
                await appScope.refreshFinance();
                if (mounted && messenger != null) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Settlement created. Complete the payment through your configured provider.')),
                  );
                }
              } catch (e) {
                if (mounted && messenger != null) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                  );
                }
              }
            },
            child: const Text('Start settlement'),
          ),
        ],
      ),
    );
  }

  Widget _route(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: .12),
            child: Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .55),
                  ),
                ),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _info(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .55),
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900), overflow: TextOverflow.ellipsis),
      ],
    );
  }
}
