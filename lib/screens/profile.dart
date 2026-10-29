import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../core/app_state.dart';
import '../core/friendly_errors.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import 'package:http/http.dart' as http;
import '../core/api/driver_api.dart';
import '../core/api/api_client.dart';
import 'chat.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool uploadingPhoto = false;

  Future<void> _pickAndUploadPhoto() async {
    final s = AppScope.of(context);
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: false);
      if (result == null || result.files.isEmpty || result.files.first.path == null) return;
      setState(() => uploadingPhoto = true);
      await DriverApi.updateProfilePhoto(result.files.first.path!);
      await s.refreshProfile();
      if (mounted) toast(context, s.t('Profile photo updated', 'Picha ya wasifu imesasishwa'));
    } catch (e) {
      if (mounted) toast(context, FriendlyErrors.message(e, swahili: AppScope.of(context).isSwahili));
    } finally {
      if (mounted) setState(() => uploadingPhoto = false);
    }
  }

  Future<void> _removePhoto() async {
    final s = AppScope.of(context);
    try {
      await DriverApi.removeProfilePhoto();
      await s.refreshProfile();
      if (mounted) toast(context, s.t('Profile photo removed', 'Picha ya wasifu imeondolewa'));
    } catch (e) {
      if (mounted) toast(context, FriendlyErrors.message(e, swahili: AppScope.of(context).isSwahili));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final p = s.profile ?? <String, dynamic>{};
    String val(List<String> keys, [String fallback = '—']) {
      for (final k in keys) {
        final v = p[k];
        if (v != null && v.toString().trim().isNotEmpty) return v.toString();
      }
      return fallback;
    }
    final name = val(['full_name', 'fullName', 'name'], 'Driver');
    final code = val(['driver_code', 'driverCode', 'id']);
    final status = val(['application_status', 'applicationStatus', 'status'], 'Unknown').toUpperCase();
    final rating = val(['rating', 'average_rating', 'averageRating'], '—');
    final reviewCount = val(['review_count', 'reviewCount', 'total_reviews', 'total_rides'], '—');
    final photo = val(['photo_url', 'photoUrl'], '');

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: s.refreshProfile,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(children: [
              Expanded(child: Text(s.t('Profile', 'Wasifu'), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900))),
              IconButton(onPressed: s.refreshProfile, icon: const Icon(Icons.refresh)),
            ]),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(children: [
                  Stack(alignment: Alignment.bottomRight, children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundImage: photo.startsWith('http') ? NetworkImage(photo) : null,
                      child: photo.startsWith('http')
                          ? null
                          : const Icon(Icons.person, size: 52),
                    ),
                    if (uploadingPhoto)
                      const Positioned.fill(child: Center(child: CircularProgressIndicator()))
                    else
                      Material(
                        color: Theme.of(context).colorScheme.primary,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () async {
                            final action = await showModalBottomSheet<String>(
                              context: context,
                              builder: (d) => SafeArea(
                                child: Column(mainAxisSize: MainAxisSize.min, children: [
                                  ListTile(
                                    leading: const Icon(Icons.photo_camera_outlined),
                                    title: Text(s.t('Upload / change photo', 'Pakia / badilisha picha')),
                                    onTap: () => Navigator.pop(d, 'upload'),
                                  ),
                                  if (photo.startsWith('http'))
                                    ListTile(
                                      leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                      title: Text(s.t('Remove photo', 'Ondoa picha')),
                                      onTap: () => Navigator.pop(d, 'remove'),
                                    ),
                                  ListTile(
                                    leading: const Icon(Icons.close),
                                    title: Text(s.t('Cancel', 'Ghairi')),
                                    onTap: () => Navigator.pop(d),
                                  ),
                                ]),
                              ),
                            );
                            if (action == 'upload') await _pickAndUploadPhoto();
                            if (action == 'remove') await _removePhoto();
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(Icons.camera_alt, size: 18, color: Colors.white),
                          ),
                        ),
                      ),
                  ]),
                  const SizedBox(height: 12),
                  Text(name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text('ZenjiGO Driver • $code'),
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, children: [
                    Pill(status, color: status == 'ACTIVE' || status == 'APPROVED' ? ZenjiColors.green : ZenjiColors.darkHighlight, icon: Icons.verified),
                    if (rating != '—') Pill('★ $rating', color: ZenjiColors.darkHighlight),
                  ]),
                ]),
              ),
            ),
            const SizedBox(height: 18),
            SectionTitle(s.t('Driver account', 'Akaunti ya dereva')),
            _tile(context, Icons.person_outline, s.t('Personal & vehicle details', 'Taarifa binafsi na za gari'),
                s.t('View details returned by your account', 'Angalia taarifa za akaunti yako'),
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverDetailsScreen()))),
            _tile(context, Icons.star_outline, s.t('Ratings & reviews', 'Ukadiriaji na maoni'),
                '$rating average • $reviewCount reviews',
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReviewsScreen()))),
            _tile(context, Icons.description_outlined, s.t('Documents', 'Nyaraka'),
                s.t('Preview documents and expiry dates', 'Angalia nyaraka na tarehe za mwisho'),
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DocumentsScreen()))),
            const SizedBox(height: 18),
            SectionTitle(s.t('Request information updates', 'Omba masasisho ya taarifa')),
            _tile(context, Icons.edit_note_outlined, s.t('Update profile info', 'Sasisha taarifa za wasifu'),
                s.t('Name, phone, email, address — admin approval required', 'Jina, simu, barua pepe, anwani — inahitaji idhini'),
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileChangeRequestScreen()))),
            _tile(context, Icons.directions_car_outlined, s.t('Update vehicle details', 'Sasisha taarifa za gari'),
                s.t('Plate, make, model, color — admin approval required', 'Namba, chapa, modeli, rangi — inahitaji idhini'),
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VehicleChangeRequestScreen()))),
            _tile(context, Icons.upload_file_outlined, s.t('Update a document', 'Sasisha nyaraka'),
                s.t('License, ID, insurance — admin approval required', 'Leseni, kitambulisho, bima — inahitaji idhini'),
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DocumentChangeRequestScreen()))),
            _tile(context, Icons.history, s.t('My change requests', 'Maombi yangu ya mabadiliko'),
                s.t('Track pending, updated or rejected requests', 'Fuatilia maombi yanayosubiri, yaliyosasishwa au yaliyokataliwa'),
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangeRequestsListScreen()))),
            const SizedBox(height: 18),
            SectionTitle(s.t('Preferences & safety', 'Mapendeleo na usalama')),
            Card(
              margin: const EdgeInsets.only(bottom: 9),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: .12),
                  child: Icon(Icons.language, color: Theme.of(context).colorScheme.primary),
                ),
                title: Text(s.t('Language', 'Lugha'), style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(s.isSwahili ? 'Kiswahili' : 'English'),
                trailing: Switch(
                  value: s.isSwahili,
                  onChanged: (v) => s.setLanguage(v),
                ),
              ),
            ),
            _tile(context, Icons.emergency_outlined, s.t('Emergency & support', 'Dharura na msaada'),
                s.t('Contact ZenjiGO support', 'Wasiliana na msaada wa ZenjiGO'),
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyScreen()))),
            _tile(context, Icons.help_outline, s.t('Help & support', 'Msaada'), 'In-app support conversation',
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen(name: 'ZenjiGO Support', support: true)))),
            const SizedBox(height: 20),
            LoadingButton(
              label: s.t('Log out', 'Toka'),
              icon: Icons.logout,
              outline: true,
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (d) => AlertDialog(
                    title: Text(s.t('Log out?', 'Toka?')),
                    content: Text(s.t('You will need to sign in again to continue.', 'Utahitaji kuingia tena kuendelea.')),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(d, false), child: Text(s.t('Cancel', 'Ghairi'))),
                      FilledButton(onPressed: () => Navigator.pop(d, true), child: Text(s.t('Log out', 'Toka'))),
                    ],
                  ),
                );
                if (ok != true || !context.mounted) return;
                await s.logout();
                if (!context.mounted) return;
                Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
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
    final p = s.profile ?? <String, dynamic>{};
    String v(List<String> keys) {
      for (final k in keys) {
        final x = p[k];
        if (x != null && x.toString().trim().isNotEmpty) return x.toString();
      }
      return '—';
    }
    return Scaffold(
      appBar: AppBar(title: Text(s.t('Driver details', 'Taarifa za dereva'))),
      body: RefreshIndicator(
        onRefresh: s.refreshProfile,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                KeyValueRow(s.t('Full name', 'Jina kamili'), v(['full_name', 'fullName', 'name'])),
                KeyValueRow(s.t('Phone', 'Simu'), v(['phone'])),
                KeyValueRow(s.t('Email', 'Barua pepe'), v(['email'])),
                KeyValueRow(s.t('Driver ID', 'Kitambulisho cha dereva'), v(['driver_code', 'driverCode', 'id'])),
                KeyValueRow(s.t('Address', 'Anwani'), v(['home_address', 'homeAddress', 'address'])),
                KeyValueRow(s.t('Application status', 'Hali ya ombi'), v(['application_status', 'applicationStatus', 'status'])),
              ]),
            ),
          ),
          const SizedBox(height: 14),
          SectionTitle(s.t('Vehicle', 'Gari')),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                KeyValueRow(s.t('Type', 'Aina'), v(['vehicle_type', 'vehicleType', 'type'])),
                KeyValueRow(s.t('Plate', 'Namba'), v(['plate_number', 'plateNumber'])),
                KeyValueRow(s.t('Make', 'Chapa'), v(['make', 'vehicleMake'])),
                KeyValueRow(s.t('Model', 'Modeli'), v(['model', 'vehicleModel'])),
                KeyValueRow(s.t('Color', 'Rangi'), v(['color', 'vehicleColor'])),
                KeyValueRow(s.t('Year', 'Mwaka'), v(['model_year', 'modelYear'])),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});
  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  List<dynamic> items = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    try {
      final rows = await DriverApi.reviews();
      if (!mounted) return;
      setState(() { items = rows; loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { loading = false; error = FriendlyErrors.message(e, swahili: AppScope.of(context).isSwahili); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final p = s.profile ?? {};
    final avg = (p['rating'] ?? p['average_rating'] ?? '—').toString();
    return Scaffold(
      appBar: AppBar(title: Text(s.t('Ratings & reviews', 'Ukadiriaji na maoni')), actions: [
        IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
      ]),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.star)),
                title: Text('★ $avg', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
                subtitle: Text(s.t('Overall driver rating from riders', 'Ukadiriaji wa jumla kutoka kwa abiria')),
              ),
            ),
            const SizedBox(height: 12),
            if (loading) const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
            if (error != null) Text(error!, style: const TextStyle(color: Colors.redAccent)),
            if (!loading && items.isEmpty && error == null)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(s.t('No reviews yet. Complete rides to receive ratings.', 'Bado hakuna maoni. Maliza safari kupokea ukadiriaji.'), textAlign: TextAlign.center),
              ),
            ...items.map((raw) {
              final r = Map<String, dynamic>.from(raw is Map ? raw : {});
              final stars = (int.tryParse('${r['rating'] ?? 0}') ?? 0).clamp(0, 5);
              final name = (r['riderName'] ?? r['rider_name'] ?? 'Rider').toString();
              final comment = (r['comment'] ?? '').toString();
              final when = (r['createdAt'] ?? r['created_at'] ?? '').toString();
              final photo = (r['riderPhoto'] ?? r['rider_photo'] ?? '').toString();
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: photo.startsWith('http') ? NetworkImage(photo) : null,
                    child: photo.startsWith('http') ? null : Text(name.isNotEmpty ? name[0].toUpperCase() : 'R'),
                  ),
                  title: Row(children: [
                    Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w800))),
                    Text('★' * stars + '☆' * (5 - stars), style: const TextStyle(color: Colors.amber, fontSize: 14)),
                  ]),
                  subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (comment.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(comment)),
                    if (when.isNotEmpty) Text(when, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .5))),
                  ]),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});
  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  List<dynamic> items = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    try {
      final rows = await DriverApi.documents();
      if (!mounted) return;
      setState(() { items = rows; loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { loading = false; error = FriendlyErrors.message(e, swahili: AppScope.of(context).isSwahili); });
    }
  }

  void _openPreview(String url, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(title)),
          body: InteractiveViewer(
            child: Center(
              child: url.toLowerCase().contains('.pdf')
                  ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.picture_as_pdf, size: 72),
                      const SizedBox(height: 12),
                      SelectableText(url, textAlign: TextAlign.center),
                    ])
                  : Image.network(
                      url,
                      fit: BoxFit.contain,
                      loadingBuilder: (_, child, prog) => prog == null ? child : const Center(child: CircularProgressIndicator()),
                      errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image_outlined, size: 64)),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.t('Documents', 'Nyaraka')), actions: [
        IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
      ]),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (loading) const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
            if (error != null) Text(error!, style: const TextStyle(color: Colors.redAccent)),
            if (!loading && items.isEmpty && error == null)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(s.t('No documents found on your account.', 'Hakuna nyaraka kwenye akaunti yako.'), textAlign: TextAlign.center),
              ),
            ...items.map((raw) {
              final d = Map<String, dynamic>.from(raw is Map ? raw : {});
              final url = (d['url'] ?? '').toString();
              final type = (d['document_type'] ?? d['documentType'] ?? d['type'] ?? 'Document').toString();
              final status = (d['status'] ?? 'pending').toString();
              final expires = (d['expires_at'] ?? d['expiresAt'] ?? '').toString();
              final lower = url.toLowerCase();
              final isImage = lower.contains('.jpg') || lower.contains('.jpeg') || lower.contains('.png') || lower.contains('.webp') || lower.contains('/image/') || (d['resource_type']?.toString() == 'image');
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: url.isEmpty ? null : () => _openPreview(url, type),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    if (url.isNotEmpty && isImage)
                      Image.network(
                        url,
                        height: 180,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, prog) => prog == null
                            ? child
                            : Container(height: 180, alignment: Alignment.center, child: const CircularProgressIndicator()),
                        errorBuilder: (_, __, ___) => Container(
                          height: 120,
                          alignment: Alignment.center,
                          color: Colors.black12,
                          child: const Icon(Icons.broken_image_outlined, size: 40),
                        ),
                      )
                    else if (url.isNotEmpty)
                      Container(height: 80, alignment: Alignment.center, child: const Icon(Icons.picture_as_pdf, size: 40)),
                    ListTile(
                      title: Text(type, style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text([
                        '${s.t('Status', 'Hali')}: $status',
                        if (expires.isNotEmpty) '${s.t('Expires', 'Inaisha')}: $expires',
                        if (url.isNotEmpty) s.t('Tap to preview', 'Gusa kuona'),
                      ].join(' · ')),
                      trailing: Pill(status.toUpperCase(), color: status.toLowerCase() == 'approved' ? ZenjiColors.green : ZenjiColors.darkHighlight),
                    ),
                  ]),
                ),
              );
            }),
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
  final formKey = GlobalKey<FormState>();
  String field = 'full_name';
  final valueCtrl = TextEditingController();
  final reasonCtrl = TextEditingController();
  bool sending = false;

  final fields = const {
    'full_name': 'Full name / Jina kamili',
    'phone': 'Phone / Simu',
    'email': 'Email / Barua pepe',
    'home_address': 'Home address / Anwani',
    'national_id': 'National ID / Kitambulisho',
  };

  @override
  void dispose() {
    valueCtrl.dispose();
    reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    setState(() => sending = true);
    final s = AppScope.of(context);
    try {
      await DriverApi.requestProfileChange(field: field, newValue: valueCtrl.text.trim(), reason: reasonCtrl.text.trim());
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (d) => AlertDialog(
          icon: const Icon(Icons.schedule_send, size: 42, color: ZenjiColors.green),
          title: Text(s.t('Request sent', 'Ombi limetumwa')),
          content: Text(s.t(
            'Your profile stays unchanged until ZenjiGO admin approves. Status will show as Updated or Rejected.',
            'Wasifu wako unabaki bila kubadilika hadi msimamizi aidhinishe. Hali itaonekana Updated au Rejected.',
          )),
          actions: [FilledButton(onPressed: () => Navigator.pop(d), child: Text(s.t('OK', 'Sawa')))],
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) toast(context, FriendlyErrors.message(e, swahili: AppScope.of(context).isSwahili));
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.t('Update profile info', 'Sasisha taarifa za wasifu'))),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(s.t('Select what to change, enter the new value and reason.', 'Chagua unachotaka kubadilisha, weka thamani mpya na sababu.')),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: field,
              items: fields.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
              onChanged: (v) => setState(() => field = v!),
              decoration: InputDecoration(labelText: s.t('Field to change', 'Sehemu ya kubadilisha')),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: valueCtrl,
              validator: (v) => (v == null || v.trim().isEmpty) ? s.t('New value is required', 'Thamani mpya inahitajika') : null,
              decoration: InputDecoration(labelText: s.t('New value', 'Thamani mpya')),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: reasonCtrl,
              maxLines: 3,
              validator: (v) => (v == null || v.trim().isEmpty) ? s.t('Reason is required', 'Sababu inahitajika') : null,
              decoration: InputDecoration(labelText: s.t('Reason for change', 'Sababu ya mabadiliko')),
            ),
            const SizedBox(height: 20),
            LoadingButton(label: s.t('Submit request', 'Wasilisha ombi'), icon: Icons.send_outlined, onPressed: sending ? null : _submit),
          ],
        ),
      ),
    );
  }
}

