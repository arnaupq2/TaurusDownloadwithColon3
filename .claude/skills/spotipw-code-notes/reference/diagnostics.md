# Diagnostics

4 files, 7 notes, moved out of the code (tweak/Sources/Diagnostics/).

## `Diagnostics/Diagnostics.h`

**file overview** (was L1)
> Screen dumps for FLEX builds: the visible screen's view tree, served over the phone's loopback
> and logged when the app goes to the background.

## `Diagnostics/Diagnostics.x`

**file overview** (was L1)
> Screen dumps for FLEX builds. The tree of the visible screen is served over HTTP on the phone's
> loopback (fetched from the Mac through `iproxy` over USB), and also logged when the app goes to
> the background or the full player appears.

**`static NSString *describeValue(id value) {`** (was L46)
> What the mod has set, so a recorded tree says whether it shows Spotify as it came or a screen some
> switch has already changed: the stock marker Reset all settings leaves, then every key of the mod's
> with its value. The counters, the update check, the signing warning, the tour and the Musixmatch
> token belong to the install rather than to a choice, as in About/Backup.m, and are left out.
> scripts/record-session.py reads this section to call a snapshot clean or not.

## `Diagnostics/PlayerState.x`

**file overview** (was L1)
> Temporary diagnostics (debug builds only): what the player core says about the track it is on,
> for the reports that songs cannot be paused or scrubbed while podcasts can. Spotify greys its
> pause button and its scrubber from the state's restrictions, and nothing about them reaches the
> system log, so the state object is read out here: every property and object ivar of it, the
> restrictions inside it one level deeper, and the track's metadata, which names an ad.
>
> A line arrives on every track change and whenever the readout changes, at most one a second.

**`static NSString *summarize(id object, NSUInteger depth) {`** (was L33)
> Every property the class chain declares, then the object ivars no property covers, so a restriction
> set kept in an ivar alone still shows.

**`%hook _TtC28EncoreConsumerMobile_BaseKit14PlayButtonView`** (was L98)
> Who greys the button out: Encore draws it disabled at half alpha, and the caller says which of
> Spotify's units decided it.

## `Diagnostics/SGHangSampler.h`

**file overview** (was L1)
> FLEX builds: what the main thread is doing while it is stuck. While a watch is running, a background
> thread pings the main queue every 10 ms; once a ping has waited `kThreshold` (120 ms) the main thread
> is suspended for an instant, its stack walked by frame pointers, resumed, and the frames logged as
> "hang <reason> <n>/<m>" with the image and symbol of each, or the address in Spotify's own binary for
> scripts to symbolicate against its symbol table. A long stall is sampled again every 80 ms, up to 12
> samples a stall.
>
> Threading: start and stop on the main thread. Watches nest; the sampler runs while any is open.
