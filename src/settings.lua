-- Restore default settings and save them to disk.
local function mcp_reset_defaults()
    local mcp_defaults = {
        simpleedit_path = mcp_plugin_path .. "simpleedit/",
        edit_command = "vim -c \"set syntax=moo\" %FILE",
        stat_command = "stat",
        simpleedit_timeout = 10800,
        lambdamoo_connect_string = "\\*\\*\\* Connected \\*\\*\\*",
        debug_mcp = false
    }
    store.disk_write("mcp_settings", json.encode(mcp_defaults))
end

-- Read settings from disk.
function mcp_read_settings()
    mcp_settings = json.decode(store.disk_read("mcp_settings"))
end

-- Display MCP settings.
function mcp_display_settings(args)
    if #args == 1 then
        for key, value in pairs(mcp_settings) do
            blight.output("[mcp] " .. C_YELLOW .. key .. C_RESET .. " => " .. tostring(value))
        end
        blight.output("\nUse '/mcp defaults' to reset settings to defaults.")
    elseif args[2] == "defaults" then
        mcp_reset_defaults()
        mcp_read_settings()
        blight.output("[mcp] " .. C_CYAN .. "***" .. C_RESET .. " MCP settings restored to defaults. " .. C_CYAN .. "***" .. C_RESET)
    else
        if mcp_settings[args[2]] == nil then
            blight.output("[mcp] " .. C_RED .. " Setting doesn't exist " .. C_RESET)
        else
            blight.output("[mcp] " .. C_YELLOW .. args[2] .. C_RESET .. " => " .. tostring(mcp_settings[args[2]]))
        end
    end
end

-- Change MCP settings on disk.
function mcp_change_setting(args)
    if mcp_settings[args[2]] == nil then
        blight.output("[mcp] " .. C_RED .. " Setting doesn't exist " .. C_RESET)
    else
        -- Some settings require special shenanigans:
        if args[2] == "simpleedit_timeout" then
            args[3] = tonumber(args[3])
        elseif args[2] == "debug_mcp" then
            args[3] = args[3] == "true" and true or false
        end
        mcp_settings[args[2]] = args[3]
        store.disk_write("mcp_settings", json.encode(mcp_settings))
        blight.output("[mcp] " .. C_YELLOW .. args[2] .. C_RESET .. " => " .. tostring(mcp_settings[args[2]]))
        if args[2] == "debug_mcp" or args[2] == "simpleedit_timeout" or args[2] == "lambdamoo_connect_string" then
            blight.output("[mcp] " .. C_CYAN .. "***" .. C_RESET .. " Changing this setting requires reloading the MCP plugin. " .. C_CYAN .. "***" .. C_RESET)
        end
    end
end

-- Load settings from disk and put them in handy global variables.
if store.disk_read("mcp_settings") == nil then
    mcp_reset_defaults()
end

mcp_read_settings()

alias.add("^/mcp$", mcp_display_settings)
alias.add("^/mcp ((?:\\S+)) (.*)$", mcp_change_setting)
alias.add("^/mcp ([^ ]*)$", mcp_display_settings)
