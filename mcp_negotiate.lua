-- MCP Negotiate Package
--
-- Negotiate which packages, and their versions, are supported
-- by both the client and the server.
--
-- Author: lisdude <lisdude@lisdude.com>
--
negotiate_end_regex = "^#\\$#mcp-negotiate-end (.+)$"

-- Check a package the server sent against our supported packages.
-- If we both support it, add it to negotiated_packages and call the
-- associated initialization function.
function negotiate_can(matches)
    if matches[2] ~= auth_key then
        if debug_mcp then
            blight.output(">>>> Invalid authorization key for package " .. matches[3])
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
                blight.output(">>> Package " .. matches[3] .. " found. Negotiated version " .. version)
            end
        else
            if debug_mcp then
                blight.output(">>> Unsupported version for package " .. matches[3] .. ": " .. matches[4] .. " to " .. matches[5])
            end
        end
    else
        if debug_mcp then
            blight.output(">>> Package " .. matches[3] .. " not found")
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
