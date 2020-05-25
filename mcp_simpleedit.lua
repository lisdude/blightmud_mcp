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
local edit_begin_regex = "^#\\$#dns-org-mud-moo-simpleedit-content (.+) reference: (\".+\") name: (\".*\") type: (.+) content\\*: (\".*\") _data-tag: (.+)$";
local edit_content_regex = "^#\\$#\\* (.+) content: (.*)$";
local edit_end_regex = "^#\\$#: (.+)$";
local base_path = "mcp/simpleedit/";

-- Files currently being edited. The key is the data-tag and the value is another table with:
-- {file handle, file name, last edit time, reference, name, type, content}
local currently_editing = {};

-- Send any changes back to the MOO
function simpleedit_send(data)
    local file_path = data[2]
    local reference = data[4];
    local name = data[5];
    local data_type = data[6];
    local content = data[7];
    local data_tag = math.random(10000, 999999);
    blight:send("#$#dns-org-mud-moo-simpleedit-set " .. auth_key .. " reference: " .. reference .. " type: " .. data_type .. " content*: " .. content .. " _data-tag: " .. data_tag);
    for line in io.lines(file_path) do
        blight:send("#$#* " .. data_tag .. " content: " .. line);
    end
    blight:send("#$#: " .. data_tag);
end

-- Monitor our currently_editing files for changes.
function monitor_changes()
    for data_tag, data in pairs(currently_editing) do
        local last_modified = last_modified(data[2]);
        if last_modified == nil then
            -- The file has likely been deleted. Forget about it.
            currently_editing[data_tag] = nil;
        elseif data[3] ~= 0 and last_modified ~= data[3] then
            currently_editing[data_tag][3] = last_modified;
            simpleedit_send(data);
        end
    end
end

-- When all of the MCP data has been received, close the file and open Vim!
function simpleedit_end(data)
    local edit_data = currently_editing[data[2]];
    if edit_data == nil then
        if debug_mcp then
            blight:output(">>> Simpleedit end had invalid data-tag");
        end
        return;
    end
    edit_data[1]:close();
    currently_editing[data[2]][3] = last_modified(edit_data[2]);
    currently_editing[data[2]][1] = nil;
    os.execute("tmux new-window -n " .. edit_data[5] .. " nvim -c \"set syntax=moo\" " .. edit_data[2]);
end

-- As MCP data is received, write it to the file we want to edit.
function simpleedit_add_content(data)
    local edit_data = currently_editing[data[2]];
    if edit_data == nil then
        if debug_mcp then
            blight:output(">>> Simpleedit content had invalid data-tag");
        end
        return;
    end
    edit_data[1]:write(data[3] .. "\n");
end

-- Create a file to be edited.
-- TODO: Use the name provided by MCP. But we have to sanitize it to become a file name.
function simpleedit_begin(data)
    if data[2] ~= auth_key then
        if debug_mcp then
            blight:output(">>> Simpleedit authorization key didn't match");
        end
        return;
    end
    local reference = data[3];
    local name = data[4];
    local data_type = data[5];
    local content = data[6];
    local data_tag = data[7];
    file_name = tostring(math.random(0, 9223372036854775807)) .. ".moo";
    while file_exists(file_name) do
        -- This seems extraordinarily unlikely!
        file_name = tostring(math.random(0, 9223372036854775807)) .. ".moo";
    end
    local path = base_path .. file_name;
    local handle = io.open(path, "w");
    if handle == nil then
        blight:output("Couldn't open file " .. path .. " for editing!");
    else
        currently_editing[data_tag] = {handle, path, 0, reference, name, data_type, content};
    end
end

function init_simpleedit()
    os.execute("rm -f " .. base_path .. "*.moo");
    blight:add_trigger(edit_begin_regex, { gag = not debug_mcp }, simpleedit_begin);
    blight:add_trigger(edit_content_regex, { gag = not debug_mcp }, simpleedit_add_content);
    blight:add_trigger(edit_end_regex, { gag = not debug_mcp }, simpleedit_end);
    blight:add_timer(1, 0, monitor_changes);
end

supported_packages["dns-org-mud-moo-simpleedit"] = {init_simpleedit, 1.0, 1.0};
