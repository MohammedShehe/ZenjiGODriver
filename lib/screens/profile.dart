import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import 'chat.dart';
import '../core/api/driver_api.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final p = s.profile ?? <String, dynamic>{};
    String val(List<String> keys, [String fallback = '—']) {
      for (final k in keys) { final v = p[k]; if (v != null && v.toString().trim().isNotEmpty) return v.toString(); }
      return fallback;
    }
    final name = val(['full_name', 'fullName', 'name'], 'Driver');
    final code = val(['driver_code', 'driverCode', 'id']);
    final status = val(['application_status', 'applicationStatus', 'status'], 'Unknown').toUpperCase();
    final rating = val(['rating', 'average_rating', 'averageRating'], '—');
    final reviewCount = val(['review_count', 'reviewCount', 'total_reviews'], '—');
    return SafeArea(child: RefreshIndicator(
      onRefresh: s.refreshProfile,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        Row(children: [
          Expanded(child: Text(s.t('Profile', 'Wasifu'), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900))),
          IconButton(onPressed: s.refreshProfile, icon: const Icon(Icons.refresh)),
        ]),
        const SizedBox(height: 14),
        Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(children: [
          CircleAvatar(radius: 42, backgroundImage: val(['photo_url', 'photoUrl'], '').startsWith('http') ? NetworkImage(val(['photo_url', 'photoUrl'])) : null,
            child: val(['photo_url', 'photoUrl'], '').startsWith('http') ? null : const Icon(Icons.person, size: 48)),
          const SizedBox(height: 12),
          Text(name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text('ZenjiGO Driver • $code'),
          const SizedBox(height: 10),
          Wrap(spacing: 8, children: [
            Pill(status, color: status == 'ACTIVE' || status == 'APPROVED' ? ZenjiColors.green : ZenjiColors.darkHighlight, icon: Icons.verified),
            if (rating != '—') Pill('★ $rating', color: ZenjiColors.darkHighlight),
          ]),
        ]))),
        const SizedBox(height: 18),
        SectionTitle(s.t('Driver account', 'Akaunti ya dereva')),
        _tile(context, Icons.person_outline, s.t('Personal & vehicle details', 'Taarifa binafsi na za gari'),
          s.t('View details returned by your account', 'Angalia taarifa za akaunti yako'),
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverDetailsScreen()))),
        _tile(context, Icons.star_outline, s.t('Ratings & reviews', 'Ukadiriaji na maoni'),
          '$rating average • $reviewCount reviews',
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReviewsScreen()))),
        _tile(context, Icons.description_outlined, s.t('Documents', 'Nyaraka'),
          s.t('View documents and their server-reported status', 'Angalia nyaraka na hali yake'),
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DocumentsScreen()))),
        const SizedBox(height: 18),
        SectionTitle(s.t('Preferences & safety', 'Mapendeleo na usalama')),
        Card(margin: const EdgeInsets.only(bottom: 9), child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: .12),
            child: Icon(Icons.language, color: Theme.of(context).colorScheme.primary),
          ),
          title: Text(s.t('Language', 'Lugha'), style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(s.isSwahili ? 'Kiswahili' : 'English'),
        )),
        _tile(context, Icons.emergency_outlined, s.t('Emergency & support', 'Dharura na msaada'),
          s.t('Contact ZenjiGO support', 'Wasiliana na msaada wa ZenjiGO'),
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyScreen()))),
        _tile(context, Icons.help_outline, s.t('Help & support', 'Msaada'), 'In-app support conversation',
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen(name: 'ZenjiGO Support', support: true)))),
        const SizedBox(height: 20),
        Text('Profile data supplied by ZenjiGO API', textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .45))),
      ]),
    ));
  }

  Widget _tile(BuildContext c, IconData i, String t, String sub, VoidCallback tap) => Card(
    margin: const EdgeInsets.only(bottom: 9),
    child: ListTile(onTap: tap, leading: CircleAvatar(
      backgroundColor: Theme.of(c).colorScheme.primary.withValues(alpha: .12),
      child: Icon(i, color: Theme.of(c).colorScheme.primary)),
      title: Text(t, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text(sub),
      trailing: const Icon(Icons.chevron_right)),
  );
}

