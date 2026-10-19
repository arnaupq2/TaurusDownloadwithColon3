// Lossless, in Spotify's ⋯ menu: a row "Add lossless file" that opens the Files picker and copies the FLAC / ALAC
// files chosen into Documents/Lossless (SGLosslessStore.h), where the engine finds them by title and length and
// plays them in place of Spotify's stream (Lossless.x).
//
// The mod does not fetch any audio. The files are the user's own, from wherever they have them.
//
// The menu is Spotify's context menu sheet, ContextMenu_InternalImpl.ContextMenuViewController, whose rows come
// from Swift item factories with no way in (Shared/Player/SpeedPitchMenu.x says more). So the row is the table's
// footer, the way Edit info's is (Shared/LocalFiles/EditInfoMenu.x), and it is left out when something else
// already holds the footer. The sheet does not say which track it is for, and does not need to: the store matches
// a file to its track by the title tag and the length, so any file added here is found when its track plays.
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import <objc/runtime.h>
#import "Core/SGCore.h"
#import "Settings/SGPageStyle.h"
#import "SGLossless.h"
#import "SGLosslessStore.h"

static const CGFloat kRowHeight = 56, kSideMargin = 16, kIconSide = 24;
static char kRowKey, kDecidedKey;

#pragma mark - the icon

// The download glyph: a ring, an arrow and a tray, drawn so it takes the colour it is given.
static UIImage *downloadGlyph(UIColor *color) {
    CGFloat side = kIconSide;
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(side, side)];
    UIImage *image = [renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
        [color setStroke];
        [color setFill];
        CGFloat line = 1.6;
        UIBezierPath *ring = [UIBezierPath bezierPathWithOvalInRect:CGRectInset(CGRectMake(0, 0, side, side), line / 2, line / 2)];
        ring.lineWidth = line;
        [ring stroke];

        // Shaft and head of the arrow.
        UIBezierPath *shaft = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(11, 5, 2, 7) cornerRadius:0.6];
        [shaft fill];
        UIBezierPath *head = [UIBezierPath bezierPath];
        [head moveToPoint:CGPointMake(8, 11)];
        [head addLineToPoint:CGPointMake(16, 11)];
        [head addLineToPoint:CGPointMake(12, 15.2)];
        [head closePath];
        head.lineJoinStyle = kCGLineJoinRound;
        head.lineWidth = 0.8;
        [head fill];
        [head stroke];

        // The tray under it.
        UIBezierPath *tray = [UIBezierPath bezierPath];
        tray.lineWidth = 1.6;
        tray.lineCapStyle = kCGLineCapRound;
        tray.lineJoinStyle = kCGLineJoinRound;
        [tray moveToPoint:CGPointMake(7.5, 15.5)];
        [tray addLineToPoint:CGPointMake(7.5, 17.5)];
        [tray addLineToPoint:CGPointMake(16.5, 17.5)];
        [tray addLineToPoint:CGPointMake(16.5, 15.5)];
        [tray stroke];
    }];
    return [image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
}

#pragma mark - the import

static UIViewController *topOf(UIViewController *presenter) {
    UIViewController *top = presenter;
    while (top.presentedViewController && !top.presentedViewController.isBeingDismissed) top = top.presentedViewController;
    return top;
}

static BOOL losslessExtension(NSString *name) {
    return [@[@"flac", @"m4a", @"caf"] containsObject:name.pathExtension.lowercaseString];
}

// A name not taken yet in the folder: "Song.flac", then "Song 2.flac".
static NSString *freePath(NSString *directory, NSString *name) {
    NSString *base = name.stringByDeletingPathExtension, *extension = name.pathExtension;
    NSString *path = [directory stringByAppendingPathComponent:name];
    for (int n = 2; [NSFileManager.defaultManager fileExistsAtPath:path]; n++) {
        path = [directory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@ %d.%@", base, n, extension]];
    }
    return path;
}

@interface SGLosslessImporter : NSObject <UIDocumentPickerDelegate>
@property (nonatomic, weak) UIViewController *host;
@end

@implementation SGLosslessImporter

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    NSString *directory = SGLosslessStoreDirectory();
    NSUInteger added = 0, skipped = 0;
    for (NSURL *url in urls) {
        BOOL scoped = [url startAccessingSecurityScopedResource];
        if (losslessExtension(url.lastPathComponent)) {
            NSString *destination = freePath(directory, url.lastPathComponent);
            NSError *error;
            if ([NSFileManager.defaultManager copyItemAtPath:url.path toPath:destination error:&error]) {
                added++;
                SGLog(@"lossless: added %@", destination.lastPathComponent);
            } else {
                skipped++;
                SGLog(@"lossless: could not add %@: %@", url.lastPathComponent, error.localizedDescription);
            }
        } else {
            skipped++;
        }
        if (scoped) [url stopAccessingSecurityScopedResource];
    }
    NSString *message = added ? [NSString stringWithFormat:@"%lu file%@ added to Lossless. It plays when its song does.", (unsigned long)added, added == 1 ? @"" : @"s"]
                              : @"Nothing was added. Pick FLAC or ALAC (.m4a) files.";
    if (skipped && added) message = [message stringByAppendingFormat:@" %lu skipped.", (unsigned long)skipped];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Lossless" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    SGPresentDark(alert);
    UIViewController *host = self.host;
    if (host) [topOf(host) presentViewController:alert animated:YES completion:nil];
}

