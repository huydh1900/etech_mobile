import 'package:flutter/material.dart';
import '../config.dart';
import '../models/sampling.dart';
import '../services/sampling_service.dart';
import '../services/search_spec_service.dart';
import '../utils/vn_format.dart';
import '../widgets/module_list_scaffold.dart';
import '../widgets/record_card.dart';
import 'sampling_detail_screen.dart';

class SamplingListScreen extends StatefulWidget {
  final String sessionId;

  /// Mở tab Thông báo (chuông AppBar). null → ẩn chuông.
  final VoidCallback? onOpenNotifications;

  const SamplingListScreen({
    super.key,
    required this.sessionId,
    this.onOpenNotifications,
  });

  @override
  State<SamplingListScreen> createState() => _SamplingListScreenState();
}

class _SamplingListScreenState extends State<SamplingListScreen> {
  late final SamplingService _service;

  /// Đổi [_tick] để buộc [ModuleListScaffold] tải lại (sau khi sửa ở màn chi tiết).
  int _tick = 0;

  @override
  void initState() {
    super.initState();
    _service = SamplingService(
      baseUrl: AppConfig.odooUrl,
      sessionId: widget.sessionId,
    );
  }

  void _reload() => setState(() => _tick++);

  Future<void> _openDetail(int id) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            SamplingDetailScreen(sessionId: widget.sessionId, reportId: id),
      ),
    );
    if (changed == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return ModuleListScaffold<SamplingReportBrief>(
      key: ValueKey(_tick),
      title: 'Biên bản hiện trường',
      permissionModel: 'etech.sampling.report',
      searchSpec: () =>
          SearchSpecService.load(widget.sessionId, 'etech.sampling.report'),
      searchHint: 'Tìm số biên bản, khách hàng, mẫu…',
      onOpenNotifications: widget.onOpenNotifications,
      unitLabel: 'biên bản',
      emptyIcon: Icons.description_outlined,
      emptyTitle: 'Chưa có biên bản nào',
      emptyMessage: 'Biên bản hiện trường sẽ hiển thị tại đây.',
      fetch: ({state, query, required offset, required limit, params}) =>
          _service.getReports(
            query: query,
            offset: offset,
            limit: limit,
            params: params,
          ),
      itemBuilder: (context, r) => RecordCard(
        title: r.code,
        state: r.state,
        stateLabel: r.stateLabel,
        subtitle: r.partnerName,
        refs: [
          (Icons.science_outlined, r.sampleName),
          (Icons.place_outlined, r.samplingLocation),
          (Icons.event_outlined, formatVn(r.actualDate)),
          (Icons.inventory_2_outlined, '${r.sampleCount} mẫu'),
        ],
        onTap: () => _openDetail(r.id),
      ),
    );
  }
}
