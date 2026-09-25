import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/widgets.dart';
import 'main_shell.dart';

class _CountryCode {
  final String name, iso, dial, flag;
  const _CountryCode(this.name, this.iso, this.dial, this.flag);
}

const _countries = <_CountryCode>[
  _CountryCode('Tanzania', 'TZ', '+255', '🇹🇿'),
  _CountryCode('Kenya', 'KE', '+254', '🇰🇪'),
  _CountryCode('Uganda', 'UG', '+256', '🇺🇬'),
  _CountryCode('Rwanda', 'RW', '+250', '🇷🇼'),
  _CountryCode('Burundi', 'BI', '+257', '🇧🇮'),
  _CountryCode('South Africa', 'ZA', '+27', '🇿🇦'),
  _CountryCode('Nigeria', 'NG', '+234', '🇳🇬'),
  _CountryCode('Ghana', 'GH', '+233', '🇬🇭'),
  _CountryCode('United Kingdom', 'GB', '+44', '🇬🇧'),
  _CountryCode('United States', 'US', '+1', '🇺🇸'),
  _CountryCode('Canada', 'CA', '+1', '🇨🇦'),
  _CountryCode('United Arab Emirates', 'AE', '+971', '🇦🇪'),
  _CountryCode('India', 'IN', '+91', '🇮🇳'),
  _CountryCode('China', 'CN', '+86', '🇨🇳'),
  _CountryCode('Australia', 'AU', '+61', '🇦🇺'),
];

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});
  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  int step = 0;
  final PageController pc = PageController();
  final formKeys = List.generate(4, (_) => GlobalKey<FormState>());
  final phoneController = TextEditingController();
  String vehicle = 'Taxi';
  _CountryCode country = _countries.first;
  bool phoneVerified = false;
  bool emailVerified = false;

  @override
  void dispose() {
    pc.dispose();
    phoneController.dispose();
    super.dispose();
  }

  void next() {
    if (!(formKeys[step].currentState?.validate() ?? true)) return;
    if (step == 0 && (!phoneVerified || !emailVerified)) {
      toast(context, AppScope.of(context).t('Verify your phone number and email before continuing.', 'Thibitisha namba ya simu na barua pepe kabla ya kuendelea.'));
      return;
    }
    if (step < 3) {
      setState(() => step++);
      pc.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ApplicationTrackingScreen()));
    }
  }

  void back() {
    if (step > 0) {
      setState(() => step--);
      pc.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: step == 0,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) back();
        },
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(onPressed: back, icon: const Icon(Icons.arrow_back)),
            title: Text(AppScope.of(context).t('Driver registration', 'Usajili wa dereva')),
          ),
          body: Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: List.generate(4, (i) => Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: i < 3 ? 7 : 0),
                      height: 5,
                      decoration: BoxDecoration(
                        color: i <= step ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ))),
            ),
            Expanded(
              child: PageView(
                controller: pc,
                physics: const NeverScrollableScrollPhysics(),
                children: [_personal(), _vehicle(), _documents(), _review()],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: LoadingButton(
                label: step == 3 ? AppScope.of(context).t('Submit application', 'Wasilisha ombi') : AppScope.of(context).t('Continue', 'Endelea'),
                icon: step == 3 ? Icons.send_rounded : Icons.arrow_forward_rounded,
                onPressed: () async { await fakeDelay(); if (mounted) next(); },
              ),
            ),
          ]),
        ),
      );

  Widget _wrap(int i, String title, String sub, List<Widget> children) => Form(
        key: formKeys[i],
        child: ResponsivePage(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 8),
            Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(sub, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .65))),
            const SizedBox(height: 24),
            ...children,
          ]),
        ),
      );

  Widget _personal() => _wrap(0, AppScope.of(context).t('Personal details', 'Taarifa binafsi'), AppScope.of(context).t('Tell us who you are. Phone and email are verified using OTP.', 'Tuambie wewe ni nani. Simu na barua pepe zinathibitishwa kwa OTP.'), [
        _field(AppScope.of(context).t('Full name', 'Jina kamili'), Icons.person_outline),
        const SizedBox(height: 14),
        _phoneField(),
        const SizedBox(height: 14),
        _otpField(AppScope.of(context).t('Email', 'Barua pepe'), 'driver@example.com', Icons.email_outlined, email: true),
        const SizedBox(height: 14),
        _field(AppScope.of(context).t('National ID number', 'Namba ya kitambulisho cha taifa'), Icons.badge_outlined),
        const SizedBox(height: 14),
        _field(AppScope.of(context).t('Home area / address', 'Eneo la nyumbani / anwani'), Icons.home_outlined, required: false),
      ]);

  Widget _phoneField() => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _pickCountry,
          child: Container(
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: .7)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(country.flag, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 6),
              Text(country.dial, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(width: 2),
              const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
            ]),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            onChanged: (_) { if (phoneVerified) setState(() => phoneVerified = false); },
            validator: (v) => (v == null || v.trim().isEmpty) ? AppScope.of(context).t('Phone number is required', 'Namba ya simu inahitajika') : null,
            decoration: InputDecoration(labelText: AppScope.of(context).t('Phone number', 'Namba ya simu'), hintText: '7XX XXX XXX', prefixIcon: const Icon(Icons.phone_outlined)),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(height: 58, child: FilledButton.tonal(onPressed: _verifyPhone, child: Text(phoneVerified ? AppScope.of(context).t('Verified', 'Imethibitishwa') : AppScope.of(context).t('Verify', 'Thibitisha')))),
      ]);

  Future<void> _pickCountry() async {
    final result = await showModalBottomSheet<_CountryCode>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CountryPicker(selected: country),
    );
    if (result != null && mounted) {
      setState(() {
        country = result;
        phoneVerified = false;
      });
      toast(context, '${AppScope.of(context).t('Phone verification reset for', 'Uthibitisho wa simu umeanzishwa upya kwa')} ${result.dial}.');
    }
  }

  void _verifyPhone() {
    if (phoneController.text.trim().isEmpty) {
      toast(context, AppScope.of(context).t('Enter your phone number first.', 'Ingiza namba yako ya simu kwanza.'));
      return;
    }
    _otpDialog('Phone • ${country.dial} ${phoneController.text.trim()}', phone: true);
  }

  Widget _vehicle() => _wrap(1, AppScope.of(context).t('Vehicle details', 'Taarifa za gari'), AppScope.of(context).t('Add the vehicle you will use for ZenjiGO rides.', 'Ongeza gari utakalotumia kwa safari za ZenjiGO.'), [
        DropdownButtonFormField<String>(initialValue: vehicle, items: ['Boda', 'Bajaji', 'Taxi'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => vehicle = v!), decoration: InputDecoration(labelText: AppScope.of(context).t('Vehicle type', 'Aina ya gari'), prefixIcon: const Icon(Icons.directions_car_outlined))),
        const SizedBox(height: 14), _field(AppScope.of(context).t('Vehicle plate number', 'Namba ya usajili wa gari'), Icons.pin_outlined), const SizedBox(height: 14),
        _field(AppScope.of(context).t('Vehicle make', 'Chapa ya gari'), Icons.factory_outlined), const SizedBox(height: 14), _field(AppScope.of(context).t('Vehicle model', 'Modeli ya gari'), Icons.commute_outlined), const SizedBox(height: 14),
        _field(AppScope.of(context).t('Vehicle color', 'Rangi ya gari'), Icons.palette_outlined), const SizedBox(height: 14), _field(AppScope.of(context).t('Model year', 'Mwaka wa modeli'), Icons.calendar_today_outlined),
      ]);

  Widget _documents() => _wrap(2, AppScope.of(context).t('Documents & photos', 'Nyaraka na picha'), AppScope.of(context).t('Upload clear, current documents. Admin will verify them manually.', 'Pakia nyaraka wazi za sasa. Msimamizi atazithibitisha kwa mikono.'), [
        _upload(AppScope.of(context).t("Driver's license", 'Leseni ya dereva'), AppScope.of(context).t('Front or PDF', 'Mbele au PDF'), Icons.credit_card),
        _upload(AppScope.of(context).t('Zanzibar / Tanzania ID', 'Kitambulisho cha Zanzibar / Tanzania'), AppScope.of(context).t('Front and back', 'Mbele na nyuma'), Icons.badge_outlined),
        _upload(AppScope.of(context).t('Insurance', 'Bima'), AppScope.of(context).t('Valid insurance document', 'Nyaraka halali ya bima'), Icons.verified_user_outlined),
        _upload(AppScope.of(context).t('Vehicle photos', 'Picha za gari'), AppScope.of(context).t('Up to 5 exterior/interior photos', 'Hadi picha 5 za nje/ndani'), Icons.photo_library_outlined, multiple: true),
        _upload(AppScope.of(context).t('Driver photo', 'Picha ya dereva'), AppScope.of(context).t('Clear face photo', 'Picha wazi ya uso'), Icons.add_a_photo_outlined),
      ]);

  Widget _review() => _wrap(3, AppScope.of(context).t('Review application', 'Kagua ombi'), AppScope.of(context).t('Confirm the details below before submitting for manual verification.', 'Thibitisha maelezo yaliyo hapa chini kabla ya kuwasilisha kwa uthibitisho wa mikono.'), [
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
          KeyValueRow(AppScope.of(context).t('Name', 'Jina'), 'Hassan Ali'),
          KeyValueRow(AppScope.of(context).t('Phone', 'Simu'), '${country.dial} ${phoneController.text.isEmpty ? '712 345 678' : phoneController.text}'),
          KeyValueRow(AppScope.of(context).t('Email', 'Barua pepe'), 'hassan@example.com'),
          KeyValueRow(AppScope.of(context).t('Vehicle', 'Gari'), 'Taxi • Toyota • Z 123 ABC'),
          KeyValueRow(AppScope.of(context).t('Documents', 'Nyaraka'), AppScope.of(context).t('5 document groups attached', 'Vikundi 5 vya nyaraka vimeambatishwa')),
        ]))),
        const SizedBox(height: 14),
        CheckboxListTile(contentPadding: EdgeInsets.zero, value: true, onChanged: (_) {}, title: Text(AppScope.of(context).t('I confirm the information provided is accurate.', 'Ninathibitisha taarifa zilizotolewa ni sahihi.')), subtitle: Text(AppScope.of(context).t('False or expired documents can cause application rejection.', 'Nyaraka za uongo au zilizoisha zinaweza kusababisha kukataliwa kwa ombi.'))),
      ]);

  Widget _field(String label, IconData icon, {bool required = true}) => TextFormField(
        validator: (v) => required && (v == null || v.trim().isEmpty) ? '$label is required' : null,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      );

  Widget _otpField(String label, String hint, IconData icon, {bool email = false}) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: TextFormField(
          keyboardType: email ? TextInputType.emailAddress : TextInputType.phone,
          validator: (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null,
          decoration: InputDecoration(labelText: label, hintText: hint, prefixIcon: Icon(icon)),
        )),
        const SizedBox(width: 8),
        SizedBox(height: 58, child: FilledButton.tonal(onPressed: () => _otpDialog(label, phone: false), child: Text(emailVerified ? 'Verified' : 'Verify'))),
      ]);

  void _otpDialog(String target, {required bool phone}) {
    showDialog(
      context: context,
      builder: (d) => AlertDialog(
        title: Text('${AppScope.of(context).t('Verify', 'Thibitisha')} $target'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(AppScope.of(context).t('A 6-digit OTP has been sent. Enter any 6 digits for this frontend demo.', 'OTP ya tarakimu 6 imetumwa. Ingiza tarakimu zozote 6 kwa onyesho hili la frontend.')),
          SizedBox(height: 14),
          TextField(keyboardType: TextInputType.number, maxLength: 6, decoration: InputDecoration(labelText: 'OTP code')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: Text(AppScope.of(context).t('Cancel', 'Ghairi'))),
          FilledButton(onPressed: () { Navigator.pop(d); setState(() { if (phone) phoneVerified = true; else emailVerified = true; }); toast(context, AppScope.of(context).t('Verified successfully', 'Imethibitishwa kwa mafanikio')); }, child: Text(AppScope.of(context).t('Verify', 'Thibitisha'))),
        ],
      ),
    );
  }

  Widget _upload(String title, String sub, IconData icon, {bool multiple = false}) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(contentPadding: const EdgeInsets.all(14), leading: CircleAvatar(child: Icon(icon)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text(sub), trailing: FilledButton.tonal(onPressed: () => toast(context, multiple ? 'Photo picker ready for up to 5 files' : 'File picker ready for backend/plugin integration'), child: Text(AppScope.of(context).t('Upload', 'Pakia'))),
      ));
}

