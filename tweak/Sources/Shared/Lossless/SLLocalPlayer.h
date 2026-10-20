// Plays a downloaded file by itself, with no network: the file, its title, artist and cover are all on the phone.
// Spotify cannot stream a song with no connection, and the Lossless engine plays the file only on top of Spotify's
// own sound, so offline (or for a file that is not linked to a Spotify song) the Downloads page plays the file
// here: AVAudioPlayer, with the lock screen's now playing card and its buttons. Spotify is paused first, and this
// stops when Spotify plays.
//
// Main thread only.
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

extern NSNotificationName const SLLocalPlayerDidChangeNotification;

@interface SLLocalPlayer : NSObject
+ (instancetype)shared;
/// Whether the phone has a connection right now (the path monitor's last word; yes until it has spoken).
+ (BOOL)online;
/// `entries`: path, title, artist, cover (a file path, or empty). Plays entries[index], then the ones after it.
- (void)playQueue:(NSArray<NSDictionary *> *)entries index:(NSUInteger)index;
- (void)stop;
- (void)pause;
- (void)resume;
- (void)seek:(NSTimeInterval)seconds;
/// +1 the next download, -1 the one before (back restarts a song past its first seconds). NO when there is none.
- (BOOL)skip:(NSInteger)direction;
@property (nonatomic, readonly, nullable) NSString *currentPath;
/// A song is loaded (playing or paused).
@property (nonatomic, readonly) BOOL active;
@property (nonatomic, readonly) BOOL playing;
@property (nonatomic, readonly) NSTimeInterval position, duration;
/// path, title, artist, album, cover of the song, and of the ones around it; nil when nothing is loaded.
@property (nonatomic, readonly, nullable) NSDictionary *currentEntry;
@property (nonatomic, readonly) NSArray<NSDictionary *> *queue;
@property (nonatomic, readonly) NSInteger index;
@end

NS_ASSUME_NONNULL_END
