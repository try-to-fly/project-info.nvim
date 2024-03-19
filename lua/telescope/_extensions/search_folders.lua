local actions = require("telescope.actions")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local conf = require("telescope.config").values
local action_state = require("telescope.actions.state")
local scandir = require("plenary.scandir")

local function is_gitignored(path)
	local gitignore_check = vim.fn.systemlist("git check-ignore " .. path)
	-- 如果git check-ignore命令的输出非空，表示路径被.gitignore忽略
	return #gitignore_check > 0
end

local function get_all_folders(root, current_path, folders, exclude)
	scandir.scan_dir(current_path, {
		hidden = false,
		add_dirs = true,
		depth = 1,
		on_insert = function(entry, typ)
			local relative_path = entry:sub(#root + 2)
			if typ == "directory" and not entry:match(exclude) and not is_gitignored(entry) then
				if relative_path ~= "" then
					table.insert(folders, "./" .. relative_path)
					get_all_folders(root, entry, folders, exclude)
				end
			end
		end,
	})
end
-- 执行Oil命令的函数
local function oil_command(dir)
	vim.cmd("Oil " .. dir)
end

local function search_folders(opts)
	opts = opts or {}
	local cwd = vim.fn.getcwd()
	local folders = { "./" }

	get_all_folders(cwd, cwd, folders, "node_modules")

	pickers
		.new(opts, {
			prompt_title = "Search Folders",
			finder = finders.new_table({
				results = folders,
				entry_maker = function(entry)
					return {
						value = entry,
						display = entry,
						ordinal = entry,
					}
				end,
			}),
			sorter = conf.generic_sorter(opts),
			attach_mappings = function(prompt_bufnr)
				actions.select_default:replace(function()
					local selection = action_state.get_selected_entry()
					actions.close(prompt_bufnr)
					oil_command(selection.value)
				end)
				return true
			end,
		})
		:find()
end

return require("telescope").register_extension({
	exports = {
		search_folders = search_folders,
	},
})
