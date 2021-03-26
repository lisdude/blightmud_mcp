if debug_mcp then
    gag = {}
else
    gag = {gag=true, skip_log=true}  -- Default mud.send options.
end

-- Seed the random number generator. Lua seems to be weird about this,
-- so also generate a few random numbers to kick it into gear.
function seed_rng()
    if not rng_seeded then
        math.randomseed(os.clock() ^ 5)
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
    local f = io.popen(stat_command .. " -c %Y " .. file)
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

-- Return a random file name
function random_filename(base_path)
    file_name = base_path .. tostring(math.random(0, 9223372036854775807)) .. ".moo"
    while file_exists(file_name) do
        -- This seems extraordinarily unlikely!
        file_name = base_path .. tostring(math.random(0, 9223372036854775807)) .. ".moo"
    end
    return file_name
end

-- Delete all of the *.moo files in the simpleedit path.
function delete_editor_files()
    os.execute("rm -f " .. simpleedit_path .. "*.moo")
end

delete_editor_files()
