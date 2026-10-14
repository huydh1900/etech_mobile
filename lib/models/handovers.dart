import '../utils/vn_format.dart';
// Model cho luồng "Bàn giao mẫu" — etech.sampling.handover.
// Map 1:1 với /api/handovers (list) và /api/handovers/<id> (detail).
//
// STATE ENUM: draft="Dự thảo", handed="Đã bàn giao", received="Đã tiếp nhận",
// returned="Trả lại mẫu", cancel="Hủy".

// Odoo trả `false` cho field rỗng (char/many2one/date...) -> coerce về ''.
// id phải an toàn với null/false để tránh crash khi backend thiếu dữ liệu.
String _s(Map<String, dynamic> j, String k) {
  final v = j[k];
  if (v == null || v == false) return '';
  return v.toString();
}

int _i(Map<String, dynamic> j, String k) {
  final v = j[k];
  return v is num ? v.toInt() : 0;
}

// many2many -> list tên; bỏ phần tử rỗng/false Odoo có thể chèn.
List<String> _strList(Map<String, dynamic> j, String k) =>
    (j[k] is List ? j[k] as List : const [])
        .where((e) => e != null && e != false)
        .map((e) => e.toString())
        .where((s) => s.isNotEmpty)
        .toList();

class HandoverBrief {
  final int id;
  final String code;
  final String state;
  final String stateLabel;
  final String reportCode;
  final String programCode;
  final String requestCode;
  final String partnerName;
  final String sampleType;
  final String sampleName;
  // Raw ISO yyyy-MM-dd (khoá nhóm) — formatVn() tại điểm hiển thị.
  final String receiveDate;
  final String completionDate;
  final String slaState;
  final String slaStateLabel;

  HandoverBrief({
    required this.id,
    required this.code,
    required this.state,
    required this.stateLabel,
    required this.reportCode,
    required this.programCode,
    this.requestCode = '',
    required this.partnerName,
    required this.sampleType,
    required this.sampleName,
    this.receiveDate = '',
    this.completionDate = '',
    this.slaState = '',
    this.slaStateLabel = '',
  });

  factory HandoverBrief.fromJson(Map<String, dynamic> j) => HandoverBrief(
    id: _i(j, 'id'),
    code: _s(j, 'code'),
    state: _s(j, 'state'),
    stateLabel: _s(j, 'state_label'),
    reportCode: _s(j, 'report_code'),
    programCode: _s(j, 'program_code'),
    requestCode: _s(j, 'request_code'),
    partnerName: _s(j, 'partner_name'),
    sampleType: _s(j, 'sample_type'),
    sampleName: _s(j, 'sample_name'),
    receiveDate: _s(j, 'receive_date'),
    completionDate: _s(j, 'completion_date'),
    slaState: _s(j, 'sla_state'),
    slaStateLabel: _s(j, 'sla_state_label'),
  );
}

/// Một dòng yêu cầu sơ chế tham chiếu trong chi tiết bàn giao.
class HandoverPreprocessRef {
  final int id;
  final String name;
  final String state;

  HandoverPreprocessRef({
    required this.id,
    required this.name,
    required this.state,
  });

  factory HandoverPreprocessRef.fromJson(Map<String, dynamic> j) =>
      HandoverPreprocessRef(
        id: _i(j, 'id'),
        name: _s(j, 'name'),
        state: _s(j, 'state'),
      );
}

/// Một dòng mẫu (section II "Thông tin mẫu") của phiếu bàn giao.
class HandoverLine {
  final int id;
  final String originalCode;
  final List<String> parameters; // chỉ tiêu (m2m tag)
  final String sealStampNo;
  final String evalSampleStatus; // selection label
  final String evalPacking; // char
  final int sampleWeight;
  final String packingUnit; // selection label
  final String evalStorage; // selection label
  final String recvStatusResult; // Đạt/Không đạt
  final String recvPackingResult;
  final String recvWeightResult;
  final String recvStorageResult;
  final bool attachedSamplingRecord;
  final bool attachedHandoverSlip;
  final String conclusion; // selection label

  HandoverLine({
    required this.id,
    required this.originalCode,
    required this.parameters,
    required this.sealStampNo,
    required this.evalSampleStatus,
    required this.evalPacking,
    required this.sampleWeight,
    required this.packingUnit,
    required this.evalStorage,
    required this.recvStatusResult,
    required this.recvPackingResult,
    required this.recvWeightResult,
    required this.recvStorageResult,
    required this.attachedSamplingRecord,
    required this.attachedHandoverSlip,
    required this.conclusion,
  });

