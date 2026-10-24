import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../core/api/driver_api.dart';
import '../core/app_state.dart';
import '../core/friendly_errors.dart';
import '../core/widgets.dart';
import 'main_shell.dart';
import 'login.dart';
import '../core/api/api_client.dart';

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

class _CountryPicker extends StatelessWidget {
  const _CountryPicker({required this.selected});

  final _CountryCode selected;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Container(
          margin: const EdgeInsets.only(top: 48),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Select country',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _countries.length,
                  itemBuilder: (context, index) {
                    final country = _countries[index];
                    return ListTile(
                      leading: Text(country.flag, style: const TextStyle(fontSize: 24)),
                      title: Text(country.name),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(country.dial),
                          if (country.iso == selected.iso) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.check),
                          ],
                        ],
                      ),
                      onTap: () => Navigator.of(context).pop(country),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
}

class _OtpCodeDialog extends StatefulWidget {
  const _OtpCodeDialog({
    required this.title,
    required this.label,
    required this.cancelLabel,
    required this.confirmLabel,
  });

  final String title;
  final String label;
  final String cancelLabel;
  final String confirmLabel;

  @override
  State<_OtpCodeDialog> createState() => _OtpCodeDialogState();
}

class _OtpCodeDialogState extends State<_OtpCodeDialog> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.title),
        content: TextField(
          controller: _codeController,
          autofocus: true,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _confirm(),
          decoration: InputDecoration(labelText: widget.label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(widget.cancelLabel),
          ),
          FilledButton(
            onPressed: _confirm,
            child: Text(widget.confirmLabel),
          ),
        ],
      );

  void _confirm() {
    final code = _codeController.text.trim();
    if (code.isNotEmpty) Navigator.of(context).pop(code);
  }
}

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
  final Map<String, String> documentExpirations = {}; // key -> YYYY-MM-DD
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
        PlacesAutocompleteField(controller: addressController, label: AppScope.of(context).t('Home area / address', 'Eneo la nyumbani / anwani')),
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
      if (mounted) toast(context, FriendlyErrors.message(e, swahili: AppScope.of(context).isSwahili));
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
        emailOtpCode:emailOtpCode!,files:selectedFiles,expirations:documentExpirations);
      if(!mounted)return;
      final id = result['driverId'] ?? result['driver_id'] ?? result['id'];
      // Persist auth session from registration response so profile/photo work immediately
      if (result['accessToken'] != null || result['access_token'] != null) {
        await AppScope.of(context).login(result);
      } else if (id != null && emailController.text.trim().isNotEmpty) {
        try {
          final session = await DriverApi.bootstrapSession(
            driverId: id.toString(),
            email: emailController.text.trim(),
          );
          if (session['accessToken'] != null) {
            await AppScope.of(context).login(session);
          }
        } catch (_) {}
      }
      if(!mounted)return;
      toast(context,AppScope.of(context).t('Application submitted successfully.','Ombi limetumwa kwa mafanikio.'));
      if(!mounted)return;
      Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>ApplicationTrackingScreen(driverId: id?.toString(), email: emailController.text.trim())));
    }catch(e){
      final msg = FriendlyErrors.message(e, swahili: AppScope.of(context).isSwahili);
      // If backend already created the driver (timeout after success), still go to tracking
      if (msg.toLowerCase().contains('already') || msg.toLowerCase().contains('exist')) {
        if(mounted) toast(context, msg);
      } else if (msg.toLowerCase().contains('timeout') || msg.toLowerCase().contains('timed out')) {
        if(mounted) {
          toast(context, AppScope.of(context).t('Submitted — checking status…','Imewasilishwa — inakagua hali…'));
          Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>const ApplicationTrackingScreen()));
        }
      } else {
        if(mounted) toast(context, msg);
      }
    }
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

  String _docKey(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('license') || lower.contains('leseni')) return 'license';
    if (lower.contains('id') || lower.contains('kitambulisho')) return 'nationalId';
    if (lower.contains('insurance') || lower.contains('bima')) return 'insurance';
    if (lower.contains('vehicle') || lower.contains('gari')) return 'vehiclePhotos';
    if (lower.contains('driver photo') || lower.contains('picha ya dereva')) return 'driverPhoto';
    return title.replaceAll(RegExp(r'[^a-zA-Z]'), '');
  }

  Widget _upload(String title, String sub, IconData icon, {bool multiple = false}) {
    final t = AppScope.of(context);
    final key = _docKey(title);
    final paths = selectedFiles[key] ?? const <String>[];
    final needsExpiry = key == 'license' || key == 'insurance' || key == 'nationalId';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: .12),
              child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              Text(sub, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .55))),
            ])),
            FilledButton.tonal(
              onPressed: () async {
                try {
                  final result = await FilePicker.platform.pickFiles(
                    allowMultiple: multiple,
                    type: FileType.custom,
                    allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
                  );
                  if (result == null || result.files.isEmpty) return;
                  final picked = result.files.where((f) => f.path != null).toList();
                  final valid = picked.where((f) {
                    final ext = (f.extension ?? '').toLowerCase();
                    return {'jpg', 'jpeg', 'png', 'webp', 'pdf'}.contains(ext);
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
            const SizedBox(height: 10),
            SizedBox(
              height: 88,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: paths.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) {
                  final path = paths[i];
                  final isPdf = path.toLowerCase().endsWith('.pdf');
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: isPdf
                            ? Container(
                                width: 88,
                                height: 88,
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: .08),
                                child: const Icon(Icons.picture_as_pdf, size: 36),
                              )
                            : Image.file(
                                // ignore: prefer_const_constructors
                                // File requires dart:io
                                // Using File via dynamic path
                                // We'll use a helper below
                                File(path),
                                width: 88,
                                height: 88,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 88,
                                  height: 88,
                                  color: Colors.black12,
                                  child: const Icon(Icons.broken_image_outlined),
                                ),
                              ),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: Material(
                          color: Colors.black54,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => setState(() {
                              final updated = List<String>.from(selectedFiles[key] ?? []);
                              updated.removeAt(i);
                              selectedFiles[key] = updated;
                            }),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.close, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
          if (needsExpiry) ...[
            const SizedBox(height: 10),
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: const Icon(Icons.event_outlined),
              title: Text(t.t('Expiration date', 'Tarehe ya mwisho')),
              subtitle: Text(documentExpirations[key] ?? t.t('Tap to set (required for license/insurance)', 'Gusa kuweka (inahitajika kwa leseni/bima)')),
              trailing: const Icon(Icons.edit_calendar_outlined),
              onTap: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: now.add(const Duration(days: 365)),
                  firstDate: now,
                  lastDate: now.add(const Duration(days: 365 * 15)),
                );
                if (picked != null && mounted) {
                  final formatted = '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                  setState(() => documentExpirations[key] = formatted);
                }
              },
            ),
          ],
        ]),
      ),
    );
  }

}



