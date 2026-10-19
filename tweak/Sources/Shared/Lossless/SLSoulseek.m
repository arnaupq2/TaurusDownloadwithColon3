// SLSoulseek.m — the Lossless downloader: it finds the FLAC or ALAC of a song on SpotiFlac
// (github.com/XerLib/SpotiFlac, api spotiflac.dev — the source colon3, github.com/AmineWallah/colon3,
// downloads from) and saves it in Documents/Lossless.
//
// SpotiFlac is a public HTTP API with no account and no password: nothing to set in Mod Settings,
// nothing kept in the Keychain. The flow mirrors colon3's SoulseekKit/SongFetcher — search, pick the
// best lossless file, fetch it — over URLSession instead of Soulseek's P2P sockets:
//
//   GET {base}/search?q=<artist title>&limit=25
//     -> {"results":[{"id","title","artist","album","duration","fileSize","quality":{"format",
//         "bitRate","bitDepth","sampleRate"},"thumbnail"...}], "provider":"..."}
//   GET {base}/download/<id>
//     -> JSON {"url": "..."} (a signed link), or the audio bytes sent straight back.
//
// A different base can be pointed at with the setting "spotifyglass.lossless.base" (an instance of
// SpotiFlac's self-hostable server); empty means the public one.
//
// Ranking follows colon3's TrackMatcher.score, trimmed to what the API answers: lossless FLAC/ALAC
// only, title checked against the Spotify track, artist somewhere in the credit, length within
// seconds of Spotify's, format and quality breaking ties; at most five candidates, tried in turn.
// The finished file lands named "<Title>.flac" in Documents/Lossless (SGLosslessStore), where the
// engine finds it by name and length without knowing the track URI yet — never in the lossy folder.
#import <sys/stat.h>
#import <unistd.h>

#import "Core/SGCore.h"
#import "SGLosslessStore.h"
#import "SLSoulseek.h"

static NSString *const kSearchPath = @"/search";        // + ?q=&limit=
static NSString *const kDownloadPath = @"/download/";   // + <id>
static const NSInteger kMaxCandidates = 5;              // best files first, tried in turn
static const NSTimeInterval kRequestTimeout = 30;       // per HTTP call
static const NSUInteger kMaxFileBytes = 500u * 1000 * 1000;  // no song is 500 MB

static NSString *slBaseURL(void) {
    NSString *set = [NSUserDefaults.standardUserDefaults stringForKey:@"spotifyglass.lossless.base"];
    NSString *base = set.length ? set : @"https://api.spotiflac.dev";
    while ([base hasSuffix:@"/"]) base = [base substringToIndex:base.length - 1];
    return base;
}

#pragma mark - matching (TrackMatching.swift, trimmed to what a single track needs)

static NSString *slFold(NSString *text) {
    return [text lowercaseString];
}

// Letters and digits only, any script (colon3's CharacterSet.alphanumerics = alpha union decimals).
static NSCharacterSet *slAlphanumericSet(void) {
    static NSCharacterSet *set;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ set = [NSCharacterSet alphanumericCharacterSet]; });
    return set;
}

static NSString *slAlphanumerics(NSString *text) {
    NSMutableString *out = [NSMutableString string];
    NSCharacterSet *allowed = slAlphanumericSet();
    NSUInteger i = 0;
    while (i < text.length) {
        NSRange atom = [text rangeOfComposedCharacterSequenceAtIndex:i];
        NSString *piece = [text substringWithRange:atom];
        if ([piece rangeOfCharacterFromSet:allowed].location != NSNotFound) [out appendString:[piece lowercaseString]];
        i = NSMaxRange(atom);
    }
    return out;
}

static NSString *slRegexReplace(NSString *text, NSString *pattern, NSString *template, NSRegularExpressionOptions options) {
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:options error:&error];
    if (!regex) return text;
    return [regex stringByReplacingMatchesInString:text options:0 range:NSMakeRange(0, text.length) withTemplate:template];
}

