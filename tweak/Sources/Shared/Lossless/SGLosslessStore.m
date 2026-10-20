#import "SGLosslessStore.h"
#import <AudioToolbox/AudioToolbox.h>

static NSString *const kIndex = @".index.plist";   // track URI -> file name

NSString *SGLosslessStoreDirectory(void) {
    NSString *documents = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *directory = [documents stringByAppendingPathComponent:@"Lossless"];
    [NSFileManager.defaultManager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:NULL];
    return directory;
}

static NSString *indexPath(void) {
    return [SGLosslessStoreDirectory() stringByAppendingPathComponent:kIndex];
}

static NSString *folded(NSString *text) {
    return [[text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet]
        stringByFoldingWithOptions:NSCaseInsensitiveSearch | NSWidthInsensitiveSearch locale:nil];
}

// A file's title tag and length, read once per file and kept by name and modification date.
static NSDictionary *tags(NSString *path) {
    static NSMutableDictionary<NSString *, NSDictionary *> *cache;
    if (!cache) cache = [NSMutableDictionary dictionary];
    NSDate *modified = [NSFileManager.defaultManager attributesOfItemAtPath:path error:NULL].fileModificationDate;
    NSString *key = [NSString stringWithFormat:@"%@|%f", path, modified.timeIntervalSince1970];
    if (cache[key]) return cache[key];
    NSMutableDictionary *found = [NSMutableDictionary dictionary];
    AudioFileID file;
    if (AudioFileOpenURL((__bridge CFURLRef)[NSURL fileURLWithPath:path], kAudioFileReadPermission, 0, &file) == noErr) {
        CFDictionaryRef info = NULL;
        UInt32 size = sizeof info;
        if (AudioFileGetProperty(file, kAudioFilePropertyInfoDictionary, &size, &info) == noErr && info) {
            NSDictionary *read = CFBridgingRelease(info);
            if (read[@kAFInfoDictionary_Title]) found[@"title"] = read[@kAFInfoDictionary_Title];
            if (read[@kAFInfoDictionary_ApproximateDurationInSeconds]) found[@"duration"] = @([read[@kAFInfoDictionary_ApproximateDurationInSeconds] doubleValue]);
        }
        AudioFileClose(file);
    }
    cache[key] = found;
    return found;
}

static NSString *find(NSString *uri, NSString *title, double duration) {
    NSString *directory = SGLosslessStoreDirectory();
    NSDictionary *index = [NSDictionary dictionaryWithContentsOfFile:indexPath()];
    NSString *known = index[uri];
    if (known) {
        NSString *path = [directory stringByAppendingPathComponent:known];
        if ([NSFileManager.defaultManager fileExistsAtPath:path]) return path;
    }
    if (!title.length) return nil;
    NSString *wanted = folded(title);
    for (NSString *name in [NSFileManager.defaultManager contentsOfDirectoryAtPath:directory error:NULL]) {
        NSString *extension = name.pathExtension.lowercaseString;
        if (![@[@"flac", @"m4a", @"caf"] containsObject:extension]) continue;
        NSString *path = [directory stringByAppendingPathComponent:name];
        NSDictionary *tag = tags(path);
        NSString *fileTitle = tag[@"title"];
        BOOL titled = fileTitle ? [folded(fileTitle) isEqualToString:wanted]
                                : [folded(name.stringByDeletingPathExtension) containsString:wanted];
        if (titled && (duration < 0 || fabs([tag[@"duration"] doubleValue] - duration) <= 2)) return path;
    }
    return nil;
}

NSString *SGLosslessStoreFile(NSString *uri, NSString *title, double duration) {
    return duration > 0 ? find(uri, title, duration) : find(uri, @"", 0);
}

BOOL SGLosslessStoreHas(NSString *uri, NSString *title) {
    return find(uri, title, -1) != nil;
}

void SGLosslessStoreRemember(NSString *uri, NSString *path) {
    NSMutableDictionary *index = [NSMutableDictionary dictionaryWithContentsOfFile:indexPath()] ?: [NSMutableDictionary dictionary];
    if ([index[uri] isEqualToString:path.lastPathComponent]) return;
    index[uri] = path.lastPathComponent;
    [index writeToFile:indexPath() atomically:YES];
}

#pragma mark - what the Downloads page shows

static NSString *const kInfo = @".info.plist";   // file name -> {uri, title, artist, album, duration, cover}

static NSString *infoPath(void) {
    return [SGLosslessStoreDirectory() stringByAppendingPathComponent:kInfo];
}

NSString *SGLosslessCoversDirectory(void) {
    NSString *directory = [SGLosslessStoreDirectory() stringByAppendingPathComponent:@".covers"];
    [NSFileManager.defaultManager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:NULL];
    return directory;
}

NSDictionary *SGLosslessStoreInfo(NSString *fileName) {
    @synchronized (NSFileManager.defaultManager) {
        NSDictionary *all = [NSDictionary dictionaryWithContentsOfFile:infoPath()];
        NSDictionary *info = all[fileName];
        return [info isKindOfClass:NSDictionary.class] ? info : nil;
    }
}

void SGLosslessStoreSetInfo(NSString *fileName, NSDictionary *info) {
    if (!fileName.length || !info.count) return;
    @synchronized (NSFileManager.defaultManager) {
        NSMutableDictionary *all = [NSMutableDictionary dictionaryWithContentsOfFile:infoPath()] ?: [NSMutableDictionary dictionary];
        all[fileName] = info;
        [all writeToFile:infoPath() atomically:YES];
    }
}

