--[[
one of the more simple commands.
Changes the config file that clupl uses to determine how to run.
Relies heavily on the clupl library from utilities
]]

local cli = require("@batteries/cli")
local richterm = require("@batteries/richterm")

local types = require("@commands/types")
local uts = require("@utilities")
local clupl = require("@utilities/clupl")
local github = require("@utilities/platforms/github")

local function findSetting(key: string): clupl.Setting?
	for _, setting in clupl.settings do
		if setting.key == key then
			return setting
		end
	end
	return nil
end

local command: types.Command = {
	name = "config",
	description = "Show or change clupl's settings",
	setup = function(parser: cli.Parser)
		parser:add("key", "positional", { help = "setting to show or change, leave out to list them all" })
		parser:add("value", "positional", { help = "new value for the setting" })
	end,
	run = function(parser: cli.Parser)
		local key, value = parser:get("key"), parser:get("value")
		local config = clupl.loadConfig() :: any

		-- if no key was provided, just list the config
		if not key then
			for _, setting in clupl.settings do
				print(`{richterm.bold(setting.key)} = {richterm.cyan(config[setting.key])}`)
				print(`  {setting.help}`)
				print(`  values: {table.concat(setting.values, ", ")} (default {setting.default})`)
			end
			print()
			print(richterm.dim(`stored in {clupl.configPath()}`))
			return
		end

		-- when a key WAS provided.

		local setting = findSetting(key)
		if not setting then
			local keys = {}
			for _, s in clupl.settings do
				table.insert(keys, s.key)
			end
			uts.fail(`unknown setting '{key}' (settings: {table.concat(keys, ", ")})`)
			return
		end

		-- if the key is just being queried and doesn't have a value to set
		if not value then
			print(config[key])
			return
		end

		if not table.find(setting.values, value) then
			uts.fail(`'{key}' must be one of {table.concat(setting.values, ", ")}`)
		end

		if key == "github" and value == "gh" and not github.ghAvailable() then
			if not uts.hasProgram("gh") then
				uts.fail("gh isn't installed. Install GitHub's CLI, run 'gh auth login', then try again")
			end
			uts.fail("gh isn't logged in. Run 'gh auth login', then try again")
		end

		config[key] = value
		clupl.saveConfig(config)
		print(`{key} = {value}`)
	end,
}

return command
