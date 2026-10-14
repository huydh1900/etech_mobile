import '../utils/vn_format.dart';

// Odoo trả `false` cho field rỗng (char/m2o/date) -> coerce về ''/0,
// tránh render "false" và crash cast khi backend thiếu dữ liệu.
String _sv(Object? v) => (v == null || v == false) ? '' : v.toString();
int _iv(Object? v) => v is num ? v.toInt() : 0;
double _dv(Object? v) => v is num ? v.toDouble() : 0;

class SelectOption {
  final String value;
  final String label;
  const SelectOption(this.value, this.label);

  factory SelectOption.fromJson(Map<String, dynamic> j) =>
      SelectOption(_sv(j['value']), _sv(j['label']));
}

class SamplingOptions {
  final List<SelectOption> sampleStatus;
  final List<SelectOption> packingUnit;
  final List<SelectOption> storage;
  final List<SelectOption> envCondition;
  final List<SelectOption> photoColumns;

  SamplingOptions({
    required this.sampleStatus,
    required this.packingUnit,
    required this.storage,
    required this.envCondition,
    required this.photoColumns,
  });

  static List<SelectOption> _list(dynamic raw) => (raw is List ? raw : const [])
      .map((e) => SelectOption.fromJson(e))
      .toList();

  factory SamplingOptions.fromJson(Map<String, dynamic> j) => SamplingOptions(
    sampleStatus: _list(j['sample_status']),
    packingUnit: _list(j['packing_unit']),
    storage: _list(j['storage']),
    envCondition: _list(j['env_condition']),
    photoColumns:
        (j['photo_columns'] is List ? j['photo_columns'] as List : const [])
            .map((e) => SelectOption(_sv(e['key']), _sv(e['label'])))
            .toList(),
  );
}

class SamplingProgram {
  final int id;
  final String code;
  final String partnerName;
  final String sampleName;
  final String samplingLocation;
  final String scheduled;
  final String state;
  final String stateLabel;

  SamplingProgram({
    required this.id,
    required this.code,
    required this.partnerName,
    required this.sampleName,
    required this.samplingLocation,
    required this.scheduled,
    required this.state,
    required this.stateLabel,
  });

  factory SamplingProgram.fromJson(Map<String, dynamic> j) => SamplingProgram(
    id: _iv(j['id']),
    code: _sv(j['code']),
    partnerName: _sv(j['partner_name']),
    sampleName: _sv(j['sample_name']),
    samplingLocation: _sv(j['sampling_location']),
    // Field hiển-thị-thuần → format kiểu VN ngay tại fromJson.
    scheduled: formatVn(_sv(j['scheduled'])),
    state: _sv(j['state']),
    stateLabel: _sv(j['state_label']),
  );
}

class SamplingProgramParameter {
  final String parameter;
  final String method;
  final String unit;
  final String analyzerDevice;
  final bool isOutsourced;
  final String detectionLimit;

  SamplingProgramParameter({
    required this.parameter,
    required this.method,
    required this.unit,
    required this.analyzerDevice,
    required this.isOutsourced,
    required this.detectionLimit,
  });

  factory SamplingProgramParameter.fromJson(Map<String, dynamic> j) =>
      SamplingProgramParameter(
        parameter: _sv(j['parameter']),
        method: _sv(j['method']),
        unit: _sv(j['unit']),
        analyzerDevice: _sv(j['analyzer_device']),
        isOutsourced: j['is_outsourced'] == true,
        detectionLimit: _sv(j['detection_limit']),
      );
}

class SamplingProgramMethod {
  final String sampleType;
  final String method;

  SamplingProgramMethod({required this.sampleType, required this.method});

  factory SamplingProgramMethod.fromJson(Map<String, dynamic> j) =>
      SamplingProgramMethod(
        sampleType: _sv(j['sample_type']),
        method: _sv(j['method']),
      );
}

class SamplingProgramReportRef {
  final int id;
  final String code;
  final String state;
  final String stateLabel;

  SamplingProgramReportRef({
    required this.id,
    required this.code,
    required this.state,
    required this.stateLabel,
  });

