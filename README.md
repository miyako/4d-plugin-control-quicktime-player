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

---

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
