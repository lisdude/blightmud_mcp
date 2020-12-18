-- MCP dns-org-mud-moo-simpleedit Package
-- (http://www.moo.mud.org/mcp2/simpleedit.html)
--
-- This package makes several assumptions that may not be true for you:
-- 1. You're using Blightmud inside of tmux.
-- 2. You edit your text files in Vim.
--
-- If these are not true for you, this code may require some modification.
--
-- Author: lisdude <lisdude@lisdude.com>
--
local edit_begin_regex = "^#\\$#dns-org-mud-moo-simpleedit-content (.+) reference: (\".+\") name: (\".*\") type: (.+) content\\*: (\".*\") _data-tag: (.+)$"
local edit_content_regex = "^#\\$#\\* (.+) content: (.*)$"
local edit_end_regex = "^#\\$#: (.+)$"

-- Files currently being edited. The key is the data-tag and the value is another table with:
-- {file handle, file name, last edit time, reference, name, type, content}
local currently_editing = {}

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
    for data_tag, data in pairs(currently_editing) do
        local last_modified = last_modified(data[2])
        if last_modified == nil then
            -- The file has likely been deleted. Forget about it.
            currently_editing[data_tag] = nil
        elseif data[3] ~= 0 and last_modified ~= data[3] then
            currently_editing[data_tag][3] = last_modified
            simpleedit_send(data)
        end
    end
end

-- When all of the MCP data has been received, close the file and open the editor.
function simpleedit_end(data)
    local edit_data = currently_editing[data[2]]
    if edit_data == nil then
        if debug_mcp then
            blight:output(">>> Simpleedit end had invalid data-tag")
        end
        return
    end
    edit_data[1]:close()
    currently_editing[data[2]][3] = last_modified(edit_data[2])
    currently_editing[data[2]][1] = nil
    os.execute(edit_command .." " .. edit_data[2])
end

-- As MCP data is received, write it to the file we want to edit.
function simpleedit_add_content(data)
    local edit_data = currently_editing[data[2]]
    if edit_data == nil then
        if debug_mcp then
            blight:output(">>> Simpleedit content had invalid data-tag")
        end
        return
    end
    edit_data[1]:write(data[3] .. "\n")
end

-- Create a file to be edited.
function simpleedit_begin(data)
    if data[2] ~= auth_key then
        if debug_mcp then
            blight:output(">>> Simpleedit authorization key didn't match")
        end
        return
    end
    local reference = data[3]
    local name = sanitize_name(data[4])
    local data_type = data[5]
    local content = data[6]
    local data_tag = data[7]
    path = random_filename(simpleedit_path)
    local handle = io.open(path, "w")
    if handle == nil then
        blight:output(">>> Couldn't open file " .. path .. " for editing!")
    else
        currently_editing[data_tag] = {handle, path, 0, reference, name, data_type, content}
    end
end

function init_simpleedit()
    if simpleedit_trigger ~= nil then
        -- Probably a /reconnect. Forget what we know.
        currently_editing = {}
    else
        simpleedit_trigger = trigger.add(edit_begin_regex, { gag = not debug_mcp }, simpleedit_begin)
        trigger.add(edit_content_regex, { gag = not debug_mcp }, simpleedit_add_content)
        trigger.add(edit_end_regex, { gag = not debug_mcp }, simpleedit_end)
        timer.add(1, 0, monitor_changes)
        if debug_mcp then
            blight:output(">>> Initialized MCP simpleedit")
        end
    end
end

supported_packages["dns-org-mud-moo-simpleedit"] = {init_simpleedit, 1.0, 1.0}
