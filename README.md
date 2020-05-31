# Blightmud MCP

This is a collection of Lua scripts for Blightmud that implement the [MUD Client Protocol v2.1](http://www.moo.mud.org/mcp2/mcp2.html).

It includes the following MCP packages:
- dns-com-vmoo-client (Report client name and version. INCOMPLETE: Does not include linelength setting yet.)
- dns-org-mud-moo-simpleedit (Allow editing of MOO verbs and lists in an external editor.)

In addition, for MOOs that don't support MCP, these scripts include support for the early LambdaMOO local editing protocol.

## Installation
1. Clone this repository in the Blightmud directory: `git clone https://github.com/lisdude/blightmud_mcp.git mcp`
2. Load the script in Blightmud: `/load mcp/mcp.lua`

If you want to auto-load the script instead of typing the load command every time you connect, you can do so with a loader script in your Blightmud directory:
1. `echo 'blight:load("mcp/mcp.lua");' > mcp_loader.lua`

## Configuration
You can customize some settings inside the `mcp.lua` file:
| Setting          | Effect                                                                        |
| -----------------|-------------------------------------------------------------------------------|
| simpleedit_path  | The path where editor files are created.                                      |
| edit_command     | The command executed to launch your editor.                                   |
| stat_command     | Your 'stat' command. macOS users should use the Homebrew `gstat` command.     |
| debug_mcp        | Don't hide out-of-band MCP communication. Show additional debugging messages. |
