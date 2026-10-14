# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

`etech_lab` is a Flutter mobile client (Dart SDK ^3.11.5) for an **Odoo LIMS backend** ("elab-tech", a set of `etech_*` Odoo addons). The app is field/lab-staff facing. UI text and code comments are in Vietnamese — keep that convention.

## Commands

```bash
flutter pub get                       # install deps
flutter run                           # run on connected device/emulator (entry: lib/main.dart)
flutter analyze                       # lint (flutter_lints via analysis_options.yaml)
flutter test                          # all tests
flutter test test/session_store_test.dart   # single test file
flutter test --update-goldens test/login_visual_test.dart   # regenerate golden images
```

Dev preview harnesses render a single screen with mock data, no login/backend needed:
```bash
flutter run -t lib/dev_account_preview.dart
flutter run -t lib/dev_change_password_preview.dart
flutter run -t lib/dev_login_preview.dart
```

Helper scripts:
```bash
./run_phone.sh [-t lib/dev_xxx.dart]  # boot Android emulator (AVD pixel_api34) if needed, then flutter run
./run_web_dev.sh                       # web dev: Flutter dev server :5001 + web_proxy.js on :5000 (proxies /web,/api to Odoo), auto hot-restart on lib/ changes
```

Golden/visual tests (`login_visual_test.dart`, `form_golden_test.dart`, `formview_render_test.dart`, `mobile_screens_render_test.dart`, `mobile_detail_actions_render_test.dart`, …) load real fonts from a **hardcoded local Flutter cache path** (`/home/huytq/snap/flutter/.../material_fonts`); they break on other machines — adjust the path or skip them elsewhere. Diff artifacts land in `test/failures/`.

## Backend connection

- `lib/config.dart` — `odooDb` and native URL `_nativeOdooUrl` are **hardcoded** (LAN IP `:8001`, db `elabtech_11`); change when switching environments (`10.0.2.2` for Android emulator → host). On **web**, `odooUrl` is always same-origin (`Uri.base.origin`) because Odoo sends no CORS headers and the `session_id` cookie isn't `SameSite=None` — so web must run behind the `run_web_dev.sh` proxy, never hit Odoo cross-origin. `AppConfig.appVersion` must be kept in sync with `pubspec.yaml`.
- Auth is **Odoo session-based**: `OdooAuthService.login()` POSTs to `/web/session/authenticate`, then extracts `session_id` from the `Set-Cookie` header.
- `SessionStore` persists `session_id` + `uid` in `SharedPreferences` for "stay logged in" — **never stores the password**.
- Data services are thin REST clients to custom Odoo endpoints under `/api/*`, authenticating by sending `Cookie: session_id=<id>`. **`lib/services/customer_service.dart` is the canonical reference** for a new module service: 15s `_send()` timeout, `_fail()` for normalizing HTTP/`{error}` bodies into Vietnamese `Exception`s, `_qs()` for building `?offset=&limit=&state=&q=` paging queries, and a `_mock*` fallback in `catch` so screens still render in dev preview / golden tests when offline. List endpoints return the `{items,total,all_count,counts,offset,limit}` shape parsed by `PagedResult.fromJson` (`lib/models/paged.dart`).

## Architecture

Layout: `lib/{config,main}.dart`, `screens/`, `services/`, `models/`, `widgets/`, `menu/`, `theme/`. Plain layered structure — no state-management package (no Riverpod/Bloc/Provider). State is local `StatefulWidget` state; cross-cutting state uses **global `ChangeNotifier` singletons** (`themeController`, `permissions`, `notifications`).

**Bootstrap flow:** `main()` loads `themeController` → `SplashScreen` calls `SessionStore().load()` and routes to `HomeScreen` (valid session) or `LoginScreen`. `HomeScreen` then `permissions.load(sid)`, `notifications.attach(sid)` + `refresh()`, and `_syncMenus()`.

**Feature module pattern (the common case).** Most of the ~12 LIMS modules (analysis requests, handovers, lab batches/samples/tests, preprocess, destructions, retention, service requests, test reports, customers, …) follow one shared shape — copy an existing module rather than inventing structure: a `*_service.dart` (canonical REST client, see above) + `models/*.dart` (`fromJson`, paged brief + detail) + `*_screens.dart` built on the generic widgets in `lib/widgets/`:
- `ModuleListScaffold<T>` — AppBar + notification bell + permission gating + `PagedListView`.
- `PagedListView<T>` (driven by the `PagedFetch<T>` typedef) — search, server-side state-filter chips with server counts, infinite scroll, pull-to-refresh, and the shared empty/error/loading states from `widgets/states.dart`. **Filter/search/paging run server-side** — never filter a loaded page client-side.
- `ModuleDetailScaffold<T>` — `FutureBuilder` wrapping skeleton/error-retry/`builder`; pass a `load()` factory (not a ready future) so retry re-fetches.
- Shared detail/list building blocks: `widgets/detail_kit.dart`, `status_chip.dart`.

