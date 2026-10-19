---
name: spotipw-code-notes
description: The explanations, reverse-engineering notes and traps that used to sit in the spoti.pw Spotify tweak's code comments, organised by layer and file. Use when reading or changing tweak/Sources to recover why a hook exists, what Spotify class, selector or recorded view tree it targets, and what it must not do; also use it as the reference for the house style when adding code.
---

# spoti.pw code notes

The spoti.pw tweak (`spotifyglass`) injects into the decrypted Spotify app. Its code deliberately
carries no long comments: the paragraphs that explained *why* each hook exists, which Spotify class,
selector, key or recorded view tree it was proved against, and the traps it avoids were moved here,
verbatim. **`AGENTS.md` at the repo root is the front door** — read it for the architecture, the
layer rule and the workflow. This skill is where the per-file detail behind it lives.

## How to use it

- Find the note for a file with the path, e.g. `Redesigned/Lyrics/SGRKaraokeView.m`, as a heading in
  the matching reference file below.
- Each note is a blockquote preceded by what it documented: the following declaration or code line,
  or **file overview** for the header note at the top of a file. The `was L<n>` is the line in the
  pre-move file (`git show HEAD:<path>` still has the comments in place).
- Grep the reference files for a class, selector, key or tree path (`trees/clean/...`) to find every
  place it is discussed.

## The layers

Imports run one way: `Core <- Settings <- Shared <- Native | Redesigned <- App`. Native and Redesigned
never import each other. `scripts/check-layers.sh` fails a build that breaks it.

| Reference | Layer | What it covers |
| --- | --- | --- |
| [core.md](reference/core.md) | `Core/` | prefs, UI-mode gate, glass, view-tree, rebinding, flag forcing |
| [settings.md](reference/settings.md) | `Settings/` | the Mod Settings row/page framework and styling |
| [shared.md](reference/shared.md) | `Shared/` | behaviour either look uses: ads, privacy, lyrics, gestures, flags, Speed, Live Activity |
| [native.md](reference/native.md) | `Native/` | Spotify's own screens tweaked (native look only) |
| [redesign.md](reference/redesign.md) | `Redesigned/` | the mod's own Liquid Glass look (iOS 26 only) |
| [app.md](reference/app.md) | `App/` | Mod Settings root, combined pages, Mod page, tour |
| [headers.md](reference/headers.md) | `Headers/` | Spotify runtime headers the tweak calls |
| [diagnostics.md](reference/diagnostics.md) | `Diagnostics/` | the `[spotifyglass]` log and view-tree dumps |

`core.md` = 22 notes, `settings.md` = 38, `shared.md` = 408, `native.md` = 89, `redesign.md` = 523,
`app.md` = 36, `headers.md` = 5, `diagnostics.md` = 7.

## Things the notes keep repeating

- **Prove it against the tree or the binary.** A class or selector is only real if it is in a recorded
  tree (`trees/`) or the Spotify binary. The notes name the tree path (`trees/clean/...:line`) they
  were checked against.
- **Two looks, never both.** A switch in `Mod Settings -> Appearance` picks Native or Redesigned once
  at launch. Native tweaks are gated `if (!SGNativeUI()) return;`, the redesign's
  `if (!SGRedesignedUI()) return;`. Anything that does not draw on Spotify's screens is in `Shared/`
  and runs under both.
- **The redesign needs iOS 26.** `SGRedesignAvailable()` holds it there: below 26 both
  `SGRedesignedUI()` and `SGRedesignedUIStored()` answer NO whatever is stored.
- **Switches are read at launch** — a settings change needs an app restart.
- **Traps** (also in `AGENTS.md`): push onto Spotify's nav stack only via a `SPTPageController`; never
  set `hidden` inside an `OverflowStackView`/Encore stack (use alpha); a 60 Hz `CADisplayLink` drags
  the player's 120 Hz down; glass outside Spotify's nav stacks inherits the system appearance, so set
  `overrideUserInterfaceStyle = UIUserInterfaceStyleDark` on the mod's own panes.