// "Song (feat. X) - 2011 Remaster" → "song".
static NSString *slNormalizeTitle(NSString *title) {
    NSString *folded = [title stringByFoldingWithOptions:NSDiacriticInsensitiveSearch | NSWidthInsensitiveSearch locale:nil];
    NSArray *patterns = @[@"\\([^)]*\\)", @"\\[[^\\]]*\\]", @"\\b(feat|ft|featuring)\\.?\\s.*$",
        @"\\s-\\s.*\\b(remaster|remastered|version|edit|mix|mono|stereo|live|recorded|single|radio|acoustic|demo|bonus|deluxe|explicit|instrumental|from|session|take)\\b.*$"];
    NSString *text = folded;
    for (NSString *pattern in patterns) text = slRegexReplace(text, pattern, @" ", NSRegularExpressionCaseInsensitive);
    NSString *result = slAlphanumerics(text);
    return result.length ? result : slAlphanumerics(folded);
}

// "The Beatles" → "beatles", "Simon & Garfunkel" → "simonandgarfunkel".
static NSString *slNormalizeName(NSString *name) {
    NSString *text = [name stringByFoldingWithOptions:NSDiacriticInsensitiveSearch | NSWidthInsensitiveSearch locale:nil];
    text = [text stringByReplacingOccurrencesOfString:@"&" withString:@" and "];
    text = [text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
    if ([text hasPrefix:@"the "] && text.length > 4) text = [text substringFromIndex:4];
    return slAlphanumerics(text);
}

static NSSet *slArtistKeys(NSString *credit) {
    NSMutableSet *keys = [NSMutableSet set];
    NSString *whole = slNormalizeName(credit);
    if (whole.length) [keys addObject:whole];
    NSString *separators = @"\\s*(,|;|/|&|\\+|\\bfeat\\b\\.?|\\bft\\b\\.?|\\bfeaturing\\b|\\bwith\\b|\\bvs\\b\\.?|\\bx\\b|\\band\\b)\\s*";
    NSString *marked = slRegexReplace(credit, separators, @"\u0001", NSRegularExpressionCaseInsensitive);
    for (NSString *part in [marked componentsSeparatedByString:@"\u0001"]) {
        NSString *key = slNormalizeName(part);
        if (key.length >= 2) [keys addObject:key];
    }
    return keys;
}

// live/remix/… words present in a name, so a Live version is never taken for the studio one.
static NSSet *slVariantWords(NSString *text) {
    static NSArray *pairs;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        pairs = @[@[@"live", @"\\blive\\b"], @[@"remix", @"\\b(re-?mix(es|ed)?|rmx)\\b"], @[@"karaoke", @"\\bkaraoke\\b"],
                 @[@"instrumental", @"\\binstrumentals?\\b"], @[@"acapella", @"\\ba\\s?cap+ell+a\\b"], @[@"cover", @"\\bcovers?\\b"],
                 @[@"tribute", @"\\btribute\\b"], @[@"nightcore", @"\\bnightcore\\b"], @[@"sped up", @"\\bsped\\s?up\\b"],
                 @[@"slowed", @"\\bslowed\\b"], @[@"acoustic", @"\\bacoustic\\b"], @[@"unplugged", @"\\bunplugged\\b"],
                 @[@"demo", @"\\bdemo\\b"], @[@"8bit", @"\\b8[\\s-]?bit\\b"], @[@"extended", @"\\bextended\\b"]];
    });
    NSString *folded = [@" " stringByAppendingString:[slFold(text) stringByReplacingOccurrencesOfString:@"[_.]" withString:@" " options:NSRegularExpressionSearch]];
    folded = [folded stringByAppendingString:@" "];
    NSMutableSet *found = [NSMutableSet set];
    for (NSArray *pair in pairs) {
        NSError *error = nil;
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pair[1] options:0 error:&error];
        if (regex && [regex firstMatchInString:folded options:0 range:NSMakeRange(0, folded.length)]) [found addObject:pair[0]];
    }
    return found;
}

