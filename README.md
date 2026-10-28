# Neovim configuration

Requires Neovim 0.12+. Plugins are managed by Lazy; `lazy-lock.json` records the tested versions. Use `:Lazy restore` to restore them, or `:Lazy update` to update.

## Native features

Neovim handles LSP startup, completion, LSP snippets, inlay hints, diagnostics, Tree-sitter highlighting, context menus, file browsing, and terminals. Small autocmds provide autosave and reload files changed externally. Plugins remain for features such as fuzzy search, Git integration, debugger UI, themes, parser installation and formatter orchestration.

Format-on-save is disabled. Autosave remains enabled for modified, writable, named file buffers, with a 750 ms debounce. `Space u a` / `:AutosaveToggle` pauses it for the current buffer; `:AutosaveDelay 1000` changes that buffer’s delay. Pausing cancels pending saves.

Persistent undo is stored under Neovim’s state directory and survives editor restarts. Native EditorConfig applies project indentation settings; Python, Rust, C and C++ fall back to four spaces, with two spaces as the general default. Conform’s formatter definitions discover `.clang-format`, `pyproject.toml` and other project formatter settings. Format-on-save remains off.

## AI assistants

Codex, Claude Code and Gemini CLI run in native floating terminals. Each uses its own CLI authentication, model, permissions and configuration. No API keys or models are configured in Neovim. Assistants start only when you explicitly open them; choosing one does not forward your conversation to another.

| Shortcut | Command | Action |
| --- | --- | --- |
| `Space a a` | `:Assistant` | Choose an assistant |
| `Space a c` | `:Codex` | Toggle Codex |
| `Space a l` | `:Claude` | Toggle Claude Code |
| `Space a g` | `:Gemini` | Toggle Gemini CLI |

Sessions are independent for each assistant and project. They start at the current file's Git root, or Neovim's working directory if no Git root is found.

- `Ctrl-g` inside an assistant: hide its window without stopping the session. Open it again with its shortcut to resume.
- `Ctrl-\`: toggle the general shell, or hide the current managed terminal.
- `Ctrl-x` inside a terminal: enter terminal normal mode to select/copy/scroll. Press `i` to return.
- Escape and `jk` are passed through to the CLI. Exiting Neovim ends its terminal processes; use each CLI's own resume workflow in a later session.

Saved file changes made by assistants are reloaded when you return to the buffer. Unsaved editor changes retain Neovim's conflict handling.

The executables must be on `PATH`. Sign in interactively on first launch as needed:

- [Codex CLI](https://learn.chatgpt.com/docs/codex/cli): `codex`.
- [Claude Code](https://github.com/anthropics/claude-code#installation): install with `brew install --cask claude-code`, then run `claude`.
- [Gemini CLI](https://geminicli.com/docs/get-started/installation/): install with `brew install gemini-cli`, then run `gemini`.

## Editing shortcuts

- `Ctrl-n`: toggle the native file explorer; `Space -`: explore the current file's directory.
- Completion appears automatically. `Ctrl-n` / `Ctrl-p` select candidates; Enter accepts a selected candidate, otherwise inserts a newline. `Ctrl-y` also accepts; `Ctrl-e` dismisses.
- `Ctrl-o` in insert mode: request completion. `Ctrl-x Ctrl-f`: filename completion.
- Tab / Shift-Tab: move between active snippet placeholders.
- `gd`, `gri`, `grr`, `K`: definition, implementation, references and hover.
- Native `grn`, `gra`, `grt`, `gO`: rename, code action, type definition and document symbols.
- `Space ch`: toggle inlay hints.
- `Space q`: close a saved file buffer while preserving the window layout.
- `Space o q`: close other saved file buffers; keep unsaved buffers and terminal jobs.
- `Ctrl-s` in insert mode: native LSP signature help.
- `Space cf`: format buffer/selection using Conform, with LSP fallback.
- `Ctrl-t` or right-click: native context menu.
- Existing FZF, Git, buffer and debugger shortcuts remain configured in `lua/core/plugin_config/`.

## External tools

For macOS, `brew install neovim tree-sitter-cli fzf ripgrep pyright` provides the editor, parser compiler, search tools and Python language server. The optional `:LazyGit` workflow needs `lazygit` on `PATH`.

Use `:Mason` to install `lua-language-server`, `clangd`, `rust-analyzer`, `stylua`, `black`, `isort`, `clang-format`, and `codelldb`. Rust projects also need their usual Rust toolchain. Python debugging uses `uv` and the DAP Python integration.

Install parsers with `:TSInstall c cpp lua vim vimdoc query markdown markdown_inline python rust javascript`. After updating Tree-sitter, run `:TSUpdate`. Missing parsers fall back to standard syntax highlighting.

Run `:checkhealth vim.lsp nvim-treesitter lazy` to inspect the installation. `nvim-lspconfig` supplies server definitions; it does not replace Neovim's native LSP implementation.

## Build and test workflow

| Shortcut | Command | Action |
| --- | --- | --- |
| `Space m b` | `:Build [targets...]` | Build configured CMake project, four parallel jobs |
| `Space m t` | `:Test [ctest options...]` | Run CTest with failure output |
| `Space m p` | `:TestPython [pytest arguments...]` | Run `uv run pytest --tb=short` |
| `Space m q` | `:copen` | Open task results |
| | `:BuildDir [path]` | Show/select build directory for this project and editor session |
| | `:TaskStop` | Request cancellation of the active task |

Tasks run asynchronously with arguments passed directly to the executable. Results go into a separate quickfix list; use native `]q` / `[q` or `:cnext` / `:cprevious` to navigate. Only one task runs at a time. Tasks use saved files and do not force-save paused/unfinished edits. Background failures do not steal focus from a terminal.

The root is the current file’s Git root, with build/project markers as a fallback. Existing `build/macos` is preferred on macOS; otherwise the configured `build` directory is used. `:BuildDir` supports other layouts. clangd uses the selected directory’s `compile_commands.json`, or a database at the LSP root. Restart clangd after changing build directories (`:lsp restart clangd`).

For MCN, configure using the repository’s appropriate preset first (for example `cmake --preset macos` on macOS, or the documented local preset on the cluster). The presets already enable compile-command export. `:Build mcn25` builds a target, `:Test -R pattern` selects CTest tests, and `:TestPython tools/tests` runs the Python tooling tests. The commands inherit Neovim’s environment: source the repository’s environment scripts before starting Neovim when required. They refuse heavy jobs on ARM login nodes; start Neovim on a cluster node instead. They do not launch MCN simulation sweeps automatically.

## Startup and verification

Debugger plugins load on debugger keys/commands, Markdown rendering on Markdown files, FZF on search keys, Conform on formatting, and Diffview on its commands. Gitsigns and conflict helpers load when a file is read/created. Use `:Lazy profile` to inspect timings on your machine; use `:Lazy restore` for the recorded plugin versions.

Run the smoke checks from a fresh process:

```sh
nvim --headless -i NONE --cmd 'let g:auto_session_enabled = v:false' \
  '+lua vim.defer_fn(function() dofile(vim.fn.stdpath("config") .. "/tests/smoke.lua") end, 500)'
```

The tests use temporary files and a simulated build process to check autosave, indentation, buffer/terminal preservation, quickfix paths, native mappings and lazy loading. They do not run a real project build or contact an AI assistant.

`tests/build_integration.lua` can be run with the same command. It additionally requires CMake, a C++ compiler and clangd, and checks a real build, CTest, a deliberate compiler failure and compile-database discovery in a temporary fixture.
