import 'package:flutter/material.dart';
import '../core/widgets.dart';
import '../core/app_state.dart';
import 'registration.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController pc = PageController();
  int index = 0;
  bool location = true, updates = true;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _brandingHeader(context),
              Expanded(
                child: PageView(
                  controller: pc,
                  onPageChanged: (v) => setState(() => index = v),
                  children: [_about(), _permissions()],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
                child: Column(
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
                    const SizedBox(height: 16),
                    LoadingButton(
                      label: index == 0 ? 'Continue' : 'Allow & continue',
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

  Widget _brandingHeader(BuildContext context) {
    return SizedBox(
      height: 218,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Full-screen center: deliberately independent of the corner controls.
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: SizedBox(
                  height: 200,
                  child: const ZenjiLogo(height: 200),
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            top: 14,
            child: PopupMenuButton<bool>(
              tooltip: 'Language',
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
            right: 20,
            top: 10,
            child: Builder(
              builder: (context) {
                final dark = Theme.of(context).brightness == Brightness.dark;
                return IconButton.filledTonal(
                  tooltip: dark ? 'Use light mode' : 'Use dark mode',
                  onPressed: () => AppScope.of(context).toggleTheme(!dark),
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

  Widget _about() => ResponsivePage(
        child: Column(
          children: [
            const SizedBox(height: 4),
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: .12),
              ),
              child: Icon(
                Icons.directions_car_filled_rounded,
                size: 58,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Drive with ZenjiGO',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            Text(
              'ZenjiGO connects trusted drivers with riders across Zanzibar and Tanzania. Earn on your schedule, receive nearby ride requests, track trips live, manage earnings, and get support in one professional driver app.',
              textAlign: TextAlign.center,
              style: TextStyle(
                height: 1.55,
                fontSize: 16,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: .72),
              ),
            ),
            const SizedBox(height: 28),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: const [
                Pill('Flexible driving', icon: Icons.schedule),
                Pill('Secure earnings', icon: Icons.account_balance_wallet_outlined),
                Pill('Driver support', icon: Icons.support_agent),
              ],
            ),
          ],
        ),
      );

  Widget _permissions() => ResponsivePage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              'Permissions',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              'These permissions help ZenjiGO work properly while you drive.',
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: .68),
              ),
            ),
            const SizedBox(height: 24),
            _permission(
              Icons.location_on_outlined,
              'Location permission',
              'Required for nearby requests, navigation and live ride tracking.',
              location,
              (v) => setState(() => location = v),
            ),
            const SizedBox(height: 12),
            _permission(
              Icons.notifications_active_outlined,
              'Updates & offers',
              'Receive ride activity, driver announcements, bonuses and offers.',
              updates,
              (v) => setState(() => updates = v),
            ),
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.privacy_tip_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You can change optional notification preferences later in Settings. Location is required when going online.',
                        style: TextStyle(
                          height: 1.45,
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
    ValueChanged<bool> cb,
  ) => Card(
        child: SwitchListTile(
          value: value,
          onChanged: title.startsWith('Location')
              ? (v) {
                  setState(() => location = true);
                  toast(context, 'Location is required for driver services.');
                }
              : cb,
          secondary: CircleAvatar(
            backgroundColor:
                Theme.of(context).colorScheme.primary.withValues(alpha: .12),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(text),
          ),
        ),
      );
}
