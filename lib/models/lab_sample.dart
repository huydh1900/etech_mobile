import '../utils/vn_format.dart';
// Model cho luồng "Tiếp nhận mẫu / Chuẩn bị mẫu".
// Map 1:1 với /api/handovers/*, /api/preprocess_requests/*, /api/analysis_requests/*.

String _s(Map<String, dynamic> j, String k) => _sv(j[k]);
int _i(Map<String, dynamic> j, String k) => _iv(j[k]);
double _d(Map<String, dynamic> j, String k) => _dv(j[k]);
List<String> _strList(dynamic raw) => (raw is List ? raw : const [])
    .where((e) => e != null && e != false)
    .map((e) => e.toString())
    .where((s) => s.isNotEmpty)
    .toList();

// ───────────────────────── Phiếu bàn giao mẫu ─────────────────────────

// Odoo trả `false` cho field rỗng (char/m2o/date) -> coerce về ''/0,
// tránh render "false" và crash cast khi backend thiếu dữ liệu.
String _sv(Object? v) => (v == null || v == false) ? '' : v.toString();
int _iv(Object? v) => v is num ? v.toInt() : 0;
double _dv(Object? v) => v is num ? v.toDouble() : 0;

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

  HandoverBrief({
    required this.id,
    required this.code,
    required this.state,
    required this.stateLabel,
    required this.reportCode,
    required this.programCode,
    required this.requestCode,
    required this.partnerName,
    required this.sampleType,
    required this.sampleName,
  });

  factory HandoverBrief.fromJson(Map<String, dynamic> j) => HandoverBrief(
    id: _iv(j['id']),
    code: _s(j, 'code'),
    state: _s(j, 'state'),
    stateLabel: _s(j, 'state_label'),
    reportCode: _s(j, 'report_code'),
    programCode: _s(j, 'program_code'),
    requestCode: _s(j, 'request_code'),
    partnerName: _s(j, 'partner_name'),
    sampleType: _s(j, 'sample_type'),
    sampleName: _s(j, 'sample_name'),
  );
}

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
        id: _iv(j['id']),
        name: _s(j, 'name'),
        state: _s(j, 'state'),
      );
}

class HandoverDetail extends HandoverBrief {
  final List<HandoverPreprocessRef> preprocessRequests;

  HandoverDetail({
    required super.id,
    required super.code,
    required super.state,
    required super.stateLabel,
    required super.reportCode,
    required super.programCode,
    required super.requestCode,
    required super.partnerName,
    required super.sampleType,
    required super.sampleName,
    required this.preprocessRequests,
  });

  factory HandoverDetail.fromJson(Map<String, dynamic> j) => HandoverDetail(
    id: _iv(j['id']),
    code: _s(j, 'code'),
    state: _s(j, 'state'),
    stateLabel: _s(j, 'state_label'),
    reportCode: _s(j, 'report_code'),
    programCode: _s(j, 'program_code'),
    requestCode: _s(j, 'request_code'),
    partnerName: _s(j, 'partner_name'),
    sampleType: _s(j, 'sample_type'),
    sampleName: _s(j, 'sample_name'),
    preprocessRequests:
        (j['preprocess_requests'] is List
                ? j['preprocess_requests'] as List
                : const [])
            .map((e) => HandoverPreprocessRef.fromJson(e))
            .toList(),
  );
}

// ───────────────────────── Phiếu yêu cầu sơ chế ─────────────────────────

class PreprocessRequestBrief {
  final int id;
  final String name;
  final String state;
  final String stateLabel;
  final String partnerName;
  final String sampleType;
  final String sampleName;
  final String quantity;
  final String receivedAt;
  final String preprocessDoneAt;

  PreprocessRequestBrief({
    required this.id,
    required this.name,
    required this.state,
    required this.stateLabel,
    required this.partnerName,
    required this.sampleType,
    required this.sampleName,
    required this.quantity,
    required this.receivedAt,
    required this.preprocessDoneAt,
  });

  factory PreprocessRequestBrief.fromJson(Map<String, dynamic> j) =>
      PreprocessRequestBrief(
        id: _iv(j['id']),
        name: _s(j, 'name'),
        state: _s(j, 'state'),
        stateLabel: _s(j, 'state_label'),
        partnerName: _s(j, 'partner_name'),
        sampleType: _s(j, 'sample_type'),
        sampleName: _s(j, 'sample_name'),
        quantity: _s(j, 'quantity'),
        receivedAt: formatVn(_s(j, 'received_at')),
        preprocessDoneAt: formatVn(_s(j, 'preprocess_done_at')),
      );
}

class PreprocessRequestLine {
  final int id;
  final String codedSample;
  final String testParameter;
  final String preprocessPart;
  final String testMinWeight;
  final String testSampleCount;

  PreprocessRequestLine({
    required this.id,
    required this.codedSample,
    required this.testParameter,
    required this.preprocessPart,
    required this.testMinWeight,
    required this.testSampleCount,
  });

  factory PreprocessRequestLine.fromJson(Map<String, dynamic> j) =>
      PreprocessRequestLine(
        id: _iv(j['id']),
        codedSample: _s(j, 'coded_sample'),
        testParameter: _s(j, 'test_parameter'),
        preprocessPart: _s(j, 'preprocess_part'),
        testMinWeight: _s(j, 'test_min_weight'),
        testSampleCount: _s(j, 'test_sample_count'),
      );
}

