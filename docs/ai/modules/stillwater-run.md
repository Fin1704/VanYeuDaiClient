# 3D: điều phối chương và tiến trình

Trở về [module index](../module-index.md). Nguồn chính: `scripts/rebirth/Stillwater.gd` (extends Node3D, không class_name), `scripts/rebirth/RunDirector.gd` (RefCounted). Entry: `scenes/rebirth/Stillwater.tscn`.

## Trách nhiệm, ownership và lifecycle

`Stillwater._ready()` gắn `director.world`, gọi `setup_map()` để lấy node từ `StillwaterMap.tscn` và gắn visual observer, rồi tạo ACTOR với `hero = true`, gắn `player.world` **trước** `add_child`, tiếp theo CanvasLayer/StillwaterUI và tám audio voices. Root scene sở hữu actor/effects/UI; map scene sở hữu geometry, camera, environment, light, rain và fireflies. `setup_map()` duplicate Environment theo từng root. `rng.seed = 47029`; sau khi setup map, `rng.state` được đặt về terminal state của bộ dựng cũ để giữ chuỗi random gameplay.

`mode` là cổng logic: `title`, `play`, `pause`, `upgrade`, `defeat`, `victory`, `closing`. Root PROCESS_MODE_ALWAYS; việc dừng combat dùng kiểm tra mode/cinematic chứ không SceneTree.paused. `_process` vẫn animate fireflies, seal Core và camera trước cổng `play`. `Duelist._physics_process` kiểm tra cùng contract.

Map node-path contract được mô tả trong [presentation](stillwater-presentation.md); đổi tên `SealPlatforms/Seal_01..03`, `Camera3D`, `KeyLight`, `WorldEnvironment` hoặc `Fireflies/Firefly_01..35` cần cập nhật `setup_map()`.

## API và call flow

- `start_run()` chỉ từ title; `resume()` trở lại play, bỏ modal, release dash.
- `interact()` ưu tiên `try_execute()`, sau đó seal gần chưa hoàn thành trong bán kính 2.5. Ghi checkpoint trước encounter; wave có `4 + round_index*2` guard, đồng thời tối đa bốn enemy sống.
- `spawn_guard()` thiết lập kind/world/position trước khi add_child; physics query thử 18 vị trí với mask 1|2|4. Có fallback nếu không tìm được điểm (xem known-issues).
- `complete_seal()` đánh dấu seal, tăng round/score/flow, hồi HP/stamina. Hai round đầu chuyển mode upgrade; round ba ghi checkpoint rồi `begin_boss()`.
- `prepare_upgrades()` chia sáu Dictionary vào hai nhóm cố định ba lựa chọn. `upgrade(choice)` cập nhật director.bonuses và chỉ số actor, resume, rồi ghi checkpoint.
- `begin_boss()` tạo cùng ACTOR với boss flag, cinematic 1.65s. `RunDirector.update()` chuyển phase hai khi HP <= 50%; `enter_boss_phase_two()` hủy hostile_projectile, điều chỉnh posture và camera/notification.
- `fallen(actor)` ghi kill hoặc defeat/victory. Chỉ victory lưu best time/settings.

## Combat API giữa module

`melee(attacker)` được Duelist gọi đúng contact_fraction; lọc reach + cone + ray mask 1 rồi gọi `target.hurt()`, posture, interrupt. Ranged kind 2 tạo SpiritBolt; hero spirit blade combo ba tạo SwordWave.

`cast(0)` kiểm tra echo, đường về bằng ray mask 1, stamina và cooldown; sát thương dọc segment được tính ngay, actor di chuyển theo action recall sau đó. `cast(1)` tạo PressureWave phản đạn và launch các enemy trong cone có line of sight. `heal()` tiêu wine. `activate_surge()` tiêu 100 flow, tạo StillnessBurst, buff sáu giây. `incoming_damage()` áp difficulty cho player, director damage multiplier khi source là player.

`combat_event(kind, actor, source, amount)` chuyển thẳng đến `RunDirector.record()`. Các loại được record: hit, damage_taken, parry, perfect_dodge, execution, recall, crash, kill, posture_break. Director giữ flow/chain/score/stats/bonuses/hints; UI đọc trực tiếp và `run_report()` trả Dictionary rank S/A/B/C. `guard_break` được phát từ Duelist nhưng không có nhánh record tương ứng.

## Persistence và chuyển scene

`capture_checkpoint()` lưu seal flags, round, weapon, max_hp, damage_bonus, wine, director.snapshot, position, kills. Không serialize ra đĩa. `retry_from_checkpoint()` gọi deferred `_retry_checkpoint()`; tạo root Stillwater mới, truyền persist_progress, add_child rồi đặt current_scene, restore, queue_free root cũ. `restore_checkpoint()` hồi đầy HP/stamina, đảm bảo ít nhất hai wine, giữ run_time/retries; nếu round ba thì dựng lại boss. RNG, cooldown, echo, encounter đang dở và từng enemy không thuộc checkpoint.

`save_settings()` ghi `user://stillwater.cfg`: settings shake/difficulty/sound, run.best; có cổng `persist_progress`. `_ready()` vẫn đọc file khi cổng false, chỉ bỏ qua difficulty trong trường hợp đó. Không có save toàn bộ run.

## Trước khi sửa

- Đọc [3D actor](duelist-combat.md), [presentation](stillwater-presentation.md) và test `test_stillwater*.gd`, `test_run_director.gd`, `test_combat_mastery.gd`, `test_rain_combat.gd`.
- Giữ thứ tự world/hero/boss/kind được gán trước add_child vì `_ready()` dùng chúng.
- Đổi mode/checkpoint/upgrades phải đối chiếu cả StillwaterUI và RunDirector.snapshot/restore.
- Input 3D gồm InputMap runtime và raw key events; không suy ra từ project.godot một mình.
- Hiệu năng mesh/effect allocation, enemy array và metadata save errors: xem [known issues](../known-issues.md). Runtime chưa được bảo đảm chỉ từ phân tích tĩnh.
