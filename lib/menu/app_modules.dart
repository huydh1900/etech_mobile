import 'package:flutter/material.dart';

/// ───────────────────────────────────────────────────────────────────────────
/// CÂY MENU CHÍNH CỦA APP — ĐỒNG BỘ 1:1 VỚI BACKEND `elab-tech` (Odoo)
///
/// Mỗi [AppModule] / [AppSubMenu] map trực tiếp tới một `<menuitem>` ở backend
/// qua trường [backendXmlId]. Đây là **nguồn sự thật duy nhất** cho điều hướng
/// nghiệp vụ trên mobile: khi backend thêm/sửa/đổi tên menu, chỉ cần cập nhật
/// file này để giữ đồng bộ.
///
/// Phạm vi: 6 module nghiệp vụ dành cho người dùng hiện trường / phòng lab.
/// (Đã loại "Danh mục"/Cấu hình — chỉ dùng trên desktop cho admin.)
///
/// TODO(sync-động): có thể thay bảng tĩnh này bằng việc nạp `ir.ui.menu` trực
/// tiếp từ backend (lọc theo quyền user) để đồng bộ hoàn toàn tự động.
/// ───────────────────────────────────────────────────────────────────────────

/// Một menu con (cấp 2) — tương ứng 1 menuitem lá ở backend.
class AppSubMenu {
  /// Nhãn hiển thị — khớp `name` của menuitem backend.
  final String name;

  /// XML id của menuitem backend (tham chiếu đồng bộ, không hiển thị).
  final String backendXmlId;

  final IconData icon;

  /// `true` khi đã có màn hình mobile thật; `false` → hiện màn placeholder.
  final bool implemented;

  /// Menu cấp 3 (nếu backend có menu con dưới menu này). Rỗng → menu lá.
  final List<AppSubMenu> children;

  const AppSubMenu({
    required this.name,
    required this.backendXmlId,
    required this.icon,
    this.implemented = false,
    this.children = const [],
  });

  AppSubMenu copyWith({String? name, List<AppSubMenu>? children}) => AppSubMenu(
        name: name ?? this.name,
        backendXmlId: backendXmlId,
        icon: icon,
        implemented: implemented,
        children: children ?? this.children,
      );
}

/// Một module (cấp 1) — tương ứng 1 root menuitem ở backend.
class AppModule {
  final String key;
  final String name;
  final String backendXmlId;
  final String description;
  final IconData icon;
  final List<Color> gradient;
  final List<AppSubMenu> children;

  const AppModule({
    required this.key,
    required this.name,
    required this.backendXmlId,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.children,
  });

  AppModule copyWith({String? name, List<AppSubMenu>? children}) => AppModule(
        key: key,
        name: name ?? this.name,
        backendXmlId: backendXmlId,
        description: description,
        icon: icon,
        gradient: gradient,
        children: children ?? this.children,
      );
}

