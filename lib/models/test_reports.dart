import '../utils/vn_format.dart';
// Model cho luồng "Biên bản thử nghiệm" (etech.test.report).
// Map 1:1 với /api/test_reports (list) và /api/test_reports/<id> (detail).
//
// Quy ước: mọi field string dùng _s() (Odoo coerce False -> ""); số dùng
// (j[k] as num?)?.toInt()/toDouble() ?? 0; bool là JSON bool thật.

double _d(Map<String, dynamic> j, String k) {
  final v = j[k];
  return v is num ? v.toDouble() : 0.0;
}

int _i(Map<String, dynamic> j, String k) {
  final v = j[k];
  return v is num ? v.toInt() : 0;
}

String _s(Map<String, dynamic> j, String k) {
  final v = j[k];
  if (v == null || v == false) return '';
  return v.toString();
}

class TestReportBrief {
  final int id;
  final String code;
  final String codeInternal;
  final String state;
  final String stateLabel;
  final String partnerName;
  final String sampleName;
  final String reportDate;
  final bool isValid;

  TestReportBrief({
    required this.id,
    required this.code,
    required this.codeInternal,
    required this.state,
    required this.stateLabel,
    required this.partnerName,
    required this.sampleName,
    required this.reportDate,
    required this.isValid,
  });

  factory TestReportBrief.fromJson(Map<String, dynamic> j) => TestReportBrief(
    id: _i(j, 'id'),
    code: _s(j, 'code'),
    codeInternal: _s(j, 'code_internal'),
    state: _s(j, 'state'),
    stateLabel: _s(j, 'state_label'),
    partnerName: _s(j, 'partner_name'),
    sampleName: _s(j, 'sample_name'),
    reportDate: formatVn(_s(j, 'report_date')),
    isValid: j['is_valid'] == true,
  );
}

class TestReportResultLine {
  final int id;
  final String parameterName;
  final String methodName;
  final double lod;
  final String result;
  final String unitName;
  final String remark;

  TestReportResultLine({
    required this.id,
    required this.parameterName,
    required this.methodName,
    required this.lod,
    required this.result,
    required this.unitName,
    required this.remark,
  });

  factory TestReportResultLine.fromJson(Map<String, dynamic> j) =>
      TestReportResultLine(
        id: _i(j, 'id'),
        parameterName: _s(j, 'parameter_name'),
        methodName: _s(j, 'method_name'),
        lod: _d(j, 'lod'),
        result: _s(j, 'result'),
        unitName: _s(j, 'unit_name'),
        remark: _s(j, 'remark'),
      );
}

class TestReportSampleLine {
  final int id;
  final String sampleName;
  final String sampleIdCode;
  final String sampleCodingDisplay; // mã hóa mẫu (gộp)
  final String sampleStatus; // selection label
  final String packing; // bao gói
  final double sampleWeight;
  final String packingUnit; // selection label (Quả/kg/Gói)
  final String storage; // selection label

  TestReportSampleLine({
    required this.id,
    required this.sampleName,
    required this.sampleIdCode,
    required this.sampleCodingDisplay,
    required this.sampleStatus,
    required this.packing,
    required this.sampleWeight,
    required this.packingUnit,
    required this.storage,
  });

  factory TestReportSampleLine.fromJson(Map<String, dynamic> j) =>
      TestReportSampleLine(
        id: _i(j, 'id'),
        sampleName: _s(j, 'sample_name'),
        sampleIdCode: _s(j, 'sample_id_code'),
        sampleCodingDisplay: _s(j, 'sample_coding_display'),
        sampleStatus: _s(j, 'sample_status'),
        packing: _s(j, 'packing'),
        sampleWeight: _d(j, 'sample_weight'),
        packingUnit: _s(j, 'packing_unit'),
        storage: _s(j, 'storage'),
      );
}

