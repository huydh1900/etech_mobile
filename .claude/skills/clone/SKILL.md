---
name: clone
description: Clone một màn hình web (Odoo web view, trang web bất kỳ) thành widget Flutter trong repo etech_lab — đo computed style thật bằng browser MCP, viết spec file, build tuần tự, rồi diff ảnh. Dùng khi user nói "clone màn này sang Flutter", "làm giống hệt màn Odoo web", "dựng lại UI này bằng Flutter", "pixel-perfect màn X".
argument-hint: "<url-hoặc-đường-dẫn-màn-hình> [tên-màn]"
user-invocable: true
---

# Clone UI → Flutter (/clone)

Mục tiêu: dựng lại **$ARGUMENTS** thành widget Flutter trong `lib/` **khớp số đo thật**, không áng chừng.

Nguyên tắc gốc: một lần **đo chính xác** > nhiều vòng đoán rồi sửa. Mọi giá trị px trong code phải truy được về một lần `getComputedStyle()` đã ghi vào spec file.

## Ranh giới (đọc trước khi làm)

- **KHÔNG spawn subagent.** Repo này cấm (CLAUDE.md global). Làm tuần tự một component một lượt, tự extract → tự build.
- **KHÔNG dùng git worktree / branch song song.** Repo hiện không phải git repo.
- Chỉ tạo/sửa file trong `lib/`, `assets/`, `pubspec.yaml`, `test/`. Không đụng `odoo18/`, `enterprise/`.
- Không đổi API/theme/widget dùng chung có sẵn để "cho vừa" màn mới — nếu buộc phải sửa `lib/theme/app_theme.dart` hay `lib/widgets/*`, **hỏi user trước**.
- Text UI + comment: tiếng Việt. Ngày giờ: `formatVn()` (`lib/utils/vn_format.dart`).

## Pre-Flight

1. **Cần browser automation.** Ưu tiên Chrome MCP (`mcp__claude-in-chrome__*`); nếu bị defer thì load 1 lần bằng ToolSearch:
   `select:mcp__claude-in-chrome__tabs_context_mcp,mcp__claude-in-chrome__navigate,mcp__claude-in-chrome__computer,mcp__claude-in-chrome__javascript_tool,mcp__claude-in-chrome__read_page,mcp__claude-in-chrome__tabs_create_mcp`
   Không có browser tool → hỏi user, KHÔNG tự đoán số đo từ ảnh.
2. Nếu target là Odoo web (`AppConfig.odooUrl` trong `lib/config.dart`) thì cần đăng nhập sẵn trong Chrome; nếu chưa, bảo user login rồi quay lại.
3. Xác định output: widget mới nằm ở đâu.
   - Màn list/detail của một module LIMS → theo **Feature module pattern** (`lib/screens/<module>_screens.dart` + `lib/services/<module>_service.dart` + `lib/models/`), dùng `ModuleListScaffold` / `PagedListView` / `ModuleDetailScaffold`.
   - Clone y hệt Odoo web (tree/kanban) → tái sử dụng `lib/widgets/odoo_web_clone.dart` (`OdooCloneScaffold`, `OdooTreeListView`, `OdooKanbanCardList`, bảng màu `kOdoo*`) thay vì viết lại.
   - UI mới hoàn toàn → widget riêng trong `lib/widgets/` hoặc `lib/screens/`.
   Viết ra output plan (file nào tạo, file nào sửa) trước khi gõ dòng code đầu tiên. Trùng tên file có sẵn → hỏi user.
4. `flutter analyze` phải sạch TRƯỚC khi bắt đầu — để mọi lỗi sau này là do mình.

## Phase 1: Recon (đo, chưa code)

Mở URL bằng browser MCP. **Resize cửa sổ về bề rộng mobile 390px** (`resize_window`) — app là mobile client, đo ở desktop là sai ngay từ đầu.

Chụp ảnh và lưu vào `docs/ui-clone/<màn>/`:
- Full-page ở 390px (bản gốc để đối chiếu cuối)
- Từng section một ảnh riêng

Trích global một lần:
- **Màu**: gom palette thật; map sang `AppColors.*` nếu trùng token có sẵn, chỉ hardcode `Color(0x...)` khi là clone Odoo web (như `odoo_web_clone.dart` đã làm, có comment giải thích).
- **Font**: family/weight/size thật. Nếu khác font app đang dùng → báo user, đừng tự thêm font vào `pubspec.yaml`.
- **Asset**: liệt kê `<img>`, background-image, inline `<svg>`. Icon module Odoo lấy từ `assets/icons/odoo/` (map trong `lib/widgets/odoo_icon.dart`) trước khi tải mới.

