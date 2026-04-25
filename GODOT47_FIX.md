# Godot 4.7 Compatibility Fix

**Status:** Import fixed for VRM 0.0 and 1.0. Export remains broken due to upstream Godot 4.7 bug.

## What Godot 4.7 Broke

Godot 4.7 PR #94062 changed how `GLTFDocumentExtension` instances are handled during import/export. Extensions are now duplicated via `.duplicate()`, which strips GDScript scripts from the duplicated instances. This means all `_import_post`, `_export_preflight`, `_export_post`, etc. callbacks run on scriptless C++ base classes instead of our GDScript overrides.

**Affected:** All VRM import and export functionality.

## What's Fixed

### ✅ VRM Import (Both 0.0 and 1.0)

**Files changed:**
- `addons/vrm/import_vrm.gd` - Creates instances of ALL VRM extensions and manually calls `_import_post` after `generate_scene()`, bypassing Godot's broken duplicated instances
- `addons/vrm/vrm_options_post_import_plugin.gd` - `_post_process` detects VRM scenes by skeleton structure and restores stripped scripts/metadata as a safety net
- `addons/vrm/vrm_runtime_detector.gd` - New autoload that detects VRM scenes at runtime/editor and reattaches stripped scripts
- `addons/vrm/plugin.gd` - Registers `VRMRuntimeDetector` autoload
- `addons/vrm/vrm_extension.gd` - Metadata fallbacks for vrm_meta, spring_bones, collider data
- `addons/vrm/1.0/VRMC_vrm.gd` - Metadata fallbacks
- `addons/vrm/1.0/VRMC_springBone.gd` - Metadata fallbacks

**Tested models:**
- AliciaSolid VRM 0.0 (18 spring bones) - ✅ Fully working
- VRoid Studio VRM 1.0 (24 spring bones) - ✅ Fully working

**Verified working:**
- VRMTopLevel script restoration
- vrm_secondary script restoration  
- Spring bones (0.0 and 1.0)
- Colliders and collider groups
- vrm_meta metadata
- First-person mesh hiding
- MToon materials
- Humanoid bone retargeting

### ⚠️ VRM Export - BROKEN

Export uses the same `append_from_scene` path which duplicates extensions. The export pipeline has multiple interdependent callbacks (`_export_preflight`, `_export_post_convert`, `_export_preserialize`, `_export_node`, `_export_post`) that all need to run, making the fix more complex than import.

**Impact:** Exporting VRM models produces broken `.vrm` files missing metadata, spring bones, constraints, and material properties.

### ⚠️ VRM 1.0 Node Constraints - PARTIALLY BROKEN

`VRMC_node_constraint._parse_node_extensions` runs on the duplicated instance and fails to store constraint data. The model still imports but without node constraints.

### ❌ VRM Animation - NOT IMPLEMENTED

`VRMC_vrm_animation.gd` is currently a stub (`extends GLTFDocumentExtension \n pass`). Not related to Godot 4.7 - this feature was never implemented.

## How to Use This Fork

1. Download/clone this fork into your Godot 4.7 project's `addons/vrm` folder
2. Enable the VRM addon in Project Settings > Plugins
3. Import VRM files normally - they will work automatically

## Upstream Issue

This is a Godot engine bug, not a VRM addon bug. The fix here is a workaround until Godot fixes the extension duplication behavior.

**Related:** [godotengine/godot PR #94062](https://github.com/godotengine/godot/pull/94062)
