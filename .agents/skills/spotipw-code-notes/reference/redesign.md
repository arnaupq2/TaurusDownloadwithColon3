# Redesign (the mod's own Liquid Glass look)

99 files, 523 notes, moved out of the code (tweak/Sources/Redesigned/).

## `Redesigned/Album/Album.h`

**file overview** (was L1)
> The album redesign: Spotify's album page kept, with its header, its track list and its controls, and laid
> out the way the Music app lays an album out -- the same page the playlist redesign gives a playlist, so
> the two read as one app.
>
> The album page is not the playlist's. It is built by the Creative Work Platform out of the element
> framework (trees/clean/album/01.txt: CreativeWorkPlatform.CreativeWorkTemplateView, a header element over
> one list), its header is a column of stack views rather than a plain block, and its play and shuffle
> float over the page instead of scrolling with the header. So none of Redesigned/Playlist/ is shared: only
> the Kit is, which is what keeps the look the same.
>
> AlbumField.x     the artwork field behind the whole page, the artwork it is read from, the flags the
> screen forces
> AlbumHeader.x    the header: the cover full bleed at the top dissolving into the field, and the Kit's
> SGRHeaderInfo over it -- title, artist, kind and date, shuffle, a white Play, add
> AlbumRows.x      the track rows on the field with no surface of their own and a hairline between them
> AlbumSections.x  everything under the tracks dropped but the album's own line and its copyright: no
> more by the artist, no videos, no concerts, no merch, no you might also like
> AlbumSettings.m  the Albums page of Mod Settings
>
> Every hook installs only while Redesigned UI is on (SGRedesignedUI); the native look's do not then.
> Threading: main thread only.

**`UIView *SGRAlbumPageOf(UIView *view);`** (was L32)
> The album page `view` is on, or nil: the CreativeWorkTemplateView that carries the header, the list and
> the two floating controls (trees/clean/album/01.txt:22).

**`UIColor *SGRAlbumFieldColor(UIView *view);`** (was L36)
> AlbumField.x. The field belongs to the page `view` is on, found by walking up from it, so two album pages
> on the navigation stack keep a field each.
>
> The colour the page's field is showing, SGRNeutralField() before one has been read: what the header's
> cover has to dissolve into for there to be no seam.

## `Redesigned/Album/AlbumField.x`

**file overview** (was L1)
> Album redesign: the artwork field behind the whole page, and what the switch forces.
>
> Tree (trees/clean/album/01.txt:22). The page is CreativeWorkPlatform.CreativeWorkTemplateView, and it
> holds, in this order: the header's colour wash (a LegacyUI HeaderView the height of the header, with
> Spotify's GradientView in it), CreativeWorkPlatform.Tab with the scrolling list inside it, the sticky
> HeaderNavigationBar, and the two controls Spotify floats over the page, shuffle and play. Nothing of it
> scrolls except what is inside the Tab, so a field put behind the lot stays still while the cover at the
> top of the header slides up over it -- which is what the Music app does with the page colour.
>
> So the field is the page's bottom-most view, the size of the view and bleeding past it, with no backdrop
> of its own: the sharp cover at the top of the header is the picture, and AlbumHeader.x fades it into
> exactly this field's colour, and conceals Spotify's wash so the field is what shows. What Spotify paints
> over the field -- the list and every row, all of them the base surface -- is kept clear by the Kit's
> repaint hook while sgr_albumRoot is this page, and by the list's own pass below, which paints itself
> rather than through a layer the repaint hook would hear about.
>
> The colour is the cover's main colour (Kit/SGRPalette.h); before it is read the field is the neutral one.
>
> The page is the album's by its identifier, which is how Native/Album/Album.x has told it apart since it
> shipped: the artist page is TemplateKit's TemplateView instead. A podcast's episode page is built from
> this same template (trees/continuous/1.txt 2026-09-20: CreativeWorkTemplateView over Element_List cells
> of EpisodePage_ModernEpisodePageImpl), so it is given the field too, and everything below that holds for
> the album holds for it. What it puts on the field is its own -- a description, a comments card, Episode
> Transcript, See all episodes -- and only the paint is taken off it; AlbumHeader.x and AlbumSections.x
> look for the album's own elements and find none of them there.

**`static BOOL isPageCell(UIView *cell) {`** (was L46)
> A cell of the page's own list rather than a card inside one of its carousels: a card is a cell of the
> same class, and the row that carries the carousel decides for it (Artist/ArtistSections.x). So the walk
> up to the page stops at the first cell it meets on the way.

**`sgr_albumRoot = page;`** (was L93)
> The page the repaint hook keeps clear is the one laying out, which is the one on screen; an album
> pushed over this one sets itself from its own pass, and this one sets itself again coming back.

**`SGRRevealHold(page, 0);`** (was L96)
> Behind a curtain from the first pass (Kit/SGRReveal.h), which the header claims once it knows the page for
> an album's (AlbumHeader.x). An episode page is this template too and never is, so its curtain lifts
> unclaimed a moment later.

**`%hook _TtC32CreativeWorkPlatform_TemplateKit28CreativeWorkTemplateListView`** (was L107)
> The list paints itself the base surface from its own pass. Its collection view is a private class whose
> name carries a build hash, so the list view around it -- one public name, one child -- is where it is
> cleared.

**`%hook _TtC12Element_List18CollectionViewCell`** (was L122)
> Every cell of the list paints the base surface too, and the repaint hook misses it: a cell is painted
> before it is inside the page, and a reused one brings its old paint with it. On the episode page the
> Episode Transcript row, the empty section under it and the rule under that sat on black bands (device,
> trees/continuous/1.txt 2026-09-20).

**`@"ios-album-albumfeatureproperties-impl.context_menu_in_navigation_bar_enabled": @NO,`** (was L137)
> More stays in Spotify's own header row, blanked with the rest of the column, and the redesign pins
> its own glass ⋯ over the page (Kit/SGRActionRow.h). In the navigation bar -- which this flag is
> Spotify's own way of putting it, and which the redesign forced until 2026-09-20 -- it was gone as
> soon as the page was scrolled (the playlist's tree caught the bar's trailing slot empty,
> trees/continuous/1.txt, issue #57).

## `Redesigned/Album/AlbumHeader.x`

**file overview** (was L1)
> Album redesign: the header the Music app gives an album (iOS 26.4), the same one the playlist redesign
> gives a playlist. The cover runs full bleed across the top of the page and dissolves into the page's
> colour; the title, the artist and the kind and date are centred on the bottom of that dissolve; and under
> them one row -- shuffle, a white Play capsule, and add.
>
> Tree (trees/clean/album/01.txt:39-152). The header is one element of the page's scrolling stack,
> id=CreativeWorkPlatform.Components.UI.CreativeWorkHeader, a plain UIView whose height the element framework
> measures from what it holds, down a chain of four stack views:
>
> UIView {0, 78}                     the top inset, the status bar and the navigation bar's room
> UIStackView                      the two groups
> UIView 402x321                 the top group: the cover square, a spacer, and the title block --
> TitleRow, and ParentRow, the artist with a facepile
> UIView {0, 329} 402x71         the bottom group: Components.UI.MetadataRow (the kind and the date,
> cells of a collection view) and the action row
>
> What the header shows is the redesign's own (the Kit's SGRHeaderInfo), not Spotify's rearranged: moving
> Spotify's stacks meant answering every pass of theirs, and the element framework measured the title for
> its own font. So Spotify's whole column is concealed and the Kit's view is drawn over the header in its
> place, reading its text off Spotify's concealed labels -- so it is in the app's language and follows
> whatever Spotify shows -- and drawing and firing Spotify's own controls. The header keeps its height, its
> fade as the page scrolls and its place in the stack.
>
> Play and shuffle are not in the header. The album page floats them over the page, pinned to the top
> trailing corner outside the scroll (01.txt:1431, :1436): they are concealed where they are, and the row
> draws them and fires them all the same.

**`static const CGFloat kDissolve = 0.46, kTopScrim = 140, kTopScrimAlpha = 0.28;`** (was L35)
> How much of the cover's height the dissolve into the field covers, and the scrim over the top of it that
> keeps the status bar and the back button legible on a bright picture. The playlist's numbers: one page.

**`static const CGFloat kMinHero = 120, kMinCover = 80;`** (was L38)
> A header whose text begins nearer the top than this is one mid load, not one to measure the hero from;
> and an artwork view narrower than this is a placeholder glyph rather than the cover.

**`static void conceal(UIView *view) {`** (was L48)
> Invisible for good. Spotify fades the header and the two floating controls by alpha as the page scrolls,
> so a redesign that answers with alpha is in a fight it loses a frame of on every scroll. `hidden` on the
> layer cannot be undone by a write to alpha, costs nothing per frame, and, unlike -[UIView setHidden:],
> tells neither KVO nor the stack views of it, which is what makes it safe on Spotify's Encore layouts; an
> empty mask holds when Spotify shows the view again with -setHidden:NO, which the playlist page does when
> Play is pressed (Playlist/PlaylistHeader.x).

**`static void blank(UIView *view) {`** (was L62)
> Drawn by nothing but not hidden: for Spotify's own column of the header, which the redesign still reads. A
> hidden collection view makes no cells, and the kind and the date are cells ("no metadata" in the harness
> with the column hidden, 2026-09-18), so the column keeps laying itself out and only its drawing goes.

**`static UIView *wrapperFor(UIView *control, UIView *stop) {`** (was L72)
> The outermost view that still wraps the control exactly: the element view Spotify's layout places, so
> concealing it leaves the control itself alone to be read and fired.

**`static UIView *floatingIn(UIView *page, NSString *identifier, const void *cacheKey) {`** (was L84)
> One of the two controls Spotify floats over the page. They are direct children of the page and 48pt
> across, so only the small children are searched: the wash, the tab and the navigation bar are the width
> of the page, and walking into the tab would be walking the whole list on every pass that missed.

**`@interface SGRAlbumHero : UIView`** (was L117)
> The picture across the top of the page with the field showing through the bottom of it. Two gradients
> rather than a mask or a blur: a scrim over the top for the status bar, and under it a fade from the
> picture to the very colour the page's field is drawing, so the two meet with nothing to see.

**`- (void)followCover:(UIImageView *)source;`** (was L123)
> The cover in Spotify's artwork view, and every cover it puts there afterwards: the hero keeps itself
> right, rather than being handed a picture on each of the header's passes and staying empty between them.

**`[CATransaction begin];`** (was L183)
> The clear end is the same colour with no alpha rather than +clearColor, so the fade keeps its hue
> instead of going through grey.

**`- (void)takeCover:(UIImageView *)source late:(BOOL)late {`** (was L299)
> `late` is a cover that arrived after the header had laid out -- an album opened for the first time, whose
> artwork is still being fetched while the page is already on screen. The log line says once that the watch,
> and not one of the header's passes, is what filled the hero.

**`static UIImageView *coverImageIn(UIView *cover) {`** (was L318)
> The image view of Spotify's artwork square: the one with the cover in it, or, before the cover has been
> fetched, the empty one it will land in, so it can be watched from the first pass.

**`static void applyHero(UIView *header, UIView *cover, CGFloat bottom) {`** (was L332)
> The picture runs from the top of the header down past where its text begins, so the title and the artist
> sit on the bottom of its dissolve; below that the page's field is already drawing the very colour the
> picture dissolves into, so there is no seam to see.
>
> `bottom` is taken from the header at rest, never from where it is mid scroll, and only ever grows: a header
> still loading is shorter than it will end up, and once the cover and the artist are in it settles and the
> picture does not change size again.

**`static NSString *metadataText(UIView *metadata) {`** (was L380)
> The kind and the date ("Album • 31. 1. 2025", "Single • 2024") are cells of a collection view, a label each;
> read in the order they are drawn in.

**`NSInteger tries = [objc_getAssociatedObject(header, &kRetryKey) integerValue];`** (was L420)
> The kind and the date are cells the metadata row's collection view makes on its own pass, after the
> header's, and nothing lays the header out again when they arrive; the collection is Spotify's own Swift
> class, which cannot be watched. So an empty row is read again a moment later, for as long as the page's
> curtain waits at most (Kit/SGRReveal.h): the page is shown once they are in, so soon is better.

**`[info showCreatorLink:parent];`** (was L433)
> The artist under the title, opened from the line that names them. ParentRow is one control for the
> whole line however many artists are on the album, so several of them open Spotify's own picker
> (issue #56).

**`UIView *inRow = add ?: download ?: SGRFindByIdentifier(header, @"Components.UI.WatchFeedEntityExplorerButton", &kExploreKey);`** (was L453)
> Add arrives after the header has laid out on an album opened for the first time (the next time its state
> is cached and it is there from the start), in a row that lays nothing else out (Native/Album/Album.x): the
> row drew download on Play's right, or nothing, until the page was opened again (issue #19). So the row's
> own pass is watched, a plain UIStackView, as the artist page's is, found from whichever of Spotify's
> buttons is in it already.

**`static void maskOut(UIView *view) {`** (was L476)
> Drawn by nothing, whatever Spotify does to it: an empty mask. Spotify switches the navigation bar's
> gradient on and off with -setHidden:, which writes the layer's own hidden and so undoes conceal(); and
> it fades both gradients by alpha. Neither touches a mask.

**`static void applyWash(UIView *page) {`** (was L485)
> Spotify's colour wash behind the header goes, so the page's field shows through.
>
> The navigation bar's gradient goes too. Hidden at rest, it is shown as the page scrolls under the
> title, and over the field it was a flat dark band across the top (device, 2026-09-18). What keeps the
> title legible over the list is the soft top edge every redesigned page has (SGREdgeEffect.x), as it is
> on Home, Search and Library.

**`CGFloat rest = MAX([objc_getAssociatedObject(header, &kHeaderHeightKey) doubleValue], header.bounds.size.height);`** (was L508)
> The picture reaches to where the content's top is at rest, plus the title and the artist. The header at
> rest is the tallest it has been, so the picture does not change size as the header loads or scrolls.

**`watch(header, &kHeaderWatchedKey, ^(UIView *view) {`** (was L521)
> The header lays itself out again whenever its cover, its artist or its buttons arrive, which the
> page's own pass does not hear about. It is a plain UIView, so its pass can be watched.

**`%hook _TtC28EncoreConsumerMobile_BaseKit14PlayButtonView`** (was L536)
> The play button arrives in the page after the row that replaces it has been laid out, so a page opening
> showed Spotify's green disc in the corner until something else laid the page out. Its own pass is where
> it goes, and the class is Spotify's own so nothing else pays for the check.

## `Redesigned/Album/AlbumRows.x`

**file overview** (was L1)
> Album redesign: the track rows on the field, the way the Music app has them -- no surface of their own
> and a hairline from the text's edge between one row and the next.
>
> Tree (trees/clean/album/03.txt:524-575): every row of the page is an Element_List.CollectionViewCell
> holding an Encore.ListRow, id=Components.UI.RetrievalRowElementUI, with the title
> (EncoreConsumerMobile.View.Granular.Title), the artists under it (…Granular.Subtitle) and, at the
> trailing edge, Components.UI.ContextMenuButton. An album row carries no artwork -- every track on the
> page shares the cover the header is already showing -- so the hairline runs from the page's own margin,
> where the text starts.
>
> The row's paint is cleared here rather than left to the Kit's repaint hook, which only hears about a
> colour when Spotify sets it and not when a reused cell already carries one.
>
> Spotify's type is left alone: a row with metadata is 56pt for a title of 13pt, and a larger font of
> the Kit's would be cut off by the box the element framework measured for it. Rows without metadata close up.

**`static const CGFloat kHairline = 0.5;`** (was L20)
> Under the text rather than the whole row, as the Music app draws it; the trailing end clears the page
> margin.

**`if (SGRRevealWaitsFor(page, SGRRevealList) && SGRRevealShowsText(row)) SGRRevealMark(page, SGRRevealList);`** (was L139)
> The first track with its title in is the list the page waits for (Kit/SGRReveal.h); a row still loading
> draws grey bars with empty labels.

**`static BOOL isTrackContent(UIView *content) {`** (was L162)
> Which cells of Element_List belong to an album's track list, answered once per content class: the same
> cell class carries Home's sections and the album's footer too, and a walk up to the page on every pass of
> every cell is what the answer is cached to avoid.

## `Redesigned/Album/AlbumSections.x`

**file overview** (was L1)
> Album redesign: everything under the track list dropped but what the album itself says.
>
> Spotify closes an album page with a run of sections the server sends -- more by the artist, related music
> videos, concerts, merch, you might also like -- and more of them whenever it likes. None of them is the
> album. So the rule is not a list of their names, which would be a list in one language that the next
> section walks past: every one of those cells reports no height, and only two are kept.
>
> Tree (trees/clean/album/04.txt:979-2576). Everything under the tracks comes as an Element_List cell whose
> content is an ElementContentView over Album_PageImpl.FooterStructuredData -- the headings, the carousels,
> the merch cards, the 16pt spacers between them, and the two worth keeping:
>
> Album.ConsumptionExperience   "22 songs • 1hr 24min", the line the Music app puts under a track list
> Album.Copyright               the © and ℗ lines, which are the label's and stay
>
> The tracks themselves are the same cell class over RetrievalListStructuredData and are never touched here.
>
> A dropped cell is 0 tall, but what it holds keeps the height it measured at, hidden and cut off by the
> cell: Spotify's content squeezed to 0 with the cell breaks its own required constraints on every layout
> pass, which is what held the main thread where dropped sections scrolled in on Home (2026-09-17). The two
> kept cells are given the gap the spacers used to draw and their content is pinned under it.

**`static BOOL isKept(UIView *content) {`** (was L43)
> The two the album says about itself, restyled as it is kept: Spotify draws both in white, and under a
> track list they are a footnote, not a line to read.

**`static void settle(UICollectionViewCell *cell, CGFloat natural, CGFloat lead) {`** (was L59)
> The content laid at `lead` down the cell, at the height it measured at, and the cell sized for both.
> Kept on the cell so its own passes, which size the content to the cell again, do not undo it.

## `Redesigned/Artist/Artist.h`

**file overview** (was L1)
> The artist redesign: Spotify's artist page kept, with its list and its controls, decluttered and given the
> header the playlist and album pages have, so the three read as one app.
>
> The page is TemplateKit's TemplateView, id=creator-page (trees/clean/artist/01.txt:26, recorded
> 2026-09-16), not the album's CreativeWorkTemplateView: its header is an ImageHeaderView, the photo, the
> name, the listeners and a row of explore, follow, more, shuffle and play, which Spotify shrinks to a 100pt
> bar pinned at the top as the page scrolls; under it a strip of Music / Video / Merch tabs, each a list.
>
> ArtistField.x     the photo's field behind the whole page, the page kept clear on it, the tab strip
> gone (the Music list is the page), the flags the screen forces
> ArtistHeader.x    the header: the photo full bleed dissolving into the field, and the Kit's
> SGRHeaderInfo over it -- the name, the listeners, shuffle, a white Play and Follow
> ArtistSections.x  the sections the Music list carries that are not the artist's music: its videos
> ArtistFollow.x    whether the artist is followed, from Spotify's collection, for Follow's glyph
>
> Every hook installs only while Redesigned UI is on (SGRedesignedUI); the native look's do not then.
> Threading: main thread only.

**`UIColor *SGRArtistFieldColor(UIView *view);`** (was L23)
> ArtistField.x. The field belongs to the page `view` is on.
>
> The colour the page's field is showing, SGRNeutralField() before one has been read.

**`BOOL SGRArtistFollowing(UIView *page, NSString *moreIdentifier, BOOL *following, void (^changed)(void));`** (was L30)
> ArtistFollow.x. YES once Spotify's collection has said whether the user follows the page's artist, with
> the answer; NO until then. The first call subscribes for the page's lifetime, and `changed` runs on the
> main thread whenever the answer changes.

## `Redesigned/Artist/ArtistField.x`

**file overview** (was L1)
> Artist redesign: the photo's field behind the whole page, and the tab strip gone.
>
> Tree (trees/clean/artist/01.txt:26-40). The page is a TemplateView holding two scroll views of the page's
> size -- PCFFTabLayoutViewController.overlayScrollView and .containerScrollView -- and the container's stack:
> the header, then PCFFTabLayoutViewController.tabsViewAccessibilityID, the strip of tabs
> (Components.UI.TabsSectionHeading, 44pt) over a paging scroll view with one list per tab. The field goes
> under all of it, as the page's bottom-most view, and what Spotify paints the page, its lists and its rows
> with -- the base surface -- is kept clear by the Kit's repaint hook while sgr_artistRoot is this page.
>
> The strip is Music, Video and Merch. The Music list is the page the Music app gives an artist: the videos
> and the merch have their own tabs only so that they can be left out, so the strip goes and the Music list
> stays. The strip sits in an AutoLayoutStackView, which traps when a view in it hides, so it goes invisible
> and the pages under it move up into its place and stop paging, the way the native look's switch does it
> (Native/Artist/Artist.x).

**`SGRRevealHold(page, 0);`** (was L73)
> Behind a curtain from the first pass (Kit/SGRReveal.h), which the header claims once it lays out the photo
> header (ArtistHeader.x); a page with a header the redesign does not lay out is shown a moment later.

**`%hook _TtC32CreativeWorkPlatform_TemplateKit28CreativeWorkTemplateListView`** (was L83)
> Each tab's list paints itself the base surface from its own pass, and may have before the page first laid
> out and the repaint hook knew the page; its collection view is a private class whose name carries a build
> hash, so the list view around it -- one public name, one child -- is where it is cleared, as the album's is.

**`if (!SGRedesignedUI()) return;`** (was L132)
> No flags forced here. `ios-creator-impl.context_menu_in_navigation_bar_enabled_artist` moves more out of
> the header's row, and with it gone Spotify's OverflowStackView force-unwraps the tallest view of a line
> that has none and traps as the page opens (device crash 2026-09-18 19:09, SIGTRAP in -[OverflowStackView
> updateConstraints], OverflowStackViewLayoutBuilder.Line.tallestView nil). The row stays Spotify's, and
> ArtistHeader.x draws more itself.

## `Redesigned/Artist/ArtistFollow.x`

**file overview** (was L1)
> Whether the user follows the page's artist, read from Spotify's collection state (following saves the
> artist to the collection) rather than the Follow button, whose only state is its localized title.
> The provider is the one Spotify's own code uses, kept weakly.

**`static NSURL *artistURI(UIView *page, NSString *moreIdentifier) {`** (was L151)
> The artist the page is for. The artist page's controllers carry no URI, but the header's ⋯ does:
> Components.UI.ContextMenuButton-<artist id>.

## `Redesigned/Artist/ArtistHeader.x`

**file overview** (was L1)
> Artist redesign: the header the playlist and album pages have. The photo runs full bleed across the top
> of the page and dissolves into the page's colour; the name and the monthly listeners are centred on the
> bottom of that dissolve; and under them one row -- shuffle, a white Play capsule, and Follow.
>
> Tree (trees/clean/artist/01.txt:37-170). The header is TemplateKit's HeaderContainer, 568pt, the first view
> of the page's stack, holding an element view that holds the ImageHeaderView:
>
> UIView 402x424 clips                    the photo (Components.Header.UI.ArtworkImage) and a gradient
> UIView {16, 334}                        the name, Encore.AdaptiveTitle, 45pt
> ImageHeaderView.VerifiedBadge           "Verified by Spotify"
> Components.Header.UI.Metadata           "58,4M monthly listeners"
> UIStackView {4, 456} 394x48             explore, Follow (Curation.FollowButtonElementKit.FollowButton,
> a text button), more, Components.UI.ShuffleButton, and
> header-play-button
> UIStackView {0, 504} 402x64             Components.UI.ArtistHeadline, "Pre-save the upcoming album"
> HeaderForegroundView                    the 100pt navigation bar with the name, shown collapsed
>
> Scrolled (02.txt:26-30), the container keeps its 568pt and scrolls away with the page, while the element
> view slides down inside it and the ImageHeaderView shrinks to the 100pt bar, pinned at the top of the
> screen. So the photo and the redesign's text are the container's, not the ImageHeaderView's: in the header
> view they would be pinned at the top with it. The bar stays Spotify's, drawing the name once the page is
> scrolled, with its gradient masked out as the album's is.
>
> Everything else of the ImageHeaderView is drawn by nothing (an empty mask) and takes no touches: the badge,
> Explore, and the headline go with it -- the headline's pre-save is also the list's own Release Countdown
> section. The Kit's SGRHeaderInfo reads the name and the listeners off Spotify's concealed labels and draws
> and fires Spotify's shuffle, play and Follow, Follow as a glyph from the collection (ArtistFollow.x). More stays in Spotify's row, where the row needs it (ArtistField.x), and the Kit's pinned ⋯
> (SGRPinnedMore) draws and fires it from the top trailing corner of the page, level with the back button.

**`static const CGFloat kDissolve = 0.46, kTopScrim = 140, kTopScrimAlpha = 0.28;`** (was L33)
> How much of the photo's height the dissolve into the field covers, and the scrim over the top of it that
> keeps the status bar and the back button legible on a bright picture. The playlist's and the album's.

**`static void blank(UIView *view) {`** (was L46)
> Drawn by nothing and out of the way of touches, whatever Spotify does to it: an empty mask. Not hidden --
> the header's OverflowStackView traps when a view in it hides, and a hidden view is one the redesign still
> has to read and fire.

**`@interface SGRArtistHero : UIView`** (was L84)
> The picture across the top of the page with the field showing through the bottom of it: a scrim over the
> top for the status bar, and under it a fade to the very colour the page's field is drawing.

**`- (void)followArtwork:(UIImageView *)source;`** (was L89)
> The photo in Spotify's artwork view, and every photo it puts there afterwards: the hero keeps itself
> right, rather than being handed a picture on each of the header's passes and staying empty between them.
> The same view again only re-reads it.

