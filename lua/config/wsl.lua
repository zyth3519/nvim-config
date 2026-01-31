local function is_wsl()
    -- 读取环境变量 WSL_DISTRO_NAME，存在则为 WSL 环境
    return vim.env.WSL_DISTRO_NAME ~= nil
end

-- 获取Rime执行文件
local function get_rime()
    -- 读取注册表来获取Rime执行文件所在文件
    local cmd = {
        "powershell.exe",
        "-c",
        "reg query HKEY_LOCAL_MACHINE\\SOFTWARE\\WOW6432Node\\Rime\\Weasel /v WeaselRoot"
    }
    local reg_result = vim.fn.system(cmd)
    local path = nil;

    -- 解析输出
    if vim.v.shell_error == 0 then
        local arr = vim.fn.split(reg_result);
        path = string.format("%s %s", arr[4], arr[5]);
    end


    if not path then
        return nil
    end


    -- 将Windows路径转为wsl路径
    local wslpath_result = vim.fn.system({
        'wslpath',
        path
    })
    return string.format("%s/WeaselServer.exe", string.gsub(wslpath_result, "%s+$", ""))
end

if is_wsl() then
    local rime_cmd = get_rime();
    if not rime_cmd then
        return
    end

    local flag = false;
    vim.api.nvim_create_augroup("ZythRimeSwitch", { clear = true })
    -- 进入Normal和命令模式切换到英文, 只切换一次
    -- 只有再次进入Inster模式才会切换
    vim.api.nvim_create_autocmd("ModeChanged", {
        group = "ZythRimeSwitch",
        pattern = { "*:n", "*:c" },
        callback = function()
            if flag then
                return
            end
            flag = true;
            -- 切换中文是 /nascii
            vim.fn.system({
                rime_cmd,
                "/ascii"
            })
        end,
    })

    -- 重置状态
    vim.api.nvim_create_autocmd("InsertEnter", {
        group = "ZythRimeSwitch",
        callback = function ()
            flag = false
        end
    })
end
