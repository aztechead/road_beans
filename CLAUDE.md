# CLAUDE.md

## XcodeBuildMCP — the only way to build, run, and test

This project uses [XcodeBuildMCP](https://github.com/getsentry/XcodeBuildMCP) for all Xcode operations. Prefer its tools over raw `xcodebuild`, `xcrun`, or `simctl` shell commands.

### Per-session workflow

1. **Invoke the `xcodebuildmcp` skill first.** Before calling any `mcp__XcodeBuildMCP__*` tool, invoke the `xcodebuildmcp` skill via the Skill tool. This is also enforced by `AGENTS.md`.
2. **Run `session_show_defaults` once** before your first build/run/test call. It reports the project path, scheme, configuration, simulator, and device. If those look correct, do not call `discover_projs`.
3. **Use combined build-and-run tools.** Prefer `build_run_device` (physical iPhone) or `build_run_sim` (simulator) over separate `build_*` → `install_*` → `launch_*` chains.
4. **Use the dedicated log tools.** `start_device_log_cap` / `start_sim_log_cap` and their `stop_*` counterparts — don't shell out to `log stream`.
5. **Never write `xcodebuild` / `xcrun` / `simctl` Bash commands.** If a capability seems missing from XcodeBuildMCP, check the workflow config below before falling back to the shell.

### Workflow configuration

`.xcodebuildmcp/config.yaml` declares which workflows are enabled, which in turn determines tool availability. Current set: `project-discovery`, `simulator`, `device`, `logging`, `ui-automation`.

Schema notes (easy to get wrong):

- The field is `enabledWorkflows` — **not** `workflows.enabled`.
- Workflow names are bare: `simulator`, `device`. **Not** `simulator-project`, `device-project`.

If a tool you expect to call is unavailable, verify the workflow is in this file before assuming the server is broken. Editing the config requires the user to reload/restart the MCP server in their client.

### SourceKit noise to ignore

After Swift edits, the indexer frequently surfaces transient diagnostics like "Cannot find type X in scope" or "No such module 'UIKit'" for symbols that resolve fine at build time. Always verify with an actual `build_run_*` call before chasing these with code changes — they almost always clear once indexing catches up.

### Reporting results

When a build/run/test action completes, return the active context that was used (project, scheme, simulator/device platform). On failure, name the exact failing step and the next concrete tool call to try.
