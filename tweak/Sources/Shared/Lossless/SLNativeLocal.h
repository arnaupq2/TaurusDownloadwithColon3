// The local-file address a download goes by (spotify:local:<artist>:<album>:<title>:<seconds>, each part form
// encoded, as Shared/LocalFiles/LocalFiles.h describes), so the track the native player shows for a download is
// read by the local file code that already exists (names, edits, lyrics by names).
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
/// `entry`: path, title, artist, album, seconds (each may be missing). nil when it has no title.
NSString *_Nullable SLNativeLocalURI(NSDictionary *entry);
NS_ASSUME_NONNULL_END
