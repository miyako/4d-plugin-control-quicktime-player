![version](https://img.shields.io/badge/version-19%2B-5682DF)
![platform](https://img.shields.io/static/v1?label=platform&message=mac-intel%20|%20mac-arm&color=blue)
[![license](https://img.shields.io/github/license/miyako/4d-plugin-control-quicktime-player)](LICENSE)
![downloads](https://img.shields.io/github/downloads/miyako/4d-plugin-control-quicktime-player/total)

# 4d-plugin-control-quicktime-player

This plugin drives QuickTime Player X on macOS via Apple's ScriptingBridge/Apple Events automation, exposing a single 4D command, `QuickTime Player Execute`, that dispatches on an action code. It can start new movie/audio recordings, control playback (play/pause/resume/stop/present), and open, save, close, or quit QuickTime Player. All results — including errors — come back as fields on a `status` object; there is no separate error/exception path in 4D.

Every call first checks (or re-uses a cached check of) macOS Automation permission for QuickTime Player X. If that permission chain isn't satisfied, `status.success` is `false` and `status.errorMessage` explains exactly which requirement is missing — see [Requirements & platform notes](#requirements--platform-notes) before anything else.

## Summary

| Action constant | Returns | Purpose |
|---|---|---|
| [`qtpc new movie recording`](#new-movie-recording) | `status` | Start a new movie recording document |
| [`qtpc new audio recording`](#new-audio-recording) | `status` | Start a new audio recording document |
| [`qtpc new screen recording`](#new-screen-recording) | `status` | Not implemented — always fails |
| [`qtpc start`](#start) | `status` | Begin recording on a document created above |
| [`qtpc play`](#play) | `status` | Start/resume playback |
| [`qtpc pause`](#pause) | `status` | Pause playback |
| [`qtpc resume`](#resume) | `status` | Resume playback (currently identical to `play`) |
| [`qtpc stop`](#stop) | `status` | Stop playback (no-op if not currently playing) |
| [`qtpc present`](#present) | `status` | Enter full-screen presentation |
| [`qtpc open`](#open) | `status` | Open a file in QuickTime Player X |
| [`qtpc close`](#close) | `status` | Alias of `save` |
| [`qtpc save`](#save) | `status` | Save (and close) or close-discarding a document |
| [`qtpc quit`](#quit) | `status` | Terminate all QuickTime Player X instances |

**Platforms:** macOS only (Intel and Apple Silicon). There is no Windows code path in this plugin at all — every system call it makes (AppKit, ScriptingBridge, Apple Events) is Mac-only.

## Manual versioning and publication

**Bump version** and **Build** are independent, manual-only Actions workflows.
Neither runs for pushes, tags, or pull requests. Bump offers `patch`, `minor`,
and `major`; Build has **zero custom inputs**, only GitHub's built-in ref selector.
Select the source branch for Bump, then explicitly run Build on the desired
source commit. Bump never creates a tag, release, build, or dispatch.

### Source authority and intake repair

The committed Bump header at
[`30a180bbfb18aa2a19db907ce103a31ceeed995d`](https://github.com/miyako/4d-plugin-control-quicktime-player/blob/30a180bbfb18aa2a19db907ce103a31ceeed995d/.github/workflows/bump-version.yml)
explicitly coordinates `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` and
`CFBundleShortVersionString` / `CFBundleVersion`. That explicit contract governs,
despite its fallback body updating only the first available project key.
Rename-follow history contains no later authority change. This is not a
marketing-only policy inferred from the fallback implementation.

The six marketing assignments already agree at **1.0.3**. Migration repairs only
the six stale current-version literals and the two display-version tokens in
source `English.lproj/InfoPlist.strings` from 1.0.0 to that existing authority.
It does **not** increment the intake version. `Info.plist` retains its literal
`$(MARKETING_VERSION)` reference and absent optional `CFBundleVersion`; no key
is inserted. Future bumps coordinate present literals and retain supported
`$(...)` / `${...}` marketing/current references, whitespace, BOM, each individual
CR/LF/CRLF ending, modes, and unrelated bytes.

Only the project, root plist, and source localization are version inputs.
Committed bundle destinations, archives, dependencies, manifest/schema versions,
and 4D database/catalog/localization counters are excluded. Both readers reject
noncanonical X.Y.Z (including leading zeroes and suffixes), drift, unknown/cyclic
references, missing settings, and lexical duplicates, including quoted/unquoted
same-line duplicates. Rewrites are scoped to real assignments, not comments or
string contents.

Bump pins `github.sha`, requires a clean checkout and exact selected remote
branch, and commits only nonempty source metadata changes with the Copilot
co-author trailer. Its required executable pre-push guard is checked before
editing and again after the final remote read. The guard checks the advertised
old SHA/ref, literal new SHA/HEAD, exactly one direct parent, and exactly one
update (including rejecting an already-up-to-date same-result race). Push is
explicit, non-force, with both `push.followTags=false` and `--no-follow-tags`.

### Build gates and create-only publication

Every checkout pins `github.sha`. Build reads the selected source, then checks
exact remote tag absence and authenticated, fully paginated release lists,
including drafts. Errors (including API 404, malformed responses, authentication,
network, and later-page failures) stop publication. A repository-wide constant
`release-publication` lock serializes all Build refs without cancellation.

The actual pipeline is **macOS only**: Default configuration, arm64 + x86_64,
the original 11.0 deployment override, project dependencies/frameworks, signing,
ZIP/DMG packaging and stapling are retained. The unused Windows solution setting,
v140 project, and committed Windows/Windows64 payloads are not converted into a
new Windows build. No recursive Windows output discovery or artifact download
is introduced. CopyFiles uses `dstSubfolderSpec = 7` (Resources) for manifest
and constants; localization is the existing Resources build phase.

Build removes only the exact rebuilt Mac executable, plist, English localization,
signature, and known intermediates, preserving other resources, Windows files,
and framework/dependency contents. It disables Xcode's implicit signing for
the unsigned rebuild, directs the result to the actual `test/Plugins` bundle,
requires exact `arm64` and `x86_64` lipo tokens (not arm64e/x86_64h), and checks
built plist/localization against source, including UTF-16 and compiled binary
localization. The original pipeline had no no-i386/exact-slice-count restriction;
none is invented. Explicit signing and strict verification precede packaging.
Both notary submissions must exit successfully **and** return `Accepted` JSON;
DMG stapling must succeed.

After all those gates, publication rechecks every release page and tag absence,
POSTs a new `refs/tags/vX.Y.Z` at the selected SHA, verifies it remotely, then
separately POSTs a new public, non-prerelease release with explicit tag, name,
target, body and draft flags. The original empty release body is retained.
Only the newly returned release ID receives the exact
`Control QuickTime Player-X.Y.Z.zip` and `.dmg` assets. Existing tags/releases
are never reused, patched, deleted, clobbered, retried, or rolled back.
The existing secret **names** are unchanged; no secret values are involved in
offline validation.

**Manual recovery:** any failure after a mutation retains the tag, release, and
already uploaded assets, and fails explicitly. Do not blindly rerun Build for
that version: inspect the selected SHA, remote tag, release ID and assets first.
Resolve partial publication manually under maintainer control, or use Bump and
publish a new source version. The workflow never cleans up remote evidence.

### Offline validation and pinned prior art

Run `actionlint .github/workflows/*.yml` and
`PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s .github/tests -v`.
The full suite also runs in a disposable Git/bare-origin copy after a real
guarded helper bump. Native workflow blocks execute only with a closed stub
PATH; no signing, notarization, 4D, Actions dispatch, or production publication
is needed. The string-ownership tests below also compile native source on macOS
and skip on other platforms. There is deliberately no native PR workflow.

The workflows, helpers, hooks and tests were inspected at these exact commits,
not moving branch tips; paths/counts and the macOS-only policy are adapted here:

- [miyako/4d-plugin-native-encoding-detection@c42ca565857f674bde5ea6ed3435c87375eda4a7](https://github.com/miyako/4d-plugin-native-encoding-detection/tree/c42ca565857f674bde5ea6ed3435c87375eda4a7/.github)
- [miyako/4d-plugin-file-information@19848973601acfd3a2b5070230fa40cdc7e4edb2](https://github.com/miyako/4d-plugin-file-information/tree/19848973601acfd3a2b5070230fa40cdc7e4edb2/.github)
- [miyako/4d-plugin-common-string-algorithm@2606a68201866ec9fcbb38b51462d79215f504ef](https://github.com/miyako/4d-plugin-common-string-algorithm/tree/2606a68201866ec9fcbb38b51462d79215f504ef/.github)
- [miyako/4d-plugin-window-button@3f14facb9aaaaff0e22eeb8e07531163680c3a8a](https://github.com/miyako/4d-plugin-window-button/tree/3f14facb9aaaaff0e22eeb8e07531163680c3a8a/.github)
- [miyako/4d-plugin-raw-picture-data@8144537fdc8dcc3d0c053dfe97aff0a8c0c3a6f9](https://github.com/miyako/4d-plugin-raw-picture-data/tree/8144537fdc8dcc3d0c053dfe97aff0a8c0c3a6f9/.github)
- [miyako/4d-plugin-PRNG@522f62e1e9f388be0f3f226c1d4c39362dad2491](https://github.com/miyako/4d-plugin-PRNG/tree/522f62e1e9f388be0f3f226c1d4c39362dad2491/.github)

---

## Native string ownership

The ownership audit starts at `bac6d6ff1fe96070ed9778fa8dec01174948cb09`.
Both root and committed-bundle manifests expose only
`QuickTime Player Execute(&L;&J):J`, dispatched by selector 1. There are no
`&Y` array-capable parameters or first-party method callbacks. Active sources
are the main Objective-C++ file, `support/4DPlugin-JSON.cpp`, and the bundled
SDK; `4D Plugin API/Classes` wrappers are dormant (not in Xcode's source phase).
The Windows project is not a supported implementation of this Mac-only command.

The bundled SDK implementation labels itself `rev : v14`, while its header
labels itself v13; neither establishes a verified upstream release. Its
`4DPluginAPI.c` SHA-256 is
`5bac571c5c4cafd280fa7f23d775458a23701287e8735be27d4a2190002f4e3f`.
At the audit baseline:

| API / call site | Ownership and correction |
|---|---|
| SDK `PA_CreateVariable`, 3920-4077; `PA_SetStringVariable`, 4254-4259 | Creating a text variable allocates an owned empty string; the setter shallowly overwrites it without disposal. Start with an undefined variable before assigning a newly owned string. |
| Active `getDocuments`, 342-373; JSON `ob_set_s` overloads, 42-144 | Avoid the overwritten empty allocation. Final variable cleanup still releases the assigned text after the synchronous property/collection setter copies it. |
| Dormant JSON `ob_set_a` overloads, 146-196 | Apply the same empty-overwrite correction; do not separately dispose the transferred local string alias. |
| SDK `PA_GetObjectProperty`, 636-651; JSON getters, 438-597 | The SDK explicitly requires clearing returned variables. Active `ob_get_a` clears after copying text; dormant boolean/number getters clear after copying, including mismatches. Object/collection getters clear only mismatches: successful references are handed to the caller, which must dispose them. |
| SDK `PA_GetStringInArray`, 4736-4755; `PA_SetStringInArray`, 4933-4948 | Getter results are borrowed; accepted insertion disposes the previous element and transfers the incoming allocation. Dormant `ARRAY_TEXT` copies input into independent C++ strings and transfers freshly created output strings without post-transfer disposal. |
| SDK `PA_SetUnistring`, 289-299; `PA_ReturnString`, 2600-2603; `PA_SetStringField`, 3741-3754 | Content setters/returns and the explicitly non-owning field setter are distinct from shallow struct assignment. Dormant `C_TEXT` uses the content setter, not the array ownership rule. |

`ob_stringify` already clears its independent command argument and owning
returned variable on both expected and mismatched-result paths. There is no
first-party `PA_GetPointerValue` metadata wrapper or `CPicture` implementation
to patch. Bundled SDK internals and unrelated allocation-failure behavior are
not rewritten. Guidance: [miyako/skills#69](https://github.com/miyako/skills/pull/69)
and [miyako/skills#71](https://github.com/miyako/skills/pull/71).

Run the narrow regression with:

```sh
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s .github/tests -p test_string_ownership.py -v
```

The harness compiles the actual plugin, JSON helpers, dormant text wrappers,
and **full, unmodified SDK**, replacing only `gCall4D` engine dispatch. Production
Core Foundation conversions run unchanged; there is no conversion mock that
can confuse bytes with UTF-16 units. Assertions check literal ASCII, BMP,
surrogate-pair and empty content/lengths; owning property copies, independent
collection storage, replacement, rejected array destinations, shrink/clear,
nil document names, reference handoffs and balanced final cleanup. Both
allocated-empty and null-empty host models run with ASan/UBSan. Explicit
allocation tracking detects leaks (LeakSanitizer is disabled on macOS).
`OWNERSHIP_SOURCE_ROOT` can point at an extracted baseline to run the same
tests against original sources.

On macOS 26.7 arm64 / Xcode 26.6, the baseline fails with 4 leaked strings per
document-list iteration, 80 per setter scenario, and 100 owning property
results per getter scenario; null-empty hides only the empty-overwrite leaks.
The fixes pass all four scenarios in both models. The unsigned **Default**
Xcode build also succeeds for arm64 and x86_64 with output outside the checkout.
No Deployment build, signing, notarization, archives, tags, or releases are
performed. This is host-shim evidence, not a run inside 4D or a QuickTime
Automation integration test; x86_64 is built, not runtime-tested.

## Requirements & platform notes

- **Requires macOS 10.14+.** The permission check uses `AEDeterminePermissionToAutomateTarget`, guarded by an `@available(macOS 10.14, *)` check.
- **Requires a custom-signed 4D host, not a stock 4D.com download.** Automating another app via Apple Events requires the *calling* application (4D itself) to have all of the following, none of which 4D.com's own distributed build carries:
  - An `NSAppleEventsUsageDescription` key in 4D's own `Info.plist`.
  - The `com.apple.security.automation.apple-events` code-signing entitlement set to `true`.
  - Hardened Runtime + secure timestamp code signing, and Apple notarization.
- **The target is QuickTime Player *X*** — bundle identifier `com.apple.QuickTimePlayerX`, not the older `com.apple.QuickTimePlayer`.
- **Permission is checked once per 4D session, then cached.** Once a call succeeds in obtaining Automation permission, the plugin sets an in-process flag and skips the entire permission/entitlement check on every subsequent call in that session — including if you revoke Automation access for QuickTime Player via System Settings afterward. See [Error handling](#error-handling--troubleshooting).
- **`options` is optional at the language level.** `qtpc quit` can be called with no second parameter at all (see the plugin's own `TEST.4dm`). For every other action, you'll need to supply `options` with the fields that action reads (below), since a missing field is treated the same as "nothing to do" rather than a 4D error.
- **File paths must be `.platformPath`, not `.path`.** The plugin resolves `options.path` via Core Foundation's HFS path style (colon-separated), which is what 4D's `.platformPath` produces on macOS. A POSIX-style path (`.path`, slash-separated) will not resolve correctly.

### The `options` object

| Property | Type | Used by | Description |
|---|---|---|---|
| `name` | Text | `play`, `start`, `pause`, `resume`, `stop`, `present`, `save`, `close` | The target document's exact name, as returned in `status.name` or an entry of `status.names`. |
| `path` | Text | `open`, `save`, `close` | A file path in `.platformPath` format (see above). |

### The `status` object

| Property | Type | Set by | Description |
|---|---|---|---|
| `success` | Boolean | always | `true` only when the requested action actually ran to completion — see each action's notes for cases where a real effect happens but `success` is still `false`. |
| `errorMessage` | Text | permission preflight only | Explains a failed Automation-permission/entitlement check (see table below). Command-level failures (missing document, wrong options) do **not** set this — they just leave `success: false`. |
| `name` | Text | `new movie recording`, `new audio recording` | The new document's name; pass this back as `options.name` for follow-on commands. |
| `names` | Collection of Text | `open` | Names of every document currently open in QuickTime Player X (not only the one just opened). |

### Permission preflight error messages

| Condition | `status.errorMessage` |
|---|---|
| 4D's own main bundle can't be located | `failed to locate [NSBundle mainBundle]` |
| 4D's bundle has no `Info.plist` dictionary | `failed to locate [mainBundle infoDictionary]` |
| `NSAppleEventsUsageDescription` missing from 4D's `Info.plist` | `NSAppleEventsUsageDescription is missing in app info.plist` |
| `com.apple.security.automation.apple-events` entitlement missing | `com.apple.security.automation.apple-events is missing in app entitlement` |
| Entitlement present but `false` | `com.apple.security.automation.apple-events is set to false in app entitlement` |
| Entitlement `true`, but macOS hasn't yet resolved the Automation prompt for QuickTime Player X | `permission not determined` |
| Entitlement `true`, but the user previously denied Automation access | `permission denied` |

---

## New movie recording

### Syntax
```4d
status:=QuickTime Player Execute(qtpc new movie recording; options)
```

| Parameter | Type | Description |
|---|---|---|
| `options` | Object | Required as an object (its contents aren't read for this action — pass `New object`). |
| Result | Object | `status`, with `name` and `success` set on success. |

### Description
Launches QuickTime Player X if it isn't already running and starts a new movie-recording document. On success, `status.name` holds the new document's name — save it in `options.name` to control this same document with later commands (`start`, `pause`, `save`, ...). If QuickTime Player X can't be reached (see [Open](#open)'s launch-timing note, which applies here too) or the recording document can't be created, `status.success` stays `false` with no `errorMessage`.

### Example
From the plugin's own test method (`TEST.4dm`):
```4d
$options:=New object
$status:=QuickTime Player Execute(qtpc new movie recording; $options)
If ($status.success)
	$options.name:=$status.name
	$status:=QuickTime Player Execute(qtpc start; $options)
	...
End if
```

---

## New audio recording

### Syntax
```4d
status:=QuickTime Player Execute(qtpc new audio recording; options)
```

| Parameter | Type | Description |
|---|---|---|
| `options` | Object | Required as an object; contents not read. |
| Result | Object | `status`, with `name` and `success` set on success. |

### Description
Identical shape to [New movie recording](#new-movie-recording), but starts an audio-recording document instead. Same launch-timing caveat applies.

### Example
```4d
$options:=New object
$status:=QuickTime Player Execute(qtpc new audio recording; $options)
If ($status.success)
	$options.name:=$status.name
	$status:=QuickTime Player Execute(qtpc start; $options)
End if
```

---

## New screen recording

### Syntax
```4d
status:=QuickTime Player Execute(qtpc new screen recording; options)
```

| Parameter | Type | Description |
|---|---|---|
| `options` | Object | Any object; not read. |
| Result | Object | `status.success` is always `false`. |

### Description
**Not implemented.** This action currently only resets `status` and returns — it never starts a screen recording, regardless of input. Don't rely on it; there is no code path in this plugin that creates a screen-recording document today.

---

## Start

### Syntax
```4d
status:=QuickTime Player Execute(qtpc start; options)
```

| Parameter | Type | Description |
|---|---|---|
| `options.name` | Text | Name of a document previously created by `new movie recording`/`new audio recording`. |
| Result | Object | `status.success: true` if the named document was found and the start action was sent. |

### Description
Begins recording on the named document. If `options.name` is missing, or no open document matches it, `status.success` stays `false` with no `errorMessage` — this action fails silently on a bad or missing name.

### Example
```4d
$status:=QuickTime Player Execute(qtpc new movie recording; New object)
If ($status.success)
	$options:=New object("name"; $status.name)
	$status:=QuickTime Player Execute(qtpc start; $options)
End if
```

---

## Play

### Syntax
```4d
status:=QuickTime Player Execute(qtpc play; options)
```

| Parameter | Type | Description |
|---|---|---|
| `options.name` | Text | Name of an already-open document (e.g. from `status.names` after `open`). |
| Result | Object | `status.success: true` if the document was found and playback started. |

### Description
Starts (or restarts) playback of the named document. Same silent-failure behavior as `start` if the name is missing or unmatched.

### Example
From the plugin's own test method (`TEST_play.4dm`):
```4d
$options:=New object
$options.path:=Folder(fk desktop folder).file("test.mov").platformPath
$status:=QuickTime Player Execute(qtpc open; $options)
If ($status.success)
	If ($status.names.length#0)
		$options.name:=$status.names[0]
		$status:=QuickTime Player Execute(qtpc present; $options)  //full screen
		$status:=QuickTime Player Execute(qtpc play; $options)
	End if
End if
```

---

## Pause

### Syntax
```4d
status:=QuickTime Player Execute(qtpc pause; options)
```

| Parameter | Type | Description |
|---|---|---|
| `options.name` | Text | Name of the target document. |
| Result | Object | `status.success: true` if found and paused. |

### Description
Pauses playback of the named document. Same silent-failure behavior on a missing/unmatched name as `play`.

---

## Resume

### Syntax
```4d
status:=QuickTime Player Execute(qtpc resume; options)
```

| Parameter | Type | Description |
|---|---|---|
| `options.name` | Text | Name of the target document. |
| Result | Object | `status.success: true` if found and resumed. |

### Description
**Currently identical to `play`.** The plugin author's own comment on this code path notes a true "resume" action wasn't working reliably, so this action calls the same underlying selector as `play` instead. There is no functional difference today between calling `resume` and calling `play` again after a pause.

---

## Stop

### Syntax
```4d
status:=QuickTime Player Execute(qtpc stop; options)
```

| Parameter | Type | Description |
|---|---|---|
| `options.name` | Text | Name of the target document. |
| Result | Object | `status.success: true` only if the document was actually playing. |

### Description
Stops playback. **This action only applies to playback, not recording** — the plugin author's own comment notes stopping an active recording this way doesn't work; use [Save](#save)/[Close](#close) to end a recording instead. If the named document isn't currently in the "playing" state (already paused, stopped, or mid-recording), this silently no-ops: `status.success` stays `false`, with no `errorMessage`, even though nothing went wrong per se.

---

## Present

### Syntax
```4d
status:=QuickTime Player Execute(qtpc present; options)
```

| Parameter | Type | Description |
|---|---|---|
| `options.name` | Text | Name of the target document. |
| Result | Object | `status.success: true` if found and full-screen presentation started. |

### Description
Switches the named document to full-screen presentation mode.

---

## Open

### Syntax
```4d
status:=QuickTime Player Execute(qtpc open; options)
```

| Parameter | Type | Description |
|---|---|---|
| `options.path` | Text | File path in `.platformPath` format (see [Requirements](#requirements--platform-notes)). |
| Result | Object | `status.success`, and on success `status.names` (Collection of Text — every document currently open, not just this one). |

### Description
Launches QuickTime Player X if needed and asks it to open the file at `options.path`. `status.success: true` only confirms the plugin reached a running QuickTime Player X instance and sent the open request — it does **not** confirm the file was actually opened successfully (the underlying call is fire-and-forget). If you need the specific document you just opened, don't assume it's `status.names[0]`: that's only reliable if QuickTime Player X had no other documents open beforehand — otherwise, match by the file name you actually opened.

**Launch-timing note:** if QuickTime Player X wasn't already running, this plugin launches it asynchronously and checks for it immediately afterward, with no wait/retry loop. The very first call in a session can occasionally find zero running instances yet (the app hadn't finished launching) and silently fail (`success: false`, no `errorMessage`); a second, immediately-following call typically succeeds once the app has finished launching. This applies to every action that goes through the same instance lookup (`start`, `play`, `pause`, `resume`, `stop`, `present`, `save`, `close`, and the recording-start actions), not just `open`.

### Example
From the plugin's own test method (`TEST_play.4dm`):
```4d
$options:=New object
$options.path:=Folder(fk desktop folder).file("test.mov").platformPath
$status:=QuickTime Player Execute(qtpc open; $options)
If ($status.success)
	If ($status.names.length#0)
		$options.name:=$status.names[0]
	End if
End if
```

---

## Close

### Syntax
```4d
status:=QuickTime Player Execute(qtpc close; options)
```

Dispatches to the exact same handler as [Save](#save) — see that section for the full parameter table and behavior. Per the plugin's own command list, `close` is documented as being the same as `save`.

### Example
From the plugin's own test method (`TEST.4dm`):
```4d
$options.path:=Folder(fk desktop folder).file("test.mov").platformPath
$status:=QuickTime Player Execute(qtpc close; $options)
```

---

## Save

### Syntax
```4d
status:=QuickTime Player Execute(qtpc save; options)
```

| Parameter | Type | Description |
|---|---|---|
| `options.name` | Text | Name of the target document. |
| `options.path` | Text (optional) | Destination path in `.platformPath` format. |
| Result | Object | `status.success` — see the important caveat below. |

### Description
If `options.path` is supplied, saves the named document to that path and closes it; `status.success: true` on success. **If `options.path` is omitted, the document is closed without saving — but `status.success` is left `false` even though the close-without-saving did happen.** Don't treat `success: false` here as "nothing happened": check `status.names` on a follow-up call if you need to confirm the document actually closed, rather than relying on `success` for this specific no-path case.

`close` (above) calls this exact same handler — everything in this section applies to both action constants.

### Example
From the plugin's own test method (`TEST.4dm`):
```4d
$options.path:=Folder(fk desktop folder).file("test.mov").platformPath
$status:=QuickTime Player Execute(qtpc save; $options)
```

---

## Quit

### Syntax
```4d
status:=QuickTime Player Execute(qtpc quit)
```

| Parameter | Type | Description |
|---|---|---|
| `options` | Object | **Optional** — can be omitted entirely; its contents are never read. |
| Result | Object | `status.success` is always `true`. |

### Description
Terminates every running instance of QuickTime Player X. `status.success` is always `true` regardless of whether any instance was actually running or whether termination completed (`-terminate` is fire-and-forget; the plugin doesn't wait for or confirm the quit).

### Example
From the plugin's own test method (`TEST.4dm`):
```4d
$status:=QuickTime Player Execute(qtpc quit)  //QTPXがビジーである可能性もあるのでスクリプトを使用しない
```

---

## Error handling & troubleshooting

- **`errorMessage` only appears for permission/entitlement failures.** Every command-level failure (missing document name, no match, wrong playback state, `open`/`save` without a valid path) leaves `status.success: false` with no `errorMessage` — always check `success` even when you don't see an error string.
- **Permission is cached for the whole 4D session.** Once granted, the plugin never re-checks Automation permission again in that session — if you revoke access for QuickTime Player X via System Settings mid-session, the plugin won't detect it. Later calls will proceed past the (skipped) permission check and then fail wherever the actual Apple Event is sent.
- **Use `.platformPath`, not `.path`, for every file path.** The plugin expects the HFS-style (colon-separated) path that `.platformPath` produces on macOS; a POSIX `.path` string will not resolve correctly.
- **`open` succeeding doesn't guarantee the file opened.** `status.success: true` only means the open request reached a running QuickTime Player X — confirm the actual document via `status.names`.
- **`status.names[0]` isn't necessarily "the file you just opened.**" It's reliable only when QuickTime Player X had no other documents open before your `open` call — otherwise match on the real file name.
- **The very first call in a session can spuriously fail if QuickTime Player X wasn't already running.** App launch is asynchronous with no wait/retry; a retried call typically succeeds.
- **`stop` only works on playback, not recording**, and is a silent no-op if the document isn't currently playing.
- **`resume` is not a distinct action** — it currently performs the same thing as `play`.
- **`new screen recording` is unimplemented** — it always returns `success: false`.
- **Saving/closing without a `path`** (`save`/`close` with no `options.path`) does close the document, but leaves `status.success: false` — don't read that as failure.
- **This plugin only runs on a custom-signed, notarized 4D build**, not the stock 4D.com distribution — see [Requirements](#requirements--platform-notes) for the exact entitlements and `Info.plist` key needed.

---

## Quick reference

```4d
// Play a file full-screen
$options:=New object
$options.path:=Folder(fk desktop folder).file("test.mov").platformPath
$status:=QuickTime Player Execute(qtpc open; $options)
If ($status.success) & ($status.names.length#0)
	$options.name:=$status.names[0]
	$status:=QuickTime Player Execute(qtpc present; $options)
	$status:=QuickTime Player Execute(qtpc play; $options)
End if
```

```4d
// Record, then save, then quit
$status:=QuickTime Player Execute(qtpc new movie recording; New object)
If ($status.success)
	$options:=New object("name"; $status.name)
	$status:=QuickTime Player Execute(qtpc start; $options)
	If ($status.success)
		$options.path:=Folder(fk desktop folder).file("test.mov").platformPath
		$status:=QuickTime Player Execute(qtpc close; $options)  // save + close
	End if
	$status:=QuickTime Player Execute(qtpc quit)
End if
```
