vim.diagnostic.config({
	virtual_text = false,
	virtual_lines = { current_line = true },
	severity_sort = true,
	underline = true,
	signs = true,
	update_in_insert = false,
	float = { border = "rounded", source = true },
})
