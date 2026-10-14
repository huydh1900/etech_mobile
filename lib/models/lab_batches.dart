// Model cho module "Mẻ phân tích" (etech.lab.batch).
// Map 1:1 với /api/lab_batches (list) và /api/lab_batches/<id> (detail).
//
// Đặt tên prefix `LabBatches*` để tách bạch với module lab_test hiện có
// (LabBatch*). Mọi field số/chuỗi đều coerce theo convention chung:
//   _s(j,k) -> '' nếu thiếu; (j[k] as num?)?.toInt()/.toDouble() -> 0.

String _s(Map<String, dynamic> j, String k) {
  final v = j[k];
  if (v == null || v == false) return '';
  return v.toString();
}

int _i(Map<String, dynamic> j, String k) {
  final v = j[k];
  return v is num ? v.toInt() : 0;
}

double _f(Map<String, dynamic> j, String k) {
  final v = j[k];
  return v is num ? v.toDouble() : 0.0;
}

/// Mẫu con (lặp/thêm chuẩn) thuộc 1 dòng mẫu thật (sub_line_ids).
class LabBatchesSubLine {
  final int id;
  final String codedSample;
  final String sampleType; // selection label
  final double weightG;

  LabBatchesSubLine({
    required this.id,
    required this.codedSample,
    required this.sampleType,
    required this.weightG,
  });

  factory LabBatchesSubLine.fromJson(Map<String, dynamic> j) =>
      LabBatchesSubLine(
        id: _i(j, 'id'),
        codedSample: _s(j, 'coded_sample'),
        sampleType: _s(j, 'sample_type'),
        weightG: _f(j, 'weight_g'),
      );
}

/// Một dòng mẫu trong mẻ (line_ids).
class LabBatchesLine {
  final int id;
  final int sequence;
  final String codedSample;
  final String sampleType; // selection label (không có raw value)
  final String parameterName;
  final String methodName;
  final int numDuplicate;
  final int numSpike;
  final double weightG;
  final String result;
  final List<LabBatchesSubLine> subLines;

  LabBatchesLine({
    required this.id,
    required this.sequence,
    required this.codedSample,
    required this.sampleType,
    required this.parameterName,
    required this.methodName,
    required this.numDuplicate,
    required this.numSpike,
    required this.weightG,
    required this.result,
    required this.subLines,
  });

  factory LabBatchesLine.fromJson(Map<String, dynamic> j) => LabBatchesLine(
    id: _i(j, 'id'),
    sequence: _i(j, 'sequence'),
    codedSample: _s(j, 'coded_sample'),
    sampleType: _s(j, 'sample_type'),
    parameterName: _s(j, 'parameter_name'),
    methodName: _s(j, 'method_name'),
    numDuplicate: _i(j, 'num_duplicate'),
    numSpike: _i(j, 'num_spike'),
    weightG: _f(j, 'weight_g'),
    result: _s(j, 'result'),
    subLines: (j['sub_line_ids'] is List ? j['sub_line_ids'] as List : const [])
        .map((e) => LabBatchesSubLine.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

/// Biên bản thử nghiệm liên quan tới mẻ (test_record_ids).
class LabBatchesTestRecord {
  final int id;
  final String name;
  final String state;
  final String stateLabel;
  final String metal; // hardcoded "Cd" từ backend

  LabBatchesTestRecord({
    required this.id,
    required this.name,
    required this.state,
    required this.stateLabel,
    required this.metal,
  });

  factory LabBatchesTestRecord.fromJson(Map<String, dynamic> j) =>
      LabBatchesTestRecord(
        id: _i(j, 'id'),
        name: _s(j, 'name'),
        state: _s(j, 'state'),
        stateLabel: _s(j, 'state_label'),
        metal: _s(j, 'metal'),
      );
}

/// Bản tóm tắt cho danh sách.
class LabBatchesBrief {
  final int id;
  final String name;
  final String state;
  final String stateLabel;
  final String analysisDateStart; // datetime as string
  final String methodName;
  final String
  methodCode; // dùng để chọn nhãn QC (TP-01 → "Thêm chuẩn +5 µg/kg")
  final int sampleCount;
  final int requestCount;

  LabBatchesBrief({
    required this.id,
    required this.name,
    required this.state,
    required this.stateLabel,
    required this.analysisDateStart,
    required this.methodName,
    required this.methodCode,
    required this.sampleCount,
    required this.requestCount,
  });

  factory LabBatchesBrief.fromJson(Map<String, dynamic> j) => LabBatchesBrief(
    id: _i(j, 'id'),
    name: _s(j, 'name'),
    state: _s(j, 'state'),
    stateLabel: _s(j, 'state_label'),
    analysisDateStart: _s(j, 'analysis_date_start'),
    methodName: _s(j, 'method_name'),
    methodCode: _s(j, 'method_code'),
    sampleCount: _i(j, 'sample_count'),
    requestCount: _i(j, 'request_count'),
  );
}

/// Chi tiết mẻ phân tích (kế thừa Brief + field bổ sung).
class LabBatchesDetail extends LabBatchesBrief {
  final int numBlank;
  final int numQc;
  final bool weighingDone;
  final int testRecordCount;
  final String cancelUidName;
  final String cancelReason;
  // Header meta (Tạo bởi / Cập nhật lần cuối) — khớp formview Odoo.
  final String createdBy;
  final String createdAt;
  final String updatedBy;
  final String updatedAt;
  final List<LabBatchesLine> lines;
  final List<LabBatchesTestRecord> testRecords;

  LabBatchesDetail({
    required super.id,
    required super.name,
    required super.state,
    required super.stateLabel,
    required super.analysisDateStart,
    required super.methodName,
    required super.methodCode,
    required super.sampleCount,
    required super.requestCount,
    required this.numBlank,
    required this.numQc,
    required this.weighingDone,
    required this.testRecordCount,
    required this.cancelUidName,
    required this.cancelReason,
    this.createdBy = '',
    this.createdAt = '',
    this.updatedBy = '',
    this.updatedAt = '',
    required this.lines,
    required this.testRecords,
  });

  factory LabBatchesDetail.fromJson(Map<String, dynamic> j) => LabBatchesDetail(
    id: _i(j, 'id'),
    name: _s(j, 'name'),
    state: _s(j, 'state'),
    stateLabel: _s(j, 'state_label'),
    analysisDateStart: _s(j, 'analysis_date_start'),
    methodName: _s(j, 'method_name'),
    methodCode: _s(j, 'method_code'),
    sampleCount: _i(j, 'sample_count'),
    requestCount: _i(j, 'request_count'),
    numBlank: _i(j, 'num_blank'),
    numQc: _i(j, 'num_qc'),
    weighingDone: j['weighing_done'] == true,
    testRecordCount: _i(j, 'test_record_count'),
    cancelUidName: _s(j, 'cancel_uid_name'),
    cancelReason: _s(j, 'cancel_reason'),
    createdBy: _s(j, 'created_by'),
    createdAt: _s(j, 'created_at'),
    updatedBy: _s(j, 'updated_by'),
    updatedAt: _s(j, 'updated_at'),
    lines: (j['line_ids'] is List ? j['line_ids'] as List : const [])
        .map((e) => LabBatchesLine.fromJson(e as Map<String, dynamic>))
        .toList(),
    testRecords:
        (j['test_record_ids'] is List ? j['test_record_ids'] as List : const [])
            .map(
              (e) => LabBatchesTestRecord.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
  );
}
