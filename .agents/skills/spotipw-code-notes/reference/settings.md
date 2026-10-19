# Settings

10 files, 38 notes, moved out of the code (tweak/Sources/Settings/).

## `Settings/SGDiscordIcon.m`

**file overview** (was L1)
> The Discord mark, the leading icon of the settings row that links to the server: the official glyph
> (simple-icons, CC0) kept as the base64 PNG of a white template on clear and decoded once at first
> use. It decodes as a template, so the row tints it whatever colour it is given (SGDiscordColor).

## `Settings/SGGlowSwitch.h`

**file overview** (was L1)
> A switch that glows: a capsule whose rim is a slowly circling rainbow with a soft glow of the same
> colours, full when on and softer when off, to invite the tap. A white knob slides on a spring.
> For the one switch of a page that changes the whole app (Redesigned UI in Appearance); every other
> switch stays a UISwitch.
>
> It answers isOn and sends UIControlEventValueChanged the way a UISwitch does, so a page treats both
> alike. The rim stops circling under Reduce Motion, and the glow is left out under Reduce Transparency.
> Threading: main thread only.

**`NSArray<UIColor *> *SGGlowRainbowColors(void);`** (was L16)
> The rainbow the switch circles its rim with: the stops in order, first and last the same pink so the
> turn has no seam. Shared so the Taurus wordmark wears the same one.

## `Settings/SGGlowSwitch.m`

**`NSArray<UIColor *> *SGGlowRainbowColors(void) {`** (was L12)
> Around the capsule the way a conic gradient runs, starting and ending on the same pink so the turn
> has no seam.

**`_glow = [CALayer layer];`** (was L79)
> The glow: the rainbow cut to a wide stroke, blurred as a whole, in a layer larger than the switch
> so the blur has room to spread.

**`- (void)paint {`** (was L165)
> Colours for the state. Off is meant to tempt: the rainbow already circles the rim, softer, with a
> fainter glow. On it comes in full, glow and all.

## `Settings/SGModPage.h`

**`@interface SGModRow : NSObject`** (was L4)
> A row is a switch when it has a key, a link to another page when it has a page and a slider when it has
> a number. A flag row
> switches one of Spotify's remote-config flags: on forces it (off for a forceOff row, which is how
> a flag Spotify ships on is turned off), the switch off leaves Spotify's own value. A row
> with a value reads one out on the right and is asked again while the page is open; a page row
> with a value reads it out too, next to the chevron, and is asked when the page appears. A row
> with an action runs it when tapped.

**`@property (nonatomic, strong) UIImage *image;`** (was L25)
> A leading icon of its own in place of `symbol`, tinted `color` (or white): SGDiscordIcon for the
> row that links to the server.

**`@property (nonatomic, copy) BOOL (^visible)(void);`** (was L32)
> The row shows only while this answers YES, asked again whenever a switch on the page is flipped or the
> page comes back from a choice's list: the row fades in or out where it sits. Nil shows it always.

**`@property (nonatomic) double minimum, maximum, step;`** (was L39)
> A slider row's (SGSliderRow): its range and step, and the blocks that read its number, store one and
> write one out.

**`@property (nonatomic, copy) double (^progress)(void);`** (was L45)
> A row whose value moves along with something going on (a download): a thin bar along its bottom shows
> `progress` while it answers 0...1 and goes while it answers less, and whenever `refreshOn` is posted
> the page reads its rows out again and asks which of them show, rather than waiting for its next tick.

**`SGModRow *SGChoiceRow(NSString *title, NSString *subtitle, NSString *key, NSArray<NSString *> *choices, NSInteger fallback);`** (was L78)
> A setting picked from a list of names, stored under `key` as the index into it: the row reads the
> name of the current one out and opens a list of them, a checkmark against that one.

**`SGModRow *SGSliderRow(NSString *title, NSString *subtitle, double minimum, double maximum, double step,`** (was L81)
> A number on a slider under the row's title, written out by `format` on the right: the thumb snaps to
> `step` and each step is stored through `set` as the thumb reaches it, so a setting applying as it
> changes applies while it is dragged. `subtitle` may be nil.

## `Settings/SGModPage.m`

**`SGModRow *SGUnstableRow(NSString *title, NSString *subtitle, NSString *key, NSString *warning) {`** (was L37)
> A switch whose work is not finished: turning it on says so first, and offers the repo to anyone
> who would rather fix it than live with it.

**`SGModRow *SGWarningRow(NSString *title, NSString *subtitle, void (^action)(void)) {`** (was L73)
> Red, with a warning symbol. SGFillCell tints the title and the symbol; the cell below takes the
> colour down to the subtitle too, so the whole row reads as the warning it is.

**`@interface SGChoicePage : SGPage`** (was L90)
> The list a choice row opens: the names it was given, each over its note where it has one, a green
> checkmark against the one set. Picking one writes the index, tells the row, and goes back, where the row
> it came from reads the new name out and the page it sits on rebuilds around it.

**`SGModRow *SGChoiceRow(NSString *title, NSString *subtitle, NSString *key, NSArray<NSString *> *choices, NSInteger fallback) {`** (was L170)
> No key on the row: the key lives in the blocks, so the page draws the row as the link it is
> rather than as a switch. The notes and the callback are read off the row when its list opens, so they
> can be set after this returns.

**`SGModRow *SGStatActionRow(NSString *title, NSString *subtitle, NSString *(^value)(void), void (^action)(void)) {`** (was L206)
> A value on the right and a tap: the Updates row reads its status out of About/Update.m every tick,
> and a tap asks the site again instead of waiting for the six hour cache to lapse.

