#import "SLDownloadToast.h"
#import "Core/SGCore.h"
#import "Settings/SGPageStyle.h"

static const CGFloat kCover = 52, kPad = 12, kButton = 32, kMinHeight = 76, kMaxWidth = 440;
static char kGlassKey;

#pragma mark - the card

@interface SLToastView : UIView
@property (nonatomic, strong) UIImageView *cover;
@property (nonatomic, strong) UILabel *title, *status;
@property (nonatomic, strong) UIProgressView *bar;
@property (nonatomic, strong) UIButton *close;
- (CGFloat)heightForWidth:(CGFloat)width;
@end

@implementation SLToastView

- (instancetype)initWithFrame:(CGRect)frame {
    if (!(self = [super initWithFrame:frame])) return nil;
    self.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    self.layer.shadowColor = UIColor.blackColor.CGColor;
    self.layer.shadowOpacity = 0.35;
    self.layer.shadowRadius = 18;
    self.layer.shadowOffset = CGSizeMake(0, 6);

    _cover = [UIImageView new];
    _cover.contentMode = UIViewContentModeScaleAspectFill;
    _cover.clipsToBounds = YES;
    _cover.layer.cornerRadius = 9;
    _cover.layer.cornerCurve = kCACornerCurveContinuous;
    _cover.backgroundColor = [UIColor colorWithWhite:1 alpha:0.12];
    _cover.image = [UIImage systemImageNamed:@"arrow.down.circle"];
    _cover.tintColor = [UIColor colorWithWhite:1 alpha:0.7];

    _title = [UILabel new];
    _title.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    _title.textColor = UIColor.whiteColor;
    _title.lineBreakMode = NSLineBreakByTruncatingTail;

    _status = [UILabel new];
    _status.font = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
    _status.textColor = [UIColor colorWithWhite:1 alpha:0.72];
    _status.numberOfLines = 2;

    _bar = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    _bar.progressTintColor = UIColor.whiteColor;
    _bar.trackTintColor = [UIColor colorWithWhite:1 alpha:0.18];
    _bar.layer.cornerRadius = 1.5;
    _bar.clipsToBounds = YES;

    _close = [UIButton buttonWithType:UIButtonTypeSystem];
    [_close setImage:[UIImage systemImageNamed:@"xmark.circle.fill"] forState:UIControlStateNormal];
    _close.tintColor = [UIColor colorWithWhite:1 alpha:0.55];
    _close.accessibilityLabel = @"Cancel download";

    for (UIView *view in @[_cover, _title, _status, _bar, _close]) [self addSubview:view];
    return self;
}

- (CGFloat)textWidthFor:(CGFloat)width {
    return MAX(40, width - kPad - kCover - kPad - kButton - kPad);
}

- (CGFloat)statusHeightForWidth:(CGFloat)width {
    CGSize size = [_status sizeThatFits:CGSizeMake([self textWidthFor:width], CGFLOAT_MAX)];
    return MIN(ceil(size.height), 34);
}

- (CGFloat)heightForWidth:(CGFloat)width {
    CGFloat text = 12 + 20 + 2 + [self statusHeightForWidth:width] + (_bar.hidden ? 12 : 22);
    return MAX(kMinHeight, text);
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat width = self.bounds.size.width, height = self.bounds.size.height;
    CGFloat textX = kPad + kCover + kPad, textW = [self textWidthFor:width];
    UIVisualEffectView *glass = SGGlassFor(self, &kGlassKey);
    glass.frame = self.bounds;
    SGShapeGlass(glass, 26, NO);
    self.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:26].CGPath;
    _cover.frame = CGRectMake(kPad, MAX(kPad, (height - kCover) / 2), kCover, kCover);
    _title.frame = CGRectMake(textX, 12, textW, 20);
    CGFloat statusH = [self statusHeightForWidth:width];
    _status.frame = CGRectMake(textX, 34, textW, statusH);
    _bar.frame = CGRectMake(textX, CGRectGetMaxY(_status.frame) + 7, textW, 3);
    _close.frame = CGRectMake(width - kPad - kButton, 10, kButton, kButton);
}

