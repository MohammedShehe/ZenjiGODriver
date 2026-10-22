import 'dart:async';
import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/api/driver_api.dart';
import '../core/widgets.dart';
import 'main_shell.dart';
import 'registration.dart';

/// Driver login uses email OTP only (no phone verification):
/// POST /auth/driver/send-otp { email, purpose: "login" }
/// POST /auth/driver/login     { email, code }
class DriverLoginScreen extends StatefulWidget {
  const DriverLoginScreen({super.key});
  @override
  State<DriverLoginScreen> createState() => _DriverLoginScreenState();
}

class _DriverLoginScreenState extends State<DriverLoginScreen> {
  final email = TextEditingController();
  final otp = TextEditingController();
  String currentEmail = '';
  bool sent = false;
  bool loading = false;
  int seconds = 0;
  Timer? timer;


  @override
  void dispose() {
    email.dispose();
    otp.dispose();
    timer?.cancel();
    super.dispose();
  }

  String? _validatedEmail() {
    final value = email.text.trim().toLowerCase();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)) {
      toast(context, 'Enter a valid email address.');
      return null;
    }
    return value;
  }


  Future<void> send() async {
    if (loading) return;
    final validEmail = _validatedEmail();
    if (validEmail == null) return;
    setState(() => loading = true);
    try {
      // Email is the sole login factor; no phone number is requested or verified.
      final response = await DriverApi.sendOtp(
        email: validEmail,
        purpose: 'login',
      );
      currentEmail = (response['target'] ?? validEmail).toString();
      if (!mounted) return;
      setState(() => sent = true);
      start();
      toast(context, 'OTP sent to $currentEmail.');
    } catch (e) {
      if (mounted) toast(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void start() {
    timer?.cancel();
    setState(() => seconds = 60);
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || seconds <= 1) {
        t.cancel();
        if (mounted) setState(() => seconds = 0);
        return;
      }
      setState(() => seconds--);
    });
  }

  Future<void> verify() async {
    if (loading) return;
    final code = otp.text.trim();
    if (code.length < 4) {
      toast(context, 'Enter the OTP.');
      return;
    }
    setState(() => loading = true);
    try {
      final data = await DriverApi.login(
        email: currentEmail,
        code: code,
      );
      if (!mounted) return;
      await AppScope.of(context).login(data);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainShell()),
        );
      }
    } catch (e) {
      if (mounted) toast(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void backToDetails() {
    timer?.cancel();
    setState(() {
      sent = false;
      seconds = 0;
      otp.clear();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Driver sign in')),
        body: ResponsivePage(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Text('Welcome back', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              const Text('Sign in securely using the email address registered with ZenjiGO. No phone verification is required.'),
              const SizedBox(height: 24),
              if (!sent) ...[
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(labelText: 'Email address', prefixIcon: Icon(Icons.email_outlined), hintText: 'you@example.com'),
                ),
                const SizedBox(height: 16),
                LoadingButton(label: 'Send email OTP', onPressed: send),
              ] else ...[
                Text('Email code sent to ${_maskedEmail(currentEmail)}'),
                const SizedBox(height: 12),
                TextField(
                  controller: otp,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  maxLength: 8,
                  decoration: const InputDecoration(labelText: 'OTP code', counterText: ''),
                  onSubmitted: (_) => verify(),
                ),
                const SizedBox(height: 8),
                Text(seconds > 0 ? 'Resend in $seconds s' : 'You can resend the OTP.'),
                const SizedBox(height: 12),
                LoadingButton(label: 'Verify & sign in', onPressed: verify),
                TextButton(onPressed: loading || seconds > 0 ? null : send, child: const Text('Resend OTP')),
                TextButton(onPressed: loading ? null : backToDetails, child: const Text('Change email')),
              ],
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegistrationScreen())),
                child: const Text('Register as a driver'),
              ),
            ],
          ),
        ),
      );

  String _maskedEmail(String value) {
    final parts = value.split('@');
    if (parts.length != 2 || parts[0].length < 2) return value;
    return '${parts[0][0]}***${parts[0][parts[0].length - 1]}@${parts[1]}';
  }
}
