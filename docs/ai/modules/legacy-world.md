# 2D: world, navigation và encounter

[Module index](../module-index.md) · [actors](legacy-actors.md) · [UI/progression](legacy-interface.md).

Nguồn: `scripts/world/World.gd` extends Node2D; scene `scenes/world/World.tscn` được instance trong `scenes/main/Main.tscn`. Scene là composition contract, không suy từ tên thư mục.

`_ready()` đăng ký group world, spawn crates/trees, dựng AStarGrid2D, khởi động enemy/chest clocks, bảo đảm NightAmbience/AmbientMagic, thêm shadows và GameFeel nếu có Player/Hud. Child nodes đã ready trước World; GameFeel được tạo sau để kết nối lại signal/state.

## Public API và state

- `report_combat_message(message)` phát signal combat_message_requested; `report_slam(message, impact_position)` còn tăng slam_charge. `_spawn_smash_mark()` có định nghĩa nhưng report_slam không gọi nó.
- `has_slam_charge()/consume_slam_charge()` cung cấp bonus impact cho PlayerController; charge required = 3, chỉ consume khi melee landed.
- `get_path_direction(from_position, target_position)` tìm nearest walkable cell và trả hướng đến waypoint; fallback hướng thẳng nếu không có path hợp lệ. Grid diagonal ONLY_IF_NO_OBSTACLES, cell mặc định 32.
- `register_navigation_obstacle()/unregister_navigation_obstacle()` theo dõi cells theo obstacle cùng reference count từng cell. tree_exiting one-shot giải phóng các cells; không reset cell đang còn obstacle khác.

## Spawn và bounds

`_process()` dừng khi Player.is_defeated; spawn interval giảm theo elapsed_time có minimum. Cap đếm group hostile_enemies; corpse/zombie không tính. `_pick_enemy_scene()` chọn fire lion trước, fast enemy sau grace 20s. `_get_spawn_position()` chọn mép vùng spawn, không physics overlap test.

Crates/trees dùng RNG riêng randomize, thử placement dựa Rect2, chừa đường chữ thập/player/obstacles. Chests random rồi fallback quét grid; Vector2.INF nghĩa không có chỗ, caller không spawn. Kích thước blockers có fallback cố định; visual + collider bounds cho trees/houses. Nhiều phép bounds dùng world tọa độ quanh origin, cần xem lại khi đổi transform World.

`ChestEncounter.gd` Area2D: body_entered player => open; guard is_opened; potion gọi HealthComponent.heal, mimic instance ChestMimic vào Enemies rồi survival mode; phát message qua world group và xóa chest.

`BreakableCrate.gd.shatter()` idempotent, tắt layer/mask bit 1, fade/scale rồi queue_free 0.18s. Cell AStar được gỡ ở tree_exiting, không ngay khi tắt collider. Corpse settled đăng ký navigation obstacle dù collision_layer/mask = 0; xem actor contract.

## Trước khi sửa

Giữ `Enemies`, Player, Hud và các scene export references. Kiểm tra `test_world_*.gd`, `test_chest_encounter.gd`, `test_corpse_navigation.gd`. Đổi grid hoặc footprint tác động enemy chase, random placement và boss spawn (`GameFeel._begin_boss` gọi cả helper có tên private của World).
