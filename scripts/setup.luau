--[[
Meant to be the first file and hopefully only file that is ran if you are a new contributor.
Write's lute's type definitions into a .lute folder so that luau typechecking in
editors such as vscodium recognize lute as valid code and things like @std as valid libraries

running clupl itself doesn't need any of this, only the editor and lute check do
]]

local fs = require("@std/fs")
local path = require("@std/path")
local process = require("@std/process")

local files = require("@utilities/files")
local uts = require("@utilities")

--[[
The first argument passed into the script will always be the script itself.
"well yeah, duh!" well, this actually raises one edge case that needs to be taken into account.

For the purposes of this explanation, consider the root of this repository (containing main.luau)
as the home dir (~)
running `lute scripts/setup.luau` from ~ will fill args[1] with "scripts/setup.luau"
running `lute setup.luau` from ~/scripts will fill args[1] with "setup.luau" instead

The issue with this is that files.parent takes in a STRING and returns a STRING.
It cannot assume that any given string correlates to any specific file.
Therefore, if given just the string "setup.luau" it cannot correctly guess the parent folder.
When given "scripts/setup.luau" it CAN figure this out, because it is explicitly being
told that setup is a child of scripts/ and therefore can infer the parent of setup.luau.

However note that the case of args[1] being simply "setup.luau" only happens
when the script is being invoked from the same directory it is contained in.
Therefore, if files.parent fails because it is just passed "setup.luau" it is
safe to assume the current directory is the parent of the script.
]]
local scriptFolder = files.parent(process.args[1]) or "."

local repository = scriptFolder .. "/.."
local mirror = repository .. "/.lute"

-- the same lute that is currently running the script
local lute = path.format(process.execPath())

-- If you haven't already, read over the custom utilities module!
local output = uts.run({ lute, "setup" })

-- lute prints "Writing definitions at ~/.lute/typedefs/1.0.0"
local folder = string.match(output, "Writing definitions at ([^\n]+)")
if folder == nil then
	uts.fail(`couldn't tell where lute setup wrote the type definitions. It printed:\n{output}`)
	return
end
folder = files.expandHome((string.gsub(folder, "%s+$", "")))

-- ~/.lute/typedefs/version, two folders up is ~/.lute
local luteHome = files.parent(files.parent(folder) or "") or ""

files.remove(mirror)
files.makeFolder(mirror .. "/typedefs")
fs.symbolicLink(folder, mirror .. "/typedefs/current")
fs.symbolicLink(luteHome .. "/batteries", mirror .. "/batteries")
print(`.lute/typedefs/current now points at {files.shortPath(folder)}`)
