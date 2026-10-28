local function check()
	local dir = vim.fn.tempname()
	vim.fn.mkdir(dir, "p")
	local cases = {
		{ "CMakeLists.txt", "cmake", { "cmake_minimum_required(VERSION 3.20)", "project(example)" } },
		{ "tool.cmake", "cmake", { 'set(VALUE "hello")' } },
		{ "script.sh", "sh", { "#!/bin/sh", 'echo "hello"' } },
		{ "script.bash", "sh", { "#!/usr/bin/env bash", "declare -a values=(one two)", 'echo "${values[0]}"' } },
		{ "script.zsh", "zsh", { "#!/bin/zsh", "typeset -a values=(one two)", 'print "${values[1]}"' } },
		{ "no_extension", "sh", { "#!/usr/bin/env bash", 'echo "hello"' } },
	}
	for _, case in ipairs(cases) do
		local path = dir .. "/" .. case[1]
		vim.fn.writefile(case[3], path)
		vim.cmd.edit(path)
		local buf = vim.api.nvim_get_current_buf()
		assert(vim.bo.filetype == case[2], "Filetype: " .. case[1])
		assert(vim.treesitter.highlighter.active[buf], "No highlighter: " .. case[1])
		vim.treesitter.get_parser(buf):parse()
		local captures = 0
		for row, line in ipairs(case[3]) do
			for col = 0, #line - 1 do
				captures = captures + #vim.treesitter.get_captures_at_pos(buf, row - 1, col)
			end
		end
		assert(captures > 0, "No highlight captures: " .. case[1])
		print("PASS: " .. case[1] .. " detected and highlighted")
	end
	-- Simulate a leftover parser with no queries and verify Vim syntax survives.
	vim.cmd.enew()
	local buf = vim.api.nvim_get_current_buf()
	local get = vim.treesitter.query.get
	vim.treesitter.query.get = function()
		return nil
	end
	vim.bo[buf].filetype = "sh"
	vim.treesitter.query.get = get
	assert(not vim.treesitter.highlighter.active[buf], "Started Tree-sitter without queries")
	assert(vim.bo[buf].syntax == "sh", "Fallback syntax disabled")
	print("PASS: missing-query fallback retains shell syntax")
	vim.cmd("bufdo bwipeout!")
	vim.fn.delete(dir, "rf")
end
local ok, err = xpcall(check, debug.traceback)
if not ok then
	print(err)
	vim.cmd("cquit!")
else
	vim.cmd("qa!")
end
