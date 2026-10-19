#import "Core/SGCore.h"
#import "Redesigned/Kit/SGRRepaint.h"
#import "Redesigned/Kit/SGRTokens.h"
#import "Redesigned/Navbar/Navbar.h"
#import "Shared/Lyrics/Lyrics.h"
#import "Shared/Player/NowPlayingExtras.h"
#import "Shared/Player/PlayerState.h"
#import "NowPlayingBar.h"
#import <MediaPlayer/MediaPlayer.h>
#import <objc/message.h>

static const CGFloat kCardRadius = 24;
static char kGlassKey;
static __weak UIVisualEffectView *sg_cardGlass;
static __weak UIView *sg_cardArtwork;
static __weak UIView *sg_cardContent;
static __weak UIViewController *sg_container;
static BOOL sg_docked;
static CGRect sg_dockRow;   // window coordinates
static __weak UIView *sg_dockHost;

CGRect SGRNowPlayingCardFrameIn(UIView *host, CGFloat *radius) {
    UIVisualEffectView *glass = sg_cardGlass;
    if (!glass.superview || !glass.window || !host) return CGRectNull;
    if (radius) *radius = MIN(kCardRadius, glass.bounds.size.height / 2);
    return [host convertRect:glass.bounds fromView:glass];
}

CGRect SGRNowPlayingArtworkFrameIn(UIView *host) {
    UIView *artwork = sg_cardArtwork;
    if (!artwork.window || !host) return CGRectNull;
    return [host convertRect:artwork.bounds fromView:artwork];
}

static UIView *detectColoredCard(UIView *bar) {
    __block UIView *best = nil;
    __block CGFloat bestArea = 0;
    SGForEachView(bar, ^(UIView *v) {
        if ([v isKindOfClass:UIVisualEffectView.class] || SGKeepsColor(v) || !SGLooksLikeCard(v, v.layer.backgroundColor)) return;
        CGFloat area = v.bounds.size.width * v.bounds.size.height;
        if (area > bestArea) { bestArea = area; best = v; }
    });
    return best;
}

// Fallback when nothing is painted: the box around artwork, text and the small buttons.
static CGRect contentBounds(UIView *bar, UIView *target) {
    __block CGRect box = CGRectNull;
    SGForEachView(bar, ^(UIView *v) {
        if (v.hidden || v.alpha == 0) return;
        CGFloat width = v.bounds.size.width;
        BOOL content = ([v isKindOfClass:UIImageView.class] && width >= 20 && width <= 120)
            || [v isKindOfClass:UILabel.class]
            || ([v isKindOfClass:UIControl.class] && width <= 100);
        if (content) box = CGRectUnion(box, SGFrameIn(v, target));
    });
    return CGRectIsNull(box) ? box : CGRectInset(box, -10, -8);
}

static void roundView(UIView *view, CGFloat radius) {
    view.layer.cornerRadius = radius;
    view.layer.cornerCurve = kCACornerCurveContinuous;
}

static void restyleCardContent(UIView *card) {
    sg_cardContent = card;
    SGForEachView(card, ^(UIView *v) {
        CGSize size = v.bounds.size;
        BOOL square = size.width >= 36 && size.width <= 48 && fabs(size.width - size.height) < 1;
        if (!square || v.layer.cornerRadius <= 0) return;
        CGFloat radius = SGFlag(SGRKeyNowPlayingRoundedArtwork, NO) ? MIN(9, size.width * 0.22) : size.width / 2;
        UIView *outer = v;
        for (UIView *u = v; u && u != card && CGSizeEqualToSize(u.bounds.size, size); u = u.superview) {
            roundView(u, radius);
            u.clipsToBounds = YES;
            outer = u;
        }
        sg_cardArtwork = outer;
    });
    SGForEachView(card, ^(UIView *v) {
        CGRect f = v.frame;
        if (f.size.height > 3 || f.size.width < 200 || v.superview.bounds.size.height < 40) return;
        CGRect target = CGRectMake(52, card.bounds.size.height - 6, 226, 2);
        if (CGRectEqualToRect(f, target)) return;
        v.frame = target;
        [v setNeedsLayout];
        [v layoutIfNeeded];
    });
}


#pragma mark - docked beside the tab bar's buttons

