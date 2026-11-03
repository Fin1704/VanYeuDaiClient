# Audio autoload và shutdown

[Module index](../module-index.md).

`project.godot` có đúng một autoload được khai báo: `Soundscape="*res://scripts/interface/Soundscape.gd"`. Script extends Node, PROCESS_MODE_ALWAYS, dùng chung hai nhánh; không giữ gameplay state.

`_ready()` bỏ qua khi headless; bản có cửa sổ tắt auto_accept_quit, đọc `user://settings.cfg` audio.sound để mute master bus. Không tạo continuous music player; var music và `_stop_music()` còn là hook. 3D sau đó đọc `stillwater.cfg` và có thể ghi đè master mute. 2D PauseMenu đọc lại settings.cfg. Đây là ba caller dùng cùng global AudioServer state.

`_notification(NOTIFICATION_WM_CLOSE_REQUEST)` và 3D UI quit gọi `shutdown()`: guard stopping, gọi scene.prepare_shutdown nếu có, pause tree, `_stop_audio_tree()` recursively stop/clear stream cho cả ba loại AudioStreamPlayer, await frame + timer 0.08s rồi quit. Stillwater.prepare_shutdown đặt mode closing để dừng logic root always-processing. Giữ process_mode/timer always khi sửa đường thoát.

Combat Foley 3D do Stillwater giữ tám voices + sound_bank WAV dưới `assets/audio/combat/`, throttle 40ms mỗi sound, skip headless; sound pitch dùng RNG world. 2D GameFeel.impact tổng hợp AudioStreamWAV khi sound_cooldown đã hết, rồi đặt cooldown 0.08s. Không có package audio middleware hay network service được dùng trong source đã đọc.
