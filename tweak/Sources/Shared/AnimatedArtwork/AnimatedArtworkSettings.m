// What the lock screen fills the screen with, the lyrics' style and whether the downloads run in Low Data
// Mode. iOS 26 and up only.
#import "Core/SGCore.h"
#import "Settings/SGModPage.h"
#import "Settings/SGPageStyle.h"
#import "Settings/SGSourcesPage.h"
#import "AnimatedArtwork.h"
#import "Shared/LockScreenArtwork/LockScreenArtwork.h"
#import "Shared/LockScreenLyrics/LockScreenLyrics.h"

static NSString *const kStarCanvas = @"canvas";
static NSString *const kStarCanvasLyrics = @"canvasLyrics";
static NSString *const kStarFill = @"fill";
static NSArray<NSString *> *defaultStarViewOrder(void) {
    return @[kStarCanvas, kStarCanvasLyrics, kStarFill];
}

SGLockArtwork SGLockScreenArtwork(void) {
    if (@available(iOS 26.0, *)) {
        // The old switch's YES and NO read as Moving artwork and Off, the enum's first two.
        static dispatch_once_t once;
        dispatch_once(&once, ^{
            NSUserDefaults *store = NSUserDefaults.standardUserDefaults;
            SGMigrateKey(SGKeyLockScreenMotion, SGKeyFullScreenArtwork);
            SGMigrateKey(SGKeyLegacyLockScreenArtwork, SGKeyFullScreenArtwork);
            if (![store objectForKey:SGKeyFullScreenArtwork]) {
                SGSetInt(SGKeyFullScreenArtwork, SGFlag(SGKeyLegacyLockScreenArtwork, YES)
                         ? SGLockArtworkMotion : SGLockArtworkOff);
            }
            if (![store objectForKey:SGKeyMotionSources] && [store objectForKey:SGKeyLockScreenArtworkSources]) {
                NSArray<NSString *> *legacy = SGArtworkOrder();
                if (legacy.count) [store setObject:legacy forKey:SGKeyMotionSources];
            }
        });
        return (SGLockArtwork)SGInt(SGKeyFullScreenArtwork, SGLockArtworkOff);
    }
    return SGLockArtworkOff;
}

NSArray<NSString *> *SGLockScreenStarViewOrder(void) {
    id stored = [NSUserDefaults.standardUserDefaults arrayForKey:SGKeyLockScreenStarViews];
    if (![stored isKindOfClass:NSArray.class]) return defaultStarViewOrder();
    NSMutableArray<NSString *> *order = [NSMutableArray array];
    for (id key in (NSArray *)stored) {
        if (([key isEqual:kStarCanvas] || [key isEqual:kStarCanvasLyrics] || [key isEqual:kStarFill])
            && ![order containsObject:key]) {
            [order addObject:key];
        }
    }
    return order;
}

void SGLockScreenStarAdvanceView(void) {
    NSArray<NSString *> *order = SGLockScreenStarViewOrder();
    if (!order.count) return;
    SGLockArtwork artwork = SGLockScreenArtwork();
    NSString *current = artwork == SGLockArtworkFill ? kStarFill
        : SGLockArtworkHasMotion(artwork) ? (SGLockScreenCanvasLyricsEnabled() ? kStarCanvasLyrics : kStarCanvas)
        : nil;
    NSUInteger index = current ? [order indexOfObject:current] : NSNotFound;
    NSString *next = order[index == NSNotFound ? 0 : (index + 1) % order.count];
    if ([next isEqualToString:kStarFill]) {
        SGSetInt(SGKeyFullScreenArtwork, SGLockArtworkFill);
        SGLockScreenCanvasLyricsSetEnabled(NO);
    } else {
        SGSetInt(SGKeyFullScreenArtwork, SGLockArtworkMotion);
        SGLockScreenCanvasLyricsSetEnabled([next isEqualToString:kStarCanvasLyrics]);
    }
    SGLog(@"lock star: switched to %@", next);
}

BOOL SGLockScreenCanvasLyricsEnabled(void) {
    BOOL canvas = SGHidden(SGKeyLockScreenCanvasLyrics);
    if (canvas && SGFlag(SGKeyLockScreenLyrics, NO) && SGEnabled(SGKeyLockScreenExclusiveLyrics)) {
        SGSetEnabled(SGKeyLockScreenLyrics, NO);
    }
    return canvas;
}

CGFloat SGLockScreenCoverArtworkScale(void) {
    return (CGFloat)SGInt(SGKeyLockScreenCoverArtworkScale, 50) / 100.0;
}

void SGLockScreenCanvasLyricsSetEnabled(BOOL enabled) {
    SGSetEnabled(SGKeyLockScreenCanvasLyrics, enabled);
    if (enabled && SGEnabled(SGKeyLockScreenExclusiveLyrics)) SGSetEnabled(SGKeyLockScreenLyrics, NO);
}

