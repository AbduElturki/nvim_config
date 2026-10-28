-- Fallback when the project has no EditorConfig indentation settings.
vim.bo.tabstop = 4
vim.bo.shiftwidth = 4
vim.bo.softtabstop = 4
vim.bo.expandtab = true

vim.b.undo_ftplugin = (vim.b.undo_ftplugin and (vim.b.undo_ftplugin .. " | ") or "")
	.. "setlocal tabstop< shiftwidth< softtabstop< expandtab<"