class TestReportDetail {
  final int id;
  final String code;
  final String codeInternal;
  final String state;
  final String stateLabel;
  final String partnerName;
  final String sampleName;
  final String reportDate;
  final bool isValid;
  // detail-only
  final String requestCode;
  final String samplingReportName;
  // I. Thông tin khách hàng
  final String customerAddress;
  final String samplingLocationName;
  final String plantingAreaCode;
  final String packingFacilityCode;
  final String vehiclePlate;
  final String trailerPlate;
  final String containerCode;
  final String sealNumber;
  // II. Thông tin mẫu
  final String samplingDate;
  final int totalSampleCount;
  final String sampleReceiptDate;
  final String testingDateStart;
  final String testingDateEnd;
  // III. Kết quả (header tổng hợp)
  final String sampleCodingDisplay;
  final String sampleIdCodeDisplay;
  // Ký duyệt
  final String labManagerName;
  final String labManagerSignedOn;
  final String signerTitleVi;
  final String signerTitleEn;
  final String directorName;
  final String directorSignedOn;
  final String cancelReason;
  // Header meta (Tạo bởi / Cập nhật lần cuối) — khớp formview Odoo.
  final String createdBy;
  final String createdAt;
  final String updatedBy;
  final String updatedAt;
  final List<TestReportResultLine> resultLines;
  final List<TestReportSampleLine> sampleLines;

  TestReportDetail({
    required this.id,
    required this.code,
    required this.codeInternal,
    required this.state,
    required this.stateLabel,
    required this.partnerName,
    required this.sampleName,
    required this.reportDate,
    required this.isValid,
    this.requestCode = '',
    required this.samplingReportName,
    required this.customerAddress,
    required this.samplingLocationName,
    required this.plantingAreaCode,
    required this.packingFacilityCode,
    required this.vehiclePlate,
    required this.trailerPlate,
    required this.containerCode,
    required this.sealNumber,
    required this.samplingDate,
    required this.totalSampleCount,
    required this.sampleReceiptDate,
    required this.testingDateStart,
    required this.testingDateEnd,
    required this.sampleCodingDisplay,
    required this.sampleIdCodeDisplay,
    required this.labManagerName,
    required this.labManagerSignedOn,
    required this.signerTitleVi,
    required this.signerTitleEn,
    required this.directorName,
    required this.directorSignedOn,
    required this.cancelReason,
    this.createdBy = '',
    this.createdAt = '',
    this.updatedBy = '',
    this.updatedAt = '',
    required this.resultLines,
    required this.sampleLines,
  });

  factory TestReportDetail.fromJson(Map<String, dynamic> j) => TestReportDetail(
    id: _i(j, 'id'),
    code: _s(j, 'code'),
    codeInternal: _s(j, 'code_internal'),
    state: _s(j, 'state'),
    stateLabel: _s(j, 'state_label'),
    partnerName: _s(j, 'partner_name'),
    sampleName: _s(j, 'sample_name'),
    reportDate: formatVn(_s(j, 'report_date')),
    isValid: j['is_valid'] == true,
    requestCode: _s(j, 'request_code'),
    samplingReportName: _s(j, 'sampling_report_name'),
    customerAddress: _s(j, 'customer_address'),
    samplingLocationName: _s(j, 'sampling_location_name'),
    plantingAreaCode: _s(j, 'planting_area_code'),
    packingFacilityCode: _s(j, 'packing_facility_code'),
    vehiclePlate: _s(j, 'vehicle_plate'),
    trailerPlate: _s(j, 'trailer_plate'),
    containerCode: _s(j, 'container_code'),
    sealNumber: _s(j, 'seal_number'),
    samplingDate: formatVn(_s(j, 'sampling_date')),
    totalSampleCount: _i(j, 'total_sample_count'),
    sampleReceiptDate: formatVn(_s(j, 'sample_receipt_date')),
    testingDateStart: _s(j, 'testing_date_start'),
    testingDateEnd: _s(j, 'testing_date_end'),
    sampleCodingDisplay: _s(j, 'sample_coding_display'),
    sampleIdCodeDisplay: _s(j, 'sample_id_code_display'),
    labManagerName: _s(j, 'lab_manager_name'),
    labManagerSignedOn: _s(j, 'lab_manager_signed_on'),
    signerTitleVi: _s(j, 'signer_title_vi'),
    signerTitleEn: _s(j, 'signer_title_en'),
    directorName: _s(j, 'director_name'),
    directorSignedOn: _s(j, 'director_signed_on'),
    cancelReason: _s(j, 'cancel_reason'),
    createdBy: _s(j, 'created_by'),
    createdAt: _s(j, 'created_at'),
    updatedBy: _s(j, 'updated_by'),
    updatedAt: _s(j, 'updated_at'),
    resultLines:
        (j['result_line_ids'] is List ? j['result_line_ids'] as List : const [])
            .map(
              (e) => TestReportResultLine.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
    sampleLines:
        (j['sample_line_ids'] is List ? j['sample_line_ids'] as List : const [])
            .map(
              (e) => TestReportSampleLine.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
  );
}