// Minimized, the card does not shrink into the row: scaled to fit it, its text and cover came out too small to read
// (about 0.7 of their size). The row gets a pill of the mod's own, as high as the round buttons beside it, with only
// what is needed at that size: the cover, the title on one line and play/pause. It reads the track off the player and
// the cover off the card, and every tap on it is passed on to Spotify's own card or to the player.

static const CGFloat kPillHeight = 48, kPillInset = 4, kPillGap = 10, kToggleWidth = 44;

@interface SGRMiniPlayer : UIVisualEffectView
@property (nonatomic, readonly) UIImageView *cover;
@property (nonatomic, readonly) UILabel *title;
@property (nonatomic, readonly) UIView *titleClip;
@property (nonatomic, readonly) UIButton *toggle;
@property (nonatomic, readonly) UIButton *open;
@property (nonatomic) BOOL paused;
- (void)showTitle:(NSString *)title cover:(UIImage *)cover paused:(BOOL)paused;
// Starts a long title scrolling again (an animation does not outlive the app in the background or the pill being off screen).
- (void)resumeMarquee;
@end

static void openPlayer(void);
static void togglePlayback(void);

@implementation SGRMiniPlayer {
    NSString *_marqueeKey;
}

- (instancetype)init {
    UIVisualEffect *effect = SGGlassEffect();
    if ([effect respondsToSelector:@selector(setInteractive:)]) ((void (*)(id, SEL, BOOL))objc_msgSend)(effect, @selector(setInteractive:), YES);
    if (!(self = [super initWithEffect:effect])) return nil;
    self.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    SGShapeGlass(self, kPillHeight / 2, YES);

    // Behind everything: a touch anywhere on the pill but the button opens the player, and VoiceOver finds one element.
    _open = [UIButton buttonWithType:UIButtonTypeCustom];
    [_open addTarget:self action:@selector(opened) forControlEvents:UIControlEventTouchUpInside];
    _open.accessibilityTraits = UIAccessibilityTraitButton;
    [self.contentView addSubview:_open];

    _cover = [UIImageView new];
    _cover.contentMode = UIViewContentModeScaleAspectFill;
    _cover.clipsToBounds = YES;
    _cover.backgroundColor = [UIColor colorWithWhite:1 alpha:0.12];
    _cover.userInteractionEnabled = NO;
    [self.contentView addSubview:_cover];

    // The title sits in a clip: a title that fits stays put, a longer one slides to its end and back so it can be read whole.
    _titleClip = [UIView new];
    _titleClip.clipsToBounds = YES;
    _titleClip.userInteractionEnabled = NO;
    [self.contentView addSubview:_titleClip];
    _title = [UILabel new];
    _title.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    _title.textColor = SGRPrimary();
    _title.lineBreakMode = NSLineBreakByTruncatingTail;
    _title.numberOfLines = 1;
    _title.userInteractionEnabled = NO;
    [_titleClip addSubview:_title];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(resumeMarquee) name:UIApplicationDidBecomeActiveNotification object:nil];

    _toggle = [UIButton buttonWithType:UIButtonTypeCustom];
    _toggle.tintColor = SGRPrimary();
    [_toggle addTarget:self action:@selector(toggled) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:_toggle];
    [self setPaused:YES];
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect bounds = self.bounds;
    CGFloat side = bounds.size.height - 2 * kPillInset;
    _open.frame = bounds;
    BOOL rounded = SGFlag(SGRKeyNowPlayingRoundedArtwork, NO);
    CGFloat coverX = kPillInset + (rounded ? 2 : 0);
    _cover.frame = CGRectMake(coverX, kPillInset, side, side);
    _cover.layer.cornerRadius = rounded ? MIN(9, side * 0.22) : side / 2;
    _cover.layer.cornerCurve = kCACornerCurveContinuous;
    CGFloat toggleWidth = MIN(kToggleWidth, bounds.size.width / 3);
    _toggle.frame = CGRectMake(bounds.size.width - toggleWidth - 6, 0, toggleWidth, bounds.size.height);
    CGFloat left = CGRectGetMaxX(_cover.frame) + kPillGap;
    _titleClip.frame = CGRectMake(left, 0, MAX(0, CGRectGetMinX(_toggle.frame) - kPillGap - left), bounds.size.height);
    [self layoutTitle];
}

