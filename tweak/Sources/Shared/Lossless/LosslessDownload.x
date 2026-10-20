// Lossless, in Spotify's ⋯ menu: a row "Download lossless" that fetches the FLAC or ALAC of the playing track from
// Soulseek (SLSoulseek.m: a small Soulseek client that signs in with the account saved in Mod Settings >
// Soulseek account). The file lands in Documents/Lossless (SGLosslessStore.h), where the engine finds it by title
// and length and plays it in place of Spotify's stream (Lossless.x). It goes to Lossless, never to the lossy
// folder. The song keeps playing on Spotify's sound while it comes; when the file lands its own track re-anchors
// at once.
//
// The single download row is installed in the context-menu footer by SGLosslessFooter.h.
// Finished files are listed in the Downloads page (SLDownloadsPage.h): Mod Settings > Downloads, the Downloads
// tab of the tab bar, or "Open Downloads" in the alert that ends a download.
#import <objc/runtime.h>
#import "Core/SGCore.h"
#import "Settings/SGPageStyle.h"
#import "Shared/Player/PlayerState.h"
#import "Shared/Player/SpeedPitch.h"
#import "SGLossless.h"
#import "SGLosslessStore.h"
#import "SGLosslessFooter.h"
#import "SLSoulseek.h"   // the download itself: SLDownloadLossless, phases, progress, completion
#import "SLDownloadsPage.h"
#import "SLDownloadToast.h"
#import "SLSoulseekAccountPage.h"
#import "Shared/Player/SGLastTrack.h"

static const CGFloat kRowHeight = 56, kSideMargin = 16, kIconSide = 24;
static char kRowKey, kDecidedKey;

#pragma mark - the icon

// A cloud with an arrow into a tray for a lossless download.
static UIImage *cloudGlyph(UIColor *color) {
    CGFloat side = kIconSide;
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(side, side)];
    UIImage *image = [renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
        [color setStroke];
        [color setFill];
        CGFloat line = 1.6;
        // The cloud: two bumps over a flat base.
        UIBezierPath *cloud = [UIBezierPath bezierPath];
        cloud.lineWidth = line;
        cloud.lineJoinStyle = kCGLineJoinRound;
        [cloud moveToPoint:CGPointMake(7, 11.5)];
        [cloud addArcWithCenter:CGPointMake(9, 8.5) radius:3 startAngle:M_PI * 0.9 endAngle:M_PI * 1.9 clockwise:YES];
        [cloud addArcWithCenter:CGPointMake(14.5, 8) radius:3.6 startAngle:M_PI * 1.25 endAngle:M_PI * 0.1 clockwise:YES];
        [cloud addLineToPoint:CGPointMake(18.5, 11.5)];
        [cloud stroke];
        // Shaft and head of the arrow, under the cloud.
        UIBezierPath *shaft = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(11.5, 10, 2, 4.5) cornerRadius:0.6];
        [shaft fill];
        UIBezierPath *head = [UIBezierPath bezierPath];
        [head moveToPoint:CGPointMake(8.5, 13.5)];
        [head addLineToPoint:CGPointMake(16.5, 13.5)];
        [head addLineToPoint:CGPointMake(12.5, 17.7)];
        [head closePath];
        head.lineJoinStyle = kCGLineJoinRound;
        head.lineWidth = 0.8;
        [head fill];
        [head stroke];
        // The tray.
        UIBezierPath *tray = [UIBezierPath bezierPath];
        tray.lineWidth = 1.6;
        tray.lineCapStyle = kCGLineCapRound;
        tray.lineJoinStyle = kCGLineJoinRound;
        [tray moveToPoint:CGPointMake(7.5, 18)];
        [tray addLineToPoint:CGPointMake(7.5, 20)];
        [tray addLineToPoint:CGPointMake(17.5, 20)];
        [tray addLineToPoint:CGPointMake(17.5, 18)];
        [tray stroke];
    }];
    return [image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
}