// "Artist Title" with the version noise removed; words with apostrophes left out, as the server
// matches every word against the record (TrackMatcher.searchQuery).
static NSString *slSearchQuery(NSString *artist, NSString *title, BOOL includeArtist) {
    NSString *clean = [title stringByReplacingOccurrencesOfString:@"\\([^)]*\\)|\\[[^\\]]*\\]" withString:@" " options:NSRegularExpressionSearch range:NSMakeRange(0, title.length)];
    clean = [clean stringByReplacingOccurrencesOfString:@"\\s-\\s.*$" withString:@" " options:NSRegularExpressionSearch range:NSMakeRange(0, clean.length)];
    clean = [clean stringByReplacingOccurrencesOfString:@"\\b(feat|ft|featuring)\\.?\\s.*$" withString:@" " options:NSRegularExpressionSearch | NSRegularExpressionCaseInsensitive range:NSMakeRange(0, clean.length)];
    NSString *text = includeArtist && artist.length ? [NSString stringWithFormat:@"%@ %@", artist, clean] : clean;
    NSMutableArray *words = [NSMutableArray array];
    for (NSString *word in [text componentsSeparatedByCharactersInSet:NSCharacterSet.whitespaceCharacterSet]) {
        if ([word containsString:@"'"] || [word containsString:@"\u2019"]) continue;
        NSString *trimmed = [word stringByTrimmingCharactersInSet:slAlphanumericSet().invertedSet];
        if (trimmed.length) [words addObject:trimmed];
    }
    return [words componentsJoinedByString:@" "];
}

// One search result, however the server shaped its JSON: everything read defensively, because
// third-party SpotiFlac instances differ in which fields they fill.
@interface SLResult : NSObject
@property (nonatomic) NSString *ID, *title, *artist, *album, *format;
@property (nonatomic) double duration, fileSize;
@property (nonatomic) NSInteger bitrate, sampleRate, bitDepth, score;
@end

@implementation SLResult
@end

static id slDict(NSData *body) {
    if (!body.length) return nil;
    return [NSJSONSerialization JSONObjectWithData:body options:0 error:nil];
}

static NSString *slStr(NSDictionary *dict, NSString *key) {
    id value = dict[key];
    if ([value isKindOfClass:NSString.class]) return value;
    if ([value isKindOfClass:NSNumber.class]) return [value stringValue];
    return nil;
}

static double slNum(NSDictionary *dict, NSString *key) {
    id value = dict[key];
    return [value isKindOfClass:NSNumber.class] ? [value doubleValue] : 0;
}

// Reads one entry of {"results":[...]}; nil when it isn't a usable lossless file.
static SLResult *slParseResult(id entry) {
    if (![entry isKindOfClass:NSDictionary.class]) return nil;
    NSDictionary *dict = entry;
    NSString *ID = slStr(dict, @"id") ?: slStr(dict, @"trackId") ?: slStr(dict, @"track_id");
    if (!ID.length) return nil;
    NSDictionary *quality = [dict[@"quality"] isKindOfClass:NSDictionary.class] ? dict[@"quality"] : dict;
    SLResult *result = [SLResult new];
    result.ID = ID;
    result.title = slStr(dict, @"title") ?: @"";
    result.artist = slStr(dict, @"artist") ?: slStr(dict, @"artists") ?: @"";
    result.album = slStr(dict, @"album") ?: @"";
    result.duration = slNum(dict, @"duration");
    result.fileSize = slNum(dict, @"fileSize") ?: slNum(dict, @"size");
    NSString *format = slStr(quality, @"format") ?: slStr(dict, @"format");
    result.format = format.length ? [format lowercaseString] : @"";
    result.bitrate = (NSInteger)slNum(quality, @"bitRate");
    result.sampleRate = (NSInteger)slNum(quality, @"sampleRate");
    result.bitDepth = (NSInteger)slNum(quality, @"bitDepth");
    // No format field: guess it from whatever names the file, so an instance that only says
    // "FLAC" in the quality string still counts.
    if (!result.format.length) {
        NSString *hint = slFold([NSString stringWithFormat:@"%@ %@", slStr(dict, @"fileType") ?: @"", slStr(dict, @"quality") ?: @""]);
        if ([hint containsString:@"flac"]) result.format = @"flac";
        else if ([hint containsString:@"m4a"] || [hint containsString:@"alac"]) result.format = @"m4a";
    }
    return result;
}

