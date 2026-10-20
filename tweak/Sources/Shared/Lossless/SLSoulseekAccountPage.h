#import <UIKit/UIKit.h>
#import "Settings/SGPage.h"

NS_ASSUME_NONNULL_BEGIN

/// An SGPage (so Spotify's navigation stack accepts it as SPTPageController): Soulseek account setup and server-login verification. Passwords are stored in the iOS Keychain.
@interface SLSoulseekAccountPage : SGPage
@end

/// The account saved by that page (username in the defaults, password in the Keychain); nil when none is saved.
NSString *_Nullable SLSoulseekSavedUsername(void);
NSString *_Nullable SLSoulseekSavedPassword(void);

NS_ASSUME_NONNULL_END
