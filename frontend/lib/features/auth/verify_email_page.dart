import 'package:flutter/material.dart';
import 'package:kos_management/core/navigation/app_routes.dart';
import 'package:kos_management/core/theme/app_design.dart';
import 'package:kos_management/core/widgets/app_primary_button.dart';
import 'package:kos_management/core/widgets/app_text_field.dart';
import 'package:kos_management/features/auth/widget/custom_appsnackbar.dart';
import 'package:kos_management/service/api_service.dart';
import 'package:kos_management/service/auth_service.dart';
import 'package:kos_management/utils/rapikan_pesan_error_or_sukses.dart';

class VerifyEmailPage extends StatefulWidget {
  final String kontakAwal;
  final String channel;

  const VerifyEmailPage({
    super.key,
    required this.kontakAwal,
    this.channel = 'email',
  });

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  late final AuthService _auth = AuthService(ApiService());
  late final TextEditingController _kontak;
  final _code = TextEditingController();
  bool _loading = false;
  bool _resendLoading = false;

  @override
  void initState() {
    super.initState();
    _kontak = TextEditingController(text: widget.kontakAwal);
  }

  @override
  void dispose() {
    _kontak.dispose();
    _code.dispose();
    super.dispose();
  }

  bool get _isPhone => widget.channel == 'phone';

  Future<void> _verify() async {
    setState(() => _loading = true);
    try {
      final result = _isPhone
          ? await _auth.verifyPhone(_kontak.text, _code.text)
          : await _auth.verifyEmail(_kontak.text, _code.text);
      if (!mounted) return;
      AppSnackbar.success(context, rapikanPesan(result));
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
    } catch (e) {
      if (mounted) AppSnackbar.error(context, rapikanPesan(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _resendLoading = true);
    try {
      final result = _isPhone
          ? await _auth.resendPhoneVerification(_kontak.text)
          : await _auth.resendEmailVerification(_kontak.text);
      if (!mounted) return;
      AppSnackbar.success(context, rapikanPesan(result));
    } catch (e) {
      if (mounted) AppSnackbar.error(context, rapikanPesan(e.toString()));
    } finally {
      if (mounted) setState(() => _resendLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesign.surface,
      appBar: AppBar(
        title: Text(_isPhone ? 'Verifikasi Nomor HP' : 'Verifikasi Email'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDesign.spaceLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isPhone
                    ? 'Masukkan kode OTP 6 digit yang dikirim ke nomor HP kamu.'
                    : 'Masukkan kode OTP 6 digit yang dikirim ke email kamu.',
                style: AppDesign.bodyMuted(context),
              ),
              const SizedBox(height: AppDesign.spaceLg),
              AppTextField(
                label: _isPhone ? 'Nomor HP' : 'Email',
                hint: _isPhone ? '08123456789' : 'nama@email.com',
                controller: _kontak,
                keyboardType: _isPhone
                    ? TextInputType.phone
                    : TextInputType.emailAddress,
              ),
              AppTextField(
                label: 'Kode OTP',
                hint: '123456',
                controller: _code,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppDesign.spaceMd),
              AppPrimaryButton(
                label: 'Verifikasi',
                loading: _loading,
                onPressed: _resendLoading ? null : _verify,
              ),
              const SizedBox(height: AppDesign.spaceSm),
              AppPrimaryButton(
                label: 'Kirim ulang kode',
                outlined: true,
                loading: _resendLoading,
                onPressed: _loading ? null : _resend,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
