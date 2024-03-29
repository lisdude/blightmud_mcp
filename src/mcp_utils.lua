if mcp_settings["debug_mcp"] then
    gag = {}
else
    gag = {gag=true, skip_log=true}  -- Default mud.send options.
end

-- Seed the random number generator. Lua seems to be weird about this,
-- so also generate a few random numbers to kick it into gear.
function seed_rng()
    if not rng_seeded then
        math.randomseed(os.time())
        for i = 1, 10 do
            math.random(10000, 65000)
        end
        rng_seeded = true
    end
end

-- Find the highest version in common between two sets of versions.
function supported_version(client_min, client_max, server_min, server_max)
    if client_max >= server_min and server_max >= client_min then
        return math.min(server_max, client_max)
    else
        return false
    end
end

-- Generate an MCP authentication key. As it's designed to prevent spoofing,
-- and not for security, this key is 20 random digits.
function generate_auth_key()
   	local result = ""
	for x = 1, 20 do
		result = result .. math.random(0, 9)
	end
	return result
end

-- Check if a file exists (there isn't a native way?)
function file_exists(name)
   local f = io.open(name, "r")
   return f ~= nil and io.close(f)
end

-- Return a file's last modification time
function last_modified(file)
    local f = io.popen(mcp_settings["stat_command"] .. " -c %Y \"" .. file .. "\"")
    local last_mod = f:read()
    f:close()
    if last_mod == nil then
        blight.output(C_BCYAN .. ">>> " .. C_RED .. "Couldn't get last modified date for " .. file .. C_RESET)
        return nil
    else
        return tonumber(last_mod)
    end
end

-- Sanitize name by escaping non-alphanumeric characters. This is necessary
-- because we pass it to tmux new-window and special characters could make
-- a messy and/or dangerous os.execute...
function sanitize_name(name)
    return name:gsub("%W", "\\%1")
end

-- Remove special characters from file names.
function sanitize_filename(name)
    name = name:gsub("/", "-")
    name = name:gsub('"', "")

--    if package.config:sub(1,1) == "\\" then
--        -- Windows is a little more picky about what characters it allows.
--        -- We should probably also get rid of CON, PRN, AUX, NUL, COM1-9, etc. If I ever test this on Windows.
--        name = name:gsub("[\\%?%%%*|\"<>]", "")
--        name = name:gsub(":", " - ")
--    end

    return name
end

-- Return a random file name
function simpleedit_filename(base_path)
    file_name = base_path .. ".moo"
    while file_exists(file_name) do
        file_name = base_path .. tostring(math.random(0, 9223372036854775807)) .. ".moo"
    end
    return file_name
end

-- Print tables for debugging
function print_table(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. print_table(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

-- Delete all of the *.moo files in the simpleedit path.
function delete_editor_files()
    os.execute("rm -f \"" .. mcp_settings["simpleedit_path"] .. "\"*.moo")
end
