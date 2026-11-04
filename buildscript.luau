--[[
builds clupl for release.
appimage - a .AppImage that requires lute on the system to run
deb - Debian/Ubuntu systems
arch - a zstandard package for pacman to use on an arch based system
rpm - Fedora/openSUSE systems
binary - works anywhere

Once built the files get placed in the build folder, including things like a checksum file

Relies on the files in the packaging folder, and uses custom-defined {{word}} variables so
that all the metadata can be defined in manifest.luau without needing to change like 5
files each time I make a new release.

Note: this script does not run without these utilities:
appimage - appimagetool
deb - dpkg-deb
rpm - rpmbuild
arch- makepkg

binary needs Lute... but I really hope you already have that if you are editing this file
]]

local richterm = require("@batteries/richterm")
local fs = require("@std/fs")
local path = require("@std/path")
local process = require("@std/process")
local syntax = require("@std/syntax")
local parser = require("@std/syntax/parser")
local query = require("@std/syntax/query")

local manifest = require("./manifest")
local uts = require("@utilities")
local checksums = require("@utilities/checksums")
local files = require("@utilities/files")
local releases = require("@utilities/releases")

local ROOT = path.format(path.resolve(files.parent(process.args[1]) or "."))
local BUILD = ROOT .. "/build"
local STAGE = BUILD .. "/stage"
local PACKAGING = ROOT .. "/packaging"

-- the files and folders clupl is made from
local SOURCE = { "main.luau", "manifest.luau", ".luaurc", "commands", "utilities", "vendor" }

-- the tool each format needs
-- more on this in CONTRIBUTING.md
local TOOLS: { [string]: string } = {
	appimage = "appimagetool",
	deb = "dpkg-deb",
	rpm = "rpmbuild",
	arch = "makepkg",
}

local VERSION = manifest.version
local ARCH = releases.arch()

-- the lute executable that is running buildscript.luau
local LUTE = path.format(process.execPath())

local function step(message: string)
	print(richterm.bold(richterm.blue("==> ")) .. message)
end

--[[
replaces {{word}} placeholders with actual values
]]
local function fillTemplate(templatePath: string, values: { [string]: string }): string
	local text = fs.readFileToString(templatePath)
	local filled = string.gsub(text, "{{(%w+)}}", function(word: string): string
		local value = values[word]
		if value == nil then
			error(templatePath .. " uses {{" .. word .. "}}, which buildscript.luau doesn't fill in", 0)
		end
		return value
	end)
	return filled
end

-- the values every packaging file can use
local function templateValues(): { [string]: string }
	return {
		name = manifest.name,
		version = VERSION,
		summary = manifest.summary,
		description = manifest.description,
		license = manifest.license,
		owner = manifest.owner,
		homepage = `https://github.com/{manifest.owner}/{manifest.repository}`,
		arch = ARCH,
		debianArch = releases.debianArch(ARCH),
	}
end

-- "a b c" -> "'a' 'b' 'c'", mainly for Arch's PKGBUILD file
local function quotedList(items: { string }): string
	local quoted = {}
	for _, item in items do
		table.insert(quoted, `'{item}'`)
	end
	return table.concat(quoted, " ")
end

-- "  text  " -> "  text"
local function trimEnd(text: string): string
	local trimmed = string.gsub(text, "%s+$", "")
	return trimmed
end

local function addComments(token: syntax.CstToken, comments: { syntax.Trivia }, seen: { [string]: boolean })
	for _, trivia in { token.leadingTrivia, token.trailingTrivia } do
		for _, item in trivia do
			local place = `{item.location.beginLine}:{item.location.beginColumn}`
			-- keeps things like --!strict
			local isDirective = string.sub(item.text, 1, 3) == "--!"

			if item.tag ~= "whitespace" and not isDirective and not seen[place] then
				seen[place] = true
				table.insert(comments, item)
			end
		end
	end
end

--[[
Uses the above function to go through and trim comments from
ever source file for the appimage version of CLUPL
]]
local function stripComments(source: string): string
	local result = parser.parse(source)
	local tokens = query.findAllFromRoot(result.root, function(node: syntax.CstNode): syntax.CstToken?
		return if node.kind == "token" then node else nil
	end)

	local comments: { syntax.Trivia } = {}
	local seen = {}
	for _, token in tokens.nodes do
		addComments(token, comments, seen)
	end
	-- comments at the very end of a file belong to the end-of-file token
	addComments(result.eof, comments, seen)

	table.sort(comments, function(a: syntax.Trivia, b: syntax.Trivia): boolean
		if a.location.beginLine ~= b.location.beginLine then
			return a.location.beginLine > b.location.beginLine
		end
		return a.location.beginColumn > b.location.beginColumn
	end)

	local lines = string.split(source, "\n")
	for _, comment in comments do
		local span = comment.location
		local before = string.sub(lines[span.beginLine], 1, span.beginColumn - 1)
		local after = string.sub(lines[span.endLine], span.endColumn)

		if span.beginLine == span.endLine and trimEnd(after) ~= "" then
			lines[span.beginLine] = before .. " " .. after
		elseif span.beginLine == span.endLine then
			lines[span.beginLine] = trimEnd(before)
		else
			lines[span.beginLine] = trimEnd(before)
			for line = span.beginLine + 1, span.endLine - 1 do
				lines[line] = ""
			end
			lines[span.endLine] = if trimEnd(after) == "" then "" else after
		end
	end

	return table.concat(lines, "\n")
