// The Downloads list of the mod: the lossless files in Documents/Lossless, reachable from Mod Settings, from the
// Downloads tab of the tab bar (Spotify's own spotify:collection:downloads page is not there to open) and from
// the "Open Downloads" button after a download.
#import <UIKit/UIKit.h>
#import "Settings/SGPage.h"

NS_ASSUME_NONNULL_BEGIN

@interface SLDownloadsPage : SGPage
@end

/// Pushes the Downloads page onto the selected tab's stack (presents it when nothing can be pushed onto).
void SLOpenDownloads(void);
/// Same for the Soulseek account page.
void SLOpenSoulseekAccount(void);

NS_ASSUME_NONNULL_END
