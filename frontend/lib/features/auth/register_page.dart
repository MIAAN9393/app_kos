import 'package:flutter/material.dart';
import 'package:kos_management/core/navigation/app_routes.dart';
import 'package:kos_management/core/theme/app_design.dart';
import 'package:kos_management/core/widgets/app_primary_button.dart';
import 'package:kos_management/core/widgets/app_text_field.dart';
import 'package:kos_management/features/auth/widget/custom_appsnackbar.dart';
import 'package:kos_management/service/api_service.dart';
import 'package:kos_management/service/auth_service.dart';
import 'package:kos_management/utils/rapikan_pesan_error_or_sukses.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  late final AuthService _auth = AuthService(ApiService());
  final _nama = TextEditingController();
  final _kontak = TextEditingController();
  final _password = TextEditingController();
  String _channel = 'email';
  bool _loading = false;

  @override
  void dispose() {
    _nama.dispose();
    _kontak.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    setState(() => _loading = true);
    try {
      final result = await _auth.register(
        _nama.text,
        _kontak.text,
        _password.text,
        channel: _channel,
      );
      if (!mounted) return;
      AppSnackbar.success(
        context,
        rapikanPesan(result['pesan'] ?? 'Registrasi berhasil'),
      );
      Navigator.pushNamed(
        context,
        AppRoutes.verifyEmail,
        arguments: {'kontak': _kontak.text.trim(), 'channel': _channel},
      );
    } catch (e) {
      if (mounted) AppSnackbar.error(context, rapikanPesan(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesign.surface,
      appBar: AppBar(title: const Text('Daftar')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDesign.spaceLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'Nama',
                hint: 'Nama lengkap',
                controller: _nama,
              ),
              const SizedBox(height: AppDesign.spaceMd),
              SegmentedButton<String>(
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
                onSelectionChanged: _loading
                    ? null
                    : (value) => setState(() {
                        _channel = value.first;
                        _kontak.clear();
                      }),
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
              const SizedBox(height: AppDesign.spaceMd),
              AppTextField(
                label: 'Password',
                hint: 'Minimal 6 karakter',
                controller: _password,
                obscure: true,
              ),
              const SizedBox(height: AppDesign.spaceLg),
              AppPrimaryButton(
                label: 'Daftar',
                loading: _loading,
                onPressed: _register,
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
                child: const Text('Sudah punya akun? Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