static UIFont *rowFont(void) {
    UIContentSizeCategory current = UIApplication.sharedApplication.preferredContentSizeCategory;
    if (UIContentSizeCategoryCompareToCategory(current, UIContentSizeCategoryExtraLarge) == NSOrderedDescending) current = UIContentSizeCategoryExtraLarge;
    UITraitCollection *traits = [UITraitCollection traitCollectionWithPreferredContentSizeCategory:current];
    return [UIFont systemFontOfSize:[UIFont preferredFontForTextStyle:UIFontTextStyleBody compatibleWithTraitCollection:traits].pointSize];
}

#pragma mark - the row

@interface SGLosslessDownloadRow : UIControl
@property (nonatomic, weak) UIViewController *menu;
@end

@implementation SGLosslessDownloadRow {
    UIImageView *_icon;
    UILabel *_title;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (!(self = [super initWithFrame:frame])) return nil;
    UIColor *secondary = [UIColor colorWithWhite:1 alpha:UIAccessibilityDarkerSystemColorsEnabled() ? 0.80 : 0.65];
    _icon = [[UIImageView alloc] initWithImage:cloudGlyph(secondary)];
    _icon.contentMode = UIViewContentModeCenter;
    _title = [UILabel new];
    _title.font = rowFont();
    _title.textColor = UIColor.whiteColor;
    _title.text = @"Download lossless";
    for (UIView *view in @[_icon, _title]) {
        view.userInteractionEnabled = NO;
        [self addSubview:view];
    }
    self.isAccessibilityElement = YES;
    self.accessibilityTraits = UIAccessibilityTraitButton;
    self.accessibilityLabel = @"Download lossless";
    [self addTarget:self action:@selector(open) forControlEvents:UIControlEventTouchUpInside];
    [self addTarget:self action:@selector(highlight) forControlEvents:UIControlEventTouchDown | UIControlEventTouchDragEnter];
    [self addTarget:self action:@selector(unhighlight) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel | UIControlEventTouchDragExit];
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat width = self.bounds.size.width;
    _icon.frame = CGRectMake(kSideMargin, (kRowHeight - kIconSide) / 2, kIconSide, kIconSide);
    CGFloat titleX = kSideMargin + kIconSide + kSideMargin;
    _title.frame = CGRectMake(titleX, 0, MAX(0, width - titleX - kSideMargin), kRowHeight);
}

- (void)highlight {
    self.backgroundColor = [UIColor colorWithWhite:1 alpha:0.08];
}

- (void)unhighlight {
    [UIView animateWithDuration:0.2 animations:^{ self.backgroundColor = UIColor.clearColor; }];
}

