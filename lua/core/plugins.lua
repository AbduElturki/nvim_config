-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out,                            "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local plugins = {
  { "catppuccin/nvim",                     name = "catppuccin" },

  {
    "rmagatti/auto-session",
    lazy = false,

    ---enables autocomplete for opts
    ---@module "auto-session"
    ---@type AutoSession.Config
    opts = {
      suppressed_dirs = { "~/", "~/Projects", "~/Downloads", "/" },
      -- log_level = 'debug',
    },
  },

  "Pocco81/auto-save.nvim",

  "LunarVim/bigfile.nvim",

  "nvim-tree/nvim-web-devicons",

  { "stevearc/dressing.nvim",              opts = {} },

  { "lukas-reineke/indent-blankline.nvim", main = "ibl",       opts = {} },

  "mhinz/vim-sayonara",

  "lewis6991/gitsigns.nvim",

  { "akinsho/git-conflict.nvim", version = "*", config = true },

  "sindrets/diffview.nvim",

  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    opts = {},
  },

  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons", opt = true },
  },

  { "akinsho/bufferline.nvim",   version = "*", dependencies = "nvim-tree/nvim-web-devicons" },
  "fgheng/winbar.nvim",

  {
    "nvim-treesitter/nvim-treesitter",
    run = ":TSUpdate",
    build = ":TSUpdate",
    event = "BufReadPost",
  },

  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.4",
    dependencies = { "nvim-lua/plenary.nvim" },
  },

  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    cmd = { "NvimTreeToggle", "NvimTreeOpen", "NvimTreeClose", "NvimTreeFocus", "NvimTreeFindFile", "NvimTreeFindFileToggle" },
    keys = {
      { "<C-n>", "<cmd>NvimTreeFindFileToggle<CR>", desc = "Toggle NvimTree (find file)" },
    },
    config = function()
      require("core.plugin_config.nvim-tree")
    end,
  },

  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      { "saadparwaiz1/cmp_luasnip",            lazy = true },
      { "hrsh7th/cmp-buffer",                  lazy = true },
      { "FelipeLema/cmp-async-path",           lazy = true },
      { "hrsh7th/cmp-cmdline",                 lazy = true },
      { "dmitmel/cmp-cmdline-history",         lazy = true },
      { "hrsh7th/cmp-nvim-lsp-signature-help", lazy = true },
      { "hrsh7th/cmp-nvim-lua",                lazy = true },
      { "hrsh7th/cmp-calc",                    lazy = true },
      { "ray-x/cmp-treesitter",                lazy = true },
    },
  },

  {
    "williamboman/mason.nvim",
    opts = {
      PATH = "append",
    },
  },

  {
    "rachartier/tiny-inline-diagnostic.nvim",
    event = "VeryLazy", -- Or `LspAttach`
    priority = 1000,    -- needs to be loaded in first
    config = function()
      require("tiny-inline-diagnostic").setup()
    end,
  },

  { "j-hui/fidget.nvim",       opts = {} },

  "rafamadriz/friendly-snippets",

  { "stevearc/conform.nvim", opts = {} },

  {
    "zbirenbaum/copilot-cmp",
    dependencies = {
      { "github/copilot.vim" },
      { "nvim-lua/plenary.nvim", branch = "master" },
      config = function()
        require("copilot_cmp").setup()
      end,
    },
  },

  {
    "CopilotC-Nvim/CopilotChat.nvim",
    dependencies = {
      { "github/copilot.vim" },
      { "nvim-lua/plenary.nvim", branch = "master" },
    },
    build = "make tiktoken",
    opts = {},
  },

  {
    "yetone/avante.nvim",
    build = vim.fn.has("win32") ~= 0
        and "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false"
        or "make",
    event = "VeryLazy",
    version = false, -- Never set this value to "*"! Never!
    opts = {
      provider = "openai",
      providers = {
        openai = {
          endpoint = os.getenv("OPENAI_API_BASE") or "https://api.openai.com/v1",
          model = "gpt-5-2025-08-07",
          extra_request_body = {
            temperature = 1.0,
          },
        },
      },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "echasnovski/mini.pick",         
      "nvim-telescope/telescope.nvim", 
      "hrsh7th/nvim-cmp",              
      "ibhagwan/fzf-lua",              
      "stevearc/dressing.nvim",        
      "folke/snacks.nvim",             
      "nvim-tree/nvim-web-devicons",   
      "zbirenbaum/copilot.lua",        
      {
        -- support for image pasting
        "HakonHarnes/img-clip.nvim",
        event = "VeryLazy",
        opts = {
          -- recommended settings
          default = {
            embed_image_as_base64 = false,
            prompt_for_file_name = false,
            drag_and_drop = {
              insert_mode = true,
            },
            -- required for Windows users
            use_absolute_path = true,
          },
        },
      },
      {
        -- Make sure to set this up properly if you have lazy=true
        'MeanderingProgrammer/render-markdown.nvim',
        opts = {
          file_types = { "markdown", "Avante" },
        },
        ft = { "markdown", "Avante" },
      },
    },
  }
}

require("lazy").setup(plugins, {})
