# Appendix A2: Editor Setup for Elixir Development

A well-configured editor dramatically improves your Elixir development experience. This guide covers setup for popular editors with features like syntax highlighting, code completion, formatting, and debugging.

## Table of Contents

1. [VS Code with ElixirLS (Recommended)](#vs-code-with-elixirls-recommended)
2. [Neovim Setup](#neovim-setup)
3. [Emacs](#emacs)
4. [IntelliJ IDEA / JetBrains](#intellij-idea--jetbrains)
5. [Sublime Text](#sublime-text)
6. [Vim](#vim)
7. [Helix](#helix)
8. [Editor-Agnostic Tools](#editor-agnostic-tools)

---

## VS Code with ElixirLS (Recommended)

VS Code with ElixirLS provides the best out-of-box experience for Elixir development.

### Installing VS Code

Download from [code.visualstudio.com](https://code.visualstudio.com/) or:

```bash
# macOS (Homebrew)
brew install --cask visual-studio-code

# Ubuntu/Debian
sudo snap install code --classic

# Arch Linux
sudo pacman -S code
```

### Installing ElixirLS Extension

1. Open VS Code
2. Press `Cmd+Shift+X` (macOS) or `Ctrl+Shift+X` (Windows/Linux)
3. Search for "ElixirLS"
4. Install "ElixirLS: Elixir support and debugger" by ElixirLS

Or via command line:

```bash
code --install-extension JakeBecker.elixir-ls
```

### ElixirLS Features

- **IntelliSense**: Auto-completion for modules, functions, and variables
- **Go to Definition**: `F12` or `Cmd+Click`
- **Find References**: `Shift+F12`
- **Hover Documentation**: Hover over any function for docs
- **Diagnostics**: Real-time error and warning detection
- **Code Formatting**: Automatic formatting on save
- **Debugging**: Breakpoints, step-through debugging

### Recommended VS Code Settings

Open settings (`Cmd+,`) and add to `settings.json`:

```json
{
  // Elixir-specific settings
  "[elixir]": {
    "editor.formatOnSave": true,
    "editor.defaultFormatter": "JakeBecker.elixir-ls"
  },

  // ElixirLS settings
  "elixirLS.suggestSpecs": true,
  "elixirLS.dialyzerEnabled": true,
  "elixirLS.dialyzerFormat": "dialyxir_long",
  "elixirLS.fetchDeps": true,
  "elixirLS.signatureAfterComplete": true,

  // File associations
  "files.associations": {
    "*.heex": "phoenix-heex",
    "*.leex": "phoenix-heex"
  },

  // Recommended general settings
  "editor.tabSize": 2,
  "editor.insertSpaces": true,
  "files.trimTrailingWhitespace": true,
  "files.insertFinalNewline": true
}
```

### Additional VS Code Extensions for Elixir

| Extension | Purpose |
|-----------|---------|
| Phoenix Framework | Syntax highlighting for HEEx templates |
| Surface | Support for Surface LiveView components |
| TODO Highlight | Highlight TODO/FIXME comments |
| GitLens | Enhanced Git integration |
| Error Lens | Inline error display |

### Debugging in VS Code

1. Create `.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "mix_task",
      "name": "mix test",
      "request": "launch",
      "task": "test",
      "taskArgs": ["--trace"],
      "projectDir": "${workspaceRoot}"
    },
    {
      "type": "mix_task",
      "name": "mix run",
      "request": "launch",
      "task": "run",
      "taskArgs": ["--no-halt"],
      "projectDir": "${workspaceRoot}"
    },
    {
      "type": "mix_task",
      "name": "Phoenix Server",
      "request": "launch",
      "task": "phx.server",
      "projectDir": "${workspaceRoot}"
    }
  ]
}
```

2. Set breakpoints by clicking the gutter
3. Press `F5` to start debugging

---

## Neovim Setup

Neovim offers powerful Elixir support through LSP integration and plugins.

### Prerequisites

- Neovim 0.9+ (for native LSP support)
- A plugin manager (lazy.nvim recommended)

### Using lazy.nvim

Create or edit `~/.config/nvim/init.lua`:

```lua
-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Leader key
vim.g.mapleader = " "

-- Plugins
require("lazy").setup({
  -- LSP Configuration
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
    },
    config = function()
      require("mason").setup()
      require("mason-lspconfig").setup({
        ensure_installed = { "elixirls" }
      })

      local lspconfig = require("lspconfig")
      lspconfig.elixirls.setup({
        cmd = { vim.fn.expand("~/.local/share/nvim/mason/bin/elixir-ls") },
        settings = {
          elixirLS = {
            dialyzerEnabled = true,
            fetchDeps = false,
            suggestSpecs = true,
          }
        }
      })
    end,
  },

  -- Autocompletion
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require("cmp")
      cmp.setup({
        snippet = {
          expand = function(args)
            require("luasnip").lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping.select_next_item(),
          ["<S-Tab>"] = cmp.mapping.select_prev_item(),
        }),
        sources = {
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "buffer" },
          { name = "path" },
        },
      })
    end,
  },

  -- Treesitter for syntax highlighting
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "elixir", "heex", "eex", "erlang" },
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },

  -- Elixir-specific tools
  {
    "elixir-tools/elixir-tools.nvim",
    version = "*",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("elixir").setup({
        nextls = { enable = false },
        credo = { enable = true },
        elixirls = { enable = true },
      })
    end,
    dependencies = { "nvim-lua/plenary.nvim" },
  },

  -- File explorer
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("nvim-tree").setup()
    end,
  },

  -- Fuzzy finder
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
  },
})

-- LSP Keybindings
vim.keymap.set("n", "gd", vim.lsp.buf.definition)
vim.keymap.set("n", "gr", vim.lsp.buf.references)
vim.keymap.set("n", "K", vim.lsp.buf.hover)
vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action)
vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename)
vim.keymap.set("n", "<leader>f", vim.lsp.buf.format)

-- General settings
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.termguicolors = true
```

### Key Mappings for Elixir Development

| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `gr` | Find references |
| `K` | Show documentation |
| `<leader>ca` | Code actions |
| `<leader>rn` | Rename symbol |
| `<leader>f` | Format file |

---

## Emacs

### Using Doom Emacs (Recommended)

```bash
# Install Doom Emacs
git clone --depth 1 https://github.com/doomemacs/doomemacs ~/.config/emacs
~/.config/emacs/bin/doom install
```

Enable Elixir in `~/.doom.d/init.el`:

```elisp
(doom! :lang
       (elixir +lsp +tree-sitter))
```

Then run:

```bash
~/.config/emacs/bin/doom sync
```

### Using Vanilla Emacs

Add to `~/.emacs.d/init.el`:

```elisp
;; Package management
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

;; Use-package
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

;; Elixir mode
(use-package elixir-mode
  :ensure t)

;; LSP
(use-package lsp-mode
  :ensure t
  :commands lsp
  :hook (elixir-mode . lsp)
  :init
  (setq lsp-elixir-server-command '("elixir-ls")))

;; Company for completion
(use-package company
  :ensure t
  :hook (elixir-mode . company-mode))

;; Flycheck for diagnostics
(use-package flycheck
  :ensure t
  :hook (elixir-mode . flycheck-mode))

;; Mix integration
(use-package mix
  :ensure t
  :hook (elixir-mode . mix-minor-mode))
```

---

## IntelliJ IDEA / JetBrains

### Installing the Elixir Plugin

1. Open IntelliJ IDEA (Community or Ultimate)
2. Go to `Settings/Preferences > Plugins`
3. Search for "Elixir"
4. Install "Elixir" plugin by JetBrains Marketplace
5. Restart IDE

### Configuration

1. Go to `Settings > Languages & Frameworks > Elixir`
2. Configure SDK path (auto-detected usually)
3. Enable "Format on Save" in `Settings > Tools > Actions on Save`

### Features

- Full syntax highlighting
- Code completion
- Navigation (go to definition, find usages)
- Mix task integration
- Test runner integration
- Refactoring support

---

## Sublime Text

### Installing Elixir Support

1. Install Package Control if not present
2. `Cmd+Shift+P` > "Package Control: Install Package"
3. Install these packages:
   - `Elixir`
   - `LSP`
   - `LSP-elixir`

### Configuration

Create `LSP.sublime-settings`:

```json
{
  "clients": {
    "elixir-ls": {
      "enabled": true,
      "command": ["elixir-ls"],
      "selector": "source.elixir"
    }
  }
}
```

### Key Bindings

Add to key bindings:

```json
[
  { "keys": ["f12"], "command": "lsp_symbol_definition" },
  { "keys": ["shift+f12"], "command": "lsp_symbol_references" }
]
```

---

## Vim

### Using vim-plug

Add to `~/.vimrc`:

```vim
call plug#begin()

" Elixir syntax
Plug 'elixir-editors/vim-elixir'

" ALE for linting
Plug 'dense-analysis/ale'

" CoC for completion (alternative to native LSP)
Plug 'neoclide/coc.nvim', {'branch': 'release'}

call plug#end()

" ALE configuration
let g:ale_linters = {'elixir': ['elixir-ls', 'credo']}
let g:ale_fixers = {'elixir': ['mix_format']}
let g:ale_fix_on_save = 1

" Basic settings
set number
set tabstop=2
set shiftwidth=2
set expandtab
```

Install CoC Elixir:

```vim
:CocInstall coc-elixir
```

---

## Helix

Helix is a modern terminal editor with built-in LSP support.

### Installation

```bash
# macOS
brew install helix

# Arch Linux
sudo pacman -S helix

# From source
git clone https://github.com/helix-editor/helix
cd helix
cargo install --path helix-term
```

### Configuration

Create `~/.config/helix/languages.toml`:

```toml
[[language]]
name = "elixir"
language-servers = ["elixir-ls"]
auto-format = true

[[language]]
name = "heex"
language-servers = ["elixir-ls"]
auto-format = true

[language-server.elixir-ls]
command = "elixir-ls"
config = { elixirLS.dialyzerEnabled = true }
```

### Key Bindings

Default LSP bindings:

| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `gr` | Find references |
| `K` | Show documentation |
| `<space>a` | Code actions |
| `<space>r` | Rename |

---

## Editor-Agnostic Tools

### Installing ElixirLS Manually

If your editor requires manual ElixirLS installation:

```bash
# Clone ElixirLS
git clone https://github.com/elixir-lsp/elixir-ls.git
cd elixir-ls

# Compile
mix deps.get
MIX_ENV=prod mix compile
MIX_ENV=prod mix elixir_ls.release2 -o release

# Add to PATH or configure editor to use release/language_server.sh
```

### Formatter Configuration

Create `.formatter.exs` in your project root:

```elixir
[
  inputs: [
    "{mix,.formatter,.credo}.exs",
    "{config,lib,test}/**/*.{ex,exs}",
    "priv/**/*.{ex,exs}"
  ],
  line_length: 98,
  import_deps: [:ecto, :phoenix],
  plugins: [Phoenix.LiveView.HTMLFormatter],
  heex_line_length: 120
]
```

### Credo Configuration

Create `.credo.exs` for linting:

```elixir
%{
  configs: [
    %{
      name: "default",
      files: %{
        included: ["lib/", "src/", "web/", "apps/*/lib/"],
        excluded: [~r"/_build/", ~r"/deps/"]
      },
      strict: false,
      checks: [
        {Credo.Check.Readability.MaxLineLength, max_length: 120},
        {Credo.Check.Design.TagTODO, exit_status: 0},
        {Credo.Check.Design.TagFIXME, exit_status: 0}
      ]
    }
  ]
}
```

### Dialyzer Configuration

Add to `mix.exs` for static analysis:

```elixir
defp deps do
  [
    {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
  ]
end
```

---

## Troubleshooting

### ElixirLS Not Starting

1. Check Elixir/Erlang versions are compatible
2. Verify ElixirLS is in PATH
3. Check editor's output/log panel
4. Try running `elixir-ls` manually

### Slow Completion/Diagnostics

- Dialyzer analysis can be slow on first run
- Disable Dialyzer temporarily: set `dialyzerEnabled: false`
- Ensure project compiles cleanly: `mix compile`

### Formatting Not Working

1. Ensure `.formatter.exs` exists
2. Check for syntax errors: `mix format --check-formatted`
3. Verify formatter is enabled in editor settings

---

*Last updated: January 2025*
