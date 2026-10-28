local M = {}
local function ordinary(buf)
	return vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted and vim.bo[buf].buftype == ""
end

local function remove(targets)
	local doomed = {}
	for _, buf in ipairs(targets) do
		doomed[buf] = true
	end
	local replacement
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if ordinary(buf) and not doomed[buf] then
			replacement = buf
			break
		end
	end
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		if doomed[vim.api.nvim_win_get_buf(win)] then
			replacement = replacement or vim.api.nvim_create_buf(true, false)
			vim.api.nvim_win_set_buf(win, replacement)
		end
	end
	for _, buf in ipairs(targets) do
		if vim.api.nvim_buf_is_valid(buf) then
			local ok, err = pcall(vim.api.nvim_buf_delete, buf, { force = false })
			if not ok then
				vim.notify(tostring(err), vim.log.levels.WARN)
			end
		end
	end
end

function M.close()
	local buf = vim.api.nvim_get_current_buf()
	if not ordinary(buf) then
		vim.notify("This shortcut closes file buffers only; hide terminals with Ctrl-g or Ctrl-\\.")
		return
	end
	if vim.bo[buf].modified then
		vim.notify("Buffer has unsaved changes. Save it before closing.", vim.log.levels.WARN)
		return
	end
	remove({ buf })
end

function M.close_others()
	local current = vim.api.nvim_get_current_buf()
	local targets, skipped = {}, 0
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if buf ~= current and ordinary(buf) then
			if vim.bo[buf].modified then
				skipped = skipped + 1
			else
				table.insert(targets, buf)
			end
		end
	end
	remove(targets)
	if skipped > 0 then
		vim.notify("Kept " .. skipped .. " unsaved buffer(s).")
	end
end
return M
