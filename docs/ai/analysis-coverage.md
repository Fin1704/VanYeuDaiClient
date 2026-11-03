# Analysis coverage và checkpoint

[Knowledge base](README.md) · [module index](module-index.md) · [file inventory](source-inventory.json).

Snapshot gốc: **2026-11-03**, local working tree. Phân tích ban đầu chỉ đọc. Follow-up cùng ngày chuyển map Stillwater sang scene theo yêu cầu người dùng; phạm vi follow-up và kiểm tra chưa chạy ghi ở mục Implementation follow-up. Các câu hỏi runtime/render vẫn chưa được xác nhận.

## Tổng kiểm kê đã phân tích

**182 file source/config/data**: 179 nội dung full-review, 3 scene/config structured-review. Tổng 25,986 dòng trong inventory hiện tại; dòng trống cũng tính. Trong đó **166 file nguồn** gồm:

| Loại | Số file | Trạng thái |
| --- | --- | --- |
| Runtime GDScript | 55 | Đã đọc toàn bộ |
| GDScript tools | 13 | Đã đọc toàn bộ |
| GDScript test scripts | 36 | Đã đọc toàn bộ |
| Python tools | 11 | Đã đọc toàn bộ |
| Python test files | 3 | Đã đọc toàn bộ |
| Scene .tscn | 32 | 30 scene gốc full-review; hai scene map mới structured-review và đối chiếu node paths |
| Skill Resource .tres | 5 | Đã đọc toàn bộ, lần theo effect scene |
| Shader .gdshader | 11 | Đã đọc toàn bộ; shader inline nằm trong GD đã đọc |

16 file bổ sung: project.godot, export_presets.cfg; .editorconfig/.gitattributes/.gitignore; ba .github issue forms/config; hai FontVariation .tres; ba asset JSON; ba KayKit .glb.import. Danh sách **từng file**, module, review level, line count, SHA256, symbols/line và literal resource references trong source-inventory.json. Inventory là metadata, không sao chép source.

Đã kiểm riêng JSON chunk metadata của ba GLB (nodes/skins/meshes/animation clip names), không audit binary geometry/texture payload. Đã quét UID sidecars để tìm duplicate script/shader UID: không thấy duplicate; đây là kiểm tra identity tự động, không tính sidecars vào 182 file index hiện tại. Không chạy Godot UID import resolver.

## Batches hoàn tất

| Batch | Nội dung | Kết quả |
| --- | --- | --- |
| 1 | Root tree, config, entry scenes, baseline working tree, current docs | Hoàn tất discovery; ghi version drift |
| 2 | Stillwater, RunDirector, Duelist, Form | Hoàn tất call tracing/run/combat/checkpoint |
| 3 | 3D UI/feedback/effects/animation/courtyard/shaders | Hoàn tất; ghi module notes ngay sau batch |
| 4 | 2D World/player/enemy/boss/health/skills | Hoàn tất targeting/death/nav/resource cost/refund flows |
| 5 | 2D UI/inventory/progression/pause/environment/effects | Hoàn tất; tách scaffold/authoring code khỏi runtime active |
| 6 | Mọi tool/test/scene/resource và metadata asset liên quan | Hoàn tất; 36 GD tests + 3 Python files được đọc, không suy từ tên |
| 7 | Tổng hợp 13 module, source-map, paths/symbols/links/hashes | Hoàn tất validation tài liệu, xem kết quả bên dưới |

## Coverage theo module

Số dưới đây là assignment chính của file trong inventory, không cộng double-count caller được phân tích ở nhiều module.

| Module note | File index | Trạng thái |
| --- | --- | --- |
| [Project/runtime](modules/project-runtime.md) | 11 | VERIFIED_STATIC |
| [3D run](modules/stillwater-run.md) | 2 | VERIFIED_STATIC |
| [3D actor](modules/duelist-combat.md) | 2 | VERIFIED_STATIC |
| [3D presentation](modules/stillwater-presentation.md) | 25 | VERIFIED_STATIC, hai scene mới structured |
| [2D world](modules/legacy-world.md) | 6 | VERIFIED_STATIC |
| [2D actors](modules/legacy-actors.md) | 12 | VERIFIED_STATIC |
| [2D skills](modules/legacy-skills.md) | 16 | VERIFIED_STATIC |
| [2D interface](modules/legacy-interface.md) | 22 | VERIFIED_STATIC |
| [2D environment](modules/legacy-environment.md) | 14 | VERIFIED_STATIC |
| [Audio](modules/shared-audio.md) | 1 | VERIFIED_STATIC |
| [Assets](modules/asset-pipeline.md) | 17 | VERIFIED_STATIC, GLB JSON bổ sung riêng |
| [Tooling/release](modules/tooling-release.md) | 15 | VERIFIED_STATIC |
| [Testing](modules/testing.md) | 39 | Test source reviewed, assertions chưa chạy trong đợt này |

Không còn module code trong phạm vi ở trạng thái đang/chưa phân tích. Không có source file không đọc được. Hai lệnh đọc đầu gặp stdout encoding và output truncation; phần runtime bị gián đoạn đã đọc tiếp/đối chiếu đầy đủ, không tính phần chưa thấy là đã đọc.

## Toàn bộ cấu trúc repository và phạm vi loại trừ

