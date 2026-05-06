local Keys = {}

local defaults = {
	trigger_key = "<leader>ai",
	accept_key = "<C-y>",
	highlights = {
		normal = "Normal",
		border = "Keyword",
		title_icon = "DiagnosticInfo",
		title_text = "Keyword",
		footer = "Comment",
	},
}

Keys.values = vim.deepcopy(defaults)

function Keys.setup(user_opts)
	Keys.values = vim.tbl_deep_extend("force", vim.deepcopy(defaults), user_opts or {})
	return Keys.values
end

return Keys
