--
-- MUD Client Protocol 2.1
-- (http://www.moo.mud.org/mcp2/mcp2.html)
--
-- Author: lisdude <lisdude@lisdude.com>
--

--- Configuration ---
simpleedit_path = "simpleedit/"
edit_command = "vim -c \"set syntax=moo\""
stat_command = "stat"
simpleedit_timeout = 10800
lambdamoo_connect_string = "\\*\\*\\* Connected \\*\\*\\*"
debug_mcp = false

min_version = 2.1
max_version = 2.1

advertisement_regex = "^#\\$#mcp version: (\\d{1,4}\\.\\d{1,4}) to: (\\d{1,4}\\.\\d{1,4})$"
negotiate_can_regex = "^#\\$#mcp-negotiate-can (\\d{20}) package: (.+) min-version: (\\d{1,4}\\.\\d{1,4}) max-version: (\\d{1,4}\\.\\d{1,4})$"

supported_packages = {}         -- Packages that the client supports.
negotiated_packages = {}        -- Packages that both the client and server support.

require("mcp_utils")            -- useful utility functions
require("mcp_negotiate")        -- mcp-negotiate package
require("mcp_client")           -- dns-com-vmoo-client package
require("mcp_simpleedit")       -- dns-org-mud-moo-simpleedit package
require("lambdamoo_simpleedit") -- early LambdaMOO simpleedit support
require("mcp_status")           -- dns-com-awns-status package

-- Begin registration with the server. This process sends the authentication key
-- and negotiates what packages are available. This is a bit odd because we have to
-- register the negotiation trigger outside of the actual negotiation package.
-- Why? Because we have to be able to negotiate to negotiate the negotiate package. Twisty.
function mcp_register(version)
    seed_rng()
    auth_key = generate_auth_key()
    mud.send("#$#mcp authentication-key: " .. auth_key .. " version: " .. min_version .. " to: " .. max_version, gag)
    if negotiate_trigger == nil then
        negotiate_trigger = trigger.add(negotiate_can_regex, { gag = not debug_mcp }, negotiate_can)
    end
end

-- The callback function for the MCP advertisement message. This will determine
-- if the client and server both support a common MCP version. If so, the 'mcp_version'
-- variable is set to the highest version supported by both and actual MCP registration begins.
-- If no supported versions are found, a message is printed and nothing else happens.
function mcp_register_trigger(matches)
    mcp_version = supported_version(min_version, max_version, tonumber(matches[2]), tonumber(matches[3]))
    if mcp_version == false then
        blight.output(">>> Unsupported MCP versions: " .. matches[2] .. " to " .. matches[3] .. " <<<")
    else
        mcp_register(mcp_version)
    end
end

trigger.add(advertisement_regex, { gag = not debug_mcp }, mcp_register_trigger)