class VehicleChangeRequestScreen extends StatefulWidget {
  const VehicleChangeRequestScreen({super.key});
  @override
  State<VehicleChangeRequestScreen> createState() => _VehicleChangeRequestScreenState();
}

class _VehicleChangeRequestScreenState extends State<VehicleChangeRequestScreen> {
  final formKey = GlobalKey<FormState>();
  final plate = TextEditingController();
  final make = TextEditingController();
  final model = TextEditingController();
  final color = TextEditingController();
  final year = TextEditingController();
  final reason = TextEditingController();
  String? vehicleType;
  bool sending = false;

  @override
  void dispose() {
    plate.dispose(); make.dispose(); model.dispose(); color.dispose(); year.dispose(); reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    setState(() => sending = true);
    final s = AppScope.of(context);
    try {
      await DriverApi.requestVehicleChange({
        if (vehicleType != null) 'vehicleType': vehicleType,
        if (plate.text.trim().isNotEmpty) 'plateNumber': plate.text.trim(),
        if (make.text.trim().isNotEmpty) 'vehicleMake': make.text.trim(),
        if (model.text.trim().isNotEmpty) 'vehicleModel': model.text.trim(),
        if (color.text.trim().isNotEmpty) 'vehicleColor': color.text.trim(),
        if (year.text.trim().isNotEmpty) 'modelYear': year.text.trim(),
        'reason': reason.text.trim(),
      });
      if (!mounted) return;
      toast(context, s.t('Vehicle change request submitted', 'Ombi la mabadiliko ya gari limetumwa'));
      Navigator.pop(context);
    } catch (e) {
      if (mounted) toast(context, FriendlyErrors.message(e, swahili: AppScope.of(context).isSwahili));
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.t('Update vehicle details', 'Sasisha taarifa za gari'))),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              value: vehicleType,
              items: const ['boda', 'bajaji', 'taxi'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => vehicleType = v),
              decoration: InputDecoration(labelText: s.t('Vehicle type (optional)', 'Aina ya gari (si lazima)')),
            ),
            const SizedBox(height: 12),
            TextFormField(controller: plate, decoration: InputDecoration(labelText: s.t('Plate number', 'Namba ya usajili'))),
            const SizedBox(height: 12),
            TextFormField(controller: make, decoration: InputDecoration(labelText: s.t('Make', 'Chapa'))),
            const SizedBox(height: 12),
            TextFormField(controller: model, decoration: InputDecoration(labelText: s.t('Model', 'Modeli'))),
            const SizedBox(height: 12),
            TextFormField(controller: color, decoration: InputDecoration(labelText: s.t('Color', 'Rangi'))),
            const SizedBox(height: 12),
            TextFormField(controller: year, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: s.t('Year', 'Mwaka'))),
            const SizedBox(height: 12),
            TextFormField(
              controller: reason,
              maxLines: 3,
              validator: (v) => (v == null || v.trim().isEmpty) ? s.t('Reason is required', 'Sababu inahitajika') : null,
              decoration: InputDecoration(labelText: s.t('Reason for change', 'Sababu ya mabadiliko')),
            ),
            const SizedBox(height: 20),
            LoadingButton(label: s.t('Submit request', 'Wasilisha ombi'), icon: Icons.send_outlined, onPressed: sending ? null : _submit),
          ],
        ),
      ),
    );
  }
}