**`- (void)takeArtwork:(UIImageView *)source late:(BOOL)late {`** (was L168)
> `late` is a photo that arrived after the header had laid out -- the artist opened for the first time,
> whose picture is still being fetched while the page is already on screen (issue #52). The log line says
> once that the watch, and not one of the header's passes, is what filled the hero.

**`static UIImageView *photoIn(UIView *artwork) {`** (was L187)
> The image view of Spotify's artwork: the one with the photo in it, or, before the photo has been fetched,
> the empty one it will land in, so it can be watched from the first pass. Either way one the size of the
> picture, never a small placeholder glyph beside it.

**`static void applyHero(UIView *container, UIView *artwork, CGFloat bottom) {`** (was L202)
> The picture from the top of the container down to `bottom`, which comes from the container at rest and only
> ever grows, so it does not change size while the page loads or scrolls.

**`static UIView *keepBar(UIView *header) {`** (was L229)
> Spotify's navigation bar, the one part of the header kept: collapsed, it is where the name is. Its gradient
> is a flat dark band over the field, as the album's was (Album/AlbumHeader.x); the soft top edge every
> redesigned page has keeps the name legible instead.

**`UIView *more = SGRFindByIdentifier(header, @"Components.UI.ContextMenuButton*", &kMoreKey);`** (was L289)
> More, in the top trailing corner of the page itself rather than of the container, which scrolls away
> with the photo: pinned there it is the same button in the same place on the album and the playlist,
> and the page keeps it however far down the list one is (issue #57).

**`CGFloat alpha = MAX(0, MIN(1, (header.bounds.size.height - kBar) / kFade));`** (was L295)
> Collapsing, the text would pass over Spotify's bar with the name in it: it goes over the last kFade of
> the collapse, from the header's own height, which this pass runs on every step of. More stays: it is
> outside the header and has nothing to pass over.

**`CGFloat rest = MAX([objc_getAssociatedObject(container, &kContainerHeightKey) doubleValue], container.bounds.size.height);`** (was L301)
> The picture reaches to where the content's top is at rest, plus the name. The container keeps its
> height as the header collapses, and only ever grows as the page loads.

**`UIView *row = shuffle ?: play ?: follow;`** (was L308)
> The buttons arrive after the header has laid out, in a row that keeps its size and so lays nothing out
> again (Native/Artist/Artist.x): the row's own pass is watched, a plain UIStackView.

## `Redesigned/Artist/ArtistSections.x`

**file overview** (was L1)
> Artist redesign: the Music list without the artist's videos, and nothing of it painted over the field.
>
> Tree (trees/clean/artist/05.txt, the Music list top to bottom): Popular, Artist pick, Popular releases and
> its Show all, Featuring, Release Countdown, Music videos, Watch more from…, About, Artist playlists, Fans
> also like, Appears on. Every section is three Element_List cells in a row -- a 16pt spacer, a heading
> (Components.UI.SectionHeadingHome) and what the section holds -- and every kind of content carries an
> identifier of its own, in any language: Components.UI.RetrievalRowElementUI (tracks), PinnedItemUI (the
> pick), HomeCard (a carousel), UpcomingReleaseRow, CreatorBiographyCard (About),
> Components.UI.MusicVideoShelfHeader and WatchFeedCarouselEntryPointElement (videos).
>
> So the rule is by kind, never by the heading's words, which are the app's language: a video shelf reports
> no height, and so do the heading and the spacer in the two cells before it. They were sized before it, so
> the list is asked to lay out again once they are known. Every carousel is the same kind whatever it holds,
> so the carousels all stay; merch has a tab of its own, which ArtistField.x takes away.
>
> A dropped cell is 0 tall but what it holds keeps the height it measured at, hidden and cut off by the
> cell: content squeezed to 0 breaks Spotify's required constraints on every pass (Album/AlbumSections.x).

**`static void dropHeadingOf(UICollectionView *list, NSIndexPath *path) {`** (was L105)
> A video shelf takes its heading and the spacer over it with it. Those were sized before it, so the list lays
> out again, once, to ask them again.

**`SGRClearCellPaint(cell);`** (was L171)
> What the cell paints over the field -- the "You liked" row, every carousel's collection and the
> fade Popular's "See more" draws over its last track (device, trees/continuous/3.txt 2026-09-18).

**`if (SGRRevealWaitsFor(page, SGRRevealList)) {`** (was L174)
> The first of Popular's tracks with its title in is the list the page waits for (Kit/SGRReveal.h); a
> row still loading is RetrievalRowLoadingElementUI, grey bars with empty labels.

## `Redesigned/Home/Home.h`

**file overview** (was L1)
> The Home redesign: Spotify's Home page kept, with its controllers, lists and cards, decluttered to a
> music app on black and restyled from the Kit. No settings of its own.
>
> HomeSections.x   an allow list of the feed's sections: the shortcuts grid, the DJ and the shelves of
> cards stay; video and episode previews, episode cards and any new kind collapse. The
> DJ loses its heading, and the flags the redesign forces on Home
> HomeHeader.x     a large title where the filter pills were, the avatar at the trailing edge, no scrim
> HomeHeadings.x   the shelves' headings in the Music app's size, drawn over Spotify's
> HomeCards.x      the Encore button every card is: shortcut tiles (HomeTiles.m), continuous corners on the
> shelf covers, the DJ card at the card radius without its talking transcript
> HomeTiles.m      a shortcut tile's picture run across the tile, blurred behind its title
> HomePerf.x       FLEX builds: the frames of each scroll of Home and the time the hooks above took
>
> Every hook installs only while Redesigned UI is on (SGRedesignedUI).
> Threading: main thread only.

**`typedef NS_ENUM(NSUInteger, SGRHomeProbe) {`** (was L24)
> FLEX builds only (HomePerf.x): a hook takes the time as it starts and hands it back as it ends; outside
> a FLEX build Begin returns 0 and End does nothing.

## `Redesigned/Home/HomeCards.x`

**file overview** (was L1)
> Home redesign: every card Home keeps is the same Encore button, told apart where it lays out:
> id=Shortcut.Card.Home          a shortcut tile 181x48 r=4 that clips, in a ConfigurableUIEventObservingView
> r=4 (trees/clean/home/01.txt:36-37): the cover radius, continuous, and its
> picture run across it (HomeTiles.m)
> id=Components.UI.HomeCard      a shelf card, its picture Encore.ImageView 149x149 > UIImageView with no radius
> of its own (10.txt:2280-2286): cut at the cover radius, continuous, over the
> 4pt Spotify bakes into the picture (an artist's round one sits inside it)
> in Discovery_MediumDensityCardKit.DJMDCView   the DJ card 370x192 r=8 that clips (01.txt:477-478): the card
> radius, and without the transcript Spotify's DJ talks through
> (Discovery_MediumDensityCardKit.TranscriptView, :500) or the Beta badge (:503)

**`static void calmDJ(UIView *card) {`** (was L36)
> The transcript's own labels are plain UILabels the Kit keeps transparent; the Swift views around them
> take their alpha again on every pass.

## `Redesigned/Home/HomeHeader.x`

**file overview** (was L1)
> Home redesign: the header the way the Music app has it. The filter pills (All, Music, Podcasts) go and
> a large title takes their place at the leading edge; the avatar that opens the side drawer moves to the
> trailing edge; the scrim Spotify lays behind the header goes too, the soft scroll edge (Kit/SGREdgeEffect.x)
> being what keeps the title clear of the page scrolling under it, as on every other redesigned page.
>
> Tree (trees/clean/home/10.txt:3018-3051): FunkisViewController's view holds a 402x112 UIView around
> Reprise_LiquidGlassKit LiquidGlass.GradientView (the scrim) and, at {0, 62}, an
> ElementView<HomeHeaderElement> 402x50 holding HomeHeaderView > UIStackView {0, 8} 402x34 of two arranged
> views: ListeningActivity_ElementsKit.AdaptiveFaceContainer {16, 0} 32x34 (the avatar,
> id=Components.UI.SideDrawerButton) and LiquidGlass.LeadingFadeMaskView {48, 1} 354x32 around
> Home_PillUIKit.PillScrollView.
>
> The avatar moves by the stack's layout direction rather than by a frame of ours. Right to left, the stack
> lays its first view out at the trailing edge itself on every pass, whatever width the face container
> takes when friends listening show beside the avatar; its leading margin, 16pt, is the one Spotify gives
> the header in a right to left language. The pills stay in the stack with no alpha rather than hidden,
> the way the redesign takes any view out of a stack Spotify arranges (Kit/SGRRestyle.h).
>
> The title is Spotify's own name for the tab, read off its tab bar item (id=TabBar.Item.Home, 10.txt:3100),
> so it follows the app's language.

## `Redesigned/Home/HomeHeadings.x`

**file overview** (was L1)
> Home redesign: a shelf's heading at the Music app's size, the title 2 style in bold (22pt at the default
> text size) over Spotify's 17pt. The title is a label of the Kit's own on the same baseline, drawn over
> Spotify's, which goes transparent: Spotify's label measures the heading, so the shelf keeps its layout,
> and the heading button keeps its touch and its accessibility label. The larger title reaches a few
> points up into the gap above the shelf. A small line over the title ("For fans of") and the artist's
> picture beside it stay Spotify's.
>
> The label is held on Spotify's by constraints, not by a frame worked out here: a heading with a picture lays
> its labels out in a stack of its own, which is positioned after this hook has run, so a frame taken here put
> the title over the artist's picture at the leading edge, and a cell reused for a plain heading kept the
> place the picture had left (trees/continuous/1.txt:2533 and :2291, 2026-09-17). Spotify's label can also have
> no text yet when the button lays out, which left three of that tree's headings at Spotify's own size, so a
> heading with nothing to draw on is looked at again on the next turn of the run loop, a few times at most.
>
> Tree (trees/continuous/1.txt:2289-2312, 2026-09-17): Element_List.SupplementaryItemView 370x48 >
> ... > UIView id=Components.UI.SectionHeadingHome > AutoLayoutStackView > UIView > NoIntrinsicContentSizeButton
> (a11y "For fans of  Yzomandias"), under which an ImageViewHolder 48x48 and a stack of SPTEncoreLabels:
> "For fans of " 11pt #B3B3B3, "Yzomandias" 17pt #FFFFFF at {0, 19.3} 91x20.7, and a hidden one. A heading
> of a title alone is 20.7 tall (10.txt:2363). "Show all" is Components.UI.NavigationButtonHome, a sibling
> of the button's stack, 0 wide while it is not offered.

**`static UILabel *titleLabelIn(UIView *button, UILabel *mine) {`** (was L55)
> The label that is the title: the largest text showing under the button, its own label aside. A label the stack
> has not sized yet counts, since the constraints take its place from the layout rather than from its bounds.

**`UIView *showAll = SGRFindByIdentifier(heading, @"Components.UI.NavigationButtonHome", &kShowAllKey);`** (was L99)
> The leading edge and the baseline are Spotify's label's; the title ends before "Show all", or before the
> heading's trailing edge while there is none, and truncates rather than push anything.
> Whether "Show all" is offered is read off the hidden flags, not off its width: it has none to go by until
> the layout resolves, and a title held to the heading's own edge then ran under it.

## `Redesigned/Home/HomePerf.x`

**file overview** (was L1)
> Home redesign, FLEX builds only: what a scroll of Home costs. While Home's list is dragged or
> decelerating, a display link at the screen's own rate times each frame, and the Home hooks add up
> the calls and the time spent in them (SGRHomeProbeBegin/End). When the list settles, one log line
> says the scroll's frames, its hitches (a frame late by half a frame or more), the worst frame and
> each hook's share. A hitch the hooks do not account for is Spotify's main thread; lag with no
> hitches here is the render server (masks, clipping), which a display link does not see.
>
> Main thread stalls over 120 ms are sampled too (Diagnostics/SGHangSampler.h): for 90 s once Home is
> up, and during every scroll.
>
> The hooks install with the rest of the redesign and return at once outside a FLEX build: FLEX is
> injected after the tweak, so whether it is there is only known once the app runs.

**`- (void)describeLongFrame:(CFTimeInterval)gap {`** (was L103)
> What was on screen around a long frame: each section in sight, top down, by the class of its root, and
> whether HomeSections.x collapsed it.

## `Redesigned/Home/HomeSections.x`

**file overview** (was L1)
> Home redesign: of the sections the feed sends, only the music ones stay: the grid of shortcuts, the
> DJ and the shelves of cards (Recents, Jump back in, Your playlists, New releases, the mixes, For fans
> of...). Every other section reports no height, so the list closes up around it: the medium density
> previews (a video or an episode playing muted under Unmute and Watch full episode, or a playlist to
> Preview), a heading over one of those (Fitness for you, Videos from your top artists), the episode
> cards, and any kind the server adds later.
>
> An allow list, as for the cards under the player (Redesigned/Player/PlayerCards.x): the feed is the
> server's, and a new kind should not turn up on a redesigned Home.
>
> Tree (trees/clean/home/10.txt): a section is an Element_List.CollectionViewCell of the page's list whose
> first subview is an ElementContentView over Home_EvoPageImpl.HomeStructure, then an
> ElementView<HomeStructure>, then the section's own root, which names its kind:
> Home_CarouselKit.TouchCancellingCollectionView     a shelf of SimpleCards under a heading (:2274)
> UICollectionView with no identifier                 the shortcuts grid, Home_AnchorsAndShortcutsKit cells (01.txt:33)
> UICollectionView id=ActionCardCarouselElement        episode cards (:696)
> UIStackView                                         a heading over the DJ card's LazyElementView (01.txt:460),
> or over a medium density card (:973, :1443)
> Discovery_MediumDensityCardKit.MediumCardAnimatingLayout   a preview card (:1300, :1746, :1882)
>
> The DJ stays without its heading ("Your own personal DJ" over a card that says DJ): the stack is a plain
> UIStackView, so the heading's LazyElementView is hidden before the cell is measured and the stack closes up.
>
> A dropped section still leaves the list's 24pt gap on either side of it (the shortcuts end at 216, the
> next section starts at 240, 01.txt:30, :325): the spacing is the list layout's, which a cell's height
> does not reach. Taking the sections out of the casita feed itself is what would close it.

**`static void collapse(UICollectionViewCell *cell, CGFloat natural) {`** (was L109)
> A dropped section's cell is 0 tall, but what it holds keeps the height it measured at, hidden and cut off
> by the cell. Spotify's content squeezed to 0 with the cell (trees/continuous/1.txt:375-381, every stack,
> heading and card at {402, 0}) breaks its required constraints on every layout pass of the cell, which
> held the main thread for up to 1.5 s at a time where dropped sections scrolled in (home perf, 2026-09-17).

## `Redesigned/Home/HomeTiles.m`

**file overview** (was L1)
> Home redesign: a shortcut tile the way an Apple list row holds artwork. The cover sits inset from the tile's
> edges with its own corners, the title follows it in, and the tile is a dark surface tinted faintly towards the
> cover's dominant colour (Kit/SGRPalette.h, +tintForImage:), so the grid is not one grey and white text always
> reads. Until the cover has loaded, the tile is the untinted surface.
>
> The surface sits behind Spotify's stack, over the tile's own fill, so the title, the playing indicator and
> the button's touches stay Spotify's. The inset and the title's move are transforms, which Spotify's layout
> never reads, so its constraints are left as they are. The tint is worked out off the main thread once per
> picture and follows the cover as Spotify sets it (SGRObserveImage), since a cover lands after layout.
>
> Tree (trees/home 3 more scrolled.txt:36-50, 2026-09-17): InteractableLayoutBackingButton id=Shortcut.Card.Home
> 181x48 clips > UIView 181x48 bg=#FFFFFF@0.10 (the fill), then Encore.StackView > AutoLayoutStackView >
> UIView 173x48 (the row) > UIView {0, 0} 48x48 bg=#000000@0.90 r=4 (the cover's square) > Encore.ImageView >
> UIImageView 48x48 and the PlaceholderView; then the row's 8pt spacer and the title's stack at x 56.

**`static void inset(UIView *square) {`** (was L75)
> The square scaled about its centre so it clears the tile's edges by kInset, and everything after it in the
> row moved in by what that took off its trailing side.

## `Redesigned/Kit/SGRAccent.h`

**file overview** (was L1)
> The redesign's accent colour in place of Spotify's green (SGRAccent.x), chosen apart from the native
> look's and stored under its own key; unset is #37F200, negative keeps Spotify's own green.

## `Redesigned/Kit/SGRAccent.x`

**file overview** (was L1)
> The redesign's accent colour, chosen apart from the native look's: its copy of Native/Appearance/Accent.x.
> Accent colour: Spotify's green, #1ED760, is one token. Its three components occur once in the
> whole binary, and every green the app draws, from the play button to the "Zobrazit vše" links
> and the progress bar, is that token or a state blended from it. So it is swapped where it is
> born, in the UIColor initialiser, and the blends follow. Lottie animations carry their own green
> and are caught at the layer, below. Image assets with green baked in, the logo above all, are
> out of reach.

**`static const uint32_t kGreens[] = {0x1ED760, 0x1DB954};`** (was L12)
> The greens the app is known to build from literals: the token, and the older brand green the
> upsell backend still names.

**`static BOOL swap(CGFloat *r, CGFloat *g, CGFloat *b) {`** (was L73)
> A darker green than the token comes out as the accent darkened by the same amount, so the two
> keep their relation.

**`static CGColorRef swappedCopy(CGColorRef color) {`** (was L102)
> Lottie draws its animations, the play indicator and the checkmarks among them, from colours
> in the animation file straight onto shape layers, or into colour keyframes, never through
> UIColor. The same swap goes on the CGColor. Layers get set off the main thread too, so the
> copy is made with CoreGraphics alone; NULL when the colour is not one of the greens.

## `Redesigned/Kit/SGRActionRow.h`

**file overview** (was L1)
> The controls a redesigned page puts in the row under its hero, where the Music app has them: the Play
> capsule it draws instead of a disc, and a round button standing in for one of Spotify's own where that
> one cannot be brought into the row.
>
> Neither is a control of its own making. Each takes what it shows from a button of Spotify's -- the glyph
> it draws, the word beside it in the app's own language, whether it reads play or pause -- and a tap on it
> fires that button, so the action, the state and the accessibility stay Spotify's and only the drawing is
> the redesign's. A page that can move Spotify's button into its row moves it and needs neither.
>
> Ownership: whoever adds them; each keeps a weak reference to Spotify's control.
> Threading: main thread only.

**`@interface SGRPlayCapsule : UIControl`** (was L14)
> A capsule the height of SGRActionHeight with a glyph and a word in it, on prominent glass: the one
> control of an action row that leads. `sgr_width` is the width the word it is showing asks for.

**`@property (nonatomic, copy) UIColor *fillColor;`** (was L19)
> A solid capsule of this colour instead of the prominent glass, the Music app's white Play (the playlist).
> nil, the default, is the glass. Set before the capsule is first laid out.

**`- (void)feedFrom:(UIView *)source;`** (was L24)
> Takes the glyph, the word and the language from `source`, and follows the glyph as Spotify swaps it
> (play becoming pause) without the header laying out again. Cheap to call again on every pass.

**`@interface SGRMirrorButton : UIControl`** (was L30)
> A round glass button SGRActionHeight across showing the glyph of one of Spotify's round buttons and
> firing it, for a control the row cannot reach: the album page's shuffle floats over the page rather
> than scrolling with its header, so it is left where it is, concealed, and this stands in for it.

**`@property (nonatomic, copy) UIColor *glyphColor;`** (was L37)
> The colour to draw the mirrored glyph in, whatever colour Spotify drew it. nil, the default, keeps
> Spotify's -- which is what a glyph that says something by its colour needs (shuffle turns the accent
> colour while it is on). Set it for a glyph whose colour is only the weight Spotify gave the control it
> sat in: Encore bakes the colour into the image it draws, so this re-renders the copy as a template.

**`@property (nonatomic, copy) UIColor *onGlyphColor;`** (was L42)
> The colour the glyph takes while Spotify's button is on, and glyphColor while it is off, for a button that
> says it is on with the small dot Encore puts under its glyph (shuffle: trees/continuous/1.txt, a 4pt round
> view, hidden while off). Spotify's own off grey read as a disabled button beside the white download
> (issue #65). A button with no such dot keeps Spotify's colours. nil, the default, reads no dot.

**`@property (nonatomic, copy) BOOL (^readState)(BOOL *on);`** (was L47)
> For a button that shows its state only as a word in the app's language (the artist's Follow): YES with
> whether it is on once the state is known, from wherever the page reads it. The button then draws
> stateOffSymbol, or stateOnSymbol in the accent colour, and nothing while it answers NO. Set before the
> first -feedFrom:; call -feedFrom: again when the state changes.

**`- (void)feedFrom:(UIView *)source;`** (was L54)
> Takes the glyph, its colour and the label from `source`, and follows the glyph as Spotify swaps it
> (shuffle turning on). Cheap to call again on every pass.
>
> Spotify's download button (SGRDownload.h) is drawn by Lottie, with nothing to copy: for it the button
> draws the state Spotify reports instead -- the arrow, a ring filling up, the downloaded glyph -- and reads
> it again while it is on screen, twice a second while a download runs, since nothing Spotify does then
> lays out anything the page hears. So is the add-to button, drawn as a plus or, saved, a checkmark.

**`SGRMirrorButton *SGRPinnedMore(UIView *page, const void *key, UIView *source);`** (was L64)
> The ⋯ every redesigned entity page pins to its top trailing corner, level with the back button: one
> button, one size, one place on the playlist, the album and the artist. It is added to `page` -- the
> page's own root view, outside anything that scrolls -- so it stays where it is however far the page is
> scrolled, which is what Spotify's own does not (the navigation bar's slot is emptied on the way down,
> trees/continuous/1.txt 2026-09-20, issue #57) and what a button in a scrolling header cannot.
>
> `source` is Spotify's own ⋯, wherever the page keeps it; nil hides the button until one is found. Kept
> on `page` under `key` and cheap to call again on every pass.

**`UIView *SGRPinnedMoreRecentPage(void);`** (was L76)
> The page whose pinned ⋯ was tapped within that window, or nil: for a screen that puts rows of its own on
> Spotify's context menu sheet and has to know which page the sheet belongs to.

## `Redesigned/Kit/SGRActionRow.m`

**file overview** (was L1)
> The action row's controls: the Play capsule and the button that stands in for one of Spotify's.
>
> Both are drawn from what Spotify's own button shows, and neither keeps state of its own. The glyph is
> looked for past what is hidden behind it -- a play button's glow ring is a hidden view holding an image
> of its own, and taken for the glyph it put a soft green ring in the capsule (device, 2026-09-17) -- and
> it is watched afterwards, because Spotify swaps play for pause without laying the header out again.

**`static const CGFloat kGlyphSide = 44, kCapsuleLead = 4, kCapsuleTrail = 20;`** (was L16)
> The capsule: the glyph is Spotify's own 48pt canvas with the triangle small in the middle of it, so the
> lead is short and the gap to the word comes out of the canvas itself.

**`static UIImageView *glyphIn(UIView *button, CGFloat side) {`** (was L24)
> The glyph Spotify's button draws: an image view of the button's own size that nothing hidden is in the
> way of. `side` is the size to match, 0 for any image view that is showing.

**`CGSize image = _glyph.image.size;`** (was L92)
> Spotify's glyph comes on a 48pt canvas and is scaled down into the frame; one drawn tight is shown at
> its own size instead of blown up to fill it.

**`CGSize size = source.bounds.size;`** (was L108)
> The disc is as tall as the button, not always as wide: Liked Songs' is 80x48 with the 48pt disc at
> x=16 (trees/continuous/1.txt, 2026-09-18), and matched by width the capsule drew no glyph at all.

**`if (glyph && glyph != _watchedGlyph) {`** (was L132)
> Play becomes pause without the header laying out again. Watched per glyph view rather than once for
> good, so a glyph Spotify hands to another button reports to the button it is in now.

**`static BOOL indicatorOn(UIView *button, BOOL *found) {`** (was L160)
> Whether a button that marks "on" with a small dot under its glyph (Encore's shuffle, a 4pt round view it
> hides while off) is on. `found` says whether the button has such a dot at all.

**`UIImage *_takenGlyph;`** (was L181)
> Spotify's own image, as it was taken: what the copy is compared against, since a copy re-rendered as
> a template is no longer the same object.

**`if (self.window && self.source) [self feedFrom:self.source];`** (was L224)
> Read again on the way in -- the state may have moved on while the page was away -- and not at all
> while out of the window.

**`BOOL running = state == SGRDownloadWaiting || state == SGRDownloadDownloading;`** (was L260)
> Spotify lays nothing out that the page hears as a download moves on, so the state is read again:
> twice a second while one runs, for the ring, and now and then otherwise, for one started or removed
> from elsewhere (the ⋯ sheet). Only while the button is on screen.

**`- (void)feedFrom:(UIView *)source {`** (was L325)
> The glyph is taken as Spotify drew it, colour and all: the shuffle button turns its own glyph the accent
> colour while shuffle is on, and a copy rendered as a template would lose that.

**`BOOL hasDot = NO;`** (was L350)
> A button that says "on" with its dot is drawn in our colours, on and off. One expected to have a dot
> and found without keeps Spotify's colours, which are then all that tells on from off.

**`__weak SGRMirrorButton *weakSelf = self;`** (was L397)
> The word is watched where Spotify writes it, but a button that rebuilds its content on the state it
> just took writes the new word into a label the watch has never seen. So a tap, and only a tap, asks
> the button again a moment later, which also moves the watch onto whatever label it ended up with. The
> same goes for shuffle's dot and a download's state, which change with no image or word to watch.

**`static const CGFloat kCornerSide = 16;`** (was L414)
> A mirror of the back button, which UIKit draws as a 44pt glass circle at the top of the safe area, 16pt
> in from the leading edge (trees/continuous/1.txt:2554: the navigation bar's own glass at {16, 0} 44x44,
> the bar itself at the safe area's top). ⋯ takes the same size and the same insets on the other side, so
> the two read as one row on every page (issue #57).

**`static __weak UIView *sg_morePage;`** (was L420)
> The page whose pinned ⋯ was last tapped, and when: what tells the sheet that opens a moment later which
> page's menu it is. The same trick Shared/Player/SpeedPitchMenu.x plays on the player's more button, but
> from this side of it, since this button is the redesign's own and knows its own page.
>
> Recorded on touch down rather than on touch up: the button's own -sgr_tap is registered first and fires
> Spotify's ⋯ from the same event, so a sheet Spotify puts up in that same turn would ask which page it
> belonged to before a target added after -sgr_tap had answered.

**`button.glyphColor = SGRPrimary();`** (was L451)
> ⋯ sits in an Encore Tertiary button in Spotify's own row, which draws it grey; in the corner of
> the page it is the one control there and reads white, like the back button opposite it.

**`if (button.superview != page) [page addSubview:button];`** (was L460)
> Over the page's list and its header both, and put back on top whenever Spotify adds to the page -- under
> the curtain while the page has one, so it comes in with the rest of the page.

**`UIWindow *window = page.window;`** (was L467)
> Measured in the window and converted back, never from the page's own safe area: a page under a
> navigation bar counts the bar into its inset, so the playlist's read 116 where the window's reads 62
> and the button sat a bar's height below the back button (device, trees/continuous/1.txt 2026-09-20).

## `Redesigned/Kit/SGRAmoled.x`

**file overview** (was L1)
> The redesign's AMOLED background, always on: its copy of Native/Appearance/Amoled.x without the switch.
> AMOLED background: Spotify paints its base surface #121212; with the switch on, that grey and
> the gradients fading into it go pure black. Lighter greys stay (#1F1F1F placeholders, #292929
> cards), so elevated surfaces still read against the black.
>
> Trees: #121212 sits on the Home, Search, Library and settings scroll views, on list rows, the
> message bar and the player's bottom gradient view.

**`%hook _TtC21Settings_PlatformImpl26SettingsListViewController`** (was L54)
> Spotify's settings list paints nothing of its own and shows whatever sits under it, which is not
> the base grey the hooks above turn black. The list is the top surface, so it takes the black.

## `Redesigned/Kit/SGRAppearanceSettings.m`

**`static void chooseAccent(void) {`** (was L6)
> Going back to Spotify's green is offered only once a colour of the mod's is set, so a stray tap
> cannot wipe it.

## `Redesigned/Kit/SGRBridges.h`

**file overview** (was L1)
> What the redesigned screens read from Spotify and ask of it, through one hook each, so no screen
> hooks the player a second time.
>
> Player state is Shared/Player/PlayerState.h's, imported here so a redesigned screen needs one header.
>
> Artwork is keyed on the picture the playing track names, not on the track or on where it was read
> (issue #58). The track's metadata carries its cover's image id (image_xlarge_url and its smaller
> sizes, spotify:image:<16 digits of size><24 digits of the picture>, out/karaoke-diag.log:174); two
> tracks of one album share it. On a change of picture the Kit fetches that picture itself, from
> i.scdn.co where Spotify's images live, and the answer is published whenever it lands, however late,
> unless the track has moved on to another picture meanwhile. Until it lands, and when it cannot
> (offline), the covers on screen stand in: the now playing bar's 40pt cover (trees/clean/artist/01.txt:
> id=SPTNowPlayingBar > Encore.ImageView > UIImageView 40x40), read after the bar's layout and a few
> times after a track change, and the player's own cover, which PlayerField.x publishes. A view read
> can be the last track's picture still -- a cell of the covers list that has not reloaded, a bar whose
> new picture is still loading -- so every picture published is remembered, weakly, with the picture it
> was published as, and a view showing one of them for another picture is not believed.
>
> Threading: everything here is main thread only; the player's reports are moved onto it.

**`void SGRSetNowPlayingArtwork(UIImage *image, NSString *trackURI, SGRArtworkQuality quality);`** (was L33)
> A picture read off a screen for `trackURI`: ignored unless that track is still the one playing, when
> it is a picture already published for another track, when a better one is in for this picture, and
> when it is the same image again.

**`UIImage *SGRNowPlayingArtwork(NSString **trackURI, NSString **identity);`** (was L37)
> The last artwork published; `trackURI` and `identity` (for -[SGRArtworkField setArtwork:identity:
> animated:]: the same identity is the same picture) are filled when asked for. Until the playing
> track's own picture is in, this is the last one.

**`void SGRObservePlayerTransition(id owner, void (^began)(id owner), void (^ended)(id owner));`** (was L46)
> SGPlayerTransitionNotification and SGPlayerTransitionEndedNotification as blocks, for as long as
> `owner` lives. The blocks are handed the owner so they need not capture it.

## `Redesigned/Kit/SGRBridges.x`

**file overview** (was L1)
> The Kit's bridge into Spotify: the now playing artwork. The player's state, its open and close and
> links are Shared's (Shared/Player/PlayerState.h, Shared/Player/PlayerEvents.h,
> Shared/Navigation/Links.h). SGRBridges.h names the hook and why it is the one.