/// 6 module nghiệp vụ, theo đúng thứ tự luồng LIMS của backend.
const List<AppModule> kAppModules = <AppModule>[
  // 1) menu_etech_request_root — "Hồ sơ"
  AppModule(
    key: 'request',
    name: 'Hồ sơ',
    backendXmlId: 'menu_etech_request_root',
    description: 'Phiếu yêu cầu & khách hàng',
    icon: Icons.folder_shared_rounded,
    gradient: [Color(0xFF0B5FD8), Color(0xFF22D3EE)],
    children: [
      AppSubMenu(
        name: 'Phiếu yêu cầu',
        backendXmlId: 'menu_etech_service_request',
        icon: Icons.description_rounded,
        implemented: true,
      ),
      AppSubMenu(
        name: 'Tiếp nhận khách hàng',
        backendXmlId: 'menu_etech_intake',
        icon: Icons.how_to_reg_rounded,
      ),
      AppSubMenu(
        name: 'Khách hàng',
        backendXmlId: 'menu_etech_customer',
        icon: Icons.groups_rounded,
        implemented: true,
      ),
    ],
  ),

  // 2) menu_etech_field_root — "Hiện trường"
  AppModule(
    key: 'field',
    name: 'Hiện trường',
    backendXmlId: 'menu_etech_field_root',
    description: 'Lấy mẫu & biên bản hiện trường',
    icon: Icons.location_on_rounded,
    gradient: [Color(0xFF16A34A), Color(0xFF4ADE80)],
    children: [
      AppSubMenu(
        name: 'Kế hoạch lấy mẫu',
        backendXmlId: 'menu_etech_sampling_program',
        icon: Icons.event_note_rounded,
        implemented: true,
        // Backend: menu này là menu cha (không có action), 2 menu con lá.
        children: [
          AppSubMenu(
            name: 'Của tôi',
            backendXmlId: 'menu_etech_sampling_program_my',
            icon: Icons.person_pin_circle_rounded,
            implemented: true,
          ),
          AppSubMenu(
            name: 'Cần lên lịch',
            backendXmlId: 'menu_etech_sampling_program_need_schedule',
            icon: Icons.schedule_rounded,
            implemented: true,
          ),
        ],
      ),
      AppSubMenu(
        name: 'Biên bản hiện trường',
        backendXmlId: 'menu_etech_sampling_report',
        icon: Icons.assignment_rounded,
        implemented: true,
      ),
      AppSubMenu(
        name: 'Phiếu bàn giao mẫu',
        backendXmlId: 'menu_etech_sampling_handover',
        icon: Icons.swap_horiz_rounded,
        implemented: true,
      ),
    ],
  ),

  // 3) menu_etech_reception_root — "Tiếp nhận mẫu"
  AppModule(
    key: 'reception',
    name: 'Tiếp nhận mẫu',
    backendXmlId: 'menu_etech_reception_root',
    description: 'Nhận & bàn giao mẫu',
    icon: Icons.move_to_inbox_rounded,
    gradient: [Color(0xFF0891B2), Color(0xFF22D3EE)],
    children: [
      AppSubMenu(
        name: 'Phiếu bàn giao mẫu',
        backendXmlId: 'menu_etech_reception_sampling_handover',
        icon: Icons.inbox_rounded,
        implemented: true,
      ),
      AppSubMenu(
        name: 'Yêu cầu sơ chế',
        backendXmlId: 'menu_etech_reception_preprocess_request',
        icon: Icons.pending_actions_rounded,
        implemented: true,
      ),
    ],
  ),

  // 4) menu_etech_preparation_root — "Chuẩn bị mẫu"
  AppModule(
    key: 'preparation',
    name: 'Chuẩn bị mẫu',
    backendXmlId: 'menu_etech_preparation_root',
    description: 'Sơ chế, phân tích & báo cáo',
    icon: Icons.science_rounded,
    gradient: [Color(0xFF7C3AED), Color(0xFFA855F7)],
    children: [
      AppSubMenu(
        name: 'Yêu cầu sơ chế',
        backendXmlId: 'menu_etech_preparation_preprocess_request',
        icon: Icons.blender_rounded,
        implemented: true,
      ),
      AppSubMenu(
        name: 'Yêu cầu phân tích',
        backendXmlId: 'menu_etech_preparation_analysis_request',
        icon: Icons.biotech_rounded,
        implemented: true,
      ),
      AppSubMenu(
        name: 'Báo cáo hiệu quả công việc',
        backendXmlId: 'menu_etech_preparation_report_summary',
        icon: Icons.insights_rounded,
      ),
      AppSubMenu(
        name: 'Báo cáo khối lượng công việc',
        backendXmlId: 'menu_etech_preparation_workload_report',
        icon: Icons.bar_chart_rounded,
      ),
    ],
  ),

  // 5) menu_etech_lab_root — "Phòng thí nghiệm"
  AppModule(
    key: 'lab',
    name: 'Phòng thí nghiệm',
    backendXmlId: 'menu_etech_lab_root',
    description: 'Mẻ mẫu, lưu mẫu & kết quả',
    icon: Icons.biotech_rounded,
    gradient: [Color(0xFFEA580C), Color(0xFFFB923C)],
    children: [
      AppSubMenu(
        name: 'Yêu cầu phân tích',
        backendXmlId: 'menu_etech_analysis_request',
        icon: Icons.assignment_turned_in_rounded,
        implemented: true,
      ),
      AppSubMenu(
        name: 'Tạo mẻ mẫu',
        backendXmlId: 'menu_etech_lab_batch_create',
        icon: Icons.add_box_rounded,
      ),
      AppSubMenu(
        name: 'Mẻ mẫu',
        backendXmlId: 'menu_etech_lab_batch',
        icon: Icons.inventory_2_rounded,
        implemented: true,
      ),
      AppSubMenu(
        name: 'Lưu mẫu',
        backendXmlId: 'menu_etech_retained_sample',
        icon: Icons.inventory_rounded,
        implemented: true,
      ),
      AppSubMenu(
        name: 'Biên bản hủy mẫu',
        backendXmlId: 'menu_etech_sample_destruction',
        icon: Icons.delete_sweep_rounded,
        implemented: true,
      ),
      AppSubMenu(
        name: 'Phiếu kết quả',
        backendXmlId: 'menu_etech_test_report',
        icon: Icons.fact_check_rounded,
        implemented: true,
      ),
    ],
  ),

  // 6) menu_etech_calendar_root — "Lịch công tác"
  AppModule(
    key: 'calendar',
    name: 'Lịch công tác',
    backendXmlId: 'menu_etech_calendar_root',
    description: 'Lịch & phân công công việc',
    icon: Icons.event_rounded,
    gradient: [Color(0xFF2563EB), Color(0xFF60A5FA)],
    children: [
      AppSubMenu(
        name: 'Lịch công tác',
        backendXmlId: 'menu_etech_work_schedule',
        icon: Icons.event_available_rounded,
      ),
      AppSubMenu(
        name: 'Quản lý lịch',
        backendXmlId: 'menu_etech_calendar_event',
        icon: Icons.calendar_month_rounded,
      ),
    ],
  ),
];

