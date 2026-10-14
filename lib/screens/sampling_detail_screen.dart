import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../config.dart';
import '../models/sampling.dart';
import '../services/sampling_service.dart';
import '../theme/app_theme.dart';
import '../utils/vn_format.dart';
import '../widgets/detail_kit.dart';
import '../widgets/states.dart';

class SamplingDetailScreen extends StatefulWidget {
  final String sessionId;
  final int reportId;
  final SamplingReportDetail? initial;

  const SamplingDetailScreen({
    super.key,
    required this.sessionId,
    required this.reportId,
    this.initial,
  });

  @override
  State<SamplingDetailScreen> createState() => _SamplingDetailScreenState();
}

class _SamplingDetailScreenState extends State<SamplingDetailScreen> {
  late final SamplingService _service;
  final _picker = ImagePicker();

  SamplingReportDetail? _report;
  SamplingOptions? _options;
  bool _loading = true;
  bool _busy = false;
  String? _error;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _service = SamplingService(
      baseUrl: AppConfig.odooUrl,
      sessionId: widget.sessionId,
    );
    _report = widget.initial;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _service.getOptions(),
        _service.getReport(widget.reportId),
      ]);
      setState(() {
        _options = results[0] as SamplingOptions;
        _report = results[1] as SamplingReportDetail;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _markDirty() => _dirty = true;

  Map<String, String> get _imgHeaders => {
    'Cookie': 'session_id=${widget.sessionId}',
  };

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _save({bool silent = false}) async {
    final report = _report;
    if (report == null) return;
    setState(() => _busy = true);
    try {
      final saved = await _service.saveReport(report);
      setState(() {
        _report = saved;
        _dirty = false;
      });
      if (!silent) _toast('Đã lưu nháp.');
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _complete() async {
    // Lưu nháp trước để đảm bảo dữ liệu nhập tay đã lên server.
    await _save(silent: true);
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hoàn thành lấy mẫu'),
        content: const Text(
          'Sau khi hoàn thành, biên bản sẽ bị khoá chỉnh sửa. Tiếp tục?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hoàn thành'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      final done = await _service.complete(widget.reportId);
      setState(() {
        _report = done;
        _dirty = false;
      });
      _toast('Đã hoàn thành lấy mẫu.');
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _captureGps() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _toast('Vui lòng bật GPS.');
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        _toast('Chưa cấp quyền vị trí.');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      setState(() {
        _report!.geoLat = pos.latitude;
        _report!.geoLon = pos.longitude;
        _markDirty();
      });
    } catch (e) {
      _toast('Lỗi lấy vị trí: $e');
    }
  }

  Future<void> _addPhoto(String column) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('Chụp ảnh'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Chọn từ thư viện'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1920,
    );
    if (picked == null) return;
    setState(() => _busy = true);
    try {
      final bytes = await picked.readAsBytes();
      final b64 = base64Encode(bytes);
      await _service.addPhoto(
        widget.reportId,
        column,
        b64,
        filename: picked.name,
      );
      final fresh = await _service.getReport(widget.reportId);
      setState(() => _report = fresh);
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deletePhoto(int attId) async {
    setState(() => _busy = true);
    try {
      await _service.deletePhoto(widget.reportId, attId);
      final fresh = await _service.getReport(widget.reportId);
      setState(() => _report = fresh);
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final leave = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Chưa lưu thay đổi'),
            content: const Text('Thoát mà không lưu?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Ở lại'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Thoát'),
              ),
            ],
          ),
        );
        if (leave == true) navigator.pop(true);
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          title: Text(report?.code ?? 'Biên bản'),
          actions: [
            if (report != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text(
                    report.stateLabel,
                    style: TextStyle(
                      color: report.isDraft
                          ? AppColors.primary
                          : AppColors.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: _loading
            ? const _DetailSkeleton()
            : _error != null
            ? ErrorState(message: _error!, onRetry: _load)
            : _buildBody(report!),
        bottomNavigationBar: report == null || !report.isDraft
            ? null
            : _buildBottomBar(),
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _busy ? null : () => _save(),
                icon: const Icon(Icons.save_outlined),
                label: const Text('Lưu nháp'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: _busy ? null : _complete,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                ),
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text('Hoàn thành'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(SamplingReportDetail r) {
    // Formview mobile dùng CHUNG MỘT bố cục cho mọi trạng thái — đúng như Odoo
    // (chỉ có `view_etech_sampling_report_form`, khác nhau ở `readonly` từng
    // field). Trước đây bản nháp render một form phẳng riêng nên nhìn không
    // giống biên bản bên Odoo.
    final readOnly = !r.isDraft;
    return Stack(
      children: [
        _buildFormBody(r, readOnly),
        if (_busy)
          Container(
            color: Colors.black.withValues(alpha: 0.06),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  /// Một hàng field: đọc-thuần khi [readOnly], ô nhập khi còn nháp.
  Widget _row(
    bool readOnly,
    String label,
    String value,
    ValueChanged<String> onChanged, {
    bool required = false,
    bool mono = false,
    TextInputType? keyboard,
    int maxLines = 1,
  }) {
    if (readOnly) return InfoRow(label, value, mono: mono);
    return InfoEditRow(
      label,
      value,
      (v) {
        onChanged(v);
        _markDirty();
      },
      required: required,
      keyboard: keyboard,
      maxLines: maxLines,
    );
  }

  /// Hàng field ngày (`customer_rep_id_date`): hiển thị kiểu VN, chạm để mở
  /// date-picker khi còn nháp. Giá trị giữ nguyên chuỗi ISO để gửi lên backend.
  Widget _dateRow(
    bool readOnly,
    String label,
    String isoValue,
    ValueChanged<String> onChanged, {
    bool required = false,
  }) {
    if (readOnly) return InfoRow(label, formatVn(isoValue));
    return InfoRow(
      required ? '$label *' : label,
      formatVn(isoValue).isEmpty ? 'Chọn ngày' : formatVn(isoValue),
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.tryParse(isoValue) ?? now,
          firstDate: DateTime(now.year - 60),
          lastDate: DateTime(now.year + 5),
        );
        if (picked == null) return;
        setState(() {
          onChanged(picked.toIso8601String().substring(0, 10));
          _markDirty();
        });
      },
    );
  }

  Widget _buildFormBody(SamplingReportDetail r, bool readOnly) {
    // Mục 2 formview Odoo là bảng "Người lấy mẫu | Chức vụ".
    final samplersFull = r.samplers
        .where((s) => s.name.trim().isNotEmpty)
        .toList();
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        OdooFormHeader(
          stateLabel: r.stateLabel,
          state: r.state,
          title: 'BIÊN BẢN XÁC NHẬN CÔNG VIỆC LẤY MẪU',
          subtitle: [
            HeaderSub('Hồ sơ', r.requestCode),
            HeaderSub('Kế hoạch', r.programCode, link: true),
          ],
          createdBy: r.createdBy,
          createdAt: metaDt(r.createdAt),
          updatedBy: r.updatedBy,
          updatedAt: metaDt(r.updatedAt),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
          child: Column(
            children: [
              InfoSection(
                title: '1. Đơn vị đề nghị lấy mẫu (Khách hàng)',
                children: [
                  InfoRow('Tên khách hàng', r.partnerName),
                  _row(
                    readOnly,
                    'Địa chỉ khách hàng',
                    r.customerAddress,
                    (v) => r.customerAddress = v,
                  ),
                  const InfoSubhead('Đại diện khách hàng'),
                  _row(
                    readOnly,
                    'Ông / Bà',
                    r.customerRepName,
                    (v) => r.customerRepName = v,
                    required: true,
                  ),
                  _row(
                    readOnly,
                    'Chức vụ',
                    r.customerRepTitle,
                    (v) => r.customerRepTitle = v,
                    required: true,
                  ),
                  _row(
                    readOnly,
                    'Số CCCD',
                    r.customerRepIdCard,
                    (v) => r.customerRepIdCard = v,
                    required: true,
                    mono: true,
                    keyboard: TextInputType.number,
                  ),
                  _dateRow(
                    readOnly,
                    'Ngày cấp',
                    r.customerRepIdDate,
                    (v) => r.customerRepIdDate = v,
                    required: true,
                  ),
                  _row(
                    readOnly,
                    'Địa chỉ CCCD',
                    r.customerRepAddress,
                    (v) => r.customerRepAddress = v,
                    required: true,
                  ),
                  _row(
                    readOnly,
                    'Điện thoại',
                    r.customerRepPhone,
                    (v) => r.customerRepPhone = v,
                    required: true,
                    keyboard: TextInputType.phone,
                  ),
                  const InfoSubhead('Địa điểm lấy mẫu'),
                  InfoRow('Địa điểm và địa chỉ lấy mẫu', r.samplingLocation),
                  _row(
                    readOnly,
                    'Địa điểm và địa chỉ lấy mẫu (thực tế)',
                    r.samplingLocationActual,
                    (v) => r.samplingLocationActual = v,
                    required: true,
                    maxLines: 2,
                  ),
                ],
              ),
              // 2. Đơn vị lấy mẫu — ghi chú đơn vị + bảng "Người lấy mẫu |
              // Chức vụ" (đúng list `sampler_public_ids` của Odoo).
              LineTable(
                title: '2. Đơn vị lấy mẫu',
                leading: const [
                  InfoNote(
                    'Công ty TNHH Dịch vụ Tư vấn Công nghệ Môi trường ETECH\n'
                    '172 Ngô Quyền, Kinh Bắc, Bắc Ninh',
                  ),
                ],
                columns: const [
                  LineCol('Người lấy mẫu', width: 190),
                  LineCol('Chức vụ', width: 160),
                ],
                rows: [
                  for (final sp in samplersFull) [sp.name, sp.jobTitle],
                ],
              ),
              InfoSection(
                title: '3. Đơn vị giám sát (nếu có)',
                children: [
                  const InfoSubhead('Giám sát viên 01'),
                  InfoRow('Họ tên', r.supervisor1Name),
                  InfoRow('Chức vụ', r.supervisor1Title),
                  InfoRow('Cơ quan', r.supervisor1Org),
                  InfoRow('Địa chỉ', r.supervisor1Address),
                  const InfoSubhead('Giám sát viên 02'),
                  InfoRow('Họ tên', r.supervisor2Name),
                  InfoRow('Chức vụ', r.supervisor2Title),
                  InfoRow('Cơ quan', r.supervisor2Org),
                  InfoRow('Địa chỉ', r.supervisor2Address),
                ],
              ),
              InfoSection(
                title: '4. Thông tin phương tiện / mẫu',
                children: [
                  // Nhóm "Yêu cầu" là readonly="1" ở mọi trạng thái bên Odoo
                  // (link từ phiếu yêu cầu) → app cũng chỉ đọc.
                  const InfoSubhead(
                    'Yêu cầu (Link từ phiếu yêu cầu)',
                    icon: Icons.link_rounded,
                  ),
                  InfoRow('Biển số xe', r.vehiclePlate, mono: true),
                  InfoRow('Mã số container', r.containerCode, mono: true),
                  InfoRow('Biển số Rmooc', r.trailerPlate, mono: true),
                  InfoRow('Mã vùng trồng', r.plantingAreaCode, mono: true),
                  InfoRow(
                    'Mã cơ sở đóng gói',
                    r.packingFacilityCode,
                    mono: true,
                  ),
                  const InfoSubhead(
                    'Thực tế (Cập nhật tại chỗ)',
                    icon: Icons.edit_outlined,
                  ),
                  _row(
                    readOnly,
                    'Biển số xe',
                    r.vehiclePlateActual,
                    (v) => r.vehiclePlateActual = v,
                    required: true,
                    mono: true,
                  ),
                  _row(
                    readOnly,
                    'Mã số container',
                    r.containerCodeActual,
                    (v) => r.containerCodeActual = v,
                    required: true,
                    mono: true,
                  ),
                  _row(
                    readOnly,
                    'Biển số Rmooc',
                    r.trailerPlateActual,
                    (v) => r.trailerPlateActual = v,
                    required: true,
                    mono: true,
                  ),
                  InfoRow(
                    'Tên / Loại mẫu',
                    [
                      r.sampleName,
                      r.sampleType,
                    ].where((e) => e.isNotEmpty).join(' / '),
                  ),
                  InfoRow('Mã niêm phong (Kẹp chì)', r.sealNumber),
                ],
              ),
              // 5. Nội dung công việc lấy mẫu — GIỮ NGUYÊN dạng bảng list như
              // Odoo web responsive: dưới 992px `.o_field_x2many` chỉ cuộn
              // ngang (`table.o_list_table { min-width: 600px }`), KHÔNG stack
              // thành thẻ. Cột "#" bóp còn 28px; Loại mẫu / Tên mẫu / Số tem
              // niêm phong canh giữa (`sampling_program_paper.scss`).
              LineTable(
                title: '5. Nội dung công việc lấy mẫu',
                idxWidth: 28,
                showWhenEmpty: true,
                columns: const [
                  LineCol('Loại mẫu', width: 110, center: true),
                  LineCol('Tên mẫu', width: 140, center: true),
                  LineCol('Mã số mẫu (ký hiệu mẫu ban đầu)', width: 220),
                  LineCol('Mô tả mẫu', width: 320),
                  LineCol('Chỉ tiêu phân tích', width: 200),
                  LineCol('Số tem niêm phong', width: 140, center: true),
                ],
                rows: const [],
                cellRows: [
                  for (final l in r.lines)
                    [
                      _plainCell(l.sampleTypeCode, center: true),
                      _plainCell(l.name, center: true),
                      _codeCell(l.originalCode),
                      _descCell(l, readOnly),
                      _tagsCell(l.parameters),
                      _plainCell(l.sealStampNo, center: true),
                    ],
                ],
              ),
              InfoSection(
                title: '6. Số lượng mẫu thử nghiệm',
                children: [
                  InfoRow('Số lượng mẫu thử nghiệm', r.sampleCountDisplay),
                ],
              ),
              LineTable(
                title: '7. Phương pháp lấy mẫu',
                columns: const [
                  LineCol('Loại mẫu', width: 200),
                  LineCol('Tên / số hiệu phương pháp', width: 200),
                ],
                rows: [
                  for (final m in r.methods) [m.sampleType, m.sopCode],
                ],
              ),
              InfoSection(
                title: '8. Nhận xét khác (nếu có)',
                children: [
                  _row(
                    readOnly,
                    'Nhận xét khác (nếu có)',
                    r.otherRemarks,
                    (v) => r.otherRemarks = v,
                    maxLines: 3,
                  ),
                ],
              ),
              InfoSection(
                title: '9. Điều kiện môi trường',
                children: [
                  if (readOnly)
                    InfoRow(
                      'Điều kiện môi trường',
                      r.envCondition == 'khac'
                          ? r.envConditionOther
                          : _envLabel(r.envCondition),
                    )
                  else
                    InfoEditSelect(
                      'Điều kiện môi trường',
                      r.envCondition,
                      [
                        for (final o in _options?.envCondition ?? const [])
                          (o.value, o.label),
                      ],
                      (v) => setState(() {
                        r.envCondition = v ?? '';
                        _markDirty();
                      }),
                    ),
                  if (!readOnly && r.envCondition == 'khac')
                    _row(
                      readOnly,
                      'Điều kiện môi trường khác',
                      r.envConditionOther,
                      (v) => r.envConditionOther = v,
                      required: true,
                    ),
                ],
              ),
              InfoSection(
                title: '10. Thời gian lưu mẫu',
                children: [InfoRow('Thời gian lưu mẫu', r.storageDuration)],
              ),
              // 11. Thời gian lấy mẫu + 12. câu xác nhận (cùng card như Odoo).
              LineTable(
                title: '11. Thời gian lấy mẫu',
                columns: const [
                  LineCol('Thời gian bắt đầu', width: 200),
                  LineCol('Thời gian kết thúc', width: 200),
                ],
                rows: [
                  for (final d in r.dates) [d.start, d.end],
                ],
                extra: [
                  InfoSentence(
                    before: '12. Biên bản lập hồi ',
                    value: r.completionLabel,
                    after: ' để xác nhận lấy mẫu đã hoàn thành.',
                  ),
                ],
              ),
              // Thứ tự cuối form theo Odoo: 13. Ảnh hiện trường → 14. Toạ độ.
              if (readOnly)
                _PhotoSection(
                  report: r,
                  columns: _options?.photoColumns ?? const [],
                  headers: _imgHeaders,
                )
              else
                InfoSection(
                  title: '13. Ảnh hiện trường',
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                      child: Column(
                        children: [
                          for (final col in _options?.photoColumns ?? const [])
                            _photoColumn(r, col),
                        ],
                      ),
                    ),
                  ],
                ),
              InfoSection(
                title: '14. Toạ độ lấy mẫu thực tế',
                children: [_gpsRow(r, readOnly)],
              ),
              _signatureBlock(r, readOnly),
            ],
          ),
        ),
      ],
    );
  }

  /// Khối chữ ký cuối formview Odoo (3 ô: KH / đơn vị giám sát / đơn vị lấy
  /// mẫu). Chỉ có phần HỌ TÊN — ảnh chữ ký chưa hiển thị được.
  // TODO(backend): /api/sampling/reports/<id> chưa trả customer_signature /
  // supervisor_signature / technician_signature (và chưa có endpoint ghi chữ
  // ký) → bỏ được TODO này khi API bổ sung 3 field ảnh đó.
  Widget _signatureBlock(SamplingReportDetail r, bool readOnly) {
    return InfoSection(
      title: 'Chữ ký xác nhận',
      children: [
        const InfoSubhead('Đại diện khách hàng'),
        _row(
          readOnly,
          'Ký, ghi rõ họ tên',
          r.customerSignerName,
          (v) => r.customerSignerName = v,
        ),
        const InfoSubhead('ĐD. Đơn vị giám sát'),
        InfoRow('Ký, ghi rõ họ tên', r.supervisorSignerName),
        const InfoSubhead('ĐD. Đơn vị lấy mẫu'),
        InfoRow('Ký, ghi rõ họ tên', r.technicianName),
      ],
    );
  }

  String _envLabel(String value) {
    if (value.isEmpty) return '';
    final opts = _options?.envCondition ?? const [];
    for (final o in opts) {
      if (o.value == value) return o.label;
    }
    return value;
  }

  // ── widget helpers ────────────────────────────────────────────────

  Widget _field(
    String label,
    String value,
    ValueChanged<String> onChanged, {
    bool readOnly = false,
    TextInputType? keyboard,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        initialValue: value,
        readOnly: readOnly,
        keyboardType: keyboard,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        style: TextStyle(
          fontSize: AppType.bodyLg,
          color: readOnly ? AppColors.inkSoft : AppColors.ink,
        ),
        onChanged: (v) {
          onChanged(v);
          _markDirty();
        },
        decoration: appInputDecoration(label: label, readOnly: readOnly),
      ),
    );
  }

  Widget _dropdown(
    String label,
    String value,
    List<SelectOption> options,
    ValueChanged<String?> onChanged, {
    bool readOnly = false,
  }) {
    final values = options.map((o) => o.value).toSet();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: values.contains(value) ? value : null,
        decoration: appInputDecoration(label: label, readOnly: readOnly),
        items: options
            .map((o) => DropdownMenuItem(value: o.value, child: Text(o.label)))
            .toList(),
        onChanged: readOnly ? null : onChanged,
      ),
    );
  }

  void _copyCoords(SamplingReportDetail r) {
    // Định dạng "lat,lon" dán thẳng được vào Google Maps / app bản đồ.
    final text =
        '${r.geoLat.toStringAsFixed(6)},${r.geoLon.toStringAsFixed(6)}';
    Clipboard.setData(ClipboardData(text: text));
    _toast('Đã sao chép toạ độ: $text');
  }

  Widget _gpsRow(SamplingReportDetail r, bool readOnly) {
    final hasGps = r.geoLat != 0.0 || r.geoLon != 0.0;
    // Không tự vẽ khung: widget này nằm trong card "14. Toạ độ lấy mẫu thực tế".
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.my_location_rounded,
                size: 20,
                color: hasGps ? AppColors.success : AppColors.inkMuted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Toạ độ minh chứng',
                      style: TextStyle(
                        fontSize: AppType.caption,
                        color: AppColors.inkMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasGps
                          ? '${r.geoLat.toStringAsFixed(6)}, ${r.geoLon.toStringAsFixed(6)}'
                          : 'Chưa có toạ độ',
                      style: TextStyle(
                        fontSize: AppType.body,
                        fontWeight: FontWeight.w700,
                        color: hasGps ? AppColors.ink : AppColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (!readOnly)
                TextButton.icon(
                  onPressed: _captureGps,
                  icon: Icon(
                    hasGps ? Icons.refresh_rounded : Icons.gps_fixed_rounded,
                    size: 18,
                  ),
                  label: Text(hasGps ? 'Cập nhật' : 'Lấy GPS'),
                ),
            ],
          ),
          if (hasGps)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _copyCoords(r),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, AppType.minTapTarget),
                  foregroundColor: AppColors.inkSoft,
                ),
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Sao chép toạ độ (mở bằng Google Maps)'),
              ),
            ),
        ],
      ),
    );
  }

  // ── Mục 5: các ô của bảng, khớp widget tương ứng bên Odoo ──────────

  Widget _plainCell(String text, {bool center = false}) => Text(
    text,
    textAlign: center ? TextAlign.center : TextAlign.start,
    style: TextStyle(
      fontSize: AppType.body,
      color: AppColors.inkSoft,
      height: 1.35,
    ),
  );

  /// Cột "Mã số mẫu" — widget `original_code_stacked`: mã mẹ ở trên, các mã
  /// con (chuỗi trong ngoặc do backend trả về) xếp dưới dạng pill.
  Widget _codeCell(String raw) {
    final open = raw.indexOf('(');
    final parent = (open < 0 ? raw : raw.substring(0, open)).trim();
    final children = open < 0
        ? const <String>[]
        : raw
              .substring(open + 1)
              .replaceAll(')', '')
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (parent.isNotEmpty)
          Text(
            parent,
            style: TextStyle(
              fontSize: AppType.body,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
              height: 1.35,
            ),
          ),
        if (children.isNotEmpty) ...[
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [for (final c in children) _softPill(c)],
          ),
        ],
      ],
    );
  }

  /// Cột "Chỉ tiêu phân tích" — `many2many_tags` (pill xám nhạt mặc định).
  Widget _tagsCell(List<String> tags) {
    if (tags.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [for (final t in tags) _softPill(t)],
    );
  }

  Widget _softPill(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: AppColors.bg,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      border: Border.all(color: AppColors.border),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: AppType.caption,
        color: AppColors.inkSoft,
        height: 1.3,
      ),
    ),
  );

  /// Cột "Mô tả mẫu" — widget `sample_desc`: 4 mục đánh số ghi vào
  /// sample_status / packing / sample_weight+packing_unit / storage. Ở trạng
  /// thái chốt thì render y hệt nhưng chỉ-đọc (nhánh `isReadonly` của widget).
  Widget _descCell(SamplingLine line, bool readOnly) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _descItem(
          '1. Tình trạng mẫu khi nhận:',
          readOnly
              ? _plainCell(_optLabel(_options?.sampleStatus, line.sampleStatus))
              : _chips(
                  _options?.sampleStatus,
                  line.sampleStatus,
                  (v) => line.sampleStatus = v,
                ),
        ),
        _descItem(
          '2. Bao gói:',
          readOnly
              ? _plainCell(line.packing)
              : _field('', line.packing, (v) => line.packing = v, maxLines: 2),
        ),
        _descItem(
          '3. Khối lượng mẫu ban đầu/ Đơn vị bao gói (Quả/kg/gói):',
          readOnly
              ? _plainCell(
                  [
                    if (line.sampleWeight != 0) '${line.sampleWeight}',
                    _optLabel(_options?.packingUnit, line.packingUnit),
                  ].where((e) => e.isNotEmpty).join(' '),
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      // TODO(backend): `sample_weight` đang là Integer ở model.
                      // Cần thập phân thì đổi cả 2 phía rồi nới formatter.
                      child: _field(
                        '',
                        line.sampleWeight == 0 ? '' : '${line.sampleWeight}',
                        (v) => line.sampleWeight = int.tryParse(v) ?? 0,
                        keyboard: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _dropdown(
                        '',
                        line.packingUnit,
                        _options?.packingUnit ?? const [],
                        (v) {
                          setState(() {
                            line.packingUnit = v ?? '';
                            _markDirty();
                          });
                        },
                      ),
                    ),
                  ],
                ),
        ),
        _descItem(
          '4. Tình trạng lưu mẫu:',
          readOnly
              ? _plainCell(_optLabel(_options?.storage, line.storage))
              : _chips(
                  _options?.storage,
                  line.storage,
                  (v) => line.storage = v,
                ),
        ),
      ],
    );
  }

  /// Một mục `desc-item` của widget `sample_desc`: nhãn (kèm `*` đỏ) + nội dung.
  Widget _descItem(String label, Widget child) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            style: TextStyle(
              fontSize: AppType.caption,
              fontWeight: FontWeight.w600,
              color: AppColors.inkSoft,
              height: 1.4,
            ),
            children: [
              TextSpan(
                text: ' *',
                style: TextStyle(color: AppColors.danger),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    ),
  );

  /// `o_etech_chips` — chọn một trong các giá trị selection.
  Widget _chips(
    List<SelectOption>? options,
    String value,
    ValueChanged<String> onChanged,
  ) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final o in options ?? const <SelectOption>[])
          ChoiceChip(
            label: Text(o.label),
            labelStyle: TextStyle(fontSize: AppType.caption),
            visualDensity: VisualDensity.compact,
            selected: o.value == value,
            onSelected: (_) => setState(() {
              onChanged(o.value);
              _markDirty();
            }),
          ),
      ],
    );
  }

  String _optLabel(List<SelectOption>? options, String value) {
    for (final o in options ?? const <SelectOption>[]) {
      if (o.value == value) return o.label;
    }
    return value;
  }

  Widget _photoColumn(SamplingReportDetail r, SelectOption col) {
    final photos = r.photos[col.value] ?? [];
    final readOnly = !r.isDraft;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  col.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: AppType.body,
                  ),
                ),
              ),
              Text(
                '${photos.length}',
                style: TextStyle(color: AppColors.inkMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...photos.map((p) => _photoThumb(p, readOnly)),
              if (!readOnly)
                InkWell(
                  onTap: () => _addPhoto(col.value),
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Icon(
                      Icons.add_a_photo_outlined,
                      color: AppColors.inkMuted,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _photoThumb(SamplingPhoto p, bool readOnly) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Image.network(
            '${AppConfig.odooUrl}${p.url}',
            headers: _imgHeaders,
            width: 72,
            height: 72,
            // Decode đúng cỡ hiển thị — ảnh camera gốc vài MP decode full sẽ
            // tốn RAM và gây giật khi cuộn.
            cacheWidth: (72 * MediaQuery.devicePixelRatioOf(context)).round(),
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              width: 72,
              height: 72,
              color: AppColors.bg,
              child: Icon(
                Icons.broken_image_outlined,
                color: AppColors.inkMuted,
              ),
            ),
          ),
        ),
        if (!readOnly)
          Positioned(
            top: 0,
            right: 0,
            child: Material(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(AppRadius.md),
                bottomLeft: Radius.circular(AppRadius.md),
              ),
              child: InkWell(
                onTap: () => _deletePhoto(p.id),
                child: const SizedBox(
                  width: 24,
                  height: 24,
                  child: Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Mục "13. Ảnh hiện trường" (read-mode): thanh tiêu đề tối + lưới ảnh theo nhóm.
class _PhotoSection extends StatelessWidget {
  final SamplingReportDetail report;
  final List<SelectOption> columns;
  final Map<String, String> headers;

  const _PhotoSection({
    required this.report,
    required this.columns,
    required this.headers,
  });

  @override
  Widget build(BuildContext context) {
    final groups = columns
        .where((c) => (report.photos[c.value] ?? const []).isNotEmpty)
        .toList();
    if (groups.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            color: AppColors.navy,
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            child: const Text(
              '13. Ảnh hiện trường',
              style: TextStyle(
                fontSize: AppType.subtitle,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final c in groups) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 6),
                    child: Text(
                      c.label,
                      style: TextStyle(
                        fontSize: AppType.body,
                        fontWeight: FontWeight.w700,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final p in report.photos[c.value] ?? const [])
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: Image.network(
                            '${AppConfig.odooUrl}${p.url}',
                            headers: headers,
                            width: 96,
                            height: 96,
                            cacheWidth:
                                (96 * MediaQuery.devicePixelRatioOf(context))
                                    .round(),
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              width: 96,
                              height: 96,
                              color: AppColors.bg,
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: AppColors.inkMuted,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton cho màn chi tiết khi đang tải — vài khối mô phỏng section + field.
class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
      children: const [
        SkeletonBox(
          width: 140,
          height: 16,
          margin: EdgeInsets.only(bottom: 14),
        ),
        SkeletonBox(
          height: 48,
          radius: AppRadius.md,
          margin: EdgeInsets.only(bottom: 12),
        ),
        SkeletonBox(
          height: 48,
          radius: AppRadius.md,
          margin: EdgeInsets.only(bottom: 12),
        ),
        SkeletonBox(
          height: 48,
          radius: AppRadius.md,
          margin: EdgeInsets.only(bottom: 24),
        ),
        SkeletonBox(
          width: 160,
          height: 16,
          margin: EdgeInsets.only(bottom: 14),
        ),
        SkeletonBox(
          height: 48,
          radius: AppRadius.md,
          margin: EdgeInsets.only(bottom: 12),
        ),
        SkeletonBox(
          height: 48,
          radius: AppRadius.md,
          margin: EdgeInsets.only(bottom: 12),
        ),
        SkeletonBox(height: 96, radius: AppRadius.md),
      ],
    );
  }
}
