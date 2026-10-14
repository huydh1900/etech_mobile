import 'package:flutter/material.dart';
import '../config.dart';
import '../models/service_request.dart' show CustomerBrief, CustomerDetail;
import '../services/customer_service.dart';
import '../widgets/detail_kit.dart';
import '../widgets/module_list_scaffold.dart';
import '../widgets/odoo_web_clone.dart';

/// ───────────────────────────────────────────────────────────────────────────
/// MÀN HÌNH THAM CHIẾU (CANONICAL) — Khách hàng.
///
/// Đây là mẫu chuẩn cho các module khác copy:
/// - List: StatelessWidget, dựng [CustomerService] inline + [ModuleListScaffold].
/// - Detail: dùng [ModuleDetailScaffold] (tự lo loading/error/retry).
/// - Gating quyền: gate menu qua permissions.canSeeMenu ở router; gate dữ liệu
///   qua `permissionModel: 'res.partner'` trên ModuleListScaffold.
/// - Màu sắc/thẻ: token AppColors + status_chip; card = surface + border + lg.
/// ───────────────────────────────────────────────────────────────────────────

/// Clone kanban Odoo web (Khách hàng): thẻ avatar vuông màu + tên + email/điện
/// thoại (link teal) + quốc gia + tag MST. Toolbar "Mới", nút quét mã.
class CustomersListScreen extends StatefulWidget {
  final String sessionId;

  /// Mở tab Thông báo (chuông AppBar). null → ẩn chuông.
  final VoidCallback? onOpenNotifications;

  const CustomersListScreen({
    super.key,
    required this.sessionId,
    this.onOpenNotifications,
  });

  @override
  State<CustomersListScreen> createState() => _CustomersListScreenState();
}

class _CustomersListScreenState extends State<CustomersListScreen> {
  bool _search = false;

  @override
  Widget build(BuildContext context) {
    final service = CustomerService(
      baseUrl: AppConfig.odooUrl,
      sessionId: widget.sessionId,
    );
    return OdooCloneScaffold(
      title: 'Khách hàng',
      primaryButtonLabel: 'Mới',
      onOpenNotifications: widget.onOpenNotifications,
      onSearch: () => setState(() => _search = !_search),
      searchActive: _search,
      onScan: () {},
      body: OdooKanbanCardList<CustomerBrief>(
        showSearch: _search,
        searchHint: 'Tìm theo tên / MST…',
        emptyIcon: Icons.groups_outlined,
        emptyTitle: 'Không có khách hàng',
        fetch: ({state, query, required offset, required limit, params}) =>
            service.getCustomers(
              state: state,
              query: query,
              offset: offset,
              limit: limit,
            ),
        cardBuilder: (context, c) => OdooKanbanCard(
          avatarText: c.name.isNotEmpty ? c.name : '?',
          title: c.name,
          tag: c.vat.isNotEmpty ? c.vat : '',
          lines: [
            if (c.email.isNotEmpty)
              OdooKanbanLine(Icons.email_outlined, c.email, link: true),
            if (c.phone.isNotEmpty)
              OdooKanbanLine(Icons.phone_outlined, c.phone, link: true),
            if (c.city.isNotEmpty) OdooKanbanLine(Icons.place_outlined, c.city),
          ],
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CustomerDetailPage(
                sessionId: widget.sessionId,
                partnerId: c.id,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Chi tiết khách hàng — dùng [ModuleDetailScaffold].
class CustomerDetailPage extends StatelessWidget {
  final String sessionId;
  final int partnerId;
  const CustomerDetailPage({
    super.key,
    required this.sessionId,
    required this.partnerId,
  });

  @override
  Widget build(BuildContext context) {
    final service = CustomerService(
      baseUrl: AppConfig.odooUrl,
      sessionId: sessionId,
    );
    return ModuleDetailScaffold<CustomerDetail>(
      title: 'Khách hàng',
      load: () => service.getCustomer(partnerId),
      builder: (context, c, reload) {
        return DetailBody(
          header: DetailHeader(
            code: c.name,
            subtitle: c.isCompany ? 'Tổ chức' : 'Cá nhân',
          ),
          children: [
            // I. Thông tin chung — khớp formview res.partner (mobile rút gọn,
            // chỉ field liên hệ có nghĩa; form Odoo gốc rất lớn, không replicate).
            InfoSection(
              number: 1,
              title: 'Thông tin chung',
              icon: Icons.person_outline_rounded,
              children: [
                InfoRow(
                  'Loại',
                  c.isCompany ? 'Tổ chức' : 'Cá nhân',
                  radio: true,
                ),
                InfoRow('Tên khách hàng', c.name),
                InfoRow('Tên khách hàng (Tiếng Anh)', c.nameEn),
                InfoRow('Mã khách hàng', c.ref, mono: true),
                InfoRow('Mã số thuế', c.vat, mono: true),
                InfoRow('Người đại diện theo pháp luật', c.legalRepresentative),
                InfoRow('Người liên hệ', c.contactPerson),
                InfoRow('Chức vụ', c.function),
                InfoRow('Tổ chức', c.parentName),
                InfoRow('Điện thoại', c.phone),
                InfoRow('Email', c.email),
                InfoRow('Số hồ sơ', '${c.requestCount}'),
              ],
            ),
            InfoSection(
              number: 2,
              title: 'Địa chỉ',
              icon: Icons.place_outlined,
              children: [
                InfoRow('Quốc gia', c.countryName),
                InfoRow('Tỉnh/Thành phố', c.stateName),
                InfoRow('Phường/Xã', c.wardName),
                InfoRow('Địa chỉ cụ thể', c.street),
                InfoRow('Địa chỉ bổ sung', c.street2),
                InfoRow('Mã bưu chính', c.zip, mono: true),
              ],
            ),
          ],
        );
      },
    );
  }
}
