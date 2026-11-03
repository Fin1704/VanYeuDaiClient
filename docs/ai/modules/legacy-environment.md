# 2D: props, pixel surfaces và ambience

[Module index](../module-index.md) · [world](legacy-world.md) · [assets](asset-pipeline.md).

`scripts/world/PlaceholderObstacle.gd` là @tool StaticBody2D. Scene node Visual/CollisionShape2D bắt buộc, Backdrop/CanopyVisual tùy chọn. `_ready()` nạp texture override/default hoặc procedural fallback; collision_size fallback size, boundaries rectangle, props capsule và collision_offset. Visual tree/house có thể split full-size transparent image tại passable_upper_ratio (overlap 1px), bottom anchor và z-index `global_y+500` với offsets riêng house. `_process()` cập nhật layering. Đổi texture/scale cần kiểm tra collider, nav footprint và spawn visual bounds cùng lúc.

`PixelSurface.gd` @tool TextureRect: `_ready` và NOTIFICATION_EDITOR_PRE_SAVE tạo pixel tile procedural, nearest filter và tile stretch. `create_grass_tuft(size, seed)` static phục vụ Grassland. Các pixel detail tọa độ cố định có thể vượt ảnh nếu tile_size tùy ý quá nhỏ; runtime với setting hiện tại chưa tái hiện lỗi.

`Grassland.gd` @tool Node2D: `_generate()` dựng back/front Sprite2D cho mỗi tuft, exclusions từ surface/props/world bounds; back có grass_glow shader, front chỉ 5px thấp y-sort để che chân. `_ready()` chỉ gọi generation **trong editor**; World.tscn hiện không instance Grassland/PixelSurface, Ground dùng terrain texture trực tiếp. Hai script này còn được test/có thể dùng để authoring, không phải hệ grass runtime của World hiện tại. Không set owner cho generated children trong hàm; không tự khẳng định chúng được lưu vào scene.

`NightAmbienceController.gd` + scene: Environment glow, CanvasModulate, fireflies/sparkles, moon patches, ScreenFx vignette. `_ready()` cấu hình GPU particles và chín PointLight2D grid. `_process()` cho particles theo camera; `apply_world_bounds()` rebuild particles/patches; `toggle()` chỉ đổi visible. Particle fireflies bật; sparkle emitting=false. Hidden Node2D vẫn có `_process` và ScreenFx là CanvasLayer riêng: propagation/hiển thị cần render test khi thay toggle.

`AmbientMagicController.gd` là scaffold hiện tại: configure bounds, tắt BackgroundDotsA/B/C và dọn HeroLayer/SparkleLayer. Constants cho HeroFirefly và texture không đồng nghĩa scene/behavior đó có; không tạo hero fireflies trong các rebuild methods. `test_world_firefly_ambience.gd` là bằng chứng kỳ vọng cần đối chiếu với code hiện tại.

Shader `resources/shaders/`: grass_wind vertex sway; grass_glow cùng sway + tip color; glow_outline neighbor-alpha outline. Resource inventory ghi nơi được reference; existence một shader không chứng minh nó được active runtime. Trước sửa chạy các test pixel_art_scene_visuals, world_random_breakables, world_firefly_ambience, fire_lion_light và inspect render ngày/đêm.
