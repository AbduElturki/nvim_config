-- Buffer-local controls: :AutosaveToggle and :AutosaveDelay {milliseconds}.
vim.g.autosave_delay = 750
local pending = {}
vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged" }, {
	group = vim.api.nvim_create_augroup("NativeAutosave", { clear = true }),
	callback = function(event)
		local buf = event.buf
		local token = {}
		pending[buf] = token
		vim.defer_fn(function()
			if pending[buf] ~= token then
				return
			end
			pending[buf] = nil
			if not vim.api.nvim_buf_is_valid(buf) then
				return
			end
			if vim.b[buf].autosave_enabled == false then
				return
			end
			local opt = vim.bo[buf]
			if
				opt.buftype ~= ""
				or not opt.modifiable
				or opt.readonly
				or not opt.modified
				or vim.api.nvim_buf_get_name(buf) == ""
			then
				return
			end
			local ok, err = pcall(vim.api.nvim_buf_call, buf, function()
				vim.cmd("silent update")
			end)
			if not ok then
				vim.notify("Autosave: " .. tostring(err), vim.log.levels.WARN)
			end
		end, vim.b[buf].autosave_delay or vim.g.autosave_delay)
	end,
})

vim.api.nvim_create_user_command("AutosaveToggle", function()
	vim.b.autosave_enabled = vim.b.autosave_enabled == false
	pending[vim.api.nvim_get_current_buf()] = nil
	vim.notify("Autosave " .. (vim.b.autosave_enabled and "enabled" or "paused") .. " for this buffer")
end, {})
vim.api.nvim_create_user_command("AutosaveDelay", function(opts)
	local delay = tonumber(opts.args)
	if not delay or delay < 0 or delay % 1 ~= 0 then
		vim.notify("Use a non-negative integer number of milliseconds", vim.log.levels.ERROR)
		return
	end
	vim.b.autosave_delay = delay
end, { nargs = 1 })
vim.keymap.set("n", "<leader>ua", "<Cmd>AutosaveToggle<CR>", { desc = "Toggle buffer autosave" })
