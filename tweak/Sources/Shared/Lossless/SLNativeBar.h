// SLNativeBar.x: Spotify's native now playing bar and player show and control the Downloads player.
//
// SLLocalPlayer plays the file; this makes Spotify's own screens believe the song is theirs. The state the
// native now playing platform reports (-[StatefulPlayerImplementation player:stateDidChange:]) is swapped for a
// state of the download while it plays: a subclass of SPTPlayerState and SPTPlayerTrack made at runtime that
// answers the track (its local-file address, names and cover), paused, position, length and the songs before and
// after it. The player's controls (pause, resume, skip, seek) and the playback controller's are sent to
// SLLocalPlayer while a download is loaded. When Spotify plays by itself again the swap stops.
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
/// Whether `state` is one this file made.
BOOL SLVirtualStateIs(id _Nullable state);
/// The state the platform's hook passes on: `real` untouched, or the download's while one is loaded.
id _Nullable SLVirtualStateFilter(id _Nullable real);
/// The hook tells where to push a state of the download to.
void SLVirtualAttach(id stateful, id player);
/// While set, Spotify's player controls are not sent to the Downloads player (SLLocalPlayer pausing Spotify).
void SLVirtualBypass(BOOL on);
NS_ASSUME_NONNULL_END
