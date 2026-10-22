import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../core/api/driver_api.dart';
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
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final nationalIdController = TextEditingController();
  final addressController = TextEditingController();
  final plateController = TextEditingController();
  final makeController = TextEditingController();
  final modelController = TextEditingController();
  final colorController = TextEditingController();
  final yearController = TextEditingController();
  final Map<String, List<String>> selectedFiles = {};
  String vehicle = 'Taxi';
  _CountryCode country = _countries.first;
  bool emailVerified = false;
  bool emailVerifying = false;
  String? emailOtpCode;
  bool acceptedTerms = false;

  @override
  void dispose() {
    pc.dispose();
    phoneController.dispose();
    nameController.dispose(); emailController.dispose(); nationalIdController.dispose(); addressController.dispose(); plateController.dispose(); makeController.dispose(); modelController.dispose(); colorController.dispose(); yearController.dispose();
    super.dispose();
  }

  Future<void> next() async {
    if (!(formKeys[step].currentState?.validate() ?? true)) return;
    if (step == 0 && !emailVerified) {
      toast(context, AppScope.of(context).t('Verify your email before continuing.', 'Thibitisha barua pepe kabla ya kuendelea.'));
      return;
    }
    if (step < 3) {
      setState(() => step++);
      pc.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      await _submitRegistration();
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
                onPressed: () async { await next(); },
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

  Widget _personal() => _wrap(0, AppScope.of(context).t('Personal details', 'Taarifa binafsi'), AppScope.of(context).t('Tell us who you are. Verify your email to continue; phone verification is not required.', 'Tuambie wewe ni nani. Thibitisha barua pepe ili kuendelea; uthibitisho wa simu hauhitajiki.'), [
        _field(AppScope.of(context).t('Full name', 'Jina kamili'), Icons.person_outline, controller: nameController),
        const SizedBox(height: 14),
        _phoneField(),
        const SizedBox(height: 14),
        _emailField(),
        const SizedBox(height: 14),
        _field(AppScope.of(context).t('National ID number', 'Namba ya kitambulisho cha taifa'), Icons.badge_outlined, controller: nationalIdController),
        const SizedBox(height: 14),
        _field(AppScope.of(context).t('Home area / address', 'Eneo la nyumbani / anwani'), Icons.home_outlined, required: false, controller: addressController),
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
            validator: (v) => (v == null || v.trim().isEmpty)
                ? AppScope.of(context).t('Phone number is required', 'Namba ya simu inahitajika')
                : null,
            decoration: InputDecoration(
              labelText: AppScope.of(context).t('Phone number (contact only)', 'Namba ya simu (mawasiliano tu)'),
              hintText: '7XX XXX XXX',
              prefixIcon: const Icon(Icons.phone_outlined),
            ),
          ),
        ),
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
      });
    }
  }

  Widget _emailField() => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) {
              if (emailVerified || emailOtpCode != null) setState(() { emailVerified = false; emailOtpCode = null; });
            },
            validator: (v) {
              final value = (v ?? '').trim();
              if (value.isEmpty) return AppScope.of(context).t('Email is required', 'Barua pepe inahitajika');
              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
                return AppScope.of(context).t('Enter a valid email', 'Ingiza barua pepe sahihi');
              }
              return null;
            },
            decoration: InputDecoration(
              labelText: AppScope.of(context).t('Email', 'Barua pepe'),
              prefixIcon: const Icon(Icons.email_outlined),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 58,
          child: FilledButton.tonal(
            onPressed: emailVerified || emailVerifying ? null : _verifyEmail,
            child: emailVerifying
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4))
                : Text(emailVerified ? AppScope.of(context).t('Verified', 'Imethibitishwa') : AppScope.of(context).t('Verify', 'Thibitisha')),
          ),
        ),
      ]);

  Future<void> _verifyEmail() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      toast(context, AppScope.of(context).t('Enter your email first.', 'Ingiza barua pepe kwanza.'));
      return;
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      toast(context, AppScope.of(context).t('Enter a valid email address.', 'Ingiza barua pepe sahihi.'));
      return;
    }
    if (emailVerifying) return;
    setState(() => emailVerifying = true);
    try {
      await DriverApi.sendEmailOtp(email, purpose: 'driver_registration');
      if (!mounted) return;
      final code = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (d) => _OtpCodeDialog(
          title: AppScope.of(context).t('Enter email OTP', 'Ingiza OTP ya barua pepe'),
          label: AppScope.of(context).t('OTP code', 'Namba ya OTP'),
          cancelLabel: AppScope.of(context).t('Cancel', 'Ghairi'),
          confirmLabel: AppScope.of(context).t('Confirm', 'Thibitisha'),
        ),
      );
      if (code == null || code.isEmpty || !mounted) return;
      await DriverApi.verifyRegistrationOtp(target: email, code: code, purpose: 'driver_registration');
      if (!mounted) return;
      setState(() {
        emailOtpCode = code;
        emailVerified = true;
      });
      toast(context, AppScope.of(context).t('Email verified.', 'Barua pepe imethibitishwa.'));
    } catch (e) {
      if (mounted) toast(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => emailVerifying = false);
    }
  }

  Future<void> _submitRegistration() async {
    if(!emailVerified || emailOtpCode==null){toast(context,AppScope.of(context).t('Verify your email first.','Thibitisha barua pepe kwanza.'));return;}
    if(emailController.text.trim().isEmpty || nationalIdController.text.trim().isEmpty || plateController.text.trim().isEmpty){toast(context,AppScope.of(context).t('Complete the required personal and vehicle fields.','Jaza taarifa zinazohitajika.'));return;}
    final requiredFiles=['license','nationalId','insurance','driverPhoto'];
    if(requiredFiles.any((k)=>selectedFiles[k]==null || selectedFiles[k]!.isEmpty)){toast(context,AppScope.of(context).t('Upload your license, national ID, insurance and driver photo.','Pakia leseni, kitambulisho, bima na picha ya dereva.'));return;}
    if (!acceptedTerms) { toast(context, AppScope.of(context).t('Please confirm the information is accurate before submitting.', 'Thibitisha kuwa taarifa ni sahihi kabla ya kutuma.')); return; }
    try{
      final result=await DriverApi.register(
        fullName:nameController.text.trim(),phone:'${country.dial}${phoneController.text.trim()}',
        email:emailController.text.trim(),nationalId:nationalIdController.text.trim(),homeAddress:addressController.text.trim(),
        vehicleType:vehicle.toLowerCase(),plateNumber:plateController.text.trim(),vehicleMake:makeController.text.trim(),
        vehicleModel:modelController.text.trim(),vehicleColor:colorController.text.trim(),modelYear:int.tryParse(yearController.text.trim()),
        emailOtpCode:emailOtpCode!,files:selectedFiles);
      if(!mounted)return;
      toast(context,AppScope.of(context).t('Application submitted successfully.','Ombi limetumwa kwa mafanikio.'));
      Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>ApplicationTrackingScreen(driverId:result['driverId'].toString())));
    }catch(e){if(mounted)toast(context,e.toString().replaceFirst('Exception: ',''));}
  }

  Widget _vehicle() => _wrap(1, AppScope.of(context).t('Vehicle details', 'Taarifa za gari'), AppScope.of(context).t('Add the vehicle you will use for ZenjiGO rides.', 'Ongeza gari utakalotumia kwa safari za ZenjiGO.'), [
        DropdownButtonFormField<String>(initialValue: vehicle, items: ['Boda', 'Bajaji', 'Taxi'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => vehicle = v!), decoration: InputDecoration(labelText: AppScope.of(context).t('Vehicle type', 'Aina ya gari'), prefixIcon: const Icon(Icons.directions_car_outlined))),
        const SizedBox(height: 14), _field(AppScope.of(context).t('Vehicle plate number', 'Namba ya usajili wa gari'), Icons.pin_outlined, controller: plateController), const SizedBox(height: 14),
        _field(AppScope.of(context).t('Vehicle make', 'Chapa ya gari'), Icons.factory_outlined, controller: makeController), const SizedBox(height: 14), _field(AppScope.of(context).t('Vehicle model', 'Modeli ya gari'), Icons.commute_outlined, controller: modelController), const SizedBox(height: 14),
        _field(AppScope.of(context).t('Vehicle color', 'Rangi ya gari'), Icons.palette_outlined, controller: colorController), const SizedBox(height: 14), _field(AppScope.of(context).t('Model year', 'Mwaka wa modeli'), Icons.calendar_today_outlined, controller: yearController, keyboard: TextInputType.number),
      ]);

  Widget _documents() => _wrap(2, AppScope.of(context).t('Documents & photos', 'Nyaraka na picha'), AppScope.of(context).t('Upload clear, current documents. Admin will verify them manually.', 'Pakia nyaraka wazi za sasa. Msimamizi atazithibitisha kwa mikono.'), [
        _upload(AppScope.of(context).t("Driver's license", 'Leseni ya dereva'), AppScope.of(context).t('Front or PDF', 'Mbele au PDF'), Icons.credit_card),
        _upload(AppScope.of(context).t('Zanzibar / Tanzania ID', 'Kitambulisho cha Zanzibar / Tanzania'), AppScope.of(context).t('Front and back', 'Mbele na nyuma'), Icons.badge_outlined, multiple: true),
        _upload(AppScope.of(context).t('Insurance', 'Bima'), AppScope.of(context).t('Valid insurance document', 'Nyaraka halali ya bima'), Icons.verified_user_outlined),
        _upload(AppScope.of(context).t('Vehicle photos', 'Picha za gari'), AppScope.of(context).t('Up to 5 exterior/interior photos', 'Hadi picha 5 za nje/ndani'), Icons.photo_library_outlined, multiple: true),
        _upload(AppScope.of(context).t('Driver photo', 'Picha ya dereva'), AppScope.of(context).t('Clear face photo', 'Picha wazi ya uso'), Icons.add_a_photo_outlined),
      ]);

  Widget _review() => _wrap(3, AppScope.of(context).t('Review application', 'Kagua ombi'), AppScope.of(context).t('Confirm the details below before submitting for manual verification.', 'Thibitisha maelezo yaliyo hapa chini kabla ya kuwasilisha kwa uthibitisho wa mikono.'), [
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
          KeyValueRow(AppScope.of(context).t('Name', 'Jina'), nameController.text.trim().isEmpty ? '—' : nameController.text.trim()),
          KeyValueRow(AppScope.of(context).t('Phone', 'Simu'), '${country.dial} ${phoneController.text.trim()}'),
          KeyValueRow(AppScope.of(context).t('Email', 'Barua pepe'), emailController.text.trim().isEmpty ? '—' : emailController.text.trim()),
          KeyValueRow(AppScope.of(context).t('Vehicle', 'Gari'), '${vehicle} • ${makeController.text.trim()} ${modelController.text.trim()} • ${plateController.text.trim()}'),
          KeyValueRow(AppScope.of(context).t('Documents', 'Nyaraka'), selectedFiles.values.fold<int>(0, (sum, files) => sum + files.length).toString() + ' file(s) selected'),
        ]))),
        const SizedBox(height: 14),
        CheckboxListTile(contentPadding: EdgeInsets.zero, value: acceptedTerms, onChanged: (v) => setState(() => acceptedTerms = v ?? false), title: Text(AppScope.of(context).t('I confirm the information provided is accurate.', 'Ninathibitisha taarifa zilizotolewa ni sahihi.')), subtitle: Text(AppScope.of(context).t('False or expired documents can cause application rejection.', 'Nyaraka za uongo au zilizoisha zinaweza kusababisha kukataliwa kwa ombi.'))),
      ]);

  Widget _field(String label, IconData icon, {bool required = true, TextEditingController? controller, TextInputType? keyboard}) => TextFormField(
        controller: controller,
        keyboardType: keyboard,
        validator: (v) => required && (v == null || v.trim().isEmpty) ? '$label is required' : null,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      );

  Widget _upload(String title, String sub, IconData icon, {bool multiple = false}) {
    final key = _fileKey(title);
    final paths = selectedFiles[key] ?? const <String>[];
    final t = AppScope.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(child: Icon(icon)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text(paths.isEmpty ? sub : '${paths.length} file(s) selected',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .65))),
            ])),
            FilledButton.tonal(
              onPressed: () async {
                try {
                  final result = await FilePicker.platform.pickFiles(
                    allowMultiple: multiple,
                    type: FileType.custom,
                    allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
                    withData: false,
                    lockParentWindow: true,
                  );
                  if (!mounted || result == null) return;
                  final picked = result.files.where((f) => f.path != null).toList();
                  if (picked.isEmpty) {
                    toast(context, t.t('Could not access the selected file. Please choose a file stored on this device.', 'Haiwezi kufikia faili lililochaguliwa.'));
                    return;
                  }
                  final valid = picked.where((f) {
                    final ext = (f.extension ?? '').toLowerCase();
                    return const {'jpg', 'jpeg', 'png', 'webp', 'pdf'}.contains(ext);
                  }).toList();
                  if (valid.length != picked.length) {
                    toast(context, t.t('Only JPG, PNG, WEBP and PDF files are supported.', 'Aina za JPG, PNG, WEBP na PDF pekee zinakubaliwa.'));
                  }
                  if (valid.isEmpty) return;
                  final existing = multiple ? List<String>.from(paths) : <String>[];
                  for (final file in valid) {
                    if (!existing.contains(file.path)) existing.add(file.path!);
                  }
                  final maxAllowed = key == 'nationalId' ? 2 : 5;
                  if (multiple && existing.length > maxAllowed) {
                    toast(context, t.t('You can select up to $maxAllowed files here.', 'Unaweza kuchagua faili hadi $maxAllowed hapa.'));
                    return;
                  }
                  setState(() => selectedFiles[key] = existing);
                } catch (e) {
                  if (mounted) toast(context, t.t('Unable to open files. Please try again.', 'Imeshindwa kufungua faili. Jaribu tena.'));
                }
              },
              child: Text(paths.isEmpty ? t.t('Choose files', 'Chagua faili') : t.t('Add / replace', 'Ongeza / badilisha')),
            ),
          ]),
          if (paths.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...paths.asMap().entries.map((entry) {
              final path = entry.value;
              final filename = path.replaceAll('\\', '/').split('/').last;
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(children: [
                  Icon(filename.toLowerCase().endsWith('.pdf') ? Icons.picture_as_pdf_outlined : Icons.image_outlined, size: 19),
                  const SizedBox(width: 8),
                  Expanded(child: Text(filename, maxLines: 2, overflow: TextOverflow.ellipsis)),
                  IconButton(
                    tooltip: t.t('Remove file', 'Ondoa faili'),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => setState(() {
                      final updated = List<String>.from(selectedFiles[key] ?? []);
                      updated.removeAt(entry.key);
                      selectedFiles[key] = updated;
                    }),
                    icon: const Icon(Icons.close_rounded, size: 19),
                  ),
                ]),
              );
            }),
          ],
        ]),
      ),
    );
  }

