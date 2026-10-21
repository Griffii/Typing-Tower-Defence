# VS Code, Codex, and Godot

Open the folder containing `project.godot` in VS Code. Install the recommended
`geequlim.godot-tools` and `openai.chatgpt` extensions.

## Codex MCP

The local `.codex/config.toml` configures the Godot MCP Toolkit npm bridge.
Keep the Godot editor open on this project with Godot MCP Toolkit enabled.
Trust the project in Codex if prompted, then restart the Codex extension after
changing its configuration. The first bridge launch downloads its npm package
and requires network access. Node.js 22 or newer is required.

The toolkit-generated `.mcp.json` is for other MCP clients; Codex uses TOML.
No fixed editor WebSocket port or copied authentication token is necessary:
the bridge discovers the editor using its working directory.

On a new checkout, create `.codex/config.toml` with the following and replace
`C:/path/to/project` with that checkout's absolute path:

```toml
[mcp_servers.godot]
command = "cmd.exe"
args = ["/d", "/c", "npx", "-y", "@npgamedev/godot-mcp-server"]
cwd = "C:/path/to/project"
startup_timeout_sec = 60
tool_timeout_sec = 60

[mcp_servers.godot.env]
GODOT_MCP_CONFIG_VERSION = "1"
```

Check registration using `codex mcp list` from this folder. To verify live access,
ask Codex: "Use Godot MCP to inspect the open project and current scene without
making changes." The Godot MCP dock should show a connected peer.

## VS Code editing and debugging

`.vscode/settings.json` points to the local Godot 4.7.2 installation and connects
to the editor's GDScript language server at `127.0.0.1:6005`. Update the executable
path for another machine. Keep Godot open for editor-backed completion.

Use Run and Debug (F5) with **Godot: Run project** or **Godot: Run current scene**.
The current-scene configuration requires an active scene or associated script.

In Godot, configure Editor > Editor Settings > Text Editor > External:

- Use External Editor: enabled.
- Exec Path: `C:/Users/Ty/AppData/Local/Programs/Microsoft VS Code/bin/code.cmd`.
- Exec Flags: `{project} --goto {file}:{line}:{col}`.

Enable Auto Reload Scripts on External Change in Text Editor > Behavior.
These are Godot's personal editor settings, separate from this repository.

## GitHub

Use VS Code Source Control to review diffs, commit, and push. Commit scripts,
scenes, source assets, their `.uid` files, the add-on, and shared development
configuration. The local MCP configuration, toolkit-generated `.mcp.json`,
and generated logs are ignored. Never add authentication tokens to the repository.

References:

- https://learn.chatgpt.com/docs/extend/mcp?surface=cli
- https://github.com/godotengine/godot-vscode-plugin
- https://docs.godotengine.org/en/stable/tutorials/editor/external_editor.html
- ../addons/godot_mcp_toolkit/README.md