**`static NSMapTable<UIImage *, NSString *> *sg_published;`** (was L21)
> Every picture published, held weakly, with the key it was published as. A view still showing one of
> these while another picture is wanted is showing the last track's.

**`static void followPlayer(void) {`** (was L125)
> Brings the playing track's picture up to date with the player's state, and fetches a picture newly
> wanted. Called on every state report and before any view read is believed, whichever comes first.

**`if (identity) {`** (was L163)
> A fetched picture is known for what it is; one read off a screen is only what it looked like then,
> so each of those is a picture of its own and a field redraws it.

**`@interface SGRBarArtworkWatcher : NSObject <SGPlayerStateObserver>`** (was L201)
> The bar sets its picture when the image has loaded, which lays nothing out, so a track change looks
> again a few times while the picture comes in. One that loads later still is the fetch's to bring.

## `Redesigned/Kit/SGRDownload.h`

**file overview** (was L1)
> What Spotify's download button says -- not downloaded, waiting, downloading and how far, downloaded, failed
> -- and the glyph the redesign draws for it, the Music app's: an arrow, a ring filling up with a stop square
> in it, and a filled arrow in a circle once everything is on the phone (issue #65).
>
> Spotify draws that button with Lottie, so there is no image to copy the way the action row copies the
> other glyphs. What it does have is a state in words: the button's accessibility identifier is
> `DownloadButton.Granular.<None|Waiting|Downloading|Downloaded|Error>` (every one of the five is a string
> in the 9.1.78 binary), and the Encore object that owns the button -- the button's own action target --
> keeps `currentState` and `progress` in stored properties the runtime lists by name (Swift field metadata:
> GranularDownloadButton { currentState: GranularDownloadButtonState, progress: Optional<8 bytes> }, the
> state being none, waiting, downloading, downloadingEndless, downloaded, error in that order).
>
> Threading: main thread only.

**`BOOL SGRReadDownload(UIView *source, SGRDownloadState *state, CGFloat *progress);`** (was L24)
> YES when `source`, or something under it, is Spotify's download button, with what it says: `progress`
> is 0...1 while downloading, -1 when Spotify has none to give (an endless download, or not readable).

**`BOOL SGRReadAddTo(UIView *source, BOOL *added);`** (was L28)
> YES when `source`, or something under it, is Spotify's add-to button (Components.UI.AddToButton, saving an
> album or a playlist), with whether it is saved. Lottie draws that one too, so the state is read off its
> Encore owner's `currentStatus` (AddToButtonState: notAdded, added); NO when that cannot be read.

**`@interface SGRDownloadGlyph : UIView`** (was L33)
> The glyph, 24pt square, drawn in the middle of a round action row button. A change of state is animated
> (symbol replaced in place, or the old shape shrinking away as the new one grows in), so the moment the
> download starts or ends reads as a moment; progress eases along between the reads.

## `Redesigned/Kit/SGRDownload.m`

**`static const uint8_t *propertyBytes(id object, const char *name, size_t length) {`** (was L28)
> `length` bytes of the stored property `name`, NULL when the class has no such property or it would reach
> past the end of the instance.

**`id owner = ownerOf(button, @"GranularDownloadButton");`** (was L57)
> What the button draws from. Its state is a Swift enum without payloads, one byte, its cases numbered
> in the order they are declared; its progress an optional 8 byte number, the value then a byte that is
> 1 when there is none. The identifier says the same state in words, and is what counts when the model
> cannot be read.

**`if (self.window && _showsState && _state == SGRDownloadWaiting) [self sgr_setProgress:-1 animated:NO];`** (was L221)
> Core Animation drops a repeating animation when the layer leaves the window; the turning ring is put
> back on the way in.

**`if (!ring && !wasRing) {`** (was L282)
> One symbol for another (not downloaded to downloaded, say, when it happened while the page was away):
> the symbol replaces itself in place.

**`UIView *outgoing = wasRing ? _ring : _symbol, *incoming = ring ? _ring : _symbol;`** (was L301)
> One shape for the other: the old one shrinks away as the new one grows in with a little bounce. A
> download that ends closes its ring first, so the last moment of it is seen before the arrow lands.

## `Redesigned/Kit/SGREdgeEffect.x`

**file overview** (was L1)
> The redesign's copy of Native/Appearance/EdgeEffect.x.
> Soft top edge: iOS 27 resolves a scroll view's automatic top edge effect to the hard style, the
> flat dark band under the navigation bar (UIKit.ScrollEdgeEffectView in trees/continuous/1.txt).
> Setting the soft style brings back iOS 26's thin fading blur. Set on every layout pass as well as
> on arrival, in case UIKit resolves the style again after the page appears.

## `Redesigned/Kit/SGRField.h`

**file overview** (was L1)
> The artwork field: one continuous colour taken from the artwork's main colour (SGRPalette.h) behind
> a whole redesigned page, with no card and no seam anywhere. The player's field also carries the
> artwork itself at the top, blurred and dimmed and dissolving into the colour (showsBackdrop).
>
> Nothing is blurred live and nothing is masked: the view draws a solid colour layer, a black gradient
> layer (the redesign is AMOLED throughout, fading the colour to black down the page) and at most one
> bitmap layer rendered off the main thread, so it costs a few composited layers while the page moves. A new colour or bitmap crossfades over
> SGRCrossfade; the same image again is a no-op.
>
> Ownership: the screen that installs a field owns it (usually retained by its superview and an
> associated object). The field retains its last image and palette only.
> Threading: main thread only; the palette work it starts runs off it.

**`extern NSNotificationName const SGRFieldColorDidChangeNotification;`** (was L15)
> Posted on the main thread by a field whose colour changed, with the field as the object and the
> new colour under "color".

**`@property (nonatomic) UIEdgeInsets bleed;`** (was L20)
> Where the colour, the fade to black and the backdrop reach past the bounds (overscroll, a plane
> that does not clip): positive values draw outside. The field never clips.

**`@property (nonatomic) BOOL flows;`** (was L24)
> The player's moving field instead of the still backdrop (SGRFlow.h): the artwork's colours drifting
> over the whole of the bounds, with no fade to black. It moves only while the field is in a window,
> the app is in front, the player is not opening or closing, Reduce Motion and Low Power Mode are off
> and nothing holds it (motionHeld); otherwise it stays still where it was.

