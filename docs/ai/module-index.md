# Module index

[Knowledge base](README.md). Các module dưới đây là ranh giới phân tích dựa call flow đã đọc, không phải packages độc lập. Mỗi file nguồn được gắn module trong [inventory](source-inventory.json).

| Module | Trách nhiệm / nơi bắt đầu | Tài liệu |
| --- | --- | --- |
| Project/runtime | `project.godot`, `export_presets.cfg`, entry scenes; engine/input/UID | [Project](modules/project-runtime.md) |
| 3D run | `scripts/rebirth/Stillwater.gd`, `RunDirector.gd`; `scenes/rebirth/Stillwater.tscn`; seals/boss/upgrades/checkpoint/camera | [Run](modules/stillwater-run.md) |
| 3D actor/combat | `scripts/rebirth/Duelist.gd`, `CombatPuppet.gd`; control/AI/state/collision/animation | [Duelist](modules/duelist-combat.md) |
| 3D presentation/effects | `scenes/rebirth/StillwaterMap.tscn`, `CourtyardBackdrop.tscn`, còn lại `scripts/rebirth/`, shaders; Form/UI/courtyard/projectiles/feedback | [Presentation](modules/stillwater-presentation.md) |
| 2D world/navigation | `scripts/world/World.gd`, `ChestEncounter.gd`, `BreakableCrate.gd`; World scene | [World](modules/legacy-world.md) |
| 2D actors/health/boss | `scripts/player/`, `scripts/enemies/`, `scripts/boss/`, `scripts/components/`; actor scenes | [Actors](modules/legacy-actors.md) |
| 2D skills | `scripts/skills/`, `resources/skills/`, `scenes/skills/`; Resource->effect contract | [Skills](modules/legacy-skills.md) |
| 2D UI/progression/effects | `scripts/ui/`, `scripts/interface/` trừ Soundscape, `scripts/polish/`, `scripts/effects/`, `ui/Hud.tscn` | [Interface](modules/legacy-interface.md) |
| 2D environment | Các script world còn lại và placeholder/ambience scenes, `resources/shaders/` | [Environment](modules/legacy-environment.md) |
| Shared audio/shutdown | `scripts/interface/Soundscape.gd`, audio caller ở Stillwater/GameFeel | [Audio](modules/shared-audio.md) |
| Asset pipeline | Python chroma/extract/prepare/compose/synthesize tools, assets metadata | [Assets](modules/asset-pipeline.md) |
| Build/capture/QA tools | `scripts/tools/` GD SceneTree tools, package_release.py/run_tests.py | [Tooling](modules/tooling-release.md) |
| Regression suite | `tests/`: 36 GD + 3 Python; mapping theo behavior | [Testing](modules/testing.md) |

Tra task nhanh: damage 3D => Duelist.hurt + Stillwater.incoming_damage/melee; checkpoint => Stillwater.capture_checkpoint/restore_checkpoint + RunDirector.snapshot; spell 2D => SkillDefinition/SkillCaster/effect; corpse => BasicEnemy + World nav + Transform; equipment => Hud + PlayerController + WeaponRig; animation => CombatPuppet (3D) hoặc atlas slicing PlayerController/BasicEnemy (2D); release => package_release + presets + notices.
