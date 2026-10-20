#import "SLNativeLocal.h"
#import <AudioToolbox/AudioToolbox.h>
#import "Core/SGCore.h"


#pragma mark - the address

// Form encoded, as Spotify's local URIs are: "+" for a space, percent escapes for the rest (so no raw ":").
static NSString *formEncode(NSString *text) {
    static NSCharacterSet *allowed;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        allowed = [NSCharacterSet characterSetWithCharactersInString:
            @"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~ "];
    });
    NSString *escaped = [(text ?: @"") stringByAddingPercentEncodingWithAllowedCharacters:allowed] ?: @"";
    return [escaped stringByReplacingOccurrencesOfString:@" " withString:@"+"];
}

static double fileSeconds(NSString *path) {
    AudioFileID file;
    double seconds = 0;
    if (AudioFileOpenURL((__bridge CFURLRef)[NSURL fileURLWithPath:path], kAudioFileReadPermission, 0, &file) == noErr) {
        Float64 duration = 0;
        UInt32 size = sizeof duration;
        if (AudioFileGetProperty(file, kAudioFilePropertyEstimatedDuration, &size, &duration) == noErr) seconds = duration;
        AudioFileClose(file);
    }
    return seconds;
}

NSString *SLNativeLocalURI(NSDictionary *entry) {
    NSString *title = entry[@"title"];
    if (![title length]) return nil;
    double seconds = [entry[@"seconds"] doubleValue] ?: fileSeconds(entry[@"path"]);
    return [NSString stringWithFormat:@"spotify:local:%@:%@:%@:%ld", formEncode(entry[@"artist"]), formEncode(entry[@"album"]),
            formEncode(title), lround(seconds)];
}


