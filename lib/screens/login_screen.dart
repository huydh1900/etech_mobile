import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config.dart';
import '../services/odoo_auth_service.dart';
import '../services/session_store.dart';
import '../models/employee.dart';
import '../services/employee_service.dart';
import '../theme/app_theme.dart';
import 'auth_shell.dart';
import 'forgot_password_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _obscure = true;
  bool _loading = false;
  bool _remember = true;
  String? _errorMessage;

  late final AnimationController _introCtrl;
  late final Animation<double> _introFade;
  late final Animation<Offset> _introSlide;

  @override
  void initState() {
    super.initState();
    _introCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _introFade = CurvedAnimation(parent: _introCtrl, curve: Curves.easeOut);
    _introSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _introCtrl, curve: Curves.easeOutCubic));
    _introCtrl.forward();
  }

  @override
  void dispose() {
    _introCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final service = OdooAuthService(
      baseUrl: AppConfig.odooUrl,
      database: AppConfig.odooDb,
    );
    final result = await service.login(
      _emailCtrl.text.trim(),
      _passwordCtrl.text,
    );

    if (!mounted) return;
    setState(() {
      _loading = false;
      _errorMessage = result.success
          ? null
          : result.errorMessage ?? 'Đăng nhập thất bại';
    });

    if (result.success) {
      final sessionId = result.sessionId ?? '';
      if (_remember && sessionId.isNotEmpty) {
        await SessionStore().save(sessionId: sessionId, uid: result.uid);
      } else {
        await SessionStore().clear();
      }

      final empService = EmployeeService(
        baseUrl: AppConfig.odooUrl,
        sessionId: sessionId,
      );
      Employee? employee;
      try {
        employee = await empService.getMe();
      } catch (e) {
        debugPrint('getMe error: $e');
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            uid: result.uid,
            employee: employee,
            sessionId: sessionId,
          ),
        ),
      );
    }
  }

  void _showForgotPassword() {
    Navigator.of(context).push(authRoute(const ForgotPasswordScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return AuthHeroScaffold(
      animate: (context, body) => FadeTransition(
        opacity: _introFade,
        child: SlideTransition(position: _introSlide, child: body),
      ),
      footer: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'Không nhớ mật khẩu? ',
            style: TextStyle(
              color: AppColors.inkSoft,
              fontSize: AppType.bodyLg,
            ),
          ),
          InkWell(
            onTap: _showForgotPassword,
            borderRadius: BorderRadius.circular(6),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              // widthFactor: 1 → chỉ rộng vừa chữ (Container+alignment sẽ giãn
              // hết bề ngang Wrap và đẩy link xuống dòng).
              child: Align(
                widthFactor: 1,
                child: Text(
                  'Quên mật khẩu',
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
        const AuthTitle('Chào mừng trở lại'),
        const SizedBox(height: 18),
        _buildForm(),
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
            controller: _emailCtrl,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.username],
            onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
            style: TextStyle(fontSize: AppType.subtitle, color: AppColors.ink),
            decoration: brandInputDecoration(
              hint: 'Tên đăng nhập',
              prefixIcon: Icons.mail_outline_rounded,
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Vui lòng nhập tên đăng nhập';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordCtrl,
            focusNode: _passwordFocus,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onFieldSubmitted: (_) => _loading ? null : _submit(),
            style: TextStyle(fontSize: AppType.subtitle, color: AppColors.ink),
            decoration: brandInputDecoration(
              hint: 'Mật khẩu',
              prefixIcon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.inkMuted,
                  size: 21,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
              return null;
            },
          ),
          const SizedBox(height: 14),
          Align(alignment: Alignment.centerLeft, child: _rememberToggle()),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: _errorMessage == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: AuthErrorBanner(_errorMessage!),
                  ),
          ),
          const SizedBox(height: 22),
          BrandPrimaryButton(
            label: 'Đăng nhập',
            loadingLabel: 'Đang đăng nhập…',
            loading: _loading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  Widget _rememberToggle() {
    return InkWell(
      onTap: () => setState(() => _remember = !_remember),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: _remember,
                onChanged: (v) => setState(() => _remember = v ?? false),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                side: BorderSide(color: AppColors.border, width: 1.4),
                activeColor: AppColors.success,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Duy trì đăng nhập',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: AppType.bodyLg,
                  fontWeight: FontWeight.w500,
                  color: AppColors.inkSoft,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