class PreprocessRequestDetail extends PreprocessRequestBrief {
  final String requestCode;
  final String handoverName;
  final String sender;
  final String receiver;
  final String receiverUidName;
  final List<String> preprocessors;
  final String resultDueAt;
  final List<PreprocessRequestLine> lines;

  PreprocessRequestDetail({
    required super.id,
    required super.name,
    required super.state,
    required super.stateLabel,
    required super.partnerName,
    required super.sampleType,
    required super.sampleName,
    required super.quantity,
    required super.receivedAt,
    required super.preprocessDoneAt,
    required this.requestCode,
    required this.handoverName,
    required this.sender,
    required this.receiver,
    required this.receiverUidName,
    required this.preprocessors,
    required this.resultDueAt,
    required this.lines,
  });

  factory PreprocessRequestDetail.fromJson(Map<String, dynamic> j) =>
      PreprocessRequestDetail(
        id: _iv(j['id']),
        name: _s(j, 'name'),
        state: _s(j, 'state'),
        stateLabel: _s(j, 'state_label'),
        partnerName: _s(j, 'partner_name'),
        sampleType: _s(j, 'sample_type'),
        sampleName: _s(j, 'sample_name'),
        quantity: _s(j, 'quantity'),
        receivedAt: formatVn(_s(j, 'received_at')),
        preprocessDoneAt: formatVn(_s(j, 'preprocess_done_at')),
        requestCode: _s(j, 'request_code'),
        handoverName: _s(j, 'handover_name'),
        sender: _s(j, 'sender'),
        receiver: _s(j, 'receiver'),
        receiverUidName: _s(j, 'receiver_uid_name'),
        preprocessors: _strList(j['preprocessors']),
        resultDueAt: formatVn(_s(j, 'result_due_at')),
        lines: (j['lines'] is List ? j['lines'] as List : const [])
            .map((e) => PreprocessRequestLine.fromJson(e))
            .toList(),
      );
}

// ───────────────────────── Phiếu yêu cầu phân tích ─────────────────────────

class AnalysisRequestBrief {
  final int id;
  final String name;
  final String state;
  final String stateLabel;
  final String partnerName;
  final String sampleType;
  final String sampleName;
  final String receivedAt;
  final String analysisDoneAt;

  AnalysisRequestBrief({
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

  factory AnalysisRequestBrief.fromJson(Map<String, dynamic> j) =>
      AnalysisRequestBrief(
        id: _iv(j['id']),
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

class AnalysisRequestLine {
  final int id;
  final String codedSample;
  final String testParameter;
  final double testSampleWeight;
  final int testSampleCount;
  final double retainSampleWeight;

  AnalysisRequestLine({
    required this.id,
    required this.codedSample,
    required this.testParameter,
    required this.testSampleWeight,
    required this.testSampleCount,
    required this.retainSampleWeight,
  });

  factory AnalysisRequestLine.fromJson(Map<String, dynamic> j) =>
      AnalysisRequestLine(
        id: _iv(j['id']),
        codedSample: _s(j, 'coded_sample'),
        testParameter: _s(j, 'test_parameter'),
        testSampleWeight: _d(j, 'test_sample_weight'),
        testSampleCount: _i(j, 'test_sample_count'),
        retainSampleWeight: _d(j, 'retain_sample_weight'),
      );
}

class AnalysisRequestDetail extends AnalysisRequestBrief {
  final String preprocessRequestName;
  final String requestCode;
  final String samplePreservation;
  final String retentionDuration;
  final String resultDueAt;
  final List<AnalysisRequestLine> lines;

  AnalysisRequestDetail({
    required super.id,
    required super.name,
    required super.state,
    required super.stateLabel,
    required super.partnerName,
    required super.sampleType,
    required super.sampleName,
    required super.receivedAt,
    required super.analysisDoneAt,
    required this.preprocessRequestName,
    required this.requestCode,
    required this.samplePreservation,
    required this.retentionDuration,
    required this.resultDueAt,
    required this.lines,
  });

  factory AnalysisRequestDetail.fromJson(Map<String, dynamic> j) =>
      AnalysisRequestDetail(
        id: _iv(j['id']),
        name: _s(j, 'name'),
        state: _s(j, 'state'),
        stateLabel: _s(j, 'state_label'),
        partnerName: _s(j, 'partner_name'),
        sampleType: _s(j, 'sample_type'),
        sampleName: _s(j, 'sample_name'),
        receivedAt: formatVn(_s(j, 'received_at')),
        analysisDoneAt: formatVn(_s(j, 'analysis_done_at')),
        preprocessRequestName: _s(j, 'preprocess_request_name'),
        requestCode: _s(j, 'request_code'),
        samplePreservation: _s(j, 'sample_preservation'),
        retentionDuration: _s(j, 'retention_duration'),
        resultDueAt: formatVn(_s(j, 'result_due_at')),
        lines: (j['lines'] is List ? j['lines'] as List : const [])
            .map((e) => AnalysisRequestLine.fromJson(e))
            .toList(),
      );
}
