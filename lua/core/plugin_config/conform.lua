require("conform").setup({
	-- Keep format-on-save disabled. Built-in formatter definitions discover
	-- .clang-format, pyproject.toml and other project configuration from the file.
	formatters_by_ft = {
		c = { "clang-format" },
		cpp = { "clang-format" },
		lua = { "stylua" },
		python = { "isort", "black" },
		rust = { "rustfmt", lsp_format = "fallback" },
		javascript = { "prettierd", "prettier", stop_after_first = true },
	},
})

vim.keymap.set({ "n", "v" }, "<leader>cf", function()
	require("conform").format({ lsp_format = "fallback", async = true })
end, { desc = "Format buffer or selection" })
