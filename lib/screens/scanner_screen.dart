import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../theme/app_theme.dart';

/// Màn hình quét mã vạch / QR. Trả về chuỗi giá trị quét được (hoặc null nếu
/// người dùng đóng màn hình mà không quét).
class ScannerScreen extends StatefulWidget {
  /// Tiêu đề hiển thị trên thanh AppBar (vd: "Quét mã vạch" / "Quét QR").
  final String title;

  /// Hướng dẫn ngắn hiển thị dưới khung quét.
  final String hint;

  /// Giới hạn định dạng cần nhận (rỗng = chấp nhận mọi loại mã).
  final List<BarcodeFormat> formats;

  const ScannerScreen({
    super.key,
    required this.title,
    required this.hint,
    this.formats = const [],
  });

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with WidgetsBindingObserver {
  // Tự quản lý vòng đời controller: khi truyền controller riêng cho
  // MobileScanner (mobile_scanner 5.x), widget KHÔNG tự start/stop theo
  // lifecycle nữa, nên màn hình phải tự làm để camera khởi động lại sau khi
  // app vào nền rồi quay lại. Vì vậy autoStart: false + start() thủ công.
  late final MobileScannerController _controller = MobileScannerController(
    formats: widget.formats,
    detectionSpeed: DetectionSpeed.noDuplicates,
    autoStart: false,
  );

  StreamSubscription<BarcodeCapture>? _subscription;
  bool _handled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _subscription = _controller.barcodes.listen(_onDetect);
    unawaited(_controller.start());
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final code = capture.barcodes
        .map((b) => b.rawValue)
        .firstWhere((v) => v != null && v.isNotEmpty, orElse: () => null);
    if (code == null) return;
    _handled = true;
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(code);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_controller.value.isInitialized) return;
    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        return;
      case AppLifecycleState.resumed:
        _subscription = _controller.barcodes.listen(_onDetect);
        unawaited(_controller.start());
      case AppLifecycleState.inactive:
        unawaited(_subscription?.cancel());
        _subscription = null;
        unawaited(_controller.stop());
    }
  }

  @override
  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_subscription?.cancel());
    _subscription = null;
    super.dispose();
    await _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: 'Bật/tắt đèn',
            icon: const Icon(Icons.flash_on_rounded),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            tooltip: 'Đổi camera',
            icon: const Icon(Icons.cameraswitch_rounded),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            errorBuilder: (context, error, child) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Không mở được camera: ${error.errorDetails?.message ?? error.errorCode.name}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
          // Khung ngắm
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary, width: 3),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 48,
            child: Text(
              widget.hint,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: AppType.bodyLg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
