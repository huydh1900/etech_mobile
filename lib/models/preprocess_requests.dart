import '../utils/vn_format.dart';
// Model cho luồng "Yêu cầu xử lý mẫu" (etech.preprocess.request).
// Map 1:1 với /api/preprocess_requests (list) và /api/preprocess_requests/<id> (detail).

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

class PreprocessRequestBrief {
  final int id;
  final String name;
  final String state;
  final String stateLabel;
  final String partnerName;
  final String sampleType;
  final String sampleName;
  final String quantity; // "" nếu rỗng
  final String receivedAt; // datetime string
  final String preprocessDoneAt; // datetime string

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
        id: _i(j, 'id'),
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
  final String codedSuffix; // hậu tố mã hóa (01/02/03)
  final String testParameter;
  final List<String> testMethods; // many2many display_name
  final String preprocessPart; // selection label
  final String preprocessPartOther; // text "Khác"
  final String testMinWeight; // selection label (mẫu thử nghiệm)
  final String testSampleCount; // selection label (mẫu thử nghiệm)
  final String retainMinWeight; // selection label (mẫu lưu)
  final String retainSampleCount; // selection label (mẫu lưu)

  PreprocessRequestLine({
    required this.id,
    required this.codedSample,
    required this.codedSuffix,
    required this.testParameter,
    required this.testMethods,
    required this.preprocessPart,
    required this.preprocessPartOther,
    required this.testMinWeight,
    required this.testSampleCount,
    required this.retainMinWeight,
    required this.retainSampleCount,
  });

  factory PreprocessRequestLine.fromJson(Map<String, dynamic> j) =>
      PreprocessRequestLine(
        id: _i(j, 'id'),
        codedSample: _s(j, 'coded_sample'),
        codedSuffix: _s(j, 'coded_suffix'),
        testParameter: _s(j, 'test_parameter'),
        testMethods: PreprocessRequestDetail._strList(j, 'test_methods'),
        preprocessPart: _s(j, 'preprocess_part'),
        preprocessPartOther: _s(j, 'preprocess_part_other'),
        testMinWeight: _s(j, 'test_min_weight'),
        testSampleCount: _s(j, 'test_sample_count'),
        retainMinWeight: _s(j, 'retain_min_weight'),
        retainSampleCount: _s(j, 'retain_sample_count'),
      );
}

class PreprocessRequestDetail {
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
  // header meta (Tạo bởi / Cập nhật lần cuối)
  final String createdBy;
  final String createdAt;
  final String updatedBy;
  final String updatedAt;
  // detail-only
  final String requestCode;
  final String handoverName;
  final String sender;
  final String receiver;
  final String receiverUidName;
  final List<String> preprocessors;
  final String excessHandling; // selection label "Xử lý khối lượng mẫu dư"
  final String resultDueAt;
  final String senderSignerName;
  final String receiverSignerName;
  final List<PreprocessRequestLine> lines;

  PreprocessRequestDetail({
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
    this.createdBy = '',
    this.createdAt = '',
    this.updatedBy = '',
    this.updatedAt = '',
    this.requestCode = '',
    required this.handoverName,
    required this.sender,
    required this.receiver,
    required this.receiverUidName,
    required this.preprocessors,
    required this.excessHandling,
    required this.resultDueAt,
    this.senderSignerName = '',
    this.receiverSignerName = '',
    required this.lines,
  });

  static List<String> _strList(
    Map<String, dynamic> j,
    String k,
  ) => (j[k] is List ? j[k] as List : const [])
      // Odoo có thể chèn `false` cho phần tử rỗng -> bỏ qua, không in "false".
      .where((e) => e != null && e != false)
      .map((e) => e.toString())
      .where((s) => s.isNotEmpty)
      .toList();

  factory PreprocessRequestDetail.fromJson(Map<String, dynamic> j) =>
      PreprocessRequestDetail(
        id: _i(j, 'id'),
        name: _s(j, 'name'),
        state: _s(j, 'state'),
        stateLabel: _s(j, 'state_label'),
        partnerName: _s(j, 'partner_name'),
        sampleType: _s(j, 'sample_type'),
        sampleName: _s(j, 'sample_name'),
        quantity: _s(j, 'quantity'),
        receivedAt: formatVn(_s(j, 'received_at')),
        preprocessDoneAt: formatVn(_s(j, 'preprocess_done_at')),
        createdBy: _s(j, 'created_by'),
        createdAt: _s(j, 'created_at'),
        updatedBy: _s(j, 'updated_by'),
        updatedAt: _s(j, 'updated_at'),
        requestCode: _s(j, 'request_code'),
        handoverName: _s(j, 'handover_name'),
        sender: _s(j, 'sender'),
        receiver: _s(j, 'receiver'),
        receiverUidName: _s(j, 'receiver_uid_name'),
        preprocessors: _strList(j, 'preprocessors'),
        excessHandling: _s(j, 'excess_handling'),
        resultDueAt: formatVn(_s(j, 'result_due_at')),
        senderSignerName: _s(j, 'sender_signer_name'),
        receiverSignerName: _s(j, 'receiver_signer_name'),
        lines: (j['lines'] is List ? j['lines'] as List : const [])
            .map(
              (e) => PreprocessRequestLine.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
      );
}
