// SLSoulseek.m — the Lossless downloader: a small Soulseek client. It logs in to the Soulseek server with the
// account saved in Mod Settings > Soulseek account, searches the network for the song, ranks the FLAC / ALAC
// files peers offer (colon3's TrackMatcher.score, trimmed), asks the best peer for the file, waits in its queue
// and saves the transfer in Documents/Lossless.
//
// Protocol notes (all integers little-endian; a frame is uint32 length + body):
//   server  : uint32 code + payload   login 1, GetPeerAddress 3, ConnectToPeer 18, FileSearch 26, SetStatus 28,
//             SharedFoldersFiles 35
//   peer 'P': first message uint8 init code (0 PierceFirewall(token), 1 PeerInit(user, type, token)), then
//             uint32-coded messages: FileSearchResponse 9 (zlib), TransferRequest 40, TransferResponse 41,
//             PlaceInQueueResponse 44, UploadFailed 46, UploadDenied 50, QueueUpload 43
//   peer 'F': after the init, the uploader sends the transfer token (uint32), we answer with the offset
//             (uint64) and the raw file bytes follow until the size announced in TransferRequest.
//
// This client does not listen for incoming connections (a phone is almost always behind NAT): peers that cannot
// reach us ask the server to tell us to connect to them (ConnectToPeer), which we do and answer with
// PierceFirewall. Search answers and file transfers both arrive that way.
//
// The finished file lands named "<Title>.flac" in Documents/Lossless (SGLosslessStore), where the engine finds
// it by name and length without knowing the track URI yet — never in the lossy folder.
#import <arpa/inet.h>
#import <errno.h>
#import <fcntl.h>
#import <netdb.h>
#import <netinet/in.h>
#import <sys/select.h>
#import <sys/socket.h>
#import <sys/stat.h>
#import <unistd.h>
#import <zlib.h>
#import <CommonCrypto/CommonDigest.h>

#import "Core/SGCore.h"
#import "SGLosslessStore.h"
#import "SLSoulseek.h"
#import "SLSoulseekAccountPage.h"

