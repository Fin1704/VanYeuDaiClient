# 2D: UI, inventory, progression và presentation

[Module index](../module-index.md) · [world](legacy-world.md) · [actor](legacy-actors.md) · [shared audio](shared-audio.md).

## HUD và inventory

`scripts/ui/Hud.gd` extends CanvasLayer, scene `ui/Hud.tscn`. `@onready` có node paths sâu cho StatsPanel, SkillBar Slot1..5, InventoryOverlay và BagSlot1..6; rename scene node phải sửa script + tests. PROCESS_MODE_ALWAYS cho phép menu khi tree pause. `_ready()` nối signal player/HealthComponent và đọc initial state vì child HealthComponent đã emit trước đó. World group được đăng ký trong World._ready sau Hud child ready; đường message world này cần kiểm tra runtime (known-issues).

HUD sở hữu `equipped_items`, `bag_items`, `item_definitions` in-memory. Click bag => swap equipment nếu slot hợp lệ; unequip => first empty bag, full thì từ chối. `_sync_player_equipment_visuals()` chỉ gọi set_equipped_weapon; không áp armor stats. Talisman/healing pill có definition nhưng không có use behavior trong handler. `_open_inventory()` lưu previous paused, pause tree; `_close_inventory()` phục hồi previous state. Meta journey_modal chặn input khi UpgradeChoice đang giữ pause.

`BattleLayout.install(hud)` do GameFeel gọi, thêm BattleChrome, portrait, SkillSigil, đổi layout/font và skin inventory. Các label skill được GameFeel cập nhật lại mỗi frame, khác base Hud signal rendering. `ItemGlyph` dùng WeaponRig cho vũ khí và `_draw` cho item khác. `JianghuTheme` là static factory font/theme/StyleBox; không phải autoload. `OffscreenIndicators` (scene HUD gắn) poll camera/group hostile_enemies/zombies/chests để vẽ edge arrows. `JourneyMap` poll world/player, dùng map scale cố định 1440×960.

## Progression và feedback

`scripts/polish/GameFeel.gd` được World tạo runtime, group game_feel; giữ kills/stage/boss/completed, weakrefs trong health callbacks và observed instance IDs. `_observe_enemies()` chạy lúc ready, Enemies.child_entered_tree deferred và mỗi 0.25s; nối damaged/died. `impact()` camera shake + tổng hợp WAV tại runtime có sound cooldown.

`_enemy_defeated()` tăng kills; mốc 6/14 => stage, heal/stamina, deferred UpgradeChoice; mốc >=24 => deferred `_begin_boss()`. Boss spawn dừng World._process, xóa hostile cũ, chọn walkable cell qua private helpers của World, tạo MountainGuardian và health bar. Boss chết => completed, dừng hostile physics, ResultScreen. Player chết => result(false). Victory tắt player physics. `user://journey.cfg` chỉ lưu best kill count, không save run. Đồng hồ `world.elapsed_time` ngừng ở boss vì world.set_process(false).

## Menu và scene transition

`TitleScreen.start_game()` guard starting, fade rồi change_scene_to_file Main. `_ready()` unpause. Guide/settings là procedural modal. `UpgradeChoice.select(index)` guard resolved, bỏ meta, release skill input 1/2, unpause, emit chosen; GameFeel._apply_upgrade sửa damage hoặc max-health và spawn pressure. `ResultScreen` restart hoặc về TitleScreen, luôn unpause trước transition.

`PauseMenu` poll tree.paused, inventory_open và journey_modal để quyết định visible; settings.cfg lưu shake/sound. Hud nhận Esc và toggle tree.pause; PauseMenu không tự quản lý pause ownership. Không áp pause contract 3D vào đây.

## Effects/phụ trợ

`VillageLantern` do GameFeel tạo gần buildings, light chỉ visible khi NightAmbience.visible. `TimedEffect.configure()` nhận tint/start/end/lifetime; `_process` fade/scale/free, dùng bởi HitSpark/ResurrectionAura/Puff/SmashMark scenes. `SlashTrail.setup()` nhận facing/variant để dựng ribbon, tự fade/free; tham số melee_range hiện không dùng. Các effect host lấy current_scene hoặc parent/root theo caller.

Trước sửa đọc tests inventory_ui, hud_visual_polish, viewport_layout, journey_controls, weapon_timing, player_effect_hosts và boss_telegraph. UI dùng layout 1280×720; kiểm tra render riêng sau đổi geometry/font. Không coi item placeholder hoặc artifact lịch sử là feature đã triển khai.
