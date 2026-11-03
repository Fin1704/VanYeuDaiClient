# Asset pipeline và dữ liệu artwork

[Module index](../module-index.md) · [actors 2D](legacy-actors.md) · [3D presentation](stillwater-presentation.md). Quy tắc thao tác bắt buộc và lệnh chuẩn ở [AGENTS.md](../../../AGENTS.md); không nhân bản quy trình đó ở nhiều nơi.

## Nguồn, dữ liệu runtime và generated files

- `assets/characters/kaykit/`: ba GLB Rogue_Hooded/Knight/Mage + texture, license; source cho 3D. `.glb.import` là metadata importer scene có UID, animation/import=true, fps=30, named skins, root_scale=1. Cache `.godot/imported/*.scn` là generated, không source để sửa.
- `assets/fonts/`: NotoSansSC/NotoSerifSC binaries; FontVariation wrappers StillwaterSans(weight 400)/StillwaterSerif(weight 350). Runtime 3D UI dùng wrappers, 2D JianghuTheme nạp font trực tiếp.
- `assets/audio/combat/`: tám Foley + sáu ritual/UI stingers; generator scripts là nguồn có thể tái tạo. `compose_qinglan.py` tạo underscore cũ, Soundscape hiện không play loop này.
- `assets/xianxia/`, `assets/art_v2/`: 2D art, raw sheets và derivatives cùng tồn tại. `assets/unused/` và `docs/showcase/` không phải gameplay source. Manifest xianxia/animation_intent là hồ sơ lịch sử, không schema dùng runtime; PlayerController/BasicEnemy mới là grid contract hiện tại.
- `.import` chứa import settings/remap và cần giữ nếu chỉnh asset pipeline; `.uid` là identity sidecar cho scripts/shaders. Không ghi đè source raw, không chỉnh cache engine.

GLB JSON metadata đã được kiểm tra: cả ba có skin và các clip combat được CombatPuppet dùng, gồm Idle/Running/Death/Dodge/Block/Melee/Spellcast. Head/chest/upperarm.r có trong source node names. `Skeleton3D`, `AnimationPlayer`, `handslot_r/l` là tên tree **sau import** mà script cần; raw GLB không dùng đúng các tên này, nên raw metadata một mình không xác nhận Godot import hierarchy. Dùng `scripts/tools/inspect_rig.gd` khi đổi model/import settings.

## Công cụ (Python 3, Pillow)

| File trong `scripts/tools/` | API / dữ liệu vào-ra |
| --- | --- |
| `chroma_key_cutout.py` | `cutout_image`: green threshold + despill; `cutout_outer_white_background`: BFS từ biên giữ white kín bên trong; `defringe_white_edges`: ước lượng alpha viền; `validate_alpha`: corners, coverage >0 và <0.95 |
| `extract_gemini_run_sheet.py` | `find_components` -> `cluster_rows` -> `build_aligned_sheet`, mặc định 5×6; phát lỗi nếu sai số frame; center ngang/bottom align rồi fringe cleanup |
| `extract_gemini_idle_sheet.py` | `extract_idle_sheet`: fixed source grid 5×6, chọn rows 0/1/2, remove outer white/defringe/crop rồi pack 3×6 |
| `extract_gemini_still_sheet.py` | `_extract_row_sprite`: slice từng hàng, tìm leftmost component, xuất ba PNG idle down/up/left |
| `prepare_art_v2.py` | Script chạy top-level, crop bốn vùng environment.png, resize LANCZOS, thêm padding, ghi tree_jade/tree_ginkgo/rocks_moss/supply_crate |
| `prepare_attack_v2.py` | Script chạy top-level, crop 3×6 keyed poses, mirror hàng side, scale chung, bottom anchor 220 trong ô 160×224 -> player_attack_aligned.png 960×672 |
| `compose_combat_audio.py` | Top-level deterministic synthesis seed 737, tám mono WAV 44.1kHz |
| `synthesize_ritual_audio.py` | `save` + main: sáu mono WAV 24kHz, deterministic seed 1407 |
| `compose_qinglan.py` | Top-level tổng hợp bản 24s 22.05kHz vào qinglan_night.wav |

Không import các prepare/compose scripts như thư viện vô hại: top-level ghi file. `chroma_key_cutout.py` docstring nói magenta nhưng thuật toán `cutout_image` hiện chỉ kiểm tra green; không coi magenta được hỗ trợ tự động. Các CLI cutout/extract không tự chạy validate-alpha sau save; phải làm bước validation riêng theo AGENTS.

## Kiểm tra và giới hạn

`tests/test_white_background_flood_cutout.py` unittest giữ white nội bộ; `test_extract_idle_sheet.py` pytest kiểm tra bbox/grid/white; `test_sprite_sheet_cleanup.py` là executable main kiểm tra actual run sheet <=80 bright fringe pixels, **không có pytest test function**. Không coi pytest collection đơn lẻ là đã chạy fringe check.

Môi trường khảo sát: Python 3.12 có sẵn, Pillow và pytest chưa có trong interpreter này. Các lệnh kiểm tra đã dừng vì dependency thiếu, không phải test assertion fail. Không tái tạo/chỉnh bất kỳ asset nào trong đợt lập tài liệu.

Giấy phép/provenance: đọc [LICENSE_SCOPE.md](../../../LICENSE_SCOPE.md), [THIRD_PARTY_NOTICES.md](../../../THIRD_PARTY_NOTICES.md), [asset credits](../../THIRD_PARTY_ASSETS.md); knowledge base chỉ dẫn lại phạm vi ghi trong repository, không xác nhận pháp lý bên ngoài. Binaries/font/license full text không được audit nội dung trong source analysis.
