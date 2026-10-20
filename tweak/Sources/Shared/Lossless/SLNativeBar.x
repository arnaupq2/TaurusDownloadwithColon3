// SLNativeBar.h says what this does. Everything about Spotify's classes here is by name and answered at runtime:
// the subclasses are made when first needed, a missing class or selector leaves Spotify's own state untouched,
// and nothing is sent to a class that does not answer.
#import <objc/runtime.h>
#import <objc/message.h>
#import "Core/SGCore.h"
#import "Headers/SPTNowPlayingPlaybackController.h"
#import "Headers/SPTPlayer.h"
#import "Shared/LocalFiles/LocalFiles.h"
#import "Shared/Player/PlayerState.h"
#import "SLLocalPlayer.h"
#import "SLNativeBar.h"
#import "SLNativeLocal.h"

static Class sg_trackClass, sg_stateClass;
static const void *kBag = &kBag;
static __weak id sg_stateful, sg_statefulPlayer;
static SPTPlayerState *sg_base;          // the last state Spotify itself reported
static CFAbsoluteTime sg_lastEvent;      // the last time the Downloads player changed
static BOOL sg_bypass;
static NSMutableDictionary<NSString *, id> *sg_tracks;   // path -> virtual track

static NSDictionary *bagOf(id object) { return objc_getAssociatedObject(object, kBag); }

static void onMain(dispatch_block_t block) {
    if (NSThread.isMainThread) block();
    else dispatch_async(dispatch_get_main_queue(), block);
}

void SLVirtualBypass(BOOL on) { sg_bypass = on; }
BOOL SLVirtualStateIs(id state) { return sg_stateClass && [state isKindOfClass:sg_stateClass]; }

// A download is loaded and Spotify's controls belong to it.
static BOOL mine(void) { return !sg_bypass && SLLocalPlayer.shared.active; }

#pragma mark - the classes

static void add(Class cls, const char *selector, const char *types, id block) {
    class_addMethod(cls, sel_registerName(selector), imp_implementationWithBlock(block), types);
}

static BOOL buildClasses(void) {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        Class trackSuper = objc_getClass("SPTPlayerTrack"), stateSuper = objc_getClass("SPTPlayerState");
        if (!trackSuper || !stateSuper) return;
        Class track = objc_allocateClassPair(trackSuper, "SGVirtualPlayerTrack", 0);
        Class state = objc_allocateClassPair(stateSuper, "SGVirtualPlayerState", 0);
        if (!track || !state) return;

        add(track, "URI", "@@:", ^id(id self) { return bagOf(self)[@"url"]; });
        add(track, "artistURI", "@@:", ^id(id self) { return nil; });
        add(track, "artistName", "@@:", ^id(id self) { return bagOf(self)[@"metadata"][@"artist_name"]; });
        add(track, "trackTitle", "@@:", ^id(id self) { return bagOf(self)[@"metadata"][@"title"]; });
        add(track, "provider", "@@:", ^id(id self) { return nil; });
        add(track, "metadata", "@@:", ^id(id self) { return bagOf(self)[@"metadata"]; });
        objc_registerClassPair(track);

        add(state, "track", "@@:", ^id(id self) { return bagOf(self)[@"track"]; });
        add(state, "contextURI", "@@:", ^id(id self) { return nil; });
        add(state, "options", "@@:", ^id(id self) { return [bagOf(self)[@"base"] respondsToSelector:@selector(options)] ? [bagOf(self)[@"base"] options] : nil; });
        add(state, "sleepTimer", "@@:", ^id(id self) { return nil; });
        add(state, "isPaused", "B@:", ^BOOL(id self) { return ![bagOf(self)[@"playing"] boolValue]; });
        add(state, "isPlaying", "B@:", ^BOOL(id self) { return YES; });
        add(state, "isLoading", "B@:", ^BOOL(id self) { return NO; });
        // Live: the bar and the scrubber read it as they draw.
        add(state, "position", "d@:", ^double(id self) { return SLLocalPlayer.shared.active ? SLLocalPlayer.shared.position : [bagOf(self)[@"asOf"] doubleValue]; });
        add(state, "positionAsOfTimestamp", "d@:", ^double(id self) { return [bagOf(self)[@"asOf"] doubleValue]; });
        add(state, "duration", "d@:", ^double(id self) { return [bagOf(self)[@"duration"] doubleValue]; });
        add(state, "playbackSpeed", "d@:", ^double(id self) { return 1; });
        add(state, "future", "@@:", ^id(id self) { return bagOf(self)[@"future"]; });
        add(state, "reverse", "@@:", ^id(id self) { return bagOf(self)[@"reverse"]; });
        objc_registerClassPair(state);
        sg_trackClass = track;
        sg_stateClass = state;
    });
    return sg_trackClass && sg_stateClass;
}

