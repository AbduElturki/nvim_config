-- Run: nvim --clean --headless -l ~/.config/nvim/tests/explorer.lua
-- Uses an embedded editor with temporary files; sends real key and mouse events.
local dir = vim.fn.tempname()
vim.fn.mkdir(dir, "p")
dir = vim.uv.fs_realpath(dir)
vim.fn.writefile({ "preview fixture", "second line" }, dir .. "/example.txt")
local child = vim.fn.jobstart({ "nvim", "--embed", "--headless", "-i", "NONE" }, { rpc = true })
local function eval(code, args)
	return vim.rpcrequest(child, "nvim_exec_lua", code, args or {})
end
local function input(keys)
	vim.rpcrequest(child, "nvim_input", keys)
end
local function wait(code, message)
	local done = vim.wait(4000, function()
		return eval(code)
	end, 25)
	assert(done, message or code)
end
local function open()
	input("<C-n>")
	wait(
		'local p=Snacks.picker.get({source="explorer"})[1]; return p and p:current() and not p:current().dir and p.preview.win:valid() and p.list.win:valid() and vim.api.nvim_get_current_win() == p.list.win.win and vim.fn.mode() == "n" and vim.fn.maparg("?", "n", false, true).buffer == 1',
		"Explorer file selection"
	)
	-- Allow scheduled picker focus/render callbacks to finish before sending input.
	vim.wait(100)
end
local function click(row, col)
	vim.rpcrequest(child, "nvim_input_mouse", "left", "press", "", 0, row, col)
	vim.rpcrequest(child, "nvim_input_mouse", "left", "release", "", 0, row, col)
end
local ok, err = xpcall(function()
	eval(
		"vim.o.columns=140; vim.o.lines=45; vim.cmd.cd(vim.fs.dirname(...)); vim.cmd.edit(...)",
		{ dir .. "/example.txt" }
	)
	for _, key in ipairs({ "v", "s" }) do
		local old_win = eval("return vim.api.nvim_get_current_win()")
		local old_pos = eval("return vim.api.nvim_win_get_position(0)")
		open()
		assert(
			eval(
				'local p=Snacks.picker.get({source="explorer"})[1]; return vim.inspect(vim.api.nvim_win_get_config(p.layout.root.win).footer):find("gr root",1,true) ~= nil'
			),
			"Visible keymap footer missing"
		)
		input(key)
		wait(
			'return #Snacks.picker.get({source="explorer"}) == 0 and #vim.api.nvim_tabpage_list_wins(0) == 2',
			"Split did not open/close picker"
		)
		local pos = eval("return vim.api.nvim_win_get_position(0)")
		assert(eval("return vim.api.nvim_get_current_win()") ~= old_win)
		assert(key == "v" and pos[2] > old_pos[2] or key == "s" and pos[1] > old_pos[1], "Wrong split direction")
		eval("vim.cmd.only()")
	end
	open()
	input("?")
	wait(
		'for _, w in ipairs(vim.api.nvim_list_wins()) do if vim.bo[vim.api.nvim_win_get_buf(w)].filetype == "snacks_win_help" then return true end end; return false',
		"Keymap help did not open"
	)
	input("?")
	wait(
		'for _, w in ipairs(vim.api.nvim_list_wins()) do if vim.bo[vim.api.nvim_win_get_buf(w)].filetype == "snacks_win_help" then return false end end; return true',
		"Keymap help did not close"
	)
	local pos = eval('return vim.api.nvim_win_get_position(Snacks.picker.get({source="explorer"})[1].preview.win.win)')
	click(pos[1], pos[2])
	wait(
		'local p=Snacks.picker.get({source="explorer"})[1]; return p and vim.api.nvim_get_current_win() == p.preview.win.win',
		"Clicking preview closed explorer"
	)
	local outside = eval('return vim.api.nvim_win_get_position(Snacks.picker.get({source="explorer"})[1].main)')
	click(outside[1] + 1, outside[2] + 1)
	wait('return #Snacks.picker.get({source="explorer"}) == 0', "Clicking outside did not close explorer")
	assert(eval("return #vim.api.nvim_tabpage_list_wins(0)") == 1, "Leftover floating windows")
	assert(eval("return vim.v.errmsg") == "", eval("return vim.v.errmsg"))
	-- Both entry points and navigation work when the file/cwd are deep in a repo.
	assert(vim.system({ "git", "init", "--quiet", dir }):wait().code == 0)
	vim.fn.mkdir(dir .. "/nested/deeper", "p")
	vim.fn.writefile({ "nested preview" }, dir .. "/nested/deeper/file.txt")
	eval("vim.g.explorer_test_root = ...", { dir })
	eval("vim.cmd.cd(vim.fs.dirname(...)); vim.cmd.edit(...)", { dir .. "/nested/deeper/file.txt" })
	open()
	assert(eval('return Snacks.picker.get({source="explorer"})[1]:cwd()') == dir, "Ctrl-n did not use Git root")
	input("<Esc>")
	wait('return #Snacks.picker.get({source="explorer"}) == 0')
	input(" -")
	wait(
		'local p=Snacks.picker.get({source="explorer"})[1]; return p and p:cwd() == vim.g.explorer_test_root and p.list.win:valid() and vim.api.nvim_get_current_win() == p.list.win.win and p:current() and p:current().file == vim.g.explorer_test_root .. "/nested/deeper/file.txt"'
	)
	vim.wait(100)
	assert(
		eval(
			'local p=Snacks.picker.get({source="explorer"})[1]; return vim.inspect(vim.api.nvim_win_get_config(p.layout.root.win).title):find(vim.g.explorer_test_root, 1, true) ~= nil'
		),
		"Project root not visible in title"
	)
	input("-")
	wait(
		'local p=Snacks.picker.get({source="explorer"})[1]; return p:cwd() == vim.g.explorer_test_root and p:current().file == vim.g.explorer_test_root .. "/nested/deeper"',
		"Parent selection changed root"
	)
	input(".")
	vim.wait(100)
	assert(
		eval('return Snacks.picker.get({source="explorer"})[1]:cwd() == vim.g.explorer_test_root'),
		"Directory focus changed root"
	)
	input("<BS>")
	wait(
		'local p=Snacks.picker.get({source="explorer"})[1]; return p:cwd() == vim.g.explorer_test_root and p:current().file == vim.g.explorer_test_root .. "/nested"',
		"Backspace did not select parent"
	)
	input("gr")
	wait(
		'local p=Snacks.picker.get({source="explorer"})[1]; return p:cwd() == vim.g.explorer_test_root and p:current().file == vim.g.explorer_test_root',
		"Root selection failed"
	)
	input("<BS>")
	vim.wait(100)
	assert(
		eval(
			'local p=Snacks.picker.get({source="explorer"})[1]; return p:cwd() == vim.g.explorer_test_root and p:current().file == vim.g.explorer_test_root'
		),
		"Navigated outside project root"
	)
	input("<Esc>")
	wait('return #Snacks.picker.get({source="explorer"}) == 0')
	assert(eval("return vim.v.errmsg") == "", eval("return vim.v.errmsg"))
	print("PASS: splits, help, mouse cleanup, anchored project tree and persistent root title")
end, debug.traceback)
vim.fn.jobstop(child)
vim.fn.delete(dir, "rf")
if not ok then
	print(err)
	vim.cmd("cquit!")
else
	vim.cmd("qa!")
end