### Interaction sweep (bắt buộc, trước khi code)

Web và Flutter khác nhau ở chỗ này nhiều nhất — sai model tương tác là viết lại, không phải sửa CSS:
- **Scroll**: header co lại / đổi màu? → `SliverAppBar` hay `NestedScrollView`, ghi rõ ngưỡng px.
- **Click vs scroll-driven**: cuộn trước, click sau. Tab đổi khi cuộn (IntersectionObserver) ≠ tab đổi khi bấm (`TabBar`).
- **Tab/pill nhiều state**: bấm TỪNG cái, ghi nội dung của TỪNG state.
- **Hover**: web có hover, mobile KHÔNG. Map sang `InkWell`/pressed state hoặc bỏ — ghi rõ quyết định trong spec.
- **Overflow ngang**: bảng cuộn ngang → `SingleChildScrollView(scrollDirection: Axis.horizontal)`; ghi lại độ rộng từng cột.

Lưu vào `docs/ui-clone/<màn>/BEHAVIORS.md`.

## Phase 2: Trích số đo

Với mỗi section, chạy script này qua `javascript_tool` (một lần cho cả cây con — đừng đo tay từng property):

```javascript
(function(selector){
  const el = document.querySelector(selector);
  if (!el) return JSON.stringify({error:'not found: '+selector});
  const props=['fontSize','fontWeight','fontFamily','lineHeight','letterSpacing','color',
    'textAlign','textTransform','backgroundColor','backgroundImage',
    'paddingTop','paddingRight','paddingBottom','paddingLeft',
    'marginTop','marginRight','marginBottom','marginLeft',
    'width','height','maxWidth','minHeight',
    'display','flexDirection','justifyContent','alignItems','flexWrap','gap',
    'gridTemplateColumns','borderRadius','borderTopWidth','borderTopColor',
    'borderBottomWidth','borderBottomColor','boxShadow','overflow','overflowX',
    'position','top','right','bottom','left','zIndex','opacity','transform',
    'objectFit','whiteSpace','textOverflow','WebkitLineClamp'];
  const skip=new Set(['none','normal','auto','0px','rgba(0, 0, 0, 0)','static','visible']);
  const S=e=>{const c=getComputedStyle(e),o={};props.forEach(p=>{const v=c[p];if(v&&!skip.has(v))o[p]=v;});
    o._box=e.getBoundingClientRect().toJSON();return o;};
  const walk=(e,d)=>d>4?null:({tag:e.tagName.toLowerCase(),
    cls:(e.className||'').toString().split(' ').slice(0,4).join(' '),
    text:e.childNodes.length===1&&e.childNodes[0].nodeType===3?e.textContent.trim().slice(0,300):null,
    img:e.tagName==='IMG'?{src:e.src,w:e.naturalWidth,h:e.naturalHeight}:null,
    styles:S(e),
    children:[...e.children].slice(0,20).map(c=>walk(c,d+1)).filter(Boolean)});
  return JSON.stringify(walk(el,0),null,2);
})('SELECTOR');
```

`_box` (`getBoundingClientRect`) là số đo dùng để kiểm chứng: tổng padding + content trong Flutter phải ra đúng `width`/`height` này.

Với element có nhiều state: chạy script ở state A → trigger (scroll/click) → chạy lại → **diff chính là spec hành vi**.

### Bảng quy đổi CSS → Flutter

CSS px = Flutter logical px (1:1, không nhân devicePixelRatio).

