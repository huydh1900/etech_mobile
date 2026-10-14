import '../utils/vn_format.dart';
// Model cho luồng "Hủy mẫu" (etech.sample.destruction).
// Map 1:1 với /api/destructions (list) và /api/destructions/<id> (detail).
//
// State header hủy mẫu: draft="Dự thảo", done="Đã hủy mẫu", cancel="Hủy bỏ".
// Dòng chi tiết (lines) là etech.retained.sample → state dùng enum lưu mẫu:
//   stored="Đang lưu", expired="Hết hạn lưu", destroyed="Đã hủy".

// Odoo trả `false` cho field rỗng -> coerce về ''. id an toàn với null/false.
String _s(Map<String, dynamic> j, String k) {
  final v = j[k];
  if (v == null || v == false) return '';
  return v.toString();
}

int _i(Map<String, dynamic> j, String k) {
  final v = j[k];
  return v is num ? v.toInt() : 0;
}

double _d(Map<String, dynamic> j, String k) {
  final v = j[k];
  return v is num ? v.toDouble() : 0.0;
}

class DestructionBrief {
  final int id;
  final String name;
  final String state;
  final String stateLabel;
  final String destructionDate; // date string
  final int sampleCount;
  final String destroyerName;

  DestructionBrief({
    required this.id,
    required this.name,
    required this.state,
    required this.stateLabel,
    required this.destructionDate,
    required this.sampleCount,
    required this.destroyerName,
  });

  factory DestructionBrief.fromJson(Map<String, dynamic> j) => DestructionBrief(
    id: _i(j, 'id'),
    name: _s(j, 'name'),
    state: _s(j, 'state'),
    stateLabel: _s(j, 'state_label'),
    destructionDate: formatVn(_s(j, 'destruction_date')),
    sampleCount: _i(j, 'sample_count'),
    destroyerName: _s(j, 'destroyer_name'),
  );
}

/// Dòng mẫu bị hủy — bản ghi etech.retained.sample.
class DestructionLine {
  final int id;
  final String codedSample;
  final String state; // enum lưu mẫu: stored/expired/destroyed
  final String stateLabel;
  final String partnerName;
  final int retainCount;
  final double retainWeight;
  final String expiryAt; // datetime string

  DestructionLine({
    required this.id,
    required this.codedSample,
    required this.state,
    required this.stateLabel,
    required this.partnerName,
    required this.retainCount,
    required this.retainWeight,
    required this.expiryAt,
  });

  factory DestructionLine.fromJson(Map<String, dynamic> j) => DestructionLine(
    id: _i(j, 'id'),
    codedSample: _s(j, 'coded_sample'),
    state: _s(j, 'state'),
    stateLabel: _s(j, 'state_label'),
    partnerName: _s(j, 'partner_name'),
    retainCount: _i(j, 'retain_count'),
    retainWeight: _d(j, 'retain_weight'),
    expiryAt: formatVn(_s(j, 'expiry_at')),
  );
}

class DestructionDetail {
  final int id;
  final String name;
  final String state;
  final String stateLabel;
  final String destructionDate;
  final int sampleCount;
  final String destroyerName;
  final String method;
  final String note;
  final String destroyedAt; // datetime string
  // Banner lý do hủy (chỉ có dữ liệu khi state == 'cancel').
  final String cancelBy;
  final String cancelReason;
  // Header meta (Tạo bởi / Cập nhật lần cuối) — giữ ISO raw, format ở screen.
  final String createdBy;
  final String createdAt;
  final String updatedBy;
  final String updatedAt;
  final List<DestructionLine> lines;

  DestructionDetail({
    required this.id,
    required this.name,
    required this.state,
    required this.stateLabel,
    required this.destructionDate,
    required this.sampleCount,
    required this.destroyerName,
    required this.method,
    required this.note,
    required this.destroyedAt,
    required this.cancelBy,
    required this.cancelReason,
    this.createdBy = '',
    this.createdAt = '',
    this.updatedBy = '',
    this.updatedAt = '',
    required this.lines,
  });

  factory DestructionDetail.fromJson(Map<String, dynamic> j) =>
      DestructionDetail(
        id: _i(j, 'id'),
        name: _s(j, 'name'),
        state: _s(j, 'state'),
        stateLabel: _s(j, 'state_label'),
        destructionDate: formatVn(_s(j, 'destruction_date')),
        sampleCount: _i(j, 'sample_count'),
        destroyerName: _s(j, 'destroyer_name'),
        method: _s(j, 'method'),
        note: _s(j, 'note'),
        destroyedAt: formatVn(_s(j, 'destroyed_at')),
        cancelBy: _s(j, 'cancel_by'),
        cancelReason: _s(j, 'cancel_reason'),
        createdBy: _s(j, 'created_by'),
        createdAt: _s(j, 'created_at'),
        updatedBy: _s(j, 'updated_by'),
        updatedAt: _s(j, 'updated_at'),
        lines: (j['lines'] is List ? j['lines'] as List : const [])
            .map((e) => DestructionLine.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