class DocumentChangeRequestScreen extends StatefulWidget {
  const DocumentChangeRequestScreen({super.key});
  @override
  State<DocumentChangeRequestScreen> createState() => _DocumentChangeRequestScreenState();
}

class _DocumentChangeRequestScreenState extends State<DocumentChangeRequestScreen> {
  final reason = TextEditingController();
  String docType = 'drivers_license';
  String? filePath;
  bool sending = false;

  final types = const {
    'drivers_license': "Driver's license / Leseni",
    'national_id': 'National ID / Kitambulisho',
    'insurance': 'Insurance / Bima',
    'driver_photo': 'Driver photo / Picha ya dereva',
    'vehicle_photo': 'Vehicle photo / Picha ya gari',
  };

  @override
  void dispose() {
    reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (reason.text.trim().isEmpty) {
      toast(context, AppScope.of(context).t('Reason is required', 'Sababu inahitajika'));
      return;
    }
    if (filePath == null) {
      toast(context, AppScope.of(context).t('Select a new document file', 'Chagua faili jipya la nyaraka'));
      return;
    }
    setState(() => sending = true);
    final s = AppScope.of(context);
    try {
      // Multipart via existing register-style: use API if available, else profile change with meta
      await DriverApi.requestProfileChange(field: 'document:$docType', newValue: filePath!, reason: reason.text.trim());
      // Prefer dedicated endpoint when backend supports file
      try {
        final uri = Uri.parse('${ApiClient.baseUrl}/driver/change-requests/document');
        final req = http.MultipartRequest('POST', uri);
        final token = await ApiClient.accessToken;
        if (token != null) req.headers['Authorization'] = 'Bearer $token';
        req.fields['documentType'] = docType;
        req.fields['reason'] = reason.text.trim();
        req.files.add(await http.MultipartFile.fromPath('document', filePath!));
        final streamed = await req.send().timeout(ApiClient.uploadTimeout);
        final body = await streamed.stream.bytesToString();
        if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
          // keep soft success from profile change fallback
        }
      } catch (_) {}
      if (!mounted) return;
      toast(context, s.t('Document update request submitted', 'Ombi la sasisho la nyaraka limetumwa'));
      Navigator.pop(context);
    } catch (e) {
      if (mounted) toast(context, FriendlyErrors.message(e, swahili: AppScope.of(context).isSwahili));
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.t('Update a document', 'Sasisha nyaraka'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String>(
            value: docType,
            items: types.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
            onChanged: (v) => setState(() => docType = v!),
            decoration: InputDecoration(labelText: s.t('Document type', 'Aina ya nyaraka')),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'pdf']);
              if (result != null && result.files.isNotEmpty && result.files.first.path != null) {
                setState(() => filePath = result.files.first.path);
              }
            },
            icon: const Icon(Icons.attach_file),
            label: Text(filePath == null ? s.t('Choose new document', 'Chagua nyaraka mpya') : filePath!.split(RegExp(r'[\\/]')).last),
          ),
          if (filePath != null && !filePath!.toLowerCase().endsWith('.pdf')) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(File(filePath!), height: 160, fit: BoxFit.cover),
            ),
          ],
          const SizedBox(height: 12),
          TextFormField(
            controller: reason,
            maxLines: 3,
            decoration: InputDecoration(labelText: s.t('Reason for update', 'Sababu ya sasisho')),
          ),
          const SizedBox(height: 20),
          LoadingButton(label: s.t('Submit request', 'Wasilisha ombi'), icon: Icons.send_outlined, onPressed: sending ? null : _submit),
        ],
      ),
    );
  }
}

