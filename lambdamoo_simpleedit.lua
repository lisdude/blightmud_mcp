-- Support for LambdaMOO-style local editing
-- (http://cmc.uib.no/moo/objects/LocalEditing.moo)
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
        os.execute(edit_command .. " " .. path)
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
    path = random_filename(simpleedit_path)
    local handle = io.open(path, "w")
    if handle == nil then
        blight.output(">>> Couldn't open file " .. path .. " for editing!")
    else
        currently_editing[path] = {0, name, command}
    end
    local editing_trigger = trigger.add(".+", { gag = not debug_mcp }, lambdamoo_simpleedit_capture)
    current_capture = {editing_trigger, path, handle, nil}
end

function init_lambdamoo_simpleedit()
    if not auth_key and lambdamoo_trigger == nil then
        lambdamoo_trigger = trigger.add(begin_regex, { gag = not debug_mcp }, lambdamoo_simpleedit_begin)
        timer.add(1, 0, lambdamoo_monitor_changes)
        if debug_mcp then
            blight.output(">>> Initialized LambdaMOO local edit protocol")
        end
    end
end

trigger.add(lambdamoo_connect_string, { gag = not debug_mcp }, init_lambdamoo_simpleedit)
