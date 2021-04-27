# Blightmud MCP

This is a plugin for [Blightmud](https://github.com/Blightmud/Blightmud.git) that implements the [MUD Client Protocol v2.1](http://www.moo.mud.org/mcp2/mcp2.html).

## Supported Packages
| Package                   | Description                                                                                           |
| --------------------------|-------------------------------------------------------------------------------------------------------|
|dns-com-vmoo-client        | Report client name and version to the MOO. Also sets @linelength based on terminal width.             |
|dns-org-mud-moo-simpleedit | Allow editing of MOO verbs and lists in an external editor.                                           |
|dns-com-awns-status        | Write arbitrary text to the client status bar.                                                        |

In addition, for MOOs that don't support MCP, these scripts include support for the [early LambdaMOO local editing protocol](https://lisdude.com/moo/localEditing.moo).

## Installation
Within Blightmud:
1. `/add_plugin https://github.com/lisdude/blightmud_mcp`
2. `/enable_plugin blightmud_mcp`

**NOTE**: macOS users will need to change the `stat_command` option in main.lua. See [Configuration](#configuration) below.

## Commands
| Command  | Effect                                                                                                                                                                     |
| ---------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| /mcp [setting] [value] | View or change plugin options. See [Configuration](#configuration) below.                                                                                    |
| /linelen               | Set your @linelength based on your terminal width. (dns-com-vmoo-client)                                                                                     |
| /flush                 | Reset the local editor. This deletes all intermediary .moo files and stops monitoring them for changes. (dns-org-mud-moo-simpleedit or LambdaMOO local edit) |
| /flush-all             | Delete all intermediary .moo files, including those belonging to other Blightmud instances. |
| / editing              | Display a list of files currently open for editing. |

## Configuration
While not necessary to get going (unless you use macOS...), you can customize some settings using the `/mcp` command. When supplied with no arguments, it will print your current settings. When provided with a single argument (e.g. `/mcp simpleedit_timeout`) it will print the current value of that setting. When provided when two arguments, it will change the setting (e.g. `/mcp simpleedit_timeout 0`).

| Setting                  | Effect                                                                                                                             |
| -------------------------|------------------------------------------------------------------------------------------------------------------------------------|
| simpleedit_path          | The path where editor files are created.                                                                                           |
| simpleedit_timeout       | The amount of time, in seconds, to wait after editing a file before it's considered abandoned and deleted. 0 disables the timeout. |
| edit_command             | The command executed to launch your editor.                                                                                        |
| stat_command             | Your 'stat' command. macOS users should use the Homebrew `gstat` command.                                                          |
| lambdamoo_connect_string | The string used to identify a MOO and initialize the LambdaMOO local edit protocol. (Only applies to MOOs without MCP 2.1.)        |
| debug_mcp                | Don't hide out-of-band MCP communication. Show additional debugging messages.                                                      |

**Note**: Some setting require reloading the plugin before they take effect.

### Edit Command Substitions
The `edit_command` variable accepts these substitutions:
| String | Substitution                                 |
|--------|----------------------------------------------|
| %NAME  | The name of the verb or list being edited.   |
| %FILE  | The path to the file being edited.           |

For example, if you're using tmux and want to open an editor in a new tmux window, you could do something like:

```bash
edit_command = "tmux new-window -n %NAME vim -c \"set syntax=moo\" %FILE"
```
