-- MCP Negotiate Package
--
-- Negotiate which packages, and their versions, are supported
-- by both the client and the server.
--
-- Author: lisdude <lisdude@lisdude.com>
--
negotiate_end_regex = "^#\\$#mcp-negotiate-end (\\d{20})$"

-- Check a package the server sent against our supported packages.
-- If we both support it, add it to negotiated_packages and call the
-- associated initialization function.
function negotiate_can(matches)
    if matches[2] ~= auth_key then
        if debug_mcp then
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
            if debug_mcp then
                blight.output(C_BCYAN .. ">>> " .. C_GREEN .. "Package " .. C_CYAN .. matches[3] .. C_GREEN .. " found. Negotiated version " .. C_RED .. version .. C_RESET)
            end
        else
            if debug_mcp then
                blight.output(C_BCYAN .. ">>> " .. C_RED .. "Unsupported version for package " .. C_CYAN .. matches[3] .. C_RED .. ": " .. matches[4] .. " to " .. matches[5] .. C_RESET)
            end
        end
    else
        if debug_mcp then
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