String _fileKey(String title) {
  final l = title.toLowerCase();
  if (l.contains('license') && !l.contains('insurance')) {
    return 'license';
  }
  if (l.contains('id') || l.contains('kitambulisho')) {
    return 'nationalId';
  }
  if (l.contains('insurance') || l.contains('bima')) {
    return 'insurance';
  }
  if (l.contains('vehicle')) {
    return 'vehiclePhotos';
  }
  return 'driverPhoto';
}

}



/// Owns its TextEditingController so it is disposed only after the dialog unmounts.
class _OtpCodeDialog extends StatefulWidget {
  final String title;
  final String label;
  final String cancelLabel;
  final String confirmLabel;
  const _OtpCodeDialog({
    required this.title,
    required this.label,
    required this.cancelLabel,
    required this.confirmLabel,
  });

  @override
  State<_OtpCodeDialog> createState() => _OtpCodeDialogState();
}

class _OtpCodeDialogState extends State<_OtpCodeDialog> {
  late final TextEditingController _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _ctrl,
        keyboardType: TextInputType.number,
        maxLength: 8,
        autofocus: true,
        decoration: InputDecoration(labelText: widget.label),
        onSubmitted: (v) => Navigator.pop(context, v.trim()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(widget.cancelLabel)),
        FilledButton(onPressed: () => Navigator.pop(context, _ctrl.text.trim()), child: Text(widget.confirmLabel)),
      ],
    );
  }
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

