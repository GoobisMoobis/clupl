# Contributing to CLUPL

CLUPL is meant to be the simplest it can be while retaining complex functionality. It should be programmed in a way so that someone very new to coding can read it, and possibly contribute to their first project.

If you are a starter programmer and are reading this, your contribution is wanted, and writing simple code will come easy to you. For those of you who have done this for years, prioritize the code being readable. An extra line or two isn't going to slow down the program a measurable amount, and the speed of the program isn't too much of an issue because a lot of what it does relates mainly to networking.

If you're just here for the rules, they're [at the bottom](#rules-for-contribution).

## Learning Luau

CLUPL is written in [Luau](https://luau.org/), as it is very simple to learn and is used in places a lot of young programmers have experience with such as Roblox.

If you already know Luau, you still need to learn [Lute](https://lute.luau.org/), too. Lute is the runtime that CLUPL runs on, and without it CLUPL isn't possible.

If you don't know either of these, follow these guides below.

- [Programming in Lua](https://www.lua.org/pil/contents.html) (the first edition is free online) and the [Lua 5.1 reference manual](https://www.lua.org/manual/5.1/). Almost everything in them works in Luau, because Luau is based on Lua 5.1
- [Getting started with Luau](https://luau.org/getting-started/), the [syntax tour](https://luau.org/syntax/) to see what Luau adds to Lua, and the [type system](https://luau.org/types/) it adds can all be found through those hyperlinks.
- For Lute, you can find a list of links on the [guide page](https://lute.luau.org/guide/index.html), such as the [library docs](https://lute.luau.org/lute/index.html). If you want to get into the weeds a bit more, after setting up Lute (see below) you can check the files in `.lute/typedefs/current/` to see what every function takes in and returns.

## Setting up on Linux

### 1. Install Lute

You can find the official install guide [here](https://lute.luau.org/guide/installation.html), and everything below is simply based on that. If anything in the official guide conflicts with what is compiled here, listen to the official guide.

> [!CAUTION]
> As far as I am aware, only the CLUPL and Official Binary methods allow for nightly builds of Lute, and the nightly builds are what I use to compile it! If you are planning to compile your own builds, do not use a different method!

| Method          | Description |
| :-------------: | :---------- |
| CLUPL           | That's right, CLUPL can manage the runtime it runs on. A bit confusing, but this is how I personally do it. Download any CLUPL release **aside from the AppImage**, and use the .json file inside the `examples/` directory. Run `clupl install https://raw.githubusercontent.com/GoobisMoobis/clupl/main/examples/lute.json` to install Lute. **If you plan to build releases, make sure to add the `--prerelease` flag to tell CLUPL to download the latest nightly version of Lute!** |
| Official Binary | Go to the [releases page](https://github.com/luau-lang/lute/releases) of Lute's GitHub repository |
| Rokit           | This is another official pathway documented in the official install guide. If you have [rokit](https://github.com/rojo-rbx/rokit) installed, run `rokit add luau-lang/lute@1.0.0` to install it. |
| AUR             | The package `lute-bin` on the AUR contains a prebuilt version of Lute for arch-based distros. |

### 2. Install dependencies

CLUPL does not include bundled packages for extracting, e.g. unzipping and zstandard compression. It also uses Git for version control. You need to make sure you have all of these tools if you plan to develop for CLUPL.

CLUPL also makes use of the GitHub CLI as an alternative to HTTP for managing packages from GitHub, so having it on-hand is useful.

```sh
# Arch or Arch-based
$ sudo pacman -S --needed git tar unzip gzip xz bzip2 zstd github-cli

# Debian or Debian-based (includes Ubuntu)
$ sudo apt install git tar unzip gzip xz-utils bzip2 zstd gh # Note: gh is the github-cli package on these distros

# Fedora
$ sudo dnf install git tar unzip gzip xz bzip2 zstd gh
```

### 3. Set up your environment

Git setup is required but could be a whole file by itself. I heavily recommend watching a 10-20 minute tutorial for Git on YouTube, or using a GUI for Git.
If you plan to contribute back to this repository, make sure you **fork** it.

If you are a new programmer, I encourage you to stay organized from the very start. Create a folder on your computer, say `~/Documents/Projects` and put your code in a subfolder. For CLUPL, that could mean:

```sh
# ~/Documents/Projects
$ git clone https://github.com/[USERNAME]/clupl
$ cd clupl
```

### 4. Set up type definitions

> [!NOTE]
> This is only for the editor and for the `lute check` command. Nothing else uses this explicitly.

I made this as simple as I could, and bundled a script in this repository that does it for you. Run the below command from the root of the project.

```sh
$ lute run scripts/setup.luau
```

This creates a new folder in this repository, ignored by Git, `.lute/` which contains symlinks to the system folder `~/.lute/typedefs/<version>` containing type definitions for Lute generated by the command `lute setup`. This is then used by the `.luaurc` file to prevent linting extensions from having a heart attack.
**This needs to be re-run after every Lute update.**

### 5. Run CLUPL

```sh
$ lute run main.luau --help
$ lute run buildscript.luau binary   # Creates a CLUPL binary using lute compile
```

## Editors

Any editor works, but these have good Luau support through [luau-lsp](https://github.com/JohnnyMorganz/luau-lsp), a language server for Luau made by Johnny Morganz, who you might already recognize if you've ever developed using Luau tooling before.

- **VSCodium or VS Code:** install the Luau Language Server extension (`JohnnyMorganz.luau-lsp`). I personally use VSCodium, so this repository already has a `.vscode/settings.json` file set up for CLUPL development.
- **Neovim:** [luau-lsp.nvim](https://github.com/lopi-py/luau-lsp.nvim).
- **Zed:** Use the Luau extension from Zed's extension menu ([zed-luau](https://github.com/4teapo/zed-luau)).

[StyLua](https://github.com/JohnnyMorganz/StyLua) is a formatter for Lua and Luau with extensions for the editors above, and it is another tool I personally use (and also by Johnny Morganz). `stylua.toml` was created by me to match closest to my style and keep everything in this repo consistent.

## Project layout

```
main.luau              CLUPL entrypoint
manifest.luau          Used during the build pipeline to keep information about CLUPL the same between every packaging method.
                       If you start to see yourself adding the same information about CLUPL in multiple different files,
                       add it to the manifest instead.
buildscript.luau       Simplifies the building and packaging processes and outputs results in the build folder.
                       Includes a binary, .deb, .rpm, .pkg.tar.zst, and .AppImage
packaging/             Files used by the above build script, such as for platform-specific packaging information
commands/              Logic for commands, one file per command.
commands/package/      Subcommands of clupl package
commands/types.luau    Includes the shared types used by commands
utilities/             A module built on top of batteries and centralized functions for commands.
                       Any code used enough times is put here.
utilities/platforms/   Includes every platform CLUPL supports and the logic to support them.
                       e.g. GitHub and Forgejo (which includes Gitea and Codeberg too)
vendor/batteries/      Library directly from Lute, don't edit
package.schema.json    What a package file can contain
docs/package-files.md  Guide to writing package files
examples/              Example package files (if you want an easy way to contribute,
                       make some of these for me!)
stylua.toml            Formatting settings for StyLua
build/                 Results from buildscript.luau
```

### Examples of common workflows

To add a command, make a file in `commands/` that returns a `Command` (see `commands/types.luau`) and add it to the registry located in `commands/init.luau`. Subcommands work the same way through the command's `subcommands` list, see `commands/package/init.luau`. If you're confused about anything, or I didn't comment something good enough, don't be afraid to ask me directly.

To add a platform it is a bit more involved.
Make a file in `utilities/platforms/` that does what `common.Platform` in `utilities/platforms/common.luau` describes and add it to `PLATFORMS` and `platforms.names` in `utilities/platforms/init.luau`.
If it has a well-known site associated with it and isn't something broad like Forgejo, add it to `KNOWN_HOSTS` in the same file.
You will also need to update the package schema, and all of the files that go along with it such as `docs/package-files.md`.

## Checking code

EVERYTHING needs to be clean with no errors before you open a pull request. Use the `lute check` command on important files you edit and the files that require them.
Example:

```sh
$ lute check main.luau \
>    manifest.luau \
>    commands/*.luau \
>    commands/package/*.luau \
>    utilities/*.luau \
>    utilities/platforms/*.luau \
>    scripts/*.luau
```

At least for me using VSCodium, the type checker I use is a lot stricter than the standard `lute check` command, so make sure it doesn't get angry at anything either.

> [!NOTE]
> I try to commit files that don't have ANY errors, however if you see one I didn't catch, feel free to change it.

## Testing safely

`clupl install <file> --test` shows everything an install would do without changing anything, which is usually enough if you aren't making huge changes to the installer. If you want to test an actual install, CLUPL currently relies on the HOME environment variable to know where to place files, and you can easily override that in something like Bash or Zsh for the current session.

```sh
$ mkdir -p /tmp/clupl-home
$ HOME=/tmp/clupl-home lute run main.luau install ./some-package.json
$ HOME=/tmp/clupl-home lute run main.luau package list
```

> [!WARNING]
> This method breaks the GitHub CLI! You will also need to set the `GH_CONFIG_DIR` environment variable, and the easiest way to do so is right before you override the home variable:
>
> ```sh
> $ GH_CONFIG_DIR=$HOME/.config/gh HOME=/tmp/clupl-home lute run main.luau config github gh
> ```

After you are done testing `rm -rf /tmp/clupl-home` will remove the directory. If you are scared or getting flashbacks from this command, use your file manager instead.

## Building a release

> [!NOTE]
> If you aren't planning to contribute to CLUPL and only came here for information on how to build CLUPL yourself, you can skip things like bumping the manifest and making a GitHub release.
> This file is mainly targeted at contributors and may read a bit strange.

Everything about CLUPL itself should be inside of the manifest file, `manifest.luau`, and `buildscript.luau` uses that information when making releases using the files in `packaging/`.
It is this way so that you only have to edit one file and barely have to touch the packaging folder. It is worth looking at those files inside the `packaging/` folder, however I built this pipeline specifically so that you don't have to understand them. Below is how to build a full release.

1. Bump the version in `manifest.luau`
2. Run `lute buildscript.luau` **with a Lute nightly** (remember what I said back when I was telling you how to install Lute?)
3. Make a GitHub release named after the version (e.g. v1.0.0) and upload everything in the `build/` folder BESIDES `VERSION`

By default, `buildscript.luau` will build a release for every single platform. If you want to specify specific platforms, run `lute buildscript.luau --help` to see all supported platforms and then you can compile for a specific platform.
Example:

```sh
$ lute run buildscript.luau deb arch
# Builds for Debian/Ubuntu based systems and Arch-based systems
```

> [!WARNING]
> `buildscript.luau` WILL NOT work out of the box!
> The below list is tailored specifically to an Arch or Arch-derived environment, however the tools themselves are available on most Linux distros:

| Format              | Tool         | On Arch |
| :-----------------: | :----------: | :------ |
| Binary              | lute compile | If you can't run this command, why are you here? **Note: Needs a nightly version of Lute!** |
| .AppImage           | appimagetool | [appimagetool releases](https://github.com/AppImage/appimagetool/releases) |
| .deb                | dpkg-deb     | `sudo pacman -S dpkg` |
| .rpm                | rpmbuild     | `sudo pacman -S rpm-tools` |
| .pkg.tar.zst (Arch) | makepkg | comes with pacman |

### Why a Lute nightly is required

The way that `buildscript.luau` builds a binary is via a built-in command that comes with Lute, `lute compile`.
Despite the name, it really doesn't "compile" it in the way you'd think of a language like Rust or C++. It instead includes Lute inside the binary itself along with the code. The actual Lute runtime is the one that is doing all the work under the hood.
Think of the file like a tree:

```
clupl               The binary you see and use
clupl/lute          The actual binary that is run
clupl/main.luau     The code that is run by the real binary
```

Lute 1.0.0, the official release, has a bug with `lute compile` where the program only works if run via a DIRECT path invocation. If you put it in a folder on your PATH such as `/usr/bin` and run it via a shell, it breaks, and instead runs the REAL lute underneath! I only ran into this when testing CLUPL on a Debian server, because every other time I invoked the binary I'd simply run `./build/clupl` which bypasses the bug.
This is fixed in nightly versions of Lute, as it was a bug found very quickly. However, only the official Lute 1.0.0 is included in things such as rokit and the AUR which is why installing Lute with CLUPL itself is actually the best course of action here.

### Testing your release

`clupl update` can also be overridden to use a specific path to check for an update instead of checking GitHub.
After building the release for your specific platform, rename the file to something like `build/clupl-linux-x86_64` so clupl recognizes it as a valid file to update from. You can then run the below command.

```sh
$ CLUPL_SELF_UPDATE_FROM=/home/user/Documents/Projects/clupl/build/ ./old-clupl-version update
```

If you use CLUPL yourself, `old-clupl-version` should be an independent file that isn't the one you already have on-system. If you want a new one, use the AppImage version, as it is the lightest and will work once you already have Lute. In the command simply add `.AppImage` to `./old-clupl-version`

## Rules for contribution

After reading through all that jumbo, here are the rules I have when you make code for CLUPL. I tried to keep everything short!

1. AI is a **tool**, and it doesn't take your place. Use it for learning, use it to draft code if it helps, but don't let it take your place. Before you open a pull request, make sure you understand what you are submitting. I do not accept shitty slop.
2. Look at already existing code for a benchmark on how simple everything else needs to be. Again, **simplicity is the goal**. Give things proper names, and even if a function is tiny, if it makes the code look better, use the tiny function.
3. Comment your code! I'm really bad at this personally and have to remind myself of it constantly, but for a project like this it makes everything 100,000% easier. Keep them short, and explain the *why*. Same with #2, look at already existing code for a benchmark
4. **Don't** edit `vendor/` and instead edit `utilities/` when needed. The batteries library inside `vendor/` is copied from [Lute](https://github.com/luau-lang/lute) and is external. If you need to extend it, and trust me, you will, use the already existing utility modules I wrote for this purpose.
5. Be organized and keep code where it belongs. Command-specific logic goes in `commands/` and shouldn't be scattered about. Functions that may be used by more than one command get added to the utility library.
6. **NO errors**. Check your code once, test it twice, find out if it's going to be naughty or nice (see [Checking code](#checking-code)).
7. Make sure that large changes are documented. For example, if you change the way `utilities/package.luau` works you most likely need to update `package.schema.json` and `docs/package-files.md` too.
8. Keep things backwards-compatible, and add a deprecation warning for the end-user if something might break when they update. If you update the format of package json files to add a new required field or change the way an existing field works, either make clupl automatically fix old package files, or tell people they need to update their packages. **Avoid breaking changes if you can!** Pull requests may be rejected if I think you have not done enough to try and keep everything backwards-compatible.
9. Test your code! #6 SHOULD avoid anything major, but even just small command run-throughs can save massive headaches for the both of us!

---

<h3 align="center">Contact me for any inquiries at <a href="mailto:contact@goobismoobis.com">contact@goobismoobis.com</a></h3>
<p align="center">Title your message something so I know it is CLUPL related!</p>