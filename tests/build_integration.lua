-- Run like smoke.lua, substituting tests/build_integration.lua.
-- Requires cmake, a C++ compiler, and clangd; builds only a tiny temporary fixture.
local function check()
	local dir = vim.fn.tempname()
	vim.fn.mkdir(dir .. "/.git", "p")
	dir = vim.uv.fs_realpath(dir)
	vim.fn.writefile({
		"cmake_minimum_required(VERSION 3.20)",
		"project(nvim_check LANGUAGES CXX)",
		"add_executable(check main.cpp)",
		"enable_testing()",
		"add_test(NAME check COMMAND check)",
	}, dir .. "/CMakeLists.txt")
	vim.fn.writefile({ "int main() { return 0; }" }, dir .. "/main.cpp")
	local configured = vim.system(
		{ "cmake", "-S", dir, "-B", dir .. "/build", "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON" },
		{ text = true }
	):wait()
	assert(configured.code == 0, configured.stderr)
	local rpc_start = vim.lsp.rpc.start
	local clangd_cmd
	vim.lsp.rpc.start = function(cmd, ...)
		if cmd[1] == "clangd" then
			clangd_cmd = cmd
		end
		return rpc_start(cmd, ...)
	end
	vim.cmd.edit(dir .. "/main.cpp")
	assert(vim.wait(15000, function()
		return #vim.lsp.get_clients({ bufnr = 0, name = "clangd" }) > 0
	end))
	vim.lsp.rpc.start = rpc_start
	assert(vim.tbl_contains(clangd_cmd, "--compile-commands-dir=" .. dir .. "/build"))
	local project = require("core.project")
	for _, kind in ipairs({ "build", "test" }) do
		project.run(kind, {})
		assert(
			vim.wait(30000, function()
				return vim.fn.getqflist({ context = 0 }).context.code ~= nil
			end, 100),
			"Task timed out"
		)
		assert(vim.fn.getqflist({ context = 0 }).context.code == 0, "Task failed: " .. kind)
	end
	-- Prove real compiler errors become navigable quickfix entries.
	vim.fn.writefile({ "int main() { syntax error }" }, dir .. "/main.cpp")
	project.run("build", {})
	assert(vim.wait(30000, function()
		return vim.fn.getqflist({ context = 0 }).context.code ~= nil
	end, 100))
	assert(vim.fn.getqflist({ context = 0 }).context.code ~= 0)
	local found = false
	for _, item in ipairs(vim.fn.getqflist()) do
		if item.valid == 1 and item.lnum == 1 and vim.api.nvim_buf_get_name(item.bufnr) == dir .. "/main.cpp" then
			found = true
		end
	end
	assert(found, "Real compiler error not found in quickfix")
	for _, client in ipairs(vim.lsp.get_clients({ name = "clangd" })) do
		client:stop(true)
	end
	vim.fn.delete(dir, "rf")
	print("PASS: real CMake build, CTest, compiler errors and clangd compilation database")
end
local ok, err = xpcall(check, debug.traceback)
if not ok then
	print(err)
	vim.cmd("cquit!")
else
	vim.cmd("qa!")
end