class DriverDetailsScreen extends StatelessWidget {
  const DriverDetailsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final p = s.profile ?? <String, dynamic>{};
    String v(List<String> keys) { for (final k in keys) { final x=p[k]; if(x!=null && x.toString().trim().isNotEmpty) return x.toString(); } return '—'; }
    return Scaffold(appBar: AppBar(title: Text(s.t('Driver details', 'Taarifa za dereva'))),
      body: RefreshIndicator(onRefresh: s.refreshProfile, child: ListView(padding: const EdgeInsets.all(16), children: [
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
          KeyValueRow(s.t('Full name','Jina kamili'), v(['full_name','fullName','name'])),
          KeyValueRow(s.t('Phone','Simu'), v(['phone'])),
          KeyValueRow(s.t('Email','Barua pepe'), v(['email'])),
          KeyValueRow(s.t('Driver ID','Kitambulisho cha dereva'), v(['driver_code','driverCode','id'])),
          KeyValueRow(s.t('Address','Anwani'), v(['home_address','homeAddress','address'])),
          KeyValueRow(s.t('Application status','Hali ya ombi'), v(['application_status','applicationStatus','status'])),
        ]))),
        const SizedBox(height: 14), SectionTitle(s.t('Vehicle','Gari')),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
          KeyValueRow(s.t('Type','Aina'), v(['vehicle_type','vehicleType','type'])),
          KeyValueRow(s.t('Vehicle make','Chapa ya gari'), v(['make','vehicleMake'])),
          KeyValueRow(s.t('Model','Modeli'), v(['model','vehicleModel'])),
          KeyValueRow(s.t('Plate no.','Namba ya usajili'), v(['plate_number','plateNumber'])),
          KeyValueRow(s.t('Color','Rangi'), v(['color','vehicleColor'])),
          KeyValueRow(s.t('Model year','Mwaka wa modeli'), v(['model_year','modelYear'])),
        ]))),
        const SizedBox(height: 14),
        const Card(child: ListTile(leading: Icon(Icons.info_outline), title: Text('Verified profile changes must be reviewed by ZenjiGO administration.'))),
      ])));
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
    final p = s.profile ?? <String, dynamic>{};
    final rating = p['rating'] ?? p['average_rating'] ?? p['averageRating'];
    final count = p['review_count'] ?? p['reviewCount'] ?? p['total_reviews'];
    return Scaffold(appBar: AppBar(title: Text(s.t('Ratings & reviews', 'Ukadiriaji na maoni')),
      actions: [IconButton(onPressed: s.refreshProfile, icon: const Icon(Icons.refresh))]),
      body: RefreshIndicator(onRefresh: s.refreshProfile, child: ListView(padding: const EdgeInsets.all(16), children: [
        Card(child: Padding(padding: const EdgeInsets.all(18), child: Row(children: [
          Text(rating?.toString() ?? '—', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('★', style: TextStyle(color: Colors.amber, fontSize: 24)),
            Text('${count?.toString() ?? '—'} rider reviews'),
            const Text('Rating summary returned by your driver profile API'),
          ])),
        ]))),
        const SizedBox(height: 12),
        const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Individual review records are not exposed by the current driver API. No sample reviews are displayed.'))),
      ])));
  }
}

class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});
  String _label(String value) {
    switch (value.toLowerCase()) {
      case 'drivers_license': return "Driver's license";
      case 'national_id': return 'National ID';
      case 'insurance': return 'Vehicle insurance';
      case 'driver_photo': return 'Driver photo';
      case 'vehicle_photo': return 'Vehicle photo';
      default: return value.replaceAll('_', ' ');
    }
  }
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Scaffold(appBar: AppBar(title: Text(s.t('Documents', 'Nyaraka'))),
      body: FutureBuilder<List<dynamic>>(future: DriverApi.documents(), builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_off_outlined, size: 42), const SizedBox(height: 10),
          Text(snapshot.error.toString().replaceFirst('Exception: ', ''), textAlign: TextAlign.center),
          const SizedBox(height: 10), FilledButton(onPressed: () { (context as Element).markNeedsBuild(); }, child: const Text('Retry')),
        ])));
        final docs = snapshot.data ?? [];
        if (docs.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No documents were returned by the server.')));
        return ListView(padding: const EdgeInsets.all(16), children: [
          const Text('Document status and metadata are loaded from ZenjiGO.'),
          const SizedBox(height: 12),
          ...docs.whereType<Map>().map((item) {
            final d = Map<String, dynamic>.from(item);
            final type = (d['document_type'] ?? d['documentType'] ?? 'Document').toString();
            final status = (d['status'] ?? 'unknown').toString();
            final date = d['expires_at'] ?? d['expiresAt'];
            final reason = d['rejection_reason'] ?? d['rejectionReason'];
            return Card(margin: const EdgeInsets.only(bottom: 10), child: ListTile(
              leading: CircleAvatar(child: Icon(status.toLowerCase() == 'approved' || status.toLowerCase() == 'verified' ? Icons.verified_user : Icons.description_outlined)),
              title: Text(_label(type), style: const TextStyle(fontWeight: FontWeight.w900)),
              subtitle: Text('Status: $status${date == null ? '' : '\\nExpires: $date'}${reason == null ? '' : '\\nReason: $reason'}'),
              isThreeLine: date != null || reason != null,
              trailing: d['url'] != null ? const Icon(Icons.link) : null,
              onTap: () { final url = d['url']; if (url != null) toast(context, url.toString()); },
            ));
          }),
        ]);
      }),
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
                  KeyValueRow(s.t('Phone', 'Simu'), (s.profile?['support_phone'] ?? s.profile?['supportPhone'] ?? '—').toString()),
                  KeyValueRow(s.t('Email', 'Barua pepe'), (s.profile?['support_email'] ?? s.profile?['supportEmail'] ?? '—').toString()),
                ]),
              ),
            ),
            const SizedBox(height: 14),
            LoadingButton(
              label: s.t('Open ZenjiGO in-app chat', 'Fungua gumzo la ZenjiGO ndani ya programu'),
              icon: Icons.chat_bubble_outline,
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ChatScreen(name: s.t('ZenjiGO Support', 'Msaada wa ZenjiGO'), support: true),
                ));
              },
            ),
          ],
        ),
      ),
    );
  }
}
