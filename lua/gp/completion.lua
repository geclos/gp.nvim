local u = require("gp.utils")
local context = require("gp.context")

-- Gets a buffer variable or returns the default
local function buf_get_var(buf, var_name, default)
	local status, result = pcall(vim.api.nvim_buf_get_var, buf, var_name)
	if status then
		return result
	else
		return default
	end
end

-- This function is only here make the get/set call pair look consistent
local function buf_set_var(buf, var_name, value)
	return vim.api.nvim_buf_set_var(buf, var_name, value)
end

local source = {}

source.src_name = "gp_completion"

source.new = function()
	-- print("source.new called")
	return setmetatable({}, { __index = source })
end

source.get_trigger_characters = function()
	return { "@", ":", "/" }
end

source.setup_for_buffer = function(bufnr)
	print("in setup_for_buffer")
	local config = require("cmp").get_config()

	print("cmp.get_config() returned:")
	print(vim.inspect(config))

	print("cmp_config.set_buffer: " .. config.set_buffer)
	config.set_buffer({
		sources = {
			{ name = source.src_name },
		},
	}, bufnr)
end

source.setup_autocmd_for_markdown = function()
	-- print("setting up autocmd...")
	vim.api.nvim_create_autocmd("BufEnter", {
		pattern = { "*.md", "markdown" },
		callback = function(arg)
			local attached_varname = "gp_source_attached"
			local attached = buf_get_var(arg.buf, attached_varname, false)
			if attached then
				return
			end

			print("attaching completion source for buffer: " .. arg.buf)
			local cmp = require("cmp")
			cmp.setup.buffer({
				sources = cmp.config.sources({
					{ name = source.src_name },
				}),
			})

			buf_set_var(arg.buf, attached_varname, true)
		end,
	})
end

source.register_cmd_source = function()
	-- print("registering completion src")
	require("cmp").register_source(source.src_name, source.new())
end

local function extract_cmd(request)
	local target = request.context.cursor_before_line
	local start = target:match(".*()@")
	if start then
		return string.sub(target, start, request.offset)
	end
end

source.complete = function(self, request, callback)
	local input = string.sub(request.context.cursor_before_line, request.offset - 1)
	print("[comp] input: '" .. input .. "'")
	local cmd = extract_cmd(request)
	if not cmd then
		return
	end

	print("[comp] cmd: '" .. cmd .. "'")
	local cmd_parts = context.cmd_split(cmd)

	local items = {}
	local isIncomplete = true

	if cmd_parts[1]:match("@code") then
		print("[complete] @code case")
		-- List files in the current working directory
		local cwd = vim.fn.getcwd()
		local files = {}

		local function scan_dir(dir)
			local handle = vim.loop.fs_scandir(dir)
			if handle then
				while true do
					local name, type = vim.loop.fs_scandir_next(handle)
					if not name then break end
					local full_path = dir .. '/' .. name
					if type == "file" then
						table.insert(files, full_path:sub(#cwd + 2)) -- Remove cwd prefix
					elseif type == "directory" and not name:match("^%.") then
						scan_dir(full_path)
					end
				end
			end
		end

		scan_dir(cwd)

		-- Sort files alphabetically
		table.sort(files)

		-- Limit the list to 10 items
		local limited_files = {}
		for i = 1, #files do
			table.insert(limited_files, files[i])
		end

		-- Create completion items
		for _, file in ipairs(limited_files) do
			table.insert(items, {
				label = file .. '/',
				kind = require("cmp").lsp.CompletionItemKind.File,
			})
		end

		isIncomplete = false
	elseif input:match("^@") then
		print("[complete] @ case")
		items = {
			{ label = "code", kind = require("cmp").lsp.CompletionItemKind.Keyword },
		}
		isIncomplete = false
	else
		print("[complete] default case")
		isIncomplete = true
	end

	local data = { items = items, isIncomplete = isIncomplete }
	print("[complete] Callback data:")
	print(vim.inspect(data))
	callback(data)
	print("[complete] Callback called")
end

source.setup_autocmd_for_markdown()

return source
