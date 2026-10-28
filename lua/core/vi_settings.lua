vim.opt.nu = true
vim.opt.relativenumber = true

vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.shiftround = true
vim.opt.expandtab = true

vim.opt.smartindent = true

vim.opt.wrap = false

vim.opt.swapfile = false

vim.opt.incsearch = true

vim.opt.termguicolors = true

vim.opt.scrolloff = 8

vim.opt.colorcolumn = "80"

vim.opt.clipboard = "unnamedplus"

vim.loader.enable()

-- Keep undo history across restarts in Neovim's private state directory.
local undo_dir = vim.fn.stdpath("state") .. "/undo"
vim.fn.mkdir(undo_dir, "p", 448)
vim.opt.undodir = undo_dir .. "//"
vim.opt.undofile = true
-- Native EditorConfig overrides the global/filetype fallback options.
vim.g.editorconfig = true

-- File picker splits open in predictable directions; mouse clicks can focus
-- the editor behind a floating explorer, which closes on loss of focus.
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.mouse = "a"
