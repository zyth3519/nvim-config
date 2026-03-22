local PRIORITY_TARGETS = {
	"run",
	"build",
	"test",
	"clean",
	"install",
}

local function makefile_path(root)
	local candidates = {
		root .. "/Makefile",
		root .. "/makefile",
		root .. "/GNUmakefile",
	}

	for _, path in ipairs(candidates) do
		if vim.uv.fs_stat(path) ~= nil then
			return path
		end
	end

	return nil
end

local function read_text(path)
	local fd = vim.uv.fs_open(path, "r", 438)
	if not fd then
		return nil
	end

	local stat = vim.uv.fs_fstat(fd)
	if not stat then
		vim.uv.fs_close(fd)
		return nil
	end

	local content = vim.uv.fs_read(fd, stat.size, 0)
	vim.uv.fs_close(fd)
	return content
end

local function collect_targets(content)
	local targets = {}
	local seen = {}

	for line in content:gmatch("[^\r\n]+") do
		local target = line:match("^([A-Za-z0-9][A-Za-z0-9%._%-]*)%s*:")
		if target
			and not seen[target]
			and target ~= ".PHONY"
			and not target:find("%%", 1, true)
		then
			seen[target] = true
			table.insert(targets, target)
		end
	end

	return targets
end

local function sort_targets(targets)
	local ordered = {}
	local seen = {}

	for _, target in ipairs(PRIORITY_TARGETS) do
		for _, candidate in ipairs(targets) do
			if candidate == target and not seen[candidate] then
				seen[candidate] = true
				table.insert(ordered, candidate)
			end
		end
	end

	for _, target in ipairs(targets) do
		if not seen[target] then
			table.insert(ordered, target)
		end
	end

	return ordered
end

local function make_entry(target)
	if target == "run" then
		return {
			desc = "Make Run",
			cmd = "make run",
		}
	end

	return {
		desc = "Make " .. target,
		cmd = "make " .. target,
	}
end

return {
	name = "make",
	matches = function(dir)
		return makefile_path(dir) ~= nil
	end,
	entries = function(ctx)
		local path = makefile_path(ctx.root)
		if not path then
			return {}
		end

		local content = read_text(path)
		if not content or content == "" then
			return {
				{
					desc = "Make",
					cmd = "make",
				},
			}
		end

		local targets = sort_targets(collect_targets(content))
		local entries = {}

		if #targets == 0 then
			return {
				{
					desc = "Make",
					cmd = "make",
				},
			}
		end

		for index, target in ipairs(targets) do
			if index > 9 then
				break
			end
			table.insert(entries, make_entry(target))
		end

		return entries
	end,
}
