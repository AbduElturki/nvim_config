local fzf = require("fzf-lua")

vim.keymap.set("n", "<leader>ff", fzf.files, { desc = "FZF: Find files" })
vim.keymap.set("n", "<leader>fg", fzf.live_grep, { desc = "FZF: Live grep" })
vim.keymap.set("n", "<leader>fb", fzf.buffers, { desc = "FZF: List buffers" })
vim.keymap.set("n", "<leader><leader>", fzf.resume, { desc = "FZF: Resume last search" })

vim.keymap.set("n", "<leader>gs", fzf.git_status, { desc = "FZF: Git status" })
vim.keymap.set("n", "<leader>gc", fzf.git_commits, { desc = "FZF: Git commits" })