  factory HandoverLine.fromJson(Map<String, dynamic> j) => HandoverLine(
    id: _i(j, 'id'),
    originalCode: _s(j, 'original_code'),
    parameters: _strList(j, 'parameters'),
    sealStampNo: _s(j, 'seal_stamp_no'),
    evalSampleStatus: _s(j, 'eval_sample_status'),
    evalPacking: _s(j, 'eval_packing'),
    sampleWeight: _i(j, 'sample_weight'),
    packingUnit: _s(j, 'packing_unit'),
    evalStorage: _s(j, 'eval_storage'),
    recvStatusResult: _s(j, 'recv_status_result'),
    recvPackingResult: _s(j, 'recv_packing_result'),
    recvWeightResult: _s(j, 'recv_weight_result'),
    recvStorageResult: _s(j, 'recv_storage_result'),
    attachedSamplingRecord: j['attached_sampling_record'] == true,
    attachedHandoverSlip: j['attached_handover_slip'] == true,
    conclusion: _s(j, 'conclusion'),
  );
}

class HandoverDetail {
  final int id;
  final String code;
  final String state;
  final String stateLabel;
  final String reportCode;
  final String programCode;
  final String requestCode;
  final String partnerName;
  final String sampleType;
  final String sampleName;

  /// Header meta (Tạo bởi / Cập nhật lần cuối) — khớp formview Odoo.
  final String createdBy;
  final String createdAt;
  final String updatedBy;
  final String updatedAt;

  /// Bên gửi mẫu (phòng/bộ phận).
  final String senderDept;

  /// Hình thức gửi mẫu (field selection/radio): raw value + nhãn hiển thị.
  final String sendMethod;
  final String sendMethodLabel;

  /// Nhãn tất cả lựa chọn `send_method` (để vẽ radio đủ ô như Odoo).
  final List<String> sendMethodOptions;

  /// Mã vận đơn (chỉ có khi gửi qua đơn vị vận chuyển).
  final String trackingNo;
  final int sampleCount;

  /// Các mốc thời gian đã định dạng sẵn ở backend.
  final String samplingCompletionLabel;
  final String resultDueDate;
  final String receiveDatetimeLabel;

  /// Họ tên người ký (chữ ký bên gửi / bên nhận).
  final String senderSignerName;
  final String receiverSignerName;

  /// Dòng mẫu (section II). Số ảnh khi nhận mẫu (section III).
  final List<HandoverLine> lines;
  final int receptionImageCount;
  final List<HandoverPreprocessRef> preprocessRequests;

  HandoverDetail({
    required this.id,
    required this.code,
    required this.state,
    required this.stateLabel,
    required this.reportCode,
    required this.programCode,
    this.requestCode = '',
    required this.partnerName,
    required this.sampleType,
    required this.sampleName,
    this.createdBy = '',
    this.createdAt = '',
    this.updatedBy = '',
    this.updatedAt = '',
    required this.senderDept,
    required this.sendMethod,
    required this.sendMethodLabel,
    this.sendMethodOptions = const [],
    required this.trackingNo,
    required this.sampleCount,
    required this.samplingCompletionLabel,
    required this.resultDueDate,
    required this.receiveDatetimeLabel,
    this.senderSignerName = '',
    this.receiverSignerName = '',
    required this.lines,
    required this.receptionImageCount,
    required this.preprocessRequests,
  });

  factory HandoverDetail.fromJson(Map<String, dynamic> j) => HandoverDetail(
    id: _i(j, 'id'),
    code: _s(j, 'code'),
    state: _s(j, 'state'),
    stateLabel: _s(j, 'state_label'),
    reportCode: _s(j, 'report_code'),
    programCode: _s(j, 'program_code'),
    requestCode: _s(j, 'request_code'),
    partnerName: _s(j, 'partner_name'),
    sampleType: _s(j, 'sample_type'),
    sampleName: _s(j, 'sample_name'),
    createdBy: _s(j, 'created_by'),
    createdAt: _s(j, 'created_at'),
    updatedBy: _s(j, 'updated_by'),
    updatedAt: _s(j, 'updated_at'),
    senderDept: _s(j, 'sender_dept'),
    sendMethod: _s(j, 'send_method'),
    sendMethodLabel: _s(j, 'send_method_label'),
    sendMethodOptions: (j['send_method_options'] is List)
        ? (j['send_method_options'] as List)
              .map((e) => e is Map ? (e['label'] ?? '').toString() : '$e')
              .where((e) => e.isNotEmpty)
              .toList()
        : const [],
    trackingNo: _s(j, 'tracking_no'),
    sampleCount: _i(j, 'sample_count'),
    samplingCompletionLabel: _s(j, 'sampling_completion_label'),
    resultDueDate: formatVn(_s(j, 'result_due_date')),
    receiveDatetimeLabel: _s(j, 'receive_datetime_label'),
    senderSignerName: _s(j, 'sender_signer_name'),
    receiverSignerName: _s(j, 'receiver_signer_name'),
    lines: (j['lines'] is List ? j['lines'] as List : const [])
        .map((e) => HandoverLine.fromJson(e as Map<String, dynamic>))
        .toList(),
    receptionImageCount: _i(j, 'reception_image_count'),
    preprocessRequests:
        (j['preprocess_requests'] is List
                ? j['preprocess_requests'] as List
                : const [])
            .map(
              (e) => HandoverPreprocessRef.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
  );
}
