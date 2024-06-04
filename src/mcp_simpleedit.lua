-- MCP dns-org-mud-moo-simpleedit Package
-- (http://www.moo.mud.org/mcp2/simpleedit.html)
--
-- Author: lisdude <lisdude@lisdude.com>
--
local edit_begin_regex = "^#\\$#dns-org-mud-moo-simpleedit-content (\\d{20}) reference: (\"?.+\"?) name: (\"?.*\"?) type: (.+) content\\*: (\".*\") _data-tag: (.+)$"
local edit_content_regex = "^#\\$#\\* (.+) content:[ ]?(.*)$"
local edit_end_regex = "^#\\$#: (.+)$"

-- Files currently being edited. The key is the data-tag and the value is another table with:
-- {file handle, file name, last edit time, reference, name, type, content}
local currently_editing = {}
-- The time of the last edit. See monitor_changes for why this is.
local last_edit

-- Send any changes back to the MOO
function simpleedit_send(data)
    local file_path = data[2]
    local reference = data[4]
    local name = data[5]
    local data_type = data[6]
    local content = data[7]
    local data_tag = math.random(10000, 999999)
    mud.send("#$#dns-org-mud-moo-simpleedit-set " .. auth_key .. " reference: " .. reference .. " type: " .. data_type .. " content*: " .. content .. " _data-tag: " .. data_tag, gag)
    for line in io.lines(file_path) do
        mud.send("#$#* " .. data_tag .. " content: " .. line, gag)
    end
    mud.send("#$#: " .. data_tag, gag)
end

-- Monitor our currently_editing files for changes.
function monitor_changes()
    -- Check the directory itself. If it hasn't been modified, we know none of our files have either.
    -- This way we can skip constantly checking dozens of files needlessly.
    if next(currently_editing) ~= nil and last_modified(mcp_settings["simpleedit_path"]) ~= last_edit then
        for data_tag, data in pairs(currently_editing) do
            local last_modified = last_modified(data[2])
            if last_modified == nil then
                -- The file has likely been deleted. Forget about it.
                currently_editing[data_tag] = nil
            elseif data[3] ~= 0 and last_modified ~= data[3] then
                currently_editing[data_tag][3] = last_modified
                last_edit = last_modified
                simpleedit_send(data)
            end
        end
    end
end

-- Delete files that haven't been edited in <simpleedit_timeout> seconds
-- Runs every five minutes or so (unless simpleedit_timeout is less than five minutes)
function timeout_old_edits()
    local current_time = os.time(os.date('*t'))
    for data_tag, data in pairs(currently_editing) do
        local last_modified = last_modified(data[2])
        if last_modified == nil then
            currently_editing[data_tag] = nil
        elseif data[3] ~=0 and (current_time - last_modified) >= mcp_settings["simpleedit_timeout"] then
--            data[1]:close()
            os.execute("rm \"" .. data[2] .. "\"")
            if mcp_settings["debug_mcp"] then
                blight.output(C_BCYAN .. ">>> " .. C_YELLOW .. "Simpleedit deleted editor file " .. data[2] .. C_RESET)
            end
            currently_editing[data_tag] = nil
        end
    end
end

-- When all of the MCP data has been received, close the file and open the editor.
function simpleedit_end(data)
    local edit_data = currently_editing[data[2]]
    if edit_data == nil then
        if mcp_settings["debug_mcp"] then
            blight.output(C_BCYAN .. ">>> " .. C_RED .. "Simpleedit end had invalid data-tag!" .. C_RESET)
        end
        return
    end
    edit_data[1]:close()
    currently_editing[data[2]][3] = last_modified(edit_data[2])
    currently_editing[data[2]][1] = nil
    local edit_cmd = mcp_settings["edit_command"]:gsub("%%FILE", edit_data[2])
    edit_cmd = edit_cmd:gsub("%%NAME", edit_data[5])
    os.execute(edit_cmd)
end

-- As MCP data is received, write it to the file we want to edit.
function simpleedit_add_content(data)
    local edit_data = currently_editing[data[2]]
    if edit_data == nil then
        if mcp_settings["debug_mcp"] then
            blight.output(C_BCYAN .. ">>> " .. C_RED .. "Simpleedit content had invalid data-tag!" .. C_RESET)
        end
        return
    end
    edit_data[1]:write(data[3] .. "\n")
end

-- Create a file to be edited.
function simpleedit_begin(data)
    if data[2] ~= auth_key then
        if mcp_settings["debug_mcp"] then
            blight.output(C_BCYAN .. ">>> " .. C_RED .. "Simpleedit authorization key didn't match!" .. C_RESET)
        end
        return
    end
    local reference = data[3]
    local name = sanitize_name(data[4])
    local data_type = data[5]
    local content = data[6]
    local data_tag = data[7]
    path = simpleedit_filename(mcp_settings["simpleedit_path"] .. sanitize_filename(data[4]))
    local handle = io.open(path, "w")
    if handle == nil then
        blight.output(C_BCYAN .. ">>> " .. C_RED .. "Couldn't open file " .. path .. " for editing!" .. C_RESET)
    else
        currently_editing[data_tag] = {handle, path, 0, reference, name, data_type, content}
    end
end

-- Forget everything being edited and delete the temporary files.
function clear_editor()
    for data_tag, data in pairs(currently_editing) do
        if file_exists(data[2]) then
            os.execute("rm \"" .. data[2] .. "\"")
            currently_editing[data_tag] = nil
        end
    end
    currently_editing = {}
end

function flush_all_editors()
    currently_editing = {}
    delete_editor_files()
    if mcp_settings["debug_mcp"] then
        blight.output(C_BCYAN .. ">>> " .. C_YELLOW .. "Simpleedit flushed." .. C_RESET)
    end
end

-- Display a handy list of what is currently being edited.
function show_currently_editing()
    if next(currently_editing) == nil then
        blight.output("There are no active editing sessions.")
    else
        for data_tag, data in pairs(currently_editing) do
            if file_exists(data[2]) then
                blight.output(data[5]:gsub("\\", "") .. " => " .. data[2])
            end
        end
    end
end

function init_simpleedit()
    if simpleedit_trigger ~= nil then
        -- Probably a /reconnect. Forget what we know.
        clear_editor()
    else
        simpleedit_trigger = trigger.add(edit_begin_regex, { gag = not mcp_settings["debug_mcp"] }, simpleedit_begin)
        trigger.add(edit_content_regex, { gag = not mcp_settings["debug_mcp"] }, simpleedit_add_content)
        trigger.add(edit_end_regex, { gag = not mcp_settings["debug_mcp"] }, simpleedit_end)
        timer.add(1, 0, monitor_changes)
        if mcp_settings["simpleedit_timeout"] > 0 then
            timer.add(mcp_settings["simpleedit_timeout"] < 300 and mcp_settings["simpleedit_timeout"] or 300, 0, timeout_old_edits)
        end
        blight.on_quit(clear_editor)
        alias.add("^/flush$", clear_editor)
        alias.add("^/flush-all$", flush_all_editors)
        alias.add("^/editing$", show_currently_editing)
        mud.on_disconnect(clear_editor)
        if mcp_settings["debug_mcp"] then
            blight.output(C_BCYAN .. ">>> " .. C_GREEN .. "Initialized MCP simpleedit" .. C_RESET)
        end
    end
end

supported_packages["dns-org-mud-moo-simpleedit"] = {init_simpleedit, 1.0, 1.0}
