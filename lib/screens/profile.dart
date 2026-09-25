import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import 'chat.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            Expanded(
              child: Text(
                s.t('Profile', 'Wasifu'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            IconButton.filledTonal(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
              icon: const Icon(Icons.settings_outlined),
            ),
          ]),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(children: [
                const CircleAvatar(radius: 42, child: Icon(Icons.person, size: 48)),
                const SizedBox(height: 12),
                Text('Hassan Ali', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(s.t('ZenjiGO Driver • ZG-DRV-01842', 'Dereva wa ZenjiGO • ZG-DRV-01842')),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Pill(s.t('ACTIVE', 'AKTIVU'), color: ZenjiColors.green, icon: Icons.verified),
                    const SizedBox(width: 8),
                    const Pill('★ 4.9', color: ZenjiColors.darkHighlight),
                  ],
                ),
              ]),
            ),
          ),
          const SizedBox(height: 18),
          SectionTitle(s.t('Driver account', 'Akaunti ya dereva')),
          _tile(
            context,
            Icons.person_outline,
            s.t('Personal & vehicle details', 'Taarifa binafsi na za gari'),
            s.t('View all verified profile information', 'Angalia taarifa zote zilizothibitishwa'),
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverDetailsScreen())),
          ),
          _tile(
            context,
            Icons.star_outline,
            s.t('Ratings & reviews', 'Ukadiriaji na maoni'),
            s.t('4.9 average • 238 reviews', 'Wastani 4.9 • Maoni 238'),
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReviewsScreen())),
          ),
          _tile(
            context,
            Icons.description_outlined,
            s.t('Documents', 'Nyaraka'),
            s.t('License, ID, insurance and vehicle photos', 'Leseni, kitambulisho, bima na picha za gari'),
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DocumentsScreen())),
          ),
          const SizedBox(height: 18),
          SectionTitle(s.t('Preferences & safety', 'Mapendeleo na usalama')),
          _tile(
            context,
            Icons.language,
            s.t('Language', 'Lugha'),
            s.isSwahili ? 'Kiswahili' : 'English',
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
          _tile(
            context,
            Icons.emergency_outlined,
            s.t('Emergency & support', 'Dharura na msaada'),
            s.t('Police and ZenjiGO contact options', 'Chaguo za polisi na mawasiliano ya ZenjiGO'),
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyScreen())),
          ),
          _tile(
            context,
            Icons.help_outline,
            s.t('Help & support', 'Msaada'),
            s.t('Chat with ZenjiGO support', 'Ongea na msaada wa ZenjiGO'),
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(name: s.t('ZenjiGO Support', 'Msaada wa ZenjiGO'), support: true),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            s.t('ZenjiGO Driver • Frontend demo', 'ZenjiGO Dereva • Onyesho la frontend'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .45)),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _tile(BuildContext c, IconData i, String t, String sub, VoidCallback tap) => Card(
        margin: const EdgeInsets.only(bottom: 9),
        child: ListTile(
          onTap: tap,
          leading: CircleAvatar(
            backgroundColor: Theme.of(c).colorScheme.primary.withValues(alpha: .12),
            child: Icon(i, color: Theme.of(c).colorScheme.primary),
          ),
          title: Text(t, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(sub),
          trailing: const Icon(Icons.chevron_right),
        ),
      );
}