class PlacesAutocompleteField extends StatefulWidget {
  const PlacesAutocompleteField({super.key, required this.controller, required this.label});
  final TextEditingController controller;
  final String label;
  @override
  State<PlacesAutocompleteField> createState() => _PlacesAutocompleteFieldState();
}

class _PlacesAutocompleteFieldState extends State<PlacesAutocompleteField> {
  List<Map<String, dynamic>> suggestions = [];
  bool loading = false;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      if (value.trim().length < 2) {
        if (mounted) setState(() => suggestions = []);
        return;
      }
      setState(() => loading = true);
      try {
        final list = await DriverApi.placesAutocomplete(value.trim());
        if (!mounted) return;
        setState(() { suggestions = list; loading = false; });
      } catch (_) {
        if (mounted) setState(() { suggestions = []; loading = false; });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      TextFormField(
        controller: widget.controller,
        onChanged: _onChanged,
        maxLines: 2,
        validator: (v) => (v == null || v.trim().isEmpty)
            ? AppScope.of(context).t('Home address is required', 'Anwani ya nyumbani inahitajika')
            : null,
        decoration: InputDecoration(
          labelText: widget.label,
          prefixIcon: const Icon(Icons.location_on_outlined),
          suffixIcon: loading
              ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)))
              : const Icon(Icons.search),
        ),
      ),
      if (suggestions.isNotEmpty)
        Card(
          margin: const EdgeInsets.only(top: 6),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: suggestions.length.clamp(0, 6),
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final s = suggestions[i];
              final main = (s['structured'] is Map ? s['structured']['main'] : null) ?? s['description'] ?? '';
              final secondary = (s['structured'] is Map ? s['structured']['secondary'] : null) ?? '';
              return ListTile(
                dense: true,
                leading: const Icon(Icons.place_outlined, size: 20),
                title: Text('$main', maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: secondary.toString().isEmpty ? null : Text('$secondary', maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () {
                  widget.controller.text = (s['description'] ?? main).toString();
                  setState(() => suggestions = []);
                  FocusScope.of(context).unfocus();
                },
              );
            },
          ),
        ),
    ]);
  }
}

