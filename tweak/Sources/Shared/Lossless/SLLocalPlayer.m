#import "SLLocalPlayer.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <Network/Network.h>
#import <stdatomic.h>
#import "Core/SGCore.h"
#import "Shared/Lyrics/Lyrics.h"
#import "Shared/Player/PlayerState.h"
#import "SLNativeBar.h"

NSNotificationName const SLLocalPlayerDidChangeNotification = @"spotifyglass.lossless.localPlayerDidChange";

static _Atomic bool sg_online = true;

@interface SLLocalPlayer () <AVAudioPlayerDelegate, SGPlayerStateObserver>
@end

@implementation SLLocalPlayer {
    AVAudioPlayer *_player;
    NSArray<NSDictionary *> *_queue;
    NSInteger _index;
    NSMutableArray<NSArray *> *_targets;   // {command, token}
    nw_path_monitor_t _monitor;
    CFAbsoluteTime _startedAt;
}

+ (instancetype)shared {
    static SLLocalPlayer *shared;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        shared = [SLLocalPlayer new];
        [shared watchNetwork];
        SGAddPlayerStateObserver(shared);
    });
    return shared;
}

+ (BOOL)online {
    [self shared];
    return atomic_load(&sg_online);
}

- (void)watchNetwork {
    _monitor = nw_path_monitor_create();
    nw_path_monitor_set_queue(_monitor, dispatch_get_global_queue(QOS_CLASS_UTILITY, 0));
    nw_path_monitor_set_update_handler(_monitor, ^(nw_path_t path) {
        atomic_store(&sg_online, nw_path_get_status(path) == nw_path_status_satisfied);
    });
    nw_path_monitor_start(_monitor);
}

- (BOOL)active { return _player != nil; }
- (BOOL)playing { return _player.isPlaying; }
- (NSTimeInterval)position { return _player.currentTime; }
- (NSTimeInterval)duration { return _player.duration; }
- (NSDictionary *)currentEntry { return _player ? _queue[(NSUInteger)_index] : nil; }
- (NSArray<NSDictionary *> *)queue { return _queue ?: @[]; }
- (NSInteger)index { return _index; }

- (NSString *)currentPath {
    return _player ? _queue[(NSUInteger)_index][@"path"] : nil;
}

- (void)playQueue:(NSArray<NSDictionary *> *)entries index:(NSUInteger)index {
    _queue = [entries copy];
    [self start:(NSInteger)index];
}

- (BOOL)start:(NSInteger)index {
    if (index < 0 || index >= (NSInteger)_queue.count) { [self stop]; return NO; }
    NSDictionary *entry = _queue[(NSUInteger)index];
    NSError *error = nil;
    AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:entry[@"path"]] error:&error];
    if (!player) {
        SGLog(@"lossless: can't play %@ (%@)", entry[@"path"], error.localizedDescription);
        // A file iOS can't open: try the next one rather than stop dead.
        return index + 1 < (NSInteger)_queue.count ? [self start:index + 1] : ([self stop], NO);
    }
    // Spotify's own sound stops first: two players in one app would play over each other.
    id<SPTPlayer> spotify = SGKaraokePlayer();
    SPTPlayerState *state = spotify.state;
    SLVirtualBypass(YES);   // the native player's own pause is not this player's
    if (state.isPlaying && !state.isPaused) [spotify pause:nil];
    SLVirtualBypass(NO);
    AVAudioSession *session = AVAudioSession.sharedInstance;
    [session setCategory:AVAudioSessionCategoryPlayback mode:AVAudioSessionModeDefault options:0 error:nil];
    [session setActive:YES error:nil];
    [_player stop];
    player.delegate = self;
    [player prepareToPlay];
    [player play];
    _player = player;
    _index = index;
    _startedAt = CFAbsoluteTimeGetCurrent();
    [self installCommands];
    [self publishNowPlaying];
    [NSNotificationCenter.defaultCenter postNotificationName:SLLocalPlayerDidChangeNotification object:nil];
    return YES;
}

- (void)stop {
    [_player stop];
    _player = nil;
    for (NSArray *pair in _targets) [(MPRemoteCommand *)pair[0] removeTarget:pair[1]];
    _targets = nil;
    MPNowPlayingInfoCenter.defaultCenter.nowPlayingInfo = nil;
    [NSNotificationCenter.defaultCenter postNotificationName:SLLocalPlayerDidChangeNotification object:nil];
}

#pragma mark lock screen

