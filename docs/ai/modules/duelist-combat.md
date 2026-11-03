# 3D: actor, combat và skeletal animation

[Module index](../module-index.md) · liên quan [run](stillwater-run.md), [presentation](stillwater-presentation.md).

Nguồn: `scripts/rebirth/Duelist.gd` extends CharacterBody3D; `scripts/rebirth/CombatPuppet.gd` extends Node3D. Không class_name. Cùng Duelist được cấu hình thành hero, boss hoặc guard kind 0/1/2.

## Lifecycle và contract

`Duelist._ready()` cấu hình collider, body/puppet/weapon, HP theo role/difficulty và trail. Actor.world phải có player/enemies/mode và các callback combat. `build_body()` gắn puppet.actor trước add_child; puppet phải dựng hand để actor gắn blade ngay sau đó. Trail là sibling thuộc world, được xóa trong `_exit_tree()`.

Layer bit values: world 1, hero 2, enemy 4. Hero bình thường mask 5; dash/recall tắt layer và chỉ collide mask 1. Actor chạy trên mặt phẳng XZ, position.y được ép 0.05, clamp biên courtyard. Không gravity/navigation agent.

## State và public API

`action` dùng chuỗi idle, attack, dash, recall, windup, charge, cast, execute, launch, hurt, guard_break, block_hit, stunned, broken, arrive, dead. `timer/duration`, `released`, `cooldown`, `locked`, immunity và posture thuộc từng actor; world có quyền chỉnh trực tiếp.

`_physics_process()` chặn mode/cinematic trước các đồng hồ combat; dead chỉ cập nhật pose. Input được buffer, stamina/posture/knockback cập nhật, rồi hero `control()` hoặc enemy `think()`. Hit stop dừng pose/action timer trong thời gian ngắn; movement input vẫn chạy. `released` bảo đảm chỉ gọi `world.melee(self)` một lần mỗi attack khi đạt `contact_fraction()`.

- `start_attack()` tiêu stamina hero, combo 1..3, khóa facing; chi phí/timing khác nhau theo weapon 0 straight / 1 heavy / 2 spirit.
- `dash(direction)` tạo echo trước khi di chuyển, tiêu 20 stamina, immunity, bắt pending evade bằng WeakRef. `capture_perfect_evades()` + `resolve_perfect_evades()` thưởng khi né sát contact và enemy thực sự release; `reward_perfect_evade()` tối đa một lần/dash.
- `hurt(amount, source) -> bool`: false khi không hợp lệ, immunity hoặc hero block/parry. Enemy guard vẫn nhận damage giảm và trả true. Tính difficulty/buff qua world.incoming_damage; phát combat_event; death tắt collision, gọi world.fallen và tween xóa enemy.
- `apply_posture()` không áp hero/dead; không kéo dài broken đang có. Đạt 100 => broken 2.6s; boss interrupt_resist giảm posture gain. `launch()` giữ committed boss attack trừ khi thật sự break. `world.try_execute()` reset posture/grace/resistance nếu boss sống.
- `think()` có separation, ray obstacle steering và giới hạn attacker đồng thời; windup chỉ track sớm, cuối windup giữ locked. Không có pathfinding toàn bản đồ. Boss tăng kind mỗi chiêu để chọn chop/sweep/charge/pulse.

## Animation ownership

`CombatPuppet._ready()` chọn KayKit Rogue_Hooded cho hero, Mage cho ranged, Knight cho còn lại; tìm Skeleton3D/AnimationPlayer và `handslot_r`, ẩn vũ khí gốc. Những node/bone/clip này là contract của GLB imports.

`update_pose(delta)` sample action bằng seek + advance(0), gắn contact của source clip với actor.contact_fraction. Idle/run advance theo delta. Sampled action phải dùng blend 0; comment trong source giải thích blend clock không tiến khi advance(0), làm outgoing idle thắng mãi. Root bone x/z luôn reset để gameplay điều khiển chuyển động; head scale đặt lại sau pose. Hero có scarf ImmediateMesh và palette shader runtime (`retone()`). `AnimationTree` không được dùng trong nhánh này.

## Bất biến và kiểm tra trước sửa

Giữ contact geometry/timing khớp pose; không đổi tên clip/bone mà không kiểm tra GLB và `inspect_rig.gd`. Giữ cổng pause/cinematic trước regen/timer. Đổi `hurt` return semantics ảnh hưởng melee, projectile, execution và tests. Tránh prolong broken vô hạn; duy trì resistance sau execute boss.

Tests liên quan 3D: `test_combat_animation.gd`, `test_control_readability.gd`, `test_combat_mastery.gd`, `test_rain_combat.gd`, `test_run_director.gd`. Hai test tên mature_combat và combat_feedback_variants thuộc 2D; tra [test map](testing.md) trước chọn. Kiểm tra engine thực tế trước khi dựa vào kết quả lịch sử.
