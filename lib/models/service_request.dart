import '../utils/vn_format.dart';
// Model cho luồng "Hồ sơ": phiếu yêu cầu dịch vụ + khách hàng.
// Map 1:1 với /api/service_requests/* và /api/customers/*.

// Odoo trả `false` cho field rỗng (char/m2o/date) -> coerce về ''/0,
// tránh render "false" và crash cast khi backend thiếu dữ liệu.
String _sv(Object? v) => (v == null || v == false) ? '' : v.toString();
int _iv(Object? v) => v is num ? v.toInt() : 0;

class ServiceRequestBrief {
  final int id;
  final String code;
  final String state;
  final String stateLabel;
  final String partnerName;
  final String sampleType;
  final String samplingLocation;
  final String requestDate;
  final int totalSampleQty;

  ServiceRequestBrief({
    required this.id,
    required this.code,
    required this.state,
    required this.stateLabel,
    required this.partnerName,
    required this.sampleType,
    required this.samplingLocation,
    required this.requestDate,
    required this.totalSampleQty,
  });

  static String _s(Map<String, dynamic> j, String k) => _sv(j[k]);

  factory ServiceRequestBrief.fromJson(Map<String, dynamic> j) =>
      ServiceRequestBrief(
        id: _iv(j['id']),
        code: _s(j, 'code'),
        state: _s(j, 'state'),
        stateLabel: _s(j, 'state_label'),
        partnerName: _s(j, 'partner_name'),
        sampleType: _s(j, 'sample_type'),
        samplingLocation: _s(j, 'sampling_location'),
        requestDate: formatVn(_s(j, 'request_date')),
        totalSampleQty: _iv(j['total_sample_qty']),
      );
}

class ServiceRequestLine {
  final int id;
  final String name;
  final String sampleType;
  final List<String> parameters;
  final List<String> methods;
  final int sampleQty;
  final String note;

  ServiceRequestLine({
    required this.id,
    required this.name,
    required this.sampleType,
    required this.parameters,
    required this.methods,
    required this.sampleQty,
    required this.note,
  });

  static List<String> _strList(dynamic raw) => (raw is List ? raw : const [])
      .where((e) => e != null && e != false)
      .map((e) => e.toString())
      .where((s) => s.isNotEmpty)
      .toList();

  factory ServiceRequestLine.fromJson(Map<String, dynamic> j) =>
      ServiceRequestLine(
        id: _iv(j['id']),
        name: _sv(j['name']),
        sampleType: _sv(j['sample_type']),
        parameters: _strList(j['parameters']),
        methods: _strList(j['methods']),
        sampleQty: _iv(j['sample_qty']),
        note: _sv(j['note']),
      );
}

class ServiceRequestDetail extends ServiceRequestBrief {
  // Header meta (formview Odoo: Tạo bởi / Cập nhật lần cuối)
  final String requestCode;
  final String createdBy;
  final String createdAt;
  final String updatedBy;
  final String updatedAt;
  // I. Thông tin khách hàng (field bổ sung từ etech_portal)
  final String partnerNameEn;
  final String partnerLegalRepresentative;
  final String contractNumber;
  final String partnerContactPerson;
  final String contactName;
  final String phone;
  final String email;
  final String address;
  final String partnerVat;
  final String partnerFunction;
  final String signingLocation;
  final String invoiceCompanyName;
  final String invoiceAddress;
  final String invoiceVat;
  final String invoiceEmail;
  final String packingFacilityCode;
  final String growingAreaCode;
  final String vehiclePlate;
  final String rmoocNumber;
  final String containerNumber;
  final String expectedSamplingDate;
  final String testingPurpose;
  final String testingPurposeOther;
  final String certifiedMethod;
  final String subcontractorUse;
  final String resultLanguage;
  final String sampleRetention;
  final String excessSampleHandling;
  final String analysisTime;
  final String desiredAnalysisDatetime;
  final String resultDelivery;
  final String paymentMethod;
  final String invoiceTiming;
  final String userName;
  final String departmentName;
  final String rejectReason;
  final List<ServiceRequestLine> lines;

  ServiceRequestDetail({
    required super.id,
    required super.code,
    required super.state,
    required super.stateLabel,
    required super.partnerName,
    required super.sampleType,
    required super.samplingLocation,
    required super.requestDate,
    required super.totalSampleQty,
    this.requestCode = '',
    this.createdBy = '',
    this.createdAt = '',
    this.updatedBy = '',
    this.updatedAt = '',
    this.partnerNameEn = '',
    this.partnerLegalRepresentative = '',
    this.contractNumber = '',
    this.partnerContactPerson = '',
    required this.contactName,
    required this.phone,
    required this.email,
    required this.address,
    required this.partnerVat,
    required this.partnerFunction,
    required this.signingLocation,
    required this.invoiceCompanyName,
    required this.invoiceAddress,
    required this.invoiceVat,
    required this.invoiceEmail,
    required this.packingFacilityCode,
    required this.growingAreaCode,
    required this.vehiclePlate,
    required this.rmoocNumber,
    required this.containerNumber,
    required this.expectedSamplingDate,
    required this.testingPurpose,
    required this.testingPurposeOther,
    required this.certifiedMethod,
    required this.subcontractorUse,
    required this.resultLanguage,
    required this.sampleRetention,
    required this.excessSampleHandling,
    required this.analysisTime,
    this.desiredAnalysisDatetime = '',
    required this.resultDelivery,
    required this.paymentMethod,
    required this.invoiceTiming,
    required this.userName,
    required this.departmentName,
    required this.rejectReason,
    required this.lines,
  });

