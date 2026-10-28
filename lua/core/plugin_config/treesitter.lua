-- The plugin installs parsers; highlighting itself is built into Neovim.
require("nvim-treesitter").setup({})
vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("NativeTreesitter", { clear = true }),
	callback = function(event)
		local stat = vim.uv.fs_stat(vim.api.nvim_buf_get_name(event.buf))
		if stat and stat.size > 100 * 1024 then
			return
		end
		-- A parser alone is not enough: without highlight queries, starting
		-- Tree-sitter disables Vim syntax but leaves the buffer without colors.
		local lang = vim.treesitter.language.get_lang(vim.bo[event.buf].filetype)
		if not lang then
			return
		end
		local ok, highlights = pcall(vim.treesitter.query.get, lang, "highlights")
		if ok and highlights then
			pcall(vim.treesitter.start, event.buf, lang)
		end
	end,
})