static const CGFloat kMarqueeSpeed = 32, kMarqueePause = 1.4, kMarqueeFade = 18;

- (void)layoutTitle {
    CGFloat clip = _titleClip.bounds.size.width, height = _titleClip.bounds.size.height;
    CGFloat text = ceil([_title.text ?: @"" sizeWithAttributes:@{NSFontAttributeName: _title.font}].width);
    BOOL overflows = text > clip + 0.5 && clip > 0;
    BOOL moves = overflows && !UIAccessibilityIsReduceMotionEnabled();
    // Under Reduce Motion a long title is cut with an ellipsis instead, as before.
    CGRect frame = CGRectMake(0, 0, moves ? text : clip, height);
    NSString *key = [NSString stringWithFormat:@"%@|%.1f|%d", _title.text, clip, moves];
    if (!CGRectEqualToRect(_title.frame, frame)) _title.frame = frame;
    BOOL running = [_title.layer animationForKey:@"marquee"] != nil;
    if ([key isEqualToString:_marqueeKey] && running == moves) return;
    _marqueeKey = key;
    [_title.layer removeAnimationForKey:@"marquee"];
    // The right edge fades out while a title runs on past it.
    if (moves) {
        CAGradientLayer *mask = [CAGradientLayer layer];
        mask.frame = _titleClip.bounds;
        mask.startPoint = CGPointMake(0, 0.5);
        mask.endPoint = CGPointMake(1, 0.5);
        mask.colors = @[(id)UIColor.blackColor.CGColor, (id)UIColor.blackColor.CGColor, (id)UIColor.clearColor.CGColor];
        mask.locations = @[@0, @(MAX(0.5, 1 - kMarqueeFade / clip)), @1];
        _titleClip.layer.mask = mask;
    } else {
        _titleClip.layer.mask = nil;
    }
    if (!moves) return;
    CGFloat travel = text - clip + kMarqueeFade / 2;
    CGFloat run = travel / kMarqueeSpeed, total = 2 * kMarqueePause + 2 * run;
    CAKeyframeAnimation *slide = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.x"];
    slide.values = @[@0, @0, @(-travel), @(-travel), @0];
    slide.keyTimes = @[@0, @(kMarqueePause / total), @((kMarqueePause + run) / total), @((2 * kMarqueePause + run) / total), @1];
    slide.timingFunctions = @[
        [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear],
        [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut],
        [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear],
        [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut],
    ];
    slide.duration = total;
    slide.repeatCount = HUGE_VALF;
    slide.removedOnCompletion = NO;
    [_title.layer addAnimation:slide forKey:@"marquee"];
}

- (void)resumeMarquee {
    _marqueeKey = nil;
    [self setNeedsLayout];
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)setPaused:(BOOL)paused {
    _paused = paused;
    UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:17 weight:UIImageSymbolWeightSemibold];
    UIImage *glyph = [UIImage systemImageNamed:paused ? @"play.fill" : @"pause.fill" withConfiguration:config];
    if (_toggle.currentImage != glyph) [_toggle setImage:glyph forState:UIControlStateNormal];
    _toggle.accessibilityLabel = paused ? @"Play" : @"Pause";
}

- (void)showTitle:(NSString *)title cover:(UIImage *)cover paused:(BOOL)paused {
    if (title.length && ![_title.text isEqualToString:title]) {
        _title.text = title;
        [self setNeedsLayout];
    }
    _open.accessibilityLabel = _title.text;
    if (_cover.image != cover) _cover.image = cover;
    if (_paused != paused) {
        // The glyph swaps in place, so the button does not jump while the track goes on.
        [UIView transitionWithView:_toggle duration:SGRReduceMotion() ? 0 : 0.15 options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{ [self setPaused:paused]; } completion:nil];
    }
}

- (void)opened { openPlayer(); }
- (void)toggled { togglePlayback(); }
@end

static SGRMiniPlayer *sg_mini;
static void refreshMini(void);

static SGRMiniPlayer *miniPlayer(void) {
    if (!sg_mini) {
        sg_mini = [SGRMiniPlayer new];
        sg_mini.alpha = 0;
        sg_mini.userInteractionEnabled = NO;
    }
    return sg_mini;
}

