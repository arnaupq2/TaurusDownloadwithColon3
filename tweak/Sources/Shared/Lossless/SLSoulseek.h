#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// SpotiFlac (github.com/XerLib/SpotiFlac, api spotiflac.dev), the lossless source colon3
// (github.com/AmineWallah/colon3) downloads from: a public HTTP API — no account, no password,
// nothing kept in the Keychain. The calls it needs (GET /search?q=… and GET /download/<id>) are
// implemented over URLSession in SLSoulseek.m; see the notes there.

typedef enum {
    SLProgressSearching,
    SLProgressQueued,        // the server picked a file for us; waiting for the first byte
    SLProgressTransferring,  // fraction is 0..1
} SLDownloadPhase;

// Called on the main thread while fetching. `source` names the format ("FLAC 16/44.1 · SpotiFlac"),
// nil while searching.
typedef void (^SLDownloadProgress)(SLDownloadPhase phase, double fraction, NSString *_Nullable source);

// Any thread, blocking: searches SpotiFlac for the song and downloads the best lossless file (FLAC or
// ALAC/M4A) into Spotify's Documents/Lossless folder (SGLosslessStore), named after the track so the
// store finds it by title and length even before its URI is known — never into the lossy folder.
// Cancelling the returned operation stops the search and the transfer.
//
// durationSeconds <= 0 means the length is not known: candidates are not checked against one.
// `completion` runs on the main thread with the file's URL, or nil and the reason nothing came.
NSOperation *_Nullable SLDownloadLossless(NSString *title, NSString *_Nullable artist, double durationSeconds,
                                          SLDownloadProgress _Nullable progress,
                                          void (^_Nullable completion)(NSURL *_Nullable path, NSString *_Nullable error));

NS_ASSUME_NONNULL_END
