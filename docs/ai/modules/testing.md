# Test map và mức bảo đảm

[Module index](../module-index.md) · [tool runner](tooling-release.md) · [coverage](../analysis-coverage.md).

Snapshot có **36 GDScript test scripts + 3 Python test files**. Đã đọc toàn bộ code test, không chỉ glob tên. Test script Godot extends SceneTree, tạo scene/actor hoặc fake world, gọi helper và await process_frame/physics_frame/timer. Failure thường push_error + counter rồi quit(failures); runner kiểm tra cả engine ERROR, tránh exit 0 giả khi script lỗi. Một số test cũ thao tác từ `_initialize` trực tiếp, một số deferred run. Không có framework test Godot bên ngoài.

## Chọn test theo thay đổi

Các path sau ở `tests/`; tên module dựa scene được preload, không dựa chữ combat trong tên.

| File | Nhánh / contract được assert |
| --- | --- |
| `test_stillwater.gd` | 3D title/start/input/attack/dash/parry/pause, seal->upgrade->boss->victory |
| `test_stillwater_combat.gd` | 3D projectile/wine/heavy interrupt/skill cost/boss pulse warning |
| `test_stillwater_ui.gd` | 3D button + input navigation, guide Esc, layout bounds, upgrade shortcut không đổi weapon, checkpoint retry |
| `test_run_director.gd` | 3D damage difficulty/mastery/surge one hit/pause/echo upgrade/cinematic projectile/checkpoint rollback/boss resistance |
| `test_combat_mastery.gd` | 3D pause clocks/perfect evade/guard break/committed windup/fixed break deadline/boss posture/robe/scarf |
| `test_combat_animation.gd` | 3D chín weapon-combo samples yêu cầu bone upperarm.r rời idle và tiếp tục chuyển động |
| `test_control_readability.gd` | 3D movement/dash stop, movement trong hit stop, hurt feedback, glint/attack cone/stamina rejection |
| `test_rain_combat.gd` | 3D input-to-contact ticks, skeleton, recall line/end/no echo, shove/execute/reflect và actual wall collision |
| `test_courtyard_atmosphere.gd` | 3D observer với RitualWorld/RitualBoss fake: transition bloom một lần, không đổi gameplay, cleanup |
| `test_mature_combat.gd` | **2D**: năm skills, dash/immunity, Renewal cost/refund, combo, pause, MoonCleave, 24 kills->boss->result |
| `test_combat_feedback_variants.gd` | **2D**: TimedEffect config, variant priority impact>counter>back>momentum, one message/multi-hit, impact whiff giữ charge |
| `test_inventory_ui.gd` | 2D initial items, pause/resume, bag/equipment swap và sword visibility |
| `test_journey_controls.gd` | 2D movement/dash/number cast, interactive pause và inventory |
| `test_weapon_timing.gd` | 2D delayed windup, dash cancel không release, weapon cadence, sáu attack frames |
| `test_boss_telegraph.gd` | 2D MountainGuardian locked charge và attack thứ ba pulse |
| `test_viewport_layout.gd` | Project settings 1280×720, viewport stretch, aspect default keep |
| `test_hud_visual_polish.gd` | Base HUD riêng: panel/bar styles, icon assignment, hint fade; không bao hết skin GameFeel |
| `test_player_damage_feedback.gd` | 2D body flash/pulse/ring, attack hitback và HUD low-health threshold hai HP |
| `test_player_effect_hosts.gd` | 2D current_scene=null fallback, afterimage không engine error, light nodes |
| `test_player_transform_skill_slot.gd` | 2D default slot 0 có Transform |
| `test_transform_skill.gd` | 2D revive Basic/Fast corpse, copy stats/half speed/tint, consume corpse, radius miss |
| `test_zombie_targeting.gd` | 2D group/nearest target, hostile gây damage zombie, green tint và zombie chết không corpse |
| `test_enemy_corpse_lifecycle.gd` | 2D settle tắt collision, lifetime 10s + fade |
| `test_enemy_corpse_visual.gd` | 2D corpse group/texture/accent |
| `test_corpse_navigation.gd` | 2D register/unregister dynamic corpse đổi path direction |
| `test_enemy_hit_feedback.gd` | 2D warm flash/pulse/HP bar |
| `test_enemy_direction_quantization.gd` | Fire lion cardinal/40..50° diagonal, rows và mirror |
| `test_fire_lion_enemy.gd` | Fire-lion atlas/down row và world scene selection |
| `test_fire_lion_light.gd` | Night/day light radius/energy/color/flicker, death dark |
| `test_fire_lion_transform_rules.gd` | Cấm resurrect fire lion, không tạo zombie |
| `test_chest_encounter.gd` | Spawn helper, potion, mimic position/HP/faction/death |
| `test_world_random_breakables.gd` | Crate count/ranges/overlap avoidance |
| `test_world_enemy_spawn_positions.gd` | Mép spawn trong bounds, home initialized trước ready |
| `test_world_firefly_ambience.gd` | NightAmbience nodes/layers/particle scale/glow/light, không test hero-firefly scaffold |
| `test_pixel_art_scene_visuals.gd` | Terrain/props/curated houses, tuft generation helper và grass exclusion (xem hạn chế bên dưới) |
| `test_retro_xianxia_entity_visuals.gd` | Texture/atlas rows/mirror/body/sword/idle/accents của 2D |
| `test_extract_idle_sheet.py` | pytest: năm tests bbox/grid/crop/white cleanup |
| `test_white_background_flood_cutout.py` | unittest: một test white boundary removal, giữ white kín |
| `test_sprite_sheet_cleanup.py` | main() kiểm actual PNG fringe <=80, phải chạy trực tiếp |