| CSS | Flutter |
|---|---|
| `padding: 12px 16px` | `EdgeInsets.symmetric(vertical: 12, horizontal: 16)` |
| `margin` | `Padding` bọc ngoài / `SizedBox` chèn giữa — Flutter không có margin |
| `display:flex; flex-direction:row` | `Row` (`column` → `Column`) |
| `gap: 8px` | `SizedBox(width/height: 8)` xen giữa, hoặc `Wrap(spacing:)` |
| `justify-content` | `mainAxisAlignment` |
| `align-items` | `crossAxisAlignment` |
| `flex: 1` | `Expanded` (`flex-shrink:0` → `Flexible(fit: FlexFit.loose)` / để nguyên) |
| `flex-wrap: wrap` | `Wrap(spacing:, runSpacing:)` |
| `grid-template-columns: repeat(2, 1fr)` | `GridView.count(crossAxisCount: 2, childAspectRatio: w/h)` |
| `position:absolute` | `Stack` + `Positioned` (toạ độ lấy từ top/right/bottom/left) |
| `border-radius: 12px` | `BorderRadius.circular(12)` |
| `border: 1px solid #E5E7EB` | `Border.all(color: Color(0xFFE5E7EB), width: 1)` |
| `box-shadow: 0 4px 12px rgba(0,0,0,.08)` | `BoxShadow(offset: Offset(0,4), blurRadius: 12, color: Color(0x14000000))` — alpha `.08` → `0x14` |
| `font-size:14px; line-height:20px` | `TextStyle(fontSize: 14, height: 20/14)` — **height là tỉ lệ, không phải px** |
| `letter-spacing: 0.02em` @14px | `letterSpacing: 0.28` (em × fontSize) |
| `font-weight: 500` | `FontWeight.w500` |
| `text-overflow: ellipsis` + `-webkit-line-clamp: 2` | `maxLines: 2, overflow: TextOverflow.ellipsis` |
| `overflow-x: auto` | `SingleChildScrollView(scrollDirection: Axis.horizontal)` |
| `overflow: hidden` + radius | `ClipRRect(borderRadius:)` |
| `object-fit: cover` | `BoxFit.cover` |
| `opacity` | `Opacity` / `Color.withOpacity` (ưu tiên màu, rẻ hơn) |
| `transform: scale/translate` | `Transform.scale` / `Transform.translate` |
| `transition: all .3s ease` | `AnimatedContainer(duration: Duration(milliseconds: 300), curve: Curves.easeInOut)` |
| `rgb(a,b,c)` / `#RRGGBB` | `Color(0xFFRRGGBB)` |
| `:hover` | KHÔNG có trên mobile → `InkWell` splash hoặc bỏ hẳn |
| `cursor: pointer` | `InkWell` / `GestureDetector` |

Bẫy hay gặp:
- CSS `line-height: normal` → đo `_box.height` của dòng text rồi chia `fontSize` ra `height`.
- Padding của web thường tính cả border (`box-sizing: border-box`); Flutter `Container` cộng thêm border vào ngoài padding → trừ `borderWidth` khi cần khớp `_box.width`.
- `Text` Flutter có leading trên/dưới theo `height` → khoảng cách nhìn thấy giữa 2 dòng ≠ giá trị `gap` CSS. Khớp bằng `_box`, không bằng cảm giác.

## Phase 3: Spec file

Mỗi component **một** file `docs/ui-clone/<màn>/<Component>.spec.md` trước khi code. Không code chay từ trí nhớ session browser.

```markdown
# <Component> — Spec

## Tổng quan
- File đích: `lib/widgets/<x>.dart` (hoặc `lib/screens/<x>_screens.dart`)
- Ảnh gốc: `docs/ui-clone/<màn>/<file>.png`
- Model tương tác: static | bấm | cuộn | theo thời gian
- Widget dùng lại: ModuleListScaffold / PagedListView / OdooCloneScaffold / detail_kit / status_chip …

## Cây widget
<container → children, kèm widget Flutter tương ứng>

## Số đo (computed thật)
### Container
- _box: w=… h=…
- padding / background / radius / border / shadow: …
### <con 1>
- fontSize / height / weight / color / maxLines: …

## Hành vi
- Trigger: <cuộn qua 56px | bấm tab | …>
- State A → State B: <property: trước → sau>
- Transition: <ms + curve>
- Hover web: <bỏ | chuyển thành pressed>

## Nội dung theo state (nếu có)

## Asset
- `assets/...` (hoặc icon có sẵn trong `kOdooModuleIcons`)

## Text (nguyên văn, tiếng Việt)

## Dữ liệu
- Field từ API `/api/...`, model `lib/models/<x>.dart`
- Ngày/giờ: field nào bọc `formatVn()` tại `fromJson`, field nào giữ ISO
```

Điền hết. Không áp dụng thì ghi "N/A".

## Phase 4: Build (tuần tự)

Từng component một, từ trong ra ngoài (leaf → wrapper):

