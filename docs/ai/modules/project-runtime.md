# Project, entry points và resource contracts

[Module index](../module-index.md) · [architecture](../architecture.md).

## Stack xác minh tại snapshot

`project.godot`: config_version=5, config/name Moonlit Jianghu, config/version 0.4.1, features Godot 4.7 + Forward Plus. Native binary tìm qua `.vscode/settings.json` đã trả `4.7.2.stable.official.ed1daf0bf` bằng --headless --version; đường máy cụ thể là local config chưa tracked, không phải dependency portable. Không có C#, .csproj/.sln, addons, npm/NuGet manifest trong inventory nguồn.

Runtime GDScript + Godot shader language; offline asset/build scripts Python. 3D physics Jolt, Windows rendering device d3d12. Viewport 1280×720, stretch viewport, custom NotoSansSC font, HDR 2D=true và pixel snapping=true; Stillwater._ready override viewport HDR2D=false và MSAA3D 4x. Không suy version từ README cũ (ghi 4.6.2).

## Entry points và scene tree

| Entry | Bootstrap / composition |
| --- | --- |
| `scenes/rebirth/Stillwater.tscn` (default) | Một Node3D + Stillwater.gd, dựng runtime environment/actors/camera/UI |
| `scenes/interface/TitleScreen.tscn` | Control + TitleScreen.gd, start đổi sang Main |
| `scenes/main/Main.tscn` | Main Node2D instance World.tscn |
| `scenes/world/World.tscn` | Ground, Buildings, Landmarks, Breakables, Trees, Boundaries, Player, Enemies, Chests, Hud; script tạo ambience/GameFeel |

30 scene `.tscn` đã đọc; tái sử dụng bằng PackedScene instance/overrides, không thấy scene root kế thừa một PackedScene khác. Basic/Fast/Lion/Mimic/Zombie scenes độc lập cùng gắn BasicEnemy.gd. Public Resource class_names chỉ HealthComponent, SkillDefinition, SkillCaster, SkillEffect; các tên Stillwater/Duelist/Form là script basename aliases qua preload, không global class_name.

## Input và singleton

InputMap project gồm movement, attack, defend, dash, reset_scene, open_deck/use_card_1..4, use_selected_skill, pause_game, select_skill_1..5, toggle_night, toggle_inventory, interact. Tồn tại action chưa đủ chứng minh feature: open_deck/card bindings là dấu vết cũ, không tìm thấy gameplay handler trong source đã đọc.

3D Stillwater.configure_gamepad tạo action aim/skills/wine/seal/cycle/surge và pad events runtime; _unhandled_input nhận raw Q/E/R/F/V/1..3/Esc/F11. 3D Space đi qua use_selected_skill thành dash; 2D Space cast selected spell; R 2D reload, 3D heal. Chỉ Soundscape autoload.

## Resource identity

Scene ext_resource dùng path res://, một số thêm UID; script/shader `.uid` và asset `.import` giữ identity. Generated cache `.godot` được bỏ qua. Dynamic path formatting/load theo chuỗi trong player/skills/audio không hiện đầy đủ trong static scene graph; kiểm tra cả code trước rename/move resource. Knowledge base có [source inventory](../source-inventory.json) để định vị path/symbol và hash, không thay Godot UID resolver.

## Export configuration

`export_presets.cfg`: iOS, iOS 2, Windows Desktop (x86_64, external PCK, unsigned), macOS (universal, notarization=0). iOS entries thiếu output path/bundle id, không bằng chứng mobile release sẵn sàng. Tất cả all_resources; desktop exclude tools/tests/docs/output/tmp/unused và một số raw images. Direct editor export full repo không tương đương allowlisted 3D package (xem [tooling](tooling-release.md)). Privacy defaults đã khảo sát cấu trúc; không đưa identity/signing secrets vào tài liệu.

Không có app/network/backend/service database dependency được thấy trong GDScript đã đọc. Persistence chỉ local ConfigFile như [data flows](../data-flows.md). Không tự suy có multiplayer/server từ tên workspace.