static const NSInteger kMaxCandidates = 6;                  // best files first, tried in turn
static const NSTimeInterval kSearchSeconds = 14;            // results keep arriving this long
static const NSTimeInterval kSearchExtraSeconds = 10;       // extra wait when nothing usable has come yet
static const NSTimeInterval kWaitSlotFree = 60;             // for a peer that says it has a free slot
static const NSTimeInterval kWaitQueued = 90;               // for a peer that keeps a queue
static const NSTimeInterval kStallSeconds = 30;             // a transfer with no byte for this long is dead
static const uint64_t kMaxFileBytes = 500ull * 1000 * 1000; // no song is 500 MB
static NSString *const kServerHost = @"server.slsknet.org";
static const int kServerPort = 2242;

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
    NSString *marked = slRegexReplace(credit, separators, @"\n", NSRegularExpressionCaseInsensitive);
    for (NSString *part in [marked componentsSeparatedByString:@"\n"]) {
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
    NSString *folded = [@" " stringByAppendingString:[slFold(text) stringByReplacingOccurrencesOfString:@"[_.]" withString:@" " options:NSRegularExpressionSearch range:NSMakeRange(0, slFold(text).length)]];
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

#pragma mark - one file a peer offers

@interface SLResult : NSObject
@property (nonatomic) NSString *username, *path, *title, *artist, *album, *format;  // path: "dir\sub\01 Song.flac"
@property (nonatomic) NSData *rawPath;                                              // as the peer sent it, for QueueUpload
@property (nonatomic) double duration, fileSize;
@property (nonatomic) NSInteger bitrate, sampleRate, bitDepth, score, speed, queueLength;
@property (nonatomic) BOOL slotFree;
@end

@implementation SLResult
@end

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
    for (NSString *artist in [wantedArtists.allObjects sortedArrayUsingSelector:@selector(compare:)]) {
        if (artist.length < 2) continue;
        NSRange found = [residual rangeOfString:artist];
        if (found.location != NSNotFound) { residual = [residual stringByReplacingCharactersInRange:found withString:@""]; break; }
    }
    NSUInteger start = 0;
    while (start < residual.length && [[NSCharacterSet decimalDigitCharacterSet] characterIsMember:[residual characterAtIndex:start]]) start++;
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


// Rank what peers offered, best first. A peer is tried once (its best file), then the next peer: a user who
// is offline or has no slot would fail the same way on every one of his files.
static NSArray<SLResult *> *slCandidates(NSArray<SLResult *> *offered, NSString *title, NSSet *artists, NSSet *variants, double duration) {
    NSString *wantedTitle = slNormalizeTitle(title);
    NSMutableArray<SLResult *> *scored = [NSMutableArray array];
    for (SLResult *result in offered) {
        NSString *haystack = [NSString stringWithFormat:@"%@ %@", result.path, result.title];
        NSInteger score = slScore(result, artists, wantedTitle, variants, duration, haystack);
        if (score == NSIntegerMin) continue;
        if (result.slotFree) score += 12;                       // starts at once
        score -= MIN(result.queueLength, 400) / 20;             // a long queue is a long wait
        if (result.speed > 1000000) score += 4;                 // 1 MB/s and up
        result.score = score;
        [scored addObject:result];
    }
    [scored sortUsingComparator:^NSComparisonResult(SLResult *a, SLResult *b) {
        return [@(b.score) compare:@(a.score)];  // best first
    }];
    NSMutableArray<SLResult *> *best = [NSMutableArray array];
    NSMutableSet *users = [NSMutableSet set];
    for (SLResult *result in scored) {
        if ([users containsObject:result.username]) continue;
        [users addObject:result.username];
        [best addObject:result];
        if ((NSInteger)best.count >= kMaxCandidates) break;
    }
    return best;
}

// A track title as a file name: no path separators or characters iOS file names dislike.
static NSString *slSafeName(NSString *title) {
    NSMutableString *name = [title mutableCopy];
    for (NSString *bad in @[@"/", @"\\", @":", @"*", @"?", @"\"", @"<", @">", @"|"]) {
        [name replaceOccurrencesOfString:bad withString:@"-" options:0 range:NSMakeRange(0, name.length)];
    }
    NSString *trimmed = [name stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    return trimmed.length ? trimmed : @"Track";
}

#pragma mark - wire helpers

static void slPut8(NSMutableData *data, uint8_t value) { [data appendBytes:&value length:1]; }

static void slPut32(NSMutableData *data, uint32_t value) {
    uint8_t bytes[4] = { (uint8_t)value, (uint8_t)(value >> 8), (uint8_t)(value >> 16), (uint8_t)(value >> 24) };
    [data appendBytes:bytes length:4];
}

static void slPut64(NSMutableData *data, uint64_t value) {
    slPut32(data, (uint32_t)value);
    slPut32(data, (uint32_t)(value >> 32));
}

static void slPutData(NSMutableData *data, NSData *bytes) {
    slPut32(data, (uint32_t)bytes.length);
    [data appendData:bytes];
}

static void slPutString(NSMutableData *data, NSString *text) {
    slPutData(data, [text dataUsingEncoding:NSUTF8StringEncoding] ?: [NSData data]);
}

// A frame: uint32 length, then the body.
static NSData *slFrame(NSData *body) {
    NSMutableData *frame = [NSMutableData dataWithCapacity:body.length + 4];
    slPut32(frame, (uint32_t)body.length);
    [frame appendData:body];
    return frame;
}

// A server or peer message: uint32 code + payload.
static NSData *slMessage(uint32_t code, NSData *payload) {
    NSMutableData *body = [NSMutableData data];
    slPut32(body, code);
    if (payload) [body appendData:payload];
    return slFrame(body);
}

typedef struct { const uint8_t *bytes; NSUInteger length, offset; BOOL bad; } SLReader;

static SLReader slReader(NSData *data, NSUInteger offset) {
    SLReader reader = { data.bytes, data.length, offset, NO };
    return reader;
}

static uint8_t slGet8(SLReader *r) {
    if (r->bad || r->offset + 1 > r->length) { r->bad = YES; return 0; }
    return r->bytes[r->offset++];
}

static uint32_t slGet32(SLReader *r) {
    if (r->bad || r->offset + 4 > r->length) { r->bad = YES; return 0; }
    const uint8_t *b = r->bytes + r->offset;
    r->offset += 4;
    return (uint32_t)b[0] | ((uint32_t)b[1] << 8) | ((uint32_t)b[2] << 16) | ((uint32_t)b[3] << 24);
}

static uint64_t slGet64(SLReader *r) {
    uint64_t low = slGet32(r);
    uint64_t high = slGet32(r);
    return low | (high << 32);
}

// A length-prefixed string's raw bytes.
static NSData *slGetData(SLReader *r) {
    uint32_t length = slGet32(r);
    if (r->bad || length > r->length - r->offset) { r->bad = YES; return nil; }
    NSData *bytes = [NSData dataWithBytes:r->bytes + r->offset length:length];
    r->offset += length;
    return bytes;
}

// UTF-8, or Latin-1 for the peers whose clients still send it.
static NSString *slText(NSData *bytes) {
    if (!bytes) return nil;
    return [[NSString alloc] initWithData:bytes encoding:NSUTF8StringEncoding]
        ?: [[NSString alloc] initWithData:bytes encoding:NSISOLatin1StringEncoding] ?: @"";
}

static NSString *slGetString(SLReader *r) {
    return slText(slGetData(r));
}

// Soulseek sends an address as a little-endian uint32 whose most significant byte is the first octet:
// 0x7F000001 is 127.0.0.1.
static NSString *slAddress(uint32_t value) {
    return [NSString stringWithFormat:@"%u.%u.%u.%u", value >> 24, (value >> 16) & 255, (value >> 8) & 255, value & 255];
}

static NSData *slInflate(NSData *packed) {
    z_stream stream;
    memset(&stream, 0, sizeof stream);
    if (inflateInit(&stream) != Z_OK) return nil;
    NSMutableData *out = [NSMutableData data];
    uint8_t chunk[16384];
    stream.next_in = (Bytef *)packed.bytes;
    stream.avail_in = (uInt)packed.length;
    int status = Z_OK;
    while (status == Z_OK) {
        stream.next_out = chunk;
        stream.avail_out = sizeof chunk;
        status = inflate(&stream, Z_NO_FLUSH);
        if (status != Z_OK && status != Z_STREAM_END) { inflateEnd(&stream); return nil; }
        [out appendBytes:chunk length:sizeof chunk - stream.avail_out];
        if (out.length > 8u * 1024 * 1024) break;   // a search answer is never this big
    }
    inflateEnd(&stream);
    return out;
}

#pragma mark - sockets

typedef BOOL (^SLStop)(void);

static BOOL slSendAll(int fd, NSData *data) {
    const uint8_t *bytes = data.bytes;
    size_t sent = 0;
    while (sent < data.length) {
        ssize_t count = send(fd, bytes + sent, data.length - sent, 0);
        if (count < 0 && errno == EINTR) continue;
        if (count <= 0) return NO;
        sent += (size_t)count;
    }
    return YES;
}

// recv has a one second timeout (SO_RCVTIMEO), so `stop` is asked about every second while waiting.
static BOOL slReadExact(int fd, void *buffer, size_t length, SLStop stop) {
    uint8_t *bytes = buffer;
    size_t got = 0;
    while (got < length) {
        if (stop && stop()) return NO;
        ssize_t count = recv(fd, bytes + got, length - got, 0);
        if (count > 0) { got += (size_t)count; continue; }
        if (count == 0) return NO;
        if (errno == EINTR || errno == EAGAIN || errno == EWOULDBLOCK) continue;
        return NO;
    }
    return YES;
}

// One frame's body, or nil on close, stop or nonsense.
static NSData *slReadFrame(int fd, SLStop stop) {
    uint8_t head[4];
    if (!slReadExact(fd, head, 4, stop)) return nil;
    uint32_t length = (uint32_t)head[0] | ((uint32_t)head[1] << 8) | ((uint32_t)head[2] << 16) | ((uint32_t)head[3] << 24);
    if (length > 64u * 1024 * 1024) return nil;
    NSMutableData *body = [NSMutableData dataWithLength:length];
    if (length && !slReadExact(fd, body.mutableBytes, length, stop)) return nil;
    return body;
}

static void slTune(int fd) {
    int on = 1;
    setsockopt(fd, SOL_SOCKET, SO_NOSIGPIPE, &on, sizeof on);
    struct timeval receive = { 1, 0 }, send = { 15, 0 };
    setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &receive, sizeof receive);
    setsockopt(fd, SOL_SOCKET, SO_SNDTIMEO, &send, sizeof send);
}

static int slConnectAddress(const struct sockaddr *address, socklen_t length, int family, int timeoutSeconds, SLStop stop) {
    int fd = socket(family, SOCK_STREAM, 0);
    if (fd < 0) return -1;
    int flags = fcntl(fd, F_GETFL, 0);
    fcntl(fd, F_SETFL, flags | O_NONBLOCK);
    int result = connect(fd, address, length);
    if (result < 0 && errno != EINPROGRESS) { close(fd); return -1; }
    if (result < 0) {
        for (int waited = 0; waited < timeoutSeconds * 4; waited++) {   // quarter seconds, so a stop is noticed
            if (stop && stop()) { close(fd); return -1; }
            fd_set writable;
            FD_ZERO(&writable);
            FD_SET(fd, &writable);
            struct timeval slice = { 0, 250000 };
            int ready = select(fd + 1, NULL, &writable, NULL, &slice);
            if (ready < 0 && errno != EINTR) { close(fd); return -1; }
            if (ready > 0) {
                int error = 0;
                socklen_t size = sizeof error;
                if (getsockopt(fd, SOL_SOCKET, SO_ERROR, &error, &size) < 0 || error) { close(fd); return -1; }
                result = 0;
                break;
            }
        }
        if (result != 0) { close(fd); return -1; }
    }
    fcntl(fd, F_SETFL, flags);
    slTune(fd);
    return fd;
}

static int slConnectIP(NSString *ip, uint32_t port, int timeoutSeconds, SLStop stop) {
    struct sockaddr_in address;
    memset(&address, 0, sizeof address);
    address.sin_family = AF_INET;
    address.sin_port = htons((uint16_t)port);
    if (port == 0 || port > 65535 || inet_pton(AF_INET, ip.UTF8String, &address.sin_addr) != 1) return -1;
    return slConnectAddress((struct sockaddr *)&address, sizeof address, AF_INET, timeoutSeconds, stop);
}

static int slConnectHost(NSString *host, int port, int timeoutSeconds, SLStop stop) {
    struct addrinfo hints, *list = NULL;
    memset(&hints, 0, sizeof hints);
    hints.ai_family = AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    NSString *service = [NSString stringWithFormat:@"%d", port];
    if (getaddrinfo(host.UTF8String, service.UTF8String, &hints, &list) != 0 || !list) return -1;
    int fd = -1;
    for (struct addrinfo *a = list; a && fd < 0; a = a->ai_next) {
        fd = slConnectAddress(a->ai_addr, (socklen_t)a->ai_addrlen, a->ai_family, timeoutSeconds, stop);
    }
    freeaddrinfo(list);
    return fd;
}

static NSData *slLoginFrame(NSString *username, NSString *password) {
    NSData *input = [[username stringByAppendingString:password] dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    // The login handshake of the protocol wants MD5(username + password); compatibility, not storage.
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated-declarations"
    CC_MD5(input.bytes, (CC_LONG)input.length, digest);
    #pragma clang diagnostic pop
    NSMutableString *hex = [NSMutableString string];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) [hex appendFormat:@"%02x", digest[i]];
    NSMutableData *payload = [NSMutableData data];
    slPutString(payload, username);
    slPutString(payload, password);
    slPut32(payload, 160);          // client version
    slPutString(payload, hex);
    slPut32(payload, 1);            // minor version
    return slMessage(1, payload);
}

// A FLAC file starts with "fLaC"; many rips carry an ID3v2 tag in front of it. Returns the offset of "fLaC", or -1.
static long long slFlacOffset(NSString *path) {
    FILE *file = fopen(path.UTF8String, "rb");
    if (!file) return -1;
    uint8_t head[10] = {0};
    long long offset = -1;
    size_t got = fread(head, 1, 10, file);
    if (got >= 4 && memcmp(head, "fLaC", 4) == 0) offset = 0;
    else if (got == 10 && memcmp(head, "ID3", 3) == 0) {
        long long tag = ((head[6] & 0x7F) << 21) | ((head[7] & 0x7F) << 14) | ((head[8] & 0x7F) << 7) | (head[9] & 0x7F);
        tag += 10 + ((head[5] & 0x10) ? 10 : 0);
        uint8_t magic[4] = {0};
        if (fseeko(file, (off_t)tag, SEEK_SET) == 0 && fread(magic, 1, 4, file) == 4 && memcmp(magic, "fLaC", 4) == 0) offset = tag;
    }
    fclose(file);
    return offset;
}

// Drop the first `offset` bytes of a file in place (the ID3 tag in front of a FLAC).
static BOOL slCutHead(NSString *path, long long offset) {
    NSString *tmp = [path stringByAppendingString:@".cut"];
    FILE *in = fopen(path.UTF8String, "rb"), *out = fopen(tmp.UTF8String, "wb");
    BOOL ok = in && out && fseeko(in, (off_t)offset, SEEK_SET) == 0;
    uint8_t buffer[65536];
    size_t n;
    while (ok && (n = fread(buffer, 1, sizeof buffer, in)) > 0) ok = fwrite(buffer, 1, n, out) == n;
    if (in) fclose(in);
    if (out) fclose(out);
    if (ok) ok = rename(tmp.UTF8String, path.UTF8String) == 0;
    if (!ok) remove(tmp.UTF8String);
    return ok;
}

#pragma mark - a transfer waiting for its file

// One file asked of one peer. state: 0 queued, 1 the peer is ready to send (waiting for its file connection),
// 2 done, 3 failed.
@interface SLPending : NSObject
@property (nonatomic, copy) NSString *user, *filename, *destination, *reason;
@property (nonatomic) NSData *rawName;
@property (nonatomic) uint64_t size;
@property (nonatomic) uint32_t token;
@property (nonatomic) int state;
@property (nonatomic) BOOL transferring;
@property (nonatomic) NSTimeInterval deadline;   // monotonic seconds; the wait for the queue / the file connection
@end

@implementation SLPending
@end

static NSTimeInterval slNow(void) {
    return [NSProcessInfo processInfo].systemUptime;
}

#pragma mark - the session

@interface SLSession : NSObject
@property (nonatomic, copy) BOOL (^cancelled)(void);
@property (nonatomic, copy) NSString *me;
@property (atomic) BOOL closed;
@property (atomic) BOOL lost;   // the server dropped us (account signed in somewhere else, or the link died)
- (NSString *)loginAs:(NSString *)username password:(NSString *)password;
- (NSArray<SLResult *> *)searchFor:(NSString *)query waiting:(NSTimeInterval)seconds enough:(NSUInteger)enough;
- (NSString *)download:(SLResult *)result to:(NSString *)destination source:(NSString *)source;
- (void)close;
@end

@implementation SLSession {
    int _server;
    NSObject *_sendLock;
    NSLock *_lock;
    NSMutableArray<SLResult *> *_results;
    uint32_t _searchToken;
    BOOL _searching;
    NSMutableDictionary<NSString *, NSDictionary *> *_addresses;
    NSMutableDictionary<NSString *, dispatch_semaphore_t> *_waiters;
    NSMutableDictionary<NSString *, SLPending *> *_pending;
    dispatch_queue_t _peers;
    dispatch_semaphore_t _slots;
    SLDownloadProgress _progress;
    NSString *_source;
    NSTimeInterval _lastReport;
}

- (instancetype)init {
    if (!(self = [super init])) return nil;
    _server = -1;
    _sendLock = [NSObject new];
    _lock = [NSLock new];
    _results = [NSMutableArray array];
    _addresses = [NSMutableDictionary dictionary];
    _waiters = [NSMutableDictionary dictionary];
    _pending = [NSMutableDictionary dictionary];
    _peers = dispatch_queue_create("com.spotifyglass.soulseek.peers", DISPATCH_QUEUE_CONCURRENT);
    _slots = dispatch_semaphore_create(32);
    return self;
}

- (BOOL)stopped {
    return self.closed || (self.cancelled && self.cancelled());
}

- (SLStop)stopBlock {
    __weak SLSession *weak = self;
    return ^BOOL{ SLSession *s = weak; return !s || [s stopped]; };
}

#pragma mark login and the server's own messages

- (NSString *)loginAs:(NSString *)username password:(NSString *)password {
    self.me = username;
    _server = slConnectHost(kServerHost, kServerPort, 12, [self stopBlock]);
    if (_server < 0) return @"Couldn't reach the Soulseek server. Check the network.";
    if (!slSendAll(_server, slLoginFrame(username, password))) return @"Couldn't send the Soulseek login.";
    NSTimeInterval limit = slNow() + 20;
    SLStop stop = ^BOOL{ return [self stopped] || slNow() > limit; };
    NSData *answer = slReadFrame(_server, stop);
    SLReader r = slReader(answer, 0);
    if (!answer || slGet32(&r) != 1) return @"Soulseek didn't answer the login.";
    if (!slGet8(&r)) {
        NSString *reason = slGetString(&r) ?: @"";
        if ([reason isEqualToString:@"INVALIDPASS"]) return @"Wrong Soulseek password. Fix it in Mod Settings > Soulseek account.";
        if ([reason isEqualToString:@"INVALIDUSERNAME"]) return @"That Soulseek username is invalid.";
        return [NSString stringWithFormat:@"Soulseek refused the login (%@).", reason];
    }
    NSMutableData *status = [NSMutableData data];
    slPut32(status, 2);   // online
    [self sendServer:slMessage(28, status)];
    NSMutableData *shared = [NSMutableData data];
    slPut32(shared, 0);
    slPut32(shared, 0);
    [self sendServer:slMessage(35, shared)];
    [NSThread detachNewThreadSelector:@selector(serverLoop) toTarget:self withObject:nil];
    return nil;
}

- (BOOL)sendServer:(NSData *)frame {
    @synchronized (_sendLock) {
        return _server >= 0 && slSendAll(_server, frame);
    }
}

- (void)serverLoop {
    @autoreleasepool {
        int fd = _server;
        while (!self.closed) {
            NSData *body = slReadFrame(fd, ^BOOL{ return self.closed; });
            if (!body) break;
            SLReader r = slReader(body, 0);
            uint32_t code = slGet32(&r);
            if (code == 3) {            // GetPeerAddress: user, ip, port
                NSString *user = slGetString(&r);
                uint32_t ip = slGet32(&r), port = slGet32(&r);
                if (r.bad || !user) continue;
                [_lock lock];
                _addresses[user] = @{@"ip": slAddress(ip), @"port": @(port)};
                dispatch_semaphore_t waiter = _waiters[user];
                [_lock unlock];
                if (waiter) dispatch_semaphore_signal(waiter);
            } else if (code == 18) {    // ConnectToPeer: a peer wants us to connect to it
                NSString *user = slGetString(&r), *type = slGetString(&r);
                uint32_t ip = slGet32(&r), port = slGet32(&r), token = slGet32(&r);
                if (r.bad || !user || !type) continue;
                [self peerAsksUsToConnect:user type:type ip:slAddress(ip) port:port token:token];
            } else if (code == 41) {    // Relogged: the account signed in somewhere else
                SGLog(@"lossless: soulseek account signed in elsewhere");
                self.lost = YES;
                break;
            }
        }
        if (!self.closed) { self.lost = YES; SGLog(@"lossless: soulseek server connection ended"); }
    }
}

#pragma mark peers that connect through the server

- (void)peerAsksUsToConnect:(NSString *)user type:(NSString *)type ip:(NSString *)ip port:(uint32_t)port token:(uint32_t)token {
    BOOL isFile = [type isEqualToString:@"F"];
    if (!isFile && ![type isEqualToString:@"P"]) return;
    if (!isFile && dispatch_semaphore_wait(_slots, DISPATCH_TIME_NOW) != 0) return;   // too many open: drop a search answer
    dispatch_async(_peers, ^{
        @autoreleasepool {
            int fd = slConnectIP(ip, port, 8, [self stopBlock]);
            if (fd >= 0) {
                NSMutableData *pierce = [NSMutableData data];
                slPut8(pierce, 0);                // PierceFirewall
                slPut32(pierce, token);
                if (slSendAll(fd, slFrame(pierce))) {
                    if (isFile) [self fileConnection:fd user:user];
                    else [self peerLoop:fd user:user searchOnly:YES];
                }
                close(fd);
            }
            if (!isFile) dispatch_semaphore_signal(_slots);
        }
    });
}

// Messages on a 'P' connection. A search connection ends with its answer; a connection of a peer we asked for a
// file stays until that file is done.
- (void)peerLoop:(int)fd user:(NSString *)user searchOnly:(BOOL)searchOnly {
    NSTimeInterval limit = slNow() + 12;
    SLStop stop = ^BOOL{
        if ([self stopped]) return YES;
        SLPending *p = [self pendingFor:user];
        if (p) {
            if (p.state >= 2) return YES;
            if (!p.transferring && slNow() > p.deadline) return YES;
            return NO;
        }
        return searchOnly && slNow() > limit;
    };
    while (!stop()) {
        NSData *body = slReadFrame(fd, stop);
        if (!body) return;
        SLReader r = slReader(body, 0);
        uint32_t code = slGet32(&r);
        if (code == 9) {                                   // FileSearchResponse
            [self searchAnswer:[body subdataWithRange:NSMakeRange(4, body.length - 4)] from:user];
            if (![self pendingFor:user]) return;
        } else if (code == 40) {                           // TransferRequest
            uint32_t direction = slGet32(&r), token = slGet32(&r);
            NSString *filename = slGetString(&r);
            uint64_t size = direction == 1 ? slGet64(&r) : 0;
            if (!r.bad) [self transferRequest:fd user:user direction:direction token:token filename:filename size:size];
        } else if (code == 44) {                           // PlaceInQueueResponse
            slGetString(&r);
            uint32_t place = slGet32(&r);
            if (!r.bad) [self queued:user place:place];
        } else if (code == 46) {                           // UploadFailed
            [self finish:user state:3 reason:@"The peer couldn't send the file."];
        } else if (code == 50) {                           // UploadDenied
            slGetString(&r);
            NSString *reason = slGetString(&r);
            [self finish:user state:3 reason:reason.length ? [NSString stringWithFormat:@"The peer refused: %@", reason] : @"The peer refused."];
        }
    }
}

- (SLPending *)pendingFor:(NSString *)user {
    [_lock lock];
    SLPending *p = _pending[user];
    [_lock unlock];
    return p;
}

- (void)finish:(NSString *)user state:(int)state reason:(NSString *)reason {
    [_lock lock];
    SLPending *p = _pending[user];
    if (p && p.state < 2) { p.state = state; p.reason = reason; }
    [_lock unlock];
}

- (void)queued:(NSString *)user place:(uint32_t)place {
    if (_progress) {
        NSString *where = [NSString stringWithFormat:@"%@  ·  queue %u", _source ?: @"Soulseek", place];
        SLDownloadProgress progress = _progress;
        dispatch_async(dispatch_get_main_queue(), ^{ progress(SLProgressQueued, 0, where); });
    }
}

- (void)transferRequest:(int)fd user:(NSString *)user direction:(uint32_t)direction token:(uint32_t)token
               filename:(NSString *)filename size:(uint64_t)size {
    [_lock lock];
    SLPending *p = _pending[user];
    BOOL match = p && direction == 1 && p.state == 0 && [p.filename isEqualToString:filename];
    if (match) {
        p.token = token;
        p.size = size;
        p.state = 1;
        p.deadline = slNow() + 60;   // the file connection should come within a minute
    }
    [_lock unlock];
    NSMutableData *answer = [NSMutableData data];
    slPut32(answer, token);
    slPut8(answer, match ? 1 : 0);
    if (!match) slPutString(answer, @"Cancelled");
    slSendAll(fd, slMessage(41, answer));
    SGLog(@"lossless: transfer request from %@ for %@ (%llu bytes) -> %@", user, filename, size, match ? @"accepted" : @"refused");
}

#pragma mark searching

- (void)searchAnswer:(NSData *)packed from:(NSString *)user {
    NSData *data = slInflate(packed);
    if (!data) return;
    SLReader r = slReader(data, 0);
    NSString *name = slGetString(&r);
    uint32_t token = slGet32(&r), count = slGet32(&r);
    if (r.bad || !name.length) return;
    [_lock lock];
    BOOL wanted = _searching && token == _searchToken;
    [_lock unlock];
    if (!wanted || count > 5000) return;
    NSMutableArray<SLResult *> *files = [NSMutableArray array];
    for (uint32_t i = 0; i < count; i++) {
        slGet8(&r);
        NSData *raw = slGetData(&r);
        uint64_t size = slGet64(&r);
        slGetString(&r);                         // extension, unreliable: read from the name instead
        uint32_t attributes = slGet32(&r);
        if (r.bad || attributes > 32) return;
        SLResult *file = [SLResult new];
        for (uint32_t a = 0; a < attributes; a++) {
            uint32_t type = slGet32(&r), value = slGet32(&r);
            if (type == 0) file.bitrate = value;
            else if (type == 1) file.duration = value;
            else if (type == 4) file.sampleRate = value;
            else if (type == 5) file.bitDepth = value;
        }
        if (r.bad) return;
        NSString *path = slText(raw);
        NSString *extension = path.pathExtension.lowercaseString;
        if (![extension isEqualToString:@"flac"] && ![extension isEqualToString:@"m4a"]) continue;
        if ([extension isEqualToString:@"m4a"] && file.bitDepth <= 0) continue;   // plain AAC: lossy
        NSString *slashed = [path stringByReplacingOccurrencesOfString:@"\\" withString:@"/"];
        file.username = name;
        file.path = path;
        file.rawPath = raw;
        file.format = extension;
        file.fileSize = (double)size;
        file.title = slashed.lastPathComponent.stringByDeletingPathExtension;
        [files addObject:file];
    }
    uint8_t slotFree = slGet8(&r);
    uint32_t speed = slGet32(&r), queue = slGet32(&r);
    BOOL tail = !r.bad;
    for (SLResult *file in files) {
        file.slotFree = tail && slotFree;
        file.speed = speed;
        file.queueLength = queue;
    }
    if (!files.count) return;
    [_lock lock];
    if (_searching) [_results addObjectsFromArray:files];
    [_lock unlock];
}

- (NSArray<SLResult *> *)searchFor:(NSString *)query waiting:(NSTimeInterval)seconds enough:(NSUInteger)enough {
    uint32_t token = arc4random();
    [_lock lock];
    [_results removeAllObjects];
    _searchToken = token;
    _searching = YES;
    [_lock unlock];
    NSMutableData *payload = [NSMutableData data];
    slPut32(payload, token);
    slPutString(payload, query);
    [self sendServer:slMessage(26, payload)];
    NSTimeInterval started = slNow();
    while (![self stopped]) {
        [NSThread sleepForTimeInterval:0.25];
        NSTimeInterval elapsed = slNow() - started;
        [_lock lock];
        NSUInteger have = _results.count;
        [_lock unlock];
        if (elapsed >= seconds) break;
        if (elapsed >= 6 && have >= enough) break;
    }
    [_lock lock];
    _searching = NO;
    NSArray<SLResult *> *found = [_results copy];
    [_lock unlock];
    SGLog(@"lossless: soulseek search \"%@\" -> %lu lossless files", query, (unsigned long)found.count);
    return found;
}

#pragma mark downloading

- (NSDictionary *)addressOf:(NSString *)user {
    dispatch_semaphore_t waiter = dispatch_semaphore_create(0);
    [_lock lock];
    [_addresses removeObjectForKey:user];
    _waiters[user] = waiter;
    [_lock unlock];
    NSMutableData *payload = [NSMutableData data];
    slPutString(payload, user);
    [self sendServer:slMessage(3, payload)];
    dispatch_semaphore_wait(waiter, dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC));
    [_lock lock];
    NSDictionary *address = _addresses[user];
    [_waiters removeObjectForKey:user];
    [_lock unlock];
    return address;
}