  factory SamplingProgramReportRef.fromJson(Map<String, dynamic> j) =>
      SamplingProgramReportRef(
        id: _iv(j['id']),
        code: _sv(j['code']),
        state: _sv(j['state']),
        stateLabel: _sv(j['state_label']),
      );
}

class SamplingProgramDetail {
  final int id;
  final String code;
  final String state;
  final String stateLabel;
  final String createdBy;
  final String createdAt;
  final String updatedBy;
  final String updatedAt;
  final String requestCode;
  final String testingPurpose;
  final String partnerName;
  final String customerAddress;
  final String contactName;
  final String contactPhone;
  final String sampleName;
  final String sampleType;
  final String samplingLocation;
  final String scheduled;
  final String parentSampleCode;

  /// Mã mẫu con sinh từ khối lượng mẫu ban đầu ([hồ sơ].[loại mẫu].NN).
  final List<String> initialSampleCodes;
  final int initialSampleWeight;
  final String initialSampleUom;
  final String excessSampleHandling;
  final int sampleCount;
  final String vehiclePlate;
  final String plantingAreaCode;
  final String containerCode;
  final String packingFacilityCode;
  final String trailerPlate;
  final List<String> teamLeaders;
  final List<String> deputyLeaders;
  final List<String> members;
  final List<String> transportModes;

  /// Toàn bộ lựa chọn phương tiện (để vẽ checkbox chưa chọn như Odoo).
  final List<String> transportModeOptions;
  final String samplingEquipment;
  final String comparisonStandardType;

  /// Nhãn tất cả lựa chọn của field selection `comparison_standard_type`.
  final List<String> comparisonStandardOptions;
  final String comparisonStandard;
  final List<SamplingProgramParameter> parameters;
  final List<SamplingProgramMethod> methods;
  final List<SamplingProgramReportRef> reports;

  SamplingProgramDetail({
    required this.id,
    required this.code,
    required this.state,
    required this.stateLabel,
    this.createdBy = '',
    this.createdAt = '',
    this.updatedBy = '',
    this.updatedAt = '',
    required this.requestCode,
    required this.testingPurpose,
    required this.partnerName,
    required this.customerAddress,
    required this.contactName,
    required this.contactPhone,
    required this.sampleName,
    required this.sampleType,
    required this.samplingLocation,
    required this.scheduled,
    required this.parentSampleCode,
    this.initialSampleCodes = const [],
    required this.initialSampleWeight,
    required this.initialSampleUom,
    required this.excessSampleHandling,
    required this.sampleCount,
    required this.vehiclePlate,
    required this.plantingAreaCode,
    required this.containerCode,
    required this.packingFacilityCode,
    required this.trailerPlate,
    required this.teamLeaders,
    required this.deputyLeaders,
    required this.members,
    required this.transportModes,
    this.transportModeOptions = const [],
    required this.samplingEquipment,
    required this.comparisonStandardType,
    this.comparisonStandardOptions = const [],
    required this.comparisonStandard,
    required this.parameters,
    required this.methods,
    required this.reports,
  });

  static List<String> _strList(dynamic raw) => (raw is List ? raw : const [])
      .where((e) => e != null && e != false)
      .map((e) => e.toString())
      .where((s) => s.isNotEmpty)
      .toList();