class DriverDetailsScreen extends StatelessWidget {
  const DriverDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.t('Driver details', 'Taarifa za dereva'))),
      body: ResponsivePage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  KeyValueRow(s.t('Full name', 'Jina kamili'), 'Hassan Ali'),
                  KeyValueRow(s.t('Phone', 'Simu'), '+255 712 345 678'),
                  KeyValueRow(s.t('Email', 'Barua pepe'), 'hassan@example.com'),
                  KeyValueRow(s.t('Driver ID', 'Kitambulisho cha dereva'), 'ZG-DRV-01842'),
                  KeyValueRow(s.t('Address', 'Anwani'), 'Mombasa, Zanzibar'),
                ]),
              ),
            ),
            const SizedBox(height: 14),
            SectionTitle(s.t('Vehicle', 'Gari')),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  KeyValueRow(s.t('Type', 'Aina'), s.t('Taxi', 'Teksi')),
                  KeyValueRow(s.t('Vehicle', 'Gari'), 'Toyota Premio'),
                  KeyValueRow(s.t('Plate no.', 'Namba ya usajili'), 'Z 123 ABC'),
                  KeyValueRow(s.t('Color', 'Rangi'), s.t('White', 'Nyeupe')),
                  KeyValueRow(s.t('Model year', 'Mwaka wa modeli'), '2021'),
                ]),
              ),
            ),
            const SizedBox(height: 18),
            Card(
              child: ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(
                  s.t('Profile changes require admin verification', 'Mabadiliko ya wasifu yanahitaji uthibitisho wa msimamizi'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  s.t(
                    'Drivers cannot directly edit verified identity or vehicle information. Submit a request with the new value and reason.',
                    'Madereva hawawezi kuhariri moja kwa moja taarifa za utambulisho au gari zilizothibitishwa. Tuma ombi na thamani mpya na sababu.',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            LoadingButton(
              label: s.t('Request profile change', 'Omba mabadiliko ya wasifu'),
              icon: Icons.edit_note,
              onPressed: () async {
                await fakeDelay(300);
                if (context.mounted) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileChangeRequestScreen()));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileChangeRequestScreen extends StatefulWidget {
  const ProfileChangeRequestScreen({super.key});
  @override
  State<ProfileChangeRequestScreen> createState() => _ProfileChangeRequestScreenState();
}

class _ProfileChangeRequestScreenState extends State<ProfileChangeRequestScreen> {
  String field = 'Phone';
  final key = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final fields = {
      'Full name': s.t('Full name', 'Jina kamili'),
      'Phone': s.t('Phone', 'Simu'),
      'Email': s.t('Email', 'Barua pepe'),
      'Vehicle type': s.t('Vehicle type', 'Aina ya gari'),
      'Vehicle plate no.': s.t('Vehicle plate no.', 'Namba ya usajili'),
      'Vehicle make / model': s.t('Vehicle make / model', 'Chapa / modeli ya gari'),
      'Address': s.t('Address', 'Anwani'),
    };
    return Scaffold(
      appBar: AppBar(title: Text(s.t('Request profile change', 'Omba mabadiliko ya wasifu'))),
      body: ResponsivePage(
        child: Form(
          key: key,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.t('Admin verification required', 'Uthibitisho wa msimamizi unahitajika'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                s.t(
                  'Your current profile stays unchanged until ZenjiGO reviews and approves this request.',
                  'Wasifu wako wa sasa unabaki bila kubadilika hadi ZenjiGO ikague na kuidhinisha ombi hili.',
                ),
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .66)),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: field,
                items: fields.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                onChanged: (v) => setState(() => field = v!),
                decoration: InputDecoration(labelText: s.t('Information to change', 'Taarifa ya kubadilisha')),
              ),
              const SizedBox(height: 14),
              TextFormField(
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? s.t('New information is required', 'Taarifa mpya inahitajika')
                    : null,
                decoration: InputDecoration(
                  labelText: '${s.t('New', 'Mpya')} ${fields[field] ?? field}',
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                maxLines: 4,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? s.t('Reason is required', 'Sababu inahitajika')
                    : null,
                decoration: InputDecoration(labelText: s.t('Reason for change', 'Sababu ya mabadiliko')),
              ),
              const SizedBox(height: 18),
              LoadingButton(
                label: s.t('Submit request', 'Wasilisha ombi'),
                icon: Icons.send_outlined,
                onPressed: () async {
                  if (!(key.currentState?.validate() ?? false)) return;
                  await fakeDelay();
                  if (!context.mounted) return;
                  await showDialog(
                    context: context,
                    builder: (d) => AlertDialog(
                      icon: const Icon(Icons.schedule_send, size: 42, color: ZenjiColors.green),
                      title: Text(s.t('Request sent', 'Ombi limetumwa')),
                      content: Text(
                        s.t(
                          'ZenjiGO admin will verify the request. Approved changes will automatically reflect on your profile.',
                          'Msimamizi wa ZenjiGO atakagua ombi. Mabadiliko yaliyoidhinishwa yataonekana moja kwa moja kwenye wasifu wako.',
                        ),
                      ),
                      actions: [
                        FilledButton(
                          onPressed: () => Navigator.pop(d),
                          child: Text(s.t('Done', 'Imekamilika')),
                        ),
                      ],
                    ),
                  );
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ReviewsScreen extends StatelessWidget {
  const ReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final reviews = [
      s.t('Very polite and arrived quickly.', 'Mwenye adabu sana na alifika haraka.'),
      s.t('Clean car and safe driving.', 'Gari safi na uendeshaji salama.'),
      s.t('Great communication at pickup.', 'Mawasiliano mazuri wakati wa kuchukua.'),
      s.t('Smooth trip, thank you!', 'Safari nzuri, asante!'),
    ];
    final names = ['Asha S.', 'Juma O.', 'Fatma K.', 'Salma A.'];
    return Scaffold(
      appBar: AppBar(title: Text(s.t('Ratings & reviews', 'Ukadiriaji na maoni'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(children: [
                Text('4.9', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('★★★★★', style: TextStyle(color: Colors.amber, fontSize: 20)),
                      Text(s.t('238 rider reviews', 'Maoni 238 ya abiria')),
                      Text(s.t('Excellent service rating', 'Ukadiriaji bora wa huduma')),
                    ],
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 15),
          ...reviews.asMap().entries.map(
                (e) => Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(names[e.key]),
                    subtitle: Text(e.value),
                    trailing: const Text('★ 5.0', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.t('Documents', 'Nyaraka'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            s.t(
              'Verified documents are read-only. License and insurance can be renewed through an admin-reviewed request.',
              'Nyaraka zilizothibitishwa ni za kusoma tu. Leseni na bima zinaweza kufanywa upya kupitia ombi linalokaguliwa na msimamizi.',
            ),
          ),
          const SizedBox(height: 16),
          _doc(context, s, s.t("Driver's license", 'Leseni ya dereva'), 'DL-ZNZ-884920', s.t('Expires 12 Mar 2027', 'Inaisha 12 Machi 2027'), true),
          _doc(context, s, s.t('National ID', 'Kitambulisho cha taifa'), '1995-02-22-12345', s.t('Verified • No expiry', 'Imethibitishwa • Hakuna mwisho'), false),
          _doc(context, s, s.t('Vehicle insurance', 'Bima ya gari'), 'INS-2026-8821', s.t('Expires 30 Nov 2026', 'Inaisha 30 Nov 2026'), true),
          _doc(context, s, s.t('Vehicle photos', 'Picha za gari'), s.t('5 photos', 'Picha 5'), s.t('Verified 14 Sep 2026', 'Imethibitishwa 14 Sep 2026'), false),
          _doc(context, s, s.t('Driver photo', 'Picha ya dereva'), s.t('Profile identity image', 'Picha ya utambulisho'), s.t('Verified 14 Sep 2026', 'Imethibitishwa 14 Sep 2026'), false),
        ],
      ),
    );
  }

  Widget _doc(BuildContext c, AppState s, String t, String n, String sub, bool renew) => Card(
        margin: const EdgeInsets.only(bottom: 11),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            CircleAvatar(
              backgroundColor: ZenjiColors.green.withValues(alpha: .12),
              child: const Icon(Icons.verified_user_outlined, color: ZenjiColors.green),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t, style: const TextStyle(fontWeight: FontWeight.w900)),
                  Text(n),
                  Text(sub, style: TextStyle(fontSize: 12, color: Theme.of(c).colorScheme.onSurface.withValues(alpha: .6))),
                ],
              ),
            ),
            if (renew)
              FilledButton.tonal(
                onPressed: () => Navigator.push(c, MaterialPageRoute(builder: (_) => RenewDocumentScreen(document: t))),
                child: Text(s.t('Renew', 'Fanya upya')),
              ),
          ]),
        ),
      );
}

class RenewDocumentScreen extends StatefulWidget {
  final String document;
  const RenewDocumentScreen({super.key, required this.document});
  @override
  State<RenewDocumentScreen> createState() => _RenewDocumentScreenState();
}

class _RenewDocumentScreenState extends State<RenewDocumentScreen> {
  late String reason;
  bool uploaded = false;

  @override
  void initState() {
    super.initState();
    reason = 'Document expiring soon';
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final reasons = {
      'Document expiring soon': s.t('Document expiring soon', 'Nyaraka inakaribia kuisha'),
      'Document expired': s.t('Document expired', 'Nyaraka imeisha'),
      'Updated / replaced document': s.t('Updated / replaced document', 'Nyaraka iliyosasishwa / kubadilishwa'),
      'Incorrect document on account': s.t('Incorrect document on account', 'Nyaraka isiyo sahihi kwenye akaunti'),
      'Other': s.t('Other', 'Nyingine'),
    };
    return Scaffold(
      appBar: AppBar(title: Text('${s.t('Renew', 'Fanya upya')} ${widget.document}')),
      body: ResponsivePage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.t('Renewal request', 'Ombi la kufanya upya'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              s.t(
                'The current document remains active until admin approves the replacement.',
                'Nyaraka ya sasa inabaki hai hadi msimamizi aidhinishe mbadala.',
              ),
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<String>(
              initialValue: reason,
              items: reasons.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
              onChanged: (v) => setState(() => reason = v!),
              decoration: InputDecoration(labelText: s.t('Renew reason', 'Sababu ya kufanya upya')),
            ),
            const SizedBox(height: 14),
            Card(
              child: ListTile(
                leading: Icon(uploaded ? Icons.check_circle : Icons.upload_file, color: uploaded ? ZenjiColors.green : null),
                title: Text(
                  uploaded
                      ? s.t('New document attached', 'Nyaraka mpya imeambatishwa')
                      : s.t('Upload new document', 'Pakia nyaraka mpya'),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  uploaded
                      ? 'new_${widget.document.toLowerCase().replaceAll(' ', '_')}.pdf'
                      : s.t('PDF or clear image', 'PDF au picha wazi'),
                ),
                trailing: FilledButton.tonal(
                  onPressed: () => setState(() => uploaded = true),
                  child: Text(uploaded ? s.t('Replace', 'Badilisha') : s.t('Upload', 'Pakia')),
                ),
              ),
            ),
            const SizedBox(height: 18),
            LoadingButton(
              label: s.t('Submit renewal request', 'Wasilisha ombi la kufanya upya'),
              icon: Icons.send,
              onPressed: uploaded
                  ? () async {
                      await fakeDelay();
                      if (!context.mounted) return;
                      await showDialog(
                        context: context,
                        builder: (d) => AlertDialog(
                          icon: const Icon(Icons.hourglass_top, color: ZenjiColors.green, size: 42),
                          title: Text(s.t('Under review', 'Inakaguliwa')),
                          content: Text(
                            s.t(
                              'Your new document has been sent for admin verification. You will be notified if it is approved or rejected. Rejection includes a reason.',
                              'Nyaraka yako mpya imetumwa kwa uthibitisho wa msimamizi. Utajulishwa ikiwa itaidhinishwa au kukataliwa. Kukataliwa kunajumuisha sababu.',
                            ),
                          ),
                          actions: [
                            FilledButton(
                              onPressed: () => Navigator.pop(d),
                              child: Text(s.t('Done', 'Imekamilika')),
                            ),
                          ],
                        ),
                      );
                      if (context.mounted) Navigator.pop(context);
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: Text(s.t('Settings', 'Mipangilio'))),
      body: ResponsivePage(
        child: Column(children: [
          Card(
            child: SwitchListTile(
              value: dark,
              onChanged: s.toggleTheme,
              secondary: Icon(dark ? Icons.dark_mode : Icons.light_mode),
              title: Text(s.t('Dark mode', 'Hali ya giza'), style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(s.t('Dark mode is the first-launch default.', 'Hali ya giza ni chaguo-msingi la kwanza.')),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Column(children: [
              RadioListTile<bool>(
                value: false,
                groupValue: s.isSwahili,
                onChanged: (v) => s.setLanguage(v!),
                title: const Text('English'),
              ),
              RadioListTile<bool>(
                value: true,
                groupValue: s.isSwahili,
                onChanged: (v) => s.setLanguage(v!),
                title: const Text('Kiswahili'),
              ),
            ]),
          ),
          const SizedBox(height: 10),
          Card(
            child: SwitchListTile(
              value: true,
              onChanged: null,
              secondary: const Icon(Icons.notifications_active_outlined),
              title: Text(s.t('Updates & offers', 'Taarifa na ofa'), style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(s.t('Enabled by default for this frontend demo.', 'Imewashwa kwa chaguo-msingi kwa onyesho hili la frontend.')),
            ),
          ),
        ]),
      ),
    );
  }
}

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.t('Emergency & support', 'Dharura na msaada'))),
      body: ResponsivePage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.red.withValues(alpha: .08),
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.redAccent, child: Icon(Icons.local_police, color: Colors.white)),
                title: Text(s.t('Police emergency', 'Dharura ya polisi'), style: const TextStyle(fontWeight: FontWeight.w900)),
                subtitle: Text(s.t('Call local emergency services immediately for urgent danger.', 'Piga huduma za dharura za eneo mara moja kwa hatari ya haraka.')),
                trailing: FilledButton.tonal(
                  onPressed: () => toast(context, s.t('Emergency dialer integration point', 'Sehemu ya kuunganisha kipiga dharura')),
                  child: Text(s.t('Call', 'Piga')),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SectionTitle(s.t('ZenjiGO contact details', 'Maelezo ya mawasiliano ya ZenjiGO')),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  KeyValueRow(s.t('Phone', 'Simu'), '+255 676 891 227'),
                  KeyValueRow(s.t('Email', 'Barua pepe'), 'zenjigo@support.com'),
                  const KeyValueRow('Instagram', '@zenjigo'),
                ]),
              ),
            ),
            const SizedBox(height: 14),
            LoadingButton(
              label: s.t('Open ZenjiGO in-app chat', 'Fungua gumzo la ZenjiGO ndani ya programu'),
              icon: Icons.chat_bubble_outline,
              onPressed: () async {
                await fakeDelay(250);
                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(name: s.t('ZenjiGO Support', 'Msaada wa ZenjiGO'), support: true),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