class ApplicationTrackingScreen extends StatefulWidget { const ApplicationTrackingScreen({super.key, this.driverId});
  final String? driverId; @override State<ApplicationTrackingScreen> createState() => _ApplicationTrackingScreenState(); }
class _ApplicationTrackingScreenState extends State<ApplicationTrackingScreen> {
  String status = 'Under Review';
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(AppScope.of(context).t('Application status', 'Hali ya ombi')), actions: [const ThemeLanguageRow(), const SizedBox(width: 12)]), body: ResponsivePage(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const SizedBox(height: 12), Text(AppScope.of(context).t('Registration progress', 'Maendeleo ya usajili'), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)), const SizedBox(height: 8), Text(AppScope.of(context).t('Your documents are checked manually by the ZenjiGO admin team.', 'Nyaraka zako zinakaguliwa kwa mikono na timu ya usimamizi ya ZenjiGO.'), style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .67))), const SizedBox(height: 26), ..._steps(), const SizedBox(height: 18), if (status == 'Rejected') Card(child: ListTile(leading: const Icon(Icons.error_outline, color: Colors.redAccent), title: Text(AppScope.of(context).t('Application rejected', 'Ombi limekataliwa'), style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(AppScope.of(context).t('Please contact ZenjiGO support for the review decision and next steps.', 'Wasiliana na msaada wa ZenjiGO kuhusu uamuzi na hatua zinazofuata.')))), if (status == 'Approved' || status == 'Active') LoadingButton(label: AppScope.of(context).t('Enter ZenjiGO Driver', 'Ingia ZenjiGO Dereva'), icon: Icons.local_taxi_rounded, onPressed: () async { final appState = AppScope.of(context); final navigator = Navigator.of(context); await fakeDelay(); if (!mounted) return; appState.setApplicationStatus('Active'); if (!mounted) return; navigator.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const MainShell()), (_) => false); }), if (status != 'Approved' && status != 'Active') LoadingButton(label: AppScope.of(context).t('Refresh application status', 'Sasisha hali ya ombi'), outline: true, onPressed: () async { try { await AppScope.of(context).refreshProfile(); final profile = AppScope.of(context).profile; final next = profile?['application_status'] ?? profile?['applicationStatus']; if (!mounted) return; if (next != null) { setState(() => status = next.toString()); } else { toast(context, 'Application status is not available yet. Please contact support if this persists.'); } } catch (_) { if (mounted) toast(context, 'Could not refresh status. Check your connection and try again.'); } }), const SizedBox(height: 12), Text(AppScope.of(context).t('Statuses: Pending → Under Review → Approved / Rejected → Active', 'Hali: Inasubiri → Inakaguliwa → Imeidhinishwa / Imekataliwa → Aktivu'), style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .55))) ])));
  List<Widget> _steps() { final s = AppScope.of(context);
    final labels = [s.t('Pending', 'Inasubiri'), s.t('Under Review', 'Inakaguliwa'), s.t('Approved', 'Imeidhinishwa'), s.t('Active', 'Aktivu')]; final current = status == 'Rejected' ? 1 : labels.indexOf(status); return List.generate(labels.length, (i) { final done = i <= current; return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Column(children: [CircleAvatar(radius: 18, backgroundColor: done ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withValues(alpha: .1), child: Icon(done ? Icons.check : Icons.more_horiz, size: 18, color: done ? Colors.white : null)), if (i < labels.length - 1) Container(width: 2, height: 42, color: done ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withValues(alpha: .1))]), const SizedBox(width: 14), Expanded(child: Padding(padding: const EdgeInsets.only(top: 7), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(labels[i], style: TextStyle(fontWeight: FontWeight.w800, color: done ? null : Theme.of(context).colorScheme.onSurface.withValues(alpha: .45))), if (i == current) Padding(padding: const EdgeInsets.only(top: 3), child: Text(i == 1 ? AppScope.of(context).t('Admin is checking your identity, vehicle and documents.', 'Msimamizi anakagua utambulisho wako, gari na nyaraka.') : AppScope.of(context).t('Current application stage', 'Hatua ya sasa ya ombi'), style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .6))))])))]); }); }
}
