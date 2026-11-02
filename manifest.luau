--[[
everything about clupl itself, in one place.

used by buildscript.luau during the build pipeline, read about it more there.

clupl reads its own version from here too
]]

return {
	name = "clupl",
	version = "0.1.0",
	summary = "Custom Luau-based package manager for Linux",
	description = "Installs and updates programs straight from their Git releases.",
	license = "MIT",

	--[[
	where releases are published (change this if you fork clupl
	or make your own releases):
	https://github.com/<owner>/<repository>
	]]
	owner = "GoobisMoobis",
	repository = "clupl",

	-- programs clupl needs. Most should be pre-installed.
	dependencies = {
		deb = { "tar", "unzip", "gzip", "xz-utils", "bzip2", "zstd" },
		rpm = { "tar", "unzip", "gzip", "xz", "bzip2", "zstd" },
		arch = { "tar", "unzip", "gzip", "xz", "bzip2", "zstd" },
	},

	--[[
	programs that make clupl better but aren't needed,
	which currently is only the github cli but
	might get expanded to include something like
	curl-impersonate if that turns out to be useful
	for bare http requests.
	]]
	recommends = {
		deb = { "gh" },
		rpm = { "gh" },
		arch = { "github-cli: use a logged in GitHub account (clupl config github gh)" },
	},
}
