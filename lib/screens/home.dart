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

    return SafeArea(
      child: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
                child: Row(
                  children: [
                    const CircleAvatar(radius: 23, child: Icon(Icons.person)),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Karibu, Hassan',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          Text(
                            state.online
                                ? 'You are available for rides'
                                : 'Go online to receive rides',
                            style: TextStyle(
                              fontSize: 12,
                              color: state.online
                                  ? ZenjiColors.green
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: .56),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 7, 7, 7),
                      decoration: BoxDecoration(
                        color: (state.online
                                ? ZenjiColors.green
                                : Theme.of(context).colorScheme.onSurface)
                            .withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Row(
                        children: [
                          Text(
                            state.online ? 'ONLINE' : 'OFFLINE',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
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
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                  children: [
                    MockMap(
                      height: MediaQuery.sizeOf(context).height < 700 ? 300 : 390,
                      showRequests: state.online,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _stat(Icons.payments_outlined, 'Today', 'TZS 48,500')),
                        const SizedBox(width: 10),
                        Expanded(child: _stat(Icons.route_outlined, 'Trips', '7')),
                        const SizedBox(width: 10),
                        Expanded(child: _stat(Icons.star_rounded, 'Rating', '4.9')),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const SectionTitle('Nearby activity'),
                    Card(
                      child: state.online
                          ? const ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Color(0x2234A853),
                                child: Icon(Icons.radar, color: ZenjiColors.green),
                              ),
                              title: Text(
                                'Searching for nearby riders',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                              subtitle: Text(
                                'Stay online. New requests will appear automatically.',
                              ),
                              trailing: SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : const ListTile(
                              leading: CircleAvatar(
                                child: Icon(Icons.power_settings_new),
                              ),
                              title: Text(
                                'You are offline',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                              subtitle: Text(
                                'Turn on Online mode to receive ride requests.',
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
              left: 34,
              right: 34,
              bottom: 24,
              child: ElevatedButton.icon(
                onPressed: () => state.setOnline(true),
                icon: const Icon(Icons.power_settings_new),
                label: const Text('GO ONLINE'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String label, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 7),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .55),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRideRequest() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              14,
              20,
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
                    const Pill(
                      'NEW RIDE',
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
                  'Ride request',
                  style: Theme.of(sheetContext).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 16),
                _route(Icons.trip_origin, 'Pickup', 'Darajani Market, Zanzibar'),
                _route(
                  Icons.location_on,
                  'Drop-off',
                  'Abeid Amani Karume Airport',
                ),
                const Divider(height: 28),
                Row(
                  children: [
                    Expanded(child: _info('Estimated fare', 'TZS 18,500')),
                    Expanded(child: _info('ETA', '16 min')),
                    Expanded(child: _info('Rider', '★ 4.8')),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: LoadingButton(
                        label: 'Reject',
                        outline: true,
                        onPressed: () async {
                          await fakeDelay(300);
                          if (sheetContext.mounted) Navigator.pop(sheetContext);
                          if (mounted) toast(context, 'Ride request rejected');
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: LoadingButton(
                        label: 'Accept',
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
        ),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
      ],
    );
  }
}
