local actions = require("telescope.actions")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local conf = require("telescope.config").values
local entry_display = require("telescope.pickers.entry_display")
local action_state = require("telescope.actions.state")

local function action(item)
	vim.fn.setreg("+", item.value)
end

local function search(opts)
	local displayer = entry_display.create({
		separator = " ",
		items = {
			{ width = 40 },
			{ width = 18 },
			{ remaining = true },
		},
	})
	local make_display = function(entry)
		return displayer({
			entry.name .. " " .. entry.value,
		})
	end
	local choices = {
		{
			name = "Absolute Path",
			value = vim.fn.expand("%"),
		},
		{
			name = "Relative Path",
			value = vim.fn.expand("%:p"),
		},
		{ name = "File Name", value = vim.fn.expand("%:t") },
		{
			name = "Project Directory Name",
			value = vim.fn.fnamemodify(vim.fn.getcwd(), ":t"),
		},
		{
			name = "Project Path",
			value = vim.fn.getcwd(),
		},
		{
			name = "Git Branch",
			value = vim.fn.systemlist("git branch --show-current")[1],
		},
		{
			name = "Git Origin URL",
			value = vim.fn.systemlist("git remote get-url origin")[1],
		},
		{
			name = "LAN IP Address",
			value = vim.fn.systemlist("ipconfig getifaddr en0")[1],
		},
	}

	pickers
		.new(opts, {
			prompt_title = "Project Info",
			sorter = conf.generic_sorter(opts),
			finder = finders.new_table({
				results = choices,
				entry_maker = function(emoji)
					return {
						ordinal = emoji.name .. emoji.value,
						display = make_display,

						name = emoji.name,
						value = emoji.value,
					}
				end,
			}),
			attach_mappings = function(prompt_bufnr)
				actions.select_default:replace(function()
					local emoji = action_state.get_selected_entry()
					actions.close(prompt_bufnr)
					action(emoji)
				end)
				return true
			end,
		})
		:find()
end

return require("telescope").register_extension({
	setup = function(config)
		action = config.action or action
	end,
	exports = { copypath = search },
})
