-- MCP Negotiate Package
--
-- Negotiate which packages, and their versions, are supported
-- by both the client and the server.
--
-- Author: lisdude <lisdude@lisdude.com>
--
advertisement_regex = "^#\\$#mcp version: (\\d{1,4}\\.\\d{1,4}) to: (\\d{1,4}\\.\\d{1,4})$"
negotiate_can_regex = "^#\\$#mcp-negotiate-can (\\d{20}) package: (.+) min-version: (\\d{1,4}\\.\\d{1,4}) max-version: (\\d{1,4}\\.\\d{1,4})$"
negotiate_end_regex = "^#\\$#mcp-negotiate-end (\\d{20})$"

min_version = 2.1
max_version = 2.1

supported_packages = {}         -- Packages that the client supports.
negotiated_packages = {}        -- Packages that both the client and server support.

-- Begin registration with the server. This process sends the authentication key
-- and negotiates what packages are available. This is a bit odd because we have to
-- register the negotiation trigger outside of the actual negotiation package.
-- Why? Because we have to be able to negotiate to negotiate the negotiate package. Twisty.
function mcp_register(version)
    seed_rng()
    auth_key = generate_auth_key()
    mud.send("#$#mcp authentication-key: " .. auth_key .. " version: " .. min_version .. " to: " .. max_version, gag)
    if negotiate_trigger == nil then
        negotiate_trigger = trigger.add(negotiate_can_regex, { gag = not mcp_settings["debug_mcp"] }, negotiate_can)
    end
end

-- The callback function for the MCP advertisement message. This will determine
-- if the client and server both support a common MCP version. If so, the 'mcp_version'
-- variable is set to the highest version supported by both and actual MCP registration begins.
-- If no supported versions are found, a message is printed and nothing else happens.
function mcp_register_trigger(matches)
    mcp_version = supported_version(min_version, max_version, tonumber(matches[2]), tonumber(matches[3]))
    if mcp_version == false then
        blight.output(C_BCYAN .. ">>> " .. C_RED .. "Unsupported MCP versions: " .. matches[2] .. " to " .. matches[3] .. " <<<" .. C_RESET)
    else
        mcp_register(mcp_version)
    end
end

-- Check a package the server sent against our supported packages.
-- If we both support it, add it to negotiated_packages and call the
-- associated initialization function.
function negotiate_can(matches)
    if matches[2] ~= auth_key then
        if mcp_settings["debug_mcp"] then
            blight.output(C_BCYAN .. ">>>> " .. C_RED .. "Invalid authorization key for package " .. matches[3] .. C_RESET)
        end
        return
    end
    package = supported_packages[matches[3]]
    if package ~= nil then
        version = supported_version(package[2], package[3], tonumber(matches[4]), tonumber(matches[5]))
        if version ~= false then
            negotiated_packages[matches[3]] = version
            supported_packages[matches[3]][1]()
            if mcp_settings["debug_mcp"] then
                blight.output(C_BCYAN .. ">>> " .. C_GREEN .. "Package " .. C_CYAN .. matches[3] .. C_GREEN .. " found. Negotiated version " .. C_RED .. version .. C_RESET)
            end
        else
            if mcp_settings["debug_mcp"] then
                blight.output(C_BCYAN .. ">>> " .. C_RED .. "Unsupported version for package " .. C_CYAN .. matches[3] .. C_RED .. ": " .. matches[4] .. " to " .. matches[5] .. C_RESET)
            end
        end
    else
        if mcp_settings["debug_mcp"] then
            blight.output(C_BCYAN .. ">>> " .. C_RED .. "Package " .. C_CYAN .. matches[3] .. C_RED .. " not found" .. C_RESET)
        end
    end
end

-- Initialize the MCP negotiate package and begin
-- telling the server what packages are supported.
function init_mcp_negotiate()
    trigger.add(negotiate_end_regex, { gag = true }, function () end) -- We don't actually care about this one.
    for package, data in pairs(supported_packages) do
        mud.send("#$#mcp-negotiate-can " .. auth_key .. " package: " .. package .. " min-version: " .. data[2] .. " max-version: " .. data[3], gag)
    end
    mud.send("#$#mcp-negotiate-end " .. auth_key, gag)
end

supported_packages["mcp-negotiate"] = {init_mcp_negotiate, 1.0, 2.0}

trigger.add(advertisement_regex, { gag = not mcp_settings["debug_mcp"] }, mcp_register_trigger)
