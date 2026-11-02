<p align="center">
  <img src="packaging/appimage/clupl.svg" alt="clupl logo" width="140">
</p>

<h1 align="center">CLUPL</h1>

<p align="center">
  <b>Custom Luau-based Package Manager for Linux</b><br>
  Install and update programs straight from their GitHub or Codeberg releases, and any release from a repo on a Forgejo/Gitea site.
</p>

<p align="center">
  <a href="https://github.com/GoobisMoobis/clupl/releases"><img alt="Latest release" src="https://img.shields.io/github/v/release/GoobisMoobis/clupl?color=2b5ea7"></a>
  <a href="LICENSE"><img alt="MIT License" src="https://img.shields.io/badge/license-MIT-3d7ad6"></a>
  <a href="https://luau.org/"><img alt="Written in Luau" src="https://img.shields.io/badge/written%20in-Luau-5b93e6"></a>
  <a href="https://lute.luau.org/"><img alt="Runs on Lute" src="https://img.shields.io/badge/runs%20on-Lute-7fb0f2"></a>
</p>

<p align="center">
  <a href="#installing">Installing</a> ·
  <a href="#quick-start">Quick start</a> ·
  <a href="docs/package-files.md">Writing package files</a> ·
  <a href="#usage">Usage</a> ·
  <a href="CONTRIBUTING.md">Contributing</a>
</p>

---

CLUPL exists to solve one problem in an extremely simple way, and intentionally uses the Luau programming language (more specifically the Lute runtime) so that the code is easy to read and modify.

Why would you ever want to maintain your own custom PKGBUILD files that aren't on the AUR if the developers already maintain releases on GitHub or Codeberg?

By using CLUPL and its dead-easy package definition structures, you can manage custom packages in a write-once, read-never type of way.

