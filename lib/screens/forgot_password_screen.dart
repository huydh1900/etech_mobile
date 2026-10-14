import 'package:flutter/material.dart';
import '../config.dart';
import '../services/odoo_auth_service.dart';
import '../theme/app_theme.dart';
import 'auth_shell.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  bool _loading = false;
  String? _errorMessage;
  bool _sent = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final service = OdooAuthService(
      baseUrl: AppConfig.odooUrl,
      database: AppConfig.odooDb,
    );
    final error = await service.resetPassword(_codeCtrl.text.trim());

    if (!mounted) return;
    setState(() {
      _loading = false;
      _sent = error == null;
      _errorMessage = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Header dùng y hệt màn đăng nhập; quay lại bằng link ở đáy màn (sau khi
    // gửi xong đã có nút "Quay lại đăng nhập" nên ẩn link).
    return AuthHeroScaffold(
      footer: _sent
          ? null
          : Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Đã nhớ mật khẩu? ',
                  style: TextStyle(
                    color: AppColors.inkSoft,
                    fontSize: AppType.bodyLg,
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(6),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 44),
                    // widthFactor: 1 → chỉ rộng vừa chữ (Container+alignment sẽ giãn
                    // hết bề ngang Wrap và đẩy link xuống dòng).
                    child: Align(
                      widthFactor: 1,
                      child: Text(
                        'Đăng nhập',
                        style: TextStyle(
                          color: AppColors.teal,
                          fontSize: AppType.bodyLg,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
      children: [
        AuthTitle(_sent ? 'Đã gửi hướng dẫn' : 'Quên mật khẩu'),
        const SizedBox(height: 8),
        Text(
          _sent
              ? 'Hướng dẫn đặt lại mật khẩu đã được gửi đến email của bạn. '
                    'Vui lòng kiểm tra hộp thư.'
              : 'Nhập mã nhân viên để nhận hướng dẫn đặt lại mật khẩu.',
          style: TextStyle(
            color: AppColors.inkSoft,
            fontSize: AppType.bodyLg,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 18),
        _sent ? _buildSuccess() : _buildForm(),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _codeCtrl,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _loading ? null : _submit(),
            style: TextStyle(fontSize: AppType.subtitle, color: AppColors.ink),
            decoration: brandInputDecoration(
              hint: 'Mã nhân viên (VD: 1024)',
              prefixIcon: Icons.badge_outlined,
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Vui lòng nhập mã nhân viên';
              }
              return null;
            },
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: _errorMessage == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: AuthErrorBanner(_errorMessage!),
                  ),
          ),
          const SizedBox(height: 22),
          BrandPrimaryButton(
            label: 'Gửi hướng dẫn',
            loadingLabel: 'Đang gửi…',
            loading: _loading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.successSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.mark_email_read_outlined,
              color: AppColors.success,
              size: 36,
            ),
          ),
        ),
        const SizedBox(height: 28),
        BrandPrimaryButton(
          label: 'Quay lại đăng nhập',
          loadingLabel: '',
          loading: false,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
