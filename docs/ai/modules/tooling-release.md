# Build, release và capture tools

[Module index](../module-index.md) · [configuration](project-runtime.md) · [tests](testing.md).

## Test runner

`scripts/tools/run_tests.py` tìm executable **tên godot trên PATH**; default glob tests/test_*.gd, hoặc paths theo argv. Serial subprocess headless, timeout 60s/test; pass cần exit 0 và không có `ERROR:` trong stdout/stderr. Ghi `output/rebirth/test-results.json`, exit 1 nếu có failure. Không chạy ba Python tests. Error message ghi 4.6.2 nhưng runner không kiểm tra binary version thực tế.

## Release pipeline

`scripts/tools/package_release.py.main()` nhận --revision SHA lowercase 40 ký tự, --version và --prepare-only. Tạo output/releases/<version>/project, từ chối directory có sẵn. Copy working tree theo FILES/DIRECTORIES allowlist: 3D scripts/scenes, Soundscape, KayKit, fonts, combat audio, notices/config/icon. Không git checkout revision được truyền và không kiểm tra sạch working tree; SHA là nhãn do caller cung cấp.

BUILD_MANIFEST.json chứa source_commit, engine hard-code 4.6.2.stable và sha256 từng staged file trước import. --prepare-only dừng ở đây, không kiểm tra binary/export. Full mode buộc Godot version prefix 4.6.2.stable; Apple Silicon có native arch wrapper; hai import pass (pass đầu bỏ qua ERROR text, pass sau strict) -> macOS/Windows exports -> add readable notices/manifest/readme -> verify ZIP integrity/required notices -> SHA256SUMS. Không có publish/upload trong script.

`scripts/tools/verify_release_pack.gd` là SceneTree riêng; nhận đúng một .pck user arg, load_resource_pack rồi walk inventory, reject legacy paths, kiểm tra notices/audio và instantiate 3D world. Theo comment, chạy từ empty project directory để source local không che thiếu pack. Package script không tự gọi verifier này.

**Hiện có version drift**: project.features 4.7, binary local 4.7.2, packager 4.6.2; preset macOS/iOS version 0.4.0, project.version 0.4.1. Không tự đổi version/config trong nhiệm vụ tài liệu. Release build hiện tại chưa chạy.

## Capture và inspection (không phải test tự động cân bằng)

Tất cả `.gd` dưới đây extends SceneTree, dùng `_initialize`/deferred run hoặc frame callbacks; can thiệp input/scene state có chủ đích. Render captures cần native renderer và frame_post_draw, không headless dummy. Các công cụ dùng InputMap.action_erase_events chỉ thay process hiện tại, không ghi project.godot.

| File `scripts/tools/` | Phạm vi / output |
| --- | --- |
| `capture_rebirth.gd` | 3D title/court/seal/pause -> output/rebirth; không đặt persist_progress=false |
| `capture_duel_3d.gd` | Scripted boss combat 300 frames, FPS/node print; movie output do CLI --write-movie |
| `capture_attack_review.gd` | 3D ba weapon/dash/recall, camera gần 7.5; movie do CLI |
| `capture_readability.gd` | 3D threat/hit/guard/input staging, movie do CLI |
| `capture_mastery_showcase.gd` | 3D surge/boss phases, output/mastery screenshots/performance.json; sample có VSync, không benchmark đa máy |
| `capture_stillwater_ui.gd` | Chín trạng thái UI -> output/ui-polish, report số liệu dàn dựng |
| `capture_atmosphere.gd` | output/atmosphere; gồm camera/light studies riêng, không shipping framing |
| `capture_art_v2.gd` | 2D title/village/equipment/upgrades/boss/result -> output/art-v2, xử lý HDR->sRGB |
| `capture_polish.gd` | 2D day/night/combat/inventory/skills/pause -> output/polish |
| `capture_showcase.gd` | 2D public images -> **docs/showcase/images**, có thể ghi đè media tracked; dùng terrain land/land_night cũ khác World hiện tại |
| `inspect_rig.gd` | Print imported Rogue skeleton tree/bones/clip lengths, không screenshot |
| `play_stillwater.gd` | Auto play tối đa 180 run seconds, time_scale=3, input/skills thật, PLAYTEST_RESULT JSON stdout; không sửa HP để thắng, không chứng minh human balance |

Capture tools và tests thường dùng persist_progress=false; cổng này không ngăn đọc settings (xem run module). Có script không tắt persistence, nên đọc trước chạy. Output/capture/local release dirs được gitignore; `.github` hiện chỉ có issue forms, không có workflow CI trong inventory.
