// Lossless, in Spotify's ⋯ menu: a row "Download lossless" that fetches the FLAC or ALAC of the playing track
// from SpotiFlac (github.com/XerLib/SpotiFlac — spotiflac.dev), the same source colon3
// (github.com/AmineWallah/colon3) downloads from: a public HTTP API, no account and no password needed. The file
// lands in Documents/Lossless (SGLosslessStore.h), where the engine finds it by title and length and plays it in
// place of Spotify's stream (Lossless.x). It goes to Lossless, never to the lossy folder. The song keeps playing
// on Spotify's sound while it comes; when the file lands its own track re-anchors at once.
//
// The sheet is the player's own ⋯ whenever Speed and pitch's header is there (the same test EditInfoMenu.x uses);
// the footer belongs to Add lossless file (LosslessMenu.x), so this row is the table's header — and takes the
// footer only when even that is left out.
#import <objc/runtime.h>
#import "Core/SGCore.h"
#import "Settings/SGPageStyle.h"
#import "Shared/Player/PlayerState.h"
#import "Shared/Player/SpeedPitch.h"
#import "SGLossless.h"
#import "SGLosslessStore.h"
#import "SLSoulseek.h"   // the download itself: SLDownloadLossless, phases, progress, completion

static const CGFloat kRowHeight = 56, kSideMargin = 16, kIconSide = 24;
static char kRowKey, kDecidedKey;

#pragma mark - the icon

// A cloud with an arrow into a tray: what comes off the P2P network, not off Files.
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

static UIViewController *topOf(UIViewController *presenter) {
    UIViewController *top = presenter;
    while (top.presentedViewController && !top.presentedViewController.isBeingDismissed) top = top.presentedViewController;
    return top;
}

#pragma mark - the sheet

// What the fetch is doing, in one line: searching SpotiFlac, queued at a peer, or the percentage coming through.
@interface SLDownloadSheet : UIViewController <NSProgressObserving>
@property (nonatomic, weak) NSOperation *operation;
@end

