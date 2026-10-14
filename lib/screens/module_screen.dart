import 'package:flutter/material.dart';
import '../menu/app_modules.dart';
import '../theme/app_theme.dart';
import 'sampling_list_screen.dart';
import 'sampling_program_screens.dart';
import 'sampling_schedule_board.dart';
import 'service_request_screens.dart';
import 'customers_screens.dart';
import 'lab_sample_screens.dart';
import 'sample_retention_screens.dart';
// Module mới "Bàn giao mẫu" trùng tên HandoverListScreen với bản cũ trong
// lab_sample_screens.dart → dùng prefix để chỉ rõ bản mới.
import 'handovers_screens.dart' as handovers;
import 'lab_batches_screens.dart';
import 'preprocess_requests_screens.dart';
import 'analysis_requests_screens.dart';
import 'test_reports_screens.dart';
// Module mới "Hủy mẫu" có trùng tên DestructionListScreen với bản cũ trong
// sample_retention_screens.dart → dùng prefix để chỉ rõ bản mới.
import 'destructions_screens.dart' as destructions;

/// Router đồng bộ: map menu con backend → màn hình mobile thật.
/// Chưa có màn thật → trả [FeaturePlaceholderScreen] (giữ đồng bộ cấu trúc).
Widget resolveSubMenuScreen(AppSubMenu sub, String sessionId) {
  // Menu cha (có menu cấp 3 ở backend) → màn liệt kê menu con, không phải list.
  if (sub.children.isNotEmpty) {
    return SubMenuScreen(menu: sub, sessionId: sessionId);
  }
  switch (sub.backendXmlId) {
    case 'menu_etech_sampling_program': // Kế hoạch lấy mẫu
      return SamplingProgramListScreen(sessionId: sessionId);
    case 'menu_etech_sampling_program_my': // Kế hoạch lấy mẫu › Của tôi
      return SamplingProgramListScreen(
        sessionId: sessionId,
        title: 'Kế hoạch của tôi',
        scope: 'my',
      );
    case 'menu_etech_sampling_program_need_schedule': // › Cần lên lịch
      return SamplingScheduleBoardScreen(sessionId: sessionId);
    case 'menu_etech_sampling_report': // Biên bản hiện trường
      return SamplingListScreen(sessionId: sessionId);
    case 'menu_etech_service_request': // Phiếu yêu cầu
      return ServiceRequestListScreen(sessionId: sessionId);
    case 'menu_etech_customer': // Khách hàng (màn tham chiếu canonical)
      return CustomersListScreen(sessionId: sessionId);
    // ── Phiếu bàn giao mẫu (Hiện trường + Tiếp nhận) ──
    case 'menu_etech_sampling_handover':
    case 'menu_etech_reception_sampling_handover':
      return handovers.HandoverListScreen(sessionId: sessionId);
    // ── Yêu cầu sơ chế (Tiếp nhận + Chuẩn bị) ── (module mới, gating quyền)
    case 'menu_etech_reception_preprocess_request':
    case 'menu_etech_preparation_preprocess_request':
      return PreprocessRequestsListScreen(sessionId: sessionId);
    // ── Yêu cầu phân tích ── (Chuẩn bị: module mới Ar*; Phòng lab: bản cũ)
    case 'menu_etech_preparation_analysis_request':
      return ArListScreen(sessionId: sessionId);
    case 'menu_etech_analysis_request':
      return AnalysisRequestListScreen(sessionId: sessionId);
    case 'menu_etech_lab_batch': // Mẻ phân tích (module mới, gating quyền)
      return LabBatchesListScreen(sessionId: sessionId);
    case 'menu_etech_test_report': // Biên bản thử nghiệm (module mới)
      return TestReportsListScreen(sessionId: sessionId);
    case 'menu_etech_retained_sample': // Lưu mẫu
      return RetainedSampleListScreen(sessionId: sessionId);
    case 'menu_etech_sample_destruction': // Hủy mẫu (module mới, gating quyền)
      return destructions.DestructionListScreen(sessionId: sessionId);
    default:
      return FeaturePlaceholderScreen(title: sub.name);
  }
}

/// Màn cấp 2: liệt kê các menu con của một [AppModule].
/// Cấu trúc bám đúng cây menu backend (xem [kAppModules]).
class ModuleScreen extends StatelessWidget {
  final AppModule module;
  final String sessionId;

  const ModuleScreen({
    super.key,
    required this.module,
    required this.sessionId,
  });

  void _openSubMenu(BuildContext context, AppSubMenu sub) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => resolveSubMenuScreen(sub, sessionId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(module.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _ModuleHeader(module: module),
          const SizedBox(height: 18),
          Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'CHỨC NĂNG',
              style: TextStyle(
                fontSize: AppType.micro,
                fontWeight: FontWeight.w800,
                color: AppColors.inkMuted,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
              boxShadow: AppShadows.soft,
            ),
            child: Column(
              children: [
                for (var i = 0; i < module.children.length; i++) ...[
                  _SubMenuRow(
                    sub: module.children[i],
                    accent: module.gradient.first,
                    onTap: () => _openSubMenu(context, module.children[i]),
                  ),
                  if (i != module.children.length - 1)
                    Divider(
                      height: 1,
                      color: AppColors.divider,
                      indent: 58,
                      endIndent: 14,
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Màn cấp 3: liệt kê menu con của một [AppSubMenu] là menu cha ở backend
/// (vd "Kế hoạch lấy mẫu" → "Của tôi" / "Cần lên lịch").
class SubMenuScreen extends StatelessWidget {
  final AppSubMenu menu;
  final String sessionId;

  const SubMenuScreen({super.key, required this.menu, required this.sessionId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(menu.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
              boxShadow: AppShadows.soft,
            ),
            child: Column(
              children: [
                for (var i = 0; i < menu.children.length; i++) ...[
                  _SubMenuRow(
                    sub: menu.children[i],
                    accent: AppColors.primary,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            resolveSubMenuScreen(menu.children[i], sessionId),
                      ),
                    ),
                  ),
                  if (i != menu.children.length - 1)
                    Divider(
                      height: 1,
                      color: AppColors.divider,
                      indent: 58,
                      endIndent: 14,
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleHeader extends StatelessWidget {
  final AppModule module;
  const _ModuleHeader({required this.module});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppGradients.tile(
          module.gradient.first,
          module.gradient.last,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.lifted,
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
            ),
            child: Icon(module.icon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  module.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: AppType.title,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  module.description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: AppType.caption,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubMenuRow extends StatelessWidget {
  final AppSubMenu sub;
  final Color accent;
  final VoidCallback onTap;

  const _SubMenuRow({
    required this.sub,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(sub.icon, color: accent, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  sub.name,
                  style: TextStyle(
                    fontSize: AppType.bodyLg,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ),
              if (!sub.implemented)
                Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: StatusPill(
                    label: 'Sắp có',
                    color: AppColors.inkMuted,
                    background: AppColors.divider,
                  ),
                ),
              Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Màn placeholder cho chức năng chưa dựng UI mobile (giữ đồng bộ cấu trúc).
class FeaturePlaceholderScreen extends StatelessWidget {
  final String title;
  const FeaturePlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.infoSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.construction_rounded,
                  color: AppColors.primary,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppType.title,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Chức năng này đang được phát triển trên ứng dụng di động.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppType.body,
                  color: AppColors.inkSoft,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
