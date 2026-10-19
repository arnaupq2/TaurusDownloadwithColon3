# Core

12 files, 22 notes, moved out of the code (tweak/Sources/Core/).

## `Core/SGBackdrop.h`

**file overview** (was L1)
> The cover art as a background: shrunk until no shape of it survives, blurred, under a scrim
> darkening towards the bottom. Native/Player/Player.x puts one behind the player, Native/Playlist/Playlist.x
> behind the playlist header.

## `Core/SGBackdrop.m`

**`static const CGFloat kCoverSample = 48;`** (was L3)
> Small enough that no shape of the cover survives the scaling back up, large enough to keep the
> colours where they were in it.

## `Core/SGCore.h`

**file overview** (was L1)
> What every source file of the mod builds on. Feature-specific API lives in the feature's own
> header under Shared/, Native/ or Redesigned/, next to the keys it reads.

## `Core/SGFlagForce.h`

**file overview** (was L1)
> The flags something of the mod's forces, gathered in one place so that the flag provider
> (Shared/Flags/Flags.x) and the flag rows of the settings pages (Settings/SGModPage.m) ask here
> rather than knowing every feature that forces one: the ad blocking, the lyrics sources, the redesign.
>
> A forcer answers a flag key with the value it forces, or nil. `atLaunch` answers for the running
> app, from the switches as they were at launch; `locked`, which may be nil, answers for a settings
> row, from the switches as they are stored now, and a row it answers for shows that value and takes
> no touch. A forcer that `beatsOverride` is asked before an override from the All flags page, the
> rest after it; within each group in the order they were registered.
> Threading: register from a %ctor or a constructor, before Spotify reads a flag; ask from any thread.

**`id SGLockedFlagValue(NSString *key, BOOL *beatsOverride);`** (was L19)
> The value a settings row is locked at, nil when none; `beatsOverride` says whether an override
> from the All flags page gives way to it.

## `Core/SGGlass.h`

**`(end of file)`** (was L13)
> The areas each look keeps transparent are its own: Native/Appearance/Repaint.h and
> Redesigned/Kit/SGRRepaint.h.

## `Core/SGGlass.m`

**`UIVisualEffect *SGGlassEffect(void) {`** (was L4)
> +effectWithStyle: is the only initialiser UIGlassEffect has; a bare -init leaves the material
> unresolved and the pane renders as a plain blur, while the capsule shape, which is the view's
> own property, still comes out right. Spotify's own Reprise glass builds its effect the same way.

**`glass.layer.zPosition = -1;`** (was L16)
> A pane goes in at index 0, but a host that rebuilds its content puts that in at index 0 too
> and the pane would end up over it. Depth keeps a pane behind whatever the host draws.

## `Core/SGPrefs.h`

**file overview** (was L1)
> The mod's own settings, in Spotify's NSUserDefaults. Every key is declared by the feature that
> owns it, in that feature's header, and starts with "spotifyglass.": Reset all settings on the Mod
> page sweeps by that prefix and knows no key by name. The accessors here are what the hooks and the
> pages share.

**`#define SGKeyStock @"spotifyglass.stock"`** (was L7)
> Set by the reset, after the sweep: an unset switch then reads off rather than the way the build
> came, so a reset is stock Spotify, for every switch there is and every one added later.

**`NSInteger SGInt(NSString *key, NSInteger fallback);`** (was L16)
> A setting picked from a list, stored as the index into it; the choice rows of
> Settings/SGModPage.h write these.

**`extern NSString *const SGFlagOverridePrefix;`** (was L21)
> Overrides of Spotify's remote-config flags, stored under SGFlagOverridePrefix + flag key;
> nil keeps Spotify's value. Shared/Flags reads them, the All flags page and flag rows write them.

**`void SGMigrateKey(NSString *from, NSString *to);`** (was L27)
> Moves a stored setting to another key, once: nothing happens unless `from` is set and `to` is not.
> A feature that leaves Redesigned/ for Shared/ loses the ".redesign." from its keys this way, so the
> switch someone already flipped is still the one they get.

## `Core/SGRebind.h`

**file overview** (was L1)
> Hooks a C function Spotify's executable imports, by pointing the executable's own import slot for it
> (its __got, or __la_symbol_ptr in an older build) at a replacement. Only calls Spotify's own code
> makes go through the new function; the system's frameworks keep calling the original. This is the
> fishhook technique, kept to the main executable, for the few places no Objective-C method stands
> between Spotify and a system call (the audio output unit Music Haptics listens to).
>
> Threading: call from a %ctor, before Spotify has run; the slots are written without a lock.

**`BOOL SGRebindImport(const char *symbol, void *replacement, void **original);`** (was L10)
> Returns YES when at least one slot named `symbol` (without the leading underscore) was repointed.
> `original` receives what the first slot held, which is what the replacement calls on.

## `Core/SGRebind.m`

**`static BOOL writeSlot(void **slot, void *value, BOOL readOnly) {`** (was L19)
> Writes one pointer, making its page writable first; a page dyld made read only after binding
> (__DATA_CONST, __AUTH_CONST) is copied and made read only again.

## `Core/SGUIMode.h`

**file overview** (was L1)
> Which of the two looks runs: Spotify's own screens with the mod's tweaks on them (Native/), or the
> redesign (Redesigned/), picked by Redesigned UI in Appearance. What does not draw on Spotify's
> screens (Shared/) runs under both. The switch is read once, the first time anything asks, so the
> hooks, the flags and the pages see one answer for the whole launch and a change waits for the restart.
>
> Every hook file of Native/ starts its %ctor with `if (!SGNativeUI()) return;`, every one of
> Redesigned/ with `if (!SGRedesignedUI()) return;`: the two never run together, which is what lets
> each hook the same Spotify class in its own way.
> Threading: safe from any thread.

**`BOOL SGRedesignAvailable(void);`** (was L14)
> The redesign is Liquid Glass, and Liquid Glass is UIGlassEffect, which the system renders and which
> no older OS can be given. Below iOS 26 the glass calls in Core/SGGlass.m and Redesigned/Kit/SGRGlass.m
> fall back to a blur, so the redesign does not refuse to run, it runs untested against an older UIKit
> and hangs its layout (issue #37, iOS 17: a scene-update watchdog). So it is offered only where its
> material exists, and below that the native look is the whole mod. Everything this answers NO to
> leaves the switch, the tour's card and the redesign's settings pages out, whatever is stored.

**`BOOL SGRedesignedUIStored(void);`** (was L24)
> The stored switch rather than the launch's, for settings pages opened after it was flipped: they
> show what the restart will bring.

## `Core/SGUIMode.m`

**`return SGRedesignAvailable() && SGFlag(SGKeyRedesign, YES);`** (was L25)
> The stored switch is left alone rather than turned off: a phone updated to iOS 26 gets the
> redesign it was last asked for back.

## `Core/SGViewTree.h`

**`UIStackView *SGRowIn(UIView *host);`** (was L8)
> The first wide stack view under `host` with at least two arranged children: a player row, or
> the row of items in the tab bar.

**`BOOL SGIsBaseSurface(CGColorRef color);`** (was L19)
> Spotify's base surface: the neutral #121212 it paints its pages with, or the black AMOLED turns
> that into.