## Lệnh và side effects

Từ repo root, với binary phù hợp trên PATH:

```powershell
python scripts/tools/run_tests.py tests/test_run_director.gd tests/test_stillwater_ui.gd
python scripts/tools/run_tests.py
python -m pytest -q tests/test_extract_idle_sheet.py tests/test_white_background_flood_cutout.py
python tests/test_sprite_sheet_cleanup.py
```

Runner đòi lệnh godot, không tự đọc VS Code editorPath. Chọn binary/config sau khi đọc [version drift](../known-issues.md). Import có thể tái tạo `.godot` và metadata; kiểm tra git diff sau chạy. Tests/captures có thể đọc user:// settings; persist_progress=false chỉ chặn ghi theo từng implementation. Không chạy auto-play/capture để thay thế test logic và ngược lại.

## Validation của đợt knowledge base

- Chỉ chạy binary --version, không full Godot suite/export/render vì thay đổi chỉ tài liệu. Không tuyên bố 36/36 pass ở working tree này; các con số trong README/STILLWATER là lịch sử.
- Đã thử Python pytest và fringe script; interpreter thiếu pytest/PIL nên chưa chạy assertion. Không tự cài dependency hoặc thay source.
- Chạy `python docs/ai/validate_knowledge.py` để kiểm source hashes, coverage entries, source symbols, file references và Markdown links trong knowledge base. Đây là kiểm tra tài liệu, không parser/engine compile.

## Khoảng trống có bằng chứng

`test_pixel_art_scene_visuals` hai bài exclusion tạo Grassland rồi loop các Sprite descendants nhưng không gọi `_generate()` hoặc assert số sprite >0; Grassland._ready chỉ generate trong editor. Vì vậy loop có thể rỗng trong headless test, chưa chứng minh exclusion thực hoạt động. `test_zombie_targeting` message nói player-attackable nhưng assertion chỉ group enemies; PlayerController melee bỏ zombies. `test_chest_encounter` tên nói after two minutes nhưng gọi spawn helper trực tiếp, chưa verify clock 120s. Test names/messages không phải source of truth.

Native render, imported bone hierarchy, controller vật lý, hiệu năng dài hạn, release templates/signing/notarization và full save/error paths vẫn cần kiểm riêng nếu task liên quan.
