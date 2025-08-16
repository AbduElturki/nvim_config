vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.keymap.set("n", "<TAB>", ":bnext<CR>")
vim.keymap.set("n", "<S-TAB>", ":bprev<CR>")

vim.keymap.set("n", "<leader>oq", function()
  vim.cmd("%bd|e#|bd#")
  vim.cmd("only")
end, { desc = "Close all buffers except current" })

