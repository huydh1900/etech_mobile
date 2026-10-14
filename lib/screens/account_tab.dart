import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../config.dart';
import '../models/employee.dart';
import '../services/employee_service.dart';
import '../services/session_store.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import '../utils/vn_format.dart';
import 'auth_shell.dart';
import 'change_password_screen.dart';
import 'login_screen.dart';

/// Lấy 1-2 chữ cái đầu (in hoa) từ tên nhân viên.
String _initialsFor(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((s) => s.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'E';
  if (parts.length == 1) return parts.first.characters.first.toUpperCase();
  return (parts.first.characters.first + parts.last.characters.first)
      .toUpperCase();
}

String _orDash(String v) => v.trim().isEmpty ? '—' : v.trim();

/// Nội dung trong khung avatar: ảnh thật từ backend nếu có, ngược lại chữ cái đầu.
Widget employeeAvatarChild(Employee e, String sessionId, double fontSize) {
  if (e.hasAvatar && sessionId.isNotEmpty && e.avatarUrl.isNotEmpty) {
    return ClipOval(
      child: Image.network(
        '${AppConfig.odooUrl}${e.avatarUrl}?v=${Uri.encodeComponent(e.writeDate)}',
        headers: {'Cookie': 'session_id=$sessionId'},
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _initialsText(e.name, fontSize),
      ),
    );
  }
  return _initialsText(e.name, fontSize);
}

Widget _initialsText(String name, double fontSize) => Text(
  _initialsFor(name),
  style: TextStyle(
    color: Colors.white,
    fontSize: fontSize,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  ),
);

// ─── ACCOUNT TAB (nội dung tab, home_screen có bottom nav riêng) ──────────────
class AccountTab extends StatefulWidget {
  final Employee employee;
  final String sessionId;
  final ValueChanged<Employee> onUpdated;
  const AccountTab({
    super.key,
    required this.employee,
    required this.sessionId,
    required this.onUpdated,
  });

  @override
  State<AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends State<AccountTab> {
  bool _saving = false;

  EmployeeService get _service =>
      EmployeeService(baseUrl: AppConfig.odooUrl, sessionId: widget.sessionId);

  /// Chọn ảnh từ thư viện → upload base64 → cập nhật. Sửa avatar chỉ làm ở đây
  /// (tab Tài khoản), không còn ở màn "Thông tin của tôi".
  Future<void> _editAvatar() async {
    if (_saving) return;
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (file == null) return;
    if (!mounted) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final bytes = await file.readAsBytes();
      final updated = await _service.updateMe(imageBase64: base64Encode(bytes));
      // Xoá ảnh khỏi cache để Image.network nạp lại ảnh MỚI. Không có bước này,
      // Flutter giữ avatar cũ trong imageCache (URL gần như không đổi nếu
      // write_date cùng giây) → ảnh "như chưa lưu" dù backend đã cập nhật.
      await _evictAvatar(updated);
      if (!mounted) return;
      widget.onUpdated(updated);
      messenger.showSnackBar(
        const SnackBar(content: Text('Đã cập nhật ảnh đại diện')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _evictAvatar(Employee e) async {
    if (e.avatarUrl.isEmpty) return;
    final url =
        '${AppConfig.odooUrl}${e.avatarUrl}?v=${Uri.encodeComponent(e.writeDate)}';
    await NetworkImage(
      url,
      headers: {'Cookie': 'session_id=${widget.sessionId}'},
    ).evict();
  }

  @override
  Widget build(BuildContext context) {
    final employee = widget.employee;
    final sessionId = widget.sessionId;
    return Container(
      color: AppColors.surface,
      child: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              _ProfileHeader(
                employee: employee,
                sessionId: sessionId,
                onEditAvatar: _saving ? null : _editAvatar,
              ),
              const BrandSectionLabel('Cá nhân'),
              BrandMenuGroup(
                children: [
                  BrandMenuRow(
                    icon: Icons.person_outline_rounded,
                    label: 'Thông tin của tôi',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EmployeeInfoScreen(
                          employee: employee,
                          sessionId: sessionId,
                          onUpdated: widget.onUpdated,
                        ),
                      ),
                    ),
                  ),
                  BrandMenuRow(
                    icon: Icons.lock_outline_rounded,
                    label: 'Đổi mật khẩu',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ChangePasswordScreen(),
                      ),
                    ),
                  ),
                  BrandMenuRow(
                    icon: Icons.settings_outlined,
                    label: 'Cài đặt',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AccountSettingsScreen(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              BrandMenuGroup(
                children: [
                  BrandMenuRow(
                    icon: Icons.logout_rounded,
                    label: 'Đăng xuất',
                    danger: true,
                    onTap: () => _handleLogout(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  '${AppConfig.appName} · v${AppConfig.appVersion}',
                  style: TextStyle(
                    fontSize: AppType.micro,
                    fontWeight: FontWeight.w500,
                    color: AppColors.inkMuted.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
          if (_saving)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.15),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: AppColors.border),
        ),
        title: Text(
          'Đăng xuất',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: AppType.title,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Bạn có chắc muốn đăng xuất khỏi tài khoản?',
          style: TextStyle(color: AppColors.inkSoft, fontSize: AppType.bodyLg),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy', style: TextStyle(color: AppColors.inkSoft)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await SessionStore().clear();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }
}

// ─── PROFILE HEADER ─────────────────────────────────────────────────────────
/// Header tab Tài khoản cùng style trang chủ: nền sáng cùng họ màu logo, tràn
/// lên dưới status bar, bo góc dưới; avatar lớn ở giữa + tên + chức danh.
class _ProfileHeader extends StatelessWidget {
  final Employee employee;
  final String sessionId;

  /// Bấm avatar để đổi ảnh đại diện. null → ẩn badge camera, không bấm được.
  final VoidCallback? onEditAvatar;

  const _ProfileHeader({
    required this.employee,
    required this.sessionId,
    this.onEditAvatar,
  });

  @override
  Widget build(BuildContext context) {
    final role = [
      employee.jobPosition,
      employee.department,
    ].where((s) => s.trim().isNotEmpty).join(' · ');
    return BrandHeader(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 26),
      child: Column(
        children: [
          const Text(
            'Tài khoản',
            style: TextStyle(
              color: kBrandNavy,
              fontSize: AppType.title,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onEditAvatar,
            child: Stack(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.teal,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: AppShadows.lifted,
                  ),
                  child: employeeAvatarChild(employee, sessionId, 32),
                ),
                if (onEditAvatar != null)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        gradient: AppGradients.cta,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 15,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _orDash(employee.name),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: kBrandNavy,
              fontSize: AppType.headline,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (role.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              role,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: kBrandMuted,
                fontSize: AppType.body,
              ),
            ),
          ],
          if (employee.email.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.mail_outline_rounded,
                    size: 14,
                    color: kBrandMuted,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      employee.email.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: kBrandNavy,
                        fontSize: AppType.caption,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── EMPLOYEE INFO SCREEN ────────────────────────────────────────────────────
class EmployeeInfoScreen extends StatefulWidget {
  final Employee employee;
  final String sessionId;
  final ValueChanged<Employee> onUpdated;
  const EmployeeInfoScreen({
    super.key,
    required this.employee,
    required this.sessionId,
    required this.onUpdated,
  });

  @override
  State<EmployeeInfoScreen> createState() => _EmployeeInfoScreenState();
}

class _EmployeeInfoScreenState extends State<EmployeeInfoScreen> {
  late Employee employee = widget.employee;
  bool _saving = false;

  EmployeeService get _service =>
      EmployeeService(baseUrl: AppConfig.odooUrl, sessionId: widget.sessionId);

  /// Gọi updateMe với đúng field cần đổi rồi đồng bộ state + báo lên cha.
  Future<void> _save({String? phone, String? address, String? birthday}) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final updated = await _service.updateMe(
        phone: phone,
        address: address,
        birthday: birthday,
      );
      if (!mounted) return;
      setState(() => employee = updated);
      widget.onUpdated(updated);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã cập nhật thông tin')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _editPhone() async {
    final v = await _promptText(
      title: 'Số điện thoại',
      initial: employee.phone,
      keyboardType: TextInputType.phone,
    );
    if (v != null) await _save(phone: v);
  }

  Future<void> _editAddress() async {
    final v = await _promptText(
      title: 'Địa chỉ',
      initial: employee.address,
      maxLines: 3,
    );
    if (v != null) await _save(address: v);
  }

  Future<void> _editBirthday() async {
    final initial =
        DateTime.tryParse(employee.birthday) ?? DateTime(2000, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    final s =
        '${picked.year.toString().padLeft(4, '0')}-'
        '${picked.month.toString().padLeft(2, '0')}-'
        '${picked.day.toString().padLeft(2, '0')}';
    await _save(birthday: s);
  }

  /// Dialog nhập 1 trường text. Trả null nếu huỷ.
  Future<String?> _promptText({
    required String title,
    required String initial,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: AppColors.border),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: AppColors.ink,
            fontSize: AppType.title,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          autofocus: true,
          style: TextStyle(color: AppColors.ink),
          decoration: InputDecoration(
            hintText: title,
            hintStyle: TextStyle(color: AppColors.inkMuted),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Hủy', style: TextStyle(color: AppColors.inkSoft)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final edit = !_saving;
    BrandMenuRow field(
      IconData icon,
      Color color,
      String label,
      String value, {
      VoidCallback? onEdit,
      bool multiline = false,
    }) => BrandMenuRow(
      icon: icon,
      color: color,
      label: label,
      subtitle: _orDash(value),
      valueStyle: true,
      multiline: multiline,
      trailing: onEdit == null
          ? null
          : IconButton(
              onPressed: onEdit,
              visualDensity: VisualDensity.compact,
              tooltip: 'Chỉnh sửa $label',
              icon: Icon(
                Icons.edit_outlined,
                size: 18,
                color: AppColors.inkMuted,
              ),
            ),
    );
    return BrandPage(
      title: 'Thông tin của tôi',
      busy: _saving,
      headerChild: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _orDash(employee.name),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: kBrandNavy,
              fontSize: AppType.title,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _orDash(employee.jobPosition),
            style: const TextStyle(color: kBrandMuted, fontSize: AppType.body),
          ),
        ],
      ),
      children: [
        const BrandSectionLabel('Thông tin công việc'),
        BrandMenuGroup(
          children: [
            field(
              Icons.badge_outlined,
              AppColors.primary,
              'Mã nhân viên',
              employee.employeeCode,
            ),
            field(
              Icons.work_outline,
              AppColors.teal,
              'Chức vụ',
              employee.jobPosition,
            ),
            field(
              Icons.account_tree_outlined,
              AppColors.violet,
              'Phòng ban',
              employee.department,
            ),
            field(
              Icons.supervisor_account_outlined,
              AppColors.violet,
              'Trưởng phòng',
              employee.departmentManager,
            ),
            field(
              Icons.person_outline,
              AppColors.violet,
              'Người quản lý',
              employee.manager,
            ),
            field(
              Icons.business_outlined,
              AppColors.info,
              'Công ty',
              employee.company,
            ),
            field(
              Icons.event_available_outlined,
              AppColors.success,
              'Ngày vào công ty',
              formatVn(employee.dateStart),
            ),
          ],
        ),
        const BrandSectionLabel('Thông tin liên hệ'),
        BrandMenuGroup(
          children: [
            field(
              Icons.email_outlined,
              AppColors.primary,
              'Email công ty',
              employee.email,
            ),
            field(
              Icons.phone_outlined,
              AppColors.teal,
              'Số điện thoại',
              employee.phone,
              onEdit: edit ? _editPhone : null,
            ),
            field(
              Icons.cake_outlined,
              AppColors.orange,
              'Ngày sinh',
              formatVn(employee.birthday),
              onEdit: edit ? _editBirthday : null,
            ),
            field(
              Icons.location_on_outlined,
              AppColors.warning,
              'Địa chỉ',
              employee.address,
              multiline: true,
              onEdit: edit ? _editAddress : null,
            ),
          ],
        ),
      ],
    );
  }
}

// ─── ACCOUNT SETTINGS SCREEN ─────────────────────────────────────────────────
class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  bool _notifications = true;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeController,
      builder: (context, _) {
        return BrandPage(
          title: 'Cài đặt',
          children: [
            const BrandSectionLabel('Ứng dụng'),
            BrandMenuGroup(
              children: [
                BrandMenuRow(
                  icon: themeController.isDark
                      ? Icons.dark_mode_outlined
                      : Icons.light_mode_outlined,
                  label: 'Giao diện',
                  subtitle: themeController.isDark ? 'Tối' : 'Sáng',
                  onTap: themeController.toggle,
                  trailing: _brandSwitch(
                    themeController.isDark,
                    (_) => themeController.toggle(),
                  ),
                ),
                BrandMenuRow(
                  icon: Icons.notifications_outlined,
                  label: 'Thông báo',
                  onTap: () => setState(() => _notifications = !_notifications),
                  trailing: _brandSwitch(
                    _notifications,
                    (v) => setState(() => _notifications = v),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

Widget _brandSwitch(bool value, ValueChanged<bool> onChanged) =>
    Switch.adaptive(
      value: value,
      activeThumbColor: Colors.white,
      activeTrackColor: AppColors.teal,
      onChanged: onChanged,
    );
