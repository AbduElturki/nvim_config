require("mason").setup()
require("inlay-hint").setup()

vim.lsp.config.clangd = {
	capabilities = capabilities,
	cmd = {
		"clangd",
		"--background-index",
		"--clang-tidy",
		"--offset-encoding=utf-16",
		"-j=8",
		"--malloc-trim",
		"--pch-storage=memory",
	},
	filetypes = { "c", "cpp" },
}
vim.lsp.enable("clangd")

vim.lsp.config.pyright = {
	capabilities = capabilities,
	cmd = { "pyright-langserver", "--stdio" },
	filetypes = { "python" },
}
vim.lsp.enable("pyright")

vim.lsp.config.rust_analyzer = {
	capabilities = capabilities,
	cmd = { "rust-analyzer" },
	filetypes = { "rust" },
}
vim.lsp.enable("rust_analyzer")

vim.lsp.config.emmylua_ls = {
	capabilities = capabilities,
	filetypes = { "lua" },
	settings = {
		Lua = {
			diagnostics = {
				globals = { "vim" },
			},
			workspace = {
				library = vim.api.nvim_get_runtime_file("", true),
			},
			telemetry = {
				enable = false,
			},
		},
	},
}
vim.lsp.enable("emmylua_ls")

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.workspace.didChangeWatchedFiles.dynamicRegistration = false
capabilities.textDocument.completion.completionItem.snippetSupport = true
capabilities.textDocument.completion.completionItem.preselectSupport = true
capabilities.textDocument.completion.completionItem.insertReplaceSupport = true

vim.keymap.set("n", "<leader>cf", function()
	vim.lsp.buf.format()
end, { desc = "LSP: Format buffer" })

vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, {})
vim.keymap.set(
	"n",
	"gd",
	":lua require'fzf-lua'.lsp_definitions({ winopts = {relative='cursor',row=1.01, col=0, height=0.5, width=0.5} })<cr>",
	{ desc = "Get definition" }
)
vim.keymap.set("n", "ca", vim.lsp.buf.code_action, { desc = "Code action" })
vim.keymap.set("n", "gi", vim.lsp.buf.implementation, { desc = "Get implementation" })
vim.keymap.set("n", "gr", ":lua require'fzf-lua'.lsp_references", { desc = "Get references" })
vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
