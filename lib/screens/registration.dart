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
      toast(context, 'Verify your phone number and email before continuing.');
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
            title: const Text('Driver registration'),
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
                label: step == 3 ? 'Submit application' : 'Continue',
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

  Widget _personal() => _wrap(0, 'Personal details', 'Tell us who you are. Phone and email are verified using OTP.', [
        _field('Full name', Icons.person_outline),
        const SizedBox(height: 14),
        _phoneField(),
        const SizedBox(height: 14),
        _otpField('Email', 'driver@example.com', Icons.email_outlined, email: true),
        const SizedBox(height: 14),
        _field('National ID number', Icons.badge_outlined),
        const SizedBox(height: 14),
        _field('Home area / address', Icons.home_outlined, required: false),
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
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Phone number is required' : null,
            decoration: const InputDecoration(labelText: 'Phone number', hintText: '7XX XXX XXX', prefixIcon: Icon(Icons.phone_outlined)),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(height: 58, child: FilledButton.tonal(onPressed: _verifyPhone, child: Text(phoneVerified ? 'Verified' : 'Verify'))),
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
      toast(context, 'Phone verification reset for ${result.dial}.');
    }
  }

  void _verifyPhone() {
    if (phoneController.text.trim().isEmpty) {
      toast(context, 'Enter your phone number first.');
      return;
    }
    _otpDialog('Phone • ${country.dial} ${phoneController.text.trim()}', phone: true);
  }

  Widget _vehicle() => _wrap(1, 'Vehicle details', 'Add the vehicle you will use for ZenjiGO rides.', [
        DropdownButtonFormField<String>(initialValue: vehicle, items: ['Boda', 'Bajaji', 'Taxi'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => vehicle = v!), decoration: const InputDecoration(labelText: 'Vehicle type', prefixIcon: Icon(Icons.directions_car_outlined))),
        const SizedBox(height: 14), _field('Vehicle plate number', Icons.pin_outlined), const SizedBox(height: 14),
        _field('Vehicle make', Icons.factory_outlined), const SizedBox(height: 14), _field('Vehicle model', Icons.commute_outlined), const SizedBox(height: 14),
        _field('Vehicle color', Icons.palette_outlined), const SizedBox(height: 14), _field('Model year', Icons.calendar_today_outlined),
      ]);

  Widget _documents() => _wrap(2, 'Documents & photos', 'Upload clear, current documents. Admin will verify them manually.', [
        _upload('Driver’s license', 'Front or PDF', Icons.credit_card),
        _upload('Zanzibar / Tanzania ID', 'Front and back', Icons.badge_outlined),
        _upload('Insurance', 'Valid insurance document', Icons.verified_user_outlined),
        _upload('Vehicle photos', 'Up to 5 exterior/interior photos', Icons.photo_library_outlined, multiple: true),
        _upload('Driver photo', 'Clear face photo', Icons.add_a_photo_outlined),
      ]);

  Widget _review() => _wrap(3, 'Review application', 'Confirm the details below before submitting for manual verification.', [
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
          const KeyValueRow('Name', 'Hassan Ali'),
          KeyValueRow('Phone', '${country.dial} ${phoneController.text.isEmpty ? '712 345 678' : phoneController.text}'),
          const KeyValueRow('Email', 'hassan@example.com'),
          const KeyValueRow('Vehicle', 'Taxi • Toyota • Z 123 ABC'),
          const KeyValueRow('Documents', '5 document groups attached'),
        ]))),
        const SizedBox(height: 14),
        CheckboxListTile(contentPadding: EdgeInsets.zero, value: true, onChanged: (_) {}, title: const Text('I confirm the information provided is accurate.'), subtitle: const Text('False or expired documents can cause application rejection.')),
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
        title: Text('Verify $target'),
        content: const Column(mainAxisSize: MainAxisSize.min, children: [
          Text('A 6-digit OTP has been sent. Enter any 6 digits for this frontend demo.'),
          SizedBox(height: 14),
          TextField(keyboardType: TextInputType.number, maxLength: 6, decoration: InputDecoration(labelText: 'OTP code')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
          FilledButton(onPressed: () { Navigator.pop(d); setState(() { if (phone) phoneVerified = true; else emailVerified = true; }); toast(context, 'Verified successfully'); }, child: const Text('Verify')),
        ],
      ),
    );
  }

  Widget _upload(String title, String sub, IconData icon, {bool multiple = false}) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(contentPadding: const EdgeInsets.all(14), leading: CircleAvatar(child: Icon(icon)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text(sub), trailing: FilledButton.tonal(onPressed: () => toast(context, multiple ? 'Photo picker ready for up to 5 files' : 'File picker ready for backend/plugin integration'), child: const Text('Upload'))),
      );
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
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search country, ISO or +code',
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
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Application status'), actions: [const ThemeLanguageRow(), const SizedBox(width: 12)]), body: ResponsivePage(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const SizedBox(height: 12), Text('Registration progress', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)), const SizedBox(height: 8), Text('Your documents are checked manually by the ZenjiGO admin team.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .67))), const SizedBox(height: 26), ..._steps(), const SizedBox(height: 18), if (status == 'Rejected') const Card(child: ListTile(leading: Icon(Icons.error_outline, color: Colors.redAccent), title: Text('Application rejected', style: TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('Reason: Insurance document is expired. Upload a valid insurance document and resubmit.'))), if (status == 'Approved' || status == 'Active') LoadingButton(label: 'Enter ZenjiGO Driver', icon: Icons.local_taxi_rounded, onPressed: () async { await fakeDelay(); AppScope.of(context).setApplicationStatus('Active'); if (context.mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const MainShell()), (_) => false); }), if (status != 'Approved' && status != 'Active') LoadingButton(label: 'Demo: mark approved', outline: true, onPressed: () async { await fakeDelay(); setState(() => status = 'Approved'); }), const SizedBox(height: 12), Text('Statuses: Pending → Under Review → Approved / Rejected → Active', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .55))) ])));
  List<Widget> _steps() { final labels = ['Pending', 'Under Review', 'Approved', 'Active']; final current = status == 'Rejected' ? 1 : labels.indexOf(status); return List.generate(labels.length, (i) { final done = i <= current; return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Column(children: [CircleAvatar(radius: 18, backgroundColor: done ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withValues(alpha: .1), child: Icon(done ? Icons.check : Icons.more_horiz, size: 18, color: done ? Colors.white : null)), if (i < labels.length - 1) Container(width: 2, height: 42, color: done ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withValues(alpha: .1))]), const SizedBox(width: 14), Expanded(child: Padding(padding: const EdgeInsets.only(top: 7), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(labels[i], style: TextStyle(fontWeight: FontWeight.w800, color: done ? null : Theme.of(context).colorScheme.onSurface.withValues(alpha: .45))), if (i == current) Padding(padding: const EdgeInsets.only(top: 3), child: Text(i == 1 ? 'Admin is checking your identity, vehicle and documents.' : 'Current application stage', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .6))))])))]); }); }
}
