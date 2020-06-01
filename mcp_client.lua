-- MCP dns-com-vmoo-client Package
-- (http://vmoo.com/support/moo/mcp-specs/#vm-client)
--
-- Inform the server of the client name and version.
-- TODO: Inform the server of the length of the terminal window.
--
-- Author: lisdude <lisdude@lisdude.com>
--
function init_client()
    local client_name, client_version = blight:version()
    blight:send("#$#dns-com-vmoo-client-info " .. auth_key .. " name: \"" .. client_name .. "\" text-version: \"" .. client_version .. "\" internal-version: \"0\"", gag);
end

supported_packages["dns-com-vmoo-client"] = {init_client, 1.0, 1.0};
