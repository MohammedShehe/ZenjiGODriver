import 'package:flutter/material.dart';
import '../core/widgets.dart';
import '../core/app_state.dart';
import 'registration.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController pc = PageController();
  int index = 0;
  bool location = true, updates = true;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final media = MediaQuery.of(context);
    final isSmall = media.size.height < 700 || media.size.width < 360;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _brandingHeader(context, isSmall: isSmall),
            Expanded(
              child: PageView(
                controller: pc,
                onPageChanged: (v) => setState(() => index = v),
                children: [_about(s), _permissions(s)],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, isSmall ? 12 : 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      2,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: index == i ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: index == i
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: .18),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  LoadingButton(
                    label: index == 0
                        ? s.t('Continue', 'Endelea')
                        : s.t('Allow & continue', 'Ruhusu na uendelee'),
                    icon: Icons.arrow_forward_rounded,
                    onPressed: () async {
                      await fakeDelay(350);
                      if (!context.mounted) return;
                      if (index == 0) {
                        pc.nextPage(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOut,
                        );
                      } else {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegistrationScreen(),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _brandingHeader(BuildContext context, {required bool isSmall}) {
    final headerH = isSmall ? 140.0 : 200.0;
    final logoH = isSmall ? 110.0 : 180.0;
    return SizedBox(
      height: headerH,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: SizedBox(
                  height: logoH,
                  child: ZenjiLogo(height: logoH),
                ),
              ),
            ),
          ),
          Positioned(
            left: 12,
            top: 8,
            child: PopupMenuButton<bool>(
              tooltip: AppScope.of(context).t('Language', 'Lugha'),
              initialValue: AppScope.of(context).isSwahili,
              onSelected: AppScope.of(context).setLanguage,
              itemBuilder: (_) => const [
                PopupMenuItem(value: false, child: Text('English')),
                PopupMenuItem(value: true, child: Text('Kiswahili')),
              ],
              child: Pill(
                AppScope.of(context).isSwahili ? 'Kiswahili' : 'English',
                icon: Icons.language,
              ),
            ),
          ),
          Positioned(
            right: 12,
            top: 4,
            child: Builder(
              builder: (context) {
                final dark = Theme.of(context).brightness == Brightness.dark;
                final s = AppScope.of(context);
                return IconButton.filledTonal(
                  tooltip: dark
                      ? s.t('Use light mode', 'Tumia hali ya mwanga')
                      : s.t('Use dark mode', 'Tumia hali ya giza'),
                  onPressed: () => s.toggleTheme(!dark),
                  icon: Icon(
                    dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _about(AppState s) => ResponsivePage(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            const SizedBox(height: 4),
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: .12),
              ),
              child: Icon(
                Icons.directions_car_filled_rounded,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              s.t('Drive with ZenjiGO', 'Endesha na ZenjiGO'),
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              s.t(
                'ZenjiGO connects trusted drivers with riders across Zanzibar and Tanzania. Earn on your schedule, receive nearby ride requests, track trips live, manage earnings, and get support in one professional driver app.',
                'ZenjiGO inaunganisha madereva waaminifu na abiria Zanzibar na Tanzania. Pata mapato kwa ratiba yako, pokea maombi ya safari karibu, fuatilia safari moja kwa moja, simamia mapato, na upate msaada katika programu moja ya kitaalamu ya madereva.',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                height: 1.5,
                fontSize: 15,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: .72),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                Pill(s.t('Flexible driving', 'Kuendesha kwa urahisi'), icon: Icons.schedule),
                Pill(s.t('Secure earnings', 'Mapato salama'), icon: Icons.account_balance_wallet_outlined),
                Pill(s.t('Driver support', 'Msaada wa dereva'), icon: Icons.support_agent),
              ],
            ),
          ],
        ),
      );

  Widget _permissions(AppState s) => ResponsivePage(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Text(
              s.t('Permissions', 'Ruhusa'),
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              s.t(
                'These permissions help ZenjiGO work properly while you drive.',
                'Ruhusa hizi husaidia ZenjiGO kufanya kazi vizuri unapoendesha.',
              ),
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: .68),
              ),
            ),
            const SizedBox(height: 20),
            _permission(
              Icons.location_on_outlined,
              s.t('Location permission', 'Ruhusa ya mahali'),
              s.t(
                'Required for nearby requests, navigation and live ride tracking.',
                'Inahitajika kwa maombi ya karibu, urambazaji na ufuatiliaji wa safari moja kwa moja.',
              ),
              location,
              (v) => setState(() => location = v),
              isLocation: true,
              s: s,
            ),
            const SizedBox(height: 10),
            _permission(
              Icons.notifications_active_outlined,
              s.t('Updates & offers', 'Taarifa na ofa'),
              s.t(
                'Receive ride activity, driver announcements, bonuses and offers.',
                'Pokea shughuli za safari, matangazo ya madereva, bonasi na ofa.',
              ),
              updates,
              (v) => setState(() => updates = v),
              s: s,
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.privacy_tip_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        s.t(
                          'You can change optional notification preferences later in Settings. Location is required when going online.',
                          'Unaweza kubadilisha mapendeleo ya arifa baadaye kwenye Mipangilio. Mahali inahitajika unapoenda mtandaoni.',
                        ),
                        style: TextStyle(
                          height: 1.4,
                          fontSize: 13,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: .72),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  Widget _permission(
    IconData icon,
    String title,
    String text,
    bool value,
    ValueChanged<bool> cb, {
    bool isLocation = false,
    required AppState s,
  }) =>
      Card(
        child: SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          value: value,
          onChanged: isLocation
              ? (v) {
                  setState(() => location = true);
                  toast(
                    context,
                    s.t(
                      'Location is required for driver services.',
                      'Mahali inahitajika kwa huduma za dereva.',
                    ),
                  );
                }
              : cb,
          secondary: CircleAvatar(
            backgroundColor:
                Theme.of(context).colorScheme.primary.withValues(alpha: .12),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(text, style: const TextStyle(fontSize: 13)),
          ),
        ),
      );
}
