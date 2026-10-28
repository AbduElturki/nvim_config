vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.keymap.set("n", "<TAB>", ":bnext<CR>")
vim.keymap.set("n", "<S-TAB>", ":bprev<CR>")

vim.keymap.set("n", "<leader>q", function()
	require("core.buffers").close()
end, { desc = "Close file buffer" })
vim.keymap.set("n", "<leader>oq", function()
	require("core.buffers").close_others()
end, { desc = "Close other saved file buffers" })

-- Netrw ships with Neovim; no external file-manager executable is needed.
vim.g.netrw_banner = 0
vim.g.netrw_liststyle = 3
vim.keymap.set("n", "<C-n>", "<Cmd>Lexplore<CR>", { desc = "Toggle file explorer" })
vim.keymap.set("n", "<leader>-", "<Cmd>Explore %:p:h<CR>", { desc = "Explore current file directory" })
