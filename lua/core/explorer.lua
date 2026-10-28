local M = {}

function M.root(path)
	path = path or (vim.bo.buftype == "" and vim.api.nvim_buf_get_name(0) or "")
	if path == "" then
		path = vim.fn.getcwd()
	end
	return vim.fs.root(path, { ".git" })
		or vim.fs.root(path, { "CMakeLists.txt", "pyproject.toml", "Cargo.toml", "Makefile" })
		or (vim.fn.isdirectory(path) == 1 and path or vim.fs.dirname(path))
end

function M.config(opts)
	opts.cwd = M.root(opts.cwd)
	-- The title remains visible even when the root row scrolls out of view.
	opts.title = "Project: " .. vim.fn.fnamemodify(opts.cwd, ":~")
	return require("snacks.picker.source.explorer").setup(opts)
end

function M.toggle()
	local open = Snacks.picker.get({ source = "explorer" })[1]
	if open then
		open:close()
		return
	end
	Snacks.explorer({ cwd = M.root() })
end

function M.parent(picker, item)
	local root = picker:cwd()
	local path = item and item.file or root
	local parent = path == root and root or vim.fs.dirname(path)
	if parent ~= root and not vim.startswith(parent, root .. "/") then
		parent = root
	end
	if item and item.dir and path ~= root then
		require("snacks.explorer.tree"):close(path)
	end
	require("snacks.explorer.actions").update(picker, { target = parent })
end

function M.select_root(picker)
	require("snacks.explorer.actions").update(picker, { target = picker:cwd() })
end
return M
