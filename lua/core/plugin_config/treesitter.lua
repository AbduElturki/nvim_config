-- The plugin installs parsers; highlighting itself is built into Neovim.
require("nvim-treesitter").setup({})
vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("NativeTreesitter", { clear = true }),
	callback = function(event)
		local stat = vim.uv.fs_stat(vim.api.nvim_buf_get_name(event.buf))
		if stat and stat.size > 100 * 1024 then
			return
		end
		-- Files without an installed parser retain standard syntax highlighting.
		pcall(vim.treesitter.start, event.buf)
	end,
})