- (void)open {
    UIViewController *menu = self.menu;
    if (!menu) return;
    SPTPlayerState *state = SGPlayerState();
    NSString *title = state.track.trackTitle;
    NSString *artist = state.track.artistName;
    double duration = state.duration;
    if (!title.length) {
        UIAlertController *none = [UIAlertController alertControllerWithTitle:@"Lossless"
            message:@"Play the song first: the download takes the track that is playing." preferredStyle:UIAlertControllerStyleAlert];
        [none addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [menu presentViewController:none animated:YES completion:nil];
        return;
    }
    // What the Downloads page will show for the file, taken now while this track is the one playing: the Spotify
    // track it plays with, and its cover.
    SGShownTrack *shown = SGShownTrackNow();
    NSString *uri = shown.current ? shown.uri : SGURIString(state.track.URI);
    NSString *album = shown.current ? shown.album : nil;
    // The search signs in with the Soulseek account saved in Mod Settings; without one the result says so.
    // The card goes up once Spotify's menu is gone; the song keeps playing and the app stays usable.
    [menu dismissViewControllerAnimated:YES completion:^{
        SLDownloadToast *toast = [SLDownloadToast showForTitle:title artist:artist];
        __weak SLDownloadToast *weakToast = toast;
        if (shown.current) SGShownTrackArtwork(shown, ^(UIImage *image) { weakToast.cover = image; });
        toast.operation = SLDownloadLossless(title, artist, duration, ^(SLDownloadPhase phase, double fraction, NSString *source) {
            [weakToast updatePhase:phase fraction:fraction source:source];
        }, ^(NSURL *path, NSString *error) {
            if (!path && !error) { [weakToast dismiss]; return; }   // cancelled from the card
            if (!path) {
                BOOL account = [error hasPrefix:@"Add your Soulseek account"] || [error hasPrefix:@"Wrong Soulseek password"];
                [weakToast finishWithTitle:@"Download failed" message:error failed:YES
                    tap:account ? ^{ SLOpenSoulseekAccount(); } : nil];
                return;
            }
            NSString *fileName = path.lastPathComponent;
            void (^save)(UIImage *) = ^(UIImage *image) {
                NSString *coverName = nil;
                NSData *jpeg = image ? UIImageJPEGRepresentation(image, 0.9) : nil;
                if (jpeg.length) {
                    coverName = [fileName stringByAppendingPathExtension:@"jpg"];
                    [jpeg writeToFile:[SGLosslessCoversDirectory() stringByAppendingPathComponent:coverName] atomically:YES];
                }
                NSMutableDictionary *info = [NSMutableDictionary dictionary];
                info[@"title"] = title;
                if (artist.length) info[@"artist"] = artist;
                if (album.length) info[@"album"] = album;
                if (uri.length) info[@"uri"] = uri;
                if (duration > 0) info[@"duration"] = @(duration);
                if (coverName) info[@"cover"] = coverName;
                SGLosslessStoreSetInfo(fileName, info);
                // The track plays this file from now on, whatever its length or tags say.
                if ([uri hasPrefix:@"spotify:track:"]) SGLosslessStoreRemember(uri, path.path);
                unsigned long long bytes = [[NSFileManager.defaultManager attributesOfItemAtPath:path.path error:nil] fileSize];
                NSString *size = bytes >= 1000000000 ? [NSString stringWithFormat:@"%.2f GB", bytes / 1e9] : [NSString stringWithFormat:@"%.1f MB", bytes / 1e6];
                [weakToast finishWithTitle:@"Downloaded" message:[NSString stringWithFormat:@"%@ · %@ · tap to open Downloads", title, size]
                    failed:NO tap:^{ SLOpenDownloads(); }];
            };
            if (shown.current) SGShownTrackArtwork(shown, save);   // the cover is cached by now: the call comes back at once
            else save(nil);
        });
    }];
}

@end

#pragma mark - the menu

static UITableView *findTable(UIView *root, int depth) {
    if ([root isKindOfClass:UITableView.class]) return (UITableView *)root;
    if (depth > 5) return nil;
    for (UIView *child in root.subviews) {
        UITableView *table = findTable(child, depth + 1);
        if (table) return table;
    }
    return nil;
}

static void install(UIViewController *menu) {
    UIView *root = menu.viewIfLoaded;
    if (!root || [objc_getAssociatedObject(menu, &kDecidedKey) isEqual:@NO]) return;
    UITableView *table = findTable(root, 0);
    CGFloat width = table.bounds.size.width;
    if (width <= 0) return;
    SGLosslessDownloadRow *row = objc_getAssociatedObject(menu, &kRowKey);
    BOOL created = !row;
    if (created) {
        row = [[SGLosslessDownloadRow alloc] initWithFrame:CGRectMake(0, 0, width, kRowHeight)];
        row.tag = 1;   // sole row in the shared footer box (SGLosslessFooter.h)
        row.menu = menu;
    }
    // The single download row lives in the footer. Called on every layout so it returns when Spotify replaces the footer or the table changes width.
    if (!SGLosslessFooterPlace(table, row, width, kRowHeight)) {
        if (created) {
            SGLog(@"lossless: the menu's footer is %@, Download lossless left out", NSStringFromClass(table.tableFooterView.class));
            objc_setAssociatedObject(menu, &kDecidedKey, @NO, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        return;
    }
    if (created) objc_setAssociatedObject(menu, &kRowKey, row, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

%hook _TtC24ContextMenu_InternalImpl25ContextMenuViewController
- (void)viewDidLayoutSubviews {
    %orig;
    install((UIViewController *)self);
}
%end

%ctor {
    if (!SGHidden(SGKeyLossless)) return;   // the Lossless files switch in Mod Settings, off unless set
    %init;
    SGRequireClasses(@[@"_TtC24ContextMenu_InternalImpl25ContextMenuViewController"]);
}
