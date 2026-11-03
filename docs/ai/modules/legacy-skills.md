# 2D: skill resources và effect contract

[Module index](../module-index.md) · [actor](legacy-actors.md).

`scripts/skills/SkillDefinition.gd` class_name SkillDefinition extends Resource: display_name, stamina_cost, cooldown, cast_range, targeting_mode enum SELF/FORWARD/POINT/NEAREST_ENEMY và effect_scene. Enum là data hiện có; SkillCaster không dispatch theo targeting_mode, nên không coi mọi mode đã triển khai đầy đủ.

`SkillCaster.gd` class_name SkillCaster extends Node, child của player. Giữ skills/cooldowns/active_slots/_auto_cast_timers, luôn normalize về SLOT_COUNT=5. Signals skill_slots_changed, skill_cast_failed, skill_cast_started, active_slots_changed. `try_cast_slot()` kiểm tra slot/resource/cooldown/cost/effect; đặt cooldown, instance và add effect vào current_scene (fallback root), gọi activate(context), rồi pay cost khi thành công. Boolean false trả cooldown về 0; effect có trách nhiệm tự xóa. Nếu thiếu activate thì vẫn tính là cast thành công: convention effect phải cung cấp method này.

Context Dictionary: caster, origin, direction, target_position, zone_range, zone_size, skill. Origin/direction/stamina lấy qua parent APIs. Transform zone lấy melee_range/melee_size nếu có. `toggle_slot()/activate_all_filled_slots()` bật auto cast mỗi 1s; keyboard player gọi try_cast trực tiếp, không tự toggle auto mode. Player defaults: Transform, ProtectiveDivineLight, MoonCleave, JadeTempest, Renewal; Resource trong `resources/skills/` trỏ scenes cùng tên.

| Effect script | Hành vi và ownership |
| --- | --- |
| `SkillEffect.gd` | Base class_name tồn tại nhưng chỉ activate rồi queue_free; các effect hiện tại extends Node2D trực tiếp, dùng duck typing |
| `TransformSkillEffect.gd.activate()` | Quét corpses trong radius 96, bỏ invisible/non-transformable; lấy corpse.scene_file_path (fallback Zombie), set faction zombie, speed nửa, damage/max-health copy **trước** add_child, xóa corpse sau tạo zombie |
| `ProtectiveDivineLightEffect.gd.activate()/refresh()` | Một orb/caster qua metadata protective_orb; cast lại refresh lifetime, xóa instance dư; tree_exiting chỉ bỏ meta nếu còn trỏ self. Orbit theo Time.get_ticks_msec, query mask 1, per-target hit dwell; bỏ zombies, có thể shatter breakables |
| `MartialSkillEffect.gd.activate()` | mode 0 MoonCleave projectile, 1 JadeTempest delayed AoE, 2 Renewal heal; hit_ids chống trùng; ray line of sight và hostile group. Renewal đầy HP => last_failure/false |

Risks cần đọc trước sửa: free skill cost<=0 bỏ qua can_spend_stamina; Transform báo success nếu thấy corpses nhưng không tạo được zombie; Protective orbit dựa wall clock nên pha có thể nhảy sau pause. Đây là behavior/risk từ code, không khẳng định đã tái hiện runtime. Tests: `test_transform_skill.gd`, `test_fire_lion_transform_rules.gd`, `test_player_transform_skill_slot.gd`, `test_player_effect_hosts.gd`, `test_chest_encounter.gd`.
