#!/usr/bin/env bash
# Chạy app trên emulator Android (màn hình cỡ điện thoại).
# Tự mở emulator nếu chưa chạy, đợi boot xong rồi flutter run.
#   ./run_phone.sh                  -> chạy lib/main.dart
#   ./run_phone.sh -t lib/dev_xxx.dart  -> chạy entrypoint khác (tham số truyền thẳng vào flutter run)
set -e

EMULATOR_ID="pixel_api34"            # đổi nếu dùng AVD khác (xem: flutter emulators)
ADB="${ANDROID_HOME:-$HOME/Android/Sdk}/platform-tools/adb"

# Lấy serial của thiết bị android đang online (nếu có)
device="$("$ADB" devices 2>/dev/null | awk '/emulator-[0-9]+\tdevice$/{print $1; exit}')"

if [ -z "$device" ]; then
  echo ">> Chưa có emulator -> đang mở $EMULATOR_ID ..."
  flutter emulators --launch "$EMULATOR_ID"
  echo ">> Đợi emulator boot..."
  for _ in $(seq 1 60); do
    device="$("$ADB" devices 2>/dev/null | awk '/emulator-[0-9]+\tdevice$/{print $1; exit}')"
    [ -n "$device" ] && break
    sleep 3
  done
  # đợi hệ thống boot hoàn tất
  "$ADB" -s "$device" wait-for-device
  until [ "$("$ADB" -s "$device" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]; do
    sleep 2
  done
fi

[ -z "$device" ] && { echo "!! Không tìm thấy emulator. Chạy 'flutter emulators' để kiểm tra."; exit 1; }

echo ">> Chạy app trên $device"
exec flutter run -d "$device" "$@"
