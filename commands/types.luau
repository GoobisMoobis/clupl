--[[
these are kept separate from init.luau so command modules can use the types too
otherwise there would be a circular require and the program wouldn't run
]]

local cli = require("@batteries/cli")

-- a subcommand, e.g. the install in clupl install
export type Command = {
	-- matched against the first CLI argument
	name: string,
	-- one line, shown in both clupl --help and clupl <name> --help
	description: string,
	-- registers the command's arguments on the parser
	setup: ((parser: cli.Parser) -> ())?,
	-- optional hook to rewrite the raw args in place before they are parsed,
	-- for syntax batteries can't handle on its own. --flag=value is already split by then
	prepare: ((args: { string }) -> ())?,
	-- runs after parsing succeeds, so required arguments are guaranteed to be set
	run: ((parser: cli.Parser) -> ())?,
	-- commands of its own, e.g. the list in clupl package list. a command with
	-- subcommands leaves out setup, prepare and run, since the subcommand does the work
	subcommands: { Command }?,
}

-- type-only module
return {}
