#import "Core/SGCore.h"
#import "Settings/SGModPage.h"
#import "NowPlayingBar.h"
#import "Redesigned/Player/Player.h"

UIViewController *SGRNowPlayingBarSettingsPage(void) {
    return [[SGModPage alloc] initWithTitle:@"Now playing" intro:SGRestartNote sections:@[
        SGSection(nil, @[
            SGHideRow(@"Hide the device button", nil, SGRHideBarConnect),
        ]),
        SGSection(nil, @[
            SGSwitchRow(@"Moving background", nil, SGRKeyPlayerMotion),
        ]),
    ] footer:nil];
}

// The Mini player section on the redesign's Player page: Spotify's own flag for the bar moving in between
// the tabs as the page scrolls (the Apple Music style transition the section's footer describes).
NSArray<SGModRow *> *SGRNowPlayingBarRows(void) {
    SGModRow *roundedArtwork = SGOptionRow(@"Rounded-square album art", @"Use rounded corners instead of a circle",
                                            SGRKeyNowPlayingRoundedArtwork);
    roundedArtwork.changed = ^(BOOL on) { SGRNowPlayingBarRefresh(); };
    return @[
        roundedArtwork,
        SGFlagRow(@"Mini player transition animations", @"ios-feature-nowplaying.miniplayer_transition_animations"),
    ];
}
