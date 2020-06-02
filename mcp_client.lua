-- MCP dns-com-vmoo-client Package
-- (http://vmoo.com/support/moo/mcp-specs/#vm-client)
--
-- Inform the server of the client name and version.
-- TODO: Inform the server of the length of the terminal window.
--
-- Author: lisdude <lisdude@lisdude.com>
--

-- Send the size of the terminal to the MOO to automatically set @linelength
function update_linelength()
    local width, height = blight:terminal_dimensions()
    blight:send("#$#dns-com-vmoo-client-screensize " .. auth_key .. " Cols: " .. width .. " Rows: " .. height, gag)
end
function init_client()
    local client_name, client_version = blight:version()
    blight:send("#$#dns-com-vmoo-client-info " .. auth_key .. " name: \"" .. client_name .. "\" text-version: \"" .. client_version .. "\" internal-version: \"0\"", gag);
    update_linelength()
    blight:add_alias("/linelen", update_linelength)
end

supported_packages["dns-com-vmoo-client"] = {init_client, 1.0, 1.0};