**`static UIView *valueAndChevron(NSString *text) {`** (was L235)
> What a page row carrying a value shows on the right: the value, then the chevron, the same
> distance apart as Spotify's own rows keep them.

**`static BOOL flagRowOn(SGModRow *row) {`** (was L253)
> On means the row's own override is in place; anything else, including the opposite override
> somebody set from the All flags page, reads as off.

**`static BOOL flagRowLocked(SGModRow *row) {`** (was L260)
> A flag something of the mod's forces (Core/SGFlagForce.h: the redesign, the ad blocking): its row
> shows what is forced and takes no touch, so the flag has one place to change.

**`static BOOL lockedRowOn(SGModRow *row) {`** (was L266)
> What a locked row shows: the forced value, read the row's way, so a Disable Canvas row reads on
> while Canvas is forced off.

**`@interface SGModSliderCell : UITableViewCell`** (was L309)
> The Audio effects page's slider row (Shared/AudioEffects/AudioEffectsPage.m), for any page: the title and the
> value over a slider in the accent colour, a subtitle between them when there is one, each step stored
> as the thumb reaches it.

**`static void showProgress(UITableViewCell *cell, SGModRow *row, BOOL animated) {`** (was L413)
> A row's progress as a thin bar along the bottom of its cell, on the card's own side margins; a cell
> reused for a row without one loses it.

**`NSMutableSet<NSNotificationName> *refreshOn = [NSMutableSet set];`** (was L460)
> A page row reads its value out when the page appears rather than on the ticker, so only the
> rows whose numbers climb on their own keep one running.

**`- (BOOL)showRowsThen:(void (^)(void))done {`** (was L481)
> The rows that are to show now fade in where they sit and the others fade out, and whatever came in is
> scrolled into view: it opens under the switch that brought it, which may be the page's last row. Answers
> whether anything moved; `done` runs once it has, and only then.

**`- (NSIndexPath *)pathOf:(UIView *)control {`** (was L515)
> The row a switch or an ⓘ belongs to, by the cell it sits in: rows coming and going move the rows under
> them, so a position remembered when the cell was made may be stale.

**`_shown = [self rowsToShow];`** (was L542)
> Reloaded whether or not anything ticks: a choice row is showing whatever was picked on the
> page it opened, which is gone by the time this one comes back, and may bring rows or take them.

**`[_ticker invalidate];`** (was L551)
> The counters climb while the page is open; the labels are written straight into the cells so
> that a reload never lands under a switch being dragged. A cancelled back swipe appears the
> page again without it ever disappearing, so the old timer goes first.

**`NSTimeInterval wait = [toggle isKindOfClass:SGGlowSwitch.class] ? 0.45 : 0;`** (was L735)
> A glowing switch is let finish its slide before the reload puts a new one in its place; rows coming
> or going are let finish first too.

## `Settings/SGOrderPage.h`

**`UIViewController *SGOrderPage(NSString *title, NSArray<SGOrderItem *> *items, NSArray<NSString *> *(^read)(void),`** (was L12)
> `items` in the order a fresh install asks them; `read` answers the keys switched on, in order, and
> `write` stores a new one. `note` sits under the list.

## `Settings/SGOrderPage.m`

**`- (NSIndexPath *)tableView:(UITableView *)table targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)from toProposedIndexPath:(`** (was L132)
> Dragging stays inside the order; a source is switched on and off by tapping it, not by dropping
> it into the other section, so an order is never lost to a stray drag.

## `Settings/SGPage.m`

**`static BOOL sg_pagesConform;`** (was L6)
> Spotify's navigation controller asserts that everything on its stack is one of its own pages
> (SPNavigationController.m:645, "[viewController conformsToProtocol:@protocol(SPTPageController)]"),
> and the tab bar asks it for that page on every tab tap to log the interaction. A plain view
> controller of the mod's pushed onto that stack therefore takes the app down the next time a tab
> is pressed, from wherever it was left. The pages below answer the protocol's two questions
> instead and are registered as conforming at load; if the protocol is gone they are presented
> rather than pushed, so a rename in some later Spotify costs the push, not the app.

## `Settings/SGPageStyle.h`

**file overview** (was L1)
> Spotify's own list look, for every page of the mod's: a 13pt white title over an 11pt grey
> subtitle on #121212, 38pt uppercase section headers, green switches.

## `Settings/SGPageStyle.m`

**`void SGFitNote(UITableView *table, UIView *wrapper, CGFloat top, CGFloat bottom) {`** (was L31)
> Header and footer views keep the height they are given, so size them to their text. Only the
> size is compared: the table moves the footer's origin itself, and reassigning on that would
> loop forever.

**`void SGInsetForBars(UITableView *table) {`** (was L59)
> The now playing bar and the tab bar float over the content, and the safe area does not cover
> them, so the pages inset themselves by however much of the window the bars take.

**`static NSString *const kAmoledKey = @"spotifyglass.amoled";`** (was L70)
> The pages follow the running look's black and accent colour, read here by their keys so the page
> framework depends on no layer: the native look's AMOLED switch and accent (Native/Appearance), or the
> redesign's accent (Redesigned/Kit/SGRAccent.h), which is always black.

**`void SGFillCell(UITableViewCell *cell, NSString *title, NSString *subtitle, UIColor *color, NSString *symbolName) {`** (was L110)
> Every page below draws Spotify's own list row: a 13pt white title over an 11pt grey subtitle,
> with an optional symbol in the leading slot.
