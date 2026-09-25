# loadout-socket-dev

The `socket-dev` loadout: a [Minimal](https://minimal.dev) setup for working on
[SocketDev/socket-cli](https://github.com/SocketDev/socket-cli) and
[SocketDev/socket-mcp](https://github.com/SocketDev/socket-mcp). It has two
parts:

- **A `minimal.toml` for each repo** (`socket-cli.minimal.toml`,
  `socket-mcp.minimal.toml`). It gives the session its toolchain and defines
  `min task run` tasks for install, build, test, lint, typecheck and the
  repo-specific commands.
- **This loadout** (`loadout.toml` plus helpers). When you attach, it opens a
  two-pane zellij layout. The left pane is a shell that prints the repo's
  command list. The right pane runs Claude Code.

One loadout serves both repos. The welcome message picks the repo from
`SOCKET_REPO`, which each repo's `minimal.toml` sets. When that is unset, it
falls back to the `package.json` name.

## Install

Requires a Minimal client that reads the `<name>/loadout.toml` loadout layout
(min 0.6 or later).

1. Clone this repo to `~/.config/minimal/loadouts/socket-dev/`. The directory
   name is the loadout's name, and the patch sources in `loadout.toml` point at
   that path.

   ```sh
   git clone https://github.com/mitodrummer/loadout-socket-dev.git \
     ~/.config/minimal/loadouts/socket-dev
   ```

   Run `min loadout list` to check that `socket-dev` shows up.
2. Copy the repo's config into the repo:

   ```sh
   cd ~/src/socket-cli
   mkdir -p .minimal
   cp ~/.config/minimal/loadouts/socket-dev/socket-cli.minimal.toml .minimal/minimal.toml
   ```

   Use `socket-mcp.minimal.toml` for socket-mcp.
3. Optional: allow the project's activation hook, which runs the install for
   you. Minimal runs a project's hooks only after you allow-list the project
   in `~/.config/minimal/user_policy.toml`:

   ```toml
   [hooks]
   allow = ["/Users/you/src/socket-cli", "/Users/you/src/socket-mcp"]
   ```

   Without this, run the install command from the table below by hand.
4. Export credentials on the host. Each one is optional; a missing one is
   dropped with a warning.

   | Variable | Used by |
   | --- | --- |
   | `CLAUDE_CODE_OAUTH_TOKEN` or `ANTHROPIC_API_KEY` | Claude Code. Without either, Claude Code asks you to log in. |
   | `SOCKET_API_TOKEN` | socket-mcp servers, debug clients and `test:e2e` |
   | `SOCKET_CLI_API_TOKEN`, `SOCKET_CLI_ORG_SLUG` | socket-cli API calls |
   | `GH_TOKEN` | `gh` in the session |

5. Activate:

   ```sh
   min session activate --loadout socket-dev
   ```

   `--loadout` replaces your `default_loadouts` for that activation. To keep
   them, list them too. Do not combine this loadout with another one that sets
   `PROMPT_COMMAND` or owns the zellij layout; Minimal fails the activation on
   the conflicting variable.

Re-attaching rejoins the same zellij session. For a fresh layout, run
`zellij delete-session --force socket-dev` before attaching. To print the
command list again, run `bash ~/.local/bin/socket-welcome`.

## Commands

The left column runs in the session shell against the session's
`node_modules`. That is the fast loop. The right column runs a task in a
fresh sandbox, which installs from the lockfile first. Use it for a
from-clean, CI-shaped check. A task never relies on the session's
`node_modules`.

### socket-cli

| In the session shell | Task | What it does |
| --- | --- | --- |
| `pnpm install && pnpm run prepare` | `min task run install` | Install, then hydrate `scripts/fleet/` |
| `pnpm run build` | `min task run build` | Smart build that skips unchanged outputs |
| `pnpm run build:cli` | `min task run build-cli` | Build the CLI package only |
| `pnpm run build:watch` | none | Rebuild the CLI on changes |
| `pnpm run s <args>` | `min task run cli --cmd "<args>"` | Run the built CLI (the task builds first) |
| `pnpm test --all` | `min task run test` | Whole test suite |
| `pnpm test <file>` | `min task run test --target <file>` | One test file |
| `pnpm run test:unit --all` | `min task run test-unit` | Every product unit test |
| `pnpm run type` | `min task run typecheck` | Type-check |
| `pnpm run lint --all` | `min task run lint` | Lint the whole tree |
| `pnpm run check --all` | `min task run check` | Full check suite, the CI gate |
| `pnpm run fix --all` | `min task run fix` | Auto-fix lint and formatting |
| `pnpm run preflight` | `min task run preflight` | Every local gate failure in one pass |

Debug logging: `SOCKET_CLI_DEBUG=1 pnpm run s <command>`.

`prepare` is its own step because socket-cli's `pnpm-workspace.yaml` sets
`ignoreScripts`. It downloads Socket's fleet pack from GHCR into
`scripts/fleet/`, which every build, test and lint script imports. The fetch
is anonymous and follows the pack's `green` channel, re-checked every four
hours, rather than the `bundle.ref` recorded in
`.config/repo/socket-wheelhouse.json`.

### socket-mcp

| In the session shell | Task | What it does |
| --- | --- | --- |
| `pnpm install` | `min task run install` | Install (its `prepare` hydrates the fleet scripts) |
| `pnpm run build` | `min task run build` | Bundle the server to `dist/` |
| `pnpm test --all` | `min task run test` | Whole test suite |
| `pnpm test <file>` | `min task run test --target <file>` | One test file |
| `pnpm run test:e2e` | `min task run test-e2e` | Live-API end-to-end tests. Needs `SOCKET_API_TOKEN`. |
| `pnpm run type` | `min task run typecheck` | Type-check |
| `pnpm run lint --all` | `min task run lint` | Lint the whole tree |
| `pnpm run check --all` | `min task run check` | Full check suite, the CI gate |
| `pnpm run fix --all` | `min task run fix` | Auto-fix lint and formatting |
| `pnpm run server-stdio` | none | Build and serve MCP over stdio |
| `pnpm run server-http` | `min task run server-http` | Build and serve MCP over HTTP on port 3000 |
| `pnpm run debug-sdk` | `min task run debug-sdk` | SDK mock client drives the server over stdio |

Append `:debug` to a server script, such as `server-http:debug`, for
per-request tracing on stderr.

To point Claude Code in the right pane at your local server over stdio:

```sh
pnpm run build
claude mcp add socket-local -e SOCKET_API_TOKEN="$SOCKET_API_TOKEN" -- node "$PWD/dist/index.cjs"
```

Or, with `pnpm run server-http` running in the left pane:

```sh
claude mcp add --transport http socket-local-http http://localhost:3000
```

## Toolchain choices

- **Node.** Both repos pin 26.8.1 in `.node-version`. The Minimal catalog has
  no Node 26 yet, so the configs use `node-lts` (24.x), which satisfies
  `engines.node: ">=24"`. Both repos install on it, and socket-mcp's test
  suite runs on it.
- **pnpm.** The catalog pnpm is 11.21. Both repos require
  `^11.25.0 || >=12.3.4` and fail an older pnpm outright. The configs set
  `PNPM_CONFIG_PM_ON_FAIL=download` in the session and in every task. pnpm
  then fetches the newest release that satisfies `devEngines` from the npm
  registry, checks its integrity, and re-runs under it. Today that is 12.5.1,
  the same version Socket's CI pins. This pnpm comes from the npm registry,
  not from the pinned Minimal catalog. Once the catalog carries pnpm 12.3.4 or
  later, remove the variable.
- **Session packages.** `base`, `node-lts`, `git`, `gh`, `jq`, `less`,
  `ripgrep`, `fd` and `zizmor` in both repos, plus `uv` and `python` in
  socket-cli. Those cover `.config/repo/external-tools.json` except `sfw` and
  `gh-aw`, which aren't in the Minimal catalog; the fleet setup downloads
  them itself. The lint, check and preflight tasks also get `zizmor`.
- **Editor and shell.** The loadout adds `zellij`, `claude-code`, `vim`,
  `fzf` and `bat`, and sets `EDITOR`/`VISUAL` to `vim`. The shell pane loads
  `bashrc` (fzf's Ctrl-R history, Ctrl-T file and Alt-C directory pickers, fed
  by `fd`, with `bat` previews). `vimrc` sets TypeScript-friendly defaults and
  maps Ctrl-P / `<Space>f` to `:FZF`, `<Space>g` to `:Rg`, `<Space>w` to `:Rg`
  on the word under the cursor, and `<Space>b` to `:Buffers`. `fzf.vim` is
  fzf's own Vim plugin, vendored from junegunn/fzf v0.74.2 to match the
  catalog's fzf.

## Things to know

- **`prepare` writes to your home directory.** In both repos, `prepare`
  installs git hooks and edits user-level Claude Code config:
  `~/.claude/settings.json` gets `attribution`, `fastMode` and
  `pluginConfigs`, and `~/.claude.json` gets `copyOnSelect`. Inside a Minimal
  session that is the session's own home, so nothing reaches your host.
  Outside a session it edits your real config.
- **The helper scripts run from `~/.local/bin` through `bash`.** They do not
  rely on an exec bit or on a lifecycle hook, so the layout also works under
  `--no-hooks`.
- **Tasks read credentials from your shell.** `min task run test-e2e`,
  `server-http` and `debug-sdk` fail before starting when `SOCKET_API_TOKEN`
  is not exported in the shell you run them from.

## Known issues

- **socket-cli's `pnpm run build` fails as of 2026-09-24**, with
  `Cannot find module 'scripts/fleet/process/run-main.mts'`. The newest green
  fleet pack moved that file to `process/main/run.mts`, but socket-cli's
  `scripts/repo/*` still import the old path. Because the pack follows the
  green channel, this affects every commit, not only `main`. The fix belongs
  upstream in Socket's repos. Install, the test tasks that don't build first,
  and the rest of this setup still work.
- **Claude Code's model list comes from the repo, not this loadout.** Each
  repo's fleet hooks write `.claude/settings.local.json` with a custom
  `/model` picker that lists GLM and DeepSeek offload models through Socket's
  local `ai-balancer` proxy. Without that proxy, choose an Anthropic model
  with `/model`.
- **Some of `prepare`'s setup steps warn in a session.** The sandbox has no
  system keyring (`secret-tool`), and the `ai-balancer` service does not
  install. Both are non-fatal.

## Files

| File | Purpose |
| --- | --- |
| `loadout.toml` | Packages, patches and vars for the session |
| `socket-dev-session` | Attach-time entry point. Seeds the zellij and Claude Code first-run config, then opens the layout. |
| `layout.kdl` | The two-pane zellij layout |
| `bashrc` | The shell pane's rcfile: fzf key bindings and defaults |
| `vimrc` | Vim defaults and fzf pickers (`:FZF`, `:Rg`, `:Buffers`) |
| `fzf.vim` | fzf's Vim plugin (MIT, junegunn/fzf v0.74.2) |
| `socket-welcome` | Prints the command list for the current repo |
| `socket-claude-launch` | Runs `claude update`, then starts the updated Claude Code |
| `socket-cli.minimal.toml` | `.minimal/minimal.toml` for socket-cli |
| `socket-mcp.minimal.toml` | `.minimal/minimal.toml` for socket-mcp |
