# Blightmud MCP

This is a collection of Lua scripts for Blightmud that implement the [MUD Client Protocol v2.1](http://www.moo.mud.org/mcp2/mcp2.html).

## Supported Packages
| Package                   | Description                                                                                           |
| --------------------------|-------------------------------------------------------------------------------------------------------|
|dns-com-vmoo-client        | Report client name and version to the MOO. Also automatically set @linelength based on terminal width.|
|dns-org-mud-moo-simpleedit | Allow editing of MOO verbs and lists in an external editor.                                           |
|dns-com-awns-status        | Write arbitrary text to the client status bar.                                                        |

In addition, for MOOs that don't support MCP, these scripts include support for the [early LambdaMOO local editing protocol](https://lisdude.com/moo/localEditing.moo).

## Installation
1. Clone this repository in the Blightmud directory: `git clone https://github.com/lisdude/blightmud_mcp.git mcp`
2. Load the script in Blightmud: `/load mcp/mcp.lua`

If you want to auto-load the script instead of typing the load command every time you connect, you can do so with a loader script in your Blightmud directory:
1. `echo 'blight:load("mcp/mcp.lua");' > mcp_loader.lua`

## Commands
Some packages add custom commands:
| Command  | Effect                                                                                                 |
| ---------|--------------------------------------------------------------------------------------------------------|
| /linelen | Set your @linelength based on your terminal width.                                                     |
| /flush   | Reset the local editor. This deletes all intermediary .moo files and stops monitoring them for changes.|

## Configuration
You can customize some settings inside the `mcp.lua` file:
| Setting                  | Effect                                                                                                                             |
| -------------------------|------------------------------------------------------------------------------------------------------------------------------------|
| simpleedit_path          | The path where editor files are created.                                                                                           |
| simpleedit_timeout       | The amount of time, in seconds, to wait after editing a file before it's considered abandoned and deleted. 0 disables the timeout. |
| edit_command             | The command executed to launch your editor.                                                                                        |
| stat_command             | Your 'stat' command. macOS users should use the Homebrew `gstat` command.                                                          |
| lambdamoo_connect_string | The string used to identify a MOO and initialize the LambdaMOO local edit protocol. (Only applies to MOOs without MCP 2.1.)        |
| debug_mcp                | Don't hide out-of-band MCP communication. Show additional debugging messages.                                                      |
