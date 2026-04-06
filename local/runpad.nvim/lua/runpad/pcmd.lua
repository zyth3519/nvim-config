-- 管理用户自定义项目运行命令的存储。
-- 配置文件保存为纯文本格式，每行一条命令：`描述 命令`
-- 例如：运行 cargo run
local M = {}

-- 获取当前项目的配置文件路径。
local function get_config_path()
	local root = vim.fn.getcwd()
	local config_dir = root .. "/.vim"
	local stat = vim.uv.fs_stat(config_dir)
	if not stat then
		vim.uv.fs_mkdir(config_dir, 493)
	end
	return config_dir .. "/runpad.txt"
end

-- 从配置文件加载命令列表。
-- 返回 { entries = { { desc = "...", cmd = "..." }, ... } }
function M.load()
	local path = get_config_path()
	local stat = vim.uv.fs_stat(path)
	if not stat then
		return { entries = {} }
	end

	local file = io.open(path, "r")
	if not file then
		return { entries = {} }
	end

	local entries = {}
	for line in file:lines() do
		if line and line:match("%S") then
			local first_space = line:find(" ")
			if first_space then
				local desc = line:sub(1, first_space - 1)
				local cmd = line:sub(first_space + 1):gsub("^%s+", "")
				if cmd and cmd ~= "" then
					table.insert(entries, { desc = desc, cmd = cmd })
				end
			end
		end
	end
	file:close()

	return { entries = entries }
end

-- 获取命令列表。
function M.get_entries()
	local config = M.load()
	return config.entries or {}
end

-- 打开配置文件编辑窗口。
function M.open()
	local path = get_config_path()
	vim.cmd("vs " .. path)
end

return M