// The file connection the uploader asked the server to open to us (peerAsksUsToConnect type F).
- (void)fileConnection:(int)fd user:(NSString *)user {
    SLStop stop = ^BOOL{ SLPending *p = [self pendingFor:user]; return [self stopped] || !p || p.state >= 2; };
    uint8_t raw[4];
    if (!slReadExact(fd, raw, 4, stop)) return;
    uint32_t token = (uint32_t)raw[0] | ((uint32_t)raw[1] << 8) | ((uint32_t)raw[2] << 16) | ((uint32_t)raw[3] << 24);
    [_lock lock];
    SLPending *p = _pending[user];
    BOOL mine = p && p.state == 1 && p.token == token;
    if (mine) p.transferring = YES;
    [_lock unlock];
    if (!mine) return;

    NSMutableData *offset = [NSMutableData data];
    slPut64(offset, 0);
    if (!slSendAll(fd, offset)) { [self finish:user state:3 reason:@"The transfer connection dropped."]; return; }

    uint64_t expected = p.size;
    NSString *partPath = [p.destination stringByAppendingPathExtension:@"part"];
    [[NSFileManager defaultManager] removeItemAtPath:partPath error:nil];
    [[NSFileManager defaultManager] createFileAtPath:partPath contents:[NSData data] attributes:nil];
    NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:partPath];
    if (!handle || !expected || expected > kMaxFileBytes) {
        [handle closeFile];
        remove(partPath.UTF8String);
        [self finish:user state:3 reason:@"Can't write the file."];
        return;
    }
    uint64_t received = 0;
    NSTimeInterval lastByte = slNow();
    static const size_t kChunk = 64 * 1024;
    NSMutableData *buffer = [NSMutableData dataWithLength:kChunk];
    NSString *failure = nil;
    while (received < expected) {
        if ([self stopped]) { failure = @"Cancelled."; break; }
        size_t want = (size_t)MIN((uint64_t)kChunk, expected - received);
        ssize_t count = recv(fd, buffer.mutableBytes, want, 0);
        if (count > 0) {
            @try { [handle writeData:[NSData dataWithBytes:buffer.bytes length:(NSUInteger)count]]; }
            @catch (NSException *e) { failure = @"The disk refused the file."; break; }
            received += (uint64_t)count;
            lastByte = slNow();
            [self reportFraction:(double)received / (double)expected];
            continue;
        }
        if (count == 0) { failure = @"The peer closed the transfer early."; break; }
        if (errno == EINTR) continue;
        if (errno == EAGAIN || errno == EWOULDBLOCK) {
            if (slNow() - lastByte > kStallSeconds) { failure = @"The transfer stalled."; break; }
            continue;
        }
        failure = @"The transfer connection failed.";
        break;
    }
    [handle closeFile];
    if (!failure) {
        long long start = slFlacOffset(partPath);
        BOOL m4a = [p.destination.pathExtension.lowercaseString isEqualToString:@"m4a"];
        if (start < 0 && !m4a) failure = @"The peer sent something that isn't a FLAC file.";
        else if (start > 0 && !slCutHead(partPath, start)) failure = @"Can't write the file.";
    }
    if (!failure) {
        NSURL *final = [NSURL fileURLWithPath:p.destination];
        [[NSFileManager defaultManager] removeItemAtURL:final error:nil];
        if (![[NSFileManager defaultManager] moveItemAtURL:[NSURL fileURLWithPath:partPath] toURL:final error:nil]) failure = @"Can't write the file.";
    }
    if (failure) {
        remove(partPath.UTF8String);
        [self finish:user state:3 reason:failure];
    } else {
        [self reportFraction:1.0];
        [self finish:user state:2 reason:nil];
    }
}

