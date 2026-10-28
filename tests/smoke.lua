-- Run: nvim --headless -i NONE --cmd 'let g:auto_session_enabled = v:false' \
--   '+lua vim.defer_fn(function() dofile(vim.fn.stdpath("config") .. "/tests/smoke.lua") end, 500)'
-- Uses temporary fixtures and fake task processes; does not build a real project.
local function check()
	local plugins = require("lazy.core.config").plugins
	for _, name in ipairs({
		"nvim-dap-view",
		"nvim-dap",
		"nvim-dap-python",
		"render-markdown.nvim",
		"conform.nvim",
		"fzf-lua",
		"diffview.nvim",
	}) do
		assert(not plugins[name]._.loaded, name .. " loaded during startup")
	end
	assert(vim.o.undofile and vim.fn.isdirectory(vim.fn.stdpath("state") .. "/undo") == 1)
	assert(vim.fn.maparg("gr", "n") == "")
	assert(vim.fn.maparg("grr", "n") ~= "")
	local dir = vim.fn.tempname()
	vim.fn.mkdir(dir .. "/.git", "p")
	dir = vim.uv.fs_realpath(dir)
	vim.fn.writefile({ "root = true", "[*]", "indent_style = space", "indent_size = 3" }, dir .. "/.editorconfig")
	vim.fn.writefile({ "value = 1" }, dir .. "/test.py")
	vim.cmd.edit(dir .. "/test.py")
	assert(vim.bo.shiftwidth == 3 and vim.bo.tabstop == 3, "EditorConfig must override fallback")
	vim.fn.delete(dir .. "/.editorconfig")
	vim.cmd.edit(dir .. "/fallback.py")
	assert(vim.bo.shiftwidth == 4, "Python fallback must use four spaces")
	vim.cmd("AutosaveToggle")
	vim.api.nvim_buf_set_lines(0, 0, -1, false, { "paused = True" })
	vim.api.nvim_exec_autocmds("TextChanged", { buffer = 0 })
	vim.wait(850)
	assert(vim.fn.filereadable(dir .. "/fallback.py") == 0, "Paused autosave wrote a file")
	vim.cmd("AutosaveDelay 50")
	vim.cmd("AutosaveToggle")
	vim.api.nvim_exec_autocmds("TextChanged", { buffer = 0 })
	assert(vim.wait(2000, function()
		return vim.fn.filereadable(dir .. "/fallback.py") == 1
	end))
	print("PASS: lazy startup, native LSP maps, EditorConfig and autosave controls")

	local file = vim.api.nvim_get_current_buf()
	vim.cmd.vsplit()
	local windows = vim.api.nvim_list_wins()
	local terminal = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_call(terminal, function()
		vim.fn.jobstart({ "/bin/sh" }, { term = true })
	end)
	local job = vim.b[terminal].terminal_job_id
	require("core.buffers").close()
	assert(not vim.api.nvim_buf_is_loaded(file))
	assert(#vim.api.nvim_list_wins() == #windows, "Window layout changed")
	assert(vim.fn.jobwait({ job }, 0)[1] == -1, "Terminal was killed")
	vim.cmd.enew()
	local dirty = vim.api.nvim_get_current_buf()
	vim.b.autosave_enabled = false
	vim.api.nvim_buf_set_lines(0, 0, -1, false, { "unsaved" })
	require("core.buffers").close()
	assert(vim.api.nvim_get_current_buf() == dirty and vim.bo.modified)
	local keep = vim.api.nvim_create_buf(true, false)
	vim.api.nvim_set_current_buf(keep)
	require("core.buffers").close_others()
	assert(vim.api.nvim_buf_is_loaded(dirty) and vim.bo[dirty].modified)
	assert(vim.fn.jobwait({ job }, 0)[1] == -1)
	vim.fn.jobstop(job)
	print("PASS: buffer closing preserves windows, unsaved buffers and terminal jobs")

	vim.fn.writefile({ "int main() { return 0; }" }, dir .. "/main.cpp")
	vim.cmd.edit(dir .. "/main.cpp")
	vim.fn.mkdir(dir .. "/build", "p")
	vim.fn.writefile({}, dir .. "/build/CMakeCache.txt")
	vim.fn.writefile({}, dir .. "/build/CTestTestfile.cmake")
	vim.fn.writefile({ "[]" }, dir .. "/build/compile_commands.json")
	local project = require("core.project")
	assert(
		project.root() == dir,
		"root=" .. project.root() .. " expected=" .. dir .. " buffer=" .. vim.api.nvim_buf_get_name(0)
	)
	assert(project.compilation_database(dir) == dir .. "/build")
	local command = project.command("build", { "mcn25" }, dir)
	assert(vim.deep_equal(command, { "cmake", "--build", dir .. "/build", "--parallel", "4", "--target", "mcn25" }))
	assert(project.command("test", {}, dir)[1] == "ctest")
	assert(project.command("python", {}, dir)[1] == "uv")
	local real_system = vim.system
	local finished
	vim.system = function(cmd, opts, callback)
		assert(opts.cwd == dir and cmd[1] == "cmake")
		finished = callback
		return { kill = function() end }
	end
	project.run("build", {})
	vim.system = real_system
	assert(finished)
	finished({ code = 1, stdout = "../main.cpp:7:2: error: fixture failure\n", stderr = "" })
	assert(vim.wait(2000, function()
		return vim.fn.getqflist({ context = 0 }).context.code == 1
	end))
	local items = vim.fn.getqflist()
	local found = false
	for _, item in ipairs(items) do
		if item.valid == 1 and item.lnum == 7 then
			assert(
				vim.fs.normalize(vim.api.nvim_buf_get_name(item.bufnr)) == dir .. "/main.cpp",
				vim.api.nvim_buf_get_name(item.bufnr)
			)
			found = true
		end
	end
	assert(found, "Compiler diagnostic not parsed into quickfix")
	vim.cmd.cclose()
	print("PASS: build selection, compile database discovery and async quickfix parsing")

	vim.cmd("ConformInfo")
	assert(plugins["conform.nvim"]._.loaded)
	assert(require("conform").formatters_by_ft.cpp[1] == "clang-format")
	vim.cmd.edit(dir .. "/test.md")
	assert(plugins["render-markdown.nvim"]._.loaded)
	require("lazy").load({ plugins = { "nvim-dap-view" } })
	assert(plugins["nvim-dap"]._.loaded and plugins["nvim-dap-python"]._.loaded)
	assert(vim.fn.maparg("<leader>bb", "n", false, true).callback)
	print("PASS: optional plugin configuration runs when loaded")
	vim.fn.delete(dir, "rf")
end
local ok, err = xpcall(check, debug.traceback)
if not ok then
	print(err)
	vim.cmd("cquit!")
else
	vim.cmd("qa!")
end
