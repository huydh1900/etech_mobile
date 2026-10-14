import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_kit.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  static final _specialRe = RegExp(r'[!@#$%^&*()_+\-=\[\]{};:,.<>/?]');

  @override
  void initState() {
    super.initState();
    _currentCtrl.addListener(_onChanged);
    _newCtrl.addListener(_onChanged);
    _confirmCtrl.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String get _pw => _newCtrl.text;

  // Ràng buộc mật khẩu theo mẫu thiết kế.
  bool get _ruleLength => _pw.length >= 8 && _pw.length <= 20;
  bool get _ruleComposition =>
      RegExp(r'\d').hasMatch(_pw) &&
      RegExp('[A-Z]').hasMatch(_pw) &&
      RegExp('[a-z]').hasMatch(_pw);
  bool get _ruleSpecial => _specialRe.hasMatch(_pw);

  bool get _isMatched =>
      _confirmCtrl.text.isNotEmpty && _newCtrl.text == _confirmCtrl.text;

  bool get _canSubmit =>
      _currentCtrl.text.isNotEmpty &&
      _ruleLength &&
      _ruleComposition &&
      _ruleSpecial &&
      _isMatched;

  void _submit() {
    if (!_canSubmit) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.success,
        content: const Text('Đổi mật khẩu thành công'),
      ),
    );
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return BrandPage(
      title: 'Đổi mật khẩu',
      headerChild: const Text(
        'Mật khẩu mới cần khác mật khẩu hiện tại và đáp ứng các yêu cầu bên '
        'dưới.',
        style: TextStyle(
          color: kBrandMuted,
          fontSize: AppType.body,
          height: 1.4,
        ),
      ),
      bottom: BrandPrimaryButton(
        label: 'Xác nhận',
        onPressed: _canSubmit ? _submit : null,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PasswordField(
                controller: _currentCtrl,
                hint: 'Mật khẩu hiện tại',
                icon: Icons.lock_outline_rounded,
                show: _showCurrent,
                onToggle: () => setState(() => _showCurrent = !_showCurrent),
              ),
              const SizedBox(height: 8),
              _PasswordField(
                controller: _newCtrl,
                hint: 'Mật khẩu mới',
                icon: Icons.lock_reset_rounded,
                show: _showNew,
                onToggle: () => setState(() => _showNew = !_showNew),
              ),
              const SizedBox(height: 8),
              _PasswordField(
                controller: _confirmCtrl,
                hint: 'Nhập lại mật khẩu mới',
                icon: Icons.lock_reset_rounded,
                show: _showConfirm,
                onToggle: () => setState(() => _showConfirm = !_showConfirm),
              ),
            ],
          ),
        ),
        const BrandSectionLabel('Yêu cầu mật khẩu'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              _RuleRow(ok: _ruleLength, text: 'Từ 8 đến 20 ký tự'),
              const SizedBox(height: 10),
              _RuleRow(
                ok: _ruleComposition,
                text: 'Gồm số, chữ viết hoa và chữ viết thường',
              ),
              const SizedBox(height: 10),
              _RuleRow(
                ok: _ruleSpecial,
                text: r'Có ít nhất một ký tự đặc biệt !@#$^*()_',
              ),
              const SizedBox(height: 10),
              _RuleRow(
                ok: _isMatched,
                text: 'Hai lần nhập mật khẩu mới khớp nhau',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── PASSWORD FIELD ──────────────────────────────────────────────────────────
class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool show;
  final VoidCallback onToggle;

  const _PasswordField({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.show,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: !show,
      style: TextStyle(color: AppColors.ink, fontSize: AppType.subtitle),
      decoration: brandInputDecoration(
        hint: hint,
        prefixIcon: icon,
        suffixIcon: IconButton(
          tooltip: show ? 'Ẩn mật khẩu' : 'Hiện mật khẩu',
          icon: Icon(
            show ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: AppColors.inkMuted,
            size: 21,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }
}

// ─── RULE ROW (checklist) ────────────────────────────────────────────────────
class _RuleRow extends StatelessWidget {
  final bool ok;
  final String text;

  const _RuleRow({required this.ok, required this.text});

  @override
  Widget build(BuildContext context) {
    final color = ok ? AppColors.success : AppColors.inkMuted;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(
            ok ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            color: color,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: ok ? AppColors.ink : AppColors.inkSoft,
              fontSize: AppType.bodyLg,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