@implementation SLDownloadSheet {
    UILabel *_status;
    UIProgressView *_bar;
    UIButton *_cancel;
    BOOL _done;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    UIView *sheet = [UIView new];
    sheet.backgroundColor = [UIColor colorWithWhite:0.11 alpha:1];
    sheet.layer.cornerRadius = 14;
    sheet.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:sheet];

    _status = [UILabel new];
    _status.font = rowFont();
    _status.textColor = UIColor.whiteColor;
    _status.numberOfLines = 0;
    _status.text = @"Searching SpotiFlac…";
    _status.translatesAutoresizingMaskIntoConstraints = NO;

    _bar = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    _bar.progressTintColor = UIColor.whiteColor;
    _bar.trackTintColor = [UIColor colorWithWhite:1 alpha:0.18];
    _bar.translatesAutoresizingMaskIntoConstraints = NO;

    _cancel = [UIButton buttonWithType:UIButtonTypeSystem];
    [_cancel setTitle:@"Cancel" forState:UIControlStateNormal];   // replaced below on older SDKs
    _cancel.titleLabel.font = rowFont();
    [_cancel setTitleColor:[UIColor colorWithWhite:1 alpha:0.85] forState:UIControlStateNormal];
    _cancel.translatesAutoresizingMaskIntoConstraints = NO;
    [_cancel addTarget:self action:@selector(stop) forControlEvents:UIControlEventTouchUpInside];

    [sheet addSubview:_status];
    [sheet addSubview:_bar];
    [sheet addSubview:_cancel];
    [NSLayoutConstraint activateConstraints:@[
        [sheet.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [sheet.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [sheet.widthAnchor constraintEqualToConstant:300],
        [_status.topAnchor constraintEqualToAnchor:sheet.topAnchor constant:20],
        [_status.leadingAnchor constraintEqualToAnchor:sheet.leadingAnchor constant:20],
        [_status.trailingAnchor constraintEqualToAnchor:sheet.trailingAnchor constant:-20],
        [_bar.topAnchor constraintEqualToAnchor:_status.bottomAnchor constant:14],
        [_bar.leadingAnchor constraintEqualToAnchor:_status.leadingAnchor],
        [_bar.trailingAnchor constraintEqualToAnchor:_status.trailingAnchor],
        [_cancel.topAnchor constraintEqualToAnchor:_bar.bottomAnchor constant:16],
        [_cancel.trailingAnchor constraintEqualToAnchor:sheet.trailingAnchor constant:-12],
        [_cancel.bottomAnchor constraintEqualToAnchor:sheet.bottomAnchor constant:-10],
    ]];
}

// Keep the sheet in step with the fetch. On the main thread already (SLSoulseek dispatches there).
- (void)update:(SLDownloadPhase)phase fraction:(double)fraction source:(NSString *)source {
    if (_done || !self.view.window) return;
    NSString *from = source.length ? [NSString stringWithFormat:@" · %@", source] : @"";
    switch (phase) {
        case SLProgressSearching:
            _status.text = @"Searching SpotiFlac…";
            _bar.progress = 0;
            _bar.hidden = YES;
            break;
        case SLProgressQueued:
            _status.text = [@"Waiting for an upload slot" stringByAppendingString:from];
            _bar.hidden = YES;
            break;
        case SLProgressTransferring:
            _status.text = [NSString stringWithFormat:@"Downloading — %.0f%%%@", fraction * 100, from];
            _bar.hidden = NO;
            _bar.progress = fraction;
            break;
    }
}

// The fetch ended without naming itself done: the caller closes us with the result.
- (void)finish {
    _done = YES;
}

- (void)stop {
    NSOperation *operation = self.operation;
    [operation cancel];
    _done = YES;
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (UIModalPresentationStyle)modalPresentationStyle { return UIModalPresentationOverFullScreen; }
- (UIModalTransitionStyle)modalTransitionStyle { return UIModalTransitionStyleCrossDissolve; }

@end

#pragma mark - the row

@interface SLLosslessDownloadRow : UIControl
@property (nonatomic, weak) UIViewController *menu;
@end

@implementation SLLosslessDownloadRow {
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
    // SpotiFlac's API needs no account of the user's own: straight to the search.
    __weak UIViewController *weakMenu = menu;
    // The sheet goes up after Spotify's menu is gone, the way Add lossless file gives the picker its turn.
    [menu dismissViewControllerAnimated:YES completion:^{
        UIViewController *host = weakMenu ? topOf(weakMenu.presentingViewController ?: weakMenu) : nil;
        if (!host) return;
        SLDownloadSheet *sheet = [SLDownloadSheet new];
        sheet.modalPresentationStyle = UIModalPresentationFormSheet;
        __weak SLDownloadSheet *weakSheet = sheet;
        sheet.operation = SLDownloadLossless(title, artist, duration, ^(SLDownloadPhase phase, double fraction, NSString *source) {
            [weakSheet update:phase fraction:fraction source:source];
        }, ^(NSURL *path, NSString *error) {
            UIViewController *present = weakSheet.presentingViewController ?: host;
            [weakSheet finish];
            [weakSheet dismissViewControllerAnimated:YES completion:^{
                NSString *message = path ? [NSString stringWithFormat:@"%@ is in Lossless. It plays with this song.", path.lastPathComponent]
                                         : (error ?: @"The download failed.");
                UIAlertController *result = [UIAlertController alertControllerWithTitle:@"Lossless" message:message
                    preferredStyle:UIAlertControllerStyleAlert];
                [result addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
                SGPresentDark(result);
                if (present) [topOf(present) presentViewController:result animated:YES completion:nil];
            }];
        });
        SGPresentDark(sheet);
        [host presentViewController:sheet animated:YES completion:nil];
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

static BOOL freeSlot(UIView *view) {
    return !view || view.bounds.size.height < 1;
}

static void install(UIViewController *menu) {
    UIView *root = menu.viewIfLoaded;
    if (!root || [objc_getAssociatedObject(menu, &kDecidedKey) isEqual:@NO]) return;
    UITableView *table = findTable(root, 0);
    CGFloat width = table.bounds.size.width;
    if (width <= 0) return;
    SLLosslessDownloadRow *row = objc_getAssociatedObject(menu, &kRowKey);
    if (!row) {
        if (!freeSlot(table.tableHeaderView)) {
            SGLog(@"lossless: the menu's header is %@, Download lossless left out", NSStringFromClass(table.tableHeaderView.class));
            objc_setAssociatedObject(menu, &kDecidedKey, @NO, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            return;
        }
        row = [[SLLosslessDownloadRow alloc] initWithFrame:CGRectMake(0, 0, width, kRowHeight)];
        row.menu = menu;
        objc_setAssociatedObject(menu, &kRowKey, row, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        table.tableHeaderView = row;
        [table invalidateIntrinsicContentSize];
        return;
    }
    // Spotify replaced the header, or the table changed width: put it back at the table's width.
    if (table.tableHeaderView != row || fabs(row.frame.size.width - width) > 0.5) {
        row.frame = CGRectMake(0, row.frame.origin.y, width, kRowHeight);
        table.tableHeaderView = row;
        [table invalidateIntrinsicContentSize];
    }
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
