// Khung điện thoại giả cho lúc dev trên web/desktop: bọc app trong một
// viewport đúng kích thước iPhone 17 Pro Max (440×956) kèm bezel, dynamic island,
// status bar và home indicator — để xem layout "giống thật" mà không cần
// emulator. KHÔNG ảnh hưởng build mobile thật (xem [kPhoneFrameEnabled]).
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Kích thước viewport giả lập (logical px) — iPhone 17 Pro Max.
const Size kPhoneSize = Size(440, 956);
const EdgeInsets kPhonePadding = EdgeInsets.only(top: 62, bottom: 34);
const String kPhoneName = 'iPhone 17 Pro Max';
const String kPhoneOs = 'iOS 26.3';

/// Tắt khung bằng: `flutter run -d chrome --dart-define=PHONE_FRAME=false`.
const bool _phoneFrameFlag = bool.fromEnvironment(
  'PHONE_FRAME',
  defaultValue: true,
);

// Dùng defaultTargetPlatform (không phải dart:io) vì file này compile cả cho web.
bool get _isDesktopOrWeb =>
    kIsWeb ||
    defaultTargetPlatform == TargetPlatform.linux ||
    defaultTargetPlatform == TargetPlatform.macOS ||
    defaultTargetPlatform == TargetPlatform.windows;

/// Chỉ bật khi chạy web/desktop (mobile thật không bao giờ bọc khung).
bool get kPhoneFrameEnabled => _phoneFrameFlag && _isDesktopOrWeb;

class PhoneFrame extends StatelessWidget {
  final Widget child;

  const PhoneFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final outer = MediaQuery.of(context);
    // Cửa sổ đã nhỏ như điện thoại → dùng thẳng, khỏi bọc khung.
    if (!kPhoneFrameEnabled || outer.size.width < kPhoneSize.width + 80) {
      return child;
    }

    const bezel = 11.0;
    final phone = Container(
      padding: const EdgeInsets.all(bezel),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(66),
        // Viền khung titan mỏng bao ngoài bezel đen.
        border: Border.all(color: const Color(0xFF5A5D63), width: 3),
        boxShadow: const [
          BoxShadow(color: Color(0x66000000), blurRadius: 40, spreadRadius: 4),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(55),
        child: SizedBox(
          width: kPhoneSize.width,
          height: kPhoneSize.height,
          child: MediaQuery(
            // App bên trong "tin" rằng nó đang ở màn điện thoại: đổi cả size
            // lẫn padding để SafeArea/LayoutBuilder hoạt động như máy thật.
            data: outer.copyWith(
              size: kPhoneSize,
              padding: kPhonePadding,
              viewPadding: kPhonePadding,
              viewInsets: EdgeInsets.zero,
              devicePixelRatio: 3,
            ),
            child: Stack(
              children: [
                Positioned.fill(child: child),
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _StatusBar(),
                ),
                const Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _HomeIndicator(),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Status bar giả + thanh Simulator vẽ NGOÀI Scaffold của app → không có
    // DefaultTextStyle, Text bị gạch chân vàng (cảnh báo debug). Material
    // trong suốt cung cấp text style theo theme.
    return Material(
      type: MaterialType.transparency,
      child: ColoredBox(
        color: const Color(0xFF2B2F36),
        child: Center(
          child: FittedBox(
            // Cửa sổ thấp hơn chiều cao máy → thu nhỏ cả khung thay vì cắt.
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _SimulatorBar(),
                  const SizedBox(height: 14),
                  phone,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Status bar giả (giờ + dynamic island + sóng/wifi/pin).
class _StatusBar extends StatelessWidget {
  const _StatusBar();

  @override
  Widget build(BuildContext context) {
    final now = TimeOfDay.now();
    final time = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
    // Màu chữ theo nền phía sau: lấy từ overlay style app đang đặt.
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.white : const Color(0xFF0F172A);

    return SizedBox(
      height: kPhonePadding.top,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 11,
            child: Container(
              width: 126,
              height: 37,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 34),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    color: fg,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.signal_cellular_alt_rounded,
                      size: 16,
                      color: fg,
                    ),
                    const SizedBox(width: 5),
                    Icon(Icons.wifi_rounded, size: 16, color: fg),
                    const SizedBox(width: 5),
                    Icon(Icons.battery_full_rounded, size: 17, color: fg),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Thanh tiêu đề kiểu cửa sổ Simulator (đèn giao thông + tên máy/iOS).
class _SimulatorBar extends StatelessWidget {
  const _SimulatorBar();

  @override
  Widget build(BuildContext context) {
    Widget dot(Color c) => Container(
      width: 12,
      height: 12,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(color: c, shape: BoxShape.circle),
    );
    return Container(
      width: kPhoneSize.width + 28,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2127),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF3A3F47)),
      ),
      child: Row(
        children: [
          dot(const Color(0xFFFF5F57)),
          dot(const Color(0xFFFEBC2E)),
          dot(const Color(0xFF28C840)),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                kPhoneName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                kPhoneOs,
                style: TextStyle(color: Color(0xFF9AA0A6), fontSize: 11),
              ),
            ],
          ),
          const Spacer(),
          const Icon(Icons.home_outlined, color: Colors.white70, size: 20),
          const SizedBox(width: 14),
          const Icon(
            Icons.photo_camera_outlined,
            color: Colors.white70,
            size: 20,
          ),
          const SizedBox(width: 14),
          const Icon(
            Icons.screen_rotation_outlined,
            color: Colors.white70,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _HomeIndicator extends StatelessWidget {
  const _HomeIndicator();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: kPhonePadding.bottom,
      child: Center(
        child: Container(
          width: 140,
          height: 5,
          decoration: BoxDecoration(
            color: (dark ? Colors.white : Colors.black).withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}
