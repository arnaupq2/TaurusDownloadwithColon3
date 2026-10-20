#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// The Lossless downloader: a small Soulseek client. It signs in with the account saved in Mod Settings >
// Soulseek account (SLSoulseekAccountPage), searches the network, and fetches the best FLAC / ALAC a peer
// shares. The protocol lives in SLSoulseek.m.

typedef enum {
    SLProgressSearching,
    SLProgressQueued,        // a peer was picked; waiting in its queue for the first byte
    SLProgressTransferring,  // fraction is 0..1
} SLDownloadPhase;

// Called on the main thread while fetching. `source` names the format and the peer ("FLAC 16/44.1 · user"),
// nil while searching.
typedef void (^SLDownloadProgress)(SLDownloadPhase phase, double fraction, NSString *_Nullable source);

// Any thread, blocking: searches Soulseek for the song and downloads the best lossless file (FLAC or
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
