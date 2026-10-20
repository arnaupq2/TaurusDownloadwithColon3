# Native (Spotify's screens tweaked)

28 files, 89 notes, moved out of the code (tweak/Sources/Native/).

## `Native/Album/Album.h`

**file overview** (was L1)
> Album: parts of the album page hidden one switch each, and the cover behind its header (Album.x).
> An unset switch is off.

## `Native/Album/Album.x`

**file overview** (was L1)
> Album: hides parts of the album page, one switch each in Mod Settings > Home & Library > Album,
> and puts the blurred cover behind its header.
>
> Trees (trees/continuous/*.txt): the page is a CreativeWorkTemplateView with that identifier (the
> artist page is TemplateKit's TemplateView instead). Its first child is the header's background,
> a HeaderView holding Spotify's GradientView; the header itself scrolls with the list, its buttons
> one UIStackView of element views, each holding a button with an accessibility identifier.
>
> Below the tracks every row is an Element_List cell, sectioned the way Artist/Artist.x describes: a
> heading cell (SectionHeadingHome), the carousel or card, a 16pt spacer. The copyright closes the
> page right after the last section, so it counts as a heading of its own and stays.

**`%hook UIImageView`** (was L98)
> The cover loads after the page is laid out, and a new image lays nothing out. Only the 248pt
> cover is wide enough to be worth walking up from.

## `Native/Appearance/Accent.x`

**file overview** (was L1)
> Accent colour: Spotify's green, #1ED760, is one token. Its three components occur once in the
> whole binary, and every green the app draws, from the play button to the "Zobrazit vše" links
> and the progress bar, is that token or a state blended from it. So it is swapped where it is
> born, in the UIColor initialiser, and the blends follow. Lottie animations carry their own green
> and are caught at the layer, below. Image assets with green baked in, the logo above all, are
> out of reach.

**`static const uint32_t kGreens[] = {0x1ED760, 0x1DB954};`** (was L11)
> The greens the app is known to build from literals: the token, and the older brand green the
> upsell backend still names.

**`static BOOL swap(CGFloat *r, CGFloat *g, CGFloat *b) {`** (was L69)
> A darker green than the token comes out as the accent darkened by the same amount, so the two
> keep their relation.

**`static CGColorRef swappedCopy(CGColorRef color) {`** (was L98)
> Lottie draws its animations, the play indicator and the checkmarks among them, from colours
> in the animation file straight onto shape layers, or into colour keyframes, never through
> UIColor. The same swap goes on the CGColor. Layers get set off the main thread too, so the
> copy is made with CoreGraphics alone; NULL when the colour is not one of the greens.

## `Native/Appearance/Amoled.x`

**file overview** (was L1)
> AMOLED background: Spotify paints its base surface #121212; with the switch on, that grey and
> the gradients fading into it go pure black. Lighter greys stay (#1F1F1F placeholders, #292929
> cards), so elevated surfaces still read against the black.
>
> Trees: #121212 sits on the Home, Search, Library and settings scroll views, on list rows, the
> message bar and the player's bottom gradient view.

**`%hook _TtC21Settings_PlatformImpl26SettingsListViewController`** (was L54)
> Spotify's settings list paints nothing of its own and shows whatever sits under it, which is not
> the base grey the hooks above turn black. The list is the top surface, so it takes the black.

## `Native/Appearance/Appearance.h`

**file overview** (was L1)
> The native look's appearance: the AMOLED background (Amoled.x), the accent colour in place of
> Spotify's green (Accent.x), the soft top edge (EdgeEffect.x) and Repaint.x, which keeps what the
> native tweaks stripped transparent when Spotify repaints it. The switches are off until asked for.

## `Native/Appearance/AppearanceSettings.m`

**`static void chooseAccent(void) {`** (was L6)
> Going back to Spotify's green is offered only once a colour of the mod's is set, so a stray tap
> cannot wipe it.

## `Native/Appearance/EdgeEffect.x`

**file overview** (was L1)
> Soft top edge: iOS 27 resolves a scroll view's automatic top edge effect to the hard style, the
> flat dark band under the navigation bar (UIKit.ScrollEdgeEffectView in trees/continuous/1.txt).
> Setting the soft style brings back iOS 26's thin fading blur. Set on every layout pass as well as
> on arrival, in case UIKit resolves the style again after the page appears.

## `Native/Appearance/Repaint.h`

**file overview** (was L1)
> The areas the native look's tweaks stripped and Repaint.x keeps transparent when Spotify repaints
> them, each set by the tweak that owns it.

## `Native/Appearance/Repaint.x`

**`color = NULL;`** (was L21)
> Home keeps its cards and its placeholders; only the base surface the gradient
> of Native/Home/HomeGradient.x sits behind goes.

## `Native/Artist/Artist.x`

**file overview** (was L1)
> Artist: hides parts of the artist page, one switch each in Mod Settings > Home & Library > Artist.
>
> Trees (trees/continuous/*.txt): the page is a CreativeWorkPlatform TemplateView with the
> identifier creator-page. Its header is an ImageHeaderView whose badge, listeners and buttons carry
> accessibility identifiers. Below the Music/Video tabs every row is an Element_List cell: a titled
> section is one cell for its heading (SectionHeadingHome), then its tracks, carousel or card, then
> a 16pt spacer, each a cell of its own.
>
> Only the heading names the section, so the list remembers the heading above every cell it sizes
> and a hidden section's cells all answer height 0, down to the next heading. The headings are
> told apart by their English titles.

**`if ([NSStringFromClass(action.superview.class) containsString:@"OverflowStackView"]) {`** (was L62)
> OverflowStackView traps in updateConstraints once its views go hidden (crash 2026-09-15),
> so those only turn invisible and keep their place.

**`static void closeUpTitle(UIView *header) {`** (was L84)
> The header keeps Spotify's height, so the room the hidden badge and listeners leave is given to
> the photo: the title block slides down to sit where the lowest of them sat. Transforms, because
> the header's stack views crash on anything that changes their layout.

**`CGFloat edge = listeners.alpha > 0 ? bottomOf(badge) : bottomOf(metadata);`** (was L94)
> Walks up from the listeners' line: each shown line lands on the bottom edge the line under it
> left free, keeping its own gap to the line above.

**`static UIImage *blurred(UIImage *image) {`** (was L108)
> The photo sits in a clipping view shorter than the header, and Spotify's gradient over it is cut by
> the same clip, so the picture ends in a straight line well above the buttons. With the switch on,
> the photo's lower part dissolves into a blurred copy of itself that reaches the header's bottom
> and fades out there.

**`%hook UIStackView`** (was L189)
> The buttons arrive after the header has laid out, and a row that keeps its size never lays the
> header out again.

**`static void hideTabBar(UIView *strip) {`** (was L203)
> Trees (trees/continuous/1.txt): the strip (Components.UI.TabsSectionHeading) sits above a paging
> scroll view holding one list per tab. The strip lives in a LegacyUI AutoLayoutStackView, so it
> goes invisible rather than hidden; the pages move up into its place and stop swiping, which
> leaves the Music list.

**`static NSString *sectionOf(NSIndexPath *path, NSDictionary<NSIndexPath *, NSString *> *headings) {`** (was L285)
> The title of the section the cell falls under; nil above the first heading, or where a cell
> between it and its heading has not been sized yet.

## `Native/Home/Home.h`

**file overview** (was L1)
> Home: the gradient behind the top of the page (HomeGradient.x), off until it is asked for, and
> the settings that shape it (HomeGradientChoices.m, the Gradient page in HomeSettings.m).

**`typedef NS_ENUM(NSInteger, SGHomeChoice) {`** (was L14)
> Every setting the gradient is shaped by. One entry per setting in HomeGradientChoices.m holds the
> names the Gradient page offers, the key it is stored under and the one it falls back to, so a
> name and what it does cannot drift apart.

**`NSInteger SGHomeChoiceValue(SGHomeChoice choice);`** (was L27)
> The index set for `choice`: its own default while nothing is set, or while what is set is a name
> this build no longer offers.

## `Native/Home/HomeDeclutter.x`

**file overview** (was L1)
> Home declutter: sections of Home collapsed and the filter pills hidden, one switch each on the Home &
> Library page. A section is an Element_List cell; a hidden one reports zero height when the list sizes
> it, so the list closes up around it.
>
> Trees (trees/home*.txt): every section is a CollectionViewCell whose content view names the page
> (Home_EvoPageImpl) and whose subtree names the section.

**`static NSString *classNamesIn(UIView *cell) {`** (was L17)
> Class names of everything in the cell. Lists nested in the cell are laid out first so the
> cells that name the section (shortcut tiles) exist.

## `Native/Home/HomeGradient.x`

**file overview** (was L1)
> Home gradient: a wash behind the top of the Home tab, strongest under the avatar and the pills
> and out by the second shelf, like the gradient Spotify's own Home used to have. The wash is a
> layer inside the page's scroll view, under its content, so it scrolls away with the shelves; the
> base grey the page and the shelves paint over it goes clear in Native/Appearance/Repaint.x, and
> Spotify's own scrim behind the header goes with it, since it would only mute the colour.
>
> Which colour it fades, how strong it is and how far down it reaches come from the choice tables
> in HomeGradientChoices.m, read on every layout pass, so all three apply without restarting
> Spotify. The switch itself is read once, in the %ctor, and still needs a restart.
>
> Tree (trees/home.txt): FunkisViewController.view holds the page, a 402x112 wrapper around
> LiquidGlass.GradientView (the scrim under the avatar and the pills) and HomeHeaderView. Four
> views down, EvoLoadableResourceViewController.view holds the one
> Home_CarouselKit.TouchCancellingCollectionView of the page, full screen and inset 112pt at the
> top for the header, painted #121212; the shelves inside it are collection views of their own,
> painted #121212 as well.

**`static const CGFloat kLevelHeight = 52;`** (was L21)
> Colour level behind the header before it starts to go, and colour above the content as well, for
> the rubber band of an overscroll to pull down into.

**`static const uint32_t kTints[] = {0x0B4110, 0x0B4138, 0x0B2B41, 0x160B41, 0x330B41, 0x410B2E, 0x410B10, 0x412A0B};`** (was L26)
> Each table is indexed by the choice of the same name in HomeGradientChoices.m and is as long as
> that list of names.
>
> Sampled off the design: #0B4110 at the top of the screen, level behind the header, gone by 390pt,
> which is Medium at Medium. The other seven colours are that one taken around the wheel.

**`static uint32_t strengthened(uint32_t rgb, CGFloat factor) {`** (was L52)
> Strength is the colour itself taken up or down rather than its alpha, so that Subtle stays as
> saturated as Bold instead of washing out into the page behind it.

**`@interface SGHomeGradientView : UIView`** (was L63)
> A view of its own, so the wash follows the page's layout passes instead of animating itself
> through CoreAnimation whenever the inset changes.

**`- (void)paintColor:(uint32_t)color span:(CGFloat)span {`** (was L78)
> The page lays out on every scroll, so a pass that changes neither the colour nor how far it
> reaches leaves the layer alone.

**`static void stripCells(UIScrollView *list) {`** (was L93)
> The shelves and the shortcuts grid are lists of their own, each painting the base surface over
> the wash. A cell paints itself before the page puts it in, where the hook in Native/Appearance/Repaint.x cannot
> see that it belongs to Home, so every cell is stripped once as it turns up; the repaints it
> takes later, in the page by then, go through the hook. The page's own paint is behind the wash.

**`view.layer.zPosition = -1;`** (was L112)
> A list puts its cells in at index 0, so that its scroll indicators stay on top of them;
> the subview order alone would push the wash over the content. Depth settles it instead.

**`static void layoutGradient(UIScrollView *list) {`** (was L122)
> Content coordinates: the content starts below the header, so the wash starts at minus the inset,
> where the top of the screen is when the list sits still.

**`%hook _TtC16Home_CarouselKit29TouchCancellingCollectionView`** (was L156)
> The list lays out on every scroll too, which is when the bars change its inset. Album, artist
> and playlist pages are lists of the same class, hence the check for the one Home owns.

**`%hook _TtC19Home_FunkisPageImpl20FunkisViewController`** (was L165)
> The scrim is a gradient view one view under the page's own; the gradients of the cards sit far
> deeper than that, so two levels cannot reach them.

## `Native/Home/HomeGradientChoices.m`

**file overview** (was L1)
> What the Gradient page offers and what the hooks read back, one entry per setting: the names, the
> key it is stored under and the index it falls back to. HomeGradient.x carries the numbers behind
> the names, in the same order as the names themselves.

**`@(SGHomeChoiceTint): @{`** (was L12)
> Eight rotations of the green the wash was born as, at the same depth and saturation
> around the wheel, so each of them sits behind white text the way the green does.

## `Native/Lyrics/LyricsPage.x`

**file overview** (was L1)
> The full screen lyrics page on glass ("Glass lyrics" on the Lyrics page): the card under the player
> reads as having grown to the screen (Native/Player/LyricsCard.x).
>
> Page (trees/lyrics.txt): a page of its own, presented over the player by a
> _UIOverFullscreenPresentationController, which is why the card's glass stops at the card's edge.
> Tome_PageTemplateImpl paints the template view #121212 and FullscreenView paints itself the
> album colour on top, both opaque; clearing them lets the player's blurred artwork through.
>
> The album colour is the stubborn one: it arrives per track, after the page has laid out, and it
> comes back through a path Native/Appearance/Repaint.x never sees, so a sweep at layout time loses the race.
> FullscreenView is asked not to keep it at all instead. The pane goes inside FullscreenView, in
> front of whatever that view still fills itself with, rather than behind the whole page.

**`static UIView *clearAncestors(UIView *view) {`** (was L19)
> Up to the presentation: the template views in between paint themselves opaque once, at setup.
> Only the chain is cleared, not the subtree -- nothing else on the page is painted.

**`if (glass.overrideUserInterfaceStyle != UIUserInterfaceStyleDark) glass.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;`** (was L49)
> Dark whatever the system is set to, as the player's header panes are (Native/Player/Player.x):
> light glass under white lyrics otherwise, on a phone in light mode.

## `Native/Navbar/Navbar.h`

**file overview** (was L1)
> The native look's navbar: Spotify's own tab bar composed (Navbar.x, hooked from TabBarHooks.x): an
> ordered list of entries, each a dictionary. An entry with a URI is a tab of the mod's own; one without names
> one of Spotify's, by the label under its icon. No list at all is Spotify's order, all shown.

## `Native/Navbar/Navbar.x`

**file overview** (was L1)
> Navbar: which tabs the bar shows, in what order, and tabs of the mod's own that open any
> spotify: URI. Spotify keeps its four items (Home, Search, Library, Create) as the arranged
> subviews of one stack view, but a tap on one of them is answered by counting the row off from
> the left, not by asking the item what it is: moved in the stack, an item takes the tap of
> whatever used to stand there. So the stack's own order is left exactly as Spotify built it.
>
> The row is split into equal slots instead, and each item is given the frame of its slot after
> the stack's own pass: hit testing goes by frame, so the touch follows the icon, while Spotify
> still counts its items off in the order it put them in. Items of the mod's own go on the end of
> the stack, past that count, and take a slot with the rest. A tap on one goes through Spotify's
> link dispatcher, the same route the app takes for a link it opens itself, so any URI works.
>
> Tree (trees/home.txt): NavigationUI_TabBarImpl.TabBarView > TabBarCompactView > UIStackView
> 402x49 of four ElementContentView<TabBarItemElement> 100x49, each an SPTEncoreIconView 24x24
> at y 12.5 over an SPTEncoreLabel at y 35.

**`static CGRect sg_iconBox = {{0, kIconTop}, {kIconSize, kIconSize}};`** (was L28)
> Where Spotify's own items keep their icon and label, read off one of them every pass, so an item of
> the mod's own sits on the same line as its neighbours.

**`static NSMutableArray<NSString *> *sg_stockOrder;`** (was L37)
> Spotify's own tabs in Spotify's order, from the first layout pass of this launch, before
> anything below has moved them.

**`static UIView *iconView(NSString *name) {`** (was L45)
> One of the 538 glyphs SPTEncoreIcon exposes, one class method each ("podcasts", "heart"), so an
> item of the mod's own is drawn the same way as Spotify's. An SF Symbol stands in if the name is
> not one of them.

**`- (void)layoutSubviews {`** (was L104)
> Both boxes come off a neighbour, so whatever Spotify does to the row's line-up is copied rather than
> guessed at; only the horizontal centring is the item's own.

**`- (CGSize)intrinsicContentSize {`** (was L115)
> A row that splits its width evenly ignores this, but one that sizes itself to its content would
> otherwise have nothing to go on for an item of ours.

**`static NSString *stockID(UIView *item) {`** (was L136)
> Spotify's items are told apart by the label under the icon: it survives the element views being
> rebuilt, and it is the name the Navbar page lists them under.

**`for (NSString *ident in sg_stockOrder) {`** (was L208)
> Tabs of Spotify's the list does not name — or named before Spotify had built them — keep
> Spotify's own place, at the end, shown.

**`for (UIView *item in wanted) {`** (was L227)
> Items of the mod's own join the stack at the end, where they are past whatever Spotify
> counts, and Spotify's own keep the places it gave them.

**`static void centreContents(UIView *item) {`** (was L241)
> Spotify placed the icon and the label for the width it measured (trees/test5.txt: x 28 in a
> 134pt slot, the centre of the 80pt it had with five tabs) and lays the item out no further
> once the slot changes. Assigning the centres back sends them through the hooks below.

**`static void placeRow(UIStackView *stack) {`** (was L250)
> Equal slots across the bar, in the order composed above. The frames go on after the stack's
> own pass, so Spotify's own widths never decide whether a fifth item fits.

**`static CGFloat slotCentreX(UIView *view) {`** (was L274)
> Spotify's element layout places the icon and the label from the width it measured, not from
> the slot above (trees/test5.txt: x 38 in a 134pt element in a 126pt slot), and a view placed by
> its parent gets no layout pass of its own. So the placement itself is bent: on the bar, whatever
> x Spotify sets, the view lands centred on its slot.

**`void SGLogTabBarRow(UIView *tabBar) {`** (was L317)
> What the row settled on, logged whenever it changes: `make log` then says whether the items fit,
> what is holding their width, and in what order the bar ended up.

**`%hook _TtC28NavigationUI_TabBarItemsImpl29TabBarItemsNavigationListImpl`** (was L346)
> Whether Spotify reads its own item list through this ObjC bridge decides whether the bar can be
> composed at the model level, where the order, the taps and the widths would all follow by
> themselves, instead of by moving views about. Silence in the log says it cannot.

## `Native/Navbar/NavbarSettings.m`

**`static NSArray<NSDictionary *> *tabPresets(void) {`** (was L6)
> What "Add a tab" offers: URIs Spotify's own router resolves to a page of its own, each with the
> name of the SPTEncoreIcon class method that draws its glyph.

**`static NSMutableArray<NSMutableDictionary *> *navbarEntries(void) {`** (was L30)
> The list the Navbar page edits: the saved order first, then every tab of Spotify's it does not
> name, in Spotify's order. Entries for tabs Spotify no longer has drop out.

**`static void appendTab(NSDictionary *tab) {`** (was L50)
> A tab of the mod's own carries an identity of its own, so the same page can sit on the bar twice
> and renaming one does not shuffle the order.

**`@interface SGNavbarPage : SGPage`** (was L162)
> The tabs, in the order the bar shows them: drag to reorder, tap to show or hide, swipe a tab of
> your own away. Spotify's own tabs can only be hidden, never removed. Mod Settings and the welcome
> tour show the same editor.

## `Native/Navbar/TabBarHooks.x`

**file overview** (was L1)
> What drives the native look's navbar: Spotify's tab bar composed on its layout passes (Navbar.x), and
> holding Home opens Mod Settings.
>
> Tree (trees/home.txt): NavigationUI_TabBarImpl.TabBarView > TabBarCompactView > UIStackView of
> ElementContentView<TabBarItemElement>, each with an SPTEncoreIconView and an SPTEncoreLabel.

## `Native/NowPlayingBar/NowPlayingBar.h`

**file overview** (was L1)
> The native look's now playing bar: Spotify's own bar with its device button hidden on request
> (NowPlayingBar.x), and the bar's flags (NowPlayingBarSettings.m).

## `Native/NowPlayingBar/NowPlayingBar.x`

**file overview** (was L1)
> The device button of Spotify's own now playing bar, hidden on request.
>
> Tree (trees/test6.txt): the button row is a UIStackView holding Connect_EntryPointsImpl.ConnectStateView
> (the connected device) and .ConnectButtonView, each wrapped; hiding the wrapper closes the gap.
> The ConnectStateView under the title ("playing on ...") sits in InformationContainer and stays.

## `Native/Player/LyricsCard.x`

**file overview** (was L1)
> The lyrics card under the player on glass ("Glass lyrics" on the Lyrics page).
>
> Card (trees/now-playing.txt): a Lyrics_CardElementImpl.CardView inside an
> Element_List.CollectionViewCell 370x316. The cell is the painted surface with the 16pt corners,
> so the pane fills it and the cell's own clipping cuts the corners. The page the card expands into
> is Native/Lyrics/LyricsPage.x's.

**`sg_lyricsCardRoot = cell;`** (was L32)
> Spotify repaints the card with the album colour when the track changes, which is no layout
> pass of its own; Native/Appearance/Repaint.x keeps it clear in between.

**`if (glass.overrideUserInterfaceStyle != UIUserInterfaceStyleDark) glass.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;`** (was L37)
> Dark whatever the system is set to, as the player's header panes are (Player.x): light glass under
> white lyrics otherwise, on a phone in light mode.

## `Native/Player/NowPlaying.h`

**file overview** (was L1)
> The native look's player: Spotify's full screen player with the artwork background and glass header
> buttons (Player.x), the glass lyrics card (LyricsCard.x), the gestures' hookup (PlayerGestures.x) and the parts of it to hide (PlayerDeclutter.x). The glass
> lyrics page is Native/Lyrics/LyricsPage.x's and shares SGKeyLyricsCard ("Glass lyrics").

**`#define SGKeyPlayerLyricsOnly @"spotifyglass.hide.playerLyricsOnly"`** (was L28)
> The welcome tour's one switch for the player: on hides every card under the player but the
> lyrics, off shows them again. The player's buttons are not its business. Only the tour reads
> it; the hooks read the keys above.

**`NSArray<SGModSection *> *SGNativePlayerScreenSections(void);`** (was L35)
> PlayerSettings.m: the player screen's sections of the Player page, the Queue & devices page and the
> "Glass lyrics" row of the Lyrics page.

## `Native/Player/Player.x`

**file overview** (was L1)
> Full screen player: glass where Liquid Glass belongs and nowhere else, and the album colour
> behind it traded for the cover art.
>
> Glass is the navigation layer floating over content, so only the header's two round buttons get
> a pane, the way the Music app keeps its chrome. The playlist name between them is a label, and
> shuffle, repeat, previous, next and the footer (connect, share, queue) are bare glyphs over the
> artwork next to Spotify's white play disc: a pane each turned both rows into a strip of glass
> discs sampling one another, which is the one thing the material cannot do. The cards below the
> player are surfaces rather than controls; the lyrics one is in LyricsCard.x.
>
> Tree (trees/now-playing.txt): NowPlaying_ModesImpl units, each a child controller whose view
> holds one UIStackView row; the header row is chevron 48x48, playlist name 110x48, more 48x48.
>
> The background is one plane the size of the screen painted the album colour, Spotify's gradients
> on top of it, and it is NPVBackgroundViewController's own view. Glass over a flat fill samples
> that same flat fill back, which is why the header panes cannot be made out on it; white text and
> Spotify's green both sit badly on saturated colour as well. SGKeyPlayerBackdrop strips the plane
> and puts the cover behind the player instead, shrunk until none of the picture is left in it,
> blurred, under a scrim ending near black so the cards scrolled up from below meet it. The switch
> covers what that field changes around it too: the artwork takes corners and a shadow so it sits
> on the field rather than being pasted onto it, the lyric under it drops behind the title in
> contrast, and the timestamps take monospaced digits so they stop twitching every second.

**`static void glassBehindRoundButtons(UIViewController *unit) {`** (was L37)
> A glass circle per round button in the unit's row: children about as wide as they are tall.
> The playlist name is 110 wide against 48 tall, so it keeps no pane, and neither do the children
> PlayerDeclutter.x made invisible.

**`if (glass.overrideUserInterfaceStyle != UIUserInterfaceStyleDark) glass.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;`** (was L53)
> Dark whatever the system is set to: the player is presented outside the navigation stacks
> Spotify makes dark itself, so its panes took the system's light glass on a phone in light mode.

**`static UIImage *coverInFront(UIScrollView *list) {`** (was L88)
> The covers are the cells of a list scrolled sideways, one per track in the queue; the cell under
> the middle of the list is the one playing.

**`if (backdropOn()) ((UIView *)self).alpha = 0.72;`** (was L170)
> White at full strength, and alone in the space under the artwork, the line reads louder than
> the title it sits above. PlayerDeclutter.x hides the same view outright.

## `Native/Player/PlayerDeclutter.x`

**file overview** (was L1)
> Player declutter: hides parts of the full screen player, one switch each on the Player page. Cards
> under the player are Element_List cells; a hidden one reports zero height when the list sizes it,
> so the list closes up around it (the 24pt gap between cards stays). Player buttons go invisible but
> keep their place, so their row stays centred.
>
> Trees (trees/now-playing*.txt): every card is a CollectionViewCell whose content view names the
> page (NowPlaying_ScrollAPI) and whose subtree names the card. Player rows are the UIStackView of each NowPlaying_ModesImpl unit: playback controls
> hold shuffle, previous, play, next, repeat; the footer holds connect, a hidden button, share
> and the queue; track info ends with the add-to button.

**`static NSString *classNamesIn(UIView *cell) {`** (was L27)
> Class names of everything in the cell. Lists nested in the cell are laid out first so the
> cells that name the card (video cards) exist.

## `Native/Player/PlayerGestures.x`

**file overview** (was L1)
> The native player's hookup of the gestures (Shared/Gestures): the double tap goes on the player's artwork list.
>
> Tree (trees/now-playing.txt): the artwork sits in AccessibleCollectionView, a full screen list of
> the queue scrolled sideways, so the recognizer goes on that and the grid is the screen. Spotify's
> controls are sibling units rather than children of it, so a tap on a button never reaches it.

**`%hook _TtC35CreativeWorkCommons_CoverArtTiltKit16CoverArtTiltView`** (was L9)
> A single tap on the cover is Spotify's way into the tilt mode, the artwork alone in 3D. That is
> the half of a double tap that misses, so while the zones are on it would open on the way to every
> gesture; the tap goes back to Spotify with the switch.

## `Native/Player/PlayerSettings.m`

**file overview** (was L1)
> The native player's settings: Spotify's own player screen and the parts of it to hide, and the queue
> and devices flags. The Player page that holds them is App/Pages.m's.

## `Native/Playlist/Playlist.x`

**file overview** (was L1)
> Playlist: hides parts of a playlist page, one switch each in Mod Settings > Home & Library. Album and
> artist pages are built by another framework and are left alone.
>
> The header parts are hidden from the layout pass that places them, not from the view
> controller's: the elements arrive after the page does, and a controller whose own view is not
> dirty never hears about it, so anything hidden a level up flashes first.
>
> Tree (trees/test-playlist.txt): HeaderContentLayout holds the cover over a block of title,
> description, the creator row, the length and HeaderActionsRow, a stack of the video deck, add,
> download, share and more. The header names every one of them with an accessibility identifier,
> so the switches go by those; the description and the find bar have none and go by class.
>
> The header's height is not measured from what it shows: -[SPTFreeTierPlaylistEncoreHeaderViewController
> update] adds three numbers into a stored fullHeaderHeight and pins headerViewHeightConstraint to
> it, so a hidden cover leaves the room it was counted for. collapseCover() takes that room back.

**`static void applyColumn(UIView *header) {`** (was L55)
> Title, description, the creator row and the length share one column, and only the description
> names a class of its own, so the column is reached through it and its rows go by what they hold.
> The length is the last row rather than the second stack: a byline without faces is a stack too.

**`static void applyActions(UIView *row) {`** (was L73)
> The identifier sits on the button, the stack arranges the action around it, so each switch hides
> the action rather than the button and the row closes up behind it.

**`static void collapseCover(UIViewController *headerVC, UIView *layout, UIView *cover) {`** (was L99)
> Takes back the room the hidden cover was measured into. The cover swells to fill whatever the
> header's height leaves over, so the block below it moves up to where the cover began and the
> height constraints come down by as much; the cover then has nothing left to swell into.
>
> Both numbers are read back from the frames Spotify has just set, so once the header has shrunk
> the next pass finds nothing to take and stops. The header constraint holds the content layout
> and the top accessory above it, so it is the taller of the two; if it ever is not, it is not the
> constraint sizing this layout and nothing is touched -- which is also the brake that stops this
> shrinking for ever should the header stop following.

**`static void applyBackdrop(UIView *layout) {`** (was L142)
> The cover blurred behind the header in place of Spotify's colour wash. The header's background
> (trees/test6.txt) is a HeaderView under _backgroundViewContainer holding the wash, then a black
> view that fades in as the page scrolls; the backdrop goes between them so the scroll still darkens
> it, and its scrim ends in the black of the rows below. No cover, no backdrop: the wash stays.

**`%hook UIStackView`** (was L202)
> The buttons fill in after the header is laid out, and a row that keeps its size never makes the
> header lay out again, so they stay up until something else does -- the cover loading, a second on.

**`%hook SPTFreeTierPlaylistEncoreHeaderViewController`** (was L211)
> The find bar is not in the header layout, and it fades in on its own rather than appearing, so
> the controller's pass is soon enough for it.

**`%hook _TtC35ListUXPlatform_FreeTierPlaylistImpl25ElementCollectionViewCell`** (was L221)
> The pills are a cell of the track list. ListUXPlatform_LayoutKit.ListLayout gives every item its
> height, so a cell can only close up where the layout asks it how tall it wants to be; if it
> never asks, the log stays quiet and the pills stay.