@end

#pragma mark - the controller of the card

static SLDownloadToast *sg_current;

static UIWindow *activeWindow(void) {
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (![scene isKindOfClass:UIWindowScene.class] || scene.activationState != UISceneActivationStateForegroundActive) continue;
        UIWindowScene *windowScene = (UIWindowScene *)scene;
        for (UIWindow *window in windowScene.windows) if (window.isKeyWindow) return window;
        return windowScene.windows.firstObject;
    }
    return nil;
}

static NSString *slDuration(double seconds) {
    NSInteger s = (NSInteger)llround(MAX(1, seconds));
    if (s < 60) return [NSString stringWithFormat:@"%ld s", (long)s];
    if (s < 3600) return [NSString stringWithFormat:@"%ld min %02ld s", (long)(s / 60), (long)(s % 60)];
    return [NSString stringWithFormat:@"%ld h %02ld min", (long)(s / 3600), (long)((s % 3600) / 60)];
}

@implementation SLDownloadToast {
    SLToastView *_view;
    __weak UIWindow *_window;
    NSTimer *_timer;
    void (^_tap)(void);
    BOOL _finished, _gone;
    CFTimeInterval _transferStart;
    double _startFraction, _smoothedETA;
}

+ (instancetype)showForTitle:(NSString *)title artist:(NSString *)artist {
    [sg_current dismissAnimated:NO];
    SLDownloadToast *toast = [SLDownloadToast new];
    sg_current = toast;
    [toast buildWithTitle:title artist:artist];
    return toast;
}

- (void)buildWithTitle:(NSString *)title artist:(NSString *)artist {
    UIWindow *window = activeWindow();
    if (!window) return;
    _window = window;
    _smoothedETA = -1;
    _view = [[SLToastView alloc] initWithFrame:CGRectZero];
    _view.title.text = artist.length ? [NSString stringWithFormat:@"%@ · %@", title, artist] : title;
    _view.status.text = @"Searching Soulseek…";
    _view.bar.hidden = YES;
    [_view.close addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
    [_view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped)]];
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panned:)];
    [_view addGestureRecognizer:pan];
    [window addSubview:_view];
    [self place];
    _view.transform = CGAffineTransformMakeTranslation(0, -(_view.frame.size.height + window.safeAreaInsets.top + 40));
    _view.alpha = 0;
    [UIView animateWithDuration:0.55 delay:0 usingSpringWithDamping:0.82 initialSpringVelocity:0.3 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        self->_view.transform = CGAffineTransformIdentity;
        self->_view.alpha = 1;
    } completion:nil];
}

- (void)setCover:(UIImage *)cover {
    _cover = cover;
    if (!cover || !_view) return;
    _view.cover.image = cover;
    _view.cover.tintColor = nil;
}

// Width and place: centred under the status bar, never wider than a phone's card.
- (void)place {
    UIWindow *window = _window;
    if (!window || !_view) return;
    CGFloat width = MIN(window.bounds.size.width - 24, kMaxWidth);
    CGFloat height = [_view heightForWidth:width];
    CGFloat top = window.safeAreaInsets.top + 6;
    CGAffineTransform keep = _view.transform;
    _view.transform = CGAffineTransformIdentity;
    _view.frame = CGRectMake((window.bounds.size.width - width) / 2, top, width, height);
    _view.transform = keep;
    [window bringSubviewToFront:_view];
    [_view setNeedsLayout];
    [_view layoutIfNeeded];
}

