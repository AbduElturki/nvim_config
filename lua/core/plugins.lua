-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	if vim.v.shell_error ~= 0 then
		vim.api.nvim_echo({
			{ "Failed to clone lazy.nvim:\n", "ErrorMsg" },
			{ out, "WarningMsg" },
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
	{ "catppuccin/nvim", name = "catppuccin" },

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

	{ "stevearc/dressing.nvim", opts = {} },

	{ "lukas-reineke/indent-blankline.nvim", main = "ibl", opts = {} },

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

	{ "akinsho/bufferline.nvim", version = "*", dependencies = "nvim-tree/nvim-web-devicons" },
	"fgheng/winbar.nvim",

	{
		"nvim-treesitter/nvim-treesitter",
		run = ":TSUpdate",
		build = ":TSUpdate",
	},

	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.4",
		dependencies = { "nvim-lua/plenary.nvim" },
	},

	{ "nvim-tree/nvim-tree.lua", dependencies = { "nvim-tree/nvim-web-devicons" } },

	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			{ "saadparwaiz1/cmp_luasnip", lazy = true },
			{ "hrsh7th/cmp-buffer", lazy = true },
			{ "FelipeLema/cmp-async-path", lazy = true },
			{ "hrsh7th/cmp-cmdline", lazy = true },
			{ "dmitmel/cmp-cmdline-history", lazy = true },
			{ "hrsh7th/cmp-nvim-lsp-signature-help", lazy = true },
			{ "hrsh7th/cmp-nvim-lua", lazy = true },
			{ "hrsh7th/cmp-calc", lazy = true },
			{ "ray-x/cmp-treesitter", lazy = true },
		},
	},

	{
		"williamboman/mason.nvim",
		opts = {
			PATH = "append",
		},
	},

	{
		"VonHeikemen/lsp-zero.nvim",
		branch = "v2.x",
		dependencies = {
			-- LSP Support
			{ "neovim/nvim-lspconfig" },
			{ "williamboman/mason.nvim" },
			{ "williamboman/mason-lspconfig.nvim" },

			-- Autocompletion
			{ "hrsh7th/nvim-cmp" },
			{ "hrsh7th/cmp-nvim-lsp" },
			{ "L3MON4D3/LuaSnip" },
		},
	},

	{
		"ray-x/lsp_signature.nvim",
		event = "VeryLazy",
		opts = {},
		config = function(_, opts)
			require("lsp_signature").setup(opts)
		end,
	},

	{
		"rachartier/tiny-inline-diagnostic.nvim",
		event = "VeryLazy", -- Or `LspAttach`
		priority = 1000, -- needs to be loaded in first
		config = function()
			require("tiny-inline-diagnostic").setup()
		end,
	},

	{ "j-hui/fidget.nvim", opts = {} },

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
}

require("lazy").setup(plugins, {})
