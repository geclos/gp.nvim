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

	for cmd in msg:gmatch("@code:[%w%p]+") do
		table.insert(cmds, cmd)
	end

	for cmd in msg:gmatch("@text:[%w%p]+") do
		table.insert(cmds, cmd)
	end

	if not import then
		for cmd in msg:gmatch("@import:[%w%p]+") do
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
		local fullpath = u.path_join(cwd, parts[2])
		local content = read_file(fullpath)
		if content then
			if parts[1] == "@import" then
				local recursive_texts = {}
				recursive_import(content, recursive_texts)
				table.insert(texts, table.concat(recursive_texts, "\n\n\n\n"))
			elseif parts[1] == "@code" then
				table.insert(texts, string.format("```\n%s\n```", content))
			else
				table.insert(texts, content)
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