#pragma mark - what they hold

// The cover where the local file code's image loader reads one (SGLocalFileCoversDirectory), as its address.
static NSString *coverAddress(NSString *cover) {
    if (!cover.length || ![NSFileManager.defaultManager fileExistsAtPath:cover]) return nil;
    NSString *directory = SGLocalFileCoversDirectory();
    [NSFileManager.defaultManager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *name = [@"download-" stringByAppendingString:cover.lastPathComponent];
    NSString *copy = [directory stringByAppendingPathComponent:name];
    if (![NSFileManager.defaultManager fileExistsAtPath:copy]) [NSFileManager.defaultManager copyItemAtPath:cover toPath:copy error:nil];
    return SGLocalFileCoverURL(copy);
}

static id trackFor(NSDictionary *entry) {
    NSString *path = entry[@"path"];
    if (!sg_tracks) sg_tracks = [NSMutableDictionary dictionary];
    id found = sg_tracks[path];
    if (found) return found;
    NSString *uri = SLNativeLocalURI(entry);
    if (!uri) return nil;
    NSDictionary *names = SGLocalFileInfo(uri);   // the names, with the user's edits over them
    NSMutableDictionary *metadata = [NSMutableDictionary dictionary];
    metadata[@"title"] = names[@"title"] ?: entry[@"title"] ?: @"";
    metadata[@"artist_name"] = names[@"artist"] ?: entry[@"artist"] ?: @"";
    if ([entry[@"album"] length]) metadata[@"album_title"] = entry[@"album"];
    NSString *cover = coverAddress(entry[@"cover"]);
    if (cover) for (NSString *field in @[@"image_small_url", @"image_url", @"image_large_url", @"image_xlarge_url"]) metadata[field] = cover;
    id track = [sg_trackClass alloc];
    objc_setAssociatedObject(track, kBag, @{@"url": [NSURL URLWithString:uri] ?: uri, @"metadata": metadata}, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    sg_tracks[path] = track;
    return track;
}

static NSArray *tracksAround(NSArray<NSDictionary *> *queue, NSInteger from, NSInteger step, NSInteger count) {
    NSMutableArray *tracks = [NSMutableArray array];
    for (NSInteger i = from + step; i >= 0 && i < (NSInteger)queue.count && (NSInteger)tracks.count < count; i += step) {
        id track = trackFor(queue[(NSUInteger)i]);
        if (track) [tracks addObject:track];
    }
    return tracks;
}

static id makeState(void) {
    SLLocalPlayer *player = SLLocalPlayer.shared;
    NSDictionary *entry = player.currentEntry;
    if (!entry || !buildClasses()) return nil;
    id track = trackFor(entry);
    if (!track) return nil;
    id state = [sg_stateClass alloc];
    NSMutableDictionary *bag = [@{@"track": track, @"playing": @(player.playing), @"asOf": @(player.position),
                                  @"duration": @(player.duration),
                                  @"future": tracksAround(player.queue, player.index, 1, 20),
                                  @"reverse": tracksAround(player.queue, player.index, -1, 20)} mutableCopy];
    if (sg_base) bag[@"base"] = sg_base;
    objc_setAssociatedObject(state, kBag, bag, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return state;
}

#pragma mark - into Spotify's platform

void SLVirtualAttach(id stateful, id player) {
    sg_stateful = stateful;
    sg_statefulPlayer = player;
}

id SLVirtualStateFilter(id real) {
    if (!real || SLVirtualStateIs(real)) return real;
    if ([real isKindOfClass:objc_getClass("SPTPlayerState")]) sg_base = real;
    if (!SLLocalPlayer.shared.active) return real;
    SPTPlayerState *state = real;
    // Spotify plays by itself again (its own play, a Connect device): the download gives way.
    if (state.isPlaying && !state.isPaused && CFAbsoluteTimeGetCurrent() - sg_lastEvent > 3) {
        dispatch_async(dispatch_get_main_queue(), ^{ [SLLocalPlayer.shared stop]; });
        return real;
    }
    return makeState() ?: real;
}

// Tells the platform the download's state (or Spotify's own again once it ended), as if the player had reported it.
static void push(void) {
    id stateful = sg_stateful, player = sg_statefulPlayer;
    SEL report = @selector(player:stateDidChange:);
    if (!stateful || ![stateful respondsToSelector:report]) return;
    id state = SLLocalPlayer.shared.active ? makeState() : sg_base;
    if (!state) return;
    ((void (*)(id, SEL, id, id))objc_msgSend)(stateful, report, player, state);
}

#pragma mark - Spotify's controls go to the download

%hook SPTEsperantoPlayer
- (id)pause:(id)options {
    if (!mine()) return %orig;
    onMain(^{ [SLLocalPlayer.shared pause]; });
    return nil;
}
- (id)resume:(id)options {
    if (!mine()) return %orig;
    onMain(^{ [SLLocalPlayer.shared resume]; });
    return nil;
}
- (id)seekTo:(double)seconds {
    if (!mine()) return %orig;
    onMain(^{ [SLLocalPlayer.shared seek:seconds]; });
    return nil;
}
- (id)skipToNextTrackWithOptions:(id)options {
    if (!mine()) return %orig;
    onMain(^{ [SLLocalPlayer.shared skip:1]; });
    return nil;
}
- (id)skipToPreviousTrackWithOptions:(id)options {
    if (!mine()) return %orig;
    onMain(^{ [SLLocalPlayer.shared skip:-1]; });
    return nil;
}
- (id)skipToNextTrackWithOptions:(id)options track:(id)track {
    if (!mine()) return %orig;
    onMain(^{
        // A song picked from the queue: how far ahead it is.
        NSString *uri = SGURIString([track respondsToSelector:@selector(URI)] ? [track URI] : nil);
        NSArray<NSDictionary *> *queue = SLLocalPlayer.shared.queue;
        for (NSInteger i = SLLocalPlayer.shared.index + 1; i < (NSInteger)queue.count; i++) {
            if ([SLNativeLocalURI(queue[(NSUInteger)i]) isEqualToString:uri]) {
                [SLLocalPlayer.shared skip:i - SLLocalPlayer.shared.index];
                return;
            }
        }
        [SLLocalPlayer.shared skip:1];
    });
    return nil;
}
- (void)skipToNextTrack {
    if (!mine()) { %orig; return; }
    onMain(^{ [SLLocalPlayer.shared skip:1]; });
}
%end

// The bar's and the player's buttons go through the playback controller, which asks the state what is allowed.
%hook SPTNowPlayingPlaybackControllerImplementation
- (void)setPaused:(BOOL)paused {
    if (!mine()) { %orig; return; }
    onMain(^{ if (paused) [SLLocalPlayer.shared pause]; else [SLLocalPlayer.shared resume]; });
}
- (void)skipToNextWhileDragging:(BOOL)dragging {
    if (!mine()) { %orig; return; }
    onMain(^{ [SLLocalPlayer.shared skip:1]; });
}
- (void)skipToPreviousWhileDragging:(BOOL)dragging {
    if (!mine()) { %orig; return; }
    onMain(^{ [SLLocalPlayer.shared skip:-1]; });
}
- (void)seekForwardBySeconds:(double)seconds {
    if (!mine()) { %orig; return; }
    onMain(^{ [SLLocalPlayer.shared seek:SLLocalPlayer.shared.position + seconds]; });
}
- (void)seekBackwardBySeconds:(double)seconds {
    if (!mine()) { %orig; return; }
    onMain(^{ [SLLocalPlayer.shared seek:SLLocalPlayer.shared.position - seconds]; });
}
- (BOOL)canSkipNext { return mine() ? YES : %orig; }
- (BOOL)seekingAllowed { return mine() ? YES : %orig; }
- (BOOL)disallowPausing { return mine() ? NO : %orig; }
- (BOOL)disallowResuming { return mine() ? NO : %orig; }
%end

%ctor {
    %init;
    SGRequireClasses(@[@"SPTPlayerState", @"SPTPlayerTrack", @"SPTEsperantoPlayer", @"SPTNowPlayingPlaybackControllerImplementation"]);
    // The download changed (a song started, paused, seeked, ended): the native screens are told.
    [NSNotificationCenter.defaultCenter addObserverForName:SLLocalPlayerDidChangeNotification object:nil queue:NSOperationQueue.mainQueue
        usingBlock:^(NSNotification *note) {
            sg_lastEvent = CFAbsoluteTimeGetCurrent();
            push();
        }];
}
