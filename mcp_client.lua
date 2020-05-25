-- MCP dns-com-vmoo-client Package
-- (http://vmoo.com/support/moo/mcp-specs/#vm-client)
--
-- Inform the server of the client name and version.
-- TODO: Inform the server of the length of the terminal window.
--
-- Author: lisdude <lisdude@lisdude.com>
--
function init_client()
    blight:send("#$#dns-com-vmoo-client-info " .. auth_key .. " name: \"Blightmud\" text-version: \"0.1.0\" internal-version: \"0\"");
end

supported_packages["dns-com-vmoo-client"] = {init_client, 1.0, 1.0};
