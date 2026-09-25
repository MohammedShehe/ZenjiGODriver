import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/mock_map.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import 'active_ride.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool requestShown = false;

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
                            state.t('Welcome, Hassan', 'Karibu, Hassan'),
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
                              onChanged: (value) {
                                state.setOnline(value);
                                if (value && !requestShown) {
                                  setState(() => requestShown = true);
                                  Future.delayed(const Duration(milliseconds: 450), () {
                                    if (mounted) _showRideRequest();
                                  });
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
                    MockMap(
                      height: MediaQuery.sizeOf(context).height < 700 ? 260 : 390,
                      showRequests: state.online,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _stat(Icons.payments_outlined, state.t('Today', 'Leo'), 'TZS 48,500')),
                        const SizedBox(width: 8),
                        Expanded(child: _stat(Icons.route_outlined, state.t('Trips', 'Safari'), '7')),
                        const SizedBox(width: 8),
                        Expanded(child: _stat(Icons.star_rounded, state.t('Rating', 'Ukadiriaji'), '4.9')),
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

  void _showRideRequest() {
    final state = AppScope.of(context);
    showModalBottomSheet<void>(
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
                        '12 sec',
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
                  _route(Icons.trip_origin, state.t('Pickup', 'Kuchukua'), 'Darajani Market, Zanzibar'),
                  _route(
                    Icons.location_on,
                    state.t('Drop-off', 'Kushusha'),
                    'Abeid Amani Karume Airport',
                  ),
                  const Divider(height: 28),
                  Row(
                    children: [
                      Expanded(child: _info(state.t('Estimated fare', 'Nauli inayokadiriwa'), 'TZS 18,500')),
                      Expanded(child: _info(state.t('ETA', 'Muda'), '16 min')),
                      Expanded(child: _info(state.t('Rider', 'Abiria'), '★ 4.8')),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: LoadingButton(
                          label: state.t('Reject', 'Kataa'),
                          outline: true,
                          onPressed: () async {
                            await fakeDelay(300);
                            if (sheetContext.mounted) Navigator.pop(sheetContext);
                            if (mounted) {
                              toast(context, state.t('Ride request rejected', 'Ombi la safari limekataliwa'));
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: LoadingButton(
                          label: state.t('Accept', 'Kubali'),
                          icon: Icons.check,
                          onPressed: () async {
                            await fakeDelay();
                            if (sheetContext.mounted) Navigator.pop(sheetContext);
                            if (mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ActiveRideScreen(),
                                ),
                              );
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