/// Module được hiển thị trên MÀN HÌNH CHÍNH (yêu cầu nghiệp vụ hiện tại: chỉ
/// "Hiện trường" + "Lịch công tác"). Các module khác vẫn giữ trong [kAppModules]
/// để đồng bộ cây menu backend nhưng không lên lưới trang chủ.
const Set<String> kHomeModuleKeys = {'field', 'calendar'};

/// Lọc danh sách module xuống các module hiện trên trang chủ ([kHomeModuleKeys]).
List<AppModule> homeModules(List<AppModule> modules) =>
    modules.where((m) => kHomeModuleKeys.contains(m.key)).toList();

/// Lấy module theo [key] trong danh sách [modules] (mặc định: cấu hình tĩnh).
AppModule? moduleByKey(String key, [List<AppModule>? modules]) {
  for (final m in modules ?? kAppModules) {
    if (m.key == key) return m;
  }
  return null;
}

/// Lọc cấu hình tĩnh theo tập menu user được phép thấy (đồng bộ động backend).
///
/// - [visible]: tập xmlid (đã bỏ tiền tố module) user được thấy. `null` → giữ
///   nguyên cấu hình tĩnh (dùng khi offline / lỗi tải menu).
/// - [names]: override nhãn module/menu con bằng tên lấy từ backend.
///
/// Quy tắc: chỉ giữ menu con có xmlid trong [visible]; module chỉ hiện khi còn
/// ít nhất 1 menu con khả dụng. Giữ nguyên icon/màu/thứ tự từ cấu hình tĩnh.
List<AppModule> resolveModules({
  Set<String>? visible,
  Map<String, String>? names,
}) {
  if (visible == null) return kAppModules;
  final out = <AppModule>[];
  for (final m in kAppModules) {
    final kids = <AppSubMenu>[];
    for (final c in m.children) {
      // Menu cấp 3: giữ những menu con user được thấy. Menu cha (không có
      // action ở backend) chỉ hiện khi còn ít nhất 1 menu con khả dụng.
      final grand = c.children
          .where((g) => visible.contains(g.backendXmlId))
          .map((g) => g.copyWith(name: names?[g.backendXmlId]))
          .toList();
      if (c.children.isNotEmpty) {
        if (grand.isEmpty) continue;
        kids.add(c.copyWith(name: names?[c.backendXmlId], children: grand));
        continue;
      }
      if (!visible.contains(c.backendXmlId)) continue;
      kids.add(c.copyWith(name: names?[c.backendXmlId]));
    }
    if (kids.isEmpty) continue;
    out.add(m.copyWith(name: names?[m.backendXmlId], children: kids));
  }
  return out;
}