// colon3's score, lossless-only: NSIntegerMin rejects the file, higher wins.
static NSInteger slScore(SLResult *file, NSSet *wantedArtists, NSString *wantedTitle, NSSet *wantedVariants,
                         double wantedDuration, NSString *haystack) {
    if (![file.format isEqualToString:@"flac"] && ![file.format isEqualToString:@"m4a"]) return NSIntegerMin;
    if (file.fileSize > 0 && file.fileSize <= 400000) return NSIntegerMin;  // too small to be lossless
    if (!wantedTitle.length) return NSIntegerMin;
    NSString *fileTitle = slNormalizeTitle(file.title);
    if (![fileTitle containsString:wantedTitle]) return NSIntegerMin;

    NSInteger score = 0;
    NSString *residual = fileTitle;
    for (NSString *artist in [wantedArtists.allObjects sortedUsingSelector:@selector(compare:)]) {
        if (artist.length < 2) continue;
        NSRange found = [residual rangeOfString:artist];
        if (found.location != NSNotFound) { residual = [residual stringByReplacingCharactersInRange:found withString:@""]; break; }
    }
    NSUInteger start = 0;
    while (start < residual.length && [residual characterIsDigit:start]) start++;
    residual = [residual substringFromIndex:start];
    if ([residual isEqualToString:wantedTitle]) score += 20;
    else if ([residual hasSuffix:wantedTitle] || [residual hasPrefix:wantedTitle]) {
        score += 8;
        if ((NSInteger)residual.length - (NSInteger)wantedTitle.length > 14) score -= 10;
    } else if (wantedTitle.length < 8) return NSIntegerMin;

    NSString *normalizedHay = slNormalizeName(haystack);
    BOOL artistInPath = NO;
    for (NSString *artist in wantedArtists) if (artist.length >= 2 && [normalizedHay containsString:artist]) { artistInPath = YES; break; }
    if (artistInPath) score += 10;
    else score -= 15;

    NSSet *variants = slVariantWords(haystack);
    for (NSString *variant in variants) if (![wantedVariants containsObject:variant]) return NSIntegerMin;
    if (wantedVariants.count && ![variants intersectsSet:wantedVariants]) score -= 10;

    if (wantedDuration > 0) {
        if (file.duration > 0) {
            double difference = fabs(file.duration - wantedDuration);
            if (difference <= 2) score += 15;
            else if (difference <= 5) score += 10;
            else if (difference <= 10) score += 3;
            else if (difference <= 20) score -= 10;
            else return NSIntegerMin;
        } else score -= 3;
    }
    if (file.sampleRate > 192000) return NSIntegerMin;  // DXD rips
    score += 30;                                        // flac/m4a both reach here: lossless
    if (file.sampleRate > 96000) score -= 8;            // hi-res costs 3–6× the download
    return score;
}

// Rank the parsed results, at most kMaxCandidates, best first (SongFetcher takes five and tries
// them in turn).
static NSArray<SLResult *> *slCandidates(NSArray *raw, NSString *title, NSSet *artists, NSSet *variants, double duration) {
    NSString *wantedTitle = slNormalizeTitle(title);
    NSMutableArray<SLResult *> *scored = [NSMutableArray array];
    for (id entry in raw) {
        SLResult *result = slParseResult(entry);
        if (!result) continue;
        NSString *haystack = [NSString stringWithFormat:@"%@ %@ %@", result.title, result.artist, result.album];
        NSInteger score = slScore(result, artists, wantedTitle, variants, duration, haystack);
        if (score == NSIntegerMin) continue;
        result.score = score;
        [scored addObject:result];
    }
    [scored sortUsingComparator:^NSComparisonResult(SLResult *a, SLResult *b) {
        return [@(b.score) compare:@(a.score)];  // best first
    }];
    if (scored.count > kMaxCandidates) [scored removeObjectsInRange:NSMakeRange(kMaxCandidates, scored.count - kMaxCandidates)];
    return scored;
}

