import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Chip trạng thái dùng chung cho mọi màn list/detail. Bao quanh [StatusPill]
/// nhưng tự suy màu nền/viền từ 1 màu base, để feature agent chỉ cần truyền
/// label + màu (thường lấy từ [statusColorFor]).
///
/// Convention màu trạng thái tập trung tại [statusColorFor] để các module không
/// tự chế switch màu rải rác.
class StatusChip extends StatelessWidget {
  final String label;

  /// Màu chủ đạo (chữ + viền). Nền = base nhạt 12%.
  final Color color;
  final IconData? icon;

  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  /// Tạo chip trực tiếp từ mã state nghiệp vụ (dùng [statusColorFor]).
  factory StatusChip.fromState({
    Key? key,
    required String state,
    required String label,
    IconData? icon,
  }) => StatusChip(
    key: key,
    label: label,
    color: statusColorFor(state),
    icon: icon,
  );

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return const SizedBox.shrink();
    // Nền = base trộn lên surface (không dùng alpha trong suốt) để màu ổn định
    // và đủ tương phản với chữ ở cả light lẫn dark — alpha trong suốt trước đây
    // khiến chip "Dự thảo" (xám) gần như chìm vào nền tối.
    return StatusPill(
      label: label,
      color: color,
      background: Color.alphaBlend(
        color.withValues(alpha: 0.16),
        AppColors.surface,
      ),
      icon: icon,
    );
  }
}

/// Bảng màu trạng thái canonical cho toàn app — feature agent map state nghiệp
/// vụ của mình về 1 trong các nhóm dưới đây thay vì tự định nghĩa màu.
///
/// Quy ước nhóm:
/// - hoàn tất/duyệt/sẵn sàng → success
/// - đang xử lý/đã gửi/chờ   → warning
/// - nháp/mới                → inkMuted
/// - từ chối/huỷ/lỗi         → danger
/// - còn lại (đang chạy)     → primary
Color statusColorFor(String state) {
  switch (state) {
    // success
    case 'done':
    case 'approved':
    case 'validated':
    case 'confirmed':
    case 'ready':
    case 'ready_for_job':
    case 'completed':
    case 'received':
    case 'finished':
      return AppColors.success;
    // warning
    case 'submitted':
    case 'pending':
    case 'waiting':
    case 'in_progress':
    case 'progress':
    case 'processing':
    case 'to_approve':
      return AppColors.warning;
    // draft / new → muted
    case 'draft':
    case 'new':
      return AppColors.inkMuted;
    // danger
    case 'rejected':
    case 'cancel':
    case 'cancelled':
    case 'canceled':
    case 'refused':
    case 'destroyed':
    case 'error':
      return AppColors.danger;
    default:
      return AppColors.primary;
  }
}
