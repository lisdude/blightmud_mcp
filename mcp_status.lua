-- MCP dns-com-awns-status Package
-- (http://www.awns.com/mcp/packages/README.dns-com-awns-status)
--
-- Write text to the status bar.
--
-- Author: lisdude <lisdude@lisdude.com>
--

local status_trigger = "^#\\$#dns-com-awns-status (.+) text: \"(.+)\"$"

function update_status(data)
    if data[2] ~= auth_key then
        if debug_mcp then
            blight:output(">>> dns-com-awns-status authorization key didn't match")
        end
    else
       blight:status_line(0, data[3])
    end
end

function init_status()
    if status_init_trigger == nil then
        status_init_trigger = trigger.add(status_trigger, { gag = not debug_mcp }, update_status)
    end
end

supported_packages["dns-com-awns-status"] = {init_status, 1.0, 1.0}