#pragma mark - the HTTP plumbing

// One synchronous GET, the body or nil. Runs on the fetch operation's own thread, so a plain
// semaphore is safe here.
static NSData *slGetBody(NSString *urlString, NSURLResponse *_Nullable *_Nullable responseOut, NSError *_Nullable *_Nullable errorOut) {
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) {
        if (errorOut) *errorOut = [NSError errorWithDomain:@"SpotiFlac" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Bad URL"}];
        return nil;
    }
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.timeoutInterval = kRequestTimeout;
    __block NSData *body = nil;
    __block NSURLResponse *response = nil;
    __block NSError *failure = nil;
    dispatch_semaphore_t done = dispatch_semaphore_create(0);
    NSURLSessionDataTask *task = [NSURLSession.sharedSession dataTaskWithRequest:request
                                                                  completionHandler:^(NSData *data, NSURLResponse *resp, NSError *error) {
        body = data; response = resp; failure = error;
        dispatch_semaphore_signal(done);
    }];
    [task resume];
    dispatch_semaphore_wait(done, DISPATCH_TIME_FOREVER);
    if (responseOut) *responseOut = response;
    if (errorOut) *errorOut = failure;
    return body;
}

// The search page: /search?q=…&limit=25 -> {"results":[…]}. Returns the raw entries, [] when none.
static NSArray *slSearchResults(NSString *query) {
    NSString *encoded = [query stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet] ?: @"";
    NSString *url = [NSString stringWithFormat:@"%@%@?q=%@&limit=25", slBaseURL(), kSearchPath, encoded];
    NSError *error = nil;
    NSData *body = slGetBody(url, nil, &error);
    if (error) { SGLog(@"lossless: spotiflac search failed: %@", error.localizedDescription); return @[]; }
    id json = slDict(body);
    if ([json isKindOfClass:NSArray.class]) return json;  // some instances answer the list straight
    if (![json isKindOfClass:NSDictionary.class]) return @[];
    for (NSString *key in @[@"results", @"tracks", @"items"]) {
        NSArray *list = json[key];
        if ([list isKindOfClass:NSArray.class]) return list;
    }
    return @[];
}

// /download/<id>: either JSON with a signed link, or the audio bytes themselves. `link` comes back
// with the URL to fetch when the answer was JSON.
static NSData *slDownloadCall(NSString *ID, NSString *_Nullable *_Nullable link) {
    NSString *encoded = [ID stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLPathAllowedCharacterSet] ?: @"";
    NSString *url = [NSString stringWithFormat:@"%@%@%@", slBaseURL(), kDownloadPath, encoded];
    NSURLResponse *response = nil;
    NSError *error = nil;
    NSData *body = slGetBody(url, &response, &error);
    if (error) return nil;
    NSString *type = [response isKindOfClass:NSHTTPURLResponse.class] ? ((NSHTTPURLResponse *)response).MIMEType.lowercaseString : @"";
    id json = [type containsString:@"json"] ? slDict(body) : nil;
    if (!json && body.length < 4096) json = slDict(body);  // a small body that parses: an answer, not the song
    if ([json isKindOfClass:NSDictionary.class]) {
        NSString *href = slStr(json, @"url") ?: slStr(json, @"downloadUrl") ?: slStr(json, @"link");
        if (link) *link = href;
        return nil;  // the bytes come from the link, not from this call
    }
    return body;  // the server sent the file itself
}

