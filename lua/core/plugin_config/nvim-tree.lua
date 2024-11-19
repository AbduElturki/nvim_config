-- disable netrw at the very start of your init.lua (strongly advised)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

--vim.opt.termguicolors = true

require("nvim-tree").setup({
	open_on_tab = false,
	sort_by = "case_sensitive",
	renderer = {
		group_empty = true,
	},
	filters = {
		dotfiles = true,
	},
	git = {
		enable = true,
		ignore = true,
		timeout = 500,
	},
	tab = {
		sync = {
			open = false,
			close = true,
			ignore = {},
		},
	},
})

vim.keymap.set("n", "<c-n>", ":NvimTreeFindFileToggle<CR>")