end

local function stripFolder(folder: string)
	files.walk(folder, function(relative: string, kind: string): boolean
		if kind == "file" and string.sub(relative, -5) == ".luau" then
			local filePath = folder .. "/" .. relative
			files.write(filePath, stripComments(fs.readFileToString(filePath)))
		end
		return true
	end)
end

--[[
copies source into a target destination, marked as built for format (see utilities/buildinfo.luau).
]]
local function copySource(destination: string, format: string)
	files.makeFolder(destination)
	for _, item in SOURCE do
		files.copy(ROOT .. "/" .. item, destination .. "/")
	end
	stripFolder(destination)

	local runtimeVersion = uts.run({ LUTE, "--version" })
	local formattedRuntimeVersion = `\tlute = "{runtimeVersion}",\n`

	files.write(
		destination .. "/utilities/buildinfo.luau",
		`return \{\n\tformat = "{format}",{if format ~= "appimage" then formattedRuntimeVersion else ""}\n}\n`
	)
end

--[[
Read about this in CONTRIBUTING.md
essentially, this prevents CLUPL from being built with
any Lute version below a prerelease of 1.0.1
]]
local function checkRunsByName(program: string)
	local emptyFolder = STAGE .. "/empty"
	files.makeFolder(emptyFolder)

	local script = 'cd "$1" && PATH="$2:$PATH" clupl --help'
	local output = uts.run({ "sh", "-c", script, "sh", emptyFolder, files.parent(program) or "." })

	if not string.find(output, "clupl <command>", 1, true) then
		error(
			`the compiled program acts like plain lute when it's run by name. This lute ({LUTE}) has a bug `
				.. "that breaks compiled programs started through PATH, so build with a newer one, e.g. "
				.. "/path/to/newer/lute run buildscript.luau. Lute's nightly builds have the fix",
			0
		)
	end
end

-- compiles a copy of source and returns the path of the resulting binary
local function compile(format: string): string
	local source = `{STAGE}/{format}/source`
	copySource(source, format)

	local program = `{STAGE}/{format}/compiled/clupl`
	files.makeFolder(`{STAGE}/{format}/compiled`)
	uts.run({ LUTE, "compile", source .. "/main.luau", "--output", program })
	checkRunsByName(program)
	return program
end

-- size of a file in KiB, rounded up.
local function sizeInKiB(filePath: string): number
	return math.ceil(fs.metadata(filePath).size / 1024)
end

local builders: { [string]: () -> string } = {}

function builders.binary(): string
	local output = BUILD .. "/" .. releases.fileName("binary", VERSION, ARCH)
	files.copy(compile("binary"), output)
	return output
end

function builders.appimage(): string
	local appDir = STAGE .. "/appimage/AppDir"
	copySource(appDir .. "/usr/share/clupl", "appimage")

	local values = templateValues()
	files.write(appDir .. "/clupl.desktop", fillTemplate(PACKAGING .. "/appimage/clupl.desktop", values))
	files.copy(PACKAGING .. "/appimage/clupl.svg", appDir .. "/clupl.svg")
	files.copy(PACKAGING .. "/appimage/AppRun", appDir .. "/AppRun")
	files.makeExecutable(appDir .. "/AppRun")

	local output = BUILD .. "/" .. releases.fileName("appimage", VERSION, ARCH)
	-- --no-appstream skips checking for AppStream metadata, which CLUPL doesn't have
	uts.run({ "appimagetool", "--no-appstream", appDir, output }, nil, { ARCH = ARCH })
	return output
end

function builders.deb(): string
	local program = compile("deb")
	local root = STAGE .. "/deb/root"
	files.makeFolder(root .. "/DEBIAN")
	files.makeFolder(root .. "/usr/bin")
	files.makeFolder(root .. "/usr/share/doc/clupl")
	files.copy(program, root .. "/usr/bin/clupl")
	-- Debian keeps a package's license in /usr/share/doc/<name>/copyright
	files.copy(ROOT .. "/LICENSE", root .. "/usr/share/doc/clupl/copyright")

	local values = templateValues()
	values.installedSize = tostring(sizeInKiB(program) + sizeInKiB(ROOT .. "/LICENSE"))
	-- the compiled program needs the C and C++ standard libraries, Lute is built with glibc 2.34 and GCC 12
	local depends = { "libc6 (>= 2.34)", "libstdc++6 (>= 12)", "libgcc-s1" }
	for _, dependency in manifest.dependencies.deb do
		table.insert(depends, dependency)
	end
	values.depends = table.concat(depends, ", ")
	values.recommends = table.concat(manifest.recommends.deb, ", ")
	files.write(root .. "/DEBIAN/control", fillTemplate(PACKAGING .. "/deb/control", values))

	local output = BUILD .. "/" .. releases.fileName("deb", VERSION, ARCH)
	-- --root-owner-group makes every file owned by root in the package
	uts.run({ "dpkg-deb", "--build", "--root-owner-group", root, output })
	return output