- (void)updatePhase:(SLDownloadPhase)phase fraction:(double)fraction source:(NSString *)source {
    if (_finished || _gone || !_view) return;
    switch (phase) {
        case SLProgressSearching:
            _view.status.text = @"Searching Soulseek…";
            _view.bar.hidden = YES;
            _transferStart = 0;
            break;
        case SLProgressQueued:
            _view.status.text = source.length ? [@"Waiting for the peer · " stringByAppendingString:source] : @"Waiting for the peer…";
            _view.bar.hidden = YES;
            _transferStart = 0;
            _smoothedETA = -1;
            break;
        case SLProgressTransferring: {
            CFTimeInterval now = CACurrentMediaTime();
            if (!_transferStart) { _transferStart = now; _startFraction = fraction; _smoothedETA = -1; }
            _view.bar.hidden = NO;
            [_view.bar setProgress:(float)fraction animated:YES];
            double done = fraction - _startFraction, elapsed = now - _transferStart;
            NSString *percent = [NSString stringWithFormat:@"%.0f%%", fraction * 100];
            if (fraction >= 0.999) {
                _view.status.text = @"Finishing…";
            } else if (elapsed >= 1.5 && done > 0.005) {
                double eta = (1 - fraction) / (done / elapsed);                        // seconds at the speed so far
                _smoothedETA = _smoothedETA < 0 ? eta : 0.7 * _smoothedETA + 0.3 * eta;   // steady, not jumpy
                _view.status.text = [NSString stringWithFormat:@"Downloading %@ · %@ left", percent, slDuration(_smoothedETA)];
            } else {
                _view.status.text = [NSString stringWithFormat:@"Downloading %@ · working out the time left…", percent];
            }
            break;
        }
    }
    [self place];
}

- (void)finishWithTitle:(NSString *)title message:(NSString *)message failed:(BOOL)failed tap:(void (^)(void))tap {
    if (_gone || !_view) return;
    _finished = YES;
    _tap = [tap copy];
    _view.title.text = title;
    _view.status.text = message;
    _view.status.textColor = failed ? [UIColor colorWithRed:1 green:0.55 blue:0.5 alpha:1] : [UIColor colorWithWhite:1 alpha:0.72];
    _view.bar.hidden = YES;
    _view.close.hidden = YES;
    if (failed) {
        _view.cover.image = [UIImage systemImageNamed:@"exclamationmark.triangle.fill"];
        _view.cover.tintColor = [UIColor colorWithRed:1 green:0.55 blue:0.5 alpha:1];
    } else if (!_cover) {
        _view.cover.image = [UIImage systemImageNamed:@"checkmark.circle.fill"];
        _view.cover.tintColor = SGAccentMark();
    }
    [UIView animateWithDuration:0.25 animations:^{ [self place]; }];
    [_timer invalidate];
    __weak SLDownloadToast *weakSelf = self;
    _timer = [NSTimer scheduledTimerWithTimeInterval:failed ? 8 : 5 repeats:NO block:^(NSTimer *timer) { [weakSelf dismiss]; }];
}

- (void)cancel {
    [self.operation cancel];
    [self dismiss];
}

- (void)tapped {
    if (!_finished) return;
    void (^tap)(void) = _tap;
    [self dismiss];
    if (tap) tap();
}

- (void)panned:(UIPanGestureRecognizer *)pan {
    if (pan.state == UIGestureRecognizerStateChanged) {
        CGFloat up = MIN(0, [pan translationInView:_view.superview].y);
        _view.transform = CGAffineTransformMakeTranslation(0, up);
    } else if (pan.state == UIGestureRecognizerStateEnded || pan.state == UIGestureRecognizerStateCancelled) {
        BOOL swipedAway = [pan translationInView:_view.superview].y < -30 || [pan velocityInView:_view.superview].y < -400;
        if (swipedAway && _finished) { [self dismiss]; return; }
        [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0 options:0 animations:^{
            self->_view.transform = CGAffineTransformIdentity;
        } completion:nil];
    }
}

- (void)dismiss {
    [self dismissAnimated:YES];
}

- (void)dismissAnimated:(BOOL)animated {
    if (_gone) return;
    _gone = YES;
    [_timer invalidate];
    if (sg_current == self) sg_current = nil;
    SLToastView *view = _view;
    if (!view) return;
    void (^remove)(void) = ^{ [view removeFromSuperview]; };
    if (!animated) { remove(); return; }
    [UIView animateWithDuration:0.35 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        view.transform = CGAffineTransformMakeTranslation(0, -(view.frame.size.height + 80));
        view.alpha = 0;
    } completion:^(BOOL finished) { remove(); }];
}

@end
