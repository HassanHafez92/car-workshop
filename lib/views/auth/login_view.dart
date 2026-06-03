import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/role_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref.read(authProvider.notifier).login(
            _usernameCtrl.text,
            _passwordCtrl.text,
          );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تسجيل الدخول بنجاح!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  void _bypassLogin(String username, String password) async {
    _usernameCtrl.text = username;
    _passwordCtrl.text = password;
    final success = await ref.read(authProvider.notifier).login(username, password);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('دخول سريع بصفتك: ${ref.read(authProvider).currentUser?.role.nameAr}'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Main Container Card (following Stitch No-Line Rule)
                    Container(
                      width: 480,
                      padding: const EdgeInsets.all(36.0),
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceLowest,
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x0A000000),
                            blurRadius: 40,
                            offset: Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Logo and Title
                            const Icon(
                              Icons.minor_crash_outlined,
                              size: 64,
                              color: AppColors.primary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'نظام إدارة ورش السيارات',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'سجل الدخول للوصول إلى لوحة العمل والتحكم الخاصة بك',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                            ),
                            const SizedBox(height: 32),

                            // Error Box
                            if (authState.errorMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withOpacity(0.08),
                                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline, color: AppColors.error),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        authState.errorMessage!,
                                        style: const TextStyle(
                                          color: AppColors.error,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Username Input field
                            const FormFieldLabel(label: 'اسم المستخدم'),
                            TextFormField(
                              controller: _usernameCtrl,
                              textDirection: TextDirection.ltr,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.person_outline, color: AppColors.textMuted),
                                hintText: 'أدخل اسم المستخدم',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'يرجى إدخال اسم المستخدم';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Password Input field
                            const FormFieldLabel(label: 'كلمة المرور'),
                            TextFormField(
                              controller: _passwordCtrl,
                              obscureText: true,
                              textDirection: TextDirection.ltr,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.lock_outline, color: AppColors.textMuted),
                                hintText: 'أدخل كلمة المرور',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'يرجى إدخال كلمة المرور';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),

                            // Submit Button
                            ElevatedButton(
                              onPressed: authState.isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: AppColors.primary,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(8)),
                                ),
                              ),
                              child: authState.isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      'تسجيل الدخول للنظام',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Quick Bypass Simulator Card (Stitch Surface Low)
                    Container(
                      width: 480,
                      padding: const EdgeInsets.all(24.0),
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceLow,
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.speed, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(
                                'محاكي الدخول السريع (للاختبار والتقييم)',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'اضغط على أي من الأدوار أدناه للدخول الفوري وتجربة الشاشات والتقارير المخصصة لكل وظيفة:',
                            style: TextStyle(fontSize: 12, height: 1.5),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              _buildBypassButton('المدير العام', 'admin', 'admin123', Colors.purple),
                              _buildBypassButton('الاستقبال', 'reception', 'rec123', Colors.blue),
                              _buildBypassButton('الفني المختص', 'tech', 'tech123', Colors.orange),
                              _buildBypassButton('المستودع', 'store', 'store123', Colors.green),
                              _buildBypassButton('المحاسب المالي', 'accountant', 'acc123', Colors.teal),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (authState.isLoading)
              const ModalBarrier(
                dismissible: false,
                color: Colors.black12,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBypassButton(String label, String user, String pass, Color color) {
    return ElevatedButton(
      onPressed: () => _bypassLogin(user, pass),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textMain,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        side: BorderSide(color: color.withOpacity(0.3), width: 1),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 5,
            backgroundColor: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
