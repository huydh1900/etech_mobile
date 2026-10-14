import 'package:flutter/material.dart';
import '../models/search_spec.dart';
import '../theme/app_theme.dart';
import '../utils/vn_format.dart';

/// ───────────────────────────────────────────────────────────────────────────
/// BỘ LỌC & NHÓM THEO dùng chung cho list mobile (theo search view Odoo — xem
/// [SearchSpec]). [PagedListView] tự gắn khi có `searchSpec`; các mảnh dưới
/// đây chỉ lo UI: nút lọc có badge, hàng chip đang bật, bottom sheet.
/// ───────────────────────────────────────────────────────────────────────────

String _vnDate(DateTime d) => formatVn(d.toIso8601String().substring(0, 10));

/// Nút lọc vuông cạnh ô search, badge = số mục lọc/nhóm đang bật.
class SearchFilterButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const SearchFilterButton({
    super.key,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = count > 0;
    return Semantics(
      button: true,
      label: active ? 'Bộ lọc, $count đang bật' : 'Bộ lọc',
      child: Material(
        color: active ? AppColors.primary : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(
            color: active ? AppColors.primary : AppColors.border,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: SizedBox(
            width: 46,
            height: 46,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.tune_rounded,
                  size: 21,
                  color: active ? Colors.white : AppColors.inkSoft,
                ),
                if (active)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 16,
                      height: 16,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Mở bottom sheet Bộ lọc & Nhóm theo. Trả [ListQuery] mới khi bấm "Áp dụng";
/// đóng ngang → null (giữ nguyên).
Future<ListQuery?> showSearchPanel(
  BuildContext context,
  SearchSpec spec,
  ListQuery current,
) {
  return showModalBottomSheet<ListQuery>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (_) => _SearchPanelSheet(spec: spec, initial: current),
  );
}

/// Hàng chip lựa chọn đang bật — bấm × để bỏ từng mục, "Xóa tất cả" để reset.
class ActiveQueryBar extends StatelessWidget {
  final SearchSpec spec;
  final ListQuery query;
  final ValueChanged<ListQuery> onChanged;
  const ActiveQueryBar({
    super.key,
    required this.spec,
    required this.query,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final q = query;
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
        children: [
          // Facet tìm kiếm: 1 chip/trường, nhiều giá trị nối "hoặc" (như Odoo).
          for (final field in q.facetFields)
            _RemovableChip(
              icon: Icons.search_rounded,
              label:
                  '${spec.labelOf(field)}: '
                  '${q.valuesOf(field).join(' hoặc ')}',
              onRemove: () => onChanged(q.removeField(field)),
            ),
          for (final f in q.filters)
            _RemovableChip(
              icon: Icons.filter_alt_outlined,
              label: spec.labelOf(f),
              onRemove: () =>
                  onChanged(q.copyWith(filters: {...q.filters}..remove(f))),
            ),
          if (q.hasDate)
            _RemovableChip(
              icon: Icons.event_outlined,
              label:
                  '${spec.labelOf(q.date!)}: '
                  '${q.dateFrom != null ? _vnDate(q.dateFrom!) : '…'}'
                  ' – ${q.dateTo != null ? _vnDate(q.dateTo!) : '…'}',
              onRemove: () => onChanged(q.clearDate()),
            ),
          if (q.groupBy != null)
            _RemovableChip(
              icon: Icons.layers_outlined,
              label: 'Nhóm: ${spec.labelOf(q.groupBy!)}',
              onRemove: () => onChanged(q.copyWith(groupBy: () => null)),
            ),
          TextButton(
            onPressed: () => onChanged(const ListQuery()),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              foregroundColor: AppColors.danger,
            ),
            child: const Text(
              'Xóa tất cả',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet "Bộ lọc" + "Nhóm theo" theo [SearchSpec] (search view Odoo,
/// bỏ "Bộ lọc tuỳ chỉnh" / "Nhóm tùy chỉnh").
class _SearchPanelSheet extends StatefulWidget {
  final SearchSpec spec;
  final ListQuery initial;
  const _SearchPanelSheet({required this.spec, required this.initial});

  @override
  State<_SearchPanelSheet> createState() => _SearchPanelSheetState();
}

class _SearchPanelSheetState extends State<_SearchPanelSheet> {
  late ListQuery _q = widget.initial;

  static DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  // Preset nhanh cho lọc ngày: (nhãn, từ, đến).
  List<(String, DateTime, DateTime)> get _presets {
    final t = _today;
    return [
      ('Hôm nay', t, t),
      ('7 ngày qua', t.subtract(const Duration(days: 6)), t),
      ('Tháng này', DateTime(t.year, t.month, 1), t),
      (
        'Tháng trước',
        DateTime(t.year, t.month - 1, 1),
        DateTime(t.year, t.month, 0),
      ),
    ];
  }

  // Lọc ngày chỉ áp 1 filter ngày tại 1 thời điểm (như Odoo chọn 1 kỳ).
  DateTime? _from(String date) => _q.date == date ? _q.dateFrom : null;
  DateTime? _to(String date) => _q.date == date ? _q.dateTo : null;

  void _setRange(String date, DateTime? from, DateTime? to) {
    setState(
      () => _q = from == null && to == null
          ? _q.clearDate()
          : _q.copyWith(
              date: () => date,
              dateFrom: () => from,
              dateTo: () => to,
            ),
    );
  }

  Future<void> _pickDate(String date, {required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFrom ? _from(date) : _to(date)) ?? _today,
      firstDate: DateTime(2020),
      lastDate: DateTime(_today.year + 1, 12, 31),
    );
    if (picked == null) return;
    var from = _from(date), to = _to(date);
    if (isFrom) {
      from = picked;
      if (to != null && to.isBefore(picked)) to = picked;
    } else {
      to = picked;
      if (from != null && from.isAfter(picked)) from = picked;
    }
    _setRange(date, from, to);
  }

  Widget _sectionTitle(IconData icon, Color color, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontFamily: kBrandFont,
            fontSize: AppType.subtitle,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
      ],
    ),
  );

  Widget _dateSection(SpecItem d) {
    final from = _from(d.name), to = _to(d.name);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 18),
        _SheetLabel(d.label),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (label, pf, pt) in _presets)
              _ChoicePill(
                label: label,
                selected: from == pf && to == pt,
                onTap: () {
                  final same = _from(d.name) == pf && _to(d.name) == pt;
                  _setRange(d.name, same ? null : pf, same ? null : pt);
                },
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _DateBox(
                label: 'Từ ngày',
                value: from,
                onTap: () => _pickDate(d.name, isFrom: true),
                onClear: () => _setRange(d.name, null, _to(d.name)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: AppColors.inkMuted,
              ),
            ),
            Expanded(
              child: _DateBox(
                label: 'Đến ngày',
                value: to,
                onTap: () => _pickDate(d.name, isFrom: false),
                onClear: () => _setRange(d.name, _from(d.name), null),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final spec = widget.spec;
    final activeCount = _q.activeCount;
    final hasFilters = spec.filters.isNotEmpty || spec.dates.isNotEmpty;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Bộ lọc & Nhóm theo',
                  style: TextStyle(
                    fontFamily: kBrandFont,
                    fontSize: AppType.subtitle + 2,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close_rounded, color: AppColors.inkMuted),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: AppColors.divider),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            children: [
              if (hasFilters) ...[
                _sectionTitle(
                  Icons.filter_alt_rounded,
                  AppColors.violet,
                  'Bộ lọc',
                ),
                for (final (i, block) in spec.filters.indexed) ...[
                  if (i > 0) const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final f in block)
                        _ChoicePill(
                          label: f.label,
                          selected: _q.filters.contains(f.name),
                          onTap: () => setState(
                            () => _q = _q.copyWith(
                              filters: _q.filters.contains(f.name)
                                  ? ({..._q.filters}..remove(f.name))
                                  : {..._q.filters, f.name},
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                for (final d in spec.dates) _dateSection(d),
              ],
              if (hasFilters && spec.groups.isNotEmpty) ...[
                const SizedBox(height: 18),
                Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: 18),
              ],
              if (spec.groups.isNotEmpty) ...[
                _sectionTitle(
                  Icons.layers_rounded,
                  AppColors.teal,
                  'Nhóm theo',
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final g in spec.groups)
                      _ChoicePill(
                        label: g.label,
                        selected: _q.groupBy == g.name,
                        onTap: () => setState(
                          () => _q = _q.copyWith(
                            groupBy: () => _q.groupBy == g.name ? null : g.name,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        // Footer: Xóa · Áp dụng
        Container(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            12 + MediaQuery.of(context).padding.bottom,
          ),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.divider)),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: activeCount == 0
                      ? null
                      : () => setState(() => _q = const ListQuery()),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: const Text('Xóa lọc'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, _q),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: Text(
                    activeCount == 0 ? 'Áp dụng' : 'Áp dụng ($activeCount)',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RemovableChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onRemove;
  const _RemovableChip({
    required this.icon,
    required this.label,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Container(
        padding: const EdgeInsets.only(left: 10),
        decoration: BoxDecoration(
          color: AppColors.tealSoft,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.teal),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: AppType.caption,
                fontWeight: FontWeight.w600,
                color: AppColors.teal,
              ),
            ),
            InkWell(
              onTap: onRemove,
              customBorder: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  Icons.close_rounded,
                  size: 15,
                  color: AppColors.teal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetLabel extends StatelessWidget {
  final String text;
  const _SheetLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: AppType.bodyLg,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
      ),
    );
  }
}

class _ChoicePill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ChoicePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? AppColors.tealSoft : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: selected ? AppColors.teal : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(Icons.check_rounded, size: 16, color: AppColors.teal),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: AppType.body,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.teal : AppColors.inkSoft,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateBox extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback onClear;
  const _DateBox({
    required this.label,
    required this.value,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        height: 52,
        padding: const EdgeInsets.only(left: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: AppColors.inkMuted,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: AppType.micro,
                      color: AppColors.inkMuted,
                    ),
                  ),
                  Text(
                    value == null ? 'Chọn ngày' : _vnDate(value!),
                    style: TextStyle(
                      fontSize: AppType.body,
                      fontWeight: FontWeight.w600,
                      color: value == null ? AppColors.inkMuted : AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
            if (value != null)
              IconButton(
                onPressed: onClear,
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: AppColors.inkMuted,
                ),
              )
            else
              const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}

/// Gợi ý kiểu ô search Odoo: `Tìm <Trường> cho: <text>` cho từng trường của
/// search view; chọn 1 dòng → thêm facet. Dòng đầu = mặc định khi bấm Enter.
class SearchSuggestions extends StatelessWidget {
  final String text;
  final List<SearchField> fields;
  final ValueChanged<SearchField> onPick;
  const SearchSuggestions({
    super.key,
    required this.text,
    required this.fields,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 360),
        child: Material(
          type: MaterialType.transparency,
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: fields.length,
            separatorBuilder: (_, _) =>
                Divider(height: 1, color: AppColors.divider),
            itemBuilder: (context, i) {
              final f = fields[i];
              return InkWell(
                onTap: () => onPick(f),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        i == 0
                            ? Icons.subdirectory_arrow_right_rounded
                            : Icons.search_rounded,
                        size: 18,
                        color: i == 0 ? AppColors.primary : AppColors.inkMuted,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'Tìm ',
                                style: TextStyle(color: AppColors.inkMuted),
                              ),
                              TextSpan(
                                text: f.label,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                              TextSpan(
                                text: ' cho: ',
                                style: TextStyle(color: AppColors.inkMuted),
                              ),
                              TextSpan(
                                text: text,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: AppType.body),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