- (void)reportFraction:(double)fraction {
    NSTimeInterval now = slNow();
    if (fraction < 1 && now - _lastReport < 0.25) return;
    _lastReport = now;
    SLDownloadProgress progress = _progress;
    NSString *source = _source;
    if (progress) dispatch_async(dispatch_get_main_queue(), ^{ progress(SLProgressTransferring, fraction, source); });
}

- (NSString *)download:(SLResult *)result to:(NSString *)destination source:(NSString *)source {
    if (self.lost) return @"Soulseek signed this account in somewhere else (another app or device). Close it there and try again.";
    SLPending *p = [SLPending new];
    p.user = result.username;
    p.filename = result.path;
    p.rawName = result.rawPath;
    p.destination = destination;
    p.size = (uint64_t)result.fileSize;
    p.deadline = slNow() + (result.slotFree ? kWaitSlotFree : kWaitQueued);
    _source = source;
    [_lock lock];
    _pending[result.username] = p;
    [_lock unlock];

    NSString *failure = nil;
    NSDictionary *address = [self addressOf:result.username];
    NSString *ip = address[@"ip"];
    uint32_t port = [address[@"port"] unsignedIntValue];
    if (!ip.length || [ip isEqualToString:@"0.0.0.0"] || !port) {
        failure = self.lost ? @"Soulseek signed this account in somewhere else (another app or device). Close it there and try again."
                            : [NSString stringWithFormat:@"%@ is offline.", result.username];
    } else {
        int fd = slConnectIP(ip, port, 10, [self stopBlock]);
        if (fd < 0) {
            failure = [NSString stringWithFormat:@"Couldn't reach %@ (probably behind a firewall).", result.username];
        } else {
            NSMutableData *init = [NSMutableData data];
            slPut8(init, 1);                      // PeerInit
            slPutString(init, self.me);
            slPutString(init, @"P");
            slPut32(init, 0);
            NSMutableData *queue = [NSMutableData data];
            slPutData(queue, result.rawPath);     // the name exactly as the peer sent it
            if (slSendAll(fd, slFrame(init)) && slSendAll(fd, slMessage(43, queue))) {
                SGLog(@"lossless: queued %@ at %@ (slot free: %d)", result.path, result.username, result.slotFree);
                [self peerLoop:fd user:result.username searchOnly:NO];
            } else {
                failure = @"Couldn't talk to the peer.";
            }
            close(fd);
        }
    }
    [_lock lock];
    int state = p.state;
    NSString *reason = p.reason;
    [_pending removeObjectForKey:result.username];
    [_lock unlock];
    if (state == 2) return nil;
    remove([destination stringByAppendingPathExtension:@"part"].UTF8String);
    if (failure) return failure;
    if (reason) return reason;
    if ([self stopped]) return @"Cancelled.";
    return state == 1 ? @"The peer never opened the transfer." : [NSString stringWithFormat:@"Still queued at %@ after a while.", result.username];
}

