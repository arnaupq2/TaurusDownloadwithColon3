# App (Mod Settings root, Mod page, tour)

13 files, 36 notes, moved out of the code (tweak/Sources/App/).

## `App/About/About.h`

**`extern NSString *const SGSigningHelpURL;`** (was L18)
> Whether the now playing card on the lock screen can open this build. It depends on the signature,
> not on the mod: iOS launches by the App ID of the application-identifier entitlement, so a build
> whose bundle id is not that App ID cannot be opened from the card. Signing.m says so once.

**`void SGExportSettings(void);`** (was L30)
> Backup.m: the settings out to a JSON file through the share sheet, and back in from one, replacing
> what is set and restarting.

## `App/About/AboutSettings.m`

**`static void resetAll(void) {`** (was L6)
> Every key of the mod's is under one prefix, so a reset is a sweep of the defaults with the stock
> marker of SGPrefs.h left behind; the hooks read them at launch, so it ends in a restart.

## `App/About/AppIcon.m`

**file overview** (was L1)
> Mod > App icon: the icon on the home screen, picked from the ones scripts/app-icons.sh put into the IPA
> (icons/*.icon, listed under CFBundleAlternateIcons as SGAppIcon<Name>). iOS keeps the choice itself, so
> nothing is stored here and Reset all settings leaves it, and iOS says that it changed in an alert of its
> own. The icons are Liquid Glass stacks only, which nothing before iOS 26 draws, so below 26 the row says
> so. The name under the icon is the signature's to set, not the app's.

**`static NSArray<NSString *> *iconFiles(void) {`** (was L10)
> In the order the list shows them: the file in icons/, and the name the list gives it. Spotify is the
> IPA's own icon, iOS's primary one.

**`@interface SGAppIconPage : SGPage`** (was L52)
> The list stays up after a pick, so one icon after another can be tried; the tick follows what iOS
> reports once it has switched.

## `App/About/Backup.m`

**`static BOOL isSetting(NSString *key) {`** (was L6)
> Every key under the prefix travels, the way the reset sweeps them, so a new switch needs nothing
> here. What is left out belongs to this install rather than to its user's choices.

**`static void importSettings(NSDictionary *settings) {`** (was L56)
> A key already stored keeps its type: the hooks send boolValue to whatever they find at launch, and
> an array there would crash Spotify before the reset row could be reached.

## `App/About/Licenses.m`

**file overview** (was L1)
> Mod > Licenses: the mod's own license, then each third-party one the build ships code under, in full,
> since the MIT license asks for its text to travel with every copy.

## `App/About/Signing.m`

**file overview** (was L1)
> Whether the lock screen can open this build at all. MediaRemote launches the now playing app by
> the App ID in its application-identifier entitlement, not by CFBundleIdentifier, so a build signed
> under a profile whose App ID is not the bundle id installs and plays but cannot be opened from the
> now playing card: iOS asks for a bundle that is not installed and offers the App Store instead.
> The signature decides this and nothing in the app can change it, so all the mod does is say so --
> once on the first launch under a signature, and from a red row at the top of Mod Settings for as
> long as it lasts. Both land on the same sheet, which names the bundle id to sign under and copies
> it, because that one string is the whole fix.

**`NSString *SGSigningAppIdentifier(void) {`** (was L20)
> SecTaskCopyValueForEntitlement is not in the iOS SDK, so it is resolved at runtime like the rest
> of the private API the mod uses. A build that cannot read its own entitlement stays quiet.

**`static void showFix(void) {`** (was L53)
> The fix is one string, so the sheet leads with it and Copy is the first action: whoever reads this
> is on their way back to Feather to paste it into the identifier field.

**`void SGCheckSigningOnce(void) {`** (was L88)
> Said once per signature: re-signing under a different App ID is a new mistake and says so again,
> but a build that is simply left broken does not nag on every launch. The row stays either way.

## `App/About/Update.m`

**`SGLog(@"update check failed: HTTP %ld, %@", (long)status,`** (was L94)
> Unauthenticated GitHub allows sixty requests an hour per address; a phone behind a
> carrier NAT can be told to wait, and that is worth reading apart from a dead network.

## `App/ModSettings.x`

**file overview** (was L1)
> Settings: a Taurus Settings row at the end of Spotify's settings list opens the mod's own page: the
> Appearance card with Redesigned UI, Karaoke in the redesign (Sing, Redesigned/Lyrics/SingSettings.m), then a
> page per part of Spotify, each holding what that part offers in the stored look (App/Pages.m: Navbar,
> Player, Lyrics, Home & Library for the native look, Albums for the redesign), Audio effects
> (Shared/AudioEffects, in either look and applying straight away), Misc (this page's own banners),
> Premium, ads & privacy, Labs, All flags, a searchable list of every flag with an override per flag, and Mod, the
> build, its updates and links. The same row leads the side drawer's list (trees/test6.txt), above
> Your plan, so the page is a tap from Home, and holding Home on the tab bar opens it too. The tweaks read the switches when they run, so a change
> shows after Spotify restarts; the tab editor on the Navbar page applies as soon as the bar lays
> out again.
>
> Tree (trees/settings.txt): SettingsListViewController.view > SettingsListCollectionView of
> Element_List cells 402x56: 24pt icon at x 12, 13pt white title and 11pt grey subtitle at
> x 48, 12pt chevron on the right. A pushed page (trees/settings notifications opened.txt) is a
> UITableView bg #121212: header with an 11pt grey description at (16, 24), 53pt cells with the

**`static UIColor *SGRainbowTextColor(CGFloat width, CGFloat height, double phase) {`** (was L45)
> The wordmark, drawn as a horizontal rainbow wearing the same colours as the SGGlowSwitch rim: a pattern
> image the full spectrum wide, cut to the text itself so the label keeps the font and metrics Spotify
> gives it. The ramp starts and ends on the same pink, so two cycles butted together have no seam, and the
> second cycle is drawn on so `phase` can slide the ramp off one edge and back in the other.

**`- (void)startRainbow {`** (was L131)
> The wordmark cycles while the page is on screen, one tick of the display link carrying the hue a little
> further round, and rests when it is not: the pattern image is cut to the label, so it is remade each frame.

**`- (void)applyRainbow {`** (was L154)
> Only the label on screen is redrawn: the compact title once the masthead has scrolled away, the masthead
> while it has not.

**`static UIViewController *miscSettingsPage(void) {`** (was L204)
> Misc: the two banners the mod puts on its own page, each with a switch here to put it away. Its own
> page so the Settings list stays a list of parts, the way every other part's options sit one tap in.

**`SGModRow *signing = SGSigningWarningRow();`** (was L220)
> A build the lock screen cannot open leads the page, above the tweaks: it is the one thing here
> that no switch can put right, and it is worth reading before anything else.

**`SGModRow *discord = SGLinkRow(@"Join the Discord", @"Release pings, help and previews", SGDiscordURL);`** (was L234)
> Above the signing banner, in its shape: the server is the one place to ask about a build, so it
> reads before the warning about one.

**`NSMutableArray<SGModRow *> *parts = [NSMutableArray arrayWithArray:@[`** (was L248)
> Home & Library holds only the native look's switches, and Albums only the redesign's; the Live
> Activity works under both, and only where ActivityKit's card does.

**`@interface SGModSettingsRow : UIControl`** (was L288)
> The last row of Spotify's settings list, chevron and all, or the first of the side drawer's,
> drawn like the drawer's own rows: no chevron, icon and title 4pt further in.

**`- (void)open {`** (was L336)
> The drawer is presented over the app, so its row closes it first and pushes onto the stack it
> was covering, the way the drawer's own rows open their pages.

**`static void placeRow(UICollectionView *list, SGModSettingsRow *row) {`** (was L366)
> At the end of the settings list, or above the first row of the drawer's, with the inset for it
> added again whenever Spotify resets the inset.

**`static UIViewController *settingsListIn(UIViewController *page, Class kind) {`** (was L383)
> Media quality, Playback, Account and most of the rest of settings are the same controller class
> as the list they were opened from, which is why the row turned up at the end of all of them.
> What is on the navigation stack is not that controller though: every page in the app is wrapped
> in a MusicAppPageHostingViewController (trees/settings notifications opened.txt), and Spotify
> pushes a settings sub page as a page of its own, leaving the list it came from on the stack
> underneath. So the settings list inside the lowest wrapper that holds one is the list the row
> belongs at the end of, and a controller with no stack to be found on keeps the row rather than
> losing it.

**`if (!root) {`** (was L415)
> A page that laid itself out before it was on the stack looked like the list for as long
> as that took; the row goes again as soon as it can be seen for what it is.

**`static SGModSettingsRow *ensureDrawerRow(UICollectionView *list) {`** (was L430)
> The drawer's list (trees/test6.txt: SideDrawerListCollectionView under the profile header, Your
> plan its first cell) is one of several collection views on the page, so it is found by name.

## `App/Onboarding/Onboarding.h`

**file overview** (was L1)
> Onboarding: a welcome page over Home the first time this build runs, in glass: a pick between
> the redesign (offered first) and Spotify's own look, and a line on holding Home for Mod Settings.
> The look is picked at launch, so a changed pick ends the welcome in a restart. The Mod page
> offers it again.

## `App/Onboarding/Onboarding.x`

**file overview** (was L1)
> The tour goes up the first time Home appears, not at launch: a fresh sideload lands on the login
> screen first, and a tour over that is wrong. A moment after, so Home has drawn under the glass.

## `App/Onboarding/Tour.m`

**`@interface SGLookCard : UIControl`** (was L44)
> One of the two looks, as a glass card: symbol, name, a line on what it brings, and a check
> when it is the one picked.

**`@interface SGOnboardingController : UIViewController`** (was L142)
> One page, the one choice worth making now: the redesign or Spotify's own look. Everything else
> waits in Mod Settings.

**`if (!glass) {`** (was L208)
> Liquid Glass is drawn by iOS 26 and by nothing before it, so on an older phone the card stays
> on the page to say so and the legacy look is the only one left.

## `App/Pages.h`

**file overview** (was L1)
> The pages of Mod Settings that bring the layers together: what each look offers is its own
> (Shared/, Native/, Redesigned/), and which of it a page shows is decided here, from the stored
> Redesigned UI switch, so a page opened after flipping it shows what the restart will bring.

## `App/Pages.m`

**`static void offerRestart(BOOL on) {`** (was L29)
> The whole look changes hands at launch, so the switch asks for the restart straight away rather than
> leaving Spotify half in the old look.

**`static SGModRow *unavailableRow(void) {`** (was L40)
> Below iOS 26 the row is not a switch: Liquid Glass is the redesign, and the system draws it from
> that version on, so the row reads out what is missing and the card carries the native look's rows alone.