class ApplicationTrackingScreen extends StatefulWidget {
  const ApplicationTrackingScreen({super.key, this.driverId, this.email});

  final String? driverId;
  final String? email;

  @override
  State<ApplicationTrackingScreen> createState() => _ApplicationTrackingScreenState();
}

class _ApplicationTrackingScreenState extends State<ApplicationTrackingScreen> {
  bool loading = false;
  String status = 'Pending';
  String? rejectionReason;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _refresh();
    _poll = Timer.periodic(const Duration(seconds: 30), (_) => _refresh());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (loading) return;
    setState(() => loading = true);
    try {
      final id = widget.driverId;
      Map<String, dynamic>? data;
      if (id != null && id.isNotEmpty) {
        data = await DriverApi.applicationStatus(id);
      } else {
        await AppScope.of(context).refreshProfile();
        final profile = AppScope.of(context).profile;
        data = {
          'applicationStatus': profile?['application_status'] ?? profile?['applicationStatus'],
        };
      }
      if (!mounted) return;
      final next = (data?['applicationStatus'] ?? data?['application_status'] ?? status).toString();
      final reason = data?['rejectionReason']?.toString();
      setState(() {
        status = next;
        if (reason != null && reason.isNotEmpty) rejectionReason = reason;
      });
      // Auto-enter when approved/active
      final s = next.toLowerCase();
      if (s == 'approved' || s == 'active') {
        _poll?.cancel();
        // soft delay then offer enter - auto if Active
        if (s == 'active') {
          await Future.delayed(const Duration(milliseconds: 600));
          if (!mounted) return;
          await _enterApp();
        }
      }
    } catch (e) {
      // keep previous status
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _enterApp() async {
    final appState = AppScope.of(context);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    // Ensure we have a valid auth session before entering the main app
    try {
      final token = await ApiClient.accessToken;
      if (token == null || token.isEmpty) {
        final id = widget.driverId;
        final email = widget.email ?? appState.profile?['email']?.toString();
        if (id != null && email != null && email.toString().isNotEmpty) {
          final session = await DriverApi.bootstrapSession(driverId: id, email: email.toString());
          await appState.login(session);
        }
      } else {
        // Refresh profile with existing token so UI is not offline/empty
        await appState.refreshProfile();
        await appState.refreshFinance();
      }
    } catch (e) {
      if (mounted && messenger != null) {
        messenger.showSnackBar(SnackBar(content: Text(FriendlyErrors.message(e, swahili: AppScope.of(context).isSwahili))));
      }
      // Still try to enter if we at least have a token
      final token = await ApiClient.accessToken;
      if (token == null || token.isEmpty) {
        if (mounted && messenger != null) {
          messenger.showSnackBar(const SnackBar(
            content: Text('Could not start session. Please log in with your email OTP.'),
          ));
        }
        if (!mounted) return;
        navigator.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const DriverLoginScreen()), (_) => false);
        return;
      }
    }
    appState.setApplicationStatus('Active');
    if (!mounted) return;
    navigator.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const MainShell()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final st = status;
    final approved = st == 'Approved' || st == 'Active' || st.toLowerCase() == 'approved' || st.toLowerCase() == 'active';
    final rejected = st == 'Rejected' || st.toLowerCase() == 'rejected';
    return Scaffold(
      appBar: AppBar(
        title: Text(s.t('Application status', 'Hali ya ombi')),
        actions: [
          if (loading) const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
          const ThemeLanguageRow(),
          const SizedBox(width: 12),
        ],
      ),
      body: ResponsivePage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Text(s.t('Registration progress', 'Maendeleo ya usajili'), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(
              s.t('Your documents are checked manually by the ZenjiGO admin team. Status refreshes automatically.', 'Nyaraka zako zinakaguliwa kwa mikono na timu ya usimamizi ya ZenjiGO. Hali inasasishwa moja kwa moja.'),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .67)),
            ),
            const SizedBox(height: 26),
            ..._steps(),
            const SizedBox(height: 18),
            if (rejected)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.error_outline, color: Colors.redAccent),
                  title: Text(s.t('Application rejected', 'Ombi limekataliwa'), style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(rejectionReason?.isNotEmpty == true
                      ? rejectionReason!
                      : s.t('Please contact ZenjiGO support for the review decision and next steps.', 'Wasiliana na msaada wa ZenjiGO kuhusu uamuzi na hatua zinazofuata.')),
                ),
              ),
            if (approved)
              LoadingButton(
                label: s.t('Enter ZenjiGO Driver', 'Ingia ZenjiGO Dereva'),
                icon: Icons.local_taxi_rounded,
                onPressed: _enterApp,
              ),
            if (!approved && !rejected) ...[
              LoadingButton(
                label: s.t('Refresh application status', 'Sasisha hali ya ombi'),
                outline: true,
                onPressed: _refresh,
              ),
              const SizedBox(height: 12),
              Text(
                s.t('Statuses: Pending → Under Review → Approved / Rejected → Active', 'Hali: Inasubiri → Inakaguliwa → Imeidhinishwa / Imekataliwa → Aktivu'),
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .55)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _steps() {
    final s = AppScope.of(context);
    final labels = [
      s.t('Pending', 'Inasubiri'),
      s.t('Under Review', 'Inakaguliwa'),
      s.t('Approved', 'Imeidhinishwa'),
      s.t('Active', 'Aktivu'),
    ];
    final normalized = status.toLowerCase();
    int current = 1;
    if (normalized.contains('pending')) current = 0;
    else if (normalized.contains('review')) current = 1;
    else if (normalized.contains('approved')) current = 2;
    else if (normalized.contains('active')) current = 3;
    else if (normalized.contains('reject')) current = 1;
    return List.generate(labels.length, (i) {
      final done = i <= current;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: done ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withValues(alpha: .1),
              child: Icon(done ? Icons.check : Icons.more_horiz, size: 18, color: done ? Colors.white : null),
            ),
            if (i < labels.length - 1)
              Container(width: 2, height: 42, color: done ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withValues(alpha: .1)),
          ]),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(labels[i], style: TextStyle(fontWeight: FontWeight.w800, color: done ? null : Theme.of(context).colorScheme.onSurface.withValues(alpha: .45))),
                if (i == current)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      i == 1
                          ? s.t('Admin is checking your identity, vehicle and documents.', 'Msimamizi anakagua utambulisho wako, gari na nyaraka.')
                          : s.t('Current application stage', 'Hatua ya sasa ya ombi'),
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .6)),
                    ),
                  ),
              ]),
            ),
          ),
        ],
      );
    });
  }
}
