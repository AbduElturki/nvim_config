local cmp = require("cmp")

require("luasnip.loaders.from_vscode").lazy_load()

cmp.setup({
	mapping = cmp.mapping.preset.insert({
		["<C-b>"] = cmp.mapping.scroll_docs(-4),
		["<C-f>"] = cmp.mapping.scroll_docs(4),
		["<C-o>"] = cmp.mapping.complete(),
		["<C-e>"] = cmp.mapping.abort(),
		["<CR>"] = cmp.mapping.confirm({ select = true }),
	}),
	snippet = {
		expand = function(args)
			require("luasnip").lsp_expand(args.body)
		end,
	},
	sources = cmp.config.sources({
		{ name = "copilot", group_index = 2 },
		{
			name = "luasnip",
			priority = 150,
			group_index = 1,
			option = { show_autosnippets = true, use_show_condition = false },
		},
		{
			name = "nvim_lua",
			entry_filter = function()
				if vim.bo.filetype ~= "lua" then
					return false
				end
				return true
			end,
			priority = 150,
			group_index = 1,
		},

		{
			name = "nvim_lsp",
			priority = 100,
			group_index = 1,
		},
		{ name = "nvim_lsp_signature_help", priority = 100, group_index = 1 },
		{
			name = "treesitter",
			max_item_count = 5,
			priority = 90,
			group_index = 5,
			entry_filter = function(entry, vim_item)
				if entry.kind == 15 then
					local cursor_pos = vim.api.nvim_win_get_cursor(0)
					local line = vim.api.nvim_get_current_line()
					local next_char = line:sub(cursor_pos[2] + 1, cursor_pos[2] + 1)
					if next_char == '"' or next_char == "'" then
						vim_item.abbr = vim_item.abbr:sub(1, -2)
					end
				end
				return vim_item
			end,
		},
		{
			name = "buffer",
			max_item_count = 5,
			keyword_length = 2,
			priority = 50,
			entry_filter = function(entry)
				return not entry.exact
			end,
			option = {
				get_bufnrs = function()
					return vim.api.nvim_list_bufs()
				end,
			},
			group_index = 4,
		},
	}, {
		{ name = "buffer" },
	}),
})
