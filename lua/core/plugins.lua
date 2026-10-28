-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
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

local plugins = {
	{
		"folke/tokyonight.nvim",
		lazy = false,
		priority = 1000,
		opts = {},
	},

	{
		"rmagatti/auto-session",
		lazy = false,
		opts = {
			suppressed_dirs = { "~/", "~/Projects", "~/Downloads", "/" },
		},
	},

	{
		"folke/snacks.nvim",
		priority = 1000,
		lazy = false,
		---@type snacks.Config
		opts = {
			animate = { enabled = true },
			bigfile = { enabled = true },
			dashboard = { enabled = true },
			explorer = { enabled = true },
			indent = { enabled = true },
			input = { enabled = true },
			picker = {
				enabled = true,
				ui_select = false,
				sources = {
					explorer = {
						auto_close = true,
						config = function(opts)
							return require("core.explorer").config(opts)
						end,
						actions = {
							explorer_up = function(picker, item)
								require("core.explorer").parent(picker, item)
							end,
							explorer_git_root = function(picker)
								require("core.explorer").select_root(picker)
							end,
							explorer_focus = function(picker, item)
								-- Keep the tree anchored when selecting a directory with '.'.
								if item and item.dir then
									require("snacks.explorer.actions").update(picker, { target = item.file })
								end
							end,
						},
						jump = { close = true },
						layout = {
							preset = "default",
							preview = true,
							layout = {
								box = "horizontal",
								width = 0.9,
								height = 0.85,
								min_width = 60,
								backdrop = false,
								border = "rounded",
								title = " {title} ",
								title_pos = "center",
								footer = " - up | gr root | Enter open | v/s split | ? keys | Esc close ",
								footer_pos = "center",
								{
									box = "vertical",
									{ win = "input", height = 1, border = "bottom" },
									{ win = "list", border = "none" },
								},
								{ win = "preview", title = "{preview}", border = "left", width = 0.55 },
							},
						},
						win = {
							list = {
								keys = {
									["<C-n>"] = "close",
									["<Esc>"] = "close",
									["q"] = "close",
									["<C-c>"] = "close",
									["-"] = { "explorer_up", desc = "Select parent folder in project tree" },
									["<BS>"] = { "explorer_up", desc = "Select parent folder in project tree" },
									["gr"] = { "explorer_git_root", desc = "Select project root" },
									["v"] = { "edit_vsplit", desc = "Open to the right" },
									["s"] = { "edit_split", desc = "Open below" },
									["<C-v>"] = { "edit_vsplit", desc = "Open to the right" },
									["<C-s>"] = { "edit_split", desc = "Open below" },
									["?"] = { "toggle_help_list", desc = "Show explorer keymaps" },
								},
							},
							input = {
								keys = {
									["<C-n>"] = { "close", mode = { "n", "i" } },
									["<Esc>"] = { "close", mode = { "n", "i" } },
									["<C-v>"] = { "edit_vsplit", mode = { "n", "i" }, desc = "Open to the right" },
									["<C-s>"] = { "edit_split", mode = { "n", "i" }, desc = "Open below" },
								},
							},
							preview = { keys = { ["<C-n>"] = "close", ["<Esc>"] = "close", ["q"] = "close" } },
						},
					},
				},
			},
			notifier = { enabled = true },
			quickfile = { enabled = true },
			scope = { enabled = true },
			scroll = { enabled = true },
			statuscolumn = { enabled = false },
			words = { enabled = true },
		},
	},

	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		opts = {
			-- your configuration comes here
			-- or leave it empty to use the default settings
			-- refer to the configuration section below
		},
		keys = {
			{
				"<leader>?",
				function()
					require("which-key").show({ global = false })
				end,
				desc = "Buffer Local Keymaps (which-key)",
			},
		},
	},

	"nvim-tree/nvim-web-devicons",

	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			require("core.plugin_config.git")
		end,
	},

	{
		"kdheepak/lazygit.nvim",
		lazy = true,
		cmd = {
			"LazyGit",
			"LazyGitConfig",
			"LazyGitCurrentFile",
			"LazyGitFilter",
			"LazyGitFilterCurrentFile",
		},
		-- optional for floating window border decoration
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		-- setting the keybinding for LazyGit with 'keys' is recommended in
		-- order to load the plugin when the command is run for the first time
		keys = {
			{ "<leader>gg", "<cmd>LazyGit<cr>", desc = "LazyGit" },
		},
	},

	{
		"igorlfs/nvim-dap-view",
		cmd = { "DapContinue", "DapToggleBreakpoint", "DapViewOpen", "DapViewToggle" },
		keys = { "<leader>bb", "<leader>bc", "<leader>bs", "<leader>bi", "<leader>bo", "<leader>bl", "<leader>bv" },
		config = function(_, opts)
			require("dap-view").setup(opts)
			require("core.plugin_config.dap")
		end,
		dependencies = {
			{ "mfussenegger/nvim-dap", lazy = true },
			{ "mfussenegger/nvim-dap-python", lazy = true },
		},
		---@module 'dap-view'
		---@type dapview.Config
		opts = {},
	},

	{ "akinsho/git-conflict.nvim", version = "*", event = { "BufReadPre", "BufNewFile" }, config = true },

	{ "sindrets/diffview.nvim", cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose" } },

	{
		"MeanderingProgrammer/render-markdown.nvim",
		ft = { "markdown" },
		cmd = "RenderMarkdown",
		dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
		opts = {},
	},

	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
	},

	{ "akinsho/bufferline.nvim", version = "*", dependencies = "nvim-tree/nvim-web-devicons" },
	"fgheng/winbar.nvim",

	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		branch = "main",
		lazy = false,
	},

	{
		"ibhagwan/fzf-lua",
		cmd = "FzfLua",
		keys = { "<leader>ff", "<leader>fg", "<leader>fb", "<leader><leader>", "<leader>gs", "<leader>gc" },
		config = function(_, opts)
			require("fzf-lua").setup(opts)
			require("core.plugin_config.fzf")
		end,
		dependencies = { "nvim-tree/nvim-web-devicons" },
		opts = {},
	},

	{
		"mason-org/mason.nvim",
		opts = {
			PATH = "prepend",
		},
	},

	{
		"stevearc/conform.nvim",
		cmd = "ConformInfo",
		keys = { { "<leader>cf", mode = { "n", "v" }, desc = "Format buffer or selection" } },
		config = function()
			require("core.plugin_config.conform")
		end,
	},
	"neovim/nvim-lspconfig",
}

require("lazy").setup(plugins, { rocks = { enabled = false } })