If you are curious on the use of AI during the development process, check the [AI Disclosure](AI-DISCLOSURE.md#building-a-release)

## Why clupl

- **Packages are simple.** `{ "repository": "https://github.com/BurntSushi/ripgrep" }` is all you need to write a working package file. You can be more specific if you want, but by default CLUPL picks the right download, finds the programs inside and links them onto your PATH.
- **It remembers its choices.** If it had to work out anything during the install process, it saves those steps and uses them on every single update thereafter. If you don't specify something in a package file, it chooses for you.
- **Security!** If one exists, CLUPL always uses a generated GitHub checksum to check that what it downloaded wasn't corrupted or tampered with. It also autodetects checksums in releases, and you can further specify other things to check against to make sure the files you want are the ones you get.
- **App menu entries.** If you are using CLUPL for a GUI program, you can define a desktop entry in a package file, which is automatically created and placed into the app menu by CLUPL.
- **Runs as a user.** If a step needs `sudo` to install, CLUPL will only ask for that one step. Running as root will install a package for root.
- **Wide platform support.** Codeberg and any other Forgejo or Gitea site work, and more platforms will be supported in the future!
- **Nothing is left half-installed.** If an error occurs during an install or update, CLUPL will refuse to keep it like that and will either roll back to an old version or delete the half-installed files.
- **Nightlies and prereleases, too.** Prereleases are opt-in, and work just fine.
- **Simple on purpose.** Written in Luau, the language used for Roblox programming, so anyone who is just starting out on Linux or programming in general can read it, understand it, and contribute to it.

## Installing

Every [release](https://github.com/GoobisMoobis/clupl/releases) has CLUPL in five forms:

| Format           | Install with                                           | Notes                                                                 |
| :--------------: | :----------------------------------------------------- | :-------------------------------------------------------------------- |
| Debian, Ubuntu   | `sudo apt install ./clupl_<version>_amd64.deb`         | Tested on Debian 13                                                   |
| Arch Linux       | `sudo pacman -U clupl-<version>-1-x86_64.pkg.tar.zst`  | Tested on Arch                                                        |
| Fedora, openSUSE | `sudo dnf install ./clupl-<version>-1.x86_64.rpm`      | **Untested**, see below                                               |
| Any distribution | `install -Dm755 clupl-linux-x86_64 ~/.local/bin/clupl` | A single program                                                      |
| Any distribution | `chmod +x clupl-x86_64.AppImage`                       | Needs [Lute](https://lute.luau.org/guide/installation.html) installed |

> [!NOTE]
> The `.rpm` should work and was built using the official packaging tool. It was checked to ensure integrity (its contents, dependencies and checksums are right), but it hasn't been installed on a real Fedora or openSUSE system. If you try it, please [open an issue](https://github.com/GoobisMoobis/clupl/issues) saying how it went. If you run into any bugs, I will put it at the top of my radar.

CLUPL depends on `tar`, `unzip`, `gzip`, `xz`, `bzip2` and `zstd`, which almost every Linux system already has. [`gh`](https://cli.github.com/) is optional but may be useful (see [Settings](#settings)).

`clupl update` updates CLUPL itself, and uses the right method for the version you installed. You can also view release notes before updating CLUPL.

To build CLUPL yourself, see [Building a release](CONTRIBUTING.md#building-a-release) in the contributing guide, or run it straight from the source with Lute using `lute main.luau <command>`. Note that the AppImage is just a packaged version of the source, and when you are using the AppImage version this is essentially what you are doing.

## Quick start

```sh
$ echo '{ "repository": "https://github.com/BurntSushi/ripgrep" }' > ripgrep.json
$ clupl install ripgrep.json      # ripgrep.json can be deleted afterwards
$ rg --version
$ clupl package update            # updates everything clupl installed, or any specific package
```

## Package files

In its simplest form, a package file only needs to have a repository link. Everything else can be worked out when it's installed and saved in CLUPL's own copy:

```json
{ "repository": "https://github.com/BurntSushi/ripgrep" }
```

However, if the release structure is more complex, you can specify much more in a package file. Below are a few examples, and you can find more in the [examples](https://github.com/GoobisMoobis/clupl/tree/main/examples) folder.

```json
{ "repository": "https://codeberg.org/Codeberg/pages-server", "asset": "*-debian-x86_64.tar.gz" }
```

```json
{
  "repository": "https://github.com/neovim/neovim",
  "asset": "nvim-linux-x86_64.tar.gz",
  "exclude": ["*.md"],
  "install": [
    "bin/nvim",
    { "source": "share/man/man1/*", "target": "~/.local/share/man/man1/" },
    { "source": "share/applications/nvim.desktop", "target": "~/.local/share/applications/", "mode": "copy" }
  ]
}
```

**[Writing package files](docs/package-files.md)** has an explanation and guide for everything package files support.

[`package.schema.json`](package.schema.json) gives editors autocomplete for package files if you want to write them using an editor.

Installed packages live in `~/.local/share/clupl/packages/<name>/` (or `$XDG_DATA_HOME/clupl/`). Programs are linked into `~/.local/bin`, so make sure that's on your PATH.

## Usage

```sh
$ clupl install ./tool.json                # Installs a package. The package file can be deleted after this point,
                                           # as it is moved to clupl's own managed directories
$ clupl install http(s)://..               # Gets the content stored at the URL, treating it as a CLUPL package file
$ clupl install ./tool.json -p             # Allows prereleases (betas, nightlies) if the package file doesn't say
$ clupl install ./tool.json --test         # Installs nothing, shows in detail what it would do and any problems (-t works too)
$ clupl install ./tool.jsonc               # CLUPL supports .jsonc, allowing you to write comments
$ clupl update                             # Updates clupl itself (clupl package update clupl does the same)

$ clupl package list                       # Lists all installed packages
$ clupl package list --filter-outdated     # Lists outdated packages specifically
                                           # Note: this may take a while as it fetches all release data for
                                           # all installed packages.
$ clupl package list --filter-outdated=4   # Checks the versions for 4 packages at a time instead of the default, 1
$ clupl package info package               # Gives you info on a specific installed package
$ clupl package update                     # Updates every (outdated) package
$ clupl package update package -j 4        # Updates only the packages named, 4 at a time
$ clupl package reinstall package          # Downloads and installs a package again at the version it's on
$ clupl package hold package               # Forces CLUPL to leave a package alone and refuse to update it
$ clupl package unhold package             # Lets a held package be updated again
$ clupl package install ./tool.json        # The same as clupl install

$ clupl remove --name package              # Removes a package based on its name (clupl package remove does the same)
$ clupl remove --repository https://...    # Removes a package based on its repo URL
$ clupl remove -n package -r http(s)://... # Removes only a package that matches both the name and URL

$ clupl <command> --yes                    # Answers every question with its default (-y works too)
```

## Settings

```sh
$ clupl config                             # Lists settings
$ clupl config github gh                   # Uses the GitHub CLI for GitHub instead of plain HTTP
$ clupl config github http                 # Uses http for GitHub (default)
```

Plain HTTP works without setup or prerequisites, but GitHub only allows 60 requests an hour without an account. If that runs out and `gh` is installed and logged in (`gh auth login`), clupl uses `gh` for you automatically. If not, installing and updating will start to fail!

## Contributing

Contributions are welcome, regardless of experience! [CONTRIBUTING.md](CONTRIBUTING.md) has just a few rules, and a detailed guide to get you started if you are new to programming. Even if you've never touched Luau before, I made sure to link to a few guides to learn pretty quickly.

## License

CLUPL is licensed under the [MIT License](LICENSE).

### Third-party code

- [`vendor/batteries`](vendor/batteries) is vendored from [Lute](https://github.com/luau-lang/lute) v1.0.0,
  Copyright (c) 2024–2025 Roblox Corporation, and is licensed under the MIT License.
  See [`vendor/batteries/LICENSE`](vendor/batteries/LICENSE).