  factory SamplingProgramDetail.fromJson(Map<String, dynamic> j) {
    String s(String k) => _sv(j[k]);
    return SamplingProgramDetail(
      id: _iv(j['id']),
      code: s('code'),
      state: s('state'),
      stateLabel: s('state_label'),
      createdBy: s('created_by'),
      createdAt: s('created_at'),
      updatedBy: s('updated_by'),
      updatedAt: s('updated_at'),
      requestCode: s('request_code'),
      testingPurpose: s('testing_purpose'),
      partnerName: s('partner_name'),
      customerAddress: s('customer_address'),
      contactName: s('contact_name'),
      contactPhone: s('contact_phone'),
      sampleName: s('sample_name'),
      sampleType: s('sample_type'),
      samplingLocation: s('sampling_location'),
      scheduled: formatVn(s('scheduled')),
      parentSampleCode: s('parent_sample_code'),
      initialSampleCodes: _strList(j['initial_sample_codes']),
      initialSampleWeight: _iv(j['initial_sample_weight']),
      initialSampleUom: s('initial_sample_uom'),
      excessSampleHandling: s('excess_sample_handling'),
      sampleCount: _iv(j['sample_count']),
      vehiclePlate: s('vehicle_plate'),
      plantingAreaCode: s('planting_area_code'),
      containerCode: s('container_code'),
      packingFacilityCode: s('packing_facility_code'),
      trailerPlate: s('trailer_plate'),
      teamLeaders: _strList(j['team_leaders']),
      deputyLeaders: _strList(j['deputy_leaders']),
      members: _strList(j['members']),
      transportModes: _strList(j['transport_modes']),
      transportModeOptions: _strList(j['transport_mode_options']),
      samplingEquipment: s('sampling_equipment'),
      comparisonStandardType: s('comparison_standard_type'),
      comparisonStandardOptions: (j['comparison_standard_type_options'] is List)
          ? (j['comparison_standard_type_options'] as List)
                .map((e) => e is Map ? _sv(e['label']) : _sv(e))
                .where((e) => e.isNotEmpty)
                .toList()
          : const [],
      comparisonStandard: s('comparison_standard'),
      parameters: (j['parameters'] is List ? j['parameters'] as List : const [])
          .map((e) => SamplingProgramParameter.fromJson(e))
          .toList(),
      methods: (j['methods'] is List ? j['methods'] as List : const [])
          .map((e) => SamplingProgramMethod.fromJson(e))
          .toList(),
      reports: (j['reports'] is List ? j['reports'] as List : const [])
          .map((e) => SamplingProgramReportRef.fromJson(e))
          .toList(),
    );
  }
}

class SamplingReportBrief {
  final int id;
  final String code;
  final String state;
  final String stateLabel;
  final String programCode;
  final String partnerName;
  final String sampleName;
  final String samplingLocation;
  final String actualDate;
  final int sampleCount;

  SamplingReportBrief({
    required this.id,
    required this.code,
    required this.state,
    required this.stateLabel,
    required this.programCode,
    required this.partnerName,
    required this.sampleName,
    required this.samplingLocation,
    required this.actualDate,
    required this.sampleCount,
  });

  factory SamplingReportBrief.fromJson(Map<String, dynamic> j) =>
      SamplingReportBrief(
        id: _iv(j['id']),
        code: _sv(j['code']),
        state: _sv(j['state']),
        stateLabel: _sv(j['state_label']),
        programCode: _sv(j['program_code']),
        partnerName: _sv(j['partner_name']),
        sampleName: _sv(j['sample_name']),
        samplingLocation: _sv(j['sampling_location']),
        actualDate: _sv(j['actual_date']),
        sampleCount: _iv(j['sample_count']),
      );
}

class SamplingLine {
  /// Id dòng bên Odoo. Bắt buộc khi lưu: formview không cho thêm/xoá dòng
  /// (`create="0" delete="0"`), chỉ ghi đè dòng sẵn có.
  final int id;

  String name;
  String sampleType;
  String sampleTypeCode;
  String originalCode;
  String sampleStatus;
  String packing;
  int sampleWeight;
  String packingUnit;
  String storage;
  String description;
  String sealStampNo;
  List<String> parameters;

  SamplingLine({
    this.id = 0,
    this.name = '',
    this.sampleType = '',
    this.sampleTypeCode = '',
    this.originalCode = '',
    this.sampleStatus = '',
    this.packing = '',
    this.sampleWeight = 0,
    this.packingUnit = '',
    this.storage = '',
    this.description = '',
    this.sealStampNo = '',
    this.parameters = const [],
  });

