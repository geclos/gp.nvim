local u = require("gp.utils")
local r = require("gp.render")
local M = {}

-- Split a context insertion command into its component parts
function M.cmd_split(cmd)
	return vim.split(cmd, ":", { plain = true })
end

local function read_file(filepath)
	local file = io.open(filepath, "r")
	if not file then
		return nil
	end
	local content = file:read("*all")
	file:close()
	return content
end

-- Parse out all context insertion commands
local function get_commands(msg, cmds, import)
	import = import or false

	for cmd in msg:gmatch("(@code:[%w%.%-/_ ]+)/") do
		table.insert(cmds, cmd)
	end

	for cmd in msg:gmatch("(@text:[%w%.%-/_ ]+)/") do
		table.insert(cmds, cmd)
	end

	for cmd in msg:gmatch("(@codedir:[%w%.%-/_ ]+)/") do
		table.insert(cmds, cmd)
	end

	for cmd in msg:gmatch("(@textdir:[%w%.%-/_ ]+)/") do
		table.insert(cmds, cmd)
	end

	if not import then
		for cmd in msg:gmatch("(@import:[%w%.%-/_ ]+)/") do
			table.insert(cmds, cmd)
		end
	end
end

local function recursive_import(msg, texts)
	local cmds = {}
	get_commands(msg, cmds)

	for _, cmd in ipairs(cmds) do
		local parts = M.cmd_split(cmd)

		local cwd = vim.fn.getcwd()

		local files = {}
		if parts[1] == "@codedir" or parts[1] == "@textdir" then
			local dirpath = u.path_join(cwd, parts[2])
			for _, filename in pairs(vim.fn.readdir(dirpath)) do
				local filepath = dirpath .. "/" .. filename
				local rel_path = parts[2] .. "/" .. filename
				if vim.fn.isdirectory(filepath) == 0 then
					table.insert(files, {
						cmd = parts[1]:sub(-5),
						path = rel_path,
					})
				end
			end
		else
			table.insert(files, { cmd = parts[1], path = parts[2] })
		end

		for _, file in ipairs(files) do
			local fullpath = u.path_join(cwd, file.path)
			local content = read_file(fullpath)
			if content then
				if file.cmd == "@import" then
					local recursive_texts = {}
					recursive_import(content, recursive_texts)
					table.insert(texts, table.concat(recursive_texts, "\n\n\n\n"))
				elseif file.cmd == "@code" then
					table.insert(texts, string.format("%s\n```\n%s\n```", file.path, content))
				else
					table.insert(texts, content)
				end
			end
		end
	end
end

function M.insert_contexts(msg)
	local texts = {}

	recursive_import(msg, texts)

	local cmds = {}
	get_commands(msg, cmds)
	for _, cmd in ipairs(cmds) do
		msg = msg:gsub(cmd, "", 1)
	end

	if #texts == 0 then
		return msg
	else
		return string.format("%s\n\n\n\n%s", table.concat(texts, "\n\n\n\n"), msg)
	end
end

return M
