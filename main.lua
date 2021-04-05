--
-- MUD Client Protocol 2.1
-- (http://www.moo.mud.org/mcp2/mcp2.html)
--
-- Author: lisdude <lisdude@lisdude.com>
--
mcp_plugin_path = string.sub(package.path, 1, string.find(package.path, "?")-1)

--- Requirements
require("src/settings")             -- settings
require("src/mcp_utils")            -- useful utility functions
require("src/mcp_negotiate")        -- mcp-negotiate package
require("src/mcp_client")           -- dns-com-vmoo-client package
require("src/mcp_simpleedit")       -- dns-org-mud-moo-simpleedit package
require("src/lambdamoo_simpleedit") -- early LambdaMOO simpleedit support
require("src/mcp_status")           -- dns-com-awns-status package

