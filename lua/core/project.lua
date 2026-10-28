local M = {}
local build_dirs = {}
local running

function M.root()
	return vim.fs.root(0, { ".git" })
		or vim.fs.root(0, { "CMakeLists.txt", "pyproject.toml", "Cargo.toml", "Makefile" })
		or vim.fn.getcwd()
end

function M.build_dir(root)
	root = root or M.root()
	if build_dirs[root] then
		return build_dirs[root]
	end
	local candidates = { root .. "/build", root .. "/build/macos" }
	if vim.uv.os_uname().sysname == "Darwin" then
		candidates = { root .. "/build/macos", root .. "/build" }
	end
	for _, dir in ipairs(candidates) do
		if vim.uv.fs_stat(dir .. "/CMakeCache.txt") then
			return dir
		end
	end
	return root .. "/build"
end

function M.compilation_database(root)
	root = root or M.root()
	local candidates = { M.build_dir(root), root }
	for _, dir in ipairs(candidates) do
		if vim.uv.fs_stat(dir .. "/compile_commands.json") then
			return dir
		end
	end
end

function M.set_build_dir(path)
	local root = M.root()
	path = vim.fn.expand(path)
	if not vim.startswith(path, "/") then
		path = root .. "/" .. path
	end
	build_dirs[root] = vim.fs.normalize(path)
	vim.notify("Build directory: " .. build_dirs[root] .. ". Restart clangd to use a different database.")
end

function M.command(kind, args, root)
	root = root or M.root()
	args = args or {}
	if kind == "build" then
		local dir = M.build_dir(root)
		if not vim.uv.fs_stat(dir .. "/CMakeCache.txt") then
			return nil, "No configured CMake build. Configure the project first, or use :BuildDir {path}."
		end
		local cmd = { "cmake", "--build", dir, "--parallel", "4" }
		if #args > 0 then
			vim.list_extend(cmd, { "--target" })
			vim.list_extend(cmd, args)
		end
		return cmd, dir
	elseif kind == "test" then
		local dir = M.build_dir(root)
		if not vim.uv.fs_stat(dir .. "/CTestTestfile.cmake") then
			return nil, "No CTest tests in the selected build. Use :TestPython for Python tools."
		end
		local cmd = { "ctest", "--test-dir", dir, "--output-on-failure", "--no-tests=error" }
		vim.list_extend(cmd, args)
		return cmd, dir
	elseif kind == "python" then
		local cmd = { "uv", "run", "pytest", "--tb=short" }
		vim.list_extend(cmd, args)
		return cmd, root
	end
	return nil, "Unknown task: " .. tostring(kind)
end

function M.run(kind, args)
	local host = vim.uv.os_gethostname()
	if host:match("^login") and host:match("%.arm%.com$") then
		vim.notify("Run builds/tests from a cluster node, not an ARM login node.", vim.log.levels.ERROR)
		return
	end
	if running then
		vim.notify("A task is already running. Use :TaskStop first.")
		return
	end
	local root = M.root()
	local cmd, directory = M.command(kind, args, root)
	if not cmd then
		vim.notify(directory, vim.log.levels.WARN)
		return
	end
	if vim.fn.executable(cmd[1]) == 0 then
		vim.notify("Executable not found: " .. cmd[1], vim.log.levels.ERROR)
		return
	end
	-- Do not silently save unfinished edits merely because a task was invoked.
	local efm = vim.o.errorformat
	local title = table.concat(cmd, " ")
	vim.fn.setqflist({}, " ", { title = title .. " (running)", items = {}, context = { root = root } })
	local id = vim.fn.getqflist({ id = 0 }).id
	local ok, process = pcall(vim.system, cmd, { cwd = root, text = true }, function(result)
		vim.schedule(function()
			running = nil
			local output = (result.stdout or "") .. "\n" .. (result.stderr or "")
			output = output:gsub("\27%[[0-9;]*[A-Za-z]", "")
			-- Directory markers make relative compiler paths independent of editor cwd.
			local lines = { "NVIM_TASK_DIRECTORY " .. directory }
			vim.list_extend(lines, vim.split(output, "\n", { trimempty = true }))
			table.insert(lines, "NVIM_TASK_END")
			vim.fn.setqflist({}, "r", {
				id = id,
				title = title .. " (exit " .. result.code .. ")",
				lines = lines,
				efm = "%DNVIM_TASK_DIRECTORY %f,%XNVIM_TASK_END," .. efm,
				context = { root = root, code = result.code, command = cmd },
			})
			vim.notify(
				kind .. " finished (exit " .. result.code .. ")",
				result.code == 0 and vim.log.levels.INFO or vim.log.levels.WARN
			)
			-- Never steal focus from an assistant terminal when a background task ends.
			if result.code ~= 0 and vim.bo.buftype ~= "terminal" and vim.fn.getqflist({ id = 0 }).id == id then
				vim.cmd.copen()
			end
		end)
	end)
	if ok then
		running = process
		vim.notify("Started " .. title .. "; results will be in quickfix")
	else
		vim.notify(tostring(process), vim.log.levels.ERROR)
	end
end

function M.setup()
	vim.api.nvim_create_user_command("Build", function(opts)
		M.run("build", opts.fargs)
	end, { nargs = "*" })
	vim.api.nvim_create_user_command("Test", function(opts)
		M.run("test", opts.fargs)
	end, { nargs = "*" })
	vim.api.nvim_create_user_command("TestPython", function(opts)
		M.run("python", opts.fargs)
	end, { nargs = "*" })
	vim.api.nvim_create_user_command("BuildDir", function(opts)
		if opts.args == "" then
			vim.notify(M.build_dir())
		else
			M.set_build_dir(opts.args)
		end
	end, { nargs = "?", complete = "dir" })
	vim.api.nvim_create_user_command("TaskStop", function()
		if running then
			running:kill(15)
		end
	end, {})
	vim.keymap.set("n", "<leader>mb", "<Cmd>Build<CR>", { desc = "Build project" })
	vim.keymap.set("n", "<leader>mt", "<Cmd>Test<CR>", { desc = "Run CTest" })
	vim.keymap.set("n", "<leader>mp", "<Cmd>TestPython<CR>", { desc = "Run Python tests" })
	vim.keymap.set("n", "<leader>mq", "<Cmd>copen<CR>", { desc = "Open task results" })
end
return M
