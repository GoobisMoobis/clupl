--[[
these are kept separate from init.luau so command modules can use the types too
otherwise there would be a circular require and the program wouldn't run
]]

local cli = require("@batteries/cli")

export type Command = {
	name: string,
	-- A one line description used when clupl requests more information about the command
	description: string,
	-- registers the command's arguments on the parser
	setup: ((parser: cli.Parser) -> ())?,
	--[[
	hook to rewrite raw args before they are parsed,
	for syntax that batteries' cli module can't handle on its own.
	Note that the --flag=value syntax has already been split by this point.
	]]
	prepare: ((args: { string }) -> ())?,
	-- runs after parsing succeeds
	run: ((parser: cli.Parser) -> ())?,
	--[[
	commands of its own!
	command with subcommands leave out setup,
	prepare and run, since the subcommand does the work
	]]
	subcommands: { Command }?,
}

-- type-only module
return {}