void SGLosslessStoreForget(NSString *fileName) {
    if (!fileName.length) return;
    @synchronized (NSFileManager.defaultManager) {
        NSMutableDictionary *all = [NSMutableDictionary dictionaryWithContentsOfFile:infoPath()];
        NSString *cover = all[fileName][@"cover"];
        if (cover.length) [NSFileManager.defaultManager removeItemAtPath:[SGLosslessCoversDirectory() stringByAppendingPathComponent:cover.lastPathComponent] error:NULL];
        if (all[fileName]) {
            [all removeObjectForKey:fileName];
            [all writeToFile:infoPath() atomically:YES];
        }
        NSMutableDictionary *index = [NSMutableDictionary dictionaryWithContentsOfFile:indexPath()];
        BOOL changed = NO;
        for (NSString *uri in index.allKeys) {
            if ([index[uri] isEqualToString:fileName]) { [index removeObjectForKey:uri]; changed = YES; }
        }
        if (changed) [index writeToFile:indexPath() atomically:YES];
    }
}

#pragma mark - a FLAC's own tags and cover

static uint32_t be32(const uint8_t *b) { return ((uint32_t)b[0] << 24) | ((uint32_t)b[1] << 16) | ((uint32_t)b[2] << 8) | b[3]; }
static uint32_t le32(const uint8_t *b) { return ((uint32_t)b[3] << 24) | ((uint32_t)b[2] << 16) | ((uint32_t)b[1] << 8) | b[0]; }

NSDictionary<NSString *, NSString *> *SGLosslessReadTags(NSString *path, NSData **cover) {
    if (cover) *cover = nil;
    NSFileHandle *file = [NSFileHandle fileHandleForReadingAtPath:path];
    if (!file) return nil;
    NSMutableDictionary<NSString *, NSString *> *tags = [NSMutableDictionary dictionary];
    NSData *bestPicture = nil;
    uint32_t bestType = 99;
    BOOL isFlac = NO;
    @try {
        NSData *head = [file readDataOfLength:10];
        unsigned long long position = 0;
        if (head.length == 10 && memcmp(head.bytes, "ID3", 3) == 0) {
            const uint8_t *b = head.bytes;
            position = (((unsigned long long)(b[6] & 0x7F)) << 21 | ((b[7] & 0x7F) << 14) | ((b[8] & 0x7F) << 7) | (b[9] & 0x7F)) + 10;
        }
        [file seekToFileOffset:position];
        NSData *magic = [file readDataOfLength:4];
        if (magic.length == 4 && memcmp(magic.bytes, "fLaC", 4) == 0) {
            isFlac = YES;
            position += 4;
            for (int blocks = 0; blocks < 64; blocks++) {
                [file seekToFileOffset:position];
                NSData *header = [file readDataOfLength:4];
                if (header.length < 4) break;
                const uint8_t *b = header.bytes;
                BOOL last = (b[0] & 0x80) != 0;
                int type = b[0] & 0x7F;
                uint32_t length = ((uint32_t)b[1] << 16) | ((uint32_t)b[2] << 8) | b[3];
                position += 4;
                if ((type == 4 && length < (1u << 20)) || (type == 6 && length < (24u << 20))) {
                    NSData *body = [file readDataOfLength:length];
                    if (body.length < length) break;
                    const uint8_t *p = body.bytes;
                    NSUInteger n = body.length, o = 0;
                    if (type == 4 && n >= 8) {                       // Vorbis comment: "KEY=value" lines
                        o = 4 + le32(p);
                        if (o + 4 <= n) {
                            uint32_t count = le32(p + o);
                            o += 4;
                            for (uint32_t i = 0; i < count && o + 4 <= n; i++) {
                                uint32_t l = le32(p + o);
                                o += 4;
                                if (l > n - o) break;
                                NSString *line = [[NSString alloc] initWithBytes:p + o length:l encoding:NSUTF8StringEncoding];
                                o += l;
                                NSRange equals = [line rangeOfString:@"="];
                                if (equals.location == NSNotFound) continue;
                                NSString *key = [line substringToIndex:equals.location].uppercaseString;
                                NSString *value = [line substringFromIndex:NSMaxRange(equals)];
                                NSString *name = [key isEqualToString:@"TITLE"] ? @"title" : [key isEqualToString:@"ARTIST"] ? @"artist"
                                               : [key isEqualToString:@"ALBUM"] ? @"album" : nil;
                                if (name && value.length && !tags[name]) tags[name] = value;
                            }
                        }
                    } else if (type == 6 && n >= 32) {               // picture: type, mime, description, size, data
                        uint32_t pictureType = be32(p);
                        o = 4;
                        uint32_t mime = be32(p + o); o += 4 + mime;
                        if (o + 4 <= n) { uint32_t description = be32(p + o); o += 4 + description; }
                        o += 16;                                    // width, height, depth, colours
                        if (o + 4 <= n) {
                            uint32_t size = be32(p + o);
                            o += 4;
                            if (size && size <= n - o && pictureType < bestType) {
                                bestType = pictureType;
                                bestPicture = [body subdataWithRange:NSMakeRange(o, size)];
                                if (pictureType == 3) bestType = 3;   // the front cover: best there is
                            }
                        }
                    }
                }
                position += length;
                if (last) break;
            }
        }
    } @catch (NSException *exception) {
    } @finally {
        [file closeFile];
    }
    if (!isFlac) return nil;
    if (cover) *cover = bestPicture;
    return tags;
}
