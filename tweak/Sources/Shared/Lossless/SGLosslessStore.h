#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
// Documents/Lossless: FLAC and ALAC files, put there by the user or downloaded. A file goes with the Spotify track
// it was proven against (SGLosslessStoreRemember); until then a file is a candidate when its title tag (or its
// name) is the track's title and its length is within 2 s of the track's. Artists are not compared: a tag can
// name the composer where Spotify names the performer.
NSString *SGLosslessStoreDirectory(void);
// Main thread. The file for the track, or nil.
NSString *_Nullable SGLosslessStoreFile(NSString *uri, NSString *title, double duration);
// Main thread. Whether a file is there for a track whose length is not known yet (an upcoming one): by the
// index, else by title alone.
BOOL SGLosslessStoreHas(NSString *uri, NSString *title);
// Main thread. The file matched the track's sound: look it up by the track from now on.
void SGLosslessStoreRemember(NSString *uri, NSString *path);

// What the Downloads page shows for a downloaded file, kept beside it (Documents/Lossless/.info.plist), by file name:
// uri (the Spotify track it plays with), title, artist, album, duration, cover (a file name in the covers folder).
// Any thread.
NSDictionary *_Nullable SGLosslessStoreInfo(NSString *fileName);
void SGLosslessStoreSetInfo(NSString *fileName, NSDictionary *info);
// Where the covers of downloaded files are kept (Documents/Lossless/.covers), and the path of one by its file name.
NSString *SGLosslessCoversDirectory(void);
// A file is gone: forget its info, its cover and any track the index sends to it.
void SGLosslessStoreForget(NSString *fileName);
// A FLAC's own tags and picture, read from the file with no network: title, artist, album (each present only when
// the file has it) and *cover, the front cover's bytes (JPEG or PNG) or nil. Any thread; nil when it is not a FLAC.
NSDictionary<NSString *, NSString *> *_Nullable SGLosslessReadTags(NSString *path, NSData *_Nullable *_Nullable cover);
NS_ASSUME_NONNULL_END