// Streams one URL into `destination`, reporting fractions. A temporary ".part" file becomes the
// real one only when the whole body arrived, so a half download never sits in Lossless.
static BOOL slStream(NSString *urlString, NSString *destination, uint64_t expected,
                     SLDownloadProgress progress, NSOperation *operation, NSString **error) {
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) { *error = @"The server gave a bad link."; return NO; }
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.timeoutInterval = kRequestTimeout;
    NSString *partPath = [destination stringByAppendingPathExtension:@"part"];
    [[NSFileManager defaultFileManager] removeItemAtPath:partPath error:nil];
    NSFileHandle *handle = [NSFileHandle fileHandleForCreatingAtPath:partPath];
    if (!handle) { *error = @"Can't write the file."; return NO; }
    __block BOOL ok = NO;
    __block uint64_t received = 0;
    __block NSString *failure = nil;
    __block NSURLSessionDataTask *task = nil;
    dispatch_semaphore_t done = dispatch_semaphore_create(0);
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    config.timeoutIntervalForRequest = kRequestTimeout;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    void (^append)(NSData *) = ^(NSData *chunk) {
        @try { [handle writeData:chunk]; } @catch (NSException *e) { failure = @"The disk refused the file."; };
        received += chunk.length;
        if (received > kMaxFileBytes) { failure = @"The file is too large to be a song."; [task cancel]; }
        if (progress) {
            double fraction = expected ? MIN(1.0, (double)received / expected) : 0;
            dispatch_async(dispatch_get_main_queue(), ^{ progress(SLProgressTransferring, fraction, nil); });
        }
    };
    task = [session dataTaskWithRequest:request completionHandler:^(NSData *body, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *http = [response isKindOfClass:NSHTTPURLResponse.class] ? (id)response : nil;
        if (!error && http.statusCode >= 400) failure = [NSString stringWithFormat:@"The server answered %ld.", (long)http.statusCode];
        if (!error && !failure && body.length) append(body);
        if (!error && !failure && !body.length) failure = @"The link came back empty.";
        if (error && !failure) failure = error.localizedDescription;
        dispatch_semaphore_signal(done);
    }];
    [task resume];
    dispatch_semaphore_wait(done, DISPATCH_TIME_FOREVER);
    [handle closeFile];
    [session finishTasksAndInvalidate];
    if (operation.isCancelled) { remove(partPath.UTF8String); *error = @"Cancelled."; return NO; }
    if (failure) { remove(partPath.UTF8String); *error = failure; return NO; }
    uint64_t size = [[NSFileManager defaultFileManager] attributesOfItemAtPath:partPath error:nil].fileSize;
    if (!size) { remove(partPath.UTF8String); *error = @"Nothing came through."; return NO; }
    if (expected && size < expected) {  // truncated: the sender closed early
        remove(partPath.UTF8String); *error = @"The transfer stopped partway."; return NO;
    }
    NSURL *final = [NSURL fileURLWithPath:destination];
    [[NSFileManager defaultFileManager] removeItemAtURL:final error:nil];
    if (![[NSFileManager defaultFileManager] moveItemAtURL:[NSURL fileURLWithPath:partPath] toURL:final error:nil]) {
        remove(partPath.UTF8String); *error = @"Can't write the file."; return NO;
    }
    ok = YES;
    if (progress) dispatch_async(dispatch_get_main_queue(), ^{ progress(SLProgressTransferring, 1.0, nil); });
    return ok;
}

#pragma mark - the fetch (SongFetcher.swift, one song at a time)

@interface SLFetchOperation : NSOperation
@property (nonatomic, copy) NSString *title, *artist;
@property (nonatomic) double duration;
@property (nonatomic, copy) SLDownloadProgress progress;
@property (nonatomic, strong) NSURL *result;
@property (nonatomic, copy) NSString *failure;
@end

@implementation SLFetchOperation

