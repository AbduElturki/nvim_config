-- Server definitions are data; Neovim owns startup, completion and hints.
vim.lsp.config("lua_ls", {
	settings = {
		Lua = {
			diagnostics = { globals = { "vim" } },
			workspace = { library = { vim.env.VIMRUNTIME }, checkThirdParty = false },
			telemetry = { enable = false },
		},
	},
})
vim.lsp.config("clangd", {
	cmd = function(dispatchers, config)
		local cmd = { "clangd", "--background-index", "--clang-tidy", "--offset-encoding=utf-16", "-j=4" }
		local dir = require("core.project").compilation_database(config.root_dir)
		if dir then
			table.insert(cmd, "--compile-commands-dir=" .. dir)
		end
		return vim.lsp.rpc.start(cmd, dispatchers, { cwd = config.root_dir })
	end,
})
vim.lsp.enable({ "clangd", "pyright", "rust_analyzer", "lua_ls" })

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("NativeLsp", { clear = true }),
	callback = function(event)
		local client = vim.lsp.get_client_by_id(event.data.client_id)
		if not client then
			return
		end
		if client:supports_method("textDocument/completion") then
			vim.lsp.completion.enable(true, client.id, event.buf, { autotrigger = true })
		end
		if client:supports_method("textDocument/inlayHint") then
			vim.lsp.inlay_hint.enable(true, { bufnr = event.buf })
		end
		local function map(key, action, desc)
			vim.keymap.set("n", key, action, { buffer = event.buf, desc = desc })
		end
		map("gd", vim.lsp.buf.definition, "Go to definition")
		map("<leader>ch", function()
			vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }), { bufnr = event.buf })
		end, "Toggle inlay hints")
	end,
})