  factory SamplingLine.fromJson(Map<String, dynamic> j) => SamplingLine(
    id: _iv(j['id']),
    name: _sv(j['name']),
    sampleType: _sv(j['sample_type']),
    sampleTypeCode: _sv(j['sample_type_code']),
    originalCode: _sv(j['original_code']),
    sampleStatus: _sv(j['sample_status']),
    packing: _sv(j['packing']),
    sampleWeight: _iv(j['sample_weight']),
    packingUnit: _sv(j['packing_unit']),
    storage: _sv(j['storage']),
    description: _sv(j['description']),
    sealStampNo: _sv(j['seal_stamp_no']),
    parameters: (j['parameters'] is List)
        ? (j['parameters'] as List).map((e) => e.toString()).toList()
        : const [],
  );

  /// Chỉ gửi các field widget `sample_desc` của Odoo cho sửa. `name` /
  /// `original_code` / `description` / `parameter_ids` / `seal_stamp_no` là
  /// readonly trong formview nên không đụng tới.
  Map<String, dynamic> toJson() => {
    'id': id,
    'sample_status': sampleStatus,
    'packing': packing,
    'sample_weight': sampleWeight,
    'packing_unit': packingUnit,
    'storage': storage,
  };
}

class SamplingPhoto {
  final int id;
  final String name;
  final String url;
  const SamplingPhoto({
    required this.id,
    required this.name,
    required this.url,
  });

  factory SamplingPhoto.fromJson(Map<String, dynamic> j) =>
      SamplingPhoto(id: _iv(j['id']), name: _sv(j['name']), url: _sv(j['url']));
}

/// Người lấy mẫu (section "Đơn vị lấy mẫu") — tên + chức danh.
class SamplingPerson {
  final String name;
  final String jobTitle;
  const SamplingPerson({this.name = '', this.jobTitle = ''});
  factory SamplingPerson.fromJson(Map<String, dynamic> j) =>
      SamplingPerson(name: _sv(j['name']), jobTitle: _sv(j['job_title']));
}

/// Phương pháp lấy mẫu (section "Phương pháp lấy mẫu") — loại mẫu + mã SOP.
class SamplingMethod {
  final String sampleType;
  final String sopCode;
  const SamplingMethod({this.sampleType = '', this.sopCode = ''});
  factory SamplingMethod.fromJson(Map<String, dynamic> j) => SamplingMethod(
    sampleType: _sv(j['sample_type']),
    sopCode: _sv(j['sop_code']),
  );
}

/// Một mốc thời gian lấy mẫu (mục 11 formview) — đã format kiểu VN.
class SamplingDateRange {
  final String start;
  final String end;

  const SamplingDateRange({required this.start, required this.end});

  factory SamplingDateRange.fromJson(Map<String, dynamic> j) =>
      SamplingDateRange(
        start: formatVn(_sv(j['date_start'])),
        end: formatVn(_sv(j['date_end'])),
      );
}

class SamplingReportDetail {
  final int id;
  final String code;
  final String state;
  final String stateLabel;
  final String programCode;
  final String requestCode;
  final String partnerName;
  String customerAddress;
  final String samplingLocation;
  // Header meta (Tạo bởi / Cập nhật lần cuối) khớp formview Odoo.
  final String createdBy;
  final String createdAt;
  final String updatedBy;
  final String updatedAt;
  // Section bổ sung
  final String sampleType;
  final String sampleCountDisplay;
  final String storageDuration;
  String customerRepIdDate;
  final String supervisor1Name;
  final String supervisor1Title;
  final String supervisor1Org;
  final String supervisor1Address;
  final String supervisor2Name;
  final String supervisor2Title;
  final String supervisor2Org;
  final String supervisor2Address;
  final String supervisorSignerName;

  /// Khối chữ ký cuối formview — ô "ĐD. Đơn vị lấy mẫu".
  final String technicianName;

  /// Mục 1/4 — giá trị "thực tế" cập nhật tại hiện trường (formview Odoo tách
  /// 2 cột: "Yêu cầu (link từ phiếu yêu cầu)" và "Thực tế (cập nhật tại chỗ)").
  String samplingLocationActual;
  String vehiclePlateActual;
  String containerCodeActual;
  String trailerPlateActual;

