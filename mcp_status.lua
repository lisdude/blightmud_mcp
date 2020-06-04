-- MCP dns-com-awns-status Package
-- (http://www.awns.com/mcp/packages/README.dns-com-awns-status)
--
-- Write text to the status bar.
--
-- Author: lisdude <lisdude@lisdude.com>
--

local status_trigger = "#\\$#dns-com-awns-status (.+) text: (.+)"

function update_status(data)
    blight:status_line(0, data[3])
end

function init_status()
    blight:add_trigger(status_trigger, { gag = not debug_mcp }, update_status)
end

supported_packages["dns-com-awns-status"] = {init_status, 1.0, 1.0}
