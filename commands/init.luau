local types = require("@commands/types")
local utsCli = require("@utilities/cli")

export type Command = types.Command

-- listed in the order they appear in clupl --help
local commands: { Command } = {
	require("@commands/install"),
	require("@commands/update"),
	require("@commands/package"),
	-- a shorter way to type clupl package list
	utsCli.alias(require("@commands/package/list"), "packages"),
	require("@commands/remove"),
	require("@commands/config"),
}

return commands
