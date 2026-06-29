import 'package:flutter/material.dart';
import 'package:kos_management/core/navigation/app_routes.dart';
import 'package:kos_management/core/theme/app_design.dart';
import 'package:kos_management/core/widgets/app_primary_button.dart';
import 'package:kos_management/core/widgets/app_text_field.dart';
import 'package:kos_management/features/auth/widget/custom_appsnackbar.dart';
import 'package:kos_management/service/api_service.dart';
import 'package:kos_management/service/auth_service.dart';
import 'package:kos_management/utils/rapikan_pesan_error_or_sukses.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  late final AuthService _auth = AuthService(ApiService());
  final _kontak = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String _channel = 'email';
  bool _codeSent = false;
  bool _loadingSend = false;
  bool _loadingReset = false;

  @override
  void dispose() {
    _kontak.dispose();
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    setState(() => _loadingSend = true);
    try {
      final result = await _auth.forgotPassword(
        _kontak.text,
        channel: _channel,
      );
      if (!mounted) return;
      setState(() => _codeSent = true);
      AppSnackbar.success(context, rapikanPesan(result));
    } catch (e) {
      if (mounted) AppSnackbar.error(context, rapikanPesan(e.toString()));
    } finally {
      if (mounted) setState(() => _loadingSend = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_password.text != _confirm.text) {
      AppSnackbar.error(context, 'Konfirmasi password tidak sama');
      return;
    }

    setState(() => _loadingReset = true);
    try {
      final result = await _auth.resetPassword(
        kontak: _kontak.text,
        code: _code.text,
        passwordBaru: _password.text,
        channel: _channel,
      );
      if (!mounted) return;
      AppSnackbar.success(context, rapikanPesan(result));
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
    } catch (e) {
      if (mounted) AppSnackbar.error(context, rapikanPesan(e.toString()));
    } finally {
      if (mounted) setState(() => _loadingReset = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesign.surface,
      appBar: AppBar(title: const Text('Lupa Password')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDesign.spaceLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Masukkan email atau nomor HP akun, lalu gunakan kode OTP untuk membuat password baru.',
                style: AppDesign.bodyMuted(context),
              ),
              const SizedBox(height: AppDesign.spaceLg),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'email',
                      label: Text('Email'),
                      icon: Icon(Icons.email_outlined),
                    ),
                    ButtonSegment(
                      value: 'phone',
                      label: Text('Nomor HP'),
                      icon: Icon(Icons.phone_android_rounded),
                    ),
                  ],
                  selected: {_channel},
                  onSelectionChanged: _loadingSend || _loadingReset
                      ? null
                      : (value) => setState(() {
                          _channel = value.first;
                          _kontak.clear();
                          _codeSent = false;
                        }),
                ),
              ),
              const SizedBox(height: AppDesign.spaceMd),
              AppTextField(
                label: _channel == 'phone' ? 'Nomor HP' : 'Email',
                hint: _channel == 'phone' ? '08123456789' : 'nama@email.com',
                controller: _kontak,
                keyboardType: _channel == 'phone'
                    ? TextInputType.phone
                    : TextInputType.emailAddress,
              ),
              AppPrimaryButton(
                label: _codeSent ? 'Kirim ulang kode' : 'Kirim kode reset',
                loading: _loadingSend,
                onPressed: _loadingReset ? null : _sendCode,
              ),
              if (_codeSent) ...[
                const SizedBox(height: AppDesign.spaceLg),
                AppTextField(
                  label: 'Kode OTP',
                  hint: '123456',
                  controller: _code,
                  keyboardType: TextInputType.number,
                ),
                AppTextField(
                  label: 'Password baru',
                  hint: 'Minimal 6 karakter',
                  controller: _password,
                  obscure: true,
                ),
                AppTextField(
                  label: 'Konfirmasi password',
                  hint: 'Ulangi password baru',
                  controller: _confirm,
                  obscure: true,
                ),
                const SizedBox(height: AppDesign.spaceMd),
                AppPrimaryButton(
                  label: 'Ubah password',
                  loading: _loadingReset,
                  onPressed: _loadingSend ? null : _resetPassword,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
