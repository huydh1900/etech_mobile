#!/usr/bin/env bash
# Dev web có hot restart, KHÔNG cần `flutter build web` mỗi lần sửa.
#  - Chạy Flutter dev server ở 127.0.0.1:5001
#  - web_proxy.js forward frontend sang dev server đó (cùng origin :5000 nên
#    cookie session + /api,/web về Odoo vẫn chạy).
#  - Tự hot restart khi file .dart trong lib/ đổi (tắt: AUTO_RESTART=0 ./run_web_dev.sh)
# Dùng: ./run_web_dev.sh   (mở http://192.168.1.145:5000)
# Gõ tay vẫn được: `r` (hot reload) / `R` (hot restart) / `q` (thoát) + Enter.
# (Phải bấm Enter vì phím đi qua pipe của script này chứ không thẳng vào
#  flutter — đánh đổi để watcher bơm được lệnh restart vào cùng đường đó.)
set -e
DEV_PORT=5001
AUTO_RESTART=${AUTO_RESTART:-1}
WATCH_INTERVAL=${WATCH_INTERVAL:-1}
PROXY_PORT=5000

# Preflight: lần chạy trước còn sót (đóng terminal, kill không sạch) sẽ giữ
# 5000/5001 -> "Address already in use, errno = 98". Dọn PID đang listen 2 port đó.
for p in $PROXY_PORT $DEV_PORT; do
  pids=$(ss -ltnpH "sport = :$p" 2>/dev/null | grep -oP 'pid=\K[0-9]+' | sort -u)
  if [ -n "$pids" ]; then
    echo ">> port $p đang bị chiếm bởi PID: $pids -> kill"
    kill $pids 2>/dev/null || true
    sleep 1
  fi
done

FLUTTER_DEV_PORT=$DEV_PORT node web_proxy.js &
PROXY_PID=$!

# Kênh stdin dùng chung cho flutter run: vừa nhận phím người gõ, vừa nhận
# lệnh 'R' do watcher bơm vào. Mở read-write (3<>) để không bị block lúc
# chưa có reader.
FIFO=$(mktemp -u /tmp/etech_lab_run.XXXXXX)
mkfifo "$FIFO"
exec 3<>"$FIFO"

cleanup() {
  kill "$PROXY_PID" ${KEY_PID:-} ${WATCH_PID:-} 2>/dev/null || true
  exec 3>&-
  rm -f "$FIFO"
}
trap cleanup EXIT

# Chuyển phím gõ trong terminal vào flutter run.
cat >&3 &
KEY_PID=$!

if [ "$AUTO_RESTART" = 1 ]; then
  # Không có inotify-tools trên máy này -> poll mtime của lib/**/*.dart.
  dart_sig() { find lib -name '*.dart' -printf '%T@ %p\n' 2>/dev/null | sort | cksum; }
  (
    prev=$(dart_sig)
    while sleep "$WATCH_INTERVAL"; do
      cur=$(dart_sig)
      [ "$cur" = "$prev" ] && continue
      sleep 0.3                 # debounce: đợi editor ghi xong cả loạt file
      prev=$(dart_sig)
      echo ">> lib/*.dart đổi -> hot restart"
      printf 'R\n' >&3
    done
  ) &
  WATCH_PID=$!
  echo ">> auto hot restart: BẬT (AUTO_RESTART=0 để tắt)"
fi

# Bọc `script` để flutter run có PTY: flutter CHỈ đọc lệnh phím khi stdin là
# terminal — nối thẳng FIFO vào stdin của nó thì 'R' bị bỏ qua (đã kiểm chứng).
# script nhận FIFO làm stdin rồi forward vào PTY của flutter.
# KHÔNG dùng --web-experimental-hot-reload: dwds khi đó nhúng URL tuyệt đối
# (http://127.0.0.1:5001/reloaded_sources.json) vào main_module.bootstrap.js và
# fetch nó TRƯỚC khi chạy main. Mở qua proxy origin :5000 -> cross-origin fetch bị
# CORS chặn -> main không chạy, trang trắng. Bỏ flag thì vẫn còn hot restart (R).
script -qc "flutter run -d web-server \
  --web-hostname=127.0.0.1 \
  --web-port=$DEV_PORT \
  $*" /dev/null < "$FIFO"
