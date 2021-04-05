-- MCP dns-com-awns-status Package
-- (http://www.awns.com/mcp/packages/README.dns-com-awns-status)
--
-- Write text to the status bar.
--
-- Author: lisdude <lisdude@lisdude.com>
--

local status_trigger = "^#\\$#dns-com-awns-status (\\d{20}) text: \"(.+)\"$"

function update_status(data)
    if data[2] ~= auth_key then
        if mcp_settings["debug_mcp"] then
            blight.output(C_BCYAN .. ">>> " .. C_RED .. "dns-com-awns-status authorization key didn't match!" .. C_RESET)
        end
    else
       blight.status_line(0, data[3])
    end
end

function init_status()
    if status_init_trigger == nil then
        status_init_trigger = trigger.add(status_trigger, { gag = not mcp_settings["debug_mcp"] }, update_status)
    end
end

supported_packages["dns-com-awns-status"] = {init_status, 1.0, 1.0}