@end

static SGLosslessImporter *sg_importer;   // the picker's delegate is weak

static void presentPicker(UIViewController *host) {
    if (!host) return;
    NSArray<UTType *> *types = @[UTTypeAudio];
    UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc] initForOpeningContentTypes:types asCopy:YES];
    picker.allowsMultipleSelection = YES;
    sg_importer = [SGLosslessImporter new];
    sg_importer.host = host;
    picker.delegate = sg_importer;
    SGPresentDark(picker);
    [topOf(host) presentViewController:picker animated:YES completion:nil];
}

#pragma mark - the row

@interface SGLosslessRow : UIControl
@property (nonatomic, weak) UIViewController *menu;
@end

@implementation SGLosslessRow {
    UIImageView *_icon;
    UILabel *_title;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (!(self = [super initWithFrame:frame])) return nil;
    UIColor *secondary = [UIColor colorWithWhite:1 alpha:UIAccessibilityDarkerSystemColorsEnabled() ? 0.80 : 0.65];
    _icon = [[UIImageView alloc] initWithImage:downloadGlyph(secondary)];
    _icon.contentMode = UIViewContentModeCenter;
    _title = [UILabel new];
    UIContentSizeCategory current = UIApplication.sharedApplication.preferredContentSizeCategory;
    if (UIContentSizeCategoryCompareToCategory(current, UIContentSizeCategoryExtraLarge) == NSOrderedDescending) current = UIContentSizeCategoryExtraLarge;
    UITraitCollection *traits = [UITraitCollection traitCollectionWithPreferredContentSizeCategory:current];
    _title.font = [UIFont systemFontOfSize:[UIFont preferredFontForTextStyle:UIFontTextStyleBody compatibleWithTraitCollection:traits].pointSize];
    _title.textColor = UIColor.whiteColor;
    _title.text = @"Add lossless file";
    for (UIView *view in @[_icon, _title]) {
        view.userInteractionEnabled = NO;
        [self addSubview:view];
    }
    self.isAccessibilityElement = YES;
    self.accessibilityTraits = UIAccessibilityTraitButton;
    self.accessibilityLabel = @"Add lossless file";
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

// One sheet at a time: Spotify's menu goes before the picker comes up over what presented it.
- (void)open {
    UIViewController *menu = self.menu, *host = menu.presentingViewController;
    if (!host) {
        presentPicker(menu);
        return;
    }
    [menu dismissViewControllerAnimated:YES completion:^{ presentPicker(host); }];
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
    SGLosslessRow *row = objc_getAssociatedObject(menu, &kRowKey);
    if (!row) {
        if (!freeSlot(table.tableFooterView)) {
            SGLog(@"lossless: the menu's footer is %@, Add lossless file left out", NSStringFromClass(table.tableFooterView.class));
            objc_setAssociatedObject(menu, &kDecidedKey, @NO, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            return;
        }
        row = [[SGLosslessRow alloc] initWithFrame:CGRectMake(0, 0, width, kRowHeight)];
        row.menu = menu;
        objc_setAssociatedObject(menu, &kRowKey, row, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        table.tableFooterView = row;
        [table invalidateIntrinsicContentSize];
        return;
    }
    // Spotify replaced the footer, or the table changed width: put it back at the table's width.
    if (table.tableFooterView != row || fabs(row.frame.size.width - width) > 0.5) {
        row.frame = CGRectMake(0, row.frame.origin.y, width, kRowHeight);
        table.tableFooterView = row;
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