class _CountryPicker extends StatefulWidget {
  final _CountryCode selected;
  const _CountryPicker({required this.selected});
  @override State<_CountryPicker> createState() => _CountryPickerState();
}

class _CountryPickerState extends State<_CountryPicker> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = controller.text.trim().toLowerCase();
    final filtered = _countries
        .where((c) => c.name.toLowerCase().contains(q) || c.iso.toLowerCase().contains(q) || c.dial.contains(q))
        .toList();

    return SafeArea(
      child: Container(
        height: MediaQuery.sizeOf(context).height * .78,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .18),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Select country code', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
              child: TextField(
                controller: controller,
                onChanged: (_) => setState(() {}),
                autofocus: true,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: AppScope.of(context).t('Search country, ISO or +code', 'Tafuta nchi, ISO au +code'),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final c = filtered[i];
                  final selected = c.iso == widget.selected.iso;
                  return ListTile(
                    leading: Text(c.flag, style: const TextStyle(fontSize: 27)),
                    title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(c.iso),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(c.dial, style: const TextStyle(fontWeight: FontWeight.w800)),
                        if (selected) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.check_circle_rounded),
                        ],
                      ],
                    ),
                    onTap: () => Navigator.pop(context, c),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ApplicationTrackingScreen extends StatefulWidget { const ApplicationTrackingScreen({super.key}); @override State<ApplicationTrackingScreen> createState() => _ApplicationTrackingScreenState(); }
