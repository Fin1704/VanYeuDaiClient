# AGENTS

## Project Knowledge and Code Changes

- This is a Godot GDScript project with two separate runtimes: default 3D Stillwater (`scenes/rebirth/Stillwater.tscn`) and retained 2D Qinglan (`scenes/interface/TitleScreen.tscn` / `scenes/main/Main.tscn`). Do not apply one runtime's combat or pause rules to the other.
- Start each task with [docs/ai/README.md](docs/ai/README.md), select the relevant [module](docs/ai/module-index.md), and read that module note. Open the current source at the named symbols before editing; code overrides stale documentation.
- Check [dependencies](docs/ai/dependencies.md) and affected callers. Preserve scene node paths, groups, resource UIDs, exported properties, signals, and initialization order unless the task intentionally changes their contracts.
- Set actor/world/role references before `add_child()` when `_ready()` uses them. Keep 3D mode/cinematic combat gates and 2D pause/inventory ownership intact.
- Read [known issues](docs/ai/known-issues.md) before choosing an engine/build command: project features are 4.7, while the release packager pins 4.6.2. Verify the binary actually used; do not silently rewrite configuration to match older docs.
- Make changes within the requested scope. Preserve existing user edits, original assets, and historical documentation. Do not refactor gameplay during analysis/documentation tasks. Never record secrets or credentials.
- Run checks appropriate to the change using [testing.md](docs/ai/modules/testing.md). Documentation-only changes require source/path/link validation, not a full game run. Do not report historical test passes as current validation.
- If architecture, APIs, dependencies, data flow, module responsibility, or an important invariant changes, update only affected knowledge-base pages and reviewed entries in `docs/ai/source-inventory.json`. Do not document proposals as implemented features.
- For major changes, record changed files, design decisions with evidence, subsystem impact, and handoff notes in `docs/ai/decisions.md`; update `docs/ai/analysis-coverage.md` with verification and remaining unknowns.
- Keep the knowledge base concise and progressive: path + symbol + contract, not copied source. Mark unverified claims `UNVERIFIED`. Before stopping incomplete analysis, save the next batch/file/range in coverage.
- Validate documentation with `python docs/ai/validate_knowledge.py`. Refresh hashes only after reviewing the changed source; do not update them just to silence a stale-source warning.

## Asset Workflow

- When the user provides a full sprite sheet or a single generated image, prefer keeping the source image and writing derived files as siblings instead of overwriting the original.
- For AI-generated sprite sheets on flat green backgrounds, use `scripts/tools/chroma_key_cutout.py` to remove the background and validate transparency before importing into Godot.
- For white-background contact sheets like `players_gemini.png`, use `scripts/tools/extract_gemini_run_sheet.py` to detect each sprite, remove the white background, and repack frames onto an aligned transparent sheet before wiring it into animation code.
- Keep both files when helpful:
  - `*_green.png` for the raw keyed source
  - `*.png` for the transparent output
- If the asset will be mirrored in-game, only generate the left-facing directions unless the user explicitly asks for right-facing art too.

## Chroma-Key Commands

- Cut out the background:
  - `python3 scripts/tools/chroma_key_cutout.py cutout --input assets/xianxia/players_gemini_5dir_run_green.png --output assets/xianxia/players_gemini_5dir_run.png --despill`
- Validate transparency:
  - `python3 scripts/tools/chroma_key_cutout.py validate-alpha --input assets/xianxia/players_gemini_5dir_run.png --require-transparent-corners`

## White-Background Sheet Extraction

- Rebuild an aligned transparent sheet directly from the original contact sheet:
  - `python3 scripts/tools/extract_gemini_run_sheet.py --input assets/xianxia/players_gemini.png --output assets/xianxia/players_gemini_aligned_5dir_run.png`
- Prefer this route over AI-regenerating a new sheet when the original already contains the desired motion, because it preserves the leg and body motion from the source art.

## Verification Expectation

- After any cutout pass, validate that:
  - all four corners are transparent
  - the image is not almost fully opaque
  - the image is not fully transparent
- If green fringe remains, rerun with `--despill` and inspect the result before claiming it is ready.