// The cover the card shows, which Spotify loads a moment after a new track: read off the card on each of its layout passes.
static UIImage *cardCover(void) {
    __block UIImage *image = nil;
    SGForEachView(sg_cardArtwork, ^(UIView *v) {
        if (!image && [v isKindOfClass:UIImageView.class]) image = ((UIImageView *)v).image;
    });
    return image;
}

static UIImage *currentCover(void) {
    SPTPlayerState *state = SGPlayerState();
    NSDictionary *info = MPNowPlayingInfoCenter.defaultCenter.nowPlayingInfo;
    MPMediaItemArtwork *artwork = info[MPMediaItemPropertyArtwork];
    if (SGNowPlayingTitlesMatch(info[MPMediaItemPropertyTitle], state.track.trackTitle)
        && [artwork isKindOfClass:MPMediaItemArtwork.class]) {
        UIImage *image = [artwork imageWithSize:CGSizeMake(600, 600)];
        if (image) return image;
    }
    return cardCover();
}

static BOOL hasTrack(void) {
    return SGPlayerState().track.trackTitle.length > 0;
}

void SGRNowPlayingBarRefresh(void) {
    if (sg_cardContent) restyleCardContent(sg_cardContent);
    [sg_mini setNeedsLayout];
    [sg_mini layoutIfNeeded];
    refreshMini();
}

BOOL SGRNowPlayingAvailable(void) {
    return hasTrack();
}

static void refreshMini(void) {
    SGRMiniPlayer *mini = sg_mini;
    if (!mini) return;
    SPTPlayerState *state = SGPlayerState();
    [mini showTitle:state.track.trackTitle cover:currentCover() paused:state.isPaused];
}

static void togglePlayback(void) {
    id<SPTPlayer> player = SGKaraokePlayer();
    if (!player) return;
    if (SGPlayerState().isPaused) [player resume:nil];
    else [player pause:nil];
}

// A tap on the pill is the card's own: Spotify's tap recognizer sits on the card or on a view around it, and is fired
// from the card outwards so the play button's own recognizer is never reached.
static void openPlayer(void) {
    UIView *stop = sg_container.viewIfLoaded;
    for (UIView *v = sgr_nowPlayingCard ?: sg_cardArtwork; v; v = v.superview) {
        if (SGRFireTapRecognizers(v)) return;
        if (v == stop) break;
    }
    SGLog(@"now playing pill: no tap recognizer found on the card to open the player with");
}

@interface SGRMiniPlayerWatcher : NSObject <SGPlayerStateObserver>
@end

@implementation SGRMiniPlayerWatcher
- (void)playerStateDidChange:(SPTPlayerState *)state {
    dispatch_async(dispatch_get_main_queue(), ^{
        // The queue ended with the bar minimized: the pill has nothing left to show, so the whole bar comes back.
        if (!hasTrack() && SGRTabBarMinimized()) SGRSetTabBarMinimized(NO, YES);
        refreshMini();
        // A new track's cover reaches the card a little after the state does.
        for (NSNumber *delay in @[@0.3, @1, @2.5]) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay.doubleValue * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ refreshMini(); });
        }
    });
}
@end

static SGRMiniPlayerWatcher *sg_miniWatcher;

