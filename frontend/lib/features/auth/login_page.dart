import 'package:flutter/material.dart';
import 'package:kos_management/core/navigation/app_navigation.dart';
import 'package:kos_management/core/navigation/app_routes.dart';
import 'package:kos_management/core/theme/app_design.dart';
import 'package:kos_management/core/widgets/app_primary_button.dart';
import 'package:kos_management/core/widgets/app_text_field.dart';
import 'package:kos_management/features/auth/widget/custom_appsnackbar.dart';
import 'package:kos_management/service/api_service.dart';
import 'package:kos_management/service/auth_service.dart';
import 'package:kos_management/utils/rapikan_pesan_error_or_sukses.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final AuthService _auth = AuthService(ApiService());
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  String _channel = 'email';
  bool _loading = false;
  bool _googleLoading = false;

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      final result = await _auth.login(
        _identifier.text,
        _password.text,
        channel: _channel,
      );
      if (!mounted) return;
      AppSnackbar.success(context, rapikanPesan(result));
      AppNavigation.goHome(context);
    } catch (e) {
      if (mounted) AppSnackbar.error(context, rapikanPesan(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginGoogle() async {
    setState(() => _googleLoading = true);
    try {
      final result = await _auth.loginGoogle();
      if (!mounted) return;
      AppSnackbar.success(context, rapikanPesan(result));
      AppNavigation.goHome(context);
    } catch (e) {
      if (mounted) AppSnackbar.error(context, rapikanPesan(e.toString()));
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesign.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDesign.spaceLg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppDesign.spaceXl),
                  Icon(
                    Icons.home_work_rounded,
                    size: 56,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: AppDesign.spaceMd),
                  Text(
                    'Kos Management',
                    textAlign: TextAlign.center,
                    style: AppDesign.sectionTitle(context),
                  ),
                  const SizedBox(height: AppDesign.spaceXs),
                  Text(
                    'Kelola properti kos dengan mudah',
                    textAlign: TextAlign.center,
                    style: AppDesign.bodyMuted(context),
                  ),
                  const SizedBox(height: AppDesign.spaceXl),
                  Container(
                    padding: const EdgeInsets.all(AppDesign.spaceLg),
                    decoration: AppDesign.cardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Masuk', style: AppDesign.titleBold(context)),
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
                            onSelectionChanged: (_loading || _googleLoading)
                                ? null
                                : (value) => setState(() {
                                    _channel = value.first;
                                    _identifier.clear();
                                  }),
                          ),
                        ),
                        const SizedBox(height: AppDesign.spaceMd),
                        AppTextField(
                          label: _channel == 'phone' ? 'Nomor HP' : 'Email',
                          hint: _channel == 'phone'
                              ? '08123456789'
                              : 'nama@email.com',
                          icon: _channel == 'phone'
                              ? Icons.phone_android_rounded
                              : Icons.email_outlined,
                          controller: _identifier,
                          keyboardType: _channel == 'phone'
                              ? TextInputType.phone
                              : TextInputType.emailAddress,
                        ),
                        const SizedBox(height: AppDesign.spaceMd),
                        AppTextField(
                          label: 'Password',
                          hint: '••••••••',
                          icon: Icons.lock_outline_rounded,
                          controller: _password,
                          obscure: true,
                        ),
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: AppDesign.spaceSm,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pushNamed(
                                context,
                                AppRoutes.verifyEmail,
                                arguments: {
                                  'kontak': _identifier.text.trim(),
                                  'channel': _channel,
                                },
                              ),
                              child: const Text('Verifikasi akun'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pushNamed(
                                context,
                                AppRoutes.forgotPassword,
                              ),
                              child: const Text('Lupa password?'),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDesign.spaceLg),
                        AppPrimaryButton(
                          label: 'Login',
                          loading: _loading,
                          onPressed: _googleLoading ? null : _login,
                        ),
                        const SizedBox(height: AppDesign.spaceMd),
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppDesign.spaceSm,
                              ),
                              child: Text(
                                'atau',
                                style: AppDesign.bodyMuted(context),
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: AppDesign.spaceMd),
                        AppPrimaryButton(
                          label: 'Login dengan Google',
                          icon: Icons.g_mobiledata_rounded,
                          outlined: true,
                          loading: _googleLoading,
                          onPressed: _loading ? null : _loginGoogle,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDesign.spaceMd),
                  TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.register),
                    child: const Text('Belum punya akun? Daftar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