- (void)main {
    @autoreleasepool {
        if (self.isCancelled) return;
        [self report:SLProgressSearching fraction:0 source:nil];

        NSSet *artists = self.artist.length ? slArtistKeys(self.artist) : [NSSet set];
        NSSet *variants = slVariantWords(self.title);
        NSArray *candidates = nil;
        NSString *query = slSearchQuery(self.artist, self.title, YES);
        if (query.length) {
            candidates = slCandidates(slSearchResults(query), self.title, artists, variants, self.duration);
        }
        if (!candidates.count && self.artist.length) {  // title alone, artist checked in the record
            NSString *titleOnly = slSearchQuery(nil, self.title, NO);
            if (titleOnly.length >= 4 && !self.isCancelled) {
                candidates = slCandidates(slSearchResults(titleOnly), self.title, artists, variants, self.duration);
            }
        }
        if (!candidates.count) {
            self.failure = @"No lossless copy of this song on SpotiFlac.";
            return;
        }
        if (self.isCancelled) return;

        NSString *directory = SGLosslessStoreDirectory();
        NSString *lastReason = nil;
        for (SLResult *candidate in candidates) {
            if (self.isCancelled) break;
            NSString *extension = candidate.format.length ? candidate.format : @"flac";
            NSString *name = [NSString stringWithFormat:@"%@.%@", self.title, extension];
            NSString *destination = [directory stringByAppendingPathComponent:name];
            for (int n = 2; [[NSFileManager defaultFileManager] fileExistsAtPath:destination]; n++) {
                destination = [directory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@ %d.%@", self.title, n, extension]];
            }
            NSString *source = [NSString stringWithFormat:@"%@%@\u00A0·\u00A0SpotiFlac", extension.uppercased(),
                                candidate.bitDepth > 0 ? [NSString stringWithFormat:@" %ld/%.1f",
                                    (long)candidate.bitDepth, candidate.sampleRate / 1000.0] : @""];
            [self report:SLProgressQueued fraction:0 source:source];

            // Ask for the file: a signed link to stream, or the bytes straight from the API.
            NSString *link = nil;
            NSData *inlineBytes = slDownloadCall(candidate.ID, &link);
            NSString *error = nil;
            BOOL got = NO;
            if (link.length) {
                got = slStream(link, destination, (uint64_t)candidate.fileSize,
                               ^(SLDownloadPhase phase, double fraction, NSString *nilSource) {
                    [self report:phase fraction:fraction source:source];
                }, self, &error);
            } else if (inlineBytes.length) {  // the server sent the audio itself
                NSString *partPath = [destination stringByAppendingPathExtension:@"part"];
                if ([inlineBytes writeToFile:partPath atomically:YES]) {
                    [[NSFileManager defaultFileManager] removeItemAtPath:destination error:nil];
                    got = [[NSFileManager defaultFileManager] moveItemAtPath:partPath toPath:destination error:&error];
                    if (got) [self report:SLProgressTransferring fraction:1.0 source:source];
                }
            } else {
                error = link.length ? nil : @"SpotiFlac had no link for this file.";
            }
            if (got) {
                self.result = [NSURL fileURLWithPath:destination];
                break;
            }
            SGLog(@"lossless: %@ failed (%@), trying the next file", candidate.ID, error);
            lastReason = error;
            if (self.isCancelled) break;
        }
        if (!self.result && !self.failure) self.failure = lastReason ?: @"The download failed.";
    }
}

- (void)report:(SLDownloadPhase)phase fraction:(double)fraction source:(NSString *)source {
    SLDownloadProgress block = self.progress;
    if (block) dispatch_async(dispatch_get_main_queue(), ^{ block(phase, fraction, source); });
}

@end

NSOperation *SLDownloadLossless(NSString *title, NSString *artist, double durationSeconds,
                                SLDownloadProgress progress, void (^_Nullable completion)(NSURL *_Nullable, NSString *_Nullable)) {
    SLFetchOperation *operation = [SLFetchOperation new];
    operation.title = title;
    operation.artist = artist;
    operation.duration = durationSeconds;
    operation.progress = progress;
    // The result comes back on the main thread when the operation ends.
    operation.completionBlock = ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion(operation.result, operation.failure);
        });
    };
    [[NSOperationQueue new] addOperation:operation];  // a private queue: it blocks on HTTP waits
    return operation;
}