end

function builders.rpm(): string
	local program = compile("rpm")
	local top = STAGE .. "/rpm"
	files.makeFolder(top .. "/SOURCES")
	files.makeFolder(top .. "/SPECS")
	files.copy(program, top .. "/SOURCES/clupl")
	files.copy(ROOT .. "/LICENSE", top .. "/SOURCES/LICENSE")

	local values = templateValues()
	-- rpm works out the C and C++ libraries the program needs by itself
	values.depends = table.concat(manifest.dependencies.rpm, " ")
	values.recommends = table.concat(manifest.recommends.rpm, " ")
	local spec = top .. "/SPECS/clupl.spec"
	files.write(spec, fillTemplate(PACKAGING .. "/rpm/clupl.spec", values))

	-- _topdir tells rpmbuild to work in the stage folder instead of ~/rpmbuild
	uts.run({ "rpmbuild", "-bb", "--target", ARCH, "--define", `_topdir {top}`, spec })

	local name = releases.fileName("rpm", VERSION, ARCH)
	local output = BUILD .. "/" .. name
	files.move(`{top}/RPMS/{ARCH}/{name}`, output)
	return output
end

function builders.arch(): string
	local program = compile("arch")
	local folder = STAGE .. "/arch"
	files.copy(program, folder .. "/clupl")
	files.copy(ROOT .. "/LICENSE", folder .. "/LICENSE")

	local values = templateValues()
	local depends = { "glibc", "gcc-libs" }
	for _, dependency in manifest.dependencies.arch do
		table.insert(depends, dependency)
	end
	values.depends = quotedList(depends)
	values.recommends = quotedList(manifest.recommends.arch)
	files.write(folder .. "/PKGBUILD", fillTemplate(PACKAGING .. "/arch/PKGBUILD", values))

	uts.run({ "makepkg", "--force", "--nodeps", "--noconfirm" }, folder, {
		PKGDEST = folder,
		SRCDEST = folder,
		BUILDDIR = folder .. "/work",
		PKGEXT = ".pkg.tar.zst",
	})

	local name = releases.fileName("arch", VERSION, ARCH)
	local output = BUILD .. "/" .. name
	files.move(folder .. "/" .. name, output)
	return output
end

-- the formats passed in on the command line, or every format if none
local function chosenFormats(): { string }
	local chosen = { table.unpack(process.args, 2) }
	if #chosen == 0 then
		return releases.formats
	end

	for _, format in chosen do
		if format == "--help" or format == "-h" then
			print(`Usage: lute run buildscript.luau [{table.concat(releases.formats, " ")}]`)
			process.exit(0)
		elseif not table.find(releases.formats, format) then
			uts.fail(`unknown format '{format}' (formats: {table.concat(releases.formats, ", ")})`)
		end
	end
	return chosen
end

local function main()
	if releases.parseVersion(VERSION) == nil then
		uts.fail(`manifest.luau's version must look like 1.2.3, got '{VERSION}'`)
	end

	local formats = chosenFormats()
	print(richterm.bold(`Building {manifest.name} {VERSION} for {ARCH}`))

	files.remove(BUILD)
	files.makeFolder(STAGE)

	local built: { string } = {}
	local missed: { string } = {}
	for _, format in formats do
		local tool = TOOLS[format]
		if tool and not uts.hasProgram(tool) then
			print(richterm.yellow(`skipping {format}, it needs {tool} installed`))
			table.insert(missed, format)
			continue
		end

		step(`building {format}`)
		local succeeded, result = pcall(builders[format])
		if succeeded then
			print(`    {files.shortPath(result)}`)
			table.insert(built, result)
		else
			uts.printError(uts.cleanError(result))
			table.insert(missed, format)
		end
	end

	local lines = {}
	for _, output in built do
		table.insert(lines, `{checksums.sha256(output)}  {files.basename(output)}`)
	end
	if #lines > 0 then
		files.write(BUILD .. "/SHA256SUMS", table.concat(lines, "\n") .. "\n")
	end

	-- not for uploading
	files.write(BUILD .. "/VERSION", VERSION .. "\n")

	-- the stage folder is only for building
	files.remove(STAGE)

	print()
	if #built > 0 then
		print(richterm.bold(richterm.green(`Built {uts.count(#built, "file")} in build/`)))
		print(`Upload them and SHA256SUMS (not VERSION) to a GitHub release named v{VERSION}`)
	end
	if #missed > 0 then
		uts.fail(`not built: {table.concat(missed, ", ")}`)
	end
end

main()