- (void)setProgress:(SLDownloadProgress)progress {
    _progress = progress;
}

- (void)close {
    self.closed = YES;
    int fd = _server;
    _server = -1;
    if (fd >= 0) { shutdown(fd, SHUT_RDWR); close(fd); }
}

@end

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
        NSString *username = SLSoulseekSavedUsername();
        NSString *password = SLSoulseekSavedPassword();
        if (!username.length || !password.length) {
            self.failure = @"Add your Soulseek account first: Mod Settings > Soulseek account.";
            return;
        }
        [self report:SLProgressSearching fraction:0 source:nil];

        SLSession *session = [SLSession new];
        __weak SLFetchOperation *weakSelf = self;
        session.cancelled = ^BOOL{ return weakSelf.isCancelled; };
        [session setProgress:self.progress];
        NSString *loginError = [session loginAs:username password:password];
        if (loginError) {
            self.failure = self.isCancelled ? nil : loginError;
            [session close];
            return;
        }

        NSSet *artists = self.artist.length ? slArtistKeys(self.artist) : [NSSet set];
        NSSet *variants = slVariantWords(self.title);
        NSArray<SLResult *> *candidates = nil;
        NSString *query = slSearchQuery(self.artist, self.title, YES);
        if (query.length) {
            NSArray *found = [session searchFor:query waiting:kSearchSeconds enough:30];
            candidates = slCandidates(found, self.title, artists, variants, self.duration);
            if (!candidates.count && !self.isCancelled) {   // slow answers: give the same search a little longer
                found = [session searchFor:query waiting:kSearchExtraSeconds + kSearchSeconds enough:30];
                candidates = slCandidates(found, self.title, artists, variants, self.duration);
            }
        }
        if (!candidates.count && self.artist.length && !self.isCancelled) {  // title alone, artist checked in the path
            NSString *titleOnly = slSearchQuery(nil, self.title, NO);
            if (titleOnly.length >= 4) {
                NSArray *found = [session searchFor:titleOnly waiting:kSearchSeconds enough:30];
                candidates = slCandidates(found, self.title, artists, variants, self.duration);
            }
        }
        if (self.isCancelled) { [session close]; return; }
        if (!candidates.count) {
            self.failure = session.lost ? @"Soulseek signed this account in somewhere else (another app or device). Close it there and try again."
                                        : @"No lossless copy of this song found on Soulseek.";
            [session close];
            return;
        }

        NSString *directory = SGLosslessStoreDirectory();
        NSString *lastReason = nil;
        for (SLResult *candidate in candidates) {
            if (self.isCancelled) break;
            NSString *extension = candidate.format.length ? candidate.format : @"flac";
            NSString *name = [NSString stringWithFormat:@"%@.%@", slSafeName(self.title), extension];
            NSString *destination = [directory stringByAppendingPathComponent:name];
            for (int n = 2; [[NSFileManager defaultManager] fileExistsAtPath:destination]; n++) {
                destination = [directory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@ %d.%@", slSafeName(self.title), n, extension]];
            }
            NSString *source = [NSString stringWithFormat:@"%@%@ · %@", [extension uppercaseString],
                                candidate.bitDepth > 0 ? [NSString stringWithFormat:@" %ld/%.1f",
                                    (long)candidate.bitDepth, candidate.sampleRate / 1000.0] : @"",
                                candidate.username];
            [self report:SLProgressQueued fraction:0 source:source];
            NSString *error = [session download:candidate to:destination source:source];
            if (!error) {
                self.result = [NSURL fileURLWithPath:destination];
                break;
            }
            SGLog(@"lossless: %@ at %@ failed (%@), trying the next peer", candidate.path, candidate.username, error);
            lastReason = error;
            if (session.lost) break;   // every other peer would fail the same way
        }
        [session close];
        if (!self.result && !self.isCancelled) self.failure = lastReason ?: @"The download failed.";
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
    __weak SLFetchOperation *weakOperation = operation;
    operation.completionBlock = ^{
        SLFetchOperation *finishedOperation = weakOperation;
        if (!finishedOperation) return;
        NSURL *result = finishedOperation.result;
        NSString *failure = finishedOperation.failure;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion(result, failure);
        });
    };
    [[NSOperationQueue new] addOperation:operation];  // a private queue: it blocks on network waits
    return operation;
}
