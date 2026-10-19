# Headers (Spotify runtime headers)

4 files, 5 notes, moved out of the code (tweak/Sources/Headers/).

## `Headers/SPTEncoreIconView.h`

**file overview** (was L1)
> Spotify's glyph view, from SpotifyShared.framework. It bakes its colour into what it draws, so
> tintColor never reaches it and setForegroundColor: is the way in.

## `Headers/SPTLinkDispatcherImplementation.h`

**file overview** (was L1)
> Spotify's link dispatcher, a singleton the app builds at startup; the route the app itself takes
> for a link it opens.

## `Headers/SPTNowPlayingPlaybackController.h`

**file overview** (was L1)
> The object the player's own controls drive: the seek amounts are named in seconds by the
> selectors themselves, so a gesture needs no unit of its own.

## `Headers/SPTPlayer.h`

**file overview** (was L1)
> SPTEsperantoPlayer, the app's player, and the state it reports.
> The URIs are typed id: the runtime says only that they are objects, so a reader takes NSURL or NSString.

**`- (id)pause:(id)options;`** (was L42)
> The commands below take Spotify's options object, nil for the defaults, and return the command's
> pending result.
