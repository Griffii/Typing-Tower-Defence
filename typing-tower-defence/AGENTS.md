# Working on Leximancer

This is an existing Godot 4.7 project. Preserve the project's structure and conventions.

- Prefer direct workspace edits for GDScript and other text files. Use the Godot MCP server named `godot` to inspect live editor state, edit scenes through the editor, inspect diagnostics, and playtest when appropriate.
- For MCP workflows, read `addons/godot_mcp_toolkit/CompanionSkills/godot-mcp-toolkit/SKILL.md` and consult its referenced material as needed. Discover the tool groups required for the task instead of assuming every tool is initially exposed.
- Before changing a scene, inspect its current state and account for unsaved editor changes. Save scenes changed through MCP before switching scenes or starting a playtest. Avoid concurrent filesystem and editor writes to the same scene.
- Validate relevant script changes with available Godot diagnostics. For gameplay changes, run a focused playtest when the editor is available and report what was verified. If MCP is unavailable, state that limitation and continue useful file work.
- Keep `.uid` files with their associated assets. Keep generated `.godot/` data and local credentials out of Git.
- Review diffs and preserve existing user changes. Commit or push only when requested.

Local setup and reconnection instructions: `docs/development-setup.md`.