- (void)publishNowPlaying {
    if (!_player) return;
    NSDictionary *entry = _queue[(NSUInteger)_index];
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    info[MPMediaItemPropertyTitle] = entry[@"title"] ?: @"";
    if ([entry[@"artist"] length]) info[MPMediaItemPropertyArtist] = entry[@"artist"];
    info[MPMediaItemPropertyPlaybackDuration] = @(_player.duration);
    info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = @(_player.currentTime);
    info[MPNowPlayingInfoPropertyPlaybackRate] = @(_player.isPlaying ? 1.0 : 0.0);
    NSString *coverPath = entry[@"cover"];
    UIImage *cover = [coverPath length] ? [UIImage imageWithContentsOfFile:coverPath] : nil;
    if (cover) info[MPMediaItemPropertyArtwork] = [[MPMediaItemArtwork alloc] initWithBoundsSize:cover.size requestHandler:^UIImage *(CGSize size) { return cover; }];
    MPNowPlayingInfoCenter.defaultCenter.nowPlayingInfo = info;
}

- (void)installCommands {
    if (_targets) return;
    _targets = [NSMutableArray array];
    MPRemoteCommandCenter *center = MPRemoteCommandCenter.sharedCommandCenter;
    __weak SLLocalPlayer *weak = self;
    void (^add)(MPRemoteCommand *, MPRemoteCommandHandlerStatus (^)(MPRemoteCommandEvent *)) = ^(MPRemoteCommand *command, MPRemoteCommandHandlerStatus (^handler)(MPRemoteCommandEvent *)) {
        command.enabled = YES;
        [self->_targets addObject:@[command, [command addTargetWithHandler:handler]]];
    };
    typedef MPRemoteCommandHandlerStatus Status;
    add(center.playCommand, ^Status(MPRemoteCommandEvent *event) { [weak resume]; return MPRemoteCommandHandlerStatusSuccess; });
    add(center.pauseCommand, ^Status(MPRemoteCommandEvent *event) { [weak pause]; return MPRemoteCommandHandlerStatusSuccess; });
    add(center.togglePlayPauseCommand, ^Status(MPRemoteCommandEvent *event) { [weak toggle]; return MPRemoteCommandHandlerStatusSuccess; });
    add(center.nextTrackCommand, ^Status(MPRemoteCommandEvent *event) {
        return [weak skip:1] ? MPRemoteCommandHandlerStatusSuccess : MPRemoteCommandHandlerStatusNoActionableNowPlayingItem; });
    add(center.previousTrackCommand, ^Status(MPRemoteCommandEvent *event) {
        return [weak skip:-1] ? MPRemoteCommandHandlerStatusSuccess : MPRemoteCommandHandlerStatusNoActionableNowPlayingItem; });
    add(center.changePlaybackPositionCommand, ^Status(MPRemoteCommandEvent *event) {
        [weak seek:((MPChangePlaybackPositionCommandEvent *)event).positionTime];
        return MPRemoteCommandHandlerStatusSuccess; });
}

- (void)changed {
    [NSNotificationCenter.defaultCenter postNotificationName:SLLocalPlayerDidChangeNotification object:nil];
}
- (void)resume { _startedAt = CFAbsoluteTimeGetCurrent(); [_player play]; [self publishNowPlaying]; [self changed]; }
- (void)pause { [_player pause]; [self publishNowPlaying]; [self changed]; }
- (void)toggle { if (_player.isPlaying) [self pause]; else [self resume]; }
- (void)seek:(NSTimeInterval)seconds {
    _player.currentTime = MAX(0, MIN(seconds, _player.duration));
    [self publishNowPlaying];
    [self changed];
}

// +1 the next download, -1 the one before; past the first seconds of a song, back restarts it, as everywhere.
- (BOOL)skip:(NSInteger)direction {
    if (!_player) return NO;
    if (direction < 0 && (_player.currentTime > 3 || _index == 0)) { [self seek:0]; return YES; }
    return [self start:_index + direction];
}

#pragma mark delegates

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    if (player != _player) return;
    [self start:_index + 1];   // the next download, or the end
}

// Spotify plays again (its own play button, a Connect device): this one gives way.
- (void)playerStateDidChange:(SPTPlayerState *)state {
    // The native player shows this one's own state (SLNativeBar.x): not Spotify playing again.
    if (SLVirtualStateIs(state)) return;
    // Not in the first seconds: Spotify's own pause is still on its way then.
    if (CFAbsoluteTimeGetCurrent() - _startedAt < 3) return;
    if (_player.isPlaying && state.isPlaying && !state.isPaused) [self stop];
}

@end