Three big-picture systems that span multiple files:

### 1. Menu system (static config synced to backend permissions)
- `lib/menu/app_modules.dart` is the **single source of truth** for navigation: 7 `AppModule`s, each mapped 1:1 to a backend `<menuitem>` via `backendXmlId`. When the backend menu tree changes, update this file.
- `MenuService.fetch()` (`/api/menus`) returns the set of menu xmlids the logged-in user is allowed to see.
- `resolveModules(visible, names)` filters the static config down to the user's permitted menus and overrides labels with backend names. On any network/permission error the app **falls back to the full static config** — never blocks the UI (see `HomeScreen._syncMenus`).
- `AppSubMenu.implemented` flags whether a real mobile screen exists; `false` → placeholder screen. Most LIMS modules are now implemented end-to-end (see "Feature module pattern" above); flip `implemented` when you wire a new sub-menu to a real screen.

### 2. Permission & notification systems (global singletons)
- `permissions` (`PermissionController`, `lib/services/permission_controller.dart`) holds the user's `AppPermissions` (per-model read/write/create/unlink, group flags, visible menus, visible counts). Loaded once in `HomeScreen`. **Default-allow:** before load and on load error every helper returns `true` so the UI is never blocked — the backend `ir.rule` is the real data-layer gate; this is only UI gating. (Exception: `inGroup()` defaults `false` — groups are opt-in.)
- Gate a screen by passing `permissionModel:` to `ModuleListScaffold` (shows a "no permission" state); gate create/edit actions with `permissions.canCreate('model')` / `canWrite(...)`. `canSeeMenu(xmlid)` filters navigation.
- `notifications` (`NotificationController`) tracks the unread count behind `NotificationBell` (badge auto-rebuilds via `AnimatedBuilder`); `attach(sid)` + `refresh()` in `HomeScreen`. QR scanning uses `mobile_scanner` (`screens/scanner_screen.dart`).

### 3. Theme system (runtime palette swap)
- `lib/theme/app_theme.dart` is the single source of design tokens (`AppPalette`, radii, shadows, typography). Two palettes exist: `kLightPalette` / `kDarkPalette`.
- `AppColors.apply(palette)` swaps the **active static palette** at runtime; widgets read `AppColors.*` directly rather than `Theme.of(context)`.
- `themeController` (global `ThemeController extends ChangeNotifier`, persisted via `SharedPreferences`) drives light/dark. `main.dart` wraps `MaterialApp` in an `AnimatedBuilder` on it and calls `AppColors.apply(...)` on each rebuild.


## Định dạng ngày giờ (BẮT BUỘC — quy ước Việt Nam)

Mọi ngày/giờ HIỂN THỊ cho người dùng phải ở định dạng Việt Nam:
- Ngày: `dd/MM/yyyy` (vd `18/06/2026`)
- Ngày giờ: `dd/MM/yyyy HH:mm` (bỏ giây, vd `15/06/2026 14:30`)

Backend Odoo trả chuỗi ISO (`yyyy-MM-dd` hoặc `yyyy-MM-dd HH:mm:ss`). Dùng helper duy nhất `formatVn()` trong `lib/utils/vn_format.dart` (tự nhận date vs datetime, giữ nguyên giá trị — KHÔNG đổi múi giờ, chỉ đổi cách trình bày).

Quy tắc áp dụng:
- **Field hiển-thị-thuần** (read-only, chỉ để show): bọc `formatVn(...)` ngay tại `fromJson` của model → mọi điểm hiển thị (list + detail) tự đồng bộ, không cần sửa từng screen. Đây là cách mặc định.
- **Field cần raw cho logic** thì GIỮ chuỗi ISO ở model, chỉ `formatVn()` tại điểm hiển thị:
  - `Employee.birthday` (date-picker `DateTime.tryParse`),
  - `Employee.writeDate` (cache-busting `?v=write_date`),
  - model có `toJson`/round-trip lên backend (vd `sampling.dart`),
  - `AppNotification.date` (đang dùng formatter thời-gian-tương-đối riêng).
- Khi thêm field ngày/giờ mới: mặc định bọc `formatVn()` ở `fromJson`; nếu field đó còn dùng cho logic/gửi-lên-backend thì để raw và `formatVn()` ở chỗ hiển thị.
