# 3D: giao diện, hiệu ứng và courtyard

[Module index](../module-index.md) · [run](stillwater-run.md) · [actor](duelist-combat.md).

## Giao diện

`scripts/rebirth/StillwaterUI.gd` extends CanvasLayer, dựng toàn bộ Control tree trong `_ready/build_hud`; không có scene UI tĩnh cho 3D. `world` phải gán trước add_child. Font wrappers: `assets/fonts/StillwaterSans.tres`, `StillwaterSerif.tres`. UI dùng tọa độ thiết kế 1280×720 phù hợp viewport/stretch trong project.godot.

API: `show_title`, `show_guide`, `show_pause`, `show_upgrade`, `show_result`, `notify`, `clear_modal`. Button.pressed nối Callable world trực tiếp; UI còn **đọc trực tiếp** hp/stamina, seal flags, boss state, cooldowns, director bonuses/report. UI không tự sở hữu progression. `new_modal()` xóa modal trước và kill tween cũ; deferred focus có is_instance_valid guard. `_input()` bắt Esc guide và số upgrade trước world._unhandled_input. `_process()` poll world, chỉ hiện HUD/toast trong play, làm HP trail, cinema bars và hướng dẫn theo input pad gần nhất.

`AbilitySigil.gd` vẽ glyph vector bằng `_draw` với kind/readiness/enabled/pulse. `CombatReadout.gd` project enemy position qua camera, giữ Dictionary damage trails theo instance_id và rebuild mỗi frame. `CombatFeedback.gd.receive_hit/receive_defense` nhận callback từ Duelist; `_draw` hiển thị hướng và số damage, shader veil cho low HP/defense. Feedback clock chỉ chạy khi play.

## Geometry và môi trường

`Form.gd` là RefCounted factory static cho material và geometry của combat/effect visuals; `box(..., collision=true)` gắn StaticBody3D/BoxShape. Map meshes đã serialize trong scene; Form vẫn tạo geometry runtime như projectile rings, bursts và seal crystals.

`scenes/rebirth/StillwaterMap.tscn` là PackedScene cho map 3D. Nó lưu geometry/collider/materials và MultiMesh batches của sân, cổng, điện thờ, ba trụ phong ấn, năm cây, sáu đèn, đá rìa sân, cỏ 2,200 blades, compass, banners, benches, braziers, mưa và fireflies. Nó instance `CourtyardBackdrop.tscn` cho 2 ridge MultiMeshes, 2 pagoda, 76 ripple instances, 65 lá bay và 6 lớp lake mist. Hierarchy chính gồm `CourtyardGround`, `MountainGate`, `MountainShrine`, `SealPlatforms`, `MapleTrees`, `Lanterns`, `ScatteredRocks`, `CourtyardDetails`, `Fireflies`, `Rain`, backdrop, `WorldEnvironment`, `KeyLight` và `Camera3D`.

`Stillwater.setup_map()` truy cập các node qua path cố định; seal roots là `SealPlatforms/Seal_01..03`, fireflies nằm dưới group tương ứng. `Stillwater.gd` tiếp tục điều khiển camera, Core và fireflies, còn `CourtyardDetail.attach_atmosphere()` tạo `CourtyardAtmosphere` runtime sau khi seal refs đã có. Chỉnh kích thước/vị trí/static mesh trong editor không cần sửa generator code; đổi tên node contract thì cần sửa `setup_map()`.

`CourtyardAtmosphere._ready()` chỉ dựng seal armatures và các inscription còn phản ứng với trạng thái seal/boss. `update_ritual_states()` poll world mỗi 0.1s để đổi inscription/light và spawn `SealBloom`; không điều khiển gameplay. Weather batches, ridges, pagoda và mist nằm trong backdrop scene. `SealBloom` tự giải phóng theo lifetime, chỉ visual, không collider.

Shader contracts (`scripts/rebirth/shaders/`): Weathered tint/grain; Lake deep; Foliage tint/wind_strength; Grass dùng vertex color; RainRipples/FallingLeaves cần MultiMesh custom data; LakeMist offset; SealInscription tint/strength/identity/engaged. Banner, palette, HUD gradient và damage veil có shader inline trong script, nên danh sách `.gdshader` chưa phải toàn bộ shader.

## Effects có gameplay

Tất cả dưới `scripts/rebirth/`, được world tạo và gán world/direction/source trước add_child:

| Script / API | Input, output, lifetime |
| --- | --- |
| `SpiritBolt.gd.reflect()` | Hostile projectile group; ray world mask 1; hit actor theo khoảng cách XZ; reflect bỏ group, đổi hướng về source, hồi stamina |
| `SwordWave.gd` | Hero spirit combo projectile; ray world; Array hit chống trúng lặp; damage qua enemy.hurt |
| `PressureWave.gd` | Visual sóng tiến, poll hostile_projectile để reflect; damage/launch nằm ở Stillwater.cast(1) |
| `RainEcho.gd` | Snapshot bone poses từ hero model; giữ life phục vụ recall; không collider/tether |
| `SealHazard.gd` | Chỉ khi encounter; báo trước 1.25s rồi gọi player.hurt trong radius; kết thúc encounter thì tự xóa |
| `StillnessBurst.gd` | CHARGE 0.22s, radius mở đến 5.8; damage lúc viền đến, mỗi enemy tối đa một lần, ray line of sight; reflect projectiles |
| `CombatImpact.gd` | Chỉ visual 0.2s, billboard về camera lúc tạo; dừng pause/upgrade/closing |

Các effect combat chặn world.mode/cinematic trước lifetime; visual atmosphere/SealBloom/shader TIME và tween burst không cùng cơ chế dừng. Điều này cần phân biệt khi sửa pause.

## Trước khi sửa

Đối chiếu `test_stillwater_ui.gd`, `test_courtyard_atmosphere.gd`, `test_combat_feedback_variants.gd`, `test_control_readability.gd` và capture tools. Headless không chứng minh render/font/SSAO/shadow đúng trên GPU. Các vòng lặp enemy và cấp phát nhiều effect là điểm cần profile nếu tăng mật độ combat; chưa có benchmark trong phân tích này.