  /// Mục 11 — các mốc thời gian lấy mẫu (bắt đầu / kết thúc).
  final List<SamplingDateRange> dates;

  /// Mục 12 — mốc "Biên bản lập hồi …".
  final String completionLabel;

  final List<SamplingPerson> samplers;
  final List<SamplingMethod> methods;

  String sampleName;
  String sealNumber;
  String vehiclePlate;
  String trailerPlate;
  String containerCode;
  String plantingAreaCode;
  String packingFacilityCode;
  String envCondition;
  String envConditionOther;
  String otherRemarks;
  String customerRepName;
  String customerRepPhone;
  String customerRepTitle;
  String customerRepAddress;
  String customerRepIdCard;
  String customerSignerName;
  double geoLat;
  double geoLon;
  String actualDate;

  List<SamplingLine> lines;
  Map<String, List<SamplingPhoto>> photos;

  SamplingReportDetail({
    required this.id,
    required this.code,
    required this.state,
    required this.stateLabel,
    required this.programCode,
    this.requestCode = '',
    required this.partnerName,
    required this.customerAddress,
    required this.samplingLocation,
    this.createdBy = '',
    this.createdAt = '',
    this.updatedBy = '',
    this.updatedAt = '',
    this.sampleType = '',
    this.sampleCountDisplay = '',
    this.storageDuration = '',
    this.customerRepIdDate = '',
    this.supervisor1Name = '',
    this.supervisor1Title = '',
    this.supervisor1Org = '',
    this.supervisor1Address = '',
    this.supervisor2Name = '',
    this.supervisor2Title = '',
    this.supervisor2Org = '',
    this.supervisor2Address = '',
    this.supervisorSignerName = '',
    this.technicianName = '',
    this.samplingLocationActual = '',
    this.vehiclePlateActual = '',
    this.containerCodeActual = '',
    this.trailerPlateActual = '',
    this.dates = const [],
    this.completionLabel = '',
    this.samplers = const [],
    this.methods = const [],
    required this.sampleName,
    required this.sealNumber,
    required this.vehiclePlate,
    required this.trailerPlate,
    required this.containerCode,
    required this.plantingAreaCode,
    required this.packingFacilityCode,
    required this.envCondition,
    required this.envConditionOther,
    required this.otherRemarks,
    required this.customerRepName,
    required this.customerRepPhone,
    required this.customerRepTitle,
    required this.customerRepAddress,
    required this.customerRepIdCard,
    required this.customerSignerName,
    required this.geoLat,
    required this.geoLon,
    required this.actualDate,
    required this.lines,
    required this.photos,
  });

  bool get isDraft => state == 'draft';

  static String _s(Map<String, dynamic> j, String k) => _sv(j[k]);