**`- (void)setProvisionalColor:(UIColor *)color;`** (was L36)
> A colour Spotify already has for the page (the player's background colour), made fit to be a field
> and shown until the first artwork has been read; ignored after that.

**`- (void)setPreferredColor:(UIColor *)color;`** (was L39)
> A colour the page already picked for itself, made fit to be a field; it wins over the one read from the
> artwork. nil keeps what is set.

**`- (void)setArtwork:(UIImage *)image identity:(NSString *)identity animated:(BOOL)animated;`** (was L42)
> Reads the artwork off the main thread and crossfades the result in (without animation when
> `animated` is NO or the field is not in a window). The same image, or the same non-nil identity,
> as the last call is a no-op, and a result that lands after a newer call is dropped. nil keeps
> what the field shows.

**`- (void)whenColored:(void (^)(void))colored;`** (was L47)
> `colored` once, as soon as the field shows a colour of the page's own -- read from the artwork, or the
> page's preferred one -- rather than the neutral it starts with; at once if it already does. For a page
> that waits to be shown until it has its colour (SGRReveal.h).

## `Redesigned/Kit/SGRField.m`

**`static const CGFloat kBlackFrom = 0.55, kBlackTo = 1;`** (was L12)
> Where the colour starts fading to black and where it is black, as shares of the window's height:
> the redesign is AMOLED throughout (SGRAmoled.x).

**`static NSDictionary *noActions(void) {`** (was L21)
> The field paints on sublayers of its own rather than on the view's layer: a repaint hook only clears
> the paint of a view's own layer, so the neutral colour cannot be taken for Spotify's base surface.

## `Redesigned/Kit/SGRFlow.h`

**file overview** (was L1)
> A moving field of the artwork's colours, the Music app's animated background behind its player
> (issue #59): five soft discs of colour, one for each quarter of the artwork and one for the whole of
> it, each drifting on a slow loop of its own and breathing in size, over the artwork's main colour and
> under a shade that deepens towards the bottom, where the controls are.
>
> All of it is Core Animation: radial gradient layers moved by repeating animations that the render
> server plays, so the app itself does no work per frame -- no display link, no timer, nothing redrawn
> -- and a paused layer tree costs nothing at all. The animations ask for 30 frames a second (the discs
> are soft and slow; more would only spend the GPU) and allow up to 60, so they can fall in with other
> sources rather than holding them down.
>
> Stopping holds every disc where it is and starting again carries on from there, so the owner can stop
> it as often as it likes (the player's transition, the app leaving the screen) without a jump.
>
> Threading: main thread only.

**`- (void)setColors:(NSArray<UIColor *> *)colors animated:(BOOL)animated;`** (was L19)
> Five colours, as -[SGRPalette flowColors] gives them: top left, top right, bottom left, bottom right,
> the whole artwork's. Animated, they blend into the new ones where the discs are.

## `Redesigned/Kit/SGRFlow.m`

**`typedef struct {`** (was L5)
> Each disc: where it rests, as shares of the layer (top left, top right, bottom left, bottom right,
> middle), its diameter as a share of the layer's longer side, the loop it drifts on (radii as shares of
> width and height), how long one loop takes and which way it runs, and how long a breath takes.
> The periods share no factor, so the picture they make together does not come round again for hours.

## `Redesigned/Kit/SGRGlass.h`

**file overview** (was L1)
> Glass for the redesign's control layer, and only for it: never behind rows, cards or text. Built on
> Core/SGGlass.m (the effect made through +effectWithStyle:). Under Reduce Transparency a shape is a
> solid SGRSolidGlassFill, on any OS; before iOS 26 without it, a dark thin material blur. Nothing
> touches a glass class on an OS without them. A shape is dark whatever the system appearance: glass
> takes the one it inherits, which outside the navigation stacks Spotify makes dark (the player) is the
> system's, light on a phone in light mode.
>
> Ownership: a shape belongs to the control it is made in (associated with it under the caller's key).
> Threading: main thread only.

**`UIView *SGRGlassInside(UIView *control, const void *key, CGFloat side);`** (was L12)
> A glass circle inside someone else's round control, `side` across, behind everything the control
> draws (first in its subviews, re-asserted on every call, since glass takes what is above it in the
> tree into its backdrop however the depths are set) and kept at its middle by the autoresizing mask.
> Being the control's own
> subview it goes wherever the control goes: a frame worked out from outside goes stale when Spotify
> lays a row out after the unit that holds it (the player's header circles sat 24pt off until a tap
> laid the unit out again, trees/continuous/1.txt 2026-09-17). Takes no touches; made once per control
> under `key`, and made again when Reduce Transparency changes the kind of shape.

**`UIView *SGRGlassCapsuleInside(UIView *control, const void *key, CGSize size, BOOL prominent);`** (was L22)
> The same, in a capsule `size` across rather than a circle: for the one control of an action row that
> leads (the playlist header's Play). `prominent` lays a white film inside the shape, so that control
> reads a step brighter than the circles beside it without leaving the same material.

## `Redesigned/Kit/SGRGlass.m`

**`if (!CGRectEqualToRect(film.frame, content.bounds)) {`** (was L61)
> The effect's content view does not clip, so the film carries the shape's corners itself; square ones
> drew a lighter rectangle around the playlist's Play capsule (harness, 2026-09-17).

**`if (control.subviews.firstObject != shape) [control insertSubview:shape atIndex:0];`** (was L87)
> First among the control's subviews, so the glyph the control draws is genuinely after the shape in the
> tree. The shape used to be added last and pushed back with zPosition -1 instead, which sorts the
> compositing but not what glass takes for its backdrop: on the phone the glyph above it was captured
> into it, so the button showed a soft ghost of its icon through the glass and no icon over it
> (issue #39, iOS 26.1). The simulator's glass does not refract and shows neither order failing, so this
> one is ordered the plain way rather than by depth. Re-asserted on every pass the caller makes, since a
> control that rebuilds its content puts that in at index 0 too and would end up under the shape.

## `Redesigned/Kit/SGRGlassDesign.x`

**file overview** (was L1)
> Spotify's own newer design, which it ships behind several flags switched off: the glass navigation
> bar, the new player slider, the sheet style player, the queue and Connect sheets, the redesigned
> player header, the sleep timer's options sheet. The redesign is built on all of it, so while
> Redesigned UI is on each is forced and its row elsewhere shows it locked.

## `Redesigned/Kit/SGRGlyph.h`

**file overview** (was L1)
> Bare glyphs: an SF Symbol drawn over or instead of one of Spotify's own glyphs (the player's previous,
> play and next), and a glyph button of the Kit's own where Spotify has no control (the lyrics glyph in
> the player's footer). No glass: these sit in rows of controls, where a pane each would turn the row
> into glass sampling glass.
>
> Ownership: whoever adds them. Threading: main thread only.

**`@interface SGRGlyphView : UIImageView`** (was L9)
> Takes no touches and is hidden from accessibility, so the Spotify control under it keeps both; put
> inside that control, it follows the control's own alpha when disabled or highlighted.

**`- (void)setSymbol:(NSString *)symbol animated:(BOOL)animated;`** (was L14)
> A swap replaces the glyph with the symbol transition on iOS 17 (none under Reduce Motion); the same
> symbol again is a no-op.

**`@interface SGRGlyphButton : UIControl`** (was L19)
> A glyph that is a button: at least 44pt to touch whatever the glyph's size, dims and springs back
> when pressed, 0.35 alpha and "dimmed" to VoiceOver when disabled, and shows the large content
> viewer with its title when held at accessibility text sizes.

## `Redesigned/Kit/SGRGlyph.m`

**`[button addTarget:button action:@selector(tapped) forControlEvents:UIControlEventTouchUpInside];`** (was L60)
> Touch up inside, not the primary action: UIKit sends the primary action from UIButton and the
> controls built on it, never from a UIControl of one's own, so a handler registered for it is never
> called and the button is dead to every tap (device, 2026-09-17, and the player harness).

## `Redesigned/Kit/SGRHeaderInfo.h`

**file overview** (was L1)
> The text and the controls of a redesigned page's header, under its full bleed picture, the way the Music
> app (iOS 26.4) sets a playlist or an album: the title, the creator and the length centred, one row of
> shuffle, a white Play capsule and one more round button, and the description under the row.
>
> A page conceals what Spotify draws in its header and puts this in its place, so nothing of Spotify's lays
> it out. It keeps no state of its own: the page hands it the text it read (from Spotify's model or from
> Spotify's concealed labels) and Spotify's own controls to draw from and fire, on every pass, and it lays
> itself out again only when something it shows changed.
>
> Its content sits on its bottom edge with SGRHeaderInfoBottom under it, whatever height the page gives it,
> so the buttons stay just above the first track; what does not fit rises over the picture. The page's
> picture reaches SGRHeaderInfoTitleRise below the content's top, so the title and the creator sit on the
> bottom of its dissolve.
>
> Ownership: the page that adds it; it keeps only weak references to Spotify's controls.
> Threading: main thread only.

**`- (void)showCreatorLink:(UIView *)control;`** (was L25)
> Spotify's own control behind the creator line -- the album's artist row, the playlist's collaborators
> button -- so a tap on the line opens whoever made it, and several of them open Spotify's own picker.
> The line keeps its colour: it is the page's one piece of secondary text, not a link to be tinted. nil
> leaves it as text.

**`@property (nonatomic, copy) BOOL (^trailingState)(BOOL *on);`** (was L30)
> For a trailing control that shows its state only as a word (the artist's Follow): SGRMirrorButton's
> readState and its two symbols. Set before the first -showShuffle:...; -trailingStateChanged redraws it.

**`- (void)showShuffle:(UIView *)shuffle play:(UIView *)play trailing:(UIView *)trailing`** (was L36)
> Spotify's controls, each drawn from and fired; nil hides that button. Play stays in the middle of the
> page whether the other two are there or not. `trailingFallback` is drawn when Spotify's trailing control
> has no image to copy. `playColor` is the colour of the capsule's glyph and word.

## `Redesigned/Kit/SGRHeaderInfo.m`

**file overview** (was L1)
> The header's text and controls, the redesign's own. Laid out top down from where the content has to start
> for its bottom to sit SGRHeaderInfoBottom above the view's.

**`_shuffle.glyphColor = SGRPrimary();`** (was L55)
> White like the buttons beside it while off -- Spotify's off grey read as a disabled button next to the
> white download (issue #65) -- and the accent while on, so its state still shows.

**`- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {`** (was L69)
> Touches only for the buttons and, where there is one, the creator line: the rest of the text lets a
> pull or a tap through to the page under it.

**`if (hit == self || hit == _creator) return [self sgr_creatorHit:point];`** (was L73)
> The creator label is the width of the view, so the label itself answers a touch well away from the
> name; both it and the view answer only where the name is drawn.

**`- (void)showCreatorLink:(UIView *)control {`** (was L89)
> The creator line, tappable. The label is as wide as the view and centred, so the target is narrowed to
> the text itself -- a tap either side of a short name belongs to the page under it, which a pull down
> starts on. Spotify's own control stays concealed where it is and only fires.

**`if (!hide && self.window) {`** (was L140)
> One of Spotify's buttons that turns up after the page is on screen (save, on a playlist opened for
> the first time) fades in beside the others rather than popping in.

**`CGFloat side = SGRActionHeight;`** (was L185)
> Play on the middle of the page, the other two hung off its sides, so it holds its place whether both
> are there or not.

## `Redesigned/Kit/SGRKit.h`

**file overview** (was L1)
> The Redesign Kit: what every part of the redesign (Redesigned/<Part>/) builds on, so the screens share
> one look and nothing is hand-rolled per screen. A screen imports this and Core/SGCore.h.
>
> SGRedesign.h   Redesigned UI, the one switch, and the flags the redesigned screens force
> SGRTokens.h    colours, type, spacing, radii, motion, the accessibility settings
> SGRPalette.h   the artwork's edge colour, the field colour and the pre-blurred bitmaps
> SGRField.h     the artwork field behind a page
> SGRFlow.h      the player's moving field of the artwork's colours
> SGRGlass.h     glass inside Spotify's round controls
> SGRGlyph.h     bare glyph overlays and glyph buttons
> SGRActionRow.h the Play capsule and the stand-in button of a page's action row
> SGRDownload.h  Spotify's download state, read, and the glyph drawn for it
> SGRHeaderInfo.h a page header's title, creator, length, row and description, the Music app's
> SGRReveal.h    the curtain a page is held behind until all of it has arrived, then shown at once
> SGRRestyle.h   keeping Spotify's views restyled: suppress, digits, lookups, shadows, firing
> controls, taking a list cell's paint off the field
> SGRBridges.h   player state, now playing artwork, the player's open and close
> SGRRepaint.h   the areas the redesign keeps transparent when Spotify repaints them
> SGRAccent.h    the redesign's accent colour; its AMOLED black is SGRAmoled.x, always on
>
> Every hook file of the redesign starts its %ctor with `if (!SGRedesignedUI()) return;` and every one
> of Native/ with `if (!SGNativeUI()) return;` (Core/SGUIMode.h), so the two looks never run together.

## `Redesigned/Kit/SGRPalette.h`

**file overview** (was L1)
> What a redesigned page takes from its artwork, worked out off the main thread in one pass: the
> colour along the artwork's bottom edge, the field colour made from its main colour, and the blurred
> bitmaps the field (SGRField.h) draws instead of a live blur.
>
> The field colour keeps its hue, with its OKLab lightness held to 0.34 (0.30 with Increase Contrast)
> and its chroma lifted by 1.3 up to 0.14. On anything that dark white text is past 11:1 and SGRSecondary
> (white 65%) past 4.5:1, WCAG AA, whatever the hue.
>
> Threading: +paletteForImage: may be called from the main thread only and calls back on it. The work
> runs on one serial background queue; UIImage and CoreImage are read there, UIKit views are not.

**`CGSize backdropSize;`** (was L14)
> The area a backdrop bitmap covers, in points; CGSizeZero when none is wanted. The bitmap is the
> artwork filling that area, blurred, dimmed from 0.25 black at the top to 0.45 (0.55 with
> AMOLED) at 55% of the height, and transparent from 55% down to the bottom, so the field colour
> under it shows through with no edge.

**`BOOL dissolve;`** (was L19)
> A blurred copy at the artwork's own aspect, transparent down to 55% of its height and opaque
> from 85%, to lay over the sharp picture with the same aspect fill.

**`@property (nonatomic, readonly) NSArray<UIColor *> *flowColors;`** (was L32)
> nil unless asked for: top left, top right, bottom left, bottom right, then the whole artwork's, each
> the dominant colour there, its saturation lifted a little and its luminance held between
> kFlowLuminanceMin and kFlowLuminanceMax, so white text keeps better than 5.5:1 on any of them.

**`+ (void)tintForImage:(UIImage *)image surface:(UIColor *)surface completion:(void (^)(UIColor *tint))completion;`** (was L39)
> `surface` tinted a little towards the artwork's dominant colour (brought down to a luminance of 0.05, then
> 35% of it mixed in), so a tile or row on the surface quietly takes its cover's colour while white text on
> it keeps its contrast. Never dimmer than `surface`: a mix that came out darker is lifted back to its
> luminance keeping its hue, so a near-black cover cannot cost the tile the step of elevation it stands on,
> nor sink it into the grey band SGRAmoled.x turns pure black. nil to the completion when the image has no
> bitmap to read.

**`UIColor *SGRFieldColorFor(UIColor *color);`** (was L48)
> Any colour made fit to be a field, the same way the edge colour is: for a colour Spotify hands over
> before the artwork is read. Main thread.

## `Redesigned/Kit/SGRPalette.m`

**`static const CGFloat kTintLuminance = 0.05, kTintShare = 0.35;`** (was L15)
> A tint: the artwork's dominant colour brought down to this luminance, then this share of it mixed into
> the surface it tints.

**`static const CGFloat kFlowLuminanceMin = 0.03, kFlowLuminanceMax = 0.13;`** (was L18)
> A moving field's colours: luminance held between these (the ceiling 0.07 with Increase Contrast, as a
> field's), saturation lifted by this much up to a cap, and a near-black one lifted by at most this factor.

**`static UIColor *fieldColorFor(UIColor *color, CGFloat ceiling) {`** (was L101)
> The colour's own hue, dark and a little more colourful, as the Music app draws a page: capping saturation
> in HSV instead turned every warm hue brown. Past the chroma sRGB holds at that lightness, chroma gives way.

**`static UIColor *edgeColorOf(CGImageRef image) {`** (was L129)
> The artwork squeezed into a small square, whatever its aspect, and the bottom rows of that averaged
> by coverage. A bitmap context keeps its rows top to bottom, so the last rows are the bottom edge.

**`static CGImageRef newBlurred(CGImageRef image, size_t width, size_t height, CGFloat sigma) {`** (was L152)
> The artwork drawn to fill the size, then blurred with its edges clamped so the border does not
> darken. Returned retained.

**`static void drawRamp(CGContextRef context, size_t height, CGFloat y0, CGFloat a0, CGFloat y1, CGFloat a1, CGBlendMode mode) {`** (was L167)
> A black gradient from `a0` at `y0` to `a1` at `y1` (shares of the height, top down), extended
> past both ends; with kCGBlendModeDestinationIn it becomes an alpha ramp instead of a dim.

**`static BOOL dominantIn(const uint8_t *px, size_t x0, size_t y0, size_t x1, size_t y1, CGFloat out[3]) {`** (was L198)
> The artwork's dominant colour in linear light: its pixels binned 3 bits a channel, each bin scored by its
> count weighted towards colourful pixels, so a busy cover gives its main colour instead of the grey an
> average makes. Near-black and near-white count for little unless they are nearly all there is.
> The same over the rows y0..y1 and columns x0..x1 of a kSample square bitmap (rows top down).

**`static UIColor *flowColorFor(const CGFloat linear[3], CGFloat ceiling) {`** (was L239)
> A dominant colour in linear light made fit for a moving field: a little more colourful, and within
> the luminance band that keeps white text readable on it.

**`static NSArray<UIColor *> *flowColorsOf(CGImageRef image, CGFloat ceiling) {`** (was L253)
> The artwork's main colour in each quarter, then over the whole of it: the field keeps the artwork's
> colours roughly where the artwork has them.

**`CGFloat want = 0.2126 * toLinear(r) + 0.7152 * toLinear(g) + 0.0722 * toLinear(b);`** (was L286)
> The colour mixed in is held under a luminance of 0.05 but has no floor, so a near-black cover mixes the
> surface *down*: the tile ends up darker than the untinted surface it was meant to be a step above, and a
> neutral one lands in the 1-10% grey band SGRAmoled.x turns pure black, which takes the whole card with
> it -- a black square lost on a black page (The Weeknd's Trilogy, Bieber's SWAG; issue #36). So a mix
> dimmer than the surface is lifted back to the surface's luminance, in linear light and by one factor
> across the channels, which leaves its hue where the mix put it. Lifting cannot clip: the target
> luminance is the surface's ~0.014, and the most one channel can carry of it is 0.014 / 0.0722.

**`CGFloat main[3];`** (was L318)
> The artwork's main colour, not its edge's: a scanned sleeve's edge is the scanner's grey, a
> portrait's is skin.

## `Redesigned/Kit/SGRRepaint.h`

**file overview** (was L1)
> The areas the redesign stripped and SGRRepaint.x keeps transparent when Spotify repaints them, each
> set by the part of the redesign that owns it.

**`extern __weak UIView *sgr_playlistRoot;`** (was L8)
> Redesigned/Playlist/PlaylistField.x, the playlist page. Only the base surface Spotify paints the page,
> its list and its rows with goes clear here: the artwork field is underneath, and the greys of a
> placeholder or a badge are what still has to read against it.

## `Redesigned/Kit/SGRRepaint.x`

**file overview** (was L1)
> Keeps the areas the redesign stripped transparent when Spotify repaints them, and learns which view
> is the now playing bar's card from the album-colour paint.

## `Redesigned/Kit/SGRRestyle.h`

**file overview** (was L1)
> Keeping Spotify's views the way a redesigned screen set them: Spotify re-applies its own look on
> reuse, on state changes and on every layout pass, so each helper here either survives that or is
> cheap enough to run again on every pass. Nothing here uses `hidden` on a view Spotify arranges in a
> stack: OverflowStackView and some Encore stacks trap in updateConstraints when an arranged view
> hides, so a view goes away by alpha, touches and accessibility instead.
>
> Ownership: what a helper creates belongs to the view it was made for (associated objects), and a
> helper keeps only weak references to Spotify's views.
> Threading: main thread only.

**`void SGRSuppress(UIView *view);`** (was L14)
> Alpha 0, no touches, hidden from accessibility, and kept so: the instance becomes a runtime subclass
> of its own class (the way KVO does it, `class` still answers the original) whose setAlpha: and
> setUserInteractionEnabled: hold those values. For plain UIKit views (a UIImageView, a UILabel); a
> Swift class, or an instance already observed with KVO, gets the values once instead, re-applied on
> the next call, and a log line says so once.

**`void SGRMonospacedDigits(UILabel *label);`** (was L21)
> Digits of one width in the label, kept through Spotify's own setText:, setAttributedText: and
> setFont: by a runtime subclass of the instance, like SGRSuppress. Idempotent.

**`BOOL SGRObserveImage(UIImageView *view, void (^changed)(UIImageView *view));`** (was L25)
> `changed` after every setImage: on the image view, Spotify's included, for as long as the view lives: by a
> runtime subclass of the instance like SGRSuppress, or, for one of Spotify's own classes (Encore's image
> views, which no instance of can be subclassed), by an override on that class, which only ever reports the
> instances that asked. A second call replaces the block. NO when neither took, which a log line says once:
> the caller then only sees what its own passes read.
>
> This is how a picture that lands after a screen has been laid out reaches it: setting an image lays no
> ancestor out, so nothing else tells the screen it is there.

**`BOOL SGRObserveLayout(UIView *view, void (^laidOut)(UIView *view));`** (was L35)
> `laidOut` after every layoutSubviews of the view, Spotify's included, for as long as the view lives, by
> a runtime subclass of the instance like SGRSuppress. A second call replaces the block, and a pass started
> from inside the block is not reported again. NO when the view cannot be subclassed (one of Spotify's Swift
> classes, a KVO-observed instance): the caller then has only the passes it hooks itself to work from.
>
> For a screen that arranges Spotify's controls its own way: a parent lays its children out after the
> hook that placed them has returned, so frames set from an ancestor's pass are the ones overwritten.

**`UIView *SGRFindByIdentifier(UIView *root, NSString *identifier, const void *cacheKey);`** (was L44)
> The first view under `root` (itself included) with the accessibility identifier, depth first. The
> answer is kept weakly on `root` under `cacheKey` and searched for again only when it is gone, has
> left `root` or changed its identifier. nil when there is none; a miss is not cached.

**`@interface SGRShadowPlate : UIView`** (was L49)
> A view that draws only a shadow, for a view whose own layer clips (rounded artwork): made once per
> host under `key`, inserted at the bottom of `host`. The caller gives it its frame and transform; its
> shadowPath follows its bounds and cornerRadius.

**`void SGRClearCellPaint(UIView *cell);`** (was L59)
> The base surface a list cell paints over a page's field, cleared: the #121212 the redesign's AMOLED
> black has already turned black, on the cell and on everything under it nearly as wide as the cell, and
> the full-width fade a "see more" draws over its last row, which the black makes a dark band. The Kit's
> repaint hook misses all of it -- it only hears about a colour when Spotify sets it, and a cell is painted
> before it is inside the page and brings its old paint with it when it is reused -- so this runs from the
> cell's own layout pass, and is cheap enough to.
>
> Only what is nearly as wide as the cell: a badge's black disc, a card's grey and an image's placeholder
> are their own. A cell nested inside the cell and narrower than that (a card in a carousel) is not walked
> into: its own row decides for it.

**`void SGRActivate(UIView *source);`** (was L71)
> Fires one of Spotify's own buttons the way a tap on it would: the first control under `source`, through
> SGRFire, and through -accessibilityActivate when that control answers its touches some other way. For a
> control the redesign conceals and draws itself (the action row's buttons, a header's creator line).

**`BOOL SGRFire(UIControl *control);`** (was L76)
> Fires a control's action the way a tap would: the actions registered for primary action triggered,
> else those for touch up inside. NO when the control has neither (an Encore control that reads its
> touches through a gesture recognizer); what was found is logged once per class.

## `Redesigned/Kit/SGRRestyle.m`

**`static BOOL subclassable(Class cls) {`** (was L18)
> A Swift class can lose its metadata when the runtime makes a subclass of it, and an instance KVO
> already swapped the class of would be swapped back when its last observer goes; neither is subclassed.

**`static Class instanceSubclass(Class original, const char *prefix, void (^install)(Class subclass, Class original)) {`** (was L25)
> The class `prefix` + the instance's class, made once, answering `class` with the original so
> isKindOfClass:, NSStringFromClass and the tree dumps see what Spotify made.

**`static BOOL overrideOnClass(Class cls, SEL selector, id (^make)(IMP replaced)) {`** (was L57)
> What an instance of one of Spotify's own classes cannot have -- a subclass of its own -- the class every
> instance of it shares can: the override goes on the class, the way each of the tweak's %hooks does. The
> class is taken off the instance rather than named, since Encore's names carry a build hash that moves with
> every Spotify release, and it is given the override once; an instance that never asked to be watched pays
> one associated-object lookup for it.
>
> `make` is handed the implementation the override stands in front of and answers the block that replaces
> it; that block must call the one it was given first. The implementation replaced is the class's own where
> it has one -- so nothing above it in the hierarchy, UIKit's own classes included, is touched -- and the
> inherited one where it does not.

**`if (strncmp(class_getName(cls), "NSKVONotifying_", 15) == 0) return NO;`** (was L69)
> Never the class KVO made for one instance: it is swapped away again when the last observer goes, and
> the override with it. Everything else here is a class Spotify itself wrote.

**`if (objc_getAssociatedObject(cls, (void *)selector)) return YES;`** (was L72)
> Done already? A class is an object too, and a selector is a pointer unique to its name, so the class
> carries its own mark per selector -- a plain lookup, since callers ask again on every pass they make.

**`static BOOL sg_keepingMonospaced = NO;`** (was L163)
> Spotify's setters run first; what they left is then given the feature through the original class's
> own setters. UILabel may set one property through another, so a pass started inside a pass is
> skipped rather than trusted to settle.

**`BOOL onClass = !kept && overrideOnClass(object_getClass(view), @selector(setImage:), ^id(IMP replaced) {`** (was L208)
> Encore's image views, which is what every picture Spotify loads arrives in, are Swift classes: no
> instance of one can be given a subclass of its own, so the class itself carries the override.

**`static BOOL sg_reportingLayout = NO;`** (was L220)
> A pass the block itself sets off (a frame it moves) reaches layoutSubviews again before the block has
> returned; one level is enough to settle, and re-entering would not end.

**`static const CGFloat kPaintedShare = 0.75;`** (was L334)
> Nearly as wide as the cell. The bands are the width of the page -- a row's surface, a carousel's
> collection, a "see more" fade (artist, trees/continuous/3.txt 2026-09-18; episode page and the
> playlist's Recommended songs, trees/continuous/1.txt and 2.txt 2026-09-20) -- while a badge's black
> disc is 26pt and an avatar's ring the same.

**`static void clearPaint(UIView *view, UIView *cell, CGFloat wide) {`** (was L340)
> The layer's colour, not the view's. -[UIView backgroundColor] answers only what was set through the
> view; a view painted straight on its layer reads back nil there, and the first pass of this left the
> playlist's Refresh band black while everything beside it cleared (device, trees/continuous/1.txt
> 2026-09-20). The layer is where the paint really is, and where the Kit's repaint hook watches for it.
>
> A cell nested inside the cell is walked into only while it is as wide as the band being looked for:
> a card in a carousel is its own and narrower, while the element framework wraps a cell's content in
> views of its own that are the full width, and stopping at one of those is stopping before the paint.

**`CGColorRef color = view.layer.backgroundColor;`** (was L352)
> Read off the layer, written through the view, so the two are left saying the same thing: the
> clear colour lands on both, and reads back with an alpha the next pass does not take for paint.

**`void SGRActivate(UIView *source) {`** (was L366)
> The way a tap on Spotify's own button would fire it: the first control under it, through the actions
> it registered, and through accessibility for an Encore control that reads its touches from a gesture
> recognizer instead -- which is every one of Spotify's own Swift controls.

## `Redesigned/Kit/SGRReveal.h`

**file overview** (was L1)
> A redesigned page coming in whole. Spotify fills a playlist, an album or an artist in pieces -- the cover
> straight away from the card that was tapped, the controls when its buttons arrive, the tracks once their
> rows have data -- and the redesign drew each piece as it came, so the page arrived in three steps.
>
> So a curtain of the page's black goes up over everything on the page on its first pass -- the field, the
> picture, the header's text and row, Spotify's list, the pinned ⋯ -- and once the page has all of it the
> page fades in from behind it: the field brightens out of the black into the page's colour, and the picture,
> the header and the list fade in over it where they are. The system's
> navigation bar is not in the page, so the back button is there throughout. What arrives after that comes
> in the way it always did.
>
> A page says what it waits for as parts, and the hook that sees a part arrive marks it. A page that has not
> got every part within SGRRevealCap of the curtain going up is shown as it is. A curtain nothing claims with
> its parts within a moment is lifted then: the album's template also builds a podcast's episode page, and an
> artist without a photo has a header the redesign does not lay out, and neither ever gets its parts.
>
> Ownership: the curtain and what the page is waiting for belong to the page (an associated object).
> Threading: main thread only.

**`void SGRRevealHold(UIView *page, SGRRevealPart parts);`** (was L32)
> Puts the curtain up over `page` on the first call, and makes it wait for `parts` as well as what it waits for
> already; 0 puts it up unclaimed. Every call keeps the curtain the page's front view, so it is cheap to call
> from each of the page's passes. Does nothing once the curtain has lifted.

**`void SGRRevealMark(UIView *page, SGRRevealPart part);`** (was L36)
> `part` has arrived on `page`, remembered even before the curtain goes up. The last part the curtain waits for
> lifts it.

**`BOOL SGRRevealWaitsFor(UIView *page, SGRRevealPart part);`** (was L39)
> NO once `page` has shown itself or `part` has arrived: a hook that looks for a part on every pass asks this
> first, and stops looking.

**`void SGRRevealBringToFront(UIView *page, UIView *view);`** (was L42)
> `view` in front of everything on `page` but the curtain, for a view of the redesign's own that keeps itself
> on top of the page (the pinned ⋯).

## `Redesigned/Kit/SGRReveal.m`

**file overview** (was L1)
> The curtain a redesigned page comes in behind. Laid over the page as its front subview, and drawn over
> whatever Spotify adds to the page afterwards by its zPosition, so no pass of Spotify's can put anything in
> front of it before the page's next pass brings it forward again.
>
> Lifting it fades the page in rather than fading a black sheet off it: the curtain goes at once, and in the
> same frame the page's own views start from nothing -- the field brightening out of the black into the
> page's colour, and over it the picture, the header and the list fading in where they are. Nothing moves:
> a rise into place read as the page scrolling on its own. The fades are additive and on the presentation
> layers only, so nothing Spotify sets on those views is fought over or changed, and a view Spotify fades
> meanwhile still ends where Spotify put it.

**`static void fadeIn(CALayer *layer, NSTimeInterval duration, NSTimeInterval delay) {`** (was L89)
> From nothing to what the layer's model says, added on top of it. An ease out: the page comes up fast and
> settles, rather than creeping in.

**`static void fadeInPage(UIView *page, UIView *curtain) {`** (was L103)
> Every view of the page but the curtain, from nothing, in the frame the curtain goes: the first frame drawn
> without it already has them all at their start.

## `Redesigned/Kit/SGRTokens.h`

**file overview** (was L1)
> The redesign's design tokens: every redesigned screen takes its colours, type, spacing, radii and
> motion from here, so the screens read as one app and nothing is tuned per screen by hand.
>
> Colours are white over the artwork field (SGRField.h), whose colour is kept dark enough that
> SGRPrimary and SGRSecondary both pass WCAG AA on it. Type is the system font (SF Pro) sized by the
> text style and capped, since Spotify's pages lay out for a fixed header height. Motion is springs,
> critically damped for layout and a little bounce for press feedback; under Reduce Motion both
> become instant, while crossfades stay, a fade not being motion.
>
> Threading: the constants and the colours are safe anywhere; fonts, SGRAnimate and the
> accessibility reads are main thread only.

**`UIColor *SGRHairline(void);`** (was L35)
> The line between two rows of a list, drawn a pixel thick from the text's leading edge: white 12%, 20% with
> Increase Contrast. Never a border around anything -- the redesign's surfaces are told apart by their fill.

**`UIFont *SGRFont(UIFontTextStyle style, UIFontWeight weight, UIContentSizeCategory largest);`** (was L39)
> The system font at the size `style` has for the current content size category, but never larger
> than it has at `largest`, in `weight`. Callers re-ask on traitCollectionDidChange:.

**`void SGRAnimate(SGRMotion motion, void (^animations)(void), void (^completion)(BOOL finished));`** (was L54)
> Runs `animations` with the motion's timing, or at once under Reduce Motion (except a fade), and
> always calls `completion`. Only transform, alpha and colour belong in it while a page scrolls.

## `Redesigned/Kit/SGRedesign.h`

**file overview** (was L1)
> The flags the redesign is built on. A redesigned screen, and the glass design Spotify ships switched
> off (SGRGlassDesign.x), register theirs from a %ctor whether or not Redesigned UI is on: the settings
> rows need the list to lock theirs. Only while Redesigned UI was on at launch is anything forced,
> and then over an override from the All flags page too (Core/SGFlagForce.h). The switch itself is
> Core/SGUIMode.h's.
> Threading: register from a %ctor, before Spotify reads a flag.

## `Redesigned/Kit/SGRedesign.m`

**`static os_unfair_lock sg_flagsLock = OS_UNFAIR_LOCK_INIT;`** (was L5)
> Written from the constructors, read by the configuration provider on whatever thread it asks from;
> the lock only guards the swap of the immutable table.

## `Redesigned/Library/Library.h`

**file overview** (was L1)
> The Library redesign: Spotify's Your Library kept, with its controllers, its list and its rows, decluttered
> to a library on black and restyled from the Kit. No settings of its own.
>
> LibraryHeader.x   the header the way Home and Search have theirs: a large title at the leading edge, the
> avatar at the trailing edge, the filter chips gone and the header closed up by what
> they leave. A folder opened from the library is the same header, its back button and
> its own controls kept
> LibraryRows.x     every row and grid card: the artwork at the Kit's radius with continuous corners, a
> circular one left round, and a hairline between the rows
> LibrarySearch.x   the search inside the library: its field a glass capsule, the way the Search tab's is
> (Redesigned/Navbar/SearchField.x)
>
> Every hook installs only while Redesigned UI is on (SGRedesignedUI).
> Threading: main thread only.

**`void SGRLibraryClearScrim(UIView *header);`** (was L20)
> LibraryHeader.x. The scrim Spotify lays behind a library header taken out, so the soft scroll edge
> (Kit/SGREdgeEffect.x) is what keeps the header clear of the list under it. A header without one is left
> alone; the folder's has none.

## `Redesigned/Library/LibraryHeader.x`

**file overview** (was L1)
> Library redesign: the header of Your Library and of a folder inside it, the way Home and Search have theirs
> (Redesigned/Home/HomeHeader.x, Redesigned/Search/SearchPage.x), with the avatar that opens the side drawer and
> the buttons at the trailing edge. The root draws no title of its own -- "Your Library" ran over the avatar in
> the leading corner, so it is not drawn at all and the header carries no text; a folder still draws its own
> name. The scrim Spotify lays behind the header is gone, the soft scroll edge (Kit/SGREdgeEffect.x) being what
> keeps the header clear of the list scrolling under it.
>
> The filter chips under the row stay Spotify's, untouched. They were taken out when the redesign was first
> built and the header closed up by the 49pt they left, and sorting a library turned out to be something the
> page cannot do without (issue #20). Spotify already draws them on the system's own glass
> (Reprise_LiquidGlassKit.LiquidGlass.ChipGlassView, trees/clean/library/03.txt:1210), so they belong here as
> they are; with them back the header keeps the height Spotify gives it and the list keeps Spotify's own inset,
> and there is nothing here to resize or to hold.
>
> Tree (trees/clean/library/03.txt:1159-1247): YourLibraryView holds YourLibraryContentView, the size of the
> page, and after it -- so over it -- YourLibraryHeaderView 402x159.33: LiquidGlass.GradientView (the scrim), a
> 402x48 row at {0, 62} holding an AutoLayoutStackView {8, 0} 390x48 of
> ListeningActivity_ElementsKit.AdaptiveFaceContainer (the avatar, id=Components.UI.SideDrawerButton),
> id=YourLibraryHeader.title ("Your Library", 21pt), a spacer, a hidden id=YourLibraryHeader.recents,
> id=YourLibraryHeader.search and id=YourLibraryHeader.plus; and under the row
> YourLibraryHeaderContentFiltersView {0, 110} 402x49.33, the chips. Recents is hidden on the account the tree
> is of; the header's model shows it where it says isRecentsAvailable, a clock between the spacer and Search
> (issue #21), and it goes to the trailing edge with the others. A folder (trees/continuous/1.txt:325-344)
> is the same header under YourLibrary_FolderImpl, with id=YourLibraryFolderHeader.back at the leading edge,
> its title, then contextMenu, plus and play or pause, and the chips at {0, 118}.
>
> The header neither moves nor shrinks as the list scrolls -- 03.txt, 05.txt and 06.txt hold it at
> {0, 0} 402x159.33 at three scroll positions -- so there is nothing here to follow: the row is laid out once a
> pass and stays where it is put.
>
> Each control moves by a transform rather than by a frame. Spotify's stack lays them out from constraints of
> its own on every pass, and Auto Layout sets a view's centre and bounds and leaves its transform alone, so the
> move outlives the pass that made it (Search moves the Browse cells the same way). Nothing leaves the stack:
> an arranged view of Spotify's that hides traps its stack in updateConstraints (Kit/SGRRestyle.h), so what
> goes is alpha, touches and accessibility, and the title Spotify draws goes that way while ours is a subview
> of the header the stack does not arrange.
>
> A move is worked out from where the stack put the control, so it holds only until the stack puts it somewhere
> else, and the stack does that on passes of its own that reach neither the header nor the page: the header's
> model arriving after the page first laid out shows or hides a button, the title gets its text, the avatar
> its size. A button just shown stands where it stood hidden, at the row's leading edge (Recents in 03.txt),
> until the stack's next pass places it. Moves worked out on the page's pass alone were then off by however
> far each control went since -- over the title, off the screen -- until the page laid out again on the way
> back from a playlist (issue #21). So the row the controls stand in is watched too, and every pass of its own
> places them again.

**`static const CGFloat kRowInset = 8;`** (was L53)
> Spotify's own inset for the header's controls: a 48pt button flush against the header's trailing edge has its
> 24pt glyph 20pt from the screen, and the 32pt avatar inside its own 48pt box 16pt from it, which is the
> margin Home gives the avatar.

**`static NSMutableArray<UIView *> *controlsIn(UIView *header, NSArray<NSString *> *identifiers, const void **keys) {`** (was L81)
> The header's controls, in the order they are to read from the leading edge, leaving out what this build does
> not have, what Spotify has hidden (a folder shows play or pause, never both) and what has not been laid out.

**`static CGFloat placeTrailing(UIView *header, NSArray<UIView *> *controls) {`** (was L92)
> Puts the controls at the header's trailing edge, the last of them flush against it and each keeping the width
> it has, and answers where the leading edge of the first of them fell.

**`static void watchRow(UIView *row, UIView *header, NSArray<UIView *> *(*place)(UIView *header)) {`** (was L107)
> `place` again after every pass of the row the controls stand in (see the top of the file), for as long as it
> is in the header. The row is the stack's container, a plain UIView the Kit can watch; what `place` does not
> touch -- the header's height, the list under it -- stays the page's pass's.

**`static NSArray<UIView *> *placeRoot(UIView *header) {`** (was L182)
> The root header's controls at its trailing edge, the avatar last and no title at all. Answers what it placed
> in the order it reads, nothing while the header has no control laid out.

**`placeTrailing(header, trailing);`** (was L198)
> No title on the root: "Your Library" ran over the avatar in the leading corner, so the header carries
> only the controls at its trailing edge.

**`static NSArray<UIView *> *placeFolder(UIView *header) {`** (was L205)
> The folder header's controls at its trailing edge and the title between them and the back button, which stays
> where Spotify has it. Answers what it placed in the order it reads, the back button first.

**`UIView *face = isFace(trailing.lastObject) ? trailing.lastObject : nil;`** (was L236)
> The first pass that laid the header out, not the first pass at all: a page appearing lays out before
> its controls have a size, and a line off that pass would say the header was left as Spotify's.

## `Redesigned/Library/LibraryRows.x`

**file overview** (was L1)
> Library redesign: the rows of Your Library and of a folder inside it, and the cards of its grid.
>
> Tree (trees/clean/library/03.txt:30-73, 06.txt:28-40): every cell of the list is a
> YourLibrarySwipeableCollectionViewCellContainer holding either a 402x80 row -- id=Playlist.Row.Library,
> Album.Row.Library or Podcast.Row.Library, all three an AutoLayoutStackView {16, 8} 370x64 of
> id=Artwork.Row.Library 64x64 r=4 and, 12pt after it, the title over its kind and its owner -- or a
> 112.67x161.33 card, id=Components.UI.CardLibrary, over id=Components.UI.CardLibrary.Artwork r=4.
>
> Two things are changed, both of them the Music app's library. The artwork takes the Kit's radius for its
> size with continuous corners, Spotify's 4pt being the square corner of its own look; an artist's picture
> already carries a radius half its side and is left the circle it is (r=32 in the trees, 2 of the 90 rows
> recorded). And a hairline runs between the rows from the text's leading edge, which is where a library list
> draws one -- a layer rather than a view, since the rows are reused as fast as the list scrolls, with its
> actions off so a reused row does not slide its line into place.

**`static const CGFloat kTextGap = 12;`** (was L19)
> What a row leaves between its artwork and its text (03.txt:36 and :39: the artwork ends at 64, the text
> starts at 76), and where the hairline starts with it.

**`static void hairline(UIView *cell, UIView *thumb) {`** (was L36)
> The line under a row, from its text's leading edge to the trailing edge of the page. A cell holding a card
> has none, and one reused from a row into a card loses the line it was left with.

## `Redesigned/Library/LibrarySearch.x`

**file overview** (was L1)
> Library redesign: the search inside the library, the page the header's magnifier opens.
>
> Tree (trees/clean/library/04.txt:21-63): YourLibrarySearchView holds the same YourLibraryContentView and list
> as the library itself, and over them YourLibrarySearchHeaderView 402x142 -- LiquidGlass.GradientView (the
> scrim) and, at {0, 94}, a SearchHeaderLibraryLayout of two shapes 32pt tall: the field,
> id=Components.Header.UI.Toolbar.SearchField 320x32 r=4, and id=Components.Header.UI.Toolbar.ButtonContainer
> 58x32 r=4 around Cancel. Both already draw Reprise_LiquidGlassKit's LiquidGlass.SearchBarView inside
> themselves, so there is nothing to put behind them: what Spotify's own glass is missing here is the shape.
> They become capsules, which is the shape the Search tab's field has (Redesigned/Navbar/SearchField.x), and
> the scrim goes the way it goes on every other redesigned page.
>
> The header is 142pt and holds no filter chips, so there is nothing here to close up: LibraryHeader.x shrinks
> a header only where chips leave a band behind.

## `Redesigned/Lyrics/KaraokePage.x`

**file overview** (was L1)
> The karaoke view goes over the lyrics part of the full screen lyrics page (trees/lyrics.txt:
> Lyrics_FullscreenElementPageImpl.LyricsView, between the header and the controls), so Spotify's
> header, close button and controls stay working. It is laid over rather than swapped in: Spotify's
> list keeps running underneath and comes back the moment a track has no synced lyrics.

## `Redesigned/Lyrics/LyricsPage.x`

**file overview** (was L1)
> The redesign's full screen lyrics page, on glass over the redesigned player, which shows through it:
> the lyrics card under the player reads as having grown to the screen. A copy of
> Native/Lyrics/LyricsPage.x without its switch.
>
> Page (trees/lyrics.txt): a page of its own, presented over the player by a
> _UIOverFullscreenPresentationController, which is why the card's glass stops at the card's edge.
> Tome_PageTemplateImpl paints the template view #121212 and FullscreenView paints itself the
> album colour on top, both opaque; clearing them lets the player's blurred artwork through.
>
> The album colour is the stubborn one: it arrives per track, after the page has laid out, and it
> comes back through a path SGRRepaint.x never sees, so a sweep at layout time loses the race.
> FullscreenView is asked not to keep it at all instead. The pane goes inside FullscreenView, in
> front of whatever that view still fills itself with, rather than behind the whole page.

**`static UIView *clearAncestors(UIView *view) {`** (was L19)
> Up to the presentation: the template views in between paint themselves opaque once, at setup.
> Only the chain is cleared, not the subtree -- nothing else on the page is painted.

**`if (glass.overrideUserInterfaceStyle != UIUserInterfaceStyleDark) glass.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;`** (was L48)
> Dark whatever the system is set to: the page is presented outside the navigation stacks Spotify
> makes dark, and would be light glass under white lyrics on a phone in light mode.

## `Redesigned/Lyrics/LyricsText.h`

**file overview** (was L1)
> What the redesign's lyrics show of a line besides its words: the pronunciation and the translation a
> source has for it (Shared/Lyrics/Lyrics.h), each switched on from the lyrics' own menu, and the order
> of sizes the three are set in, from the Lyrics page. The switches apply at once, to every lyrics
> view there is, and are kept for the next song and the next launch.

## `Redesigned/Lyrics/LyricsText.m`

**file overview** (was L1)
> What a line shows besides its words, as stored: the two switches of the lyrics menu and the order of
> sizes of the Lyrics page (LyricsText.h). The page itself is LyricsTextSettings.m.

## `Redesigned/Lyrics/SGRKaraokeView.h`

**file overview** (was L1)
> The redesign's Apple Music style lyrics view, always on, over Spotify's full screen lyrics page
> (KaraokePage.x) and in the redesigned player itself (Redesigned/Player/PlayerLyrics.x). A track
> without synced lyrics keeps Spotify's own lines, where there are any next to it. The lines and the
> clock are Shared/Lyrics/Lyrics.h's.
>
> It takes the whole of whatever it is put in and dims every other view in there while it has lines
> to show, so a host it shares with anything else needs a view of its own for it.

**`@property (nonatomic, readonly) UIEdgeInsets lineInsets;`** (was L14)
> The part of the view the lines are shown in, as insets from its edges (only top and bottom are
> read): the sung line rests in it, the lines fade out at its ends, the credit sits at its foot, and a
> touch outside it goes through the view. Zero, the whole view, unless set. The player lays the view
> over all of itself and moves these as its controls come and go (Redesigned/Player/PlayerLyrics.x).

**`- (void)useCompactFontSize:(CGFloat)size;`** (was L21)
> The one-line preview under the player's cover (Redesigned/Player/PlayerArtwork.x): the lines are set
> at `size`, without the credit, the pronunciation and translation button or their meanings, with
> nothing to scroll and no touches, so a tap on the preview stays Spotify's. The view takes the whole
> of its host and dims the rest of it as ever, which is how Spotify's own line under it is hidden. Set
> before it has lines, and again as the room it has changes.

**`@property (nonatomic, copy) BOOL (^takesTap)(void);`** (was L27)
> Asked as a tap lands on the lines, before it seeks or opens what a line means; NO leaves the tap to
> whoever else watches the touch. Nil takes every tap.

## `Redesigned/Lyrics/SGRKaraokeView.m`

**file overview** (was L1)
> The redesign's Apple Music style lyrics, always on: the line being sung lights up word by word, the
> rest dim and blur with distance. Lines two voices sing at once are lit together, an instrumental
> break holds three dots, and a line can show its pronunciation and its translation under it. The
> lines and the clock are Shared/Lyrics/Lyrics.h's.
>
> Only words the source timed are swept. A line timed by the line lights up whole as it starts, as
> Apple Music lights such a line, unless the Lyrics page's "Simulate word-by-word timing" asks for
> its estimated words to be swept; lyrics with no timing at all are shown as plain text, every line
> lit, nothing following the clock.

**`static const CGFloat kCompactMargin = 24, kCompactGap = 6;`** (was L23)
> The small preview under the player's cover: the room the page's lines have in it and the gap under
> the sung one, which the room leaves only a peek of the next line through.

**`static const CGFloat kBubbleSide = 22, kBubbleGap = 8, kBubbleGlyph = 11, kBubbleAlpha = 0.75, kBubbleReach = 14;`** (was L29)
> The mark of a line Genius explains: a bubble after it for the artist's own word, a dotted underline
> for anyone else's.

**`static const CGFloat kExtrasSide = 44, kExtrasBottom = 12, kExtrasGlyph = 17, kExtrasCreditGap = 12;`** (was L35)
> The button for the pronunciation and the translation, in the bottom leading corner as Apple Music
> has it, and the gap between it and the credit beside it.

**`static const CGFloat kSightBehind = 0.5, kSightAhead = 0.5, kSightSlack = 0.25;`** (was L45)
> Lines get views this far outside the visible part, in screen heights: half a screen above it
> and below, and a quarter more before a view is let go. Every view held is one more for the window
> to take in and let go when the lyrics come up; a line comes into view about once in three seconds,
> and a page flung by hand fills in at a few lines a frame.

**`static const NSInteger kBreakMinMs = 7000;`** (was L54)
> A pause in the singing this long is an instrumental break, and three dots hold its place: from the
> end of the last line sung before it to the start of the next, or from the top of the song to the
> first line. BiniLyrics' web player, which copies Apple Music's, draws them from seven seconds.

**`static const double kBreakWait = 0.25, kBreakIn = 0.4, kBreakFadeIn = 0.16, kBreathHalf = 4, kBreathLow = 0.85, kBreathHigh = 1.12`** (was L60)
> Their timeline, Apple Music's as that player reads it off: in over 0.4 s, breathing between 85 % and
> 112 % of their size in eight second cycles, filling one after another, then swelling to 120 % and
> shrinking away in 0.35 s, which ends half a second before the next line starts so it has that long
> to move up into their place. A cycle is timed to end small, so the swell starts from the bottom.
> They wait a quarter of a second before they come, for the line before them to move up out of the way.

**`static BOOL readsRightToLeft(NSString *text) {`** (was L76)
> Whether a line is written right to left, told by its first letter the way the Unicode bidi algorithm
> tells a paragraph's direction. Each line is asked on its own, since a song can mix scripts, and the
> phone's language has no say in it.

**`NSMutableParagraphStyle *paragraph = [NSMutableParagraphStyle new];`** (was L110)
> A word of a line written right to left is set in the line's direction, so the punctuation at its
> ends falls where the whole line would put it, a word of a left to right script among them too.

**`@interface SGRKaraokeWordView : UIView`** (was L121)
> The word twice: dim underneath, white on top behind a mask whose feathered edge slides across it,
> from the edge its script starts at.

**`@property (nonatomic) BOOL whole;`** (was L127)
> Lit with the rest of its line at once rather than swept, and floated up with it over riseStart to
> riseEnd, which are the word's own times until the sweep says otherwise.

**`_lit.hidden = YES;`** (was L152)
> Hidden until the line is sung: a masked layer is drawn offscreen every frame even when the
> mask leaves nothing of it, and a song has hundreds of words waiting their turn.

**`- (void)fillTo:(CGFloat)cursor {`** (was L169)
> The cursor is in line units and the feathered edge is centred on it, so the edge runs on through
> the space into the next word instead of starting over at each one. Right to left, the mask is the
> same one turned around: white from the word's right edge, the feather `local` in from it.

**`- (void)floatAt:(double)ms {`** (was L184)
> Rises like a critically damped spring let go as the word starts: no jolt, a long soft landing.
> x = 5 at the end of the word is 96 % of the way up.

**`@interface SGRKaraokeStyle : NSObject`** (was L203)
> Which of a line's texts are shown and how big, from the Lyrics page's order of the three and the
> lyrics menu's switches: the first shown is set at the lyrics' own size, and the next two keep the
> sizes of their places whatever is hidden above them, so a translation stays the smallest with the
> pronunciation off. A song is laid out and measured by one of these, so a change of it is a new one.

**`static const CGFloat kPairTighten = 2, kPairGap = 4, kPartGap = 6;`** (was L255)
> Between a row of words and the row spelling them out under it, between one such pair and the next,
> and between two texts of a line set apart.

**`@interface SGRKaraokeLayout : NSObject`** (was L259)
> Where everything of a line goes, from its text alone: each word's frame and its place along the
> sweep, the translation's frame and the backing's top. The page lays every line of a song out with
> it off the main thread to stack them, and a line view lays itself out by it when it is made, so the
> two can never disagree about a height.

**`typedef struct {`** (was L275)
> A run of words set in rows as wide as the page: where each goes along its row, which row, and where
> it sits along the sweep, the rows laid end to end. A joined word follows the one before it flush:
> the scripts that do not space their words would otherwise read with a gap between every syllable.

**`static void settle(CGRect *frames, NSUInteger *groups, NSUInteger count, NSUInteger groupCount, CGFloat width, BOOL rightToLeft, B`** (was L302)
> Written right to left, rows are laid out left to right and turned around, so the first word is at
> the right edge and each row runs leftwards from it. Then each group of rows goes against the line's
> edge, a second voice's against the far one, as Apple Music sets the two sides of a duet apart; a
> group too wide to fit stays where its first word put it.

**`static CGFloat layPair(NSArray<SGKaraokeWord *> *lead, UIFont *leadFont, NSArray<SGKaraokeWord *> *under, UIFont *underFont,`** (was L360)
> Two texts of words where the second spells out the first, or the first the second: each row of the
> leading one with the other's words under it, each under the word it starts with, as Apple Music sets
> its pronunciation, so a syllable reads under the syllable it sounds. Returns where the pair ends.

**`NSUInteger from = j, until = j;`** (was L390)
> Under the row, each word at the start of its own, pushed along past the one before it, and the
> pieces of one word flush together, the way the row above has them. A row spelt out wider than
> it is written, as Korean is, cannot keep to its words and still fit: it is set as plain words
> from the edge instead, in as many rows as it takes.

**`static SGRKaraokeLayout *layOut(SGKaraokeLine *line, CGFloat width, SGRKaraokeStyle *style, NSInteger right) {`** (was L438)
> The texts a line has, in the style's order, the lyrics and their pronunciation set as a pair where
> the order has them side by side, and the backing row after the lyrics. `right` is the side a backing
> row keeps to, its line's; -1 for a line of its own, which takes its side from its voice and script.

**`static NSArray<NSNumber *> *topsOf(NSArray<SGKaraokeLine *> *lines, CGFloat width, SGRKaraokeStyle *style, CGFloat gap) {`** (was L499)
> Where each line starts in the stack, from the heights alone. Measuring text is safe off the main
> thread, and a song's worth of it is kept off it: the first card of a track lays out while the
> player is opening, and a frame that measured every line then was a frame the animation lost.

**`@interface SGRKaraokeSweep : NSObject`** (was L518)
> One run of words lit by one sweep: a line's own, or its pronunciation's, each timed by its own words.
> A whole one lights every word of the run at once from `start`, for a run whose words are not timed.

**`- (void)buildSweep {`** (was L557)
> The fill cursor reaches each word's left edge as the word starts and clears the last word as it
> ends, on a monotone cubic through those points, so the pace changes between words without a kink.

**`@property (nonatomic, readonly) BOOL right;`** (was L613)
> Laid against the right edge: a line written right to left, or a second voice's written left to
> right. A backing row keeps to the edge of the line it hangs under, whatever script each is in.

**`- (instancetype)initWithLine:(SGKaraokeLine *)line width:(CGFloat)width style:(SGRKaraokeStyle *)style under:(SGRKaraokeLineView *`** (was L618)
> under: the line a backing row hangs under, nil for a line of its own. sweepsEstimates: the words of a
> line timed only by the line are swept on their estimated times, rather than lit whole.

**`- (SGRKaraokeSweep *)sweepOf:(NSArray<SGKaraokeWord *> *)words font:(UIFont *)font frames:(NSArray<NSValue *> *)frames`** (was L644)
> A sweep's word views, each put where the layout has it and told where it sits along the sweep.
> start: NAN for words timed one by one, else when the run lights up whole.

**`static double wholeFrom(SGKaraokeLine *run, BOOL sweepsEstimates) {`** (was L662)
> When a run of the line lights up whole, or NAN to sweep it: only words the source timed are swept,
> unless the estimate is asked for.

**`[UIView animateWithDuration:0.9 delay:0 usingSpringWithDamping:1 initialSpringVelocity:0`** (was L762)
> A sung line fades back to dim rather than dropping its fill at once, and its words sink back
> on a spring slow enough to still be seen doing it.

**`@interface SGRKaraokeBreakView : UIView`** (was L860)
> Three dots in place of the lines through an instrumental break, the way Apple Music keeps a long
> pause from reading as lyrics gone missing: they come in as the break begins, breathe while it
> lasts, fill one after another over its length and swell and go as the next line comes up.
>
> All of it is one Core Animation timeline the length of the break, on a layer whose clock is laid
> against the song's: set once as the break opens and again only when the song jumps, stops or
> starts, so the frames in between cost the page nothing. The view itself is moved by the page like
> a line, so the clock is a layer inside it, where a stopped clock cannot stop that move too.

**`static const CFTimeInterval kBreakEpoch = 1;`** (was L876)
> Local time on the dots' clock is this far into the break plus this, so no animation begins at 0,
> which Core Animation reads as "now".

**`static void atFullRate(CAAnimation *animation) {`** (was L880)
> The rate the page's display link asks for, asked for here too: an animation that settles for less
> could hold the player's own 120 Hz animations down, as a link asking for 60 once did.

**`- (void)playFrom:(NSInteger)start to:(NSInteger)end {`** (was L944)
> The break's whole run, sampled the way the numbers above describe it: densely where the dots come
> and go, every fifth of a second through the slow breath between.

**`SGRKaraokeSpan *_spans;`** (was L1053)
> What is sung now. Most of the time one line, the one at the anchor; where voices overlap, every
> line being sung, the stack arranged around the one that began first; through a break, none,
> and the dots at the anchor with the line after them just below.

**`[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(scheduleLink) name:UIApplicationDidBecomeActiveNotificatio`** (was L1126)
> A locked phone leaves the card in its window, so the link has to be put down by the app going
> away rather than by the view going: see scheduleLink.

**`- (void)useCompactFontSize:(CGFloat)size {`** (was L1133)
> The small preview under the player's cover: one line, the one being sung, without the credit, the
> pronunciation and translation button or their meanings, with nothing to scroll and no touches, so a
> tap on the preview is still Spotify's to take. The font follows the room the player gives it.

**`- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {`** (was L1216)
> Lines are placed for a content offset of 0, so following the song means scrolling back to 0.
> While the user browses, placement stands still and every line is sharp.

**`- (void)scheduleLink {`** (was L1256)
> The player opens and closes in animations that run at 120 Hz, and while a display link asked
> for 30 to 60, the range Apple's ProMotion guide says Core Animation gives priority to, those
> animations ran rough; the player and the lyrics themselves were smooth throughout. The card's
> link now asks for 60 but takes 120, and is put down for as long as the player animates, which
> NowPlayingBar.x announces as each animation starts and again as it ends. The timer is for an end
> that is never announced.
>
> The link is also put down whenever the app is not in front. Spotify keeps playing there, and a
> phone locked on the player kept the card ticking at 120 Hz against a screen that was off: 117 of
> the 137 wake ups a second the mod cost over stock Spotify were this one link, measured with
> scripts/battery-probe.sh. Nothing of the card is seen from the background, so nothing is drawn.

**`- (void)alignFade {`** (was L1289)
> The mask sits in the scroll view's own coordinates, which move with the content as it scrolls, so
> it is put back over the visible part on every frame, where the presentation layer says the
> content is: that holds through a drag and through the animated scroll home alike. Left where
> layout put it, it covered the first screenful of lines only, and a scroll past them showed nothing.
>
> It covers the lines' room alone, and while that grows or shrinks it is moved on every frame too, so
> its edges travel with the room instead of jumping to where it ends up.

**`- (void)setLineInsets:(UIEdgeInsets)insets duration:(NSTimeInterval)duration {`** (was L1329)
> The lines spring to the anchor of the new room the way they move on to a new line, the ones further
> down a beat later, while the fade's edges and the credit travel over `duration`.

**`- (void)forgetSung {`** (was L1371)
> Nothing sung, no break open: the state a song starts from, before the clock places it. The dots
> are made again for the next, in case it is laid out in another font.

**`- (void)rebuild {`** (was L1404)
> Measures the song for the width and, once that is in, places it; Spotify's own lines stay in view
> until then, since the page shows nothing of its own before it has lines to show.

**`- (void)restyle {`** (was L1440)
> A switch of the menu or the Lyrics page's order: the song is measured again in the new style off
> the main thread, as for a new width, but the lines on the page stay until it is in, and then the
> new ones crossfade over them where they were, so nothing blinks and nothing is lost of the place.

**`for (NSUInteger i = 0; i < _sungCount; i++) [self viewForLine:_sung[i]].active = YES;`** (was L1471)
> The new views come in as the old ones were: the lines being sung lit, and every blur where it
> was rather than easing in from sharp, which a view made out of sight does unseen.

**`- (void)offerExtras {`** (was L1477)
> The button shows only for a song with a pronunciation or a translation to show, and its menu only
> what the song has: a switch for each, reading what tapping it will do.

**`UIButtonConfiguration *config;`** (was L1492)
> The system's glass, which turns solid under Reduce Transparency by itself; before iOS 26, the
> Kit's solid fill in its place.

**`- (CGFloat)topOfLine:(NSInteger)index {`** (was L1529)
> Where a line starts on the page, for the stack as it is arranged now: an open break holds the room
> of one row at the anchor, and the lines from the one after it on are moved down by it.

**`- (NSInteger)distanceOf:(NSInteger)index {`** (was L1548)
> How many lines away from what is sung a line is, which is what dims, shrinks and blurs it: from the
> nearest line being sung, from an open break as if it were a line of its own, and before the first
> line from the line before it, as ever.

**`- (void)showLinesInSight {`** (was L1574)
> Views for the lines just outside the visible part as well as in it, wherever that is: around the
> sung line while following the song, around wherever the page has been scrolled to while browsing.
> The ones further off are let go, so a long song costs a couple of dozen line views rather than
> one for every line, and the lines in sight are the only ones the compositor has to draw.

**`CGFloat middle = seen + height / 2;`** (was L1607)
> A few a frame, the nearest the middle of the visible part first, so a page scrolled by hand
> fills in what is in view before what is not; the next frame picks up where this one left off.

**`- (void)placeLine:(SGRKaraokeLineView *)view at:(NSInteger)index animated:(BOOL)animated {`** (was L1624)
> One line's place in the stack: the anchor sits on the edge its text is aligned to, so it scales
> toward its own text, and it dims and blurs with its distance from what is sung.

**`- (void)placeLinesAnimated:(BOOL)animated {`** (was L1650)
> The sung line rests at the anchor and the rest stack around it; lines below it follow a beat
> later, the further down the later, as Apple Music's do. A line sung over it stays where it is
> below, lit; the stack moves on to it once the line at the anchor is sung out.

**`- (void)placeBreak {`** (was L1664)
> The dots, at the anchor for as long as a break is open, against the edge the line after it is on.
> They are only ever where they belong: they come and go by their own timeline, not by moving.

**`- (double)clockMs {`** (was L1712)
> The player's position run on by the frame times the display will show and eased toward each new
> reading, so the sweep follows neither the callback's jitter nor the small jumps of the core's
> corrections. A seek or a new track is too far off to ease and is taken at once.

**`[self setShowing:_tops != nil && !(_compact && _plain)];`** (was L1755)
> The preview has no clock of its own for words: with nothing timed there is no line to sweep, and
> Spotify's own reading is left in its place.

**`- (NSUInteger)sungAt:(double)now into:(NSInteger *)sung focus:(NSInteger *)focus openBreak:(NSInteger *)openBreak {`** (was L1795)
> What is sung at `now`: each line from its start until it is sung out, so two voices over each
> other are both lit, and the last line begun on through the pause after it, as Apple Music keeps a
> line lit until the next one comes. A pause that is a break is the dots' instead, until the moment
> before its end when the line after it moves up to the anchor, sharp but not yet lit.

## `Redesigned/Lyrics/SGRSingControl.h`

**`UIView *SGRSingControlForPage(UIView *page, CGRect lyrics, BOOL immersive, void (^hold)(BOOL));`** (was L2)
> Owned by the lyrics overlay in Now Playing (Redesigned/Player/PlayerLyrics.x). `lyrics` is the lines'
> band in the page's coordinates, and the microphone sits in its bottom trailing corner. `immersive` is
> the controls away: the microphone stays only while Sing is on. `hold` is called with YES while it is
> open, preparing or explaining itself, and with NO once it is none of them. While Sing is unavailable
> (switched off, or without its voice model) there is no microphone: a control already there is taken
> away, its hold let go, and this answers nil.

## `Redesigned/Lyrics/SGRSingControl.m`

**file overview** (was L1)
> Sing's microphone in the player's lyrics (SGRSingControl.h), the way the Music app has its Sing button: a
> round glass button with a microphone on it, and a capsule of glass growing up out of it that holds the
> vocal volume, filled from the bottom to the level. What Sing is doing shows on the button itself, never in
> words beside it:
>
> off           glass and a white microphone
> preparing     a ring turning round the microphone over a faint fill, up to the level it gets ready for
> on            the fill solid white up to the level and the microphone dark on it; closed, a white disc
> recovering    on, with the ring turning again, dark on the white, while the original covers a gap
> turning off   off at once; the original audio still queued plays out behind it
> stopped       off with the microphone dimmed; a tap says why and offers to try again
>
> A tap turns Sing on and opens the capsule. Open, a tap turns Sing off; closed while Sing is on, a tap
> opens it again. A drag anywhere on it sets the level, opening it first. The capsule closes by itself
> three seconds after the last touch while Sing is on. Sizes move on the Kit's layout spring and colours
> on its crossfade, so Reduce Motion keeps the fades and drops the movement, and the ring pulses in place
> instead of turning. VoiceOver reads the button and the slider out in full.

**`[UIColor.blackColor setFill]; [UIColor.blackColor setStroke];`** (was L54)
> A handheld microphone, drawn as a template so both the glass and white states
> use the same crisp silhouette. The three sparkles keep distinct sizes at 28 pt.

**`@interface SGRVocalSlider : UIControl`** (was L94)
> A vertical, thumb-free slider inside the glass capsule. Direct touch and VoiceOver both send
> the same value-changed event; UISlider's horizontal gesture recognizer is not involved.

**`@interface SGRVocalPan : UIPanGestureRecognizer`** (was L131)
> Spotify's player also pans to dismiss. A drag starting inside this control belongs to vocal
> volume, including a drag starting on the microphone, rather than to the enclosing player.

**`@interface SGRSingRing : UIView`** (was L139)
> The ring round the microphone while Sing gets ready: an arc turning once a second, or with Reduce Motion a
> whole ring pulsing where it is, a fade not being motion. It takes its colour from its tint.

**`- (void)collapseIfIdle {`** (was L416)
> Closes three seconds after the last touch while Sing is on, but never under a finger, while Sing prepares,
> or for VoiceOver, which has no other way back to the slider.

**`CGFloat stretch = _expanded && !SGRReduceMotion() ? _stretch : 0;`** (was L435)
> The value uses stationary page coordinates; stretching the glass must never move the
> slider's numeric endpoints. A bounded response follows the finger in either direction.

**`if (_expanded) { if (_slider.superview != content) [content insertSubview:_slider belowSubview:_button]; }`** (was L457)
> Interactive glass exposes its content as an accessibility container. Remove the folded
> slider from that container instead of leaving a zero-height adjustable element in it.

**`CGFloat travel = [gesture locationInView:self.superview].y - _dragStart.y;`** (was L522)
> Measure from touch-down, including the travel before UIPan recognizes the gesture.
> Stationary page coordinates also keep capsule expansion from changing the value.

**`UIView *surface = page.superview ?: page;`** (was L614)
> The embedded lyrics overlay passes header/transport touches through to its siblings.
> Observe their shared player surface too, so those touches can collapse the capsule.

## `Redesigned/Lyrics/Sing.h`

**file overview** (was L1)
> Sing in the redesign: its switch and the Karaoke page of Mod Settings. The work itself is
> Shared/Sing's; its microphone in the player's lyrics is SGRSingControl.h's.

**`void SGRSingApplySwitch(void);`** (was L7)
> Hands the switch to Shared/Sing while the redesign runs (Sing.x), at launch and as it is turned:
> the microphone comes and goes at once, no restart.

**`UIViewController *SGRKaraokeSettingsPage(void);`** (was L11)
> SingSettings.m: Mod Settings > Karaoke, with the switch and the voice model's download, and what its row on
> the main page says beside the chevron (Off, On, No model, the download's percentage).

## `Redesigned/Lyrics/Sing.x`

**`void SGRSingApplySwitch(void) {`** (was L5)
> Only the running look is told: a redesign switched on in Appearance but not yet restarted into takes the
> switch as it finds it at its launch.

## `Redesigned/Lyrics/SingSettings.m`

**file overview** (was L1)
> Mod Settings > Karaoke, in the redesign (App/ModSettings.x puts its row on the main page): Sing's switch and
> its model-size choice (Vitrine's full or light export), download status and actions. The switch puts the
> microphone in the player's lyrics and takes it away again at once; off, Sing does no work at all. Each
> model keeps separate installed and resumable-download files. Below iOS 18, where the separator cannot
> run, the section is one row saying so.

## `Redesigned/Navbar/Navbar.h`

**file overview** (was L1)
> The redesign's navbar: the glass tab bar (TabBar.x) over Spotify's own, composed from its own list
> (Navbar.x, NavbarLayout.m), which the redesign keeps apart from the native look's: an ordered list of
> entries, each a dictionary. An entry with a URI is a tab of the mod's own; one without names
> one of Spotify's, by the label under its icon. No list at all is Spotify's order, all shown.

**`NSURL *SGRNavbarTabURL(NSString *uri);`** (was L21)
> What a tab of the mod's own opens: its URI as typed or pasted, share links made spotify: URIs, and
> the URIs of presets that never opened (spotify:collection:playlists, up to 0.20) moved to the ones
> that replaced them, so a tab saved back then works without being added again.

## `Redesigned/Navbar/Navbar.x`

**file overview** (was L1)
> The redesign's copy of Native/Navbar/Navbar.x, composing the row the glass tab bar mirrors.
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

**`static CGRect sg_iconBox = {{0, kIconTop}, {kIconSize, kIconSize}};`** (was L29)
> Where Spotify's own items keep their icon and label, read off one of them every pass, so an item of
> the mod's own sits on the same line as its neighbours.

**`static NSMutableArray<NSString *> *sg_stockOrder;`** (was L38)
> Spotify's own tabs in Spotify's order, from the first layout pass of this launch, before
> anything below has moved them.

**`static UIView *iconView(NSString *name) {`** (was L46)
> One of the 538 glyphs SPTEncoreIcon exposes, one class method each ("podcasts", "heart"), so an
> item of the mod's own is drawn the same way as Spotify's. An SF Symbol stands in if the name is
> not one of them.

**`- (void)layoutSubviews {`** (was L105)
> Both boxes come off a neighbour, so whatever Spotify does to the row's line-up is copied rather than
> guessed at; only the horizontal centring is the item's own.

**`- (CGSize)intrinsicContentSize {`** (was L118)
> A row that splits its width evenly ignores this, but one that sizes itself to its content would
> otherwise have nothing to go on for an item of ours.

**`- (void)open {`** (was L129)
> Through the app's own link dispatcher (Shared/Navigation/Links.h). What the dispatcher makes of the
> URI goes to the log first, so a tab that ends in Spotify's "Couldn't open link" says why.

**`static NSString *stockID(UIView *item) {`** (was L144)
> Spotify's items are told apart by the label under the icon: it survives the element views being
> rebuilt, and it is the name the Navbar page lists them under.

**`for (NSString *ident in sg_stockOrder) {`** (was L216)
> Tabs of Spotify's the list does not name — or named before Spotify had built them — keep
> Spotify's own place, at the end, shown.

**`for (UIView *item in wanted) {`** (was L235)
> Items of the mod's own join the stack at the end, where they are past whatever Spotify
> counts, and Spotify's own keep the places it gave them.

**`static void centreContents(UIView *item) {`** (was L249)
> Spotify placed the icon and the label for the width it measured (trees/test5.txt: x 28 in a
> 134pt slot, the centre of the 80pt it had with five tabs) and lays the item out no further
> once the slot changes. Assigning the centres back sends them through the hooks below.

**`static void placeRow(UIStackView *stack) {`** (was L258)
> Equal slots across the bar, in the order composed above. The frames go on after the stack's
> own pass, so Spotify's own widths never decide whether a fifth item fits.

**`static CGFloat slotCentreX(UIView *view) {`** (was L282)
> Spotify's element layout places the icon and the label from the width it measured, not from
> the slot above (trees/test5.txt: x 38 in a 134pt element in a 126pt slot), and a view placed by
> its parent gets no layout pass of its own. So the placement itself is bent: on the bar, whatever
> x Spotify sets, the view lands centred on its slot.

**`void SGRLogTabBarRow(UIView *tabBar) {`** (was L325)
> What the row settled on, logged whenever it changes: `make log` then says whether the items fit,
> what is holding their width, and in what order the bar ended up.

**`%hook _TtC28NavigationUI_TabBarItemsImpl29TabBarItemsNavigationListImpl`** (was L365)
> Whether Spotify reads its own item list through this ObjC bridge decides whether the bar can be
> composed at the model level, where the order, the taps and the widths would all follow by
> themselves, instead of by moving views about. Silence in the log says it cannot.

## `Redesigned/Navbar/NavbarSettings.m`

**`static NSArray<NSDictionary *> *tabPresets(void) {`** (was L7)
> What "Add a tab" offers: URIs Spotify's own router resolves to a page of its own, each with the
> name of the SPTEncoreIcon class method that draws its glyph. Playlists was spotify:collection:playlists
> until 0.20, which 9.1.78 knows only from its old iPad sidebar table and has no handler for (#66);
> spotify:playlists is the form its collection URI parser lists, next to spotify:playlists:by-you.
> The picker still asks the dispatcher about each one and leaves out what it has nowhere to send.

**`static NSMutableArray<NSMutableDictionary *> *navbarEntries(void) {`** (was L34)
> The list the Navbar page edits: the saved order first, then every tab of Spotify's it does not
> name, in Spotify's order. Entries for tabs Spotify no longer has drop out.

**`static void appendTab(NSDictionary *tab) {`** (was L54)
> A tab of the mod's own carries an identity of its own, so the same page can sit on the bar twice
> and renaming one does not shuffle the order.

**`static NSArray<NSDictionary *> *openablePresets(void) {`** (was L66)
> The presets the dispatcher can send somewhere, each verdict logged. When it cannot be asked (not set
> up yet, or 9.1.78's registry is not where it was) every preset stays, as before.

**`@interface SGRNavbarPage : SGPage`** (was L198)
> The tabs, in the order the bar shows them: drag to reorder, tap to show or hide, swipe a tab of
> your own away. Spotify's own tabs can only be hidden, never removed. Mod Settings and the welcome
> tour show the same editor.

## `Redesigned/Navbar/SearchField.x`

**file overview** (was L1)
> The redesign's search page: the white search field becomes a glass capsule with white text.
>
> Tree (trees/search.txt): SearchHeaderFind.SearchBar, a 370x48 Encore tertiary button painted
> white, r=6, holding SearchHeaderFind.SearchBarIcon and the placeholder label. The button class is
> shared app-wide, so the identifier names the one instance the page owns, with a wide light button
> as the fallback for a build that stops setting it.
>
> Two things about the colours. The glyph is an SPTEncoreIconView, which bakes its colour into what
> it draws, so tintColor never reaches it and setForegroundColor: is the way in. And coming back
> from the full screen search (trees/search opened.txt, a page of its own that this leaves alone)
> Spotify configures the field for a white background again, black glyph and black text, after the
> layout pass that styled it: both are then invisible on the glass until the next pass, a second or
> so later. So the two setters are refused for as long as the field is a capsule.

**`@interface UIView (SGEncoreIcon)`** (was L17)
> Spotify's glyph view, resolved at runtime; declared on UIView so the call and the hook below
> share one declaration.

**`static void traceField(UIView *button, NSString *when) {`** (was L40)
> Debug builds only. The second the field stays invisible after the full screen search closes is
> too short to catch in a tree, so every pass over the field says what it looked like, and the
> silence before the first line says the field did not exist yet.

**`static void sampleField(__weak UIView *weakButton, int step) {`** (was L57)
> traceField only says what the field looked like at a layout pass, and the second it is invisible
> for holds no layout pass at all: coming back from the full screen search the last pass before it
> lands is 1077ms earlier (a log of three trips in and out). So the field is put on a clock of its
> own as well, sampled every 50ms for the two seconds after it comes back into a window, which is
> the window the glitch lives in. Debug builds only, like the rest of the tracing.

**`if (glass.overrideUserInterfaceStyle != UIUserInterfaceStyleDark) glass.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;`** (was L109)
> Dark like every glass of the redesign's, rather than by grace of the navigation stack Spotify hosts
> the page in (TabBar.x).

**`- (void)didAddSubview:(UIView *)subview {`** (was L133)
> Spotify builds the field's content again when the page comes back, which can take the pane out
> with it; waiting for the next layout pass to put it back would leave the capsule blank.

## `Redesigned/Navbar/TabBar.x`

**file overview** (was L1)
> Tab bar: Spotify's own bar stays where it is but goes invisible, and a system UITabBar sits on top
> of it. On iOS 26+ with UIDesignRequiresCompatibility off, UIKit draws that bar as real Liquid Glass
> (selection bubble, lensing, light/dark adaptation) with no glass API of ours. Spotify's bar keeps
> its frame, so the page insets and the now playing bar stay where Spotify puts them; where the system
> bar is taller than Spotify's, Spotify is made to leave it the room (see "room for the glass bar").
>
> A tab picked on the system bar is passed on as a tap on the hidden Spotify item it mirrors, and the
> system bar's selection follows whichever Spotify label is painted white. Navbar.x composes the
> hidden row, so its order, hidden tabs and tabs of the mod's own carry over. Always on in the redesign.
>
> Tree (trees/home.txt): NavigationUI_TabBarImpl.TabBarView > TabBarCompactView > UIStackView of
> ElementContentView<TabBarItemElement>, each with an SPTEncoreIconView and an SPTEncoreLabel.

**`static UIImage *glyphOf(UIView *item, BOOL active) {`** (was L104)
> Encore draws a tab's icon from one SPTEncoreIcon in two states: isActive picks its filled variant.
> Both are drawn on an icon view of our own, off screen, so the images do not wait for Spotify's
> views to lay out and paint, and UITabBar swaps image and selectedImage itself.

**`static BOOL fireTapRecognizers(UIView *view) {`** (was L137)
> NavigationUI_TabBarImpl's TabBarItemElementUI answers a tap recognizer (-handleTap), so the tap is
> replayed through the recognizer's own target-action pairs, the same call a real touch ends in.

**`- (UITabBarItem *)itemAt:(CGPoint)point {`** (was L196)
> UIKit's item views are private, so the item under a touch is the one whose title label or glyph is
> nearest. With the labels hidden only the glyph is left; UIKit shows the item's own image instance.

**`static const CGFloat kFadeRise = 112;`** (was L243)
> The system bar's own view in Spotify's bar. UIKit measures the system bar and lays it out by the safe
> area of the view it stands in, and the room made under Spotify's bar is not the phone's: on a phone
> with a home button it went under the platter as well, squeezing it to 49 pt. So this view hands the
> bar the safe area without the room.
>
> It also draws the fade over the pages behind the bars. Spotify darkens whatever scrolls under its bar
> with a TabBarGradientView reaching 112 pt above the bar's top (trees/continuous/5.txt:2200), but that
> sits in the compact view hidden above, so it went with it: only the field behind a page (Kit/SGRField.h)
> faded to black, and the rows, covers and text over it ran on bright under the now playing bar and the
> glass. The fade stands under the glass bar, so it moves and goes away with the bar.

**`static const CGFloat kStockRow = 49;`** (was L325)
> UIKit's glass bar asks for 83 pt, the platter the top 62 of it, over no more safe area than a Face ID
> phone's 34 (simulator, iOS 26.5 and 27). Spotify's bar is its 49 pt row over the bottom safe area of
> TabBarContainerImpl's view: a guide from 49 pt above the safe area's bottom to the view's bottom sets
> its height (its viewDidLoad, 0x100840a2c), the now playing bar stands on that guide's top
> (MainUIContainer's chrome bottom anchor, 0x100ae0178), the bar slides away by the inset plus 49 when
> Spotify hides it (0x1037169a4) and the pages get 49 on top of the inset (0x10707bde4). A Face ID
> phone gives the view 34 and the two bars match. A phone with a home button gives it none, and so does
> Spotify's message bar (LimitedExperienceIndicatorBar: Offline, Private Session) coming in under the
> tab bar, which takes the home indicator's inset for itself: the glass bar stood 34 pt above
> Spotify's, over the now playing bar. So the view gets the rest of the glass bar's height as safe
> area, and Spotify lays its bar, the now playing bar, the pages and the hide out for the glass bar
> itself, and moves them all with the message bar.

**`static CGFloat glassHeight(UITabBar *bar, UIView *stockBar) {`** (was L339)
> UIKit asks for 62 + max(21, inset) on a phone with a home button, max(83, 49 + inset) on a Face ID
> phone, by the safe area of the view the bar stands in. SGRTabBarHost keeps the room out of that; if
> it ever reached the bar again, the bar would ask for more room every pass, so what it asks for with
> no room made is what is kept.

**`bar.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;`** (was L378)
> UIKit draws the glass in the appearance the bar inherits, and the bar is outside the navigation
> stacks Spotify makes dark itself (-[SPNavigationController viewDidLoad] while +[SPTLiquidGlass
> isEnabled]), so a phone in light mode had it light over Spotify's black. Spotify is dark whatever
> the system is, and so is the bar.

**`- (void)viewSafeAreaInsetsDidChange {`** (was L524)
> The message bar coming or going changes the view's safe area before Spotify lays the bar out for it,
> so the room follows in that same pass, and inside the message bar's animation.

## `Redesigned/NowPlayingBar/BarConnect.x`

**file overview** (was L1)
> The device button of the now playing bar, hidden on request. The redesign keeps Spotify's own buttons
> on its glass card, so the button and the way to hide it are the native look's, copied over.
>
> Tree (trees/test6.txt): the button row is a UIStackView holding Connect_EntryPointsImpl.ConnectStateView
> (the connected device) and .ConnectButtonView, each wrapped; hiding the wrapper closes the gap.
> The ConnectStateView under the title ("playing on ...") sits in InformationContainer and stays.

## `Redesigned/NowPlayingBar/BarTransition.x`

**file overview** (was L1)
> The now playing bar and the tab bar keep their glass while the player opens and closes.
>
> Spotify does not move the real bars with the player: it hides them and moves stand-ins, made once at
> the start. -[SPTBarOverlayPresentationTransition setupTransitioningContext:] takes the bar's with
> -snapshotViewAfterScreenUpdates: when the player opens, but with -[CALayer renderInContext:] into a
> UIImageView when it closes, and the tab bar's that way too when it closes over a compact tab bar.
> renderInContext: cannot draw glass (UIVisualEffectView, UIKit's tab bar platters), so every close
> showed the bar's artwork and title and the tab bar's glyphs floating on nothing, and the glass
> popped back in when the real bars returned. Checked in the simulator: a snapshot view keeps the glass,
> a rendered image loses all of it.
>
> A stand-in that is an image gets live glass behind it, copied pane by pane from the view it was
> taken of, with the image moved into a child on top, so it moves and fades with Spotify's own frame
> and alpha changes. Live glass at half alpha still renders (simulator). The tab bar's selection bubble
> is not copied.
>
> MainUI_TabBarUIImpl.CompactOverlayTransition is a Swift animator with the same stand-ins
> (npbSnapshotView, tabBarSnapshotView); which of the two 9.1.78 runs is not known, so both are hooked
> and the log says which fired.

**`static void collectPanes(UIView *view, NSMutableArray<UIView *> *panes) {`** (was L27)
> The panes to copy: glass views and UIKit's tab bar platters, whose glass is not a UIVisualEffectView.
> The source itself may be hidden: Spotify renders the closed bar and hides it again before handing
> the image over.

**`glass.overrideUserInterfaceStyle = pane.traitCollection.userInterfaceStyle;`** (was L46)
> The effect does not carry the appearance the pane was drawn in, dark for both bars, and the stand-in
> would give the copy the system's.

## `Redesigned/NowPlayingBar/NowPlayingBar.h`

**file overview** (was L1)
> The redesign's now playing bar: the glass card it becomes (NowPlayingBar.x), Spotify's device button
> on that card hidden on request (BarConnect.x), glass behind the bar's and the tab bar's stand-ins while
> the player opens and closes (BarTransition.x), and the bar's page in Mod Settings
> (NowPlayingBarSettings.m). The redesign keeps its own copy of the hide switch and its own key; the
> native look's lives in Native/NowPlayingBar/.

**`CGRect SGRNowPlayingCardFrameIn(UIView *host, CGFloat *radius);`** (was L12)
> The bar's glass card in `host`'s coordinates, with its corner radius; CGRectNull before the bar has
> been styled or while it is out of a window (NowPlayingBar.x). The bar keeps its geometry while
> Spotify hides it for the player's open and close.

## `Redesigned/NowPlayingBar/NowPlayingBar.x`

**file overview** (was L1)
> The redesign's now playing bar: the album-coloured card becomes a glass card with round artwork and the
> progress line under the text. Spotify's own labels, buttons and gestures stay in place.
>
> The full screen player morphs the bar's own card and artwork into the cover art. The bar was
> written to hand itself back to Spotify for that animation, from NowPlaying_ViewPageImpl's
> Show/CloseFullscreenAnimatedTransitioning, but Spotify 9.1.78 never runs the player through those,
> so the handback never happened and is gone; if the morph ever reads as a cut, the place to start is
> Shared/Player/PlayerEvents.h, which does fire. What does move with the player is a stand-in of the
> bar, which BarTransition.x keeps glass behind.
>
> Tree (trees/home.txt): NowPlayingBarContainerViewController.view 402x56 > NowPlayingBarViewController.view
> at {8,0} 386x56 > UIView 386x56 (the painted card) > artwork 40x40 r=4, title stack,
> progress line 370x2 at the bottom. The glass pane goes on the container's view.

**`if (glass.overrideUserInterfaceStyle != UIUserInterfaceStyleDark) glass.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;`** (was L117)
> Dark whatever the system is set to: the bar is outside the navigation stacks Spotify makes dark, and
> took the system's light glass on a phone in light mode (TabBar.x).

## `Redesigned/NowPlayingBar/NowPlayingBarSettings.m`

**file overview** (was L1)
> The Now playing page of the redesign, under Player (App/Pages.m puts it there): the bar and the
> player behind it.

## `Redesigned/Player/Player.h`

**file overview** (was L1)
> The player redesign (screen key "player"): Spotify's full screen player kept, with its controller,
> units, controls and card list, and restyled from the Kit. Every control stays Spotify's own, so its
> action, state and accessibility do too; the redesign adds the artwork field behind it, glass behind
> the header buttons, bare glyphs for previous, play and next, a lyrics glyph in the footer, and one
> screen with nothing under it: every card is collapsed and the player does not scroll. The lyrics
> come to the player itself, the way the Music app shows them, when the lyrics glyph is tapped, and
> have it to themselves while they play untouched, until a touch brings the controls back.
>
> PlayerField.x      the switch's flags and rows, the field in the background plane, the cover it reads
> PlayerArtwork.x    the cover's corners, shadow and paused shrink, the lyric preview under it hidden
> PlayerHeader.x     glass behind the close and more buttons
> PlayerControls.x   previous, play and next as bare glyphs, monospaced times
> PlayerFooter.x     share gone, lyrics, Connect and queue as one row of three glyphs
> PlayerCards.x      every card under the player collapsed, so the list closes up
> PlayerScroll.x     the list held at its top, so the player is one screen and cannot be scrolled up
> PlayerLyrics.x     the lyrics in the player: the cover as a thumbnail, the title up beside it,
> and after a few seconds untouched the lines alone on the whole player
> PlayerGestures.x   the gestures' hookup
> PlayerMorph.x      the open and close grown out of the now playing bar's card, the cover flown
> PlayerMenu.x       the ⋯ opening a menu the way the Music app draws one (SGRPlayerMenu.h), over
> Spotify's own sheet, which it reads its rows from and keeps out of sight
>
> Speed and pitch, once the redesign's own, are Shared/Player/SpeedPitch.h's; PlayerHeader.x still hands
> the more button over, so a menu opened from it is taken for the player's.
>
> Every hook installs only while Redesigned UI is on (SGRedesignedUI); the native look's do not then.
> Threading: main thread only.

**`#define SGRKeyPlayerMotion @"spotifyglass.redesign.player.movingBackground"`** (was L32)
> The artwork's colours moving behind the player (on until switched off), or the blurred artwork held
> still; the row is on the Now playing page (Redesigned/NowPlayingBar/NowPlayingBarSettings.m).

**`void SGRPlayerMenuWatchMoreButton(UIView *button);`** (was L37)
> Marks a sheet opened soon after a tap on `button`, the player's ⋯, as the one the menu takes over, and
> the button as where the menu grows from (watching it twice does nothing).

**`CGRect SGRPlayerCoverFrameIn(UIView *host);`** (was L48)
> The cover on screen as it is drawn, its paused shrink included, in `host`'s coordinates; CGRectNull
> when no cover has laid out.

**`CGRect SGRPlayerArtworkAreaIn(UIView *host);`** (was L51)
> The band that cover sits in -- the room the player gives its artwork, between the header row and the
> title -- in `host`'s coordinates; CGRectNull when no cover has laid out.

**`void SGRPlayerSetCoverHidden(BOOL hidden);`** (was L54)
> Hides the cover on screen and its shadow, or shows them again, for a stand-in to fly in its place
> (PlayerMorph.x).

**`void SGRPlayerLyricsChanged(void);`** (was L71)
> Called by PlayerLyrics.x whenever either of those two changed, so the footer's lyrics glyph follows
> (PlayerFooter.x). It returns at once when nothing changed.

**`void SGRPlayerVanish(UIView *view);`** (was L75)
> Alpha 0, no touches, hidden from accessibility, set again on every call: for Spotify's Swift views,
> which SGRSuppress cannot keep (PlayerControls.x).

## `Redesigned/Player/PlayerArtwork.x`

**file overview** (was L1)
> Player redesign: the cover sits on the field with continuous corners and a soft shadow, and shrinks
> back while playback is paused, the way the Music app's does; the lyric preview under it is the
> page's own view at the size of Spotify's room, so the line sweeps word by word.
>
> Tree (trees/clean/player/01.txt:36-43): CoverArtCellImpl > ... > CoverArtTiltView 354x354 > an
> ElementView the same size > ImageViewProxy > Encore.ImageView (clips) > UIImageView, with
> Lyrics_NPVContainerKit.LyricsContainerView under the tilt view. The ElementView is what gets the
> corners and the scale: the tilt view's own transform is left to the tilt Spotify gives it when the
> cover is inspected. The image clips, so the shadow is a plate of the Kit's behind it.
>
> The scale is identity while the player opens or closes: the bar morphs into a 354pt stand-in
> (NowPlaying_ECMKit.MaskView, 01.txt:86) and the cover under it has to match where it lands. Once
> the transition is over a paused cover springs down.

**`static NSMapTable<UIView *, UIView *> *sg_covers;`** (was L26)
> The cover of each tilt view once found. A frame Spotify sets on a scaled view becomes its scaled
> size, leaving bounds that no longer match the tilt view's, so the cover is not looked for by size again.

**`static UIView *showingTilt(void) {`** (was L69)
> The tilt view of the cover on screen: the queue is a cover per cell and the cells out of view are
> kept hidden (player/02.txt:521), so the one showing is the one in a window with nothing hidden over it.

**`for (UIView *v = tilt.superview; v; v = v.superview) {`** (was L98)
> The band is the first view over the cover as wide as the player: the cover sits inset inside it
> (01.txt:33-36, CoverArtCellImpl > UIView {0, 110, 402, 466.67} > UIView {24, 8, ...} > the tilt view).

**`static const void *kPreviewKey;`** (was L165)
> The lyric preview under the cover (Lyrics_NPVContainerKit.LyricsContainerView, 01.txt:35): Spotify's
> one line is replaced with ours, the page's own view (Redesigned/Lyrics/SGRKaraokeView.h) at the size
> of the room, so the line sweeps word by word under the artwork as it does on the full screen. The
> view dims the rest of its host while it has lines, which is Spotify's own line; a song it cannot
> time, or one with no lyrics at all, leaves it hidden and Spotify's line is back. A tap on the
> preview still goes to Spotify, whose view remains the one under ours to receive it.

## `Redesigned/Player/PlayerCards.x`

**file overview** (was L1)
> Player redesign: nothing is kept under the player. Every card (about the artist, videos, SongDNA,
> events, explore, credits, merch, the lyrics card, anything Spotify adds later) reports no height, so
> the list closes up around it and the player is one screen; PlayerScroll.x closes off the gaps the
> list leaves between them, and the lyrics come to the player itself (PlayerLyrics.x) instead of
> waiting on a card below it.
>
> A block on everything rather than a list of what to drop: the server decides which cards a track
> gets, and a new kind should not turn up under a redesigned player. The collapse is the one
> Native/Player/PlayerDeclutter.x has shipped.
>
> Tree (trees/clean/player/01.txt:385, lyrics/01.txt:996-999): every card is an Element_List.CollectionViewCell
> whose first subview is an ElementContentView naming NowPlaying_ScrollAPI, then an ElementView, then
> the card's own root: CreatorBiographyCardLayout, song-dna-npv-card, Lyrics_CardElementImpl.CardView
> id=lyrics-card-view and so on (all ten player snapshots). The cells of lists inside a card
> (WatchFeed's) name WatchFeed_ComponentAPI instead, so they are left to their card.

## `Redesigned/Player/PlayerControls.x`

**file overview** (was L1)
> Player redesign: previous, play and next as bare glyphs, the way the Music app draws them, and the
> timestamps under the slider in digits of one width, so they stop twitching every second.
>
> The glyphs are drawn over Spotify's controls rather than instead of them: each button keeps its
> action, its enabled state, its accessibility and the Gestures zones around it, and the glyph takes no
> touches. Previous and next get theirs inside the button's content view, so the button's own press
> and disabled look carry over; Spotify's icon under it goes transparent on every pass (SPTEncoreIconView
> is a Swift class, which SGRSuppress cannot keep). Play loses its white disc, a plain UIImageView the
> size of the button, which SGRSuppress keeps transparent, and the glyph over it follows the player's state.
>
> Tree (trees/clean/player/01.txt): PlaybackControlsElementsUnit's view holds
> id=SPTNowPlayingPreviousTrackButton 56x56 > UIView > StackView > StackView > SPTEncoreIconView (:257),
> id=SPTNowPlayingPlayButton (PlayButtonView 64x64, :266) > CondensedButton (a UIButton,
> objc-meta-Spotify.txt:207312) > UIImageView 64x64 and a hidden SpinnerView, next to a hidden UIView
> holding a UIImageView (:277), and id=SPTNowPlayingNextTrackButton. DurationElementUnit's view holds
> id=now-playing-time-take-label and id=now-playing-time-remaning-label, SPTEncoreLabels whose UILabel
> is id=...-internal (:227). The sticky header has a play button of its own (:492), which a search
> inside the unit's view never reaches.

**`static const NSTimeInterval kTapTrust = 1.2;`** (was L27)
> After a tap the glyph shows what the tap asked for, and a state still saying the opposite is taken for
> one sent before the player caught up, for this long; after it the player's word is final.

**`static void keepOnTop(UIView *view, UIView *host) {`** (was L63)
> Centred by the autoresizing mask as well as here: the unit lays out before the buttons in its row
> have a size, so a centre set then is the middle of nothing, (0, 0), and no later pass of the unit's
> comes to move it (trees/continuous/1.txt, 2026-09-17: glyphs at {-23.7, -14.7} in 56pt buttons).

**`static void playTapped(void) {`** (was L121)
> The player's state reaches the glyph a beat after the tap (the request goes through the player core
> and comes back as a state), which read as a slow button; Spotify's own disc turns at the touch. So the
> glyph turns at the touch too, to the opposite of what it shows, and the state settles it after.

**`%hook _TtC28EncoreConsumerMobile_BaseKit14PlayButtonView`** (was L218)
> The action the play button's own UIButton sends (objc-methods.txt: -[PlayButtonView uiButtonTapped]).
> Only the player's button turns the glyph: the sticky header and every page with a play button of
> its own use the same class.

## `Redesigned/Player/PlayerField.x`

**file overview** (was L1)
> Player redesign: the artwork field behind the full screen player, and what the switch forces.
>
> Tree (trees/clean/player/01.txt:449): NPVBackgroundViewController's view is a plane inside the NPV's
> own list (scrolling_npv_collection_view), painted the album colour with Spotify's gradients
> (NPVGradientView) stacked on it. Its top stays at the top of the content and it grows as the list
> scrolls (874 at rest, 1495 and 2144 further down, 02.txt:757, 03.txt:861), so a field inside it
> scrolls with the cards and is laid out again on every scroll frame: the hook only compares a frame.
> The field goes on top of the plane's own subviews, so Spotify's gradients are covered rather than
> fought over, and nothing depends on a repaint hook.
>
> With Moving background on (SGRKeyPlayerMotion, the default) the field is the Kit's moving field of the
> artwork's colours (SGRFlow.h) rather than the still blurred artwork; a paused song holds it still.
>
> The picture comes from the Kit's now playing artwork, keyed on the picture the playing track names
> (SGRBridges.h, issue #58): the Kit's own fetch of it, the now playing bar's 40pt cover, published by
> the Kit, and the player's own 354pt cover, published here from the cell in the middle of the
> sideways list of covers (AccessibleCollectionView, 01.txt:28, one CoverArtCellImpl per queued track,
> the ones out of view hidden). Until the first picture has been read the field takes the colour
> Spotify already has for the player, from -[NPVBackgroundViewController
> backgroundViewModel:didChangeColor:playerState:] (objc-methods.txt:57949).

**`static const UIEdgeInsets kBleed = {200, 0, 600, 0};`** (was L26)
> Past the plane's edges: above for the pull that dismisses the player, below for the bounce at the end
> of the cards.

**`showArtwork(field, NO);`** (was L64)
> Made while the player is about to open: whatever is read lands in the first frames of the
> animation, where a crossfade would only add work.

**`static UIImage *settledCover(UIScrollView *list) {`** (was L97)
> The picture of the cell under the middle of the list once it has settled: mid swipe the middle is
> between two tracks.

**`@interface SGRPlayerCoverWatcher : NSObject <SGPlayerStateObserver>`** (was L135)
> A cover that loads after the track changed sets an image and lays nothing out, so the list is looked
> at again a few times while it comes in, as the Kit does for the bar.

**`@"ios-feature-nowplaying.new_redesign_header_with_context_menu_enabled": @YES,`** (was L163)
> The header, slider and sheets the trees were recorded with (trees/clean/player/01.txt:122
> id=Context menu, :216 SPTNowPlayingSliderV2).

## `Redesigned/Player/PlayerFooter.x`

**file overview** (was L1)
> Player redesign: the footer as the Music app's row of three glyphs, lyrics, devices and queue, spread
> evenly across the player, and no share button.
>
> Spotify's footer is Connect with the device's name at the leading edge, share, and the queue at the
> trailing edge. Connect and the queue stay Spotify's controls (the device sheet, the remote device
> tint, the Jam avatars) and are only moved, by a translation of the arranged view that holds each: a
> transform survives the stack view laying them out again, and moving the holder keeps its touches
> inside its own bounds. The device name goes transparent, since the glyph alone sits in the middle.
> Spotify has no lyrics control down here, so that one is the Kit's glyph button, and it turns the
> lyrics in the player on and off (PlayerLyrics.x): filled while they are up, dimmed and dead for a
> track that has none.
>
> The row sits lower than Spotify puts it, just over the home indicator the way the Music app's does
> (issue #54): the footer unit's view is translated down, the controls follow it part of the way, and a
> band of the redesign's hands the touches below the bottom stack's bounds back to the row.
>
> Tree (trees/clean/player/01.txt:295-320): FooterElementsUnit's view 402x44 > UIStackView 382x44 >
> ElementView > ConnectButtonOutputSwitcherViewHolder id=Components.ConnectButtonOutputSwitcher 153x36
> (a 19x19 UIImageView glyph and a MarqueeLabel with the device name), a spacer, a hidden media trimmer,
> ElementView > EncoreButton id=ShareButtonNowPlayingView 44x44, ElementView > Queue control
> id=QueueButtonNowPlaying 47x32.

**`static const CGFloat kRowAboveSafeArea = 20, kRowMinBottom = 34;`** (was L33)
> Issue #54: Spotify ends its bottom stack 61pt above the screen's bottom (01.txt:127, 576.67 + 236 of
> 874), so the row's middle sat 83pt up, well clear of the home indicator, and the controls crowded it.
> The Music app keeps that row just over the home indicator: its middle this far above the safe area's
> bottom, and never less than kRowMinBottom above the screen's on a phone without a home indicator.

**`static const CGFloat kControlsShare = 0.3;`** (was L38)
> The controls follow a share of the row's move when nothing stands between them, so the gaps above
> and below them even out instead of all the room opening under them.

**`BOOL animated = glyph.window && !SGRPlayerIsTransitioning();`** (was L92)
> Lyrics turn up once the player has fetched them, well after the footer laid out: a fade, not a pop.
> While the player opens or closes the glyph and the lyrics come and go together, so nothing animates.

**`@interface SGRFooterReach : UIView`** (was L135)
> Moved down, the row is drawn partly below the bottom stack it is arranged in, and UIKit does not look
> into a view for a touch outside its bounds. This band over the part that hangs out hands such a touch
> to the row itself, and lets every other one through. It asks nothing of a row that cannot be seen, the
> stack it is in faded out included (the lines alone, PlayerLyrics.x).

## `Redesigned/Player/PlayerGestures.x`

**file overview** (was L1)
> The redesigned player's hookup of the gestures (Shared/Gestures): the double tap goes on the player's artwork list.
>
> Tree (trees/now-playing.txt): the artwork sits in AccessibleCollectionView, a full screen list of
> the queue scrolled sideways, so the recognizer goes on that and the grid is the screen. Spotify's
> controls are sibling units rather than children of it, so a tap on a button never reaches it.

**`%hook _TtC35CreativeWorkCommons_CoverArtTiltKit16CoverArtTiltView`** (was L9)
> A single tap on the cover is Spotify's way into the tilt mode, the artwork alone in 3D. That is
> the half of a double tap that misses, so while the zones are on it would open on the way to every
> gesture; the tap goes back to Spotify with the switch.

## `Redesigned/Player/PlayerHeader.x`

**file overview** (was L1)
> Player redesign: glass circles behind the header's close and more buttons, and the more button handed to
> the menus that open from it (Speed and pitch's, and the Music app style menu of PlayerMenu.x).
>
> Glass is the control layer floating over the field, so it goes behind the round buttons only: the
> playlist name between them stays a label, and the row of playback controls stays bare glyphs
> (PlayerControls.x). Each circle is a subview of the button it sits behind (SGRGlassInside), below
> what the button draws and taking no touches, so the buttons stay Spotify's, with their actions, state
> and accessibility, and the circle follows the button wherever Spotify's row puts it. Circles placed
> from the unit's layout pass instead (a backing across the unit's view) were read before the row had
> laid the buttons out and sat 24pt up and to the side until a tap laid the unit out again
> (trees/continuous/1.txt, 2026-09-17: shapes at {-10, -22} and {320, -22}; the close button is at {12, 0}
> in the unit's view, so its circle belonged at {14, 2}).
>
> The add button keeps no circle: its glyph is a circle of its own, green and filled once the track is
> saved, and on glass it read as a disc on a disc (device test, 2026-09-17).
>
> Tree (trees/clean/player/01.txt): HeaderElementsUnit's view is a 402x48 row holding
> id=now-playing-minimize-button 48x48 (:103) and id=Context menu 48x48 (:122), the playlist name
> between them.

## `Redesigned/Player/PlayerLyrics.x`

**file overview** (was L1)
> Player redesign: the lyrics come to the player itself, the way the Music app shows them. The player
> is one screen and does not scroll (PlayerScroll.x), so the footer's lyrics glyph is the only way to
> them: it shrinks the cover into a thumbnail at the top of the artwork band, lifts the track's title
> up beside it, and fades the Apple Music style lines (Redesigned/Lyrics/SGRKaraokeView.h) into the
> room that frees between the title and the progress bar. Tapping it again puts the cover back.
>
> Nothing of Spotify's is taken apart for it. The cover is the Kit's now playing artwork drawn again
> in a view of the redesign's own, flown from where Spotify's cover is drawn to where the thumbnail
> belongs, while Spotify's list of covers goes to alpha 0 underneath: one view to move instead of a
> paging list of them, and the two pictures are the same one, so the swap is not seen. The title row
> is Spotify's own unit translated, the way PlayerFooter.x moves the footer's controls -- a transform
> survives the stack view laying its arranged views out again -- with a mask over it where the controls
> it moved towards begin, so a long title fades out before them instead of running under them. The row
> of chips over it (Switch to video) goes while the lines are up, since they take the room it sits in.
>
> Tree (trees/clean/player/01.txt): SPTNowPlayingView (:26) holds the content layers, the header row
> (:91), and id=npv.bottomStackView {0, 576.67, 402, 236} (:127) whose arranged views are the
> information unit {0, 0, 402, 64} (:160, the title, the artist and the add button), the duration unit
> {0, 64, 402, 40} (:209), the controls (:240) and the footer (:295). The title is
> id=now-playing-title-label and the artist id=now-playing-subtitle-label (:174, :185), both inside one
> arranged element view {12, 2.33, 304, 43.33} of the unit's row. Every measurement here is taken from
> the views themselves, since a player with a volume row or another mode's units has other numbers.
>
> The geometry is re-applied on every layout pass of the units, since a new track rebuilds the
> elements inside them, and it is undone before the player closes: the bar morphs back into a full
> size cover, which a thumbnail would not match.
>
> With the lines up and the song playing, the controls go after a few seconds untouched and the lines
> have the player to themselves, the way the Music app leaves its lyrics alone: the header row, the
> thumbnail and the bottom stack (the lifted title row with it) fade out, and the lines' room grows
> from the band between the title row and the progress bar to the whole height of the player. The
> lines' view is laid over all of that room from the start and only its band moves
> (SGRKaraokeView's lineInsets), so the lines spring to the new anchor as they move on to a new line,
> rather than riding a view resized under them. A touch anywhere on the player brings the controls
> back, and a tap that does so does only that: it does not seek to the line under it. Pausing brings
> them back as well, and they stay while the song is paused. VoiceOver keeps them.
>
> With Sing available (Shared/Sing: switched on in Mod Settings > Karaoke, its voice model downloaded), its
> microphone (Redesigned/Lyrics/SGRSingControl.h) sits in the bottom trailing corner of the lines' band,
> opposite their own glass button, and goes down with the band when the controls go. While it is open,
> preparing or explaining itself the controls do not go, but ones that are away already stay away: a
> touch on the microphone is for it and brings nothing back, since the band it sits in would move it out
> from under the finger. The lines open with Sing available even for a song without lyrics, so the
> microphone can always be reached; switched off, or without its model, there is no microphone and a song
> without lyrics keeps its cover. Both follow the switch and the model as they change.

**`static const CGFloat kLyricsEnterScale = 0.96;`** (was L63)
> The lines are a surface arriving, not something moving: they come up from just under full size as the
> room for them opens, and go at once when it closes. An exit the eye waits through reads as a stall.

**`static const NSTimeInterval kAloneAfter = 4;`** (was L71)
> The lines alone: this long untouched while they play, and the controls go. They go slowly, being
> nothing the eye waits for, and come back quickly, since a touch asked for them.

**`@interface SGRPlayerLyricsOverlay : UIView`** (was L99)
> The thumbnail and the lines, side by side under one view so the lines' own view has no sibling of
> ours to hide: SGRKaraokeView takes the whole of whatever it is put in and dims what is next to it.

**`_empty = [UILabel new];`** (was L491)
> What the lines leave when a song has none, which only Sing opens them for. A sibling of the lines'
> view, so it goes whenever they have something to show (SGRKaraokeView's syncSiblings).

**`- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {`** (was L511)
> The lines seek when they are tapped and the thumbnail takes no touches, so everywhere else the
> overlay would only swallow them: a view that takes touches does, even with nothing on it.
>
> What it hands them to instead is the title row. Translated to the top of the player it is drawn well
> outside the stack view it is arranged in, and UIKit stops looking at a view whose bounds the touch is
> not in, so the add button and the menu that rode up with it are past Spotify's own reach. Asked here
> directly, the row answers for where it is drawn.
>
> The stage is as tall as the lines' room with the controls away, and the lines take touches only in
> the part they have now, so the stage swallows none either. With the controls away the row is not
> there to be asked: a touch goes on to the player, whose watcher brings them back.

**`- (SGRKaraokeView *)lyrics {`** (was L530)
> Made on the first tap and kept afterwards: it measures the song for its width before it can place a
> line, so a view built again on every tap would show nothing for the first frames. Out of the window
> it costs nothing -- its display link only runs while it is in one.

**`if (overlay.superview != host) [host addSubview:overlay];`** (was L553)
> On top of the player: it reaches from under the header row down to the progress bar, so it is over
> the covers and the gradients and clear of every control. Under them instead, the mixing background
> Spotify keeps between the two (01.txt:72) would be free to draw over the lines.

**`UIView *header = sg_header.viewIfLoaded;`** (was L596)
> With the controls away: from the header row's top, just under the status bar, down to the home
> indicator. The lines fade out at both ends, so nothing needs clearing beyond that.

**`static UIEdgeInsets bandOf(SGRLyricsLayout l, BOOL alone) {`** (was L607)
> The lines' part of the stage: the band between the title row and the progress bar while the
> controls are there, all of it while they are away.

**`static CGFloat trailingEdgeIn(UIView *info) {`** (was L616)
> Where the row's trailing controls start, in the unit's coordinates: the nearest arranged view on the
> trailing side of the title that is still there to be seen. The title may not reach it.

**`static void clipTitle(UIView *element, CGFloat width) {`** (was L631)
> The title moved right by the thumbnail would run into the add button beside it, and it cannot simply
> be narrowed: Spotify lays its marquee labels out with constraints, which put the width back the next
> time anything in the row lays out -- and a long title, being a marquee, lays out often. A mask on the
> element takes no part in that, so it holds between passes, and it fades the title out where Spotify's
> own fade would have been rather than cutting it.

**`static void showControls(CGFloat alpha, SGRPlayerLyricsOverlay *overlay) {`** (was L680)
> Everything the lines leave the player to: the header row, the bottom stack with the title row lifted
> out of it, and the thumbnail. Alpha on the header unit's view and the stack, never hidden: views
> inside Spotify's stacks crash when hidden, and at alpha 0 UIKit hands them no touches either.

**`static void placeSing(SGRPlayerLyricsOverlay *overlay, SGRLyricsLayout l) {`** (was L697)
> Sing's microphone in the corner of the band the lines have now. Held, it keeps the controls from going
> and lets the count start over once it lets go.

**`static BOOL mayGoAlone(void) {`** (was L737)
> The lines on the player and the song playing, with nothing over the player and no one listening to
> its controls with VoiceOver.

**`static void scheduleAlone(void) {`** (was L753)
> Counts the time untouched from now. A timer that finds the lines not in (a track still bringing its
> own) or a sheet over the player starts over. One that finds the song paused or the app away lets it
> be, so a locked phone playing on is not woken for it: playing again starts it (SGRPlayerLyricsWatcher),
> and so does the app coming back (the %ctor).

**`@interface SGRPlayerTouchWatcher : UIGestureRecognizer`** (was L778)
> Sees every touch that starts on the player and leaves it to whatever it was meant for: it fails as
> the touch begins, so it holds nothing up, cancels nothing and stands in no gesture's way, the pull
> that closes the player included.

**`static void place(SGRPlayerLyricsOverlay *overlay, UIView *host, SGRLyricsLayout l) {`** (was L817)
> Puts the overlay's own views where the measurements say, without animating. The thumbnail is laid out
> at the size and place Spotify draws its cover at and moved by its transform alone, so a pass that
> runs while it is up leaves it exactly where the eye has it: the two are worked out from one
> measurement. Bounds and a centre, not a frame, since both views can be under a transform.

**`static CGAffineTransform thumbTransform(SGRLyricsLayout l) {`** (was L835)
> Where the thumbnail's view has to go to land on `l.thumb`, as a transform about its own centre: the
> shadow and the corners travel with it that way, instead of a shadow redrawn on every frame.

**`static CGFloat thumbRadius(SGRLyricsLayout l, BOOL open) {`** (was L844)
> The corners as they will be drawn: a radius under a scale is drawn scaled, so the thumbnail asks for
> the radius it wants divided by the shrink, and the two ends of the animation are 12pt and 8pt corners.

**`UIImage *picture = SGRNowPlayingArtwork(NULL, NULL);`** (was L864)
> The thumbnail is the Kit's picture drawn again, and Spotify's cover goes as it appears: without a
> picture there would be a hole where the cover was, so the cover stays and the lyrics wait.

**`SGRPlayerCoverList().alpha = 0;`** (was L896)
> Spotify's cover goes the moment the redesign's own takes its place: the same picture at the
> same size with the same corners, so there is nothing to see in the swap. Coming back it waits
> for the thumbnail to land on it, or the two would be on screen at once, one of them half size.

**`static void replace(void) {`** (was L947)
> A layout pass, a new track or a turn of the phone: the state is put back where it belongs without
> animating, since the frames it is measured from have just changed.

**`%hook _TtC20NowPlaying_ModesImpl20FloatingElementsUnit`** (was L1051)
> The chips over the title (Switch to video and whatever else a track brings) sit in the middle of the
> room the lines take, so they go while the lines are up. The row keeps its height: the rest of the
> bottom stack stays where it was, which is the whole point of lifting only the title out of it.

**`static void awaitLyrics(void) {`** (was L1064)
> Lyrics arrive a moment after the track does: the glyph is asked again while they would be coming, and
> the lines already up wait out the same grace before they go. Not in the background, where Spotify may
> not ask for lyrics until the app is back, so coming back starts it over.

**`static void singAvailabilityChanged(void) {`** (was L1080)
> Sing switched on or off in Mod Settings > Karaoke, or its voice model arriving or going: the lyrics' glyph and
> the microphone follow at once, and lyrics that were open only for Sing put the cover back.

## `Redesigned/Player/PlayerMenu.x`

**file overview** (was L1)
> Player redesign: the ⋯ opens a menu drawn the way the Music app draws its own (SGRPlayerMenu.h) in place
> of Spotify's sheet of rows -- while what is in it, and what each row does, stay Spotify's.
>
> **Why Spotify's sheet still opens.** The rows come from Swift item factories with no way in, and which
> there are depends on the track, where it plays from (Remove from this playlist only in one's own), the
> account, the market and the flags, and on what is playing at all (an episode has rows of its own); each
> is in the app's language and does something only Spotify's own code knows how to. A menu of hand-written
> actions would be the trap Redesigned/Playlist/PlaylistMenu.x describes. So the ⋯ opens Spotify's sheet as
> it always did and the sheet is the menu's source: it is kept out of sight from the moment its presentation
> begins -- its presented view and its dimming hidden, the sheet taking no touches -- its rows are read off its table, and the card is put over it
> in the presentation's container, grown out of the ⋯.
>
> **Spotify's rows** (trees/continuous/1.txt:648): each cell of ContextMenuTableView holds an Encore ListRow,
> a UIControl (ListRow < Layout < Box < PassthroughControl) whose accessibility identifier is the item's
> number -- 9 Share, 11 Add to Queue, 19 Add to playlist, 27 Remove from this playlist, 28 Lyrics, 34 Go to
> Queue, 59 Exclude track from your taste profile -- with its glyph and its words in it. The number is what
> places a row on the card (kKnown); a number the table does not know goes under More, in Spotify's order,
> so nothing Spotify offers is lost and nothing added later has to be known here first. Every number seen
> is logged once, with its words, for the table to grow from. The table's binder
> (ContextMenuItem.TableBinder, 9.1.78) answers the data source and willDisplayCell: only -- there is no
> didSelectRowAtIndexPath: -- so a row is fired through its ListRow (SGRActivate), as a tap would. Only the
> cells on screen exist, and the hidden table is as short as the sheet would have been, so it is made tall
> enough for all of them for the moment they are read or a row is fired, and put back.
>
> **What Spotify then does** is what it always does: it dismisses the sheet and acts (the card goes with the
> sheet), or pushes a page of its own onto the sheet (Share's destinations, a list of artists) -- the sheet
> is then shown the way Spotify drew it and the card goes -- or changes the row in place (Lyrics • Off to
> On), which the card reads again. A tap outside the card dismisses the sheet, as a tap on Spotify's dimming
> did.
>
> **Where it falls back** to Spotify's sheet as it was: no table in it, rows in the table the card cannot
> read, a row tapped before Spotify's rows are in that they are still not in kRowsWait later, and a row that
> cannot be found again to fire. Spotify's rows take as long as its slowest item factory, up to
> ios-feature-contextmenu-platform.timeout (10 s unless the server says otherwise), so the card waits for them
> for as long as it is open: when it gave up at kRowsWait whatever was happening, a slow menu turned into
> Spotify's sheet in the hand of someone moving Speed and pitch's sliders (device, 2026-09-25).
>
> **Opening at once.** Spotify's rows come in only once its item factories have answered, a moment after the
> sheet is up, and a card that waited for them opened on a spinner (device, 2026-09-24). So the card opens
> on the rows the last menu had (kept across launches, kLastRowsKey), which are nearly always the rows this
> one gets, and moves to Spotify's as they come in where they differ; a tap on a row before then is held and
> fired once they are in. The table is looked at every kRowsPoll until they are, since a hidden sheet's
> table can fill without the menu laying out.
>
> Which sheet is the player's: one that appears within kMenuAfterTap of a tap on the player's ⋯, which
> PlayerHeader.x hands over. Speed and pitch (Shared/Player) still puts its block into the hidden sheet; the
> card has a row of its own for them that opens onto the same sliders (SGSpeedPitchPanelMake).

**`static const NSTimeInterval kRowsWait = 4;`** (was L57)
> A row tapped before Spotify's rows are in and still not fired by then, and Spotify's own sheet is shown
> instead, with whatever it is showing; rows in the table the card still cannot read by then, likewise.

**`static const SGRPlayerMenuKnownRow kKnown[] = {`** (was L91)
> Numbers read off the ListRows of 9.1.78 (trees/continuous/1.txt:650-716). The glyphs are the Music app's
> for the same thing where it has one.

**`if ([button isKindOfClass:UIControl.class]) {`** (was L136)
> An Encore button may read its touches through a gesture recognizer rather than as a control, so both
> are watched, as Speed and pitch watches it.

**`static void withEveryCell(UITableView *table, void (^block)(void)) {`** (was L223)
> Runs `block` with every row of the table laid out: the hidden table is as short as the sheet would be,
> and only its cells on screen exist, so for the moment of the block it is as tall as its content. A table
> that has just taken its rows has not measured them yet -- its content size is the old one until it lays
> out, and reading it then got 9 of 15 rows (harness, 2026-09-24) -- so it is laid out first, and grown
> again for as long as the rows it then measures run past it.

**`static NSArray<SGRPlayerMenuSpotifyRow *> *readRows(UITableView *table, BOOL *complete) {`** (was L250)
> `complete` says whether every row of the table had a cell to read (a cell that is not one of Spotify's
> item rows is passed over, and does not make the read incomplete).

**`static void hideSystemDimming(UIView *container) {`** (was L392)
> The sheet and Spotify's dimming out of sight, by `hidden` and, on the sheet, a mask that lets nothing
> through; never by alpha or colour. The sheet's presentation sets its presented view's alpha back to 1
> whenever the container lays out (the harness saw it after every change of the card's height), the
> dimming's colour and alpha are what Spotify's transition animates, and iOS 26 draws a sheet's glass
> through a mask of no size at all, so the mask is a point of nothing rather than empty. The sheet's own
> mask, if it had one, is kept to put back. The catcher draws a lighter dimming of its own.
>
> UIKit's own dimming goes too, wherever the system sheet put it: in the sheet's container, where Spotify
> hides it once the sheet is up (trees/continuous/1.txt: "UIDimmingView ... hidden"), and over the view the
> sheet came up over, which UIKit wraps in a drop shadow view of its own with a UIDimmingView in it, black
> at 0.48 (harness, 2026-09-24). Under Spotify's 0.7 neither showed; with Spotify's hidden, the screen went
> dark for a moment as the ⋯ was tapped (device, 2026-09-24). They sit within three levels of the window.
> Those outside the container are put back with the sheet; the container's stays hidden, as Spotify keeps it.

**`static void placeCard(SGRPlayerMenuTakeover *t, UIView *container) {`** (was L475)
> The card's frame: its top trailing corner at the ⋯'s, so it grows out of the button as the Music app's
> menus do, and no taller than the room under it.

**`static void hold(SGRPlayerMenuTakeover *t, SGRPlayerMenuSpotifyRow *row) {`** (was L526)
> A row tapped before Spotify's rows are in waits for them, and past kRowsWait it is Spotify's sheet that
> is waited on instead, where the row can be tapped again once it is there.

**`if (complete) {`** (was L696)
> Only a whole menu is kept for the next one to open on, and a held tap waits for the whole menu
> before it is given up.

**`[t.card layoutIfNeeded];`** (was L723)
> The rows just replaced have never been laid out: frame them at the size they are about to have,
> or the animation below walks them, from nothing at the card's corner, to where they belong.

**`dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kRowsWait * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{`** (was L783)
> Spotify's rows are waited on for as long as the card is open, the table looked at until they are all in.
> What is worth saying by kRowsWait is whether they are late, and whether they are there and unreadable.

**`static NSString *darkness(UIColor *color) {`** (was L802)
> A dark picture across the screen flashed as the menu opened on the phone, with the sheet and its dimming
> out of sight from the presentation's first frame (device, 2026-09-24). So the first menus of a launch say
> what they find at a few moments after the ⋯'s tap: every view drawn dark over most of the window, and the
> windows themselves.

**`%hook _TtC22NavigationUI_SheetImpl27SheetPresentationController`** (was L850)
> The sheet and its dimming go out of sight as the presentation begins, before its first frame: the menu's
> own appearance comes later than that, and hiding them only from there let the dimming's black and the sheet
> show for a frame or two as the ⋯ was tapped (device, 2026-09-24). A presentation taken this way is claimed,
> and the menu inside it is taken over whatever the timing of the tap.

## `Redesigned/Player/PlayerMorph.x`

**file overview** (was L1)
> Player redesign: the player grows out of the now playing bar's card and the cover flies out of the
> card's artwork, the way the Music app opens its player, instead of Spotify's slide up and fade.
>
> Spotify 9.1.78 runs the open and the close through SPTBarOverlayPresentationTransition: it hides the
> real bar and tab bar, moves stand-ins, and sets -setProgress: (0 the bar, 1 the player, clamped) on
> every frame of its own display link, from a spring when tapped and from the finger when dragged
> (setProgress: at 0x109815464). There it sets the player's frame to the container's bounds moved down by
> the bar's bottom edge times (1 - progress), and the player's alpha, and moves and fades the bar's stand-in.
>
> The morph rides on that progress, after Spotify's own, so taps, drags and cancelled drags follow:
> the sheet   a rounded rect from the card's frame and radius to the screen's, filled with the
> field's colour, under the player, showing at once;
> the player  masked to the sheet, its content scaled and moved so its top left is the sheet's
> (sublayerTransform, and the frame's top moved to the sheet's; Spotify's gesture code
> reads back only the frame's height), its own background colour lifted off meanwhile
> (a sublayerTransform does not move it), and faded in over the first part of the growth;
> the bar     Spotify's stand-in riding the sheet's top edge, gone by a quarter of the way;
> the cover   a copy flown from the card's artwork to the player's cover, moved within the sheet,
> the player's own cover and shadow hidden meanwhile.
> All of it is taken down in -destroyTransitioningContext, which Spotify calls from -animationEnded:.
>
> Skipped on a regular width (Spotify's iPad branch), with Reduce Motion on, or while the bar has no
> card (hidden, not styled yet): Spotify's own transition then runs untouched.

**`_overlayColor = CGColorRetain(overlay.layer.backgroundColor);`** (was L102)
> The player's own paint is not a sublayer, so the content's transform would leave it where Spotify
> put the player, a band below the sheet's top edge; the sheet paints instead.

**`CGPoint origin = CGPointMake(_spotifyFrame.origin.x, sheet.origin.y);`** (was L141)
> The player's top goes to the sheet's: a mask clips nothing above the layer's bounds, so content
> raised above Spotify's frame would show square corners. Spotify reads back only the player's
> height (0x109815b4c, 0x109815c28), which stays.

**`CGRect from = CGRectOffset(self->_barArtwork, -self->_card.origin.x, -self->_card.origin.y);`** (was L177)
> Worked out relative to the sheet, so the cover stays on it the whole way rather than
> heading for where the player's cover is while that is still below the screen.

## `Redesigned/Player/PlayerScroll.x`

**file overview** (was L1)
> Player redesign: the player never scrolls up. Scrolling stays on because Spotify's dismiss pull rides on
> the list's own pan and starts only at its top, so the offset is clamped instead; the insets stay
> Spotify's, since changing one mid-drag moves the offset under the finger.

## `Redesigned/Player/SGRPlayerMenu.h`

**file overview** (was L1)
> The player's ⋯ menu drawn the way the Music app draws its own: a pane of glass grown out of the button,
> a row of up to three tiles across its top (a glyph over its words), then groups of rows split by a
> hairline, each row a glyph at the leading edge with its words and a line under them, a destructive row
> in red, and rows that open in place, onto rows of their own (More) or onto a view of the caller's (Speed
> and pitch). What the rows are and what they do is the caller's -- PlayerMenu.x reads them off Spotify's
> own sheet -- so this only draws them and says which was tapped.
>
> Laid out by hand at a fixed width; taller than maxHeight, the content scrolls inside the pane.
>
> Ownership: the caller keeps the card; the items are kept by the rows made for them.
> Threading: main thread only.

**`@property (nonatomic, copy) NSArray<SGRPlayerMenuItem *> *children;`** (was L23)
> A row that opens in place instead: onto `children`, or onto the view `makeExpansion` makes the first
> time it opens, `expansionHeight` tall.

**`@property (nonatomic, copy) NSString *key;`** (was L28)
> Names the row across -showSections: calls, so a row that was open stays open and -setSubtitle:forKey:
> can find it.

**`@property (nonatomic, copy) void (^sizeChanged)(SGRPlayerMenuCard *card);`** (was L47)
> Called when the content's height changed (a row opened or closed, a subtitle grew a line), from inside
> the animation when there is one, so the owner's new frame animates with it.

**`- (void)growFrom:(CGPoint)anchor;`** (was L63)
> Grown out of `anchor`, a point in the card's own coordinates (where the ⋯ is), or faded in under Reduce
> Motion; and taken away the other way, `completion` called once it is gone.

## `Redesigned/Player/SGRPlayerMenu.m`

**`const CGFloat SGRPlayerMenuWidth = 272;`** (was L5)
> The Music app's menu, measured off a screenshot of it on iOS 26 (a 402pt wide phone): 250pt wide, rows
> 36pt apart inside a group with a few points above and below it, the glyph centred about 30pt in and the
> words from about 56pt, groups split by a hairline inset from both edges. The card is a little wider,
> since Spotify's words run longer than the Music app's and Speed and pitch has sliders to fit.

**`NSMutableArray *_plan;`** (was L307)
> What the scroll view holds, top to bottom: tiles rows, rows, their expansions and the hairlines
> between groups; NSNull marks a group's padding.

## `Redesigned/Playlist/Playlist.h`

**file overview** (was L1)
> The playlist redesign: Spotify's playlist page kept, with its controllers, its header and its list, and
> laid out the way the Music app lays a playlist out. Liked Songs and a playlist of the user's own are the
> same page (trees/clean/liked-songs/01.txt, own-playlist/01.txt: one FTPViewController, one
> SPTFreeTierPlaylistEncoreHeaderViewController), so one redesign covers all three. Album and artist pages
> are built by another framework and are left alone.
>
> PlaylistField.x   the artwork field behind the whole page, the artwork it is read from, the flags
> the screen forces
> PlaylistHeader.x  the header: the cover full bleed at the top dissolving into the field, the title,
> the creator and the length centred under it, and one row of glass controls --
> shuffle, a prominent Play capsule, add, and more where Spotify still has it
> PlaylistRows.x    the track rows on the field with no surface of their own, rounded artwork, a
> hairline between them, and the curation pills collapsed
> PlaylistMenu.x    Sort and Mix, the two of the curation pills the ⋯ menu does not already offer,
> put on that menu's own sheet
>
> Every hook installs only while Redesigned UI is on (SGRedesignedUI); the native look's do not then.
> Threading: main thread only.

**`void SGRPlaylistTakeCuration(UIView *cell);`** (was L25)
> The page keeps the curation row the cell `cell` is laying out, so the ⋯ sheet has Spotify's own Sort and
> Mix buttons to fire once the list has scrolled past them. Does nothing for any other cell.

**`void SGRPlaylistTakeSort(UIView *page, UIView *button);`** (was L28)
> And keeps Spotify's own Sort button from the header's find-on-page toolbar, which sorts the same list
> and, unlike the pill, is in the header rather than in a cell the list reuses.

**`UIViewController *SGRPlaylistHeaderOf(UIView *view);`** (was L32)
> The playlist page `view` is on, or nil: SPTFreeTierPlaylistEncoreHeaderViewController's own view, the one
> the tree names PL.Header, for anything under the header, and FTPViewController's view for the list.

**`UIView *SGRPlaylistPageOf(UIView *view);`** (was L35)
> The page `view` is on -- FTPViewController's own view, the one the field and the pinned ⋯ belong to --
> or nil when it is on no playlist page.

**`UIColor *SGRPlaylistFieldColor(UIView *view);`** (was L39)
> PlaylistField.x. The field belongs to the page `view` is on, found by walking up from it, so two playlist
> pages on the navigation stack keep a field each.
>
> The colour the page's field is showing, SGRNeutralField() before one has been read: what the header's
> cover has to dissolve into for there to be no seam.

## `Redesigned/Playlist/PlaylistField.x`

**file overview** (was L1)
> Playlist redesign: the artwork field behind the whole page, and what the switch forces.
>
> Tree (trees/clean/playlist/02.txt:23 and :1096): FTPViewController's view holds the list
> (ListUXPlatform_FreeTierPlaylistImpl.FTPTouchCancellingCollectionView, id=SPTFreeTierPlaylistTableView,
> the size of the window) and, after it and so over it, the header (id=PL.Header). Neither scrolls the
> other: the list keeps its frame and the header's y runs from -134 at rest to -529 scrolled, so a field
> put behind both stays still while the cover at the top of the header slides up over it -- which is what
> the Music app does with the page colour.
>
> So the field is the page's bottom-most view, the size of the view and bleeding past it, with no backdrop
> of its own: the sharp cover at the top of the header is the picture, and PlaylistHeader.x fades it into
> exactly this field's colour. What Spotify paints over the field -- the page, the list and every row, all
> of them the base surface -- is kept clear by the Kit's repaint hook while sgr_playlistRoot is this page.
>
> The colour is read from the cover the header shows (PlaylistHeader.x hands it over), and until that has
> loaded the field is the neutral one, as it is for a playlist with no cover at all.

**`SGRRevealHold(page, SGRRevealPage);`** (was L65)
> Behind a curtain until the cover, the field's colour, the header and the first track are all in, so the
> page comes in at once rather than a piece at a time (Kit/SGRReveal.h). A playlist is always laid out by
> the redesign, so it waits for all of them from the first pass.

**`- (void)viewWillAppear:(BOOL)animated {`** (was L75)
> The page the repaint hook keeps clear is the one on screen; another playlist pushed over this one sets
> itself from its own pass, and this one sets itself again when it comes back.

**`%hook _TtC35ListUXPlatform_FreeTierPlaylistImpl32FTPTouchCancellingCollectionView`** (was L84)
> The list paints itself the base surface from its own pass rather than through a layer that the repaint
> hook would hear about, so it is cleared where it is laid out.

**`@"ios-feature-freetierplaylist.context_menu_in_navigation_bar_enabled": @NO,`** (was L99)
> More stays in Spotify's own header row, concealed with the rest of the block, and the redesign
> pins its own glass ⋯ over the page (Kit/SGRActionRow.h). Moving it into the navigation bar --
> which this flag is Spotify's own way of doing, and which the redesign forced until 2026-09-20 --
> put it somewhere Spotify empties on the way down the page: scrolled, the bar's trailing slot held
> an empty 48x44 view and there was no ⋯ anywhere (trees/continuous/1.txt, issue #57).

**`@"ios-feature-freetierplaylist.pin_curation_actions": @NO,`** (was L107)
> The curation row keeps Sort and Mix and gives the rest up to ⋯ (PlaylistRows.x). It scrolls away
> with the tracks rather than pinning itself over them, as the Music app's sort does.

## `Redesigned/Playlist/PlaylistHeader.x`

**file overview** (was L1)
> Playlist redesign: the header the Music app gives a playlist (iOS 26.4). The cover runs full bleed across
> the top of the page and dissolves into the page's colour; the title, the creator and the length are centred
> on the bottom of that dissolve; under them one row -- shuffle, a white Play capsule, and save (someone
> else's playlist) or download (one's own, Liked Songs) -- and the description last.
>
> Tree (trees/clean/playlist/01.txt:640-869). Spotify's header is id=PL.Header, and at rest its
> HeaderContentLayout starts at the very top of the page. It holds exactly two things:
>
> Components.Header.UI.ArtworkImage   a ShadowContainer, the cover square, centred at {80, 68} 243x243
> the block                           a plain UIView at {0, 327} 386x178: a column of title, description,
> creator row and length, and under it the action row
>
> A mix Spotify makes (Indie Rock Mix, Discover Weekly) is laid out the same way but draws its cover
> differently: there is no artwork square, and in its place a HeaderFullbleedCentralView holds the picture
> full bleed with Spotify's own big title over the bottom of it (trees/continuous/4.txt:1066). So the cover
> is whichever of the two the layout has, and the block is the one thing that is neither.
>
> Nothing is measured from what the header shows: -[SPTFreeTierPlaylistEncoreHeaderViewController update]
> counts a stored fullHeaderHeight and pins headerViewHeightConstraint to it. So the redesign changes no
> height: the cover's square is where the full bleed picture goes, and the block keeps its place, its size
> and its fading as the header collapses.
>
> What is in the block is the redesign's own (the Kit's SGRHeaderInfo), not Spotify's rearranged. Moving Spotify's
> column and controls meant answering every layout pass of theirs -- stacks re-arranging, Auto Layout putting
> frames back, buttons flashing where Spotify wanted them -- so Spotify's contents of the block are concealed
> whole and one view of the redesign's own is drawn in their place, which nothing of Spotify's lays out. It
> reads what it shows from the page's view model (FTPViewModelImplementation: the name, the description,
> whose playlist it is; device 2026-09-18) and from Spotify's concealed labels where the model has no getter
> (the creator, and the length line, already in the app's language). Its buttons draw Spotify's glyphs and
> fire Spotify's own concealed controls, so every action, state and language stays Spotify's.

**`static const CGFloat kDissolve = 0.46, kTopScrim = 140, kTopScrimAlpha = 0.28;`** (was L36)
> How much of the cover's height the dissolve into the field covers, and the scrim over the top of it that
> keeps the status bar and the back button legible on a bright picture.

**`static const CGFloat kMinHero = 120, kMinCover = 80;`** (was L39)
> A header whose cover square is smaller than this is one mid collapse or mid load, not one to measure
> the hero from; and an artwork view narrower than this is a placeholder glyph rather than the cover.

**`UIView *SGRPlaylistPageOf(UIView *view) {`** (was L55)
> The page the header is on: FTPViewController's own view, which holds the field, the list and the header
> and does not scroll. Walked from the header rather than taken off sgr_playlistRoot, so a playlist under
> another one on the stack pins its own ⋯ and not the one on top.

**`static void conceal(UIView *view) {`** (was L74)
> Invisible for good, whatever Spotify does to it. It fades its cover square and its colour wash back in
> from the scroll itself (trees/continuous/1.txt, 2026-09-17), which a hidden layer shrugs off; but pressing
> Play reconfigures the header, and that shows the wash, the find bar and the play disc again with
> -setHidden:NO, which writes the layer's own hidden and so undid this: the wash came back over the
> picture as a dark band and the green disc beside the capsule (trees/continuous/1.txt, 2026-09-18).
>
> So two things, each for what the other cannot do. `hidden` on the layer costs nothing while it holds --
> the layer is not drawn at all -- and, unlike -[UIView setHidden:], tells neither KVO nor the stack views,
> which is what makes it safe on Spotify's Encore layouts. An empty mask is what holds when Spotify shows
> the view anyway: nothing Spotify does to these views touches a mask, and a layer masked by nothing draws
> nothing. The album page found the same (Album/AlbumHeader.x) and masks its gradients.

**`@interface SGRPlaylistHero : UIView`** (was L103)
> The picture across the top of the page, a scrim over its top for the status bar, and its bottom masked
> away so the field shows through whatever colour it is at that height: pulled down, the hero ends where
> the field is already fading to black, and a fade to the field's flat colour showed as an edge.

**`- (void)followCover:(UIImageView *)source;`** (was L109)
> The cover in Spotify's artwork view, and every cover it puts there afterwards: the hero keeps itself
> right, rather than being handed a picture on each of the header's passes and staying empty between them.

**`- (void)takeCover:(UIImageView *)source late:(BOOL)late {`** (was L165)
> Spotify loads the artwork at the size the cover square is asking for, and the square shrinks as the
> header collapses: scrolled down it swapped a 105px copy in for the 254px one and the picture across the
> top of the page went soft with it (trees/continuous/2.txt, 2026-09-17). So a copy is taken only while the
> square is still at full size, which is the only time Spotify asks for one worth showing.
>
> `late` is a cover that arrived after the header had laid out -- a playlist opened for the first time,
> whose artwork is still being fetched while the page is already on screen. The log line says once that the
> watch, and not one of the header's passes, is what filled the hero.

**`static UIImageView *coverImageIn(UIView *cover) {`** (was L191)
> The image view of Spotify's artwork square: the one with the cover in it, or, before the cover has been
> fetched, the empty one it will land in, so it can be watched from the first pass.

**`static void applyHero(UIView *layout, UIView *cover, UIView *plane, UIView *block, CGFloat reach, CGFloat stretch) {`** (was L205)
> The hero sits in the plane Spotify's colour wash is drawn on, which slides away as the header collapses, so
> Core Animation carries it and its frame is only measured at rest: reading the header per frame flickers.
> Pulled down past the top the plane grows and the hero stretches with it, bottom kept in place.

**`CGFloat bottom = MAX(kMinHero, round(height + reach)) + stretch;`** (was L227)
> On past the block's top by `reach`, so the title sits on the bottom of the dissolve the way the Music app
> sets it on the picture. `reach` comes from the block at rest (applyHeader).

**`static id viewModelOf(UIViewController *headerVC) {`** (was L241)
> The page's view model: the header controller's defaultHeaderViewModel, FTPViewModelImplementation on every
> playlist, Liked Songs and a shared playlist alike (device, 2026-09-18). Its getters are plain ObjC --
> playlistName and playlistDescription @, isOwnedBySelf B, formatListType @ (Spotify 9.1.78) -- and each is
> checked before it is called, so a Spotify without one shows Spotify's text for it rather than crashing.

**`static NSString *creatorIn(UIView *block) {`** (was L292)
> The creator is on no getter of the page's model; Spotify's own creator row has the name beside the facepile
> (its avatars, whose initial is a one-letter label of its own: "D | Darkk" on the device, 2026-09-18). A
> shared playlist's reads "Darkk" as well, with the others in the facepile. Looked for no further up than the
> facepile's own row, where the title would be the next label found.

**`static void showPlaylist(SGRHeaderInfo *info, UIView *block, UIView *root, id model) {`** (was L314)
> What the playlist's header shows: the name and the description from the page's model, the creator and the
> length from Spotify's concealed labels, and on Play's right save for someone else's playlist, download for
> one's own and for Liked Songs, which Spotify reports as neither owned nor unsaved (isOwnedBySelf NO,
> formatListType liked-songs).

**`[info showCreatorLink:SGRFindByIdentifier(block, @"Components.PlaylistHeader.collaboratorsButton", &kCreatorKey)];`** (was L334)
> Whoever made the playlist, opened from the line that names them. Spotify's own button carries the
> facepile and the name and takes the tap to a profile -- or, for a playlist several people are on, to
> the picker it opens itself (issue #56).

**`UIView *page = SGRPlaylistPageOf(root);`** (was L339)
> More, pinned over the page rather than left in the block, which is concealed and scrolls away; and
> Spotify's own Sort, from the find-on-page toolbar this header conceals, for the ⋯ sheet to fire.

**`static SGRHeaderInfo *applyInfo(UIView *block, UIView *headerRoot, UIViewController *headerVC) {`** (was L372)
> The block's own content goes, whole, and the redesign's takes its place. Spotify adds to the block as the page
> loads and shows parts of it again when Play is pressed, so everything of Spotify's in it is concealed on every
> pass and again from the block's own pass; concealing is idempotent and costs nothing once done.

**`SGRHeaderInfo *info = objc_getAssociatedObject(headerRoot, &kInfoKey);`** (was L376)
> One per page, kept on the header's root: if Spotify ever hands over another block, the same view moves
> into it rather than a second one being drawn beside the first.

**`reapplyOnPass(SGRFindByIdentifier(block, @"HeaderActionsRow", &kRowKey), &kRowWatchedKey, block, headerRoot, headerVC);`** (was L398)
> Save arrives after the header has laid out on a playlist opened for the first time, in a row that lays
> nothing else out: Play's right drew download, or nothing, until the page was opened again (issue #19). The
> row's own pass is watched too, a plain UIStackView, as the album's and the artist's are.

**`static void glassUp(UIView *box, const void *key) {`** (was L407)
> Find on this page and Sort sit above the cover, shown as the page is pulled down. They stay Spotify's own
> controls, so the tap opens Spotify's find page; only the grey box becomes glass.

**`static void applyScrims(UIView *headerRoot) {`** (was L432)
> Two scrims Spotify fades in under the navigation bar as the page scrolls, each tinted with its own colour
> for the page rather than the field's: LiquidGlass.gradientContainer (124pt, a child of HeaderLayout) and
> the HeaderNavigationBar's GradientView. On Liked Songs the first is Spotify's blue, a band across the top
> of a black page (trees/continuous/2.txt, 2026-09-18). UIKit's own scroll edge effect is still there under
> the bar and keeps the back button legible, as on Home, Search and Library. Concealed rather than faded:
> Spotify writes their alpha on every step of the scroll, and the navigation bar's with -setHidden:.

**`if (objc_getAssociatedObject(headerRoot, &kBarScrimKey)) return;`** (was L440)
> A concealed view stays concealed, so the bar is looked for until it is found and then never again:
> the header lays out on every step of its collapse.

**`static UIView *applyBackground(UIView *layout) {`** (was L453)
> Spotify's colour wash goes, so the page's field shows through, and the plane it was drawn on is handed
> back: it is where the hero belongs (applyHero).
>
> The wash is a gradient on a plain view of its own, and that view is painted the base surface. Spotify
> keeps it at alpha 0 on an ordinary playlist, so concealing the gradient was enough; with the Mix feature
> turned on it raises the alpha and the view -- opaque black, drawn after the hero -- covered the picture
> whole (device, trees/continuous/1.txt 2026-09-20, issue #53). So the paint comes off everything on the
> plane as well, which is the same thing the field does to the rest of the page. The hero is left alone:
> the picture is drawn in it.

**`static UIView *fullbleedIn(UIView *layout) {`** (was L483)
> The full bleed picture a mix is given instead of the artwork square: a child of the layout, as wide as the
> page and at the top of it.

**`static UIView *blockIn(UIView *layout, UIView *cover, UIView *fullbleed) {`** (was L494)
> The layout holds the cover square and, under it, the block of text and controls: the one child nearly as
> wide as the page. Taken by width, not by being lowest: Liked Songs' layout also holds a 45pt slot for its
> icon, which while the page loads sits below the block, and taken for it the header was drawn twice, once
> in the slot and once in the block (device, 2026-09-18).
>
> A mix's full bleed picture is as wide as the page too, and while the block is still unmeasured it is the
> only child wide enough to be taken for it -- which drew the redesign inside it and concealed the picture
> along with the rest of what it holds, leaving a black hero for good, since concealing does not come undone
> (trees/continuous/3.txt against 4.txt, 2026-09-20). It is never the block, so it is skipped like the cover.

**`UIView *fullbleed = fullbleedIn(layout);`** (was L518)
> A playlist's artwork square, or a mix's full bleed picture where there is no square. Either way it is
> the view the picture is read from and the view that is concealed once the hero is drawing it.

**`CGFloat planeHeight = plane.bounds.size.height;`** (was L530)
> How far the page is pulled down past the top: the plane grows by that much and the block moves with it,
> so nothing is measured then. Rest is the smallest the plane has been.

**`CGFloat rest = [objc_getAssociatedObject(block, &kBlockHeightKey) doubleValue];`** (was L542)
> How far into the block the picture reaches: past the block's top by the title and the creator. The
> block's height only grows (loading the description grows it, collapsing shrinks it).

**`static UIView *layoutIn(UIView *root) {`** (was L553)
> The content layout of the page `root` belongs to, kept weakly on it: the header lays out on every step of
> its collapse and a walk of its tree each time would be the redesign's own cost.

**`%hook _TtC28EncoreConsumerMobile_BaseKit14PlayButtonView`** (was L579)
> The header's own pass catches the parts that fade in rather than being laid out: the find bar, and the
> action buttons as they arrive. The scroll's is where what Spotify fades back in is taken again.
> The play button arrives in the header's foreground plane after the row that replaces it has been laid
> out, so a page opening showed Spotify's green disc in the corner until something else laid the header out
> (device, 2026-09-17). Its own pass is where it goes, and the class is Spotify's own so nothing else pays
> for the check.

**`- (void)update {`** (was L601)
> What the page's model says changes without a layout pass of the header's: the saves count comes in after the
> page opens (0, then 4647, device 2026-09-18), and a Save or an edit to the name updates it again.

## `Redesigned/Playlist/PlaylistMenu.x`

**file overview** (was L1)
> Playlist redesign: Sort and Mix on the playlist's ⋯ sheet, where the rest of Spotify's curation row
> already is.
>
> Spotify puts seven pills over the first track -- Add, Mix, Notes, Video, Edit, Sort, Name & details
> (own-playlist/01.txt:33) -- and the Music app has none of them: its playlist sorts from its own ⋯ menu.
> So PlaylistRows.x closes the row up and these two rows stand in its place, because Sort and Mix are the
> only two of the seven the ⋯ menu does not already offer.
>
> **Why these are rows of the mod's own and not rows of Spotify's menu.** The sheet is
> ContextMenu_InternalImpl.ContextMenuViewController, a table whose rows come from Swift item factories
> with no ObjC surface: nothing can be read out of them and nothing can be put between them. What can be
> set is the table's header or footer view, which is how Speed and pitch has ridden on the player's menu
> since it shipped (Shared/Player/SpeedPitchMenu.x). So the block goes in the header, above Spotify's own
> rows, and is laid out by hand at the table's width.
>
> **And why not a menu of the redesign's own instead.** Building the sheet would mean owning its contents:
> every row Spotify offers for a playlist, which varies by whose playlist it is, by market, by account and
> by flag, each in the app's language and each doing something only Spotify's own code knows how to do.
> None of that can be read off the item factories, so it would have to be a hard-coded list in one
> language that goes stale the day Spotify adds a row -- the same trap the album's footer and the artist's
> sections are written to avoid. Spotify keeps its rows; the mod adds to them.
>
> Which sheet is the playlist's: the ⋯ that opened it is the redesign's own pinned button
> (Kit/SGRActionRow.h), so it records its page as it is tapped and a sheet that appears within
> SGRPinnedMoreWindow of that belongs to it. Under the native look nothing pins a ⋯ and nothing here runs.
>
> What each row does is fire Spotify's own pill, so the action, the sheet Sort opens and the state Mix
> keeps are all Spotify's; the words are read off the pills for the same reason. The pills sit in a list
> cell closed up to nothing, which the page hands over as it lays out (SGRPlaylistTakeCuration) and which
> is held from the page, so they are still there to fire once the list has scrolled past them.

**`static NSString *const kMixIdentifier = @"ListPlatform.ToolbarActions.MixButton";`** (was L37)
> Mix says what it is in its identifier; Sort is an Encore.Button.Primary like Video, Edit and Name &
> details, and its only word is the word in the app's language, so it is told apart by the glyph it draws
> (SpotifyShared has `sort`, `sortDown`, `sortUp` and `arrowUpDown`, and Encore's icon knows its own name).

**`static const CGFloat kRowHeight = 56, kSideMargin = 16, kGlyphSide = 24, kGlyphGap = 16;`** (was L42)
> The sheet's own measures and type: this draws on Spotify's sheet, not on a page of the redesign's, so it
> takes the sheet's side margin and row height rather than the Kit's tokens, as Speed and pitch does.

**`static NSString *glyphName(UIView *iconView) {`** (was L50)
> The SPTEncoreIcon an Encore icon view was built with, which knows its own name. Encore keeps it in a
> Swift ivar with no getter, as Redesigned/Navbar/TabBar.x found -- but not always the same one: the view
> holds both `icon` and `experimentalIcon` (nm on SpotifyShared), and reading `icon` alone left the Sort
> pill unrecognised on the phone while Mix, which is known by its identifier, came through
> (device 2026-09-20). So every object ivar the view has is asked, and the first that knows a name answers.

**`static BOOL isSortGlyph(NSString *glyph) {`** (was L91)
> The two pills of the row, in the order they are to read on the sheet. Either may be missing: a playlist
> of someone else's has no Mix, and a build without sorting has no Sort.

**`if (!identifier.length || [identifier isEqualToString:SGRPlaylistCurationIdentifier]) return;`** (was L103)
> The pills, and only the pills: the toolbar itself carries an identifier too, and the first glyph
> under it is whichever pill comes first.

**`void SGRPlaylistTakeCuration(UIView *cell) {`** (was L131)
> The cell that carries the curation row, as it lays out. Held from the page rather than from the cell: the
> list reuses the cell once it has scrolled past, and the sheet is opened from the top of a page one is
> usually well down. Held strongly for the same reason -- the element view Spotify binds to the toolbar is
> the toolbar's own, so it goes on answering wherever the cell it was in ends up.

**`@interface SGRMenuRow : UIControl`** (was L152)
> One row: a glyph, a word, and the whole width of the sheet to be tapped on. Spotify's own rows are drawn
> by its table, so this only has to read as one of them.

**`- (void)showSort:(UIView *)sort mix:(UIView *)mix {`** (was L236)
> The glyphs are the system's rather than Spotify's: Encore draws its own into a view of its own, and a
> copy of one is a snapshot to keep right, where these two say the same thing on every build. The words
> stay Spotify's, so the rows are in the app's language.

**`- (void)sgr_rowTapped:(SGRMenuRow *)row {`** (was L265)
> Spotify's Sort opens a sheet of its own and its Mix changes the page under this one, so the menu closes
> first and the pill is fired once it has: firing under an open sheet would put Spotify's next sheet behind
> this one.

**`static UIView *curationIn(UIView *page) {`** (was L299)
> The curation row of the page, held from the cell's own pass where there has been one, and looked for on
> the page where there has not: the row is a cell closed up to nothing, and a collection view lays out
> what it has to draw, so a page opened and left alone can reach the sheet before that cell has ever run
> a pass. It was the only thing keeping Mix off the sheet, and the sheet only came right after the menu
> had been opened and closed a few times (device 2026-09-20). The walk is the page's live views, which is
> the cells on screen and no more, and it is done once per sheet.

**`static UIView *pageFor(UIViewController *menu) {`** (was L316)
> The page this sheet belongs to, decided once and only from the ⋯ that opened it. What the page has to
> show is decided pass by pass below, never here: a sheet turned down because the page was not ready yet
> would stay turned down for as long as it was open.

**`UIView *sort = nil, *mix = nil;`** (was L352)
> Sort is Spotify's own header button where the page has one -- one identifier, in the header, never
> reused -- and the curation pill only where it has not, which is how it was found before the header's
> button was (device 2026-09-20: the pill's glyph did not answer and the row went missing).

**`CGFloat height = [block wantedHeight];`** (was L359)
> Nothing to show yet is not an answer: the page fills in as it lays out, and the next pass is asked
> again rather than the sheet being written off.

## `Redesigned/Playlist/PlaylistRows.x`

**file overview** (was L1)
> Playlist redesign: the track rows on the field, the way the Music app has them -- no surface of their own,
> artwork with rounded corners, and a hairline from the text's edge between one row and the next.
>
> Tree (trees/clean/playlist/02.txt:164-247): a cell id=Playlist.ItemCell holds an Encore.ListRow painted the
> base surface, and in it Encore.ImageView 48x48 (the artwork), Track.Row.Content.Title,
> Track.Row.Content.Subtitle and, at the trailing edge, Components.UI.ContextMenuButton. The row's own paint
> is cleared here rather than left to the Kit's repaint hook, which only hears about a colour when Spotify
> sets it and not when a reused cell already carries one.
>
> Spotify's type and its spacing are left alone: the row is 64pt for a title of 18pt, and a larger font of
> the Kit's would be cut off by the box the element framework measured for it.
>
> The pills over the first row (own-playlist/01.txt:33) are a cell of the list: Add, Mix, Notes, Video,
> Edit, Sort and Name & details. The row is closed up -- ListUXPlatform_LayoutKit.ListLayout gives every
> item its height, so the cell can only close up where the layout asks it how tall it wants to be -- and
> Sort and Mix are put on the ⋯ sheet instead (PlaylistMenu.x), where the rest of the row already is. The
> cell is handed over as it lays out, so the sheet has Spotify's own buttons to fire.
>
> Not every cell of the list is a track row. Under the tracks Spotify puts the extender -- Recommended
> songs, its rows and Refresh (ListUXPlatformConsumers_PlaylistExtenderImpl) -- and its heading and its
> Refresh cell paint the base surface over the field, where the black made bands of them (device,
> trees/continuous/2.txt 2026-09-20). So the paint comes off every cell of the page, the Kit's way, and
> only the row below is a row.

**`UIView *page = SGRPlaylistPageOf(cell);`** (was L67)
> The first track with its title in is the list the page waits for (Kit/SGRReveal.h). A row still loading
> is Components.UI.RetrievalRowLoadingElementUI rather than Encore.ListRow, grey bars with no text in them
> (trees/continuous/1.txt).

## `Redesigned/Search/Search.h`

**file overview** (was L1)
> The Search redesign: Spotify's Browse page (the Search tab before anything is typed) kept, with its controllers,
> list and cards, decluttered to the categories on black and restyled from the Kit. No settings of its own. The glass
> search field is the Navbar part's (Redesigned/Navbar/SearchField.x).
>
> SearchSections.x  an allow list of the page's cells: the category cards stay; the watch feed carousels
> (Playlists you can watch, Explore episodes for you), promos and any new kind collapse, and the
> cards below move up by the spacing the collapsed ones leave
> SearchPage.x      the header the way Home has it: a large title, the avatar at the trailing edge, no camera, no
> scrim; and the page's layout pass, which measures that spacing
> SearchCards.x     each category card as Liquid Glass tinted by its own colour, at the card radius, giving under a press
>
> Every hook installs only while Redesigned UI is on (SGRedesignedUI).
> Threading: main thread only.

**`void SGRSearchCloseGap(UICollectionView *list);`** (was L19)
> SearchSections.x: measures how far the cards sit below the top of the list because of the sections collapsed above
> them, and moves every cell of the list up by that much. Cheap to call on every layout pass of the page.

## `Redesigned/Search/SearchCards.x`

**file overview** (was L1)
> Search redesign: each category card as Liquid Glass tinted by its own colour. Under the glass, the card's colour runs
> diagonally from itself at the top leading corner to a darker shade of it at the bottom trailing one; the glass is the
> clear style with that colour at 35% for its tint, so its rim catches the colour and its body stays as vivid as
> Spotify's card. The cover and the title stay Spotify's, over the glass. The card takes the card radius, continuous;
> the title moves in with it; and the card gives a little under a press, which Spotify showed by darkening the colour
> the glass now covers. Picked on the iOS 27 simulator against plain tinted glass (flat on black), regular glass over
> the colour (muddy) and the cover under clear glass (smeared), 2026-09-17.
>
> Under Reduce Transparency, or before iOS 26, the card is the colour alone.
>
> Tree (trees/clean/search/01.txt:332-339): Control<Box> id=Components.UI.CategoryCardBrowse 177x108 >
> Encore.Box 177x108 clips > UIView r=4 clips (the Box's content view) > Encore.ImageView (the cover, turned 25 degrees
> at the trailing edge) and SPTEncoreLabel {8, 8} 120x18 (the title). The colour is in no view: Box's layoutSubviews sets
> the path and the fill colour of its animationLayer, a CAShapeLayer among its layer's sublayers, from the card's colour
> set on every pass (Encore_LayoutKit.Box's fields, and -[Box layoutSubviews] calling setPath: and setFillColor:,
> 2026-09-17). So the colour is read off that layer, and the layer is hidden rather than cleared, since Spotify fills it again.

**`glass.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;`** (was L124)
> Dark like every glass of the redesign's, rather than by grace of the navigation stack Spotify
> hosts the page in (Navbar/TabBar.x).

**`if (content.layer.cornerRadius != SGRRadiusCard && objc_getAssociatedObject(box, &kRoundedKey)) {`** (was L187)
> The card is cut at the card radius by the Box, which clips already and which Spotify gives no radius. Spotify puts
> its own 4pt back on the content view between layout passes, and the colour and the cover then showed past the glass
> at the corners (on the phone, 2026-09-17); the content view keeps the card radius only for as long as it lasts.

## `Redesigned/Search/SearchPage.x`

**file overview** (was L1)
> Search redesign: the Browse page's header the way Home has it (Redesigned/Home/HomeHeader.x). A large title at the
> leading edge in place of Spotify's small one; the avatar that opens the side drawer at the trailing edge; the camera
> that scans Spotify codes gone, and the scrim Spotify lays behind the header, the soft scroll edge
> (Kit/SGREdgeEffect.x) being what keeps the header clear of the cards scrolling under it. The page's layout pass also
> closes the gap the collapsed sections leave (SearchSections.x).
>
> Tree (trees/clean/search/01.txt:376-427): BrowsePageViewController's view holds the list (id=BrowsePage.ContentScrollView),
> a 402x216 UIView around Reprise_LiquidGlassKit LiquidGlass.GradientView (the scrim), and at {0, 62} the header's
> ElementView 402x124: a vertical UIStackView {16, 0} 370x108 of the toolbar row and the search field. The toolbar row
> is a UIStackView id=SearchToolBar.Header 370x48 of ListeningActivity_ElementsKit.AdaptiveFaceContainer {0, 7} 32x34
> (the avatar), SPTEncoreLabel id=SearchHeaderFind.HeaderLabel {40, 0} 278x48 ("Search", 21pt), the camera
> (id=SearchToolBar.AccessoryItem.ScannablesButton) and a hidden accessory button.
>
> Scrolled, Spotify slides the header up 56pt and fades the toolbar row out (03.txt:647-651, a=0.00), keeping the search
> field. So the title goes into that row as a subview the stack does not arrange: it slides and fades with the row, and
> its avatar moves to the trailing edge by the row's layout direction, as on Home. The title's text is Spotify's own
> label's, so it follows the app's language.

**`static BOOL findParts(UIView *view) {`** (was L56)
> The page's parts, found once per page: the page lays out on every step of its header sliding. A miss costs a walk of the
> header alone, so the page keeps looking while it loads.

## `Redesigned/Search/SearchSections.x`

**file overview** (was L1)
> Search redesign: of the cells the Browse page lists, only the category cards stay. Every other cell reports no
> height, so the list closes up around it: the watch feed carousels (Playlists you can watch, Explore episodes for
> you), and the promos, showcases and ad cards the page can also carry (BrowseStructure's other cases in the binary,
> swift-fields.txt 2026-09-17), and any kind the server adds later. An allow list, as for Home's sections
> (Redesigned/Home/HomeSections.x): the page is the server's, and a new kind should not turn up on a redesigned Search.
>
> Tree (trees/clean/search/01.txt): a cell of the list (id=BrowsePage.ContentScrollView) is an
> Element_List.CollectionViewCell whose content view is an ElementContentView over Browse_BrowsePageImpl.BrowseStructure,
> then an ElementView<BrowseStructure>, then the cell's own root:
> Control<Box> id=Components.UI.CategoryCardBrowse   a category card 177x108 (:332)
> UIView > UIView > UIStackView > ... WatchFeedCarouselEntryPointElement   a carousel 402x224 under its heading (:26-30)
>
> A collapsed cell keeps its content at the height it measured, hidden and cut off by the cell, the way Home's do: content
> squeezed to 0 with the cell breaks its constraints on every layout pass (Home.h, home perf 2026-09-17).
>
> The carousels are the page's first two sections, and the list keeps its spacing between sections whatever their
> height: collapsed, they still leave 16pt after the first and 24pt after the second (01.txt:30-31, :325), 40pt of black
> between the search field and the cards. So every cell of the list moves up by the spacing the collapsed cells above the
> first card leave, measured from the list's own layout attributes. The move is the cell's transform, set after UIKit
> applies the cell's attributes and on the cell's layout passes, so it holds through scrolling, reuse and reloads (a
> compositional list with the same shape on the iOS 27 simulator, 2026-09-17), and touches follow it. Spotify's content
> inset, which its collapsing header is worked out from, stays its own.