| Path | Vai trò / mức khảo sát |
| --- | --- |
| scripts/, scenes/, resources/, ui/, tests/ | Toàn bộ text source đã đọc như thống kê trên |
| assets/characters, fonts, audio | Metadata/references/license attribution; GLB JSON inspected; binaries không audit/render/nghe |
| assets/xianxia, art_v2, unused | Catalog + JSON + source consumers/tools; không inspect từng raster frame/unused artwork |
| docs/, documents/ | Giữ tài liệu hiện có; README English, docs index/DEVELOPMENT/STILLWATER, CONTRIBUTING, LICENSE_SCOPE, THIRD_PARTY_NOTICES, asset credits được dùng như context đối chiếu; không audit mọi bản dịch/spec/plan/archive/marketing text |
| licenses/ và asset license texts | Xác minh path/cách package, không phân tích pháp lý hoặc audit lại toàn văn third-party notices |
| .github/ | Ba issue forms/config đã đọc; không có workflows trong inventory |
| .editorconfig/.gitattributes/.gitignore | Đã đọc; UTF-8/LF/cache/output conventions |
| .vscode/ | Local untracked editor setting được đọc để tìm Godot executable; không đưa vào portable inventory |
| .git/, .godot/ | VCS và engine cache; không deep scan history/generated import payload |
| .superpowers/ | Local scratch/html/log/pid, không runtime module; bỏ qua nội dung |
| output/, tmp/, out/, build/test artifacts | Generated/ignored, không source of truth. tmp/ai-analysis là scratch của phân tích, không thuộc deliverable |

Không có C#/.csproj/.sln, addons/package manifest được thấy trong source scope. Không có kết luận về remote repository/release trạng thái hiện tại vì không truy cập web.

## Implementation follow-up

- Chuyển map geometry của `Stillwater.gd` và `CourtyardDetail.gd` sang `StillwaterMap.tscn`; cảnh xa/lá/mưa/mist được serialize trong `CourtyardBackdrop.tscn`. `Stillwater.setup_map()` giữ named-node references và tạo seal-reactive `CourtyardAtmosphere` khi chạy. Static map builders và mesh generators cũ đã bỏ khỏi runtime scripts.
- `Stillwater.gd` giữ camera tracking, firefly/Core animation, gameplay actors, combat effects và encounter logic. Terminal state của RNG thế giới được ghi thành constant từ Godot 4.7.2 để giữ chuỗi gameplay sau khi bỏ các lượt gọi RNG chỉ dùng dựng cảnh.
- Các scene mới được tạo từ layout/runtime tree cũ và inventory hashes được cập nhật sau khi đọc lại phần source liên quan. **UNVERIFIED:** scene wiring, visible parity, collision/query parity và retry behavior chưa được kiểm tra bằng cách chạy game sau thay đổi. Không thêm/chạy regression tests trong follow-up này.

## Validation thực hiện và chưa thực hiện

- `python docs/ai/validate_knowledge.py`: kiểm 182 snapshot hashes, tất cả module mappings, inventory symbols, Markdown local links, source path references và qualified symbols. Không lỗi ở lượt kiểm cuối; số links/symbol có thể tăng khi trang này được cập nhật, lấy stdout chạy mới làm kết quả chính xác.
- Binary từ local editor config là **4.7.2.stable.official.ed1daf0bf**. Dùng `--headless` để serialize hai PackedScenes từ cây runtime cũ; đây là bước tạo asset, không phải kiểm tra sau khi nối scene mới. Không chạy full game/test suite.
- `python -m pytest ...` không chạy vì thiếu pytest; `python tests/test_sprite_sheet_cleanup.py` không chạy vì thiếu PIL. Không có assertion result được tạo; chưa cài dependencies.
- Chưa chạy 36 Godot tests, native captures/full journey, export/package/PCK verifier hoặc benchmark. Các kết quả pass/Metal capture trong docs cũ là lịch sử, không validation của working tree này.
- Follow-up map đổi `Stillwater.gd`, `CourtyardDetail.gd`, `CourtyardAtmosphere.gd`, `Form.gd`, `Stillwater.tscn`, `StillwaterMap.tscn` và thêm `CourtyardBackdrop.tscn`; tài liệu/inventory liên quan cũng cập nhật. Các thay đổi có từ đầu trong project.godot, ba .glb.import, .vscode/ và verify_release_pack.gd.uid vẫn được giữ. Không commit/stage.

## UNVERIFIED và bước tiếp theo theo nhu cầu

1. Khi sửa gameplay: tra module + source-inventory path/symbol, mở source mới, chọn tests từ testing.md. Chạy trên target Godot đã thống nhất, không dùng historical passes.
2. Khi làm release/engine migration: giải quyết K01/K02/K07 trước; kiểm templates, import hierarchy, headless palette path, native render và isolated PCK inventory. --prepare-only không chứng minh export ready.
3. Khi sửa assets: cung cấp Pillow/pytest trong môi trường phù hợp, chạy Python assertions và direct fringe script; thực hiện alpha/visual QA theo AGENTS.
4. Khi sửa 2D message/pause/navigation: reproduce K03 và R04/R05; read-only analysis chưa thay logic. Khi tăng mật độ: profile R01/R02/R03 thay vì suy từ số node.
5. Khi source đổi: review đúng file, cập nhật module/flow/issue và hash inventory tương ứng, thêm file mới vào inventory. Validator cố ý báo stale snapshot để agent sau không tin nhầm tài liệu cũ.

Các quyết định lịch sử không có lý do trong code được đánh dấu UNVERIFIED trong decisions.md; hardware/controller/render/runtime và tính đầy đủ quyền artwork vẫn ngoài bằng chứng của đợt phân tích này.