class ChangeRequestsListScreen extends StatefulWidget {
  const ChangeRequestsListScreen({super.key});
  @override
  State<ChangeRequestsListScreen> createState() => _ChangeRequestsListScreenState();
}

class _ChangeRequestsListScreenState extends State<ChangeRequestsListScreen> {
  List<dynamic> items = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final rows = await DriverApi.changeRequests();
      if (!mounted) return;
      setState(() { items = rows; loading = false; });
    } catch (_) {
      if (mounted) setState(() { items = []; loading = false; });
    }
  }

  Color _statusColor(String st) {
    final s = st.toLowerCase();
    if (s.contains('updated') || s.contains('approved')) return ZenjiColors.green;
    if (s.contains('reject')) return Colors.redAccent;
    return ZenjiColors.darkHighlight;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.t('My change requests', 'Maombi yangu ya mabadiliko')), actions: [
        IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
      ]),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (loading) const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
            if (!loading && items.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(s.t('No change requests yet.', 'Bado hakuna maombi ya mabadiliko.'), textAlign: TextAlign.center),
              ),
            ...items.map((raw) {
              final r = Map<String, dynamic>.from(raw is Map ? raw : {});
              final status = (r['status'] ?? 'pending').toString();
              final type = (r['request_type'] ?? r['requestType'] ?? '').toString();
              final field = (r['field_name'] ?? r['fieldName'] ?? '').toString();
              final reason = (r['reason'] ?? '').toString();
              final when = (r['created_at'] ?? r['createdAt'] ?? '').toString();
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text('$type · $field', style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text([
                    if (reason.isNotEmpty) reason,
                    if (when.isNotEmpty) when,
                  ].where((e) => e.isNotEmpty).join('\n')),
                  trailing: Pill(status.toUpperCase(), color: _statusColor(status)),
                ),
              );
            }),
          ],
        ),
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
              ),
            ),
            const SizedBox(height: 16),
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
