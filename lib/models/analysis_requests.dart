import '../utils/vn_format.dart';
// Model cho luồng "Yêu cầu phân tích" (etech.analysis.request).
// Map 1:1 với /api/analysis_requests (list) và /api/analysis_requests/<id> (detail).
//
// Lưu ý: dùng tiền tố `Ar*` để tránh trùng tên với AnalysisRequestBrief/Detail
// đang tồn tại ở models/lab_sample.dart (cùng nghiệp vụ, khác màn dùng).

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

// many2many -> list tên; bỏ phần tử rỗng/false Odoo có thể chèn.
List<String> _strList(Map<String, dynamic> j, String k) =>
    (j[k] is List ? j[k] as List : const [])
        .where((e) => e != null && e != false)
        .map((e) => e.toString())
        .where((s) => s.isNotEmpty)
        .toList();

class ArBrief {
  final int id;
  final String name;
  final String state;
  final String stateLabel;
  final String partnerName;
  final String sampleType;
  final String sampleName;
  final String receivedAt; // datetime string
  final String analysisDoneAt; // datetime string

  ArBrief({
    required this.id,
    required this.name,
    required this.state,
    required this.stateLabel,
    required this.partnerName,
    required this.sampleType,
    required this.sampleName,
    required this.receivedAt,
    required this.analysisDoneAt,
  });

  factory ArBrief.fromJson(Map<String, dynamic> j) => ArBrief(
    id: _i(j, 'id'),
    name: _s(j, 'name'),
    state: _s(j, 'state'),
    stateLabel: _s(j, 'state_label'),
    partnerName: _s(j, 'partner_name'),
    sampleType: _s(j, 'sample_type'),
    sampleName: _s(j, 'sample_name'),
    receivedAt: formatVn(_s(j, 'received_at')),
    analysisDoneAt: formatVn(_s(j, 'analysis_done_at')),
  );
}

class ArLine {
  final int id;
  final String codedSample;
  final String testParameter;
  final List<String> testMethods; // many2many display_name
  final double testSampleWeight;
  final int testSampleCount;
  final double retainSampleWeight;
  final int retainSampleCount;

  ArLine({
    required this.id,
    required this.codedSample,
    required this.testParameter,
    required this.testMethods,
    required this.testSampleWeight,
    required this.testSampleCount,
    required this.retainSampleWeight,
    required this.retainSampleCount,
  });

  factory ArLine.fromJson(Map<String, dynamic> j) => ArLine(
    id: _i(j, 'id'),
    codedSample: _s(j, 'coded_sample'),
    testParameter: _s(j, 'test_parameter'),
    testMethods: _strList(j, 'test_methods'),
    testSampleWeight: _d(j, 'test_sample_weight'),
    testSampleCount: _i(j, 'test_sample_count'),
    retainSampleWeight: _d(j, 'retain_sample_weight'),
    retainSampleCount: _i(j, 'retain_sample_count'),
  );
}

class ArDetail extends ArBrief {
  final String sender;
  final String receiver;
  final String preprocessRequestName;
  final String requestCode;
  final String samplePreservation; // selection label
  final String retentionDuration;
  final String preprocessDoneAt; // datetime string
  final String resultDueAt; // datetime string
  // header meta (Tạo bởi / Cập nhật lần cuối)
  final String createdBy;
  final String createdAt;
  final String updatedBy;
  final String updatedAt;
  final String senderSignerName;
  final String receiverSignerName;
  final List<ArLine> lines;

  ArDetail({
    required super.id,
    required super.name,
    required super.state,
    required super.stateLabel,
    required super.partnerName,
    required super.sampleType,
    required super.sampleName,
    required super.receivedAt,
    required super.analysisDoneAt,
    required this.sender,
    required this.receiver,
    required this.preprocessRequestName,
    this.requestCode = '',
    required this.samplePreservation,
    required this.retentionDuration,
    required this.preprocessDoneAt,
    required this.resultDueAt,
    this.createdBy = '',
    this.createdAt = '',
    this.updatedBy = '',
    this.updatedAt = '',
    this.senderSignerName = '',
    this.receiverSignerName = '',
    required this.lines,
  });

  factory ArDetail.fromJson(Map<String, dynamic> j) => ArDetail(
    id: _i(j, 'id'),
    name: _s(j, 'name'),
    state: _s(j, 'state'),
    stateLabel: _s(j, 'state_label'),
    partnerName: _s(j, 'partner_name'),
    sampleType: _s(j, 'sample_type'),
    sampleName: _s(j, 'sample_name'),
    receivedAt: formatVn(_s(j, 'received_at')),
    analysisDoneAt: formatVn(_s(j, 'analysis_done_at')),
    sender: _s(j, 'sender'),
    receiver: _s(j, 'receiver'),
    preprocessRequestName: _s(j, 'preprocess_request_name'),
    requestCode: _s(j, 'request_code'),
    samplePreservation: _s(j, 'sample_preservation'),
    retentionDuration: _s(j, 'retention_duration'),
    preprocessDoneAt: formatVn(_s(j, 'preprocess_done_at')),
    resultDueAt: formatVn(_s(j, 'result_due_at')),
    createdBy: _s(j, 'created_by'),
    createdAt: _s(j, 'created_at'),
    updatedBy: _s(j, 'updated_by'),
    updatedAt: _s(j, 'updated_at'),
    senderSignerName: _s(j, 'sender_signer_name'),
    receiverSignerName: _s(j, 'receiver_signer_name'),
    lines: (j['lines'] is List ? j['lines'] as List : const [])
        .map((e) => ArLine.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