static void applyDock(BOOL animated) {
    UIView *view = sg_container.viewIfLoaded;
    UIView *host = sg_dockHost;
    UIVisualEffectView *glass = sg_cardGlass;
    if (!view || !host || !host.window || glass.superview != view) return;

    // Nothing is playing (or the player has not reported): there is no pill, and the card stays as Spotify has it.
    BOOL docked = sg_docked && hasTrack();
    SGRMiniPlayer *mini = miniPlayer();
    if (mini.superview != host) [host addSubview:mini];
    refreshMini();

    CGRect card = [host convertRect:glass.bounds fromView:glass];
    CGRect row = [host convertRect:sg_dockRow fromView:nil];
    // The pill is as high as the buttons beside it, and keeps their middle.
    CGRect pill = CGRectMake(row.origin.x, CGRectGetMidY(row) - kPillHeight / 2, row.size.width, kPillHeight);
    CGRect target = docked ? pill : card;
    CGFloat pillAlpha = docked ? 1 : 0, cardAlpha = docked ? 0 : 1;

    BOOL settled = CGRectEqualToRect(mini.frame, target) && mini.alpha == pillAlpha && view.alpha == cardAlpha;
    mini.userInteractionEnabled = docked;
    view.userInteractionEnabled = !docked;
    if (settled) return;

    // Out of sight, the pill waits on the card, so it comes out of it on the way down and goes back into it on the way up.
    if (mini.alpha < 0.01 && docked) {
        [mini resumeMarquee];
        [UIView performWithoutAnimation:^{
            mini.frame = card;
            [mini layoutIfNeeded];
        }];
    }
    void (^apply)(void) = ^{
        mini.frame = target;
        [mini layoutIfNeeded];
        mini.alpha = pillAlpha;
        view.alpha = cardAlpha;
    };
    if (!animated) {
        [UIView performWithoutAnimation:apply];
        return;
    }
    // A spring with no bounce: nothing was thrown, and it starts from wherever the pill is now if it is turned around.
    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:1 initialSpringVelocity:0
                        options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction
                     animations:apply completion:nil];
}

void SGRDockNowPlayingCard(BOOL docked, CGRect row, UIView *host, BOOL animated) {
    sg_docked = docked;
    if (docked) sg_dockRow = row;
    if (host) sg_dockHost = host;
    applyDock(animated && !UIAccessibilityIsReduceMotionEnabled());
}

static void styleNowPlayingBar(UIViewController *container) {
    UIViewController *barVC = container.childViewControllers.firstObject;
    UIView *bar = barVC.viewIfLoaded ?: container.view;
    sgr_nowPlayingRoot = bar;
    sg_container = container;

    UIView *card = sgr_nowPlayingCard;
    if (!card || !SGIsInside(card, bar)) card = sgr_nowPlayingCard = detectColoredCard(bar);

    container.view.layer.backgroundColor = NULL;
    SGStripBackgrounds(bar);

    CGRect frame = card ? SGFrameIn(card, container.view) : contentBounds(bar, container.view);
    if (CGRectIsNull(frame)) return;
    frame.size.height = MIN(frame.size.height, 80);
    if (frame.size.height < 30 || frame.size.width < 100) return;

    CGFloat radius = MIN(kCardRadius, frame.size.height / 2);
    if (card) {
        roundView(card, radius);
        restyleCardContent(card);
    }

    UIVisualEffectView *glass = SGGlassFor(container.view, &kGlassKey);
    if (glass.overrideUserInterfaceStyle != UIUserInterfaceStyleDark) glass.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    sg_cardGlass = glass;
    glass.frame = frame;
    SGShapeGlass(glass, radius, NO);
    // A new track can change the card's size and brings its cover; the pill follows them.
    if (sg_docked) applyDock(NO);
    else refreshMini();

    static dispatch_once_t once;
    dispatch_once(&once, ^{
        SGLog(@"now playing card %@ at %@ (bar %@, container %@)", card.class, NSStringFromCGRect(frame),
              NSStringFromCGRect(bar.frame), NSStringFromCGRect(container.view.bounds));
    });
}

%hook _TtC18NowPlaying_BarImpl36NowPlayingBarContainerViewController
- (void)viewDidLayoutSubviews {
    %orig;
    styleNowPlayingBar((UIViewController *)self);
}
%end

%hook _TtC18NowPlaying_BarImpl27NowPlayingBarViewController
- (void)viewDidLayoutSubviews {
    %orig;
    UIViewController *parent = ((UIViewController *)self).parentViewController;
    if ([NSStringFromClass(parent.class) containsString:@"NowPlayingBarContainer"]) styleNowPlayingBar(parent);
}
%end

%ctor {
    if (!SGRedesignedUI()) return;
    %init;
    sg_miniWatcher = [SGRMiniPlayerWatcher new];
    SGAddPlayerStateObserver(sg_miniWatcher);
    SGRequireClasses(@[
        @"_TtC18NowPlaying_BarImpl36NowPlayingBarContainerViewController",
        @"_TtC18NowPlaying_BarImpl27NowPlayingBarViewController",
    ]);
}
