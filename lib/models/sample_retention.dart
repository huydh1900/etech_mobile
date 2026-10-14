import '../utils/vn_format.dart';
// Model cho luồng "Lưu mẫu + Biên bản hủy mẫu".
// Map 1:1 với /api/retained_samples/* và /api/destructions/*.

// Odoo trả `false` cho field rỗng (char/m2o/date) -> coerce về ''/0,
// tránh render "false" và crash cast khi backend thiếu dữ liệu.
String _sv(Object? v) => (v == null || v == false) ? '' : v.toString();
int _iv(Object? v) => v is num ? v.toInt() : 0;
double _dv(Object? v) => v is num ? v.toDouble() : 0;

class RetainedSampleBrief {
  final int id;
  final String codedSample;
  final String state;
  final String stateLabel;
  final String partnerName;
  final double retainWeight;
  final int retainCount;
  final String expiryAt;

  RetainedSampleBrief({
    required this.id,
    required this.codedSample,
    required this.state,
    required this.stateLabel,
    required this.partnerName,
    required this.retainWeight,
    required this.retainCount,
    required this.expiryAt,
  });

  static String _s(Map<String, dynamic> j, String k) => _sv(j[k]);

  factory RetainedSampleBrief.fromJson(Map<String, dynamic> j) =>
      RetainedSampleBrief(
        id: _iv(j['id']),
        codedSample: _s(j, 'coded_sample'),
        state: _s(j, 'state'),
        stateLabel: _s(j, 'state_label'),
        partnerName: _s(j, 'partner_name'),
        retainWeight: _dv(j['retain_weight']),
        retainCount: _iv(j['retain_count']),
        expiryAt: formatVn(_s(j, 'expiry_at')),
      );
}

class RetainedSampleDetail extends RetainedSampleBrief {
  final String analysisRequestName;
  final String serviceRequestCode;
  final String testReportCode;
  final String preservation;
  final String retentionPolicy;
  final String reportReturnedAt;
  final String destructionName;
  final String destructionDate;
  // Header meta (Tạo bởi / Cập nhật lần cuối) — giữ chuỗi ISO raw, format ở
  // screen bằng metaDt (kiểu "HH:mm dd thg M" như status banner Odoo).
  final String createdBy;
  final String createdAt;
  final String updatedBy;
  final String updatedAt;

  RetainedSampleDetail({
    required super.id,
    required super.codedSample,
    required super.state,
    required super.stateLabel,
    required super.partnerName,
    required super.retainWeight,
    required super.retainCount,
    required super.expiryAt,
    required this.analysisRequestName,
    required this.serviceRequestCode,
    required this.testReportCode,
    required this.preservation,
    required this.retentionPolicy,
    required this.reportReturnedAt,
    required this.destructionName,
    required this.destructionDate,
    this.createdBy = '',
    this.createdAt = '',
    this.updatedBy = '',
    this.updatedAt = '',
  });

  factory RetainedSampleDetail.fromJson(Map<String, dynamic> j) {
    String s(String k) => _sv(j[k]);
    return RetainedSampleDetail(
      id: _iv(j['id']),
      codedSample: s('coded_sample'),
      state: s('state'),
      stateLabel: s('state_label'),
      partnerName: s('partner_name'),
      retainWeight: _dv(j['retain_weight']),
      retainCount: _iv(j['retain_count']),
      expiryAt: formatVn(s('expiry_at')),
      analysisRequestName: s('analysis_request_name'),
      serviceRequestCode: s('service_request_code'),
      testReportCode: s('test_report_code'),
      preservation: s('preservation'),
      retentionPolicy: s('retention_policy'),
      reportReturnedAt: formatVn(s('report_returned_at')),
      destructionName: s('destruction_name'),
      destructionDate: formatVn(s('destruction_date')),
      createdBy: s('created_by'),
      createdAt: s('created_at'),
      updatedBy: s('updated_by'),
      updatedAt: s('updated_at'),
    );
  }
}

class DestructionBrief {
  final int id;
  final String name;
  final String state;
  final String stateLabel;
  final String destructionDate;
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

  static String _s(Map<String, dynamic> j, String k) => _sv(j[k]);

  factory DestructionBrief.fromJson(Map<String, dynamic> j) => DestructionBrief(
    id: _iv(j['id']),
    name: _s(j, 'name'),
    state: _s(j, 'state'),
    stateLabel: _s(j, 'state_label'),
    destructionDate: formatVn(_s(j, 'destruction_date')),
    sampleCount: _iv(j['sample_count']),
    destroyerName: _s(j, 'destroyer_name'),
  );
}

class DestructionLine {
  final int id;
  final String codedSample;
  final String state;
  final String stateLabel;
  final String partnerName;
  final int retainCount;
  final double retainWeight;
  final String expiryAt;

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
    id: _iv(j['id']),
    codedSample: _sv(j['coded_sample']),
    state: _sv(j['state']),
    stateLabel: _sv(j['state_label']),
    partnerName: _sv(j['partner_name']),
    retainCount: _iv(j['retain_count']),
    retainWeight: _dv(j['retain_weight']),
    expiryAt: formatVn(_sv(j['expiry_at'])),
  );
}

class DestructionDetail extends DestructionBrief {
  final String method;
  final String note;
  final String destroyedAt;
  final List<DestructionLine> lines;

  DestructionDetail({
    required super.id,
    required super.name,
    required super.state,
    required super.stateLabel,
    required super.destructionDate,
    required super.sampleCount,
    required super.destroyerName,
    required this.method,
    required this.note,
    required this.destroyedAt,
    required this.lines,
  });

  factory DestructionDetail.fromJson(Map<String, dynamic> j) {
    String s(String k) => _sv(j[k]);
    return DestructionDetail(
      id: _iv(j['id']),
      name: s('name'),
      state: s('state'),
      stateLabel: s('state_label'),
      destructionDate: formatVn(s('destruction_date')),
      sampleCount: _iv(j['sample_count']),
      destroyerName: s('destroyer_name'),
      method: s('method'),
      note: s('note'),
      destroyedAt: formatVn(s('destroyed_at')),
      lines: (j['lines'] is List ? j['lines'] as List : const [])
          .map((e) => DestructionLine.fromJson(e))
          .toList(),
    );
  }
}
