# Quy ước thực tế và invariants

[Index](README.md) · quy tắc bắt buộc tại [AGENTS](../../AGENTS.md). Đây là quan sát từ source; không áp một style mới bằng refactor ngoài task.

## Code và resource naming

GDScript dùng tabs, snake_case functions/vars/signals, UPPER_CASE constants, PascalCase script/scene filenames. `@export` cho settings có thể override trong scene, `@onready` cho named node dependency; một số scripts dùng typed variables/return values, một số duck typing. Python tools có cả CLI main guard và top-level executable scripts; xem module trước import. `.editorconfig` UTF-8; `.gitattributes` text auto, LF. UI text Chinese + tên kỹ thuật English, không có localization framework được thấy.

Global class_name chỉ HealthComponent/SkillDefinition/SkillCaster/SkillEffect. Script aliases F/ACTOR/STYLE dùng preload; không tự thêm class_name cho mọi file. Không có C# partial/interface conventions vì không có C# source. Không thấy GDScript custom inheritance ngoài base engine types trong runtime hiện tại; SkillEffect base tồn tại nhưng concrete effects dùng activate duck typing.

## Lifecycle và state ownership

- Set world/actor/role/config trước add_child nếu `_ready()` cần; sau instantiate chưa ready, sau add_child có thể đã ready ngay.
- Scene nodes/path là contract, nhất là Hud, BasicEnemy và player 2D. Kiểm script, scene và tests cùng lúc khi rename.
- 3D game mode và cinematic gate phải chặn combat timers/regen/projectiles; 2D dùng tree pause, ALWAYS UI và journey_modal. Không trộn hai cơ chế theo tên file chung.
- `HealthComponent.heal` không revive; Transform tạo instance mới. Dead hostile/group/nav cleanup phải giữ đúng thứ tự.
- Queue_free là deferred; các loops giữ actor references dùng is_instance_valid trước truy cập. Tests có cả free ngay và await frame; không dùng reference đã giải phóng.
- Sibling trail/effects cần cleanup owner rõ ràng. CombatPuppet manual sampling phải advance/seek đúng contract, không thêm timed blend cho sampled action.
- Shared Resource/shape/material có thể dùng chung giữa instances; xem code có duplicate hay tạo mới trước khi mutate. Đừng cho runtime cooldown/state vào SkillDefinition shared resource.

## Error handling và logging

Runtime ưu tiên guard/early return, optional get_node_or_null/has_method và UI failure messages; required node paths không có fallback tổng quát. `SkillCaster._fail` phát skill_cast_failed; effect.last_failure làm message tùy effect. Một số texture loaders thử Image fallback rồi push_error. Config load có fallback; save return thường bị bỏ qua.

Godot tests dùng failure count + push_error + quit; Python runner còn kiểm chuỗi ERROR và timeout. Python asset CLI để exceptions nổi lên khi thiếu input/sai grid. Capture tools print diagnostics/JSON có prefix; không coi log FPS ghi movie là hardware benchmark. Không ghi secrets hoặc local user settings contents vào docs/logs.

## Engine/asset compatibility

Phân biệt project feature version (4.7), installed binary (4.7.2) và packager pin (4.6.2). Không sửa config để làm khớp tài liệu cũ. Import cache `.godot` không phải authoring source; `.uid`/`.import` giữ metadata và cần review diff có chủ đích. Native rendering và headless logic là hai mức kiểm khác nhau; assertions về resource/property không chứng minh shader/render/GPU frame time.

Giữ original sprites/GLBs; derivatives là sibling. Sprite rows/grid/mirror/anchor là API giữa Python extractor và actor slicing. Lệnh cutout/validation có tại AGENTS. Artwork manifests/plans có thể cũ, luôn đối chiếu asset path thực đang load.

## Cập nhật knowledge base

Thay API/state/ownership/dependency/flow => sửa module tương ứng và trang tổng hợp bị ảnh hưởng; thay nhỏ không rewrite tất cả. Ghi source path + symbol; unknown reason => UNVERIFIED. Chỉ ghi behavior đã triển khai, proposal giữ trong plan. Khi change lớn, thêm entry decisions gồm files, decision, impact và điều agent tiếp theo cần biết. Chạy validator; cập nhật inventory hash của đúng file đã review.
