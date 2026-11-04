local process = require("@std/process")

local commands = require("@commands")
local manifest = require("./manifest")
local buildinfo = require("@utilities/buildinfo")
local utsCli = require("@utilities/cli")
local uts = require("@utilities")
local path = require("@std/path")

local LUTE = path.format(process.execPath())

--[[
buildscript.luau injects some information into "buildinfo"
one of them is the format clupl is in.
For example, a .deb file is marked as "deb"

Every single format besides appimage uses a bundled lute runtime.
Appimage is literally just a bundle of the source code.
It relies on whatever lute the user themselves has installed.
Therefore, buildinfo.lute is not filled out for an appimage.

Instead, the version of lute is gotten directly from lute itself.
]]
local runtime = if buildinfo.lute then buildinfo.lute else uts.run({ LUTE, "--version" })

-- shown at the top of clupl --help
local description = `{manifest.name} {manifest.version} ({buildinfo.format})\nLute runtime v{runtime}`

--[[
table.unpack(..., 2) skips [1] in the process.args table
args[1] is just the path of the script (read more about it in scripts/setup.luau)
this isn't needed for any of clupl's commands and is therefore skipped.
]]
utsCli.dispatch(commands, { table.unpack(process.args, 2) }, "clupl", description)
