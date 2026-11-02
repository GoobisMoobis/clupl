# batteries (vendored from Lute v1.0.0)

Source: https://github.com/luau-lang/lute/tree/v1.0.0/batteries. Upstream has no
API docs for these modules; the closest thing is the test suite at
`tests/batteries/*.test.luau` in the Lute repo. This file is a hand-written
reference based on reading the source and running it.

Resolved through the `"batteries"` alias in the project `.luaurc`.

---

## cli — argument parser

```luau
local cli = require("@batteries/cli")

local p = cli.parser()
p:add("name",    "positional", { required = true, help = "package name" })
p:add("verbose", "flag",       { aliases = { "v" } })
p:add("filter",  "option",     { aliases = { "f" }, default = "all" })
p:add("files",   "variadic",   {})
-- process.args (from @std/process) includes the script path as args[1], so skip it
p:parse({ table.unpack(process.args, 2) })

p:get("name")     --> string?   (positional / option values)
p:has("verbose")  --> boolean   (flags only)
p:variadics()     --> { string }
p:forwarded()     --> { string } (everything after "--", plus unclaimed extras)
p:usage("clupl")  --> "clupl <name> [options] [files...]"
p:help(fmt?)      -- prints a usage block; fmt is an optional (string) -> string
```

- Kinds: `"positional" | "flag" | "option" | "variadic"`.
- Options: `{ help: string?, aliases: { string }?, default: string?, required: boolean?, hidden: boolean? }`.
  The options argument is required by the type signature, so pass `{}` if you have none.
- `--name` or `--alias` matches long; `-abc` is three single-letter flags/aliases.
  An option consumes the *next* argument (`--filter x`); `--filter=x` is **not** supported.
- Unknown args, missing option values and missing required args **throw** (via `assert`).
  Wrap `parse` in `pcall` if you want a friendly message.
- No subcommands. For `clupl install ...`, read `args[1]` yourself and build a parser per command.
- Quirk: `help()` prints `(-)` for args with no aliases.

## toml — minimal TOML

```luau
local toml = require("@batteries/toml")
toml.serialize(tbl: { [string]: any }): string
toml.deserialize(input: string): { [string]: unknown }
```

- Deserialize handles: `key = value`, quoted keys, `[table]`, `[a.b]`, `[[array.of.tables]]`,
  `#` comment lines, strings (`"…"`/`'…'` with `\n \t \\` escapes), numbers,
  `true`/`false`, `inf`/`-inf`/`nan`.
- **Not supported:** inline arrays (`[1, 2]`) and inline tables (`{ x = 1 }`) come back
  as raw strings; multi-line strings; trailing comments after values; dates.
- Serialize handles strings, numbers and nested tables (emitted as `[sections]`).
  Arrays **error**.
- For anything non-trivial, prefer JSON via `@std/json`.

## result — Result type

```luau
local result = require("@batteries/result")
type T<V> = { success: true, value: V } | { success: false, err: string, traceback: string }

result.ok(value): T<V>
result.fail(err: string): T<V>     -- captures a traceback
result.pcall(f, ...): T<R>         -- pcall that returns a result (first return value only)
```

The type `T` isn't exported, so annotate with the shape above if you need it.

## richterm — ANSI terminal styling

```luau
local rt = require("@batteries/richterm")
print(rt.bold(rt.red("error:")) .. " something broke")
local warn = rt.combine(rt.yellow, rt.bold)
print(warn("careful"))
print(rt.red("plain", true)) -- second arg `nocolor = true` returns s unchanged
```

Every formatter is `(s: string, nocolor: boolean?) -> string` (exported as `Formatter`).

- Styles: `reset bold dim italic underline inverse hidden strikethrough`
- Colors: `black red green yellow blue magenta cyan white gray`, plus `bright*` variants
  (`brightRed`, …)
- Backgrounds: `bg*` and `bgBright*` (`bgRed`, `bgBrightBlue`, …)
- `combine(...formatters)` gives a new formatter that applies each in order.

Nesting works: inner resets are rewritten so the outer style continues.

## glob — glob matching and filesystem discovery

```luau
local glob = require("@batteries/glob")
glob.match("src/**/*.luau", "src/a/b.luau") --> true (pure, no filesystem access)
glob.discover("/opt/clupl/packages/*.json") --> { path.Path } (sorted; `~` is not expanded)
```

Takes `@std/path` `Pathlike` values (strings work). Syntax follows Rust's `glob` crate:
`?`, `*` (doesn't cross `/`), `**` (must be a whole path segment), `[abc]`, `[a-z]`, `[!x]`;
use `[*]` to match a literal `*`. Call `tostring` on results, or use `@std/path` helpers.

## base64

```luau
local base64 = require("@batteries/base64")
base64.encode(buffer.fromstring("hello")) --> buffer ("aGVsbG8=")
base64.decode(buf: buffer): buffer
```

Works on **buffers**, not strings: use `buffer.fromstring` / `buffer.tostring` to convert.

## pp — pretty-printer

```luau
local pp = require("@batteries/pp")
print(pp({ a = 1, nested = { "x", "y" } }))
pp(value, { rawStrings = true }) -- don't quote/escape strings
```

Returns a multi-line string; handles cycles and sorts keys by type. Good for debugging.

## difftext — text diffs (Myers algorithm)

```luau
local difftext = require("@batteries/difftext")
local d = difftext.diff(a, b)                    -- line-by-line
local d = difftext.diff(a, b, { byChar = true }) -- character-by-character
-- d: { { key: "EQUAL" | "ADD" | "DELETE", text: string } }

print(difftext.prettydiff(a, b))                                      -- colored +/- lines
print(difftext.prettydiff(a, b, { detailed = true, includeLineNumbers = true }))
```

Exported types: `difftext.diff`, `difftext.diffoptions`.

## collections/deque — double-ended queue

```luau
local deque = require("@batteries/collections/deque")
local q = deque.new()          -- or deque.new(firstValue)
q:pushback(1); q:pushfront(0)
q:popfront() --> 0   (errors if empty)
q:popback()  --> 1   (errors if empty)
q:peekfront(); q:peekback()    -- nil if empty
#q                             -- length
```

Exported type: `Deque<T>`.