class _ApplicationTrackingScreenState extends State<ApplicationTrackingScreen> {
  String status = 'Under Review';
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(AppScope.of(context).t('Application status', 'Hali ya ombi')), actions: [const ThemeLanguageRow(), const SizedBox(width: 12)]), body: ResponsivePage(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const SizedBox(height: 12), Text(AppScope.of(context).t('Registration progress', 'Maendeleo ya usajili'), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)), const SizedBox(height: 8), Text(AppScope.of(context).t('Your documents are checked manually by the ZenjiGO admin team.', 'Nyaraka zako zinakaguliwa kwa mikono na timu ya usimamizi ya ZenjiGO.'), style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .67))), const SizedBox(height: 26), ..._steps(), const SizedBox(height: 18), if (status == 'Rejected') Card(child: ListTile(leading: const Icon(Icons.error_outline, color: Colors.redAccent), title: Text(AppScope.of(context).t('Application rejected', 'Ombi limekataliwa'), style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(AppScope.of(context).t('Reason: Insurance document is expired. Upload a valid insurance document and resubmit.', 'Sababu: Nyaraka ya bima imeisha. Pakia nyaraka halali ya bima na uwasilishe tena.')))), if (status == 'Approved' || status == 'Active') LoadingButton(label: AppScope.of(context).t('Enter ZenjiGO Driver', 'Ingia ZenjiGO Dereva'), icon: Icons.local_taxi_rounded, onPressed: () async { await fakeDelay(); AppScope.of(context).setApplicationStatus('Active'); if (context.mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const MainShell()), (_) => false); }), if (status != 'Approved' && status != 'Active') LoadingButton(label: AppScope.of(context).t('Demo: mark approved', 'Onyesho: weka kuwa imeidhinishwa'), outline: true, onPressed: () async { await fakeDelay(); setState(() => status = 'Approved'); }), const SizedBox(height: 12), Text(AppScope.of(context).t('Statuses: Pending → Under Review → Approved / Rejected → Active', 'Hali: Inasubiri → Inakaguliwa → Imeidhinishwa / Imekataliwa → Aktivu'), style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .55))) ])));
  List<Widget> _steps() { final s = AppScope.of(context);
    final labels = [s.t('Pending', 'Inasubiri'), s.t('Under Review', 'Inakaguliwa'), s.t('Approved', 'Imeidhinishwa'), s.t('Active', 'Aktivu')]; final current = status == 'Rejected' ? 1 : labels.indexOf(status); return List.generate(labels.length, (i) { final done = i <= current; return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Column(children: [CircleAvatar(radius: 18, backgroundColor: done ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withValues(alpha: .1), child: Icon(done ? Icons.check : Icons.more_horiz, size: 18, color: done ? Colors.white : null)), if (i < labels.length - 1) Container(width: 2, height: 42, color: done ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withValues(alpha: .1))]), const SizedBox(width: 14), Expanded(child: Padding(padding: const EdgeInsets.only(top: 7), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(labels[i], style: TextStyle(fontWeight: FontWeight.w800, color: done ? null : Theme.of(context).colorScheme.onSurface.withValues(alpha: .45))), if (i == current) Padding(padding: const EdgeInsets.only(top: 3), child: Text(i == 1 ? AppScope.of(context).t('Admin is checking your identity, vehicle and documents.', 'Msimamizi anakagua utambulisho wako, gari na nyaraka.') : AppScope.of(context).t('Current application stage', 'Hatua ya sasa ya ombi'), style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .6))))])))]); }); }
}
