local dap = require("dap")
local dapview = require("dap-view")

dap.adapters.codelldb = {
	type = "executable",
	command = "codelldb",
}

dap.configurations.cpp = {
	{
		name = "Launch file",
		type = "codelldb",
		request = "launch",
		program = function()
			return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
		end,
		cwd = "${workspaceFolder}",
		stopOnEntry = false,
	},
}
dap.configurations.c = dap.configurations.cpp
dap.configurations.rust = dap.configurations.cpp

require("dap-python").setup("uv")

vim.keymap.set("n", "<leader>bb", dap.toggle_breakpoint, { desc = "Toggle Breakpoint" })
vim.keymap.set("n", "<leader>bc", dap.continue, { desc = "Continue or start new debugging session" })
vim.keymap.set("n", "<leader>bs", dap.step_over, { desc = "Step Over" })
vim.keymap.set("n", "<leader>bi", dap.step_into, { desc = "Step Into" })
vim.keymap.set("n", "<leader>bo", dap.step_out, { desc = "Step Out" })
vim.keymap.set("n", "<leader>bl", dap.run_last, { desc = "Run Last" })
vim.keymap.set("n", "<leader>bv", dapview.toggle, { desc = "Toggle DAP View" })

vim.fn.sign_define("DapBreakpoint", { text = "", texthl = "DiagnosticSignError", linehl = "", numhl = "" })
