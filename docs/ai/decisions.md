# Quyết định kiến trúc có bằng chứng

[Index](README.md). Đây là ledger của implementation đã thấy, không tự dựng lại động cơ tác giả. Trade-off ghi **nhận định phân tích** khi không phải lý do có comment/tài liệu hỗ trợ. VERIFIED_STATIC không tương đương đã chạy game.

| Quyết định đã triển khai | Bằng chứng | Lý do / giới hạn |
| --- | --- | --- |
| Giữ hai entry 3D default và 2D độc lập | project.godot run/main_scene; TitleScreen.start_game; Main.tscn | README/CONTRIBUTING xác nhận giữ 2D archive; không có migration thống nhất hai combat systems |
| Map 3D được serialize thành scene, orchestration giữ ở GDScript | Stillwater.tscn instance StillwaterMap.tscn; scene này instance CourtyardBackdrop.tscn; Stillwater.setup_map | Geometry/collider/material, cảnh xa, lá/mưa/mist nằm trong PackedScenes; gameplay/camera tracking và seal-reactive visuals còn runtime. RNG terminal state được giữ để bảo toàn chuỗi gameplay hiện tại. Lý do: yêu cầu chuyển map sang scene để chỉnh trong editor. Render/gameplay parity sau wiring chưa được xác minh |
| Một Duelist script cho hero/guard/boss | Stillwater.spawn_guard/begin_boss, Duelist._ready/think/control | Lý do lịch sử **UNVERIFIED**; role flags và kind là contract thực |
| Manual animation timing khớp hit | CombatPuppet.update_pose, Duelist.contact_fraction | Comment source giải thích advance(0) không đẩy blend clock; sampled clips dùng blend 0 để tránh outgoing idle giữ pose |
| Pause combat clock trước regen | Duelist._physics_process đầu hàm, projectile guards | Comment source nêu menu/cinematic không refill stamina/consume counter window; các test mastery/director assert invariant |
| Hit pause cục bộ | PlayerController._apply_hit_pause; Duelist pose_delta | Comment 2D tránh tranh chấp pause menu/inventory; 3D comment và tests giữ movement input |
| Broken có deadline, boss có recovery | Duelist.apply_posture/launch; Stillwater.try_execute | Comments ngăn stun/execution loop vô hạn và bảo toàn committed boss move trừ khi posture thật sự break |
| Checkpoint in-memory, rebuild root khi retry | Stillwater.capture_checkpoint/_retry_checkpoint/restore_checkpoint; RunDirector.snapshot | docs/STILLWATER xác nhận không có quit-resume save; rollback score nhưng giữ run_time/retries |
| Dynamic AStar obstacle reference counts | World.register_navigation_obstacle/unregister_navigation_obstacle/_add_path_solid_id/_remove_path_solid_id | Behavior đã thấy; lý do tác giả không ghi riêng. Nhận định: tránh clear cell khi còn obstacle chồng lấn |
| Transform clone source scene, copy stats trước ready | TransformSkillEffect._get_source_scene/_copy_zombie_stats/activate | Test giữ max HP/damage và half speed; fire lion opt out; không dùng HealthComponent.heal để revive |
| Một protective orb mỗi caster | ProtectiveDivineLightEffect.activate/refresh/_on_tree_exiting | Metadata protective_orb, refresh thay tạo orb stack; cleanup kiểm current == self |
| Tắt loop music, giữ Foley/stingers | Soundscape._ready comment; compose/synthesize tools, Stillwater.combat_sound | Comment nói chừa không gian cho combat Foley; file nhạc cũ được giữ |
| Release dùng staging allowlist 3D | package_release.FILES/DIRECTORIES/main; docs/DEVELOPMENT, LICENSE_SCOPE | Tài liệu repo nêu tách legacy art/scratch khỏi package, giữ notices; không xác minh external release artifact |
| Raw asset giữ nguyên, derivative sibling | AGENTS Asset Workflow; prepare/extract tools | Quy tắc repo bảo toàn source/motion; không ghi đè trong đợt tài liệu |

## Entry bảo trì 2026-11-03

Thêm AGENTS bootstrap/CLAUDE adapter và `docs/ai/` với 13 module notes, dependency/data-flow maps, issue/coverage ledger và inventory validator. Trong đợt đó không sửa gameplay, config, asset hoặc test logic; các file đã thay đổi từ trước được giữ nguyên. Follow-up cùng ngày theo yêu cầu người dùng đã chuyển geometry Stillwater sang `StillwaterMap.tscn`, nối node refs từ `Stillwater.gd` và giữ `CourtyardAtmosphere` runtime. Tác động: map geometry có thể chỉnh trong editor; run orchestration vẫn ở code. Runtime/render parity chưa được xác minh.
