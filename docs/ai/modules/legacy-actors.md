# 2D: player, health, enemies và boss

[Module index](../module-index.md) · [world](legacy-world.md) · [skills](legacy-skills.md) · [interface](legacy-interface.md).

## PlayerController

`scripts/player/PlayerController.gd` extends CharacterBody2D. `scenes/player/Player.tscn` cung cấp Body, FacingMarker, SelectionRing, HealthComponent, GuardRing, DamageRing, AttackPreview/Visual, SkillCaster, Sword và Camera2D. `_ready()` nạp atlas, tạo visual/WeaponRig, nối health và skill signals, khởi tạo stamina/default slots rồi phát state cho HUD.

Signals: stamina_changed, exhaustion_changed, blocked, combat_message_requested, skill_slots_changed, active_skill_slots_changed. API cho caller: `apply_incoming_damage`, `handle_enemy_attack`, `apply_attack_hitback`, `is_attack_target_active`, `set_equipped_weapon`, `can_spend_stamina/spend_stamina`, `get_skill_origin/direction/slot_names`.

`_physics_process()` có buffer attack 0.18s, delayed `_resolve_melee_attack()` tại 48% animation, input movement/guard/dash/skill và texture animation. Combo 1..3 giữ trong 0.85s. Rectangle shape query tối đa 16 hits, loại zombie và trùng collider, ray kiểm tra vật cản; áp knockback/stagger/back-hit/counter/momentum/charged impact rồi HealthComponent.take_damage. Charge chỉ consume nếu landed; `_apply_hit_pause()` tăng recovery cục bộ, không pause tree.

`handle_enemy_attack()` là đường có perfect guard/counter, `apply_incoming_damage()` là damage chung có dash/immunity/flat block. Không hoán đổi hai API tùy tiện. Stamina hết => exhausted đến khi hồi **đầy**, không phải vừa đủ attack cost. Dash hủy attack pending/visual và tạo afterimage. `set_equipped_weapon()` thay timing/cost/damage/shape/range cho iron_sword/heavy_saber/jade_sword.

Atlas contract: run 6×5 thứ tự down_left,left,up_left,up,down, FPS 10; mirror phải khi x>0. Idle 6×3 down/up/left, FPS 1; attack thật dùng `assets/art_v2/player_attack_aligned.png` 160×224/cell, ba hàng down/left/up; death từ `assets/xianxia/players_attack.png` 6×5, hàng 3, FPS 8. `WeaponRig.gd` vẽ vũ khí theo hand sockets được author theo sáu frame; đừng thay grid/anchor đơn lẻ. Atlas slicing được cache Dictionary, không AnimatedSprite2D.

## HealthComponent

`scripts/components/HealthComponent.gd` có class_name HealthComponent, extends Node. `_ready()` set current = max và emit health_changed. `take_damage()` bỏ amount<=0 hoặc đã chết; emit damaged -> health_changed -> died khi về 0. `heal()` không hồi sinh đối tượng đã chết. Max/current là integer; nhánh 3D dùng float riêng, không component này.

## BasicEnemy, faction và corpse

`scripts/enemies/BasicEnemy.gd` dùng cho BasicEnemy/FastEnemy/FireLionEnemy/ChestMimic và Zombie scenes qua cấu hình export; không GDScript subclass riêng cho mỗi loại. `_ready()` nạp atlas, visuals, group enemies + hostile_enemies hoặc zombies, target, health signals và light. `set_survival_mode(true)` bỏ leash bằng radius rất lớn. `find_nearest_target()` quét player/zombies nếu hostile, hostile_enemies nếu zombie; bỏ inactive target. `_get_path_direction()` gọi World AStar rồi local ray steering; `_compute_separation_force()` quét enemies.

Attack: range => windup => `_try_damage_player()` chọn handle_enemy_attack, apply_incoming_damage hoặc HealthComponent.take_damage; attack_hitback chạy sau callback. API ngoài: apply_knockback, apply_recoil, apply_stagger, is_hit_from_behind, is_transformable_corpse, settle_dead_body. Slam collisions phân biệt enemy/crate/wall, deduplicate collider và report_slam.

Death: zombie hoặc destroy_on_death => queue_free; hostile thường => is_dying, group corpses, bỏ hostile, flight -> settle -> lifetime/fade -> queue_free. `settle_dead_body()` tắt physics collision nhưng đăng ký AStar obstacle; tree_exiting tự unregister qua World. Fire lion không transformable, vẫn có corpse lifecycle và tắt accent light khi chết. Transform tạo node mới, không heal corpse cũ.

Enemy run atlases 6×5 cùng row ordering với player, FPS 7; diagonal chỉ chọn khi angle 40..50 độ, khác player sign-based direction. Attack atlas 6×5 lấy down/side/up; fire lion/zombie dùng visual run riêng. Light texture 256² được dựng trong mỗi enemy `_ready`, kể cả non-lion: điểm profile được ghi ở known-issues.

## MountainGuardian

`scripts/boss/MountainGuardian.gd` là CharacterBody2D riêng, scene có HealthComponent. State approach -> windup/charge/recover, mỗi attack thứ ba pulse_windup -> pulse/recover. Lock target ở đầu windup; `_release_pulse` gọi player.handle_enemy_attack, JadeTempest instance chỉ visual (không activate/caster). `apply_stagger()` là no-op; knockback giới hạn. Death bỏ hostile, tắt collision, phát defeated, fade/xóa. GameFeel đếm boss qua HealthComponent.died và group boss.

## Trước khi sửa

Kiểm tra tests player damage/effect-host/transform-slot, weapon timing, enemy direction/hit/corpse lifecycle/navigation, zombie targeting, fire-lion rules/light và boss telegraph. Đổi group/health signal/node path phải kiểm tra skills, HUD, GameFeel và World, không chỉ actor.
