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

-- Floating file tree with a live preview, using the existing Snacks plugin.
vim.keymap.set("n", "<C-n>", function()
	require("core.explorer").toggle()
end, { desc = "Toggle project file explorer" })
vim.keymap.set("n", "<leader>-", function()
	require("core.explorer").toggle()
end, { desc = "Reveal current file in project explorer" })

-- The command-history window is a special buffer: close the window itself,
-- rather than passing it to the file-buffer deletion shortcuts.
vim.api.nvim_create_autocmd("CmdwinEnter", {
	group = vim.api.nvim_create_augroup("CommandHistoryKeys", { clear = true }),
	callback = function(event)
		for _, key in ipairs({ "<Esc>", "q", "<leader>q" }) do
			vim.keymap.set("n", key, "<Cmd>quit<CR>", { buffer = event.buf, desc = "Close command history" })
		end
		vim.keymap.set("i", "<Esc>", "<Esc><Cmd>quit<CR>", { buffer = event.buf, desc = "Close command history" })
	end,
})