NSArray *SGLockScreenMotionRows(void) {
    if (@available(iOS 26.0, *)) {
        SGLockScreenArtwork();   // moves the old switch over before the row reads the new key
        SGModRow *style = SGChoiceRow(@"Lyrics style", @"Still draws each line once; Animated breathes the cover behind it",
                                      SGKeyLockScreenLyricsStyle, @[@"Still", @"Animated"], 0);
        style.visible = ^BOOL { return SGLockScreenArtwork() == SGLockArtworkLyrics; };
        SGModRow *canvasLyrics = SGOptionRow(@"Canvas lyrics", @"Show synced lines over the moving artwork",
                                             SGKeyLockScreenCanvasLyrics);
        canvasLyrics.changed = ^(BOOL on) { SGLockScreenCanvasLyricsSetEnabled(on); };
        SGModRow *exclusiveLyrics = SGSwitchRow(@"Automatically switch lyric styles",
            @"Turn off artist-name lyrics when Canvas lyrics turn on, and vice versa", SGKeyLockScreenExclusiveLyrics);
        exclusiveLyrics.changed = ^(BOOL on) {
            if (on) (void)SGLockScreenCanvasLyricsEnabled();
        };
        SGModRow *star = SGOptionRow(@"Switch with the star", @"Cycle through Canvas, Canvas with lyrics and Fill",
                                     SGKeyLockScreenStar);
        SGModRow *starViews = SGLockScreenStarViewsRow();
        starViews.visible = ^BOOL { return SGHidden(SGKeyLockScreenStar); };
        SGModRow *lowData = SGOptionRow(@"Download in Low Data Mode", @"Moving artwork, up to about 7 MB a song", SGKeyMotionLowData);
        lowData.visible = ^BOOL { return SGLockArtworkHasMotion(SGLockScreenArtwork()); };
        SGModRow *coverSize = SGSliderRow(@"Fallback album art size",
            @"Every song's blurred fallback when no moving artwork or lyrics clip is available",
            0.25, 0.85, 0.05,
            ^double { return SGLockScreenCoverArtworkScale(); },
            ^(double value) { SGSetInt(SGKeyLockScreenCoverArtworkScale, (NSInteger)lround(value * 100)); },
            ^NSString *(double value) { return [NSString stringWithFormat:@"%.0f%%", value * 100]; });
        coverSize.visible = ^BOOL { return SGLockScreenArtwork() == SGLockArtworkEverySong; };
        SGModRow *sources = SGMotionSourcesRow();
        sources.visible = lowData.visible;
        return @[
            SGChoiceRow(@"Full-screen artwork", @"The Canvas or Apple Music's animated cover, or the lyrics a line at a time. "
                                                 @"Every song puts the cover over a moving blur of it where a song has neither. "
                                                 @"Fill uses a sharp cover fading into progressively blurred artwork.",
                        SGKeyFullScreenArtwork, @[@"Off", @"Moving artwork", @"Lyrics", @"Every song", @"Fill"], SGLockArtworkOff),
            style,
            canvasLyrics,
            exclusiveLyrics,
            star,
            starViews,
            sources,
            lowData,
            coverSize,
        ];
    }
    return @[SGLockScreenArtworkNeedsRow()];
}

SGModRow *SGLockScreenStarViewsRow(void) {
    SGModRow *row = SGPageRow(@"Lock-screen star views", ^UIViewController *{
        NSArray<SGSource *> *views = @[
            [SGSource sourceWithKey:kStarCanvas name:@"Canvas" detail:@"The track's Canvas or its Apple Music animated cover"],
            [SGSource sourceWithKey:kStarCanvasLyrics name:@"Canvas with lyrics" detail:@"Synced lyrics over the moving artwork"],
            [SGSource sourceWithKey:kStarFill name:@"Fill" detail:@"The cover fading into progressively blurred artwork"],
        ];
        return SGSourcesPageMake(@"Lock-screen star views",
            @"Drag to choose the cycle order. Move a view below the line to disable it.",
            views, ^NSArray<NSString *> *{ return SGLockScreenStarViewOrder(); },
            ^(NSArray<NSString *> *keys) {
                [NSUserDefaults.standardUserDefaults setObject:keys forKey:SGKeyLockScreenStarViews];
            });
    });
    row.value = ^NSString * {
        NSArray<NSString *> *current = SGLockScreenStarViewOrder();
        if (!current.count) return @"Off";
        NSString *first = [current.firstObject isEqualToString:kStarCanvas] ? @"Canvas"
            : [current.firstObject isEqualToString:kStarCanvasLyrics] ? @"Canvas with lyrics" : @"Fill";
        return current.count == 1 ? first : [NSString stringWithFormat:@"%@ +%lu", first, (unsigned long)current.count - 1];
    };
    return SGWithSymbol(row, @"arrow.trianglehead.2.clockwise.rotate.90");
}

// Below iOS 26 the section stays, with one row that says why there is nothing to pick.
SGModRow *SGLockScreenArtworkNeedsRow(void) {
    return SGStatActionRow(@"Full-screen artwork", nil, ^NSString *{ return @"Needs iOS 26"; }, ^{
        NSString *message = [NSString stringWithFormat:@"This iPhone has iOS %@. The lock screen takes moving artwork "
                                                       @"from apps from iOS 26 on, so the Canvas and Apple Music's animated "
                                                       @"covers and Fill can show there once the iPhone is updated.", UIDevice.currentDevice.systemVersion];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Needs iOS 26" message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
        [SGTopController() presentViewController:alert animated:YES completion:nil];
    });
}
