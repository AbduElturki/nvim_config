-- Use Neovim's built-in context menu (also available with right-click).
vim.opt.mousemodel = "popup_setpos"
vim.keymap.set("n", "<C-t>", "<Cmd>popup PopUp<CR>", { desc = "Context menu" })
