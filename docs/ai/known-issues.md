# Known issues, debt và điều chưa xác minh

[Index](README.md) · [testing](modules/testing.md). Phân loại **VERIFIED_STATIC** = có bằng chứng code/config; **RISK / UNVERIFIED_RUNTIME** = tác động chưa tái hiện/profile. Nhiệm vụ này không sửa các vấn đề dưới đây.

## Mismatch và behavior đã xác minh tĩnh

| ID / mức ưu tiên | Bằng chứng và ảnh hưởng | Kiểm tiếp khi task liên quan |
| --- | --- | --- |
| K01 / cao — engine version drift | project.godot features 4.7, local --version 4.7.2; package_release.main chỉ chấp nhận 4.6.2.stable và manifest hard-code cùng version; README/DEVELOPMENT vẫn 4.6.2 | Full release command với binary 4.7.2 sẽ bị guard từ chối; quyết định target engine/templates/import compatibility trước đổi pipeline |
| K02 / vừa — export metadata drift | project.version 0.4.1, macOS/iOS presets app.version 0.4.0; hai iOS preset thiếu export_path/bundle id | Không coi iOS ready hoặc package version đúng trước kiểm output |
| K03 / vừa — 2D World message hookup bị lỡ lúc ready | Hud._ready tìm group world để nối combat_message_requested; World.tscn root không khai báo group, World._ready mới add_to_group sau Hud child ready; không thấy reconnect sau đó | Trace cho thấy standard World boot bỏ connection này; chest/slam/world messages có thể không lên HUD. Reproduce bằng instantiate World rồi report_combat_message |
| K04 / vừa — tài liệu headless palette cũ | DEVELOPMENT/STILLWATER nói headless skip palette; CombatPuppet._ready gọi retone vô điều kiện, retone có get_active_material | Chạy headless binary thực tế để biết renderer có lỗi; **không khẳng định hiện tại compile/render fail** chỉ từ mismatch |
| K05 / thấp — AmbientMagic scaffold | _configure_background_layers tắt emitting, rebuild chỉ queue_free; HeroFirefly và bảy texture literal paths không tồn tại | Không ghi hero-firefly implementation đã xong; source không load các constants này trên path đang chạy, nên chưa phải missing-resource crash |
| K06 / vừa — hạn chế tests | Grassland headless exclusion loops có thể rỗng; zombie_targeting chỉ assert group; chest test gọi spawn helper trực tiếp | Xem testing.md; assertions pass không đủ chứng minh behavior theo tên |
| K07 / vừa — packager provenance label | package_release copy working tree, --revision chỉ kiểm format SHA, không assert HEAD/clean state | Caller có thể gán SHA không khớp staged files; manifest hashes vẫn chỉ staged snapshot. Build từ clean committed checkout theo DEVELOPMENT |
| K08 / thấp — item/targeting placeholder | Hud chỉ sync weapon, armor không stats, talisman/pill không use; SkillDefinition targeting_mode không được SkillCaster dispatch | Đây là giới hạn tính năng hiện tại, không tự gọi là regression. Player unequip weapon chỉ ẩn visual; `_try_melee_attack` không kiểm equipped ID nên vẫn đánh được |
| K09 / thấp — docs/count/link lịch sử | DEVELOPMENT ghi 32/32, README/STILLWATER ghi 36/36 lịch sử; issue config/placeholder trỏ preview 0.3.0 trong khi README 0.4.1 | Dùng số file inventory và kết quả chạy mới; không sửa archive hàng loạt |

## Rủi ro thiết kế/hiệu năng cần đo hoặc tái hiện

- **R01 / performance**: BasicEnemy._ready tạo ImageTexture light 256² bằng pixel loops cho mọi enemy, dù chỉ fire lion dùng; per-instance atlas/frame dictionaries; find_nearest_target/separation/AStar mỗi physics frame. Chi phí tăng theo số actor, nhưng chưa có profile hiện tại.
- **R02 / performance**: Stillwater.burst/Form tạo nhiều node/material/tween; world.enemies giữ freed references đến root teardown (loops kiểm is_instance_valid); AI separation quét array. Chapter nhỏ giới hạn living enemies, chưa bằng chứng bottleneck hoặc leak vô hạn.
- **R03 / placement**: Stillwater.spawn_guard có fallback không validate sau 18 attempt thất bại; 2D World._get_spawn_position chỉ chọn mép, không overlap query. Kiểm map đông/props mới trước tăng mật độ.
- **R04 / transforms/navigation**: World obstacle sizing bỏ collision_offset/rotation/scale ở một số path; blockers/grid pha local/global và bounds quanh origin. Hiện scene World origin/scale identity; cần reproduce trước kết luận path lỗi trong layout hiện tại.
- **R05 / pause/effect lifecycle**: 3D burst/ritual_pulse dùng tween, CourtyardAtmosphere/SealBloom/shader TIME vẫn animate khi combat mode pause; CombatFeedback clock khác. 2D protective orb orbit dùng Time.get_ticks_msec nên pha nhảy khi resume. Visual pause consistency là task riêng, chưa xác nhận defect gameplay.
- **R06 / stale callbacks**: queue_free/deferred retry, lambdas modal, scene transitions và sibling trail/effect ownership cần giữ validity/closing guards. Không có worker thread/concurrency primitive trong gameplay đã đọc; rủi ro là callbacks cùng main-loop/lifecycle, không tự suy data race đa luồng.
- **R07 / errors**: ConfigFile.save return thường bị bỏ; thiếu required imported bones/nodes/clip có thể gây lỗi vì không null guard tổng quát. Binary --version không chứng minh import tree đúng. Kiểm rig/import/headless/native riêng khi đổi asset/engine.
- **R08 / skill transaction**: TransformSkillEffect.activate trả true khi có eligible corpse ngay cả nếu tất cả `_create_zombie_from_corpse` fail; SkillCaster effect thiếu activate vẫn pay; zero-cost skill bypass can_spend_stamina. Default resources hiện có đủ effect/cost nên cần case tái hiện trước sửa.
- **R09 / UI/capture**: Fixed 1280×720 và minimap scale 1440×960; capture_showcase/capture_polish dùng old land textures khác World. Không coi screenshot các script đó đại diện chính xác terrain hiện tại.

## Chưa kiểm runtime trong đợt này

Full Godot tests, native rendering, GPU performance, controller thật, export templates, packed artifacts, signatures/notarization và external release links **UNVERIFIED**. Python checks bị thiếu Pillow/pytest nên chưa chạy assertions. Không có blocker đọc source/config của các module đã khảo sát.
