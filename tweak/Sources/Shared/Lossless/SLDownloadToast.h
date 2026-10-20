// The notification a lossless download shows inside Spotify: a liquid glass card at the top of the screen with the
// song's cover, what the download is doing and how long it still needs. It does not block the app: the song keeps
// playing and Spotify stays usable while it comes. When the file lands the card says so and a tap opens Downloads.
//
// Main thread only.
#import <UIKit/UIKit.h>
#import "SLSoulseek.h"

NS_ASSUME_NONNULL_BEGIN

@interface SLDownloadToast : NSObject
/// Shows the card for `title` by `artist`. Only one is up at a time: a new one replaces the old.
+ (instancetype)showForTitle:(NSString *)title artist:(nullable NSString *)artist;
/// Cancelled by the card's ✕ button.
@property (nonatomic, weak, nullable) NSOperation *operation;
@property (nonatomic, strong, nullable) UIImage *cover;
/// The fetch's progress (SLDownloadProgress): the card works out the time left from how fast the transfer goes.
- (void)updatePhase:(SLDownloadPhase)phase fraction:(double)fraction source:(nullable NSString *)source;
/// The fetch ended: the card says `message` for a few seconds; a tap runs `tap` (nil: dismisses).
- (void)finishWithTitle:(NSString *)title message:(NSString *)message failed:(BOOL)failed tap:(nullable void (^)(void))tap;
- (void)dismiss;
@end

NS_ASSUME_NONNULL_END