  factory ServiceRequestDetail.fromJson(Map<String, dynamic> j) {
    String s(String k) => _sv(j[k]);
    return ServiceRequestDetail(
      id: _iv(j['id']),
      code: s('code'),
      state: s('state'),
      stateLabel: s('state_label'),
      partnerName: s('partner_name'),
      sampleType: s('sample_type'),
      samplingLocation: s('sampling_location'),
      requestDate: formatVn(s('request_date')),
      totalSampleQty: _iv(j['total_sample_qty']),
      // Meta header giữ raw ISO (screen format qua metaDt).
      requestCode: s('request_code'),
      createdBy: s('created_by'),
      createdAt: s('created_at'),
      updatedBy: s('updated_by'),
      updatedAt: s('updated_at'),
      partnerNameEn: s('partner_name_en'),
      partnerLegalRepresentative: s('partner_legal_representative'),
      contractNumber: s('contract_number'),
      partnerContactPerson: s('partner_contact_person'),
      contactName: s('contact_name'),
      phone: s('phone'),
      email: s('email'),
      address: s('address'),
      partnerVat: s('partner_vat'),
      partnerFunction: s('partner_function'),
      signingLocation: s('signing_location'),
      invoiceCompanyName: s('invoice_company_name'),
      invoiceAddress: s('invoice_address'),
      invoiceVat: s('invoice_vat'),
      invoiceEmail: s('invoice_email'),
      packingFacilityCode: s('packing_facility_code'),
      growingAreaCode: s('growing_area_code'),
      vehiclePlate: s('vehicle_plate'),
      rmoocNumber: s('rmooc_number'),
      containerNumber: s('container_number'),
      expectedSamplingDate: formatVn(s('expected_sampling_date')),
      testingPurpose: s('testing_purpose'),
      testingPurposeOther: s('testing_purpose_other'),
      certifiedMethod: s('certified_method'),
      subcontractorUse: s('subcontractor_use'),
      resultLanguage: s('result_language'),
      sampleRetention: s('sample_retention'),
      excessSampleHandling: s('excess_sample_handling'),
      analysisTime: s('analysis_time'),
      desiredAnalysisDatetime: formatVn(s('desired_analysis_datetime')),
      resultDelivery: s('result_delivery'),
      paymentMethod: s('payment_method'),
      invoiceTiming: s('invoice_timing'),
      userName: s('user_name'),
      departmentName: s('department_name'),
      rejectReason: s('reject_reason'),
      lines: (j['lines'] is List ? j['lines'] as List : const [])
          .map((e) => ServiceRequestLine.fromJson(e))
          .toList(),
    );
  }
}

class CustomerBrief {
  final int id;
  final String name;
  final String vat;
  final String phone;
  final String email;
  final String city;
  final bool isCompany;

  CustomerBrief({
    required this.id,
    required this.name,
    required this.vat,
    required this.phone,
    required this.email,
    required this.city,
    required this.isCompany,
  });

  static String _s(Map<String, dynamic> j, String k) => _sv(j[k]);

  factory CustomerBrief.fromJson(Map<String, dynamic> j) => CustomerBrief(
    id: _iv(j['id']),
    name: _s(j, 'name'),
    vat: _s(j, 'vat'),
    phone: _s(j, 'phone'),
    email: _s(j, 'email'),
    city: _s(j, 'city'),
    isCompany: j['is_company'] == true,
  );
}

class CustomerDetail extends CustomerBrief {
  final String ref;
  final String nameEn;
  final String legalRepresentative;
  final String contactPerson;
  final String function;
  final String parentName;
  // Địa chỉ (Quốc gia / Tỉnh-Thành / Phường-Xã / Địa chỉ cụ thể)
  final String countryName;
  final String stateName;
  final String wardName;
  final String street;
  final String street2;
  final String zip;
  final int requestCount;

  CustomerDetail({
    required super.id,
    required super.name,
    required super.vat,
    required super.phone,
    required super.email,
    required super.city,
    required super.isCompany,
    this.ref = '',
    this.nameEn = '',
    this.legalRepresentative = '',
    this.contactPerson = '',
    required this.function,
    required this.parentName,
    this.countryName = '',
    this.stateName = '',
    this.wardName = '',
    required this.street,
    required this.street2,
    this.zip = '',
    required this.requestCount,
  });

  factory CustomerDetail.fromJson(Map<String, dynamic> j) {
    String s(String k) => _sv(j[k]);
    return CustomerDetail(
      id: _iv(j['id']),
      name: s('name'),
      vat: s('vat'),
      phone: s('phone'),
      email: s('email'),
      city: s('city'),
      isCompany: j['is_company'] == true,
      ref: s('ref'),
      nameEn: s('name_en'),
      legalRepresentative: s('legal_representative'),
      contactPerson: s('contact_person'),
      function: s('function'),
      parentName: s('parent_name'),
      countryName: s('country_name'),
      stateName: s('state_name'),
      wardName: s('ward_name'),
      street: s('street'),
      street2: s('street2'),
      zip: s('zip'),
      requestCount: _iv(j['request_count']),
    );
  }
}