1. Viết widget theo spec, **copy đúng số** từ spec, không làm tròn cho "đẹp".
2. Ưu tiên widget/hằng số có sẵn: `AppColors.*`, `detail_kit.dart`, `status_chip.dart`, `states.dart`, `OdooIcon`. Đừng tự định nghĩa lại màu/khoảng cách đã có token.
3. Dữ liệu: service mới copy khuôn `lib/services/customer_service.dart` (timeout 15s, `_fail()`, `_qs()`, `_mock*` fallback). List trả `PagedResult`; **lọc/tìm/phân trang chạy server-side**.
4. `flutter analyze` sau mỗi component. Không để lỗi tích lại.

**Vòng lặp rẻ — bắt buộc khi phải chỉnh nhiều lần:** tạo harness preview `lib/dev_<màn>_preview.dart` (theo mẫu `lib/dev_account_preview.dart`) render đúng widget đó với mock data, chạy `flutter run -t lib/dev_<màn>_preview.dart`. Không build cả app + login mỗi vòng chỉnh 4px.

**Circuit breaker:** cùng một chỗ lệch mà sửa 2 lần vẫn sai → DỪNG, quay lại đo lại `_box` của cả element cha lẫn con. Sửa lần 3, 4 là dấu hiệu đang đoán.

## Phase 5: Diff ảnh

Chưa diff thì chưa xong.

1. Chụp màn Flutter ở 390px (emulator/thiết bị, hoặc golden test theo mẫu `test/login_visual_test.dart` — nhớ path font hardcode chỉ đúng trên máy này).
2. Đặt cạnh ảnh gốc `docs/ui-clone/<màn>/`, so từng section từ trên xuống.
3. Mỗi chỗ lệch: kiểm spec trước → spec sai thì đo lại + sửa spec + sửa code; spec đúng thì chỉ sửa code.
4. Test hành vi thật: cuộn, bấm từng tab, pull-to-refresh, infinite scroll, trạng thái rỗng/lỗi/loading (`widgets/states.dart`).
5. Kiểm cả dark mode — widget đọc `AppColors.*` nên phải thử `themeController` cả 2 palette. Chỗ hardcode màu sẽ lộ ở đây.

## Checklist trước khi code mỗi component

- [ ] Có spec file, điền đủ mọi mục
- [ ] Mọi số trong spec từ `getComputedStyle()`/`getBoundingClientRect()`, không ước lượng
- [ ] Model tương tác đã xác định (cuộn hay bấm) — đã cuộn thử TRƯỚC khi click
- [ ] Component nhiều state: đã bấm hết mọi state và ghi nội dung từng state
- [ ] Đã liệt kê hết ảnh/icon, kể cả lớp phủ chồng nhau
- [ ] Đã quyết định hover web xử lý thế nào trên mobile
- [ ] Đã chọn widget dùng lại có sẵn thay vì viết mới
- [ ] Field ngày/giờ đã theo quy ước `formatVn()`

## KHÔNG làm

- **Không đoán số từ ảnh screenshot.** Ảnh dùng để đối chiếu, `getComputedStyle` mới là nguồn số.
- **Không build tab bấm khi bản gốc đổi theo cuộn** (và ngược lại) — lỗi đắt nhất, phải viết lại.
- **Không copy nguyên chiều rộng desktop.** Đo ở 390px.
- **Không hardcode màu khi đã có `AppColors` token** — trừ clone Odoo web (đã có tiền lệ + comment trong `odoo_web_clone.dart`).
- **Không lọc/sort client-side** trên list đã phân trang.
- **Không tự thêm package state-management.** Repo dùng `StatefulWidget` + `ChangeNotifier` singleton.
- **Không sửa `lib/theme/app_theme.dart` hoặc widget dùng chung** để màn mới vừa — hỏi user trước.
- **Không viết một widget khổng lồ.** Spec quá ~150 dòng → tách component.
- **Không bỏ qua state rỗng/lỗi/loading.** Web thường không có, app bắt buộc có.
- **Không spawn agent để "build song song".**

## Báo cáo khi xong

- URL/màn gốc → file Flutter đã tạo
- Số component + số spec file (phải bằng nhau)
- Asset đã thêm (và dòng khai báo trong `pubspec.yaml`)
- `flutter analyze` sạch chưa
- Kết quả diff ảnh: chỗ nào còn lệch, lý do
- Cái gì cố ý làm khác web (hover, layout mobile) và vì sao