  factory SamplingReportDetail.fromJson(Map<String, dynamic> j) {
    final rawPhotos = (j['photos'] is Map ? (j['photos'] as Map) : const {});
    final photos = <String, List<SamplingPhoto>>{};
    rawPhotos.forEach((key, value) {
      photos[key.toString()] = (value is List ? value : const [])
          .map((e) => SamplingPhoto.fromJson(e))
          .toList();
    });
    return SamplingReportDetail(
      id: _iv(j['id']),
      code: _s(j, 'code'),
      state: _s(j, 'state'),
      stateLabel: _s(j, 'state_label'),
      programCode: _s(j, 'program_code'),
      requestCode: _s(j, 'request_code'),
      partnerName: _s(j, 'partner_name'),
      customerAddress: _s(j, 'customer_address'),
      samplingLocation: _s(j, 'sampling_location'),
      createdBy: _s(j, 'created_by'),
      createdAt: _s(j, 'created_at'),
      updatedBy: _s(j, 'updated_by'),
      updatedAt: _s(j, 'updated_at'),
      sampleType: _s(j, 'sample_type'),
      sampleCountDisplay: _s(j, 'sample_count_display'),
      storageDuration: _s(j, 'storage_duration'),
      customerRepIdDate: _s(j, 'customer_rep_id_date'),
      supervisor1Name: _s(j, 'supervisor1_name'),
      supervisor1Title: _s(j, 'supervisor1_title'),
      supervisor1Org: _s(j, 'supervisor1_org'),
      supervisor1Address: _s(j, 'supervisor1_address'),
      supervisor2Name: _s(j, 'supervisor2_name'),
      supervisor2Title: _s(j, 'supervisor2_title'),
      supervisor2Org: _s(j, 'supervisor2_org'),
      supervisor2Address: _s(j, 'supervisor2_address'),
      supervisorSignerName: _s(j, 'supervisor_signer_name'),
      technicianName: _s(j, 'technician_name'),
      samplingLocationActual: _s(j, 'sampling_location_actual'),
      vehiclePlateActual: _s(j, 'vehicle_plate_actual'),
      containerCodeActual: _s(j, 'container_code_actual'),
      trailerPlateActual: _s(j, 'trailer_plate_actual'),
      dates: (j['dates'] is List ? j['dates'] as List : const [])
          .map((e) => SamplingDateRange.fromJson(e))
          .toList(),
      completionLabel: _s(j, 'completion_label'),
      samplers: (j['samplers'] is List ? j['samplers'] as List : const [])
          .map((e) => SamplingPerson.fromJson(e))
          .toList(),
      methods: (j['methods'] is List ? j['methods'] as List : const [])
          .map((e) => SamplingMethod.fromJson(e))
          .toList(),
      sampleName: _s(j, 'sample_name'),
      sealNumber: _s(j, 'seal_number'),
      vehiclePlate: _s(j, 'vehicle_plate'),
      trailerPlate: _s(j, 'trailer_plate'),
      containerCode: _s(j, 'container_code'),
      plantingAreaCode: _s(j, 'planting_area_code'),
      packingFacilityCode: _s(j, 'packing_facility_code'),
      envCondition: _s(j, 'env_condition'),
      envConditionOther: _s(j, 'env_condition_other'),
      otherRemarks: _s(j, 'other_remarks'),
      customerRepName: _s(j, 'customer_rep_name'),
      customerRepPhone: _s(j, 'customer_rep_phone'),
      customerRepTitle: _s(j, 'customer_rep_title'),
      customerRepAddress: _s(j, 'customer_rep_address'),
      customerRepIdCard: _s(j, 'customer_rep_id_card'),
      customerSignerName: _s(j, 'customer_signer_name'),
      geoLat: _dv(j['geo_lat']),
      geoLon: _dv(j['geo_lon']),
      actualDate: _s(j, 'actual_date'),
      lines: (j['lines'] is List ? j['lines'] as List : const [])
          .map((e) => SamplingLine.fromJson(e))
          .toList(),
      photos: photos,
    );
  }

  Map<String, dynamic> toSaveJson() => {
    'sample_name': sampleName,
    'seal_number': sealNumber,
    'vehicle_plate': vehiclePlate,
    'trailer_plate': trailerPlate,
    'container_code': containerCode,
    'planting_area_code': plantingAreaCode,
    'packing_facility_code': packingFacilityCode,
    'env_condition': envCondition,
    'env_condition_other': envConditionOther,
    'other_remarks': otherRemarks,
    'customer_rep_name': customerRepName,
    'customer_rep_phone': customerRepPhone,
    'customer_rep_title': customerRepTitle,
    'customer_rep_address': customerRepAddress,
    'customer_rep_id_card': customerRepIdCard,
    'customer_signer_name': customerSignerName,
    // Nhóm field formview Odoo cho nhập khi còn nháp: địa chỉ KH, ngày cấp
    // CCCD, và các giá trị "thực tế" ghi nhận tại hiện trường (mục 1 & 4).
    'customer_address': customerAddress,
    'customer_rep_id_date': customerRepIdDate,
    'sampling_location_actual': samplingLocationActual,
    'vehicle_plate_actual': vehiclePlateActual,
    'container_code_actual': containerCodeActual,
    'trailer_plate_actual': trailerPlateActual,
    'geo_lat': geoLat,
    'geo_lon': geoLon,
    'lines': lines.map((l) => l.toJson()).toList(),
  };
}
