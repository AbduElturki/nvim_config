require("mason").setup()

local on_attach = function(_, _)
  vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, {})
  vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, {})

  vim.keymap.set("n", "gd", vim.lsp.buf.definition, {})
  vim.keymap.set("n", "gi", vim.lsp.buf.implementation, {})
  vim.keymap.set("n", "gr", require("telescope.builtin").lsp_references, {})
  vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
end

vim.lsp.config.clangd = {
  capabilities = capabilities,
  on_attach = on_attach,
  cmd = { "clangd", "--background-index", "--clang-tidy", "--offset-encoding=utf-16", "-j=8", "--malloc-trim", "--pch-storage=memory" },
  filetypes = { "c", "cpp" },
}
vim.lsp.enable("clangd")

vim.lsp.config.pyright = {
  capabilities = capabilities,
  on_attach = on_attach,
  cmd = { "pyright-langserver", "--stdio" },
  filetypes = { "python" },
}
vim.lsp.enable("pyright")

vim.lsp.config.rust_analyzer = {
  capabilities = capabilities,
  on_attach = on_attach,
  cmd = { "rust-analyzer" },
  filetypes = { "rust" },
}
vim.lsp.enable("rust_analyzer")

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.workspace.didChangeWatchedFiles.dynamicRegistration = false
capabilities.textDocument.completion.completionItem.snippetSupport = true
capabilities.textDocument.completion.completionItem.preselectSupport = true
capabilities.textDocument.completion.completionItem.insertReplaceSupport = true
