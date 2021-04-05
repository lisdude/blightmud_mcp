-- Support for LambdaMOO-style local editing
-- (https://lisdude.com/moo/LocalEditing.moo)
--
-- Author: lisdude <lisdude@lisdude.com>
--
local begin_regex = "^#\\$# edit name: (.*) upload: (.+)$"

-- Files currently being edited. The key is the file path and the value is a table of:
-- {last edit time, name, upload command}
local currently_editing = {}
-- The file currently being captured. Value is: {editing_trigger, file name, file handle, got MCP trigger}
local current_capture = {}

-- Send changes back to the MOO with the upload command
function lambdamoo_send(path, data)
    mud.send(data[3])
    for line in io.lines(path) do
        mud.send(line, gag)
    end
    mud.send(".", gag)
end

-- Monitor the currently_editing files for changes.
function lambdamoo_monitor_changes()
    for path, data in pairs(currently_editing) do
        local last_modified = last_modified(path)
        if last_modified == nil then
            -- Forget the deleted file.
            currently_editing[path] = nil
        elseif data[1] ~= 0 and last_modified ~= data[1] then
            currently_editing[path][1] = last_modified
            lambdamoo_send(path, data)
        end
    end
end

-- Delete files that haven't been edited in <simpleedit_timeout> seconds
-- Runs every five minutes or so (unless simpleedit_timeout is less than five minutes)
function lambdamoo_timeout_old_edits()
    local current_time = os.time(os.date('*t'))
    for path, data in pairs(currently_editing) do
        local last_modified = last_modified(path)
        if last_modified == nil then
            currently_editing[path] = nil
        elseif data[1] ~=0 and (current_time - last_modified) >= simpleedit_timeout then
--            data[1]:close()
            os.execute("rm \"" .. path .. "\"")
            if debug_mcp then
                blight.output(C_BCYAN .. ">>> " .. C_YELLOW .. "LambdaMOO edit deleted editor file " .. path .. C_RESET)
            end
            currently_editing[path] = nil
        end
    end
end

-- Write data to the file as it's received. If the data is a single period on a line,
-- we close the file and launch our editor.
function lambdamoo_simpleedit_capture(data)
    if current_capture[4] == nil then
        -- This is kind of a kludge. Our capture all trigger also seems to capture the initial
        -- "MCP" string, so we need to ignore it. Instead of matching the string again (who knows,
        -- it might exist in some invalid verb code and really donk things up), we use this flag.
        current_capture[4] = 1
        return
    elseif data[1] == "." then
        -- End of the capture.
        local path = current_capture[2]
        current_capture[3]:close()
        trigger.remove(current_capture[1].id)
        currently_editing[path][1] = last_modified(path)
        local edit_data = currently_editing[path]
        local edit_cmd = edit_command:gsub("%%FILE", path)
        edit_cmd = edit_cmd:gsub("%%NAME", edit_data[2])
        os.execute(edit_cmd)
        current_capture = {}
    else
        if data[1].sub(1, 2) == ".." then
            -- The spec says that a line beginning with double periods
            -- is 'dot quoted' and should remove the first period.
            data[1] = data[1].sub(2, -1)
        end
        current_capture[3]:write(data[1] .. "\n")
    end
end

function lambdamoo_simpleedit_begin(data)
    local name = sanitize_name("\"" .. data[2] .. "\"")
    local command = data[3]
    path = simpleedit_filename(simpleedit_path .. sanitize_filename(data[2]))
    local handle = io.open(path, "w")
    if handle == nil then
        blight.output(C_BCYAN .. ">>> " .. B_RED .. "Couldn't open file " .. path .. " for editing!" .. C_RESET)
    else
        currently_editing[path] = {0, name, command}
    end
    local editing_trigger = trigger.add(".+", { gag = not debug_mcp }, lambdamoo_simpleedit_capture)
    current_capture = {editing_trigger, path, handle, nil}
end

-- Forget everything being edited and delete the temporary files.
function lambdamoo_clear_editor()
    currently_editing = {}
    delete_editor_files()
    if debug_mcp then
        blight.output(C_BCYAN .. ">>> " .. C_YELLOW .. "LambdaMOO local edit flushed." .. C_RESET)
    end
end

function init_lambdamoo_simpleedit()
    if not auth_key and lambdamoo_trigger == nil then
        lambdamoo_trigger = trigger.add(begin_regex, { gag = not debug_mcp }, lambdamoo_simpleedit_begin)
        timer.add(1, 0, lambdamoo_monitor_changes)
        if simpleedit_timeout > 0 then
            timer.add(simpleedit_timeout < 300 and simpleedit_timeout or 300, 0, lambdamoo_timeout_old_edits)
        end
        alias.add("^/flush$", lambdamoo_clear_editor)
        if debug_mcp then
            blight.output(C_BCYAN .. ">>> " .. C_GREEN .. "Initialized LambdaMOO local edit protocol" .. C_RESET)
        end
    end
end

trigger.add(lambdamoo_connect_string, { gag = not debug_mcp }, init_lambdamoo_simpleedit)
