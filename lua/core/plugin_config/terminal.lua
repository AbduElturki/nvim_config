-- Persistent terminal buffers, backed entirely by Neovim's terminal API.
local M = {}
local sessions = {}
local assistants = {
	{ name = "Codex", command = "codex", key = "<leader>ac" },
	{ name = "Claude", command = "claude", key = "<leader>al" },
	{ name = "Gemini", command = "gemini", key = "<leader>ag" },
}
local assistant_names = {}
for _, assistant in ipairs(assistants) do
	assistant_names[assistant.name] = true
end

function M.toggle(name, command)
	-- A terminal-local toggle always hides that terminal, even after :cd.
	local current = vim.api.nvim_get_current_buf()
	for _, session in pairs(sessions) do
		if
			session.name == name
			and session.buf == current
			and session.win
			and vim.api.nvim_win_is_valid(session.win)
		then
			vim.api.nvim_win_close(session.win, true)
			session.win = nil
			return
		end
	end
	local cwd = vim.fs.root(0, { ".git" }) or vim.fn.getcwd()
	local key = cwd .. "\n" .. name
	local session = sessions[key] or { name = name }
	sessions[key] = session
	if session.win and vim.api.nvim_win_is_valid(session.win) then
		vim.api.nvim_win_close(session.win, true)
		session.win = nil
		return
	end
	local fresh = not session.buf or not vim.api.nvim_buf_is_valid(session.buf) or session.exited
	if fresh then
		if session.buf and vim.api.nvim_buf_is_valid(session.buf) then
			vim.api.nvim_buf_delete(session.buf, { force = true })
		end
		if vim.fn.executable(command[1]) == 0 then
			vim.notify("Executable not found: " .. command[1], vim.log.levels.ERROR)
			return
		end
		session.buf = vim.api.nvim_create_buf(false, true)
		session.exited = false
	end
	local width = math.max(1, math.min(vim.o.columns - 2, math.floor(vim.o.columns * 0.9)))
	local height = math.max(1, math.min(vim.o.lines - 4, math.floor(vim.o.lines * 0.85)))
	session.win = vim.api.nvim_open_win(session.buf, true, {
		relative = "editor",
		style = "minimal",
		border = "rounded",
		title = " " .. name .. " ",
		title_pos = "center",
		width = width,
		height = height,
		col = math.max(0, math.floor((vim.o.columns - width) / 2) - 1),
		row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1),
	})
	if fresh then
		vim.bo[session.buf].bufhidden = "hide"
		local job = vim.fn.jobstart(command, {
			term = true,
			cwd = cwd,
			on_exit = function()
				session.exited = true
			end,
		})
		if job <= 0 then
			session.exited = true
			vim.notify("Could not start " .. name, vim.log.levels.ERROR)
			return
		end
		vim.keymap.set({ "n", "t" }, "<C-\\>", function()
			M.toggle(name, command)
		end, { buffer = session.buf, desc = "Hide terminal" })
		if assistant_names[name] then
			vim.keymap.set({ "n", "t" }, "<C-g>", function()
				M.toggle(name, command)
			end, { buffer = session.buf, desc = "Hide " .. name })
		end
	end
	vim.cmd.startinsert()
end

local function shell()
	M.toggle("Terminal", { vim.o.shell })
end
vim.keymap.set("n", "<C-\\>", shell, { desc = "Toggle terminal" })
for _, assistant in ipairs(assistants) do
	local function toggle()
		M.toggle(assistant.name, { assistant.command })
	end
	vim.keymap.set("n", assistant.key, toggle, { desc = "Toggle " .. assistant.name })
	vim.api.nvim_create_user_command(assistant.name, toggle, {
		desc = "Toggle " .. assistant.name .. " in the project root",
	})
end
local function choose_assistant()
	vim.ui.select(assistants, {
		prompt = "Choose assistant:",
		format_item = function(assistant)
			return assistant.name .. (vim.fn.executable(assistant.command) == 1 and "" or " (CLI not installed)")
		end,
	}, function(assistant)
		if assistant then
			M.toggle(assistant.name, { assistant.command })
		end
	end)
end
vim.keymap.set("n", "<leader>aa", choose_assistant, { desc = "Choose AI assistant" })
vim.api.nvim_create_user_command("Assistant", choose_assistant, { desc = "Choose AI assistant" })
vim.api.nvim_create_user_command("Terminal", shell, { desc = "Toggle terminal" })
vim.api.nvim_create_autocmd("TermOpen", {
	group = vim.api.nvim_create_augroup("TerminalKeymaps", { clear = true }),
	callback = function(event)
		-- Keep Escape and jk available to terminal TUIs such as Codex.
		vim.keymap.set("t", "<C-x>", "<C-\\><C-n>", { buffer = event.buf, desc = "Terminal normal mode" })
	end,
})
vim.opt.autoread = true
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "TermClose", "TermLeave" }, {
	group = vim.api.nvim_create_augroup("ReloadExternalEdits", { clear = true }),
	callback = function()
		vim.schedule(function()
			-- :checktime is forbidden in the special q: / q/ command window.
			if vim.fn.getcmdwintype() ~= "" then
				return
			end
			vim.cmd.checktime()
		end)
	end,
})
return M
