-- Run: nvim --clean --headless -l ~/.config/nvim/tests/command_window.lua
-- Exercise actual input in an embedded Neovim, including its special cmdwin loop.
local child = vim.fn.jobstart({ "nvim", "--embed", "--headless", "-i", "NONE" }, { rpc = true })
local function eval(code)
	return vim.rpcrequest(child, "nvim_exec_lua", code, {})
end
local function input(keys)
	vim.rpcrequest(child, "nvim_input", keys)
end
local function until_true(code, message)
	assert(
		vim.wait(3000, function()
			return eval(code)
		end, 20),
		message
	)
end
local ok, err = xpcall(function()
	-- No UI/network interaction; only a scratch buffer and command history.
	local original = eval("return vim.api.nvim_get_current_buf()")
	for _, keys in ipairs({ "<Esc>", "q", " q", "i<Esc>" }) do
		input("q:")
		until_true("return vim.fn.getcmdwintype() == ':'", "Command history did not open")
		input(keys)
		until_true(
			"return vim.fn.getcmdwintype() == '' and vim.api.nvim_get_mode().mode == 'n'",
			"Could not close with " .. keys
		)
		assert(eval("return vim.api.nvim_get_current_buf()") == original)
	end
	input("q/")
	until_true("return vim.fn.getcmdwintype() == '/'", "Search history did not open")
	input("<Esc>")
	until_true("return vim.fn.getcmdwintype() == ''", "Search history did not close")
	assert(eval("return vim.fn.maparg('q', 'n')") == "", "Macro recording key was changed outside cmdwin")
	assert(eval("return vim.v.errmsg") == "", "Unexpected Neovim error: " .. eval("return vim.v.errmsg"))
	print("PASS: Escape, q and Space q close command history; insert Escape and search history also work")
end, debug.traceback)
vim.fn.jobstop(child)
if not ok then
	print(err)
	vim.cmd("cquit!")
else
	vim.cmd("qa!")
end
