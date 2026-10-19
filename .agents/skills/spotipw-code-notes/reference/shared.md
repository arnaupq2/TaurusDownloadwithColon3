# Shared

116 files, 408 notes, moved out of the code (tweak/Sources/Shared/).

## `Shared/AdBlock/AdBlock.h`

**file overview** (was L1)
> EeveeSpotify's layers, ported, at the top of the Premium, ads & privacy page. Three switches, each off until asked for. Hide ads
> keeps the ad services from starting (AdServices.x), takes ad components out of Home and Search
> before they render (AdHubs.x, Feeds.m) and answers the requests behind them empty (AdNetwork.x).
> Hide upsells drops the Premium prompts (AdPopups.x, AdServices.x) and forces the flags that show
> them off (AdBlock.m, through Flags.x). Spoof Premium rewrites the product state and remote
> config as they arrive (Premium.m), crossfade and automix included (Crossfade.x), and keeps the
> session alive when the server disagrees (AdNetwork.x). The two Search switches force their flags
> off (AdBlock.m, through Flags.x).

**`NSData *SGPatchCustomize(NSData *body);`** (was L28)
> Premium.m: the body of v1/customize, or the bootstrap message that wraps one, rewritten to a
> Premium account's. nil when the bytes do not parse.

**`NSData *SGStripFeed(NSData *body);`** (was L33)
> Feeds.m: a browsita, casita or scrollsita feed with its ad sections taken out; nil when there
> were none, or the bytes were not the shape expected.

## `Shared/AdBlock/AdBlockSettings.m`

**`static UIViewController *adFlagsPage(void) {`** (was L8)
> Every switch here forces a flag Spotify ships on to off, so the titles name the blocking: on stops
> the thing, off is Spotify's own value. Hide ads and Hide upsells already force the first two
> sections off, which locks those rows.

## `Shared/AdBlock/AdHubs.x`

**file overview** (was L1)
> Ad components taken out of the Hub JSON Home, Browse and Search pages are built from, before
> the builder renders them (EeveeSpotify's HubsAdBlocker). A component is an ad when its
> namespace, name, id, type or the keys of its metadata, logging or custom dictionaries say so;
> its title never counts, "Billboard Hot 100" is a playlist. The plain ad words go with the ads
> switch, a promotion word next to a surface word with the upsells one.

## `Shared/AdBlock/AdNetwork.x`

**file overview** (was L1)
> Spotify's responses on their way in, through the URLSession delegates it reads them by:
> SPTDataLoaderService for most of spclient, HttpClientURLSession for what some regions route the
> other way. A request for an ad is answered empty. With Spoof Premium on, the bootstrap
> and customize bodies are rewritten by Premium.m before the client sees them, the endpoints the
> server would use to log the account out are answered as if they succeeded, and past the first
> thirty seconds the re-fetches that could bring the real state back are cancelled before they
> leave. Feeds go through Feeds.m. Everything here is EeveeSpotify's, less its Ably hooks, which
> it does not turn on for 9.1 either.

**`static BOOL isFeed(NSString *path) {`** (was L31)
> The feeds Home, Search and the page under the player are built from. casita/v1/feeds is the flat
> list of tab chips, not sections.

**`static BOOL isRefetch(NSString *path) {`** (was L64)
> The first thirty seconds are a fresh login's: signup/public and customize are part of it, and
> answering them broke first launch.

**`static NSData *blockedReply(NSString *path) {`** (was L90)
> The body a blocked request is answered with: what its reader parses for, so that nothing is
> retried and no logout path taken.

**`static void deliver(id<NSURLSessionDataDelegate> delegate, NSURLSession *session, NSURLSessionTask *task, NSData *data) {`** (was L119)
> Data handed to the delegate by the mod goes through its hooked didReceiveData like Spotify's own,
> with the pass mark on the task so the hook lets it by.

**`static BOOL holds(NSURLSessionTask *task, NSData *data) {`** (was L136)
> YES when the data is not the delegate's to see yet: dropped for a blocked request, kept back for
> one whose reply is rewritten when it finishes.

**`if (!buffer) {`** (was L175)
> Nothing to rewrite: a 304, or a body of no bytes. The delegate is told of a body either
> way, since a completion with none hangs some readers.

**`%group Premium`** (was L220)
> The re-fetches that could put the real product state back, or drop the push token, use sessions
> of their own that the delegate hooks do not see; they are cancelled at the task. login5 and the
> Google token stay: blocking those was a crash loop.

**`static NSURLRequest *unconditional(NSURLRequest *request) {`** (was L241)
> The config comes back 304 with no body when the app holds a copy of it and asks whether that is still
> current, and a copy taken while Spoof Premium was off is the server's own: the mod then has nothing to
> rewrite, and the account stays free until the server changes the config (device 2026-09-21). So the two
> go out without the question, and the server always answers in full.

**`%group PremiumLocalRequests`** (was L265)
> The sessions Spotify makes are __NSURLSessionLocal; hooked as well only when that class answers
> dataTaskWithRequest: itself, since a hook on an inherited method would sit on NSURLSession's twice.

## `Shared/AdBlock/AdPopups.x`

**file overview** (was L1)
> The Premium prompts Spotify presents as Encore pop-ups, dropped when their words sell Premium
> (EeveeSpotify's UpsellPopupBlocker). The words are read where the dialog model is made, since
> the dialog handed to the presenter does not expose them on every build; the presenter reads
> them itself as a fallback.

## `Shared/AdBlock/AdServices.x`

**file overview** (was L1)
> The services behind every ad surface and Premium prompt, each an SPTService Spotify starts by
> sending it -load. Hooked to do nothing, the surface is never built: the brand ad on Home, the card
> under the player, the sponsored playlist header, the sponsorship on the now playing bar, the
> in-stream ad, and the sheets and cards that sell Premium. The two views are a fallback for a
> header or banner already on screen before its service was silenced.

**`%hook _TtC32AdsEmbedded_EmbeddedCTACardsImpl23EmbeddedCTACardsService`** (was L44)
> The leavebehind card among the player's scroll cards. It has no -load; its card is added the way
> lyrics and credits add theirs, so it is kept off the list instead.

## `Shared/AdBlock/Crossfade.x`

**file overview** (was L1)
> Crossfade under Spoof Premium (EeveeSpotify's): the fade engine reads the stored crossfade switch,
> but the duration slider only writes the duration, so the fade stayed off at any length.

## `Shared/AdBlock/Feeds.m`

**file overview** (was L1)
> Ad sections taken out of the feeds Home, Search and the page under the player are built from
> (EeveeSpotify's BrowsitaSectionStripper). A feed is one container field of sections, each a
> field 1 message; a section goes when its bytes name an ad, or a promotion and a surface for it.

## `Shared/AdBlock/Premium.m`

**file overview** (was L1)
> Spoof Premium: the UCS response, which carries the account's product state and its remote
> config, rewritten as it arrives. The attributes and the flag rules are EeveeSpotify's. Offline,
> audio quality and the social session attributes are left alone: the server still decides those,
> and a spoofed one only shows UI the request behind it will fail.
>
> UcsResponse: 1 ResolveResponse { 1 ResolveConfiguration { 3 repeated AssignedValue } },
> 3 AccountAttributesResponse { 1 repeated entry { 1 key, 2 AccountAttribute { 2 bool, 4 string } } }
> AssignedValue: 1 { 1 scope, 2 name }, 3 BoolValue { 1 }, 4 IntValue { 1 }, 5 EnumValue { 1 }
> A customize body is CustomizeMessage { 1 UcsResponse }; bootstrap wraps that in 2 { 1 { 1 { it } } }.

**`if (SGPBFirst(value, 3)) setValue(value, SGPBBytes(3, boolValue(rules[i].on)));`** (was L387)
> Set changes a boolean that is there; a value of another kind (a count of seconds, say)
> under the same name is left as the server sent it rather than turned into a false.

## `Shared/AdBlock/Protobuf.h`

**file overview** (was L1)
> The protobuf wire format, just enough to walk into a message, change a few fields and write it
> back with everything else untouched. Premium.m and Feeds.m read Spotify's responses through it.

**`NSData *SGPBEdit(NSData *message, NSArray<NSNumber *> *path, NSData *(^edit)(NSData *inner));`** (was L20)
> The message at `path` (field numbers, outermost first) handed to `edit`, whose result takes its
> place; nil when a field of the path is missing, the bytes do not parse or `edit` returns nil.

## `Shared/ArtistBlock/ArtistBlock.h`

**file overview** (was L1)
> Artist block: tracks by artists on the list are skipped as they come up (ArtistSkip.x). An artist
> is kept by URI, with the name it had when it was blocked, so a rename or a namesake changes nothing.

## `Shared/ArtistBlock/ArtistBlockSettings.m`

**file overview** (was L1)
> The Blocked artists page: the switch, whether a featured credit counts, blocking someone off the
> track playing now, and the list, swiped to unblock. The hook reads all of it per track, so a change
> needs no restart.

## `Shared/ArtistBlock/ArtistSkip.x`

**file overview** (was L1)
> Skips a track by a blocked artist the moment the player moves onto it, whatever started it: the
> queue, autoplay, a radio or a tap. The track is read off SPTEsperantoPlayer, the app's player,
> which the now playing bar asks for its state from launch on; the full screen player's playback
> controller only exists while that player does, so it is the skip's first choice, not the source. A
> track change is heard from the lock screen's now playing info, which Spotify sets on every track.
> A track is looked at once, so an update within it does not skip twice.

## `Shared/Audio/SGAudioPipeline.h`

**file overview** (was L1)
> Single owner of Spotify's mixer connection and RemoteIO notify. Registrations are fixed slots,
> independent of constructor/rebinding order. All render functions are bounded C callbacks.

**`typedef OSStatus (*SGAudioSourceProcessor)(void *context, UInt32 frames, AudioBufferList *data,`** (was L30)
> Sing's source-domain processor runs before a speed/pitch unit consumes these frames. Its raw
> source callback calls PullOriginal, never Pull (which would recurse into the processor).

**`UInt32 SGAudioPipelineSourceAheadFrames(UInt32 maximumFrames);`** (was L35)
> Render endpoint only: verified decoded prefix, capped at maximumFrames, before a source event.
> Zero keeps normal pulls and lets retained original audio drain. Never an extra source consumer.

**`bool SGAudioPipelineSetSourceProcessor(SGAudioSourceProcessor processor, void *context);`** (was L40)
> Off-render only. Waits for an active callback to leave before replacing the context. After this
> returns, the old context is no longer used by the pipeline (its worker may still own it).

## `Shared/Audio/SGAudioPipeline.x`

**`enum { rendering = 1, changing = 2 };`** (was L24)
> Graph changes wait off the render thread. A render callback makes one attempt and never waits.
> This protects the source/bus pair and prevents disposing a source during a pull. Setters can
> invoke a property listener synchronously, hence the per-thread nesting count.
> Sing also bounds look-ahead by the source mixer's `OutputIsSilence` flag when Spotify's callback
> ABI is not pinned; this path does not inspect decoder-queue memory.

## `Shared/Audio/SGAudioRingBuffer.h`

**file overview** (was L1)
> Preallocated single-producer/single-consumer PCM packets. Creation/destruction require both
> endpoints to be stopped. Never reset indices across threads; invalidate by generation instead.

## `Shared/Audio/SGAudioSourceQueue.h`

**`SGAudioSourcePrefix SGAudioSourceQueuePrefix(AURenderCallbackStruct callback, UInt32 maximumFrames, bool continuous);`** (was L12)
> A continuous stream may cross one end marker only when the native reader can continue
> without stopping. Commands, a second marker, or an unstable snapshot still fence the prefix.

**`UInt32 SGAudioSourceQueueFrames(AURenderCallbackStruct callback, UInt32 maximumFrames);`** (was L15)
> Sole source consumer only. Zero means no verified spare audio, including an event boundary.
> Inspect only the prefix needed for this pull; never walk the entire decoder queue needlessly.

## `Shared/Audio/SGAudioSourceQueue.m`

**`if (!context || context > UINTPTR_MAX - 0x90 ||`** (was L44)
> Adjacent metadata fields share one checked copy. Do not repeat kernel reads for
> each word of the same source context, sink or queue node on every audio callback.

**`if (!continuous || boundary != UINT64_MAX) break;`** (was L79)
> 0x1454b4–0x1454fc pops a null block and continues unless byte a1 is 1
> and byte a2 is 0 (the stop/wait path at 0x1456ac). Never read PCM directly
> or invoke that private reader: the original AudioUnit remains the consumer.

**`samples += remaining;`** (was L92)
> An exact-sized pull leaves the exhausted block at the head. The verified
> reader (0x145550–0x1455c8) pops it on the next pull and continues with the
> following block. Only a null block is an event fence; zero samples are not.

**`UInt32 frames = (UInt32)MIN(samples / 2, maximumFrames);`** (was L107)
> Unvisited nodes cannot affect this prefix. Pending commands and an unstable queue
> still invalidate the snapshot even when enough frames were found in its first node.

## `Shared/AudioEffects/AudioEffects.h`

**file overview** (was L1)
> Audio effects on Spotify's sound: the mod's own engine (SGDSPEngine), run on every buffer Spotify's output
> unit finishes, before the speaker. Either look: it draws nothing on Spotify's screens. Mod Settings >
> Audio effects is its page.
>
> What it offers: output gain and limiter, a multiband compander, dynamic bass boost, a 15 band equalizer,
> the Graphic EQ (any curve, as AutoEq writes them), the convolver (impulse responses), ViPER DDC files,
> Liveprog (EEL2 scripts), reverb, stereo widening, crossfeed and analog modelling. Each effect has a switch
> and its own values, kept under its own keys.
>
> Unlike the mod's other switches these apply as they change, not at launch: every setter below stores the
> value and hands the effect it belongs to to the engine, which re-reads that effect's keys off the main
> thread. The engine is made the first time Spotify starts its output with the master switch on.
>
> Threading: everything here is main thread, except SGDSPStatus and SGDSPError, which any thread may call.

**`#define SGKeyDSPCompanderGains          @"spotifyglass.dsp.compander.gains"`** (was L29)
> Seven amounts, "a;a;a;a;a;a;a", one per band at SGDSPCompanderFrequencies, each within SGDSPCompanderGainLimit:
> over 0 evens the band's loud and quiet moments out, under 0 pulls them apart.

**`#define SGKeyDSPConvolver               @"spotifyglass.dsp.convolver"`** (was L44)
> File effects name a file in their library (SGDSPLibraryFiles), by its name alone: the app's container
> moves on every reinstall, the name does not.

**`NSString *SGDSPImportFile(SGDSPFileKind kind, NSURL *url, NSError **error);`** (was L120)
> Copies a picked file into the library, replacing one of the same name; answers its name, nil and an
> error when it is not a file of that kind.

**`NSString *SGDSPError(NSString *switchKey);`** (was L129)
> Why an effect's last change did not take, nil when it did: a script that did not compile (with the
> line), an impulse response that could not be read, a DDC file that was not one. Keyed by the effect's
> switch key (SGKeyDSPLiveprog, SGKeyDSPConvolver, SGKeyDSPDDC, SGKeyDSPGraphicEq).

**`void SGDSPEqualizerResponse(NSArray<NSNumber *> *gains, NSInteger count, double *frequencies, double *decibels);`** (was L134)
> The equalizer's magnitude response for the given gains, for drawing the curve: `count` points
> log-spaced from 20 Hz to 20 kHz into `frequencies` and `decibels`.

## `Shared/AudioEffects/AudioEffects.x`

**file overview** (was L1)
> Audio effects on Spotify's sound (AudioEffects.h): every buffer Spotify's output unit finishes runs
> through SGDSPEngine before it reaches the speaker.
>
> Spotify plays through Core Audio units of its own (AudioUnitDriver2 in the binary: converter, EQ, mixer
> and a RemoteIO output unit, started with AudioOutputUnitStart), with no Objective-C method between it and
> the unit. Shared/Audio/SGAudioPipeline owns that connection and invokes this output processor
> after speed/pitch and before music haptics. The processor reads the speaker-bound buffer into float
> lanes, runs the engine and writes it back in place. Graph/format changes use the same pipeline gate.
>
> The engine is made the first time the output starts with the master switch on, at the output's rate,
> and lives as long as Spotify: the render thread may be holding it at any time. With the switch off the
> notify returns straight away, and Spotify's sound is untouched. Silence goes through the engine too, so a
> reverb or a convolver rings out after a track stops.
>
> Settings apply as they change: SGDSPApply marks the effect, and a serial queue reads its keys a moment
> later and sets them, so a slider dragged across comes down to the last few values. The queue also makes
> the engine, follows the output to a new sample rate, and once a second frees what the effects replaced.
>
> Threading: the notify runs on the render thread and touches only atomics, its scratch lanes and the
> engine's render side. Spotify starts its output on a thread of its own. The effects are set on the queue;
> SGDSPApply and the curves are main thread; SGDSPStatus and SGDSPError any thread.

**`static atomic_uint_fast64_t sg_rateBits;`** (was L51)
> The format of the buffers the notify gets: the rate, and the layout packed into one word so the render
> thread never reads half of a change (flags in the low 32 bits, then channels, then bytes per sample).

**`static void processBuffer(SGDSPEngine *engine, AudioUnitRenderActionFlags *flags, UInt32 frames, AudioBufferList *data) {`** (was L105)
> The buffer through the engine in place, whatever its format: the buffers themselves as the engine's lanes
> when they are float, one per channel (the hardware's usual), otherwise read into the scratch lanes and
> written back. The first two channels are the engine's; a mono output is fed to both and gets their mean.

**`BOOL fits = split ? data->mNumberBuffers == channels : data->mNumberBuffers == 1 && data->mBuffers[0].mNumberChannels == channels;`** (was L115)
> Buffers not laid out as the format says are left alone rather than read as noise: the format read at
> the start can be a moment old.

**`static BOOL readFormat(AudioUnit unit) {`** (was L190)
> The format the notify's buffers are in, which is the RemoteIO unit's output side (element 0, output scope):
> the hardware's, not the one Spotify hands the unit (the input scope). In the simulator a 44.1 kHz client
> comes out at 48 kHz, and a 16-bit interleaved one as float, a buffer per channel (harness/audio-effects/sim).
> Answers whether the engine can take it.

**`static os_unfair_lock lock = OS_UNFAIR_LOCK_INIT;`** (was L203)
> Spotify starts its output again after every pause; the format is logged when it is not the last one.
> Spotify's thread and a format change's may both be here.

**`static void tend(void) {`** (was L409)
> Once a second while the engine lives: what the effects replaced freed, an engine gone non-finite started
> over, and now and then a summary.

**`static dispatch_source_t sg_tendTimer;`** (was L438)
> The engine is read out once a second while it runs. With the switch off there is nothing in it to
> read, so the source is suspended rather than left ticking for the rest of the app's life: the engine
> is never freed, and a timer tied to its making would outlive every use of it. Only ever touched from
> applyMaster, which is to say on applyQueue().

**`static BOOL applyMaster(void) {`** (was L452)
> The switch and the output's format: the engine made or moved to the output's rate, everything set when
> it was, and the notify let in or kept out. Answers whether every effect was set.

## `Shared/AudioEffects/AudioEffectsApply.h`

**file overview** (was L1)
> Between the audio effects' settings (AudioEffectsSettings.m) and their engine (AudioEffects.x), inside
> Shared/AudioEffects.

**`NSString *SGDSPEffectOf(NSString *key);`** (was L5)
> The effect a key belongs to, named by its switch key. The master switch and output control's keys
> belong to SGKeyDSP.

**`void SGDSPApply(NSString *effect);`** (was L9)
> Re-reads the effect's keys into the engine off the main thread, a burst of calls (a slider being dragged)
> coming down to the last. SGKeyDSP starts the engine when Spotify's output has started, or bypasses it.
> Main thread.

## `Shared/AudioEffects/AudioEffectsFiles.m`

**file overview** (was L1)
> The audio effects' file libraries: Documents/spoti.pw/Audio effects/<Convolver|DDC|Liveprog>, where the
> file effects find their files by name. Documents, which the app's backups keep. Every file in them is
> one the user imported.
>
> Threading: any thread (the engine's queue reads the paths too); a library is made once.

**`static BOOL looksLike(SGDSPFileKind kind, NSData *data) {`** (was L109)
> Whether the bytes look like a file of the kind, before it goes into the library: a WAV (RIFF, RF64) or
> FLAC stream, a DDC file's two rates, a Liveprog script's @sample section.

## `Shared/AudioEffects/AudioEffectsLibraryPage.m`

**file overview** (was L1)
> The pages a file effect's row and the Graphic EQ's row push: a library of files with the chosen one
> ticked, and the GraphicEQ text to paste or edit. Each shows the effect's error, if its last change did
> not take, in a red card at the top, looked at again once a second while the page is open.

**`@interface SGDSPErrorPage : SGPage`** (was L66)
> A page of this file whose section 0 is the effect's error: one red row while there is one, nothing
> otherwise, the row coming and going without the page reloading.

**`@interface SGDSPFilesPage : SGDSPErrorPage <UIDocumentPickerDelegate>`** (was L137)
> The files of one kind, the chosen one ticked: a tap chooses a file and uses it straight away, and the
> page stays, so one after another can be heard. A swipe deletes one; Import file… copies one in from Files.

**`- (void)pickFile {`** (was L247)
> .eel, .vdc and .irs are nobody's registered types, so the picker offers any file and the name is
> checked after.

## `Shared/AudioEffects/AudioEffectsPage.h`

**file overview** (was L1)
> Mod Settings > Audio effects: the effects' switch with what the engine is doing under it, then a card per
> effect, each opening out into its controls while its switch is on. Everything on it goes through
> AudioEffects.h's setters, so it applies as it changes, a slider while it is dragged.
>
> AudioEffectsPage.m          the page: the switch, the status, the effects' cards, their sliders and choices
> SGDSPCurveView.m            the equalizer's and the compander's curve, with a handle to drag per band
> AudioEffectsLibraryPage.m   a file effect's library (the convolver's, ViPER DDC's, Liveprog's) and the GraphicEQ editor
>
> Main thread only.

## `Shared/AudioEffects/AudioEffectsPage.m`

**file overview** (was L1)
> The Audio effects page. It is not an SGModPage: its sliders store as they move, its cards open out
> into their controls as their switches go on, and its status line and the effects' errors come and go
> while it is open, none of which a page of fixed rows does. It keeps Settings/'s look all the same: the
> cards, the 13pt titles over 11pt subtitles, the tiles, the value and the chevron, the checkmark lists.

**`static NSString *numberText(SGDSPRow *row, double value) {`** (was L178)
> "−3.5 dB", "+2 dB", "60 ms", "0.22 s", "60%": the step's decimals unless the number is whole, a sign
> where the range runs both ways, and a real minus.

**`@interface SGDSPChoicePage : SGPage`** (was L320)
> The names a choice picks from, a checkmark against the one set. Unlike Settings' own list it stays
> open after a pick, so one reverb room after another can be heard before going back.

**`- (UITableViewCell *)valueCell:(UITableView *)table title:(NSString *)title value:(NSString *)value {`** (was L634)
> The value on the right beside the chevron where it fits next to the title, and under the title
> where it does not: the compressor's transforms are longer than a narrow phone has room for.

**`- (void)effectToggled:(UISwitch *)toggle {`** (was L686)
> The effect's rows come in under its switch, or go, rather than the page reloading around them; then the
> card is scrolled into view, as much of it as the screen holds.

## `Shared/AudioEffects/AudioEffectsSettings.m`

**file overview** (was L1)
> The audio effects' settings: what each key holds until set, its bounds, and the lists the page's choices
> pick from, in the order the engine numbers them (SGDSPEffects.h).

## `Shared/AudioEffects/SGDSPConvolver.h`

**file overview** (was L1)
> Impulse responses of up to 4 paths through blocks of stereo, and the files they are read from. The first
> 16384 frames go in partitions of one block, so the output is ready as the block comes in; the rest in
> partitions of 8 blocks, their work spread evenly over the 8. SGDSPConvolverProcess never allocates or locks.

**`SGDSPConvolver *SGDSPConvolverCreate(const float *const *responses, int paths, size_t length);`** (was L14)
> `paths` responses of `length` frames: 1 (each channel through it), 2 (left to left, right to right) or 4
> (left to left, left to right, right to left, right to right). NULL when out of memory.

**`bool SGDSPReadImpulse(const char *path, double rate, SGDSPImpulseMode mode, SGDSPImpulse *impulse, char *error, size_t errorSize);`** (was L33)
> A WAV (.wav, .irs) or FLAC file of 1, 2 or 4 channels, resampled to `rate` and scaled so its loudest
> output channel passes as much power as it takes in.

## `Shared/AudioEffects/SGDSPConvolver.m`

**`typedef struct {`** (was L16)
> One partition size: the responses' spectra, the inputs' spectra of as many partitions back, and what
> is being summed for each output. Split complex, packed as vDSP's real FFT packs them (bin 0 holds the DC
> and the Nyquist bins).

**`float scale = 1.0f / (8.0f * size);`** (was L61)
> A response's partitions transformed once, scaled so that the inverse transform of their products is
> the convolution itself (vDSP's forward transform doubles, its inverse multiplies by the length).

**`int next = 1 - convolver->reading;`** (was L197)
> A tail partition of input is complete: the sum for the one before it is finished and becomes the
> next kSpread blocks' output, and this one's spectrum starts a new sum.

## `Shared/AudioEffects/SGDSPCurveView.h`

**file overview** (was L1)
> The equalizer's 15 bands or the compander's 7 points, drawn as the response they make over a grid of
> their range, with a handle per band: dragged up and down it stores as it moves, a double tap puts it back
> to zero, and VoiceOver adjusts it a step at a time. Over it, Reset, and for the equalizer the presets in a
> pull-down named after the one the bands match.

## `Shared/AudioEffects/SGDSPCurveView.m`

**`if (_presets) {`** (was L275)
> Measured here: a button's configuration catches up with a new title only on its next pass, so
> sizeToFit would still be fitting the old name.

**`CGRect plot = [self plotRect];`** (was L346)
> Past the plot's edges the mask cuts the curve off; points kept near them keep a runaway value
> from stretching the path.

**`CAMediaTimingFunction *easing = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];`** (was L366)
> A shape layer's path has no implicit animation, so the curve morphs by hand, from wherever it is
> now; the handles are plain layers and slide on their own.

**`- (NSInteger)bandAt:(CGPoint)point {`** (was L460)
> The band whose handle is under `point`: the nearest by frequency, if the finger is close enough to its
> handle. Anywhere else on the plot a drag scrolls the page instead.

## `Shared/AudioEffects/SGDSPDynamics.m`

**`static void split(SGDSPCompander *compander, int channel, const float *input, uint32_t frames) {`** (was L46)
> Each channel into seven bands: a Linkwitz-Riley low pass off what is left at each crossover, the rest
> passing on. A band then goes through the allpasses of the crossovers above it, so the sum is flat.

**`static float sg_halfband[kTaps];`** (was L107)
> The filter of both the doubling and the halving: a low pass at a quarter of the doubled rate, minimum
> phase, so it delays by a few samples rather than half its length. Made once, the same at every rate.

**`void SGDSPTubeSet(SGDSPTube *tube, double driveDB) {`** (was L160)
> A full scale sound at 0 dB of drive reaches half way up the curve; the output is scaled back by the
> curve's slope at rest, so quiet sounds keep their level.

## `Shared/AudioEffects/SGDSPEffects.h`

**file overview** (was L1)
> The effects SGDSPEngine chains (SGDSPTone.m, SGDSPDynamics.m, SGDSPCrossfeed.m, SGDSPReverb.m,
> SGDSPLiveprog.m; the convolver is SGDSPConvolver.h). Create, Set and Free are never the render thread's, and
> a Set changes a running state, so it is called under the engine's lock. Run never allocates, locks or logs.

**`typedef struct SGDSPBass SGDSPBass;`** (was L15)
> A low shelf at 100 Hz lifting by up to `maxGainDB`, less while the lows are loud: never past -3 dBFS
> where the headroom allows none.

**`typedef struct SGDSPCompander SGDSPCompander;`** (was L40)
> Seven Linkwitz-Riley bands around `frequencies`, each band's loud and quiet moments pulled towards its own
> running level by gains[i] (1: 60% less dynamics) or pushed away from it (-1: 60% more), by 12 dB at most.
> `timeConstant` is the release; the attack a tenth of it, the running level ten times it.

**`typedef struct SGDSPLiveprog SGDSPLiveprog;`** (was L69)
> A script in JSFX's shape: a desc: line and sliderN: defaults, then @init, @slider, @block and @sample
> sections, spl0 and spl1 the samples, srate the rate. NULL and why, with the file's line, when it does
> not compile.

## `Shared/AudioEffects/SGDSPEngine.h`

**file overview** (was L1)
> The audio effects' engine, for Core Audio's render thread: one per process, fed the finished output a slice
> at a time. It re-blocks into kSGDSPEngineBlock frames, so the sound is exactly one block late whatever the
> slices; with every effect off and the gain at 0 dB a block passes untouched.
>
> Threading: SGDSPEngineProcess never allocates, blocks, logs or messages; it only tries the lock the setters
> hold for their swaps, and a block that finds it taken passes dry, as late. SGDSPEngineRestart and the
> diagnostics are for any thread; the rest is the config side, one thread at a time.

**`bool SGDSPEngineSetGraphicEq(SGDSPEngine *engine, bool on, const char *nodes, char *error, size_t errorSize);`** (was L44)
> These answer false and say why in `error` when the effect could not take; it is then off.
> AutoEq's GraphicEQ format, "GraphicEQ: 20 -1.2; 21 -1.1; ...".

**`void SGDSPEngineRestart(SGDSPEngine *engine);`** (was L58)
> The next SGDSPEngineProcess starts over from a block of silence, for a stream that stopped and starts
> again (the sound held from before it would otherwise play first). Any thread.

**`void SGDSPEngineEqualizerCurve(const double bandFrequencies[15], const double gains[15], int count, double *frequencies, double *d`** (was L78)
> `count` points log-spaced from 20 Hz to 20 kHz into `frequencies`, and the curve at them: the
> equalizer's response at 48 kHz, the compander's gains drawn smooth.

## `Shared/AudioEffects/SGDSPEngine.m`

**`enum { kRing = 4 * kSGDSPEngineBlock };`** (was L16)
> The FIFO the processed blocks wait in: a power of two holding the primed block, the one being handed out
> and the one just made, with room to spare.

**`typedef enum {`** (was L20)
> The order a block goes through the effects: tone, then dynamics and colour, the script, the stereo image,
> and the rooms last.

**`static void output(SGDSPEngine *engine, float *left, float *right) {`** (was L218)
> The gain, moving to a new one over the block, then a limiter with no lookahead: it clamps a peak the
> sample it comes, stereo linked, and lets go at the release's pace.

**`static void runBlock(SGDSPEngine *engine) {`** (was L251)
> The gathered block, processed (or as it is, when a setter holds the lock) into the ring. The ring is a
> whole number of blocks and blocks are written whole, so a block never wraps.

**`if (active && !allFinite(left, right)) {`** (was L271)
> An effect gone unstable would put NaN into its own state and every block after; silence rather
> than noise, and the config side resets the engine when it sees the count move.

**`while (out < in) {`** (was L296)
> As many frames out as came in: the ring is always a block ahead, so it has them, and the frames
> overwritten were copied into the block already.

**`static void install(SGDSPEngine *engine, Slot slot, void *state) {`** (was L330)
> A new state for the slot (NULL: off), crossfaded in over the next block. A fade still to be heard keeps
> what is heard now as its start, and the state it was going to drops.

## `Shared/AudioEffects/SGDSPFilters.h`

**file overview** (was L1)
> The effects' filter maths: biquads and their designs, the gain a design makes, ViPER DDC and GraphicEQ text
> read, and minimum phase responses made from a magnitude. SGBiquadTick and SGBiquadRun are the render
> thread's; the rest allocates.

**`void SGDSPDesignEqualizer(double rate, const double frequencies[15], const double gains[15], SGBiquad bands[15]);`** (was L34)
> Peaking bands at `frequencies`, their own gains solved so that the whole cascade meets each band's gain
> at its centre. A band at or over 0.46 of the rate stays flat.

**`typedef struct {`** (was L46)
> A .vdc file: biquads for 44.1 and for 48 kHz, five numbers each (b0, b1, b2 and the two feedback
> coefficients, whose sign is read from the file: the one that makes every filter stable).

**`SGBiquad *SGDSPDDCFor(const SGDSPDDC *ddc, double rate, int *count);`** (was L55)
> The file's filters at `rate`: its own at 44.1 or 48 kHz, otherwise the nearer set moved to the rate by
> a bilinear frequency warp. malloc'd, `count` of them.

**`bool SGDSPMinimumPhase(const double *magnitude, int log2n, float *impulse, int taps);`** (was L74)
> The minimum phase impulse response of a magnitude given at the n / 2 + 1 bins of an n = 2^log2n point
> spectrum, its first `taps` samples into `impulse`. false when out of memory.

## `Shared/AudioEffects/SGDSPLiveprog.m`

**`static pthread_mutex_t sg_lock = PTHREAD_MUTEX_INITIALIZER;`** (was L22)
> EEL2 locks around its memory being grown and its tables being changed, which only a compile does here. On
> the render thread nothing is grown: gmem stays unallocated there, and the lock is never waited on. The
> thread is told apart by pthread_self, not a thread-local, whose first use on a thread allocates.

## `Shared/ConnectDiscovery/ConnectDiscovery.x`

**`static NSDictionary *rememberInjectedPacketLocked(int fd, const void *bytes, size_t length,`** (was L61)
> Called while sg_discoveryLock is held and before the send, so the receive hook's lock-free
> expiry check already sees it when the reply lands.

**`static void runBridgeRound(SGBridgeRound *round) {`** (was L318)
> Each round fans out through one nonblocking socket per family and collects replies in parallel.
> It also watches for targets that finish Bonjour resolution shortly after the failed send.

## `Shared/Flags/Flags.h`

**file overview** (was L1)
> Flags: Spotify's remote-config flags. Flags.x forces an override into the configuration
> provider; SGFlagList.m is the table of every flag, generated from the IPA by
> scripts/extract-flags.py; FlagsPage.m is the searchable All flags page and FlagPages.m the Labs
> page. Flags that change a part of the app sit on that part's own page.

## `Shared/Flags/Flags.x`

**file overview** (was L1)
> Spotify reads every remote-config flag once at startup through the configuration provider,
> keyed "component.property". The value handed back is Core/SGFlagForce.h's: what the redesign forces
> (Redesigned/Kit/SGRedesign.h), which comes before an override so one left from Spotify's own screens
> cannot pull a redesigned one apart, then an override from the Flags page, then what the ad blocking
> and the lyrics sources force.

## `Shared/Flags/FlagsPage.m`

**`@interface SGFlagsPage : SGPage <UISearchBarDelegate>`** (was L16)
> Every flag in SGFlagTable, filtered by the search words; forced flags first while the search
> is empty. Bool flags get an Auto / Off / On control, the others a text field in an alert.

## `Shared/Gestures/GestureZones.m`

**`static NSArray<NSNumber *> *defaultZones(NSInteger columns, NSInteger rows) {`** (was L37)
> Seek out to the sides, play or pause in the middle; a grid of three rows repeats the columns, so
> the split changes the cells to edit without changing what the player does until one is edited.

## `Shared/Gestures/Gestures.h`

**file overview** (was L1)
> Double tap zones over the player's artwork: the artwork already answers a sideways swipe with the
> next track and a vertical drag with the cards below, so a double tap is what is left free.

**`void SGPerformGestureAction(SGGestureAction action);`** (was L22)
> Runs one of the actions above against the player, exactly as a double tap on a zone does; the
> haptics observer hears it too. Main thread. Used by the double tap and by the AirPods gestures.

**`void SGGestureSetObserver(void (^observer)(SGGestureAction action));`** (was L46)
> Told of each action a double tap is about to perform, before the player has acted on it; one observer,
> for a look that answers the gesture (the redesign's haptics). Main thread.

**`void SGGestureAttach(UIView *host);`** (was L50)
> Puts the double tap on `host`, the view the player's grid covers, while the switch is on; again on
> every layout pass of the host, so taps Spotify adds later still wait for it. Main thread.

## `Shared/Gestures/Gestures.x`

**file overview** (was L1)
> A double tap on the player, read against the grid Settings draws: the recognizer, what each cell does
> and the playback controller it does it with. Which view of the player it goes on is each look's own
> hookup (Native/Player/PlayerGestures.x, Redesigned/Player/PlayerGestures.x), which call SGGestureAttach.
>
> The player already answers a sideways swipe with the next track and a vertical drag with the
> cards below, which leaves the double tap as the one gesture free to take.

**`static __weak id sg_auxModel;`** (was L16)
> The now playing screen's model for liking, captured below: the only object Spotify gives that
> knows how to put the song into Liked Songs. Absent until that screen has been built once.

**`@protocol SGAuxActions <NSObject>`** (was L26)
> The two sides of Like that Spotify's model answers to; the model is not part of any header the mod
> carries, so it is called through these. The track is asked whether it can be liked at all.

**`if (!SGFlag(SGKeyGestures, NO)) return;`** (was L95)
> The recognizer outlives the switch: it stays on the player once attached, so the switch is
> read here as well and the gesture stops the moment it goes off.

**`UIView *host = tap.view;`** (was L98)
> The host is the queue scrolled sideways, so a tap lands in content coordinates a few million
> points out; its bounds origin is that scroll, and taking it off gives the point on screen.

**`static void yieldSingleTaps(UIView *host, UITapGestureRecognizer *tap) {`** (was L120)
> Spotify's own single tap on the player scrolls it to the cards below, and would fire on the first
> of a pair as well; every one above the artwork is asked to wait for the double tap to miss.

**`static NSUInteger tapsAbove(UIView *host) {`** (was L134)
> Spotify adds its own recognizers as the player's controllers load, which is not ordered against
> this hook: the count of what stands above the artwork is watched so a later one still yields.

**`%hook SPTNowPlayingAuxiliaryActionsModel`** (was L168)
> The now playing screen's own model is built with the screen; held weak so its going away is not
> kept alive, and so the Like action simply does nothing while there is none.

**`%ctor {`** (was L178)
> A single tap on the cover is Spotify's way into the tilt mode, the artwork alone in 3D. That is
> the half of a double tap that misses, so while the zones are on it would open on the way to every
> gesture; the tap goes back to Spotify with the switch.

## `Shared/Gestures/GesturesSettings.m`

**file overview** (was L1)
> The Gestures page: the grid over a player-shaped preview, a cell tapped to say what a double tap
> there does, under it the split, the seek step and a reset.

**`@interface SGZoneGridView : UIView`** (was L20)
> The grid the player is read against, drawn at the size of a phone and read the same way, so what
> the page shows and what the double tap does cannot drift apart.

**`_grid.autoresizingMask = UIViewAutoresizingFlexibleWidth;`** (was L119)
> The table sets its header's width itself, and the grid follows it, so the header never has to
> be handed back during layout: doing that lays the table out again and never settles.

## `Shared/Haptics/ControlHaptics.x`

**file overview** (was L1)
> Vibrations > Controls: a tap for what a finger does to playback, in the full screen player and the
> now playing bar (SGFeedback.m holds which tap each gets).
>
> Buttons: every control's action passes -[UIControl sendAction:to:forEvent:] (target and action) or
> -[UIControl sendAction:] (a UIAction), so the controls are told apart there by accessibility
> identifier, after they have acted. Tree (trees/clean/player/01.txt): id=SPTNowPlayingPlayButton is the
> PlayButtonView (:266, and the sticky header's :492) around the UIButton that acts (CondensedButton, :272),
> in the bar too (trees/clean/home/01.txt:1281); id=SPTNowPlayingPreviousTrackButton and ...NextTrackButton
> are Encore buttons (:257, :282); id=Components.UI.ShuffleButton and Nowplaying-RepeatButton are
> EncoreButtons, UIButtons (:247, :290); id=Components.UI.AddToButton is a UIButton (:205, :425 on a card,
> home/01.txt:1296 in the bar).
> Play or pause is read off the player's state before the button acts, since the tap turns it.
>
> Scrubbing: the position slider is NowPlaying_ECMKit.ProgressBar.Slider, a UISlider
> (id=SPTNowPlayingSliderV2, :216) that overrides UIControl's begin, continue and endTracking
> (objc-methods.txt:83559); a tap when it is taken, a tick at every tenth of the song it passes, a firmer one at
> either end, a soft one when it lets go.
>
> Cover swipes: the player's covers are a list of pages scrolled sideways (AccessibleCollectionView,
> :28) and so are the bar's titles (NowPlaying_BarImpl.InformationCollectionView, home/01.txt:1104);
> a tick when a drag or its fling carries the list past halfway to the next page, where letting go skips.
>
> Gestures (Shared/Gestures) tell of each action a double tap performs; the lyrics page's tap to seek
> plays its tap in Redesigned/Lyrics/SGRKaraokeView.m.

## `Shared/Haptics/Haptics.h`

**file overview** (was L1)
> Vibrations (Mod Settings > Player > Vibrations), under either look: the Taptic Engine answering
> what a finger does to playback (Controls), and playing along with the music (Music Haptics).
>
> SGFeedback.m         which tap each kind of control gets, played while Controls is on
> ControlHaptics.x     the player's and the now playing bar's controls, the scrubber, the cover swipes, the gestures
> MusicHaptics.x       Spotify's audio output listened to, and Core Haptics played along with it
> SGMusicAnalyzer.m    the listening: taps and a rumble out of the samples
> HapticsSettings.m    the Vibrations cards, with each switch's strength and what Music Haptics follows
>
> Everything on them applies at once, without a restart. Everything hooked is Spotify's own (its controls
> by accessibility identifier, its scrubber, its cover and title lists, its audio unit), so all of it works
> on Spotify's own screens and on the redesign's alike. The redesigned lyrics page's tap to seek plays its
> feedback from Redesigned/Lyrics/SGRKaraokeView.m.
> Threading: main thread only.

**`enum {`** (was L31)
> Controls go softer only: most of their taps are UIKit's at full intensity already. Music Haptics goes
> either way: at 200% the rumble reaches 0.7 of the Taptic Engine's most, and most taps their most.

**`NSArray<SGModSection *> *SGVibrationsSections(void);`** (was L72)
> The Vibrations sections of the Player page: a card for Controls and one for Music Haptics, each opening
> out into its settings while its switch is on.

## `Shared/Haptics/HapticsSettings.m`

**file overview** (was L1)
> The Vibrations sections of the Player page, under either look (App/Pages.m puts them there): a card
> per switch, the way the Audio effects page has one per effect, each opening out into its settings while
> its switch is on. Controls has its strength; Music Haptics its strength and what it follows, a choice
> that also says whether the rumble plays, rather than a switch of its own that one choice would leave
> with nothing to do.

## `Shared/Haptics/MusicHaptics.x`

**file overview** (was L1)
> Vibrations > Music Haptics: the Taptic Engine playing along with the song, taps on the drums and a
> rumble under the bass, the way Apple Music's Music Haptics feels, worked out live from the sound.
>
> Spotify plays through Core Audio units of its own (AudioUnitDriver2 in the binary: converter, EQ, mixer
> and a RemoteIO output unit, started with AudioOutputUnitStart(_outputUnit)), with no Objective-C
> method between it and the unit. So Spotify's import of AudioOutputUnitStart is rebound
> (Core/SGRebind.h), and every RemoteIO unit it starts gets a render notify: after each render, the
> buffer bound for the speaker is mixed to mono and handed to the analyzer (SGMusicAnalyzer.h) on
> the render thread, which puts what it hears into a ring of events. That buffer is in the unit's output
> format, the hardware's, not the one Spotify hands the unit (in the simulator 48 kHz float with a buffer
> per channel, whatever the client: harness/audio-effects/sim, harness/haptics/sim), so the analyzer runs at
> the hardware's rate, and a listener on the format follows it to a new one. The render timestamp says when
> that buffer reaches the output; AVAudioSession's output latency (large over Bluetooth) is added, so
> a tap lands when its drum is heard. A thread of this file's own takes the events off the ring and
> schedules them with Core Haptics at those times: each hit a transient, the rumble one looping
> continuous event whose intensity follows the level. The strength scales both as they are played, and
> what Music Haptics follows leaves out the snares' taps (Bass) or the rumble (Beat) there too, so a change
> applies to the next event.
>
> The rebinding and the notify are in place under either look, so the switch works at once;
> with the switch off the notify returns straight away. Nothing listens while Spotify is not the active
> app, since iOS plays no haptics for an app in the background. Sound that is not Spotify's own
> output (Connect, AirPlay to another device, video) never passes the unit, and plays no haptics.
>
> Threading: the notify runs on the render thread and only touches atomics, the analyzer and the
> ring; the Core Haptics objects belong to the player thread; the switch, its settings and the app's
> state are set on the main thread.

**`static const double kQuietAfter = 0.1, kQuietAfterBuffers = 2.5, kEngineStopAfter = 5;`** (was L53)
> Without events for this long, or for this many IO buffers if that is longer, the rumble goes quiet (the
> output stopped rendering), and after the longer wait the engine is stopped.

**`static atomic_uint_fast64_t sg_sampleRateBits, sg_layout;`** (was L67)
> The format of the buffers the notify gets: the rate, and the layout packed into one word so the render
> thread never reads half of a change (flags in the low 32 bits, then channels, then bytes per sample).

**`static OSStatus rendered(void *refCon, AudioUnitRenderActionFlags *flags, const AudioTimeStamp *timestamp, UInt32 bus,`** (was L116)
> The hardware's format is float with a buffer per channel, but it is read rather than assumed (readFormat),
> and buffers not laid out the way it says are left alone rather than read as noise: the format read at the
> start can be a moment old.

**`static void readFormat(AudioUnit unit) {`** (was L187)
> The format the notify's buffers are in: the RemoteIO unit's output side (element 0, output scope), the
> hardware's, not the one Spotify hands the unit (the input scope). A format the analyzer cannot read
> leaves the buffers alone.

**`static os_unfair_lock lock = OS_UNFAIR_LOCK_INIT;`** (was L199)
> Spotify starts its output again after every pause; the format is logged when it is not the last one.
> Spotify's thread and a format change's may both be here.

## `Shared/Haptics/SGFeedback.m`

**file overview** (was L1)
> The taps of Vibrations > Controls, one per kind of control, from UIKit's feedback generators, so they
> feel like the rest of iOS: impacts for a press that does something, selection ticks for a value moving
> under the finger (Apple's Playing haptics: impact complements a physical action, selection a changing
> value). Starting playback is a crisp tap and stopping it a soft one, so the two can be told apart
> without looking.
>
> Controls' strength scales every impact's intensity. A selection tick has no intensity to scale, so under
> 100% it becomes a rigid impact, the nearest thing UIKit has to it, at about a tick's weight times the
> strength; at 100% it stays the system's own tick.

## `Shared/Haptics/SGMusicAnalyzer.h`

**file overview** (was L1)
> Music Haptics' ear: the samples Spotify sends to the speaker turned into what the Taptic Engine plays,
> a tap where a drum hits and a level for the rumble under the bass.
>
> Two bands are listened to, the bass under 110 Hz (kicks) and the top over 2 kHz (snares, claps). A band
> hits when its energy over the last few ms (25 for the bass, a cycle of its lowest notes) rises well
> above its own average of the last second, and may hit again once it has fallen back under that
> average; the top also needs the middle of the sound (250 Hz to 2 kHz) to lift with it, which a snare
> or a clap does and a hi-hat does not. A tap's intensity is how far over the average the hit went,
> scaled by how loud the band is against its recent peak, and its sharpness is how bright the sound is.
> The level follows the bass envelope against the same peak, so quiet passages rumble less.
>
> Tuned on the Mac against librosa's onsets for a 172 BPM track (precision 0.88, recall 0.82, 3.3 taps a
> second) and a synthetic 124 BPM beat over a held bass (57 of 58 kicks and all 29 snares, no hi-hats).
>
> Plain C over a struct the caller owns: it runs on Core Audio's render thread, so nothing here
> allocates, locks, logs or sends a message. Compiles on the Mac as is, for tuning against a file.

## `Shared/Haptics/SGMusicAnalyzer.m`

**`typedef struct {`** (was L13)
> How far over its average a band's energy has to go to hit, how far under it to hit again, how much it
> has to have risen over the last SGMusicAttackHops (a swell rises too slowly), the rest after a hit,
> the dB over the threshold that makes a tap as strong as it gets, how quiet the band may be and still
> hit, and the level a band is called loud at even when it has not been louder lately. The energy a
> band is judged by is the mean of its last `windowHops`, which for the bass has to span a cycle of a
> 40 Hz note (25 ms), or the note's own ripple reads as hits. `midRatio` is how far over its own average
> the middle of the sound (250 Hz to 2 kHz, over the bass that fills the whole) has to go at the same
> time: a snare or a clap lifts it, a hi-hat hardly does.

**`static const int kMaxRisingHops = 3;`** (was L30)
> A hit keeps rising for at most this many hops before it is taken at its highest. Longer finds no
> more hits (a 172 BPM track gave 3.2 taps a second at 2, 3 and 5) and only makes every tap later.

**`static const float kLouderRatio = 4;`** (was L35)
> A hit this much louder than the last one is taken even while the band rests, once this long has passed:
> a soft rise just before a big one would otherwise hold the big one back.

**`static float track(SGMusicAnalyzer *analyzer, SGMusicBand *band, int windowHops, double energy, double *average) {`** (was L113)
> Moves a band on by one hop's energy: the energy of its last `windowHops` hops, and the average of the
> last second before this hop in `average`.

**`band->pendingTime = time - (uint64_t)(0.5 * tuning->windowHops * hop * analyzer->ticksPerSecond);`** (was L185)
> The window crosses the threshold about when half of it holds the hit, so the hit began half a
> window back; a haptic lands a touch after its sound rather than before.

## `Shared/HeadGestures/HeadGestures.h`

**file overview** (was L1)
> AirPods gestures (Mod Settings > Player > AirPods gestures), under either look: with AirPods in,
> moving the head runs one of the player's actions. A double nod likes the song (or whatever it is
> set to), a shake of the head skips it. The motion comes from the AirPods' own sensors through
> CoreMotion, so nothing is heard or recorded: only how the head turns.
>
> HeadGestures.m          the CoreMotion manager, the recognizer and the actions it runs
> HeadGestures.x          the %ctor that starts it at launch when the switch is on
> HeadGesturesSettings.m  its page, opened from the Player page
>
> It reads the same action list as the double tap zones (Shared/Gestures), so a nod and a shake are
> set to any of those, liked songs included. The switch, the two choices and the motion prompts apply
> at once; everything else about the feature lives at launch.
> Threading: main thread only. The AirPods' samples arrive on the main queue.

## `Shared/HeadGestures/HeadGestures.m`

**file overview** (was L1)
> The AirPods gesture engine: listens to the AirPods' motion through CoreMotion, watches how the head
> turns and runs the player action the two gestures are set to. Nothing but rotation is looked at.
>
> A gesture is a run of "strokes": one stroke is the head turning one way, and the next turn the other
> way is the next stroke, so a stroke ends where the rotation rate passes back through zero or turns
> around. A double nod is four strokes on the pitch axis (down, up, down, up); a shake is three on the
> yaw axis (left, right, left). A run counts only when the strokes alternate, each is quick enough and
> far enough, they fall within one short window, the right axis leads the others, and the head is not
> being jostled by walking. The result is one action per gesture, held off for a moment afterwards.

**`static const double kOnset = 0.7;`** (was L31)
> Rotation rate above which the head counts as turning, and the peak a stroke must reach, both in
> radians a second.

**`static const double kDominance = 1.6;`** (was L42)
> The gesture's axis must lead the other by this much, and the head must be stiller than this (in g's)
> so a nod while walking is not taken.

**`[self updateListening];`** (was L107)
> The first call asks for Motion & Fitness; the samples only start once the AirPods are connected
> and the sound is coming out of them.

**`static CMHeadphoneMotionManager *sgStatusManager(void) {`** (was L265)
> A manager of its own for the questions the page asks: one exists whether or not the feature is
> listening, and building one starts nothing.

## `Shared/HeadGestures/HeadGestures.x`

**file overview** (was L1)
> Starts the AirPods gesture engine at launch when its switch is on. The switch itself starts and
> stops the listening live from the settings page; nothing here runs at launch for anyone who has
> never turned it on.

## `Shared/HeadGestures/HeadGesturesSettings.m`

**file overview** (was L1)
> The AirPods gestures page: the switch, what a double nod and a shake of the head do, and what the
> listening is doing at the moment. The actions are the double tap zones' list, so a gesture is set to
> any of them and the names cannot drift apart.

## `Shared/LiveActivity/LiveActivity.h`

**file overview** (was L1)
> The Live Activity (Mod Settings > Live Activity), on the lock screen and in the Dynamic
> Island (iOS 17+), under either look: it draws on no Spotify screen of its own. In one of three views: the line being sung with the next one under it, the tracks
> up next (a tap on one skipping ahead to it), or the control menu, tabs of Controls (previous, play and
> pause, next, shuffle, repeat), Queue and a sleep Timer of the mod's own that pauses Spotify.
>
> LiveActivity.x              polls the player, sends the activity a new state when what it shows changes
> LiveActivityBridge.swift    ActivityKit, which is Swift only
> LiveActivityShared.swift    the attributes and the taps' intents, compiled into the extension too
> LiveActivitySettings.m      its page, opened from the root of Mod Settings
>
> Every tap in the card runs an intent inside Spotify and takes a second or two to show on the card.
>
> The widget is extension/LiveActivity, built into the IPA by scripts/build-extension.sh; the tap's
> intent runs in Spotify, so scripts/merge-appintents.py adds it to Spotify's App Intents metadata. The lines and
> the clock come from Shared/Lyrics, the queue from the player's state. The switch and the view apply at
> once: iOS lets an activity start only while the app is in front, which it is when the switch is flipped.
>
> The Swift names crossing into the widget (SGLyricsAttributes, the two intents, the notifications)
> are a contract with extension/LiveActivity and with the App Intents metadata merged into Spotify:
> ActivityKit and App Intents pair the two processes by type name, so a change here is a change there.
> Threading: main thread only.

## `Shared/LiveActivity/LiveActivity.x`

**file overview** (was L1)
> Polls the player and sends the activity a new state only when what its view shows changes: the
> lyrics' line, what is up next, the control menu's tab, track, shuffle, repeat or sleep timer, or a
> pause. The view is read on every tick, so picking another one shows within a tick. Spotify keeps
> playing in the background, so the timer keeps running there too, and with it the sleep timer.
> The activity is started only while the app is in front, the one place ActivityKit allows it.

**`static const NSTimeInterval kPausedTick = 1;`** (was L31)
> Paused, the only thing on the card that still moves is the sleep timer, and a slower tick catches
> its end well within the second the card shows. Four ticks a second for a still card is a wake up
> eighty times a minute for a picture that does not change.

**`static const NSUInteger kUpNextQueue = 4;`** (was L39)
> Tracks up next: the queue view shows four on the lock screen (three in the Dynamic Island), the
> control menu's queue tab three.

**`static void send(NSString *shown, void (^show)(void)) API_AVAILABLE(ios(17.0)) {`** (was L66)
> Sends `shown`, what the activity is to show as one string, unless it is showing that already; starts
> the activity when there is none and the app is in front.

**`static NSString *lyricsLine(NSString *trackID, NSString **next) {`** (was L104)
> The line being sung and the one after it; before the first line, between lines and without lyrics
> at all, a note holds the place.

**`static void checkSleepTimer(id<SPTPlayer> player, SPTPlayerState *state, NSString *trackID) {`** (was L132)
> Pauses once the sleep timer is up: at its end, or just before the end of the track it was set on
> (on the next track, should the length not be known).

**`static void playQueued(NSString *uri) {`** (was L195)
> A tap on a track up next: skips ahead to it, found again by its URI in case the queue moved since
> the card was drawn.

## `Shared/LiveActivity/LiveActivityBridge.swift`

**`private enum Change: Sendable {`** (was L17)
> Updates and ends go out one at a time in the order asked for, since ActivityKit applies
> concurrent ones in whatever order they finish. An update still waiting gives way to a newer one.

**`@objc public static func show(view: Int, paused: Bool, line: String, nextLine: String,`** (was L64)
> A new activity can only be requested while the app is in the foreground; an update works from the background.
> One call per new state. View and tab are SGLiveActivityView's and SGLiveActivityTab's values;
> titles, artists and URIs pair up by index, the tracks up next; timerEnd is nil without a timer.

## `Shared/LiveActivity/LiveActivityShared.swift`

**file overview** (was L1)
> Compiled into both the tweak and extension/LiveActivity: ActivityKit pairs the two sides by the
> attributes' type name and App Intents by the intent's, so this must stay identical in both.

## `Shared/LockScreenArtwork/LockScreenArtwork.h`

**file overview** (was L1)
> The playing track's Canvas as the system's animated now playing artwork: from iOS 26 the lock
> screen plays a looping clip behind the controls the way Apple Music plays an animated cover. It
> draws nothing on Spotify's own screens, so it answers under either look.

**`NSArray<NSString *> *SGAnimatedArtworkKeys(void);`** (was L19)
> Every now playing key this iOS takes a clip under, and the one of them the Canvas goes under with
> the shape it wants there through `aspect`; nil where there is none.

**`NSDictionary *SGArtworkInInfo(NSDictionary *info, id artwork, NSString *key);`** (was L23)
> `artwork` under `key` in a copy of `info`, everything else left as it stands. The lock screen
> lyrics rewrite the dictionary on a timer, so the key is put back on every one that passes.

## `Shared/LockScreenArtwork/LockScreenArtwork.m`

**file overview** (was L1)
> What the hook, the harness and the settings share: the order of the sources, which key this iOS
> takes a clip under, and putting one there.

## `Shared/LockScreenArtwork/LockScreenArtwork.x`

**file overview** (was L1)
> The track's Canvas or its album's Apple Music cover as the lock screen's animated artwork. The key
> is put on every dictionary that goes out, so the lock screen lyrics' rewrites carry it too.

**`static NSObject *sg_lock;`** (was L15)
> Spotify sets the now playing info from several threads; what the hook reads is behind the lock and
> everything else is main thread.

**`static void resend(void) {`** (was L79)
> The last dictionary sent again so the system asks for the clip that has just landed, its position
> run on to now. The artist comes off the player rather than out of the dictionary: the lock screen
> lyrics may have put the line being sung there before this hook ever saw it, and a line sent back
> as the track's own would stick until Spotify set the info itself again.

## `Shared/LockScreenArtwork/SGAppleArtwork.h`

**file overview** (was L1)
> Apple Music's animated album cover, looked up the way music.apple.com does it: the web player's own
> token, one catalog search that carries the covers' HLS playlists, and the single MP4 file a
> playlist's stream is cut from. Only the artist and album names go out, never the account.

**`void SGAppleArtworkFind(NSString *artist, NSString *album, BOOL tall, void (^done)(SGCanvas *canvas, NSString *note));`** (was L8)
> `done` runs on the main queue with the clip, or nil and why. `tall` wants the 3:4 cover and takes
> the square one where there is none; otherwise only the square one.

**`NSURL *SGAppleCoverPlaylist(NSArray *albums, NSString *artist, NSString *album, BOOL tall);`** (was L15)
> The cover's playlist out of a search answer's albums, the same artist's and the same album's
> name first, then one that differs only in its edition: "(Deluxe)", " - Single".

## `Shared/LockScreenArtwork/SGArtworkFile.h`

**file overview** (was L1)
> The clip on disk: fetched once into Caches, reshaped once for the now playing key, and kept until
> the cap pushes the oldest out. Everything answers off the main thread.

**`NSURLSessionTask *SGArtworkFetchAside(NSString *identifier, NSString *address, void (^done)(NSURL *file, NSString *note));`** (was L9)
> The same without dropping anything: for a page's own clip, next to the lock screen's. The download to
> cancel, or nil when there is none.

## `Shared/LockScreenArtwork/SGArtworkFile.m`

**`static CGSize shownSize(AVAssetTrack *track, CGAffineTransform *upright) {`** (was L99)
> The size the clip is played at, its rotation applied, and the transform that puts its top left at
> the origin.

## `Shared/LockScreenArtwork/SGCanvas.h`

**`SGCanvas *SGCanvasFromMetadata(NSDictionary *metadata);`** (was L10)
> Spotify's core writes canvas.id, canvas.url, canvas.fileId and canvas.type into the played track's
> metadata, the type spelled IMAGE, VIDEO, VIDEO_LOOPING, VIDEO_LOOPING_RANDOM or GIF.

**`NSData *SGCanvazRequestBody(NSString *trackURI);`** (was L14)
> spotify.canvaz.cache, the service Spotify's own canvases come from: the body asking for one track,
> and the canvas its answer carries back. Type 1, 2 and 3 of its enum are the video ones.

## `Shared/LockScreenLyrics/LockScreenLyrics.h`

**file overview** (was L1)
> The line being sung in place of the artist in the system's now playing: lock screen, Dynamic Island,
> Control Center, CarPlay. There is a Live Activity for it too (Shared/LiveActivity). The
> lines and the clock come from Karaoke.

## `Shared/LockScreenLyrics/LockScreenLyrics.x`

**file overview** (was L1)
> Spotify's now playing info passes through with the artist swapped for the current line, and a timer
> sends it again each time the line changes. Spotify itself only ever sees its own dictionary back.
>
> The timer follows the playback rate rather than running from launch: a paused player's line does not
> move, so working it out four times a second only wakes the phone. The lock screen keeps the line it
> was left on until the sound starts again.

**`static NSArray<NSArray<SGKaraokeWord *> *> *piecesOf(SGKaraokeLine *line) {`** (was L35)
> A line longer than the artist row holds, split into even pieces rather than a full one and a stub.
> Each piece shows from its first word's estimated start.

**`static BOOL playingBy(NSDictionary *info) {`** (was L136)
> Whether the sound is moving. A rate Spotify did not report at all counts as moving: the line would
> stand still either way, and a missing key is no reason to leave the feature switched off for good.

**`%orig(line ? withLine(info, line, elapsed) : withElapsed(info, elapsed));`** (was L168)
> Like the update's own rewrite: the line replaces the artist when there is one, and the clock is
> written either way. Spotify's dictionary keeps every other key.

## `Shared/Lyrics/KaraokeSource.x`

**file overview** (was L1)
> Where the karaoke page gets its lines and its clock. The color-lyrics body is copied as it passes
> the same URLSession delegates AdBlock/AdNetwork.x reads, untouched, and kept per track, since the
> page may open long after the request finished. The clock is SPTEsperantoPlayer's state, asked for on
> every frame: the player is caught the first time the app asks it, and its position runs on by itself.
> With a source of the mod's on, the color-lyrics body is Shared/LyricsSources' to answer and it
> hands the lines over.

**`static const NSTimeInterval kRetryPause = 10, kRetryPauseMost = 60;`** (was L19)
> A track whose request was lost may be asked for again after this long, twice as long after each loss
> in a row up to the most: soon enough for the song still playing, not so soon that a busy server is pressed.

**`static NSMutableSet<NSString *> *sg_asking;`** (was L27)
> Of those, the ones with a request still out or waiting out its pause. A full cache spares their lines
> and leaves them asked for, so no second request runs beside the first.

**`static NSMutableDictionary<NSString *, SPTPlayerTrack *> *sg_seenTracks;`** (was L33)
> Every track the player has reported, by id, so a source can name a track that is not the one
> playing at the moment it is asked: a lyrics request routinely lands a beat before the player
> moves on to its track. The last object seen is kept by pointer so the check on each call is free,
> and its id behind it, since the player hands out a fresh object with every state it reports.

**`static void keep(NSString *track, NSArray<SGKaraokeLine *> *lines) {`** (was L79)
> Main queue only. A full cache is emptied but for the track playing, the one up next and those still
> being asked for; what goes can be asked for again.

**`static void askAgainLater(NSString *trackID) {`** (was L129)
> Main queue only. The track stays asked for through the pause, so the readers asking on every tick
> send nothing until it is over.

**`BOOL lost = SGLyricsReplyFailed(response, error) || status == 401 || status == 403;`** (was L166)
> A refused authorization is lost too: the captured one may have expired, and Spotify's next
> spclient request brings a fresh one.

**`static void remember(SPTPlayerTrack *track, NSString *trackID) {`** (was L249)
> Tracks come in from the player and from every list that reads their metadata, so when the table
> is full it is emptied, all but the track playing, whose name the next lyrics request needs.

**`static void prefetch(SPTPlayerTrack *track, NSString *trackID, SPTPlayerState *state) {`** (was L274)
> With a source of the mod's on, the walk for a track starts the moment the player moves to it and,
> for the track after it, while this one still plays: Spotify asks for a track's lyrics within a
> beat of starting it and gives its card list about a second to load, so an answer that is already
> in is what puts the card there. The track is named here, so no walk waits for a name.

**`@interface SGKaraokeTrackWatcher : NSObject <SGPlayerStateObserver>`** (was L306)
> A new track is noticed where the player is asked for its state, and with nothing on screen nothing
> may ask: the player's own report of the change asks it, so the walk starts at the skip.

**`if (!SGRedesignedUI() && !SGFlag(SGKeyLockScreenLyrics, YES) && !SGLyricsEnabled()) return;`** (was L342)
> The sources that search by name learn the name from the player, so the player is caught
> whenever one is on, not only for the redesign's lyrics and the lock screen.

**`[NSNotificationCenter.defaultCenter addObserverForName:UIApplicationDidBecomeActiveNotification object:nil`** (was L354)
> Spotify's lyrics request can wait for the app to come back, and a walk that failed in the
> background was not kept, so it runs again now, ahead of that request.

## `Shared/Lyrics/KaraokeTiming.m`

**`static const NSInteger kLineBaseMs = 350, kMsPerLetter = 75;`** (was L10)
> A line is sung at about this pace and never takes longer than the gap to the next one. A slow
> line gets at least 60 % of its gap, but not more than 1.8x the estimate, so a long instrumental
> after it does not stretch its last word across the break.

**`static const NSUInteger kSyllableLetters = 3;`** (was L17)
> A syllable of an unspaced script is one character but a whole beat, so it counts for this many
> letters; without it a Japanese line reads as a handful of letters and its sweep finishes early.

**`static NSCharacterSet *unspacedScript(void) {`** (was L45)
> Japanese, Chinese and Korean, and the punctuation set with them. Kana and Hangul are listed as
> well as the ideographs: a line of either is written without spaces just the same.

**`static NSArray<SGKaraokeWord *> *piecesOf(NSString *line) {`** (was L103)
> The line split into what the sweep lights one at a time: words where the script spaces them, a
> syllable at a time where it does not, so a Japanese line sweeps instead of lighting up whole.
> Everything a token holds past its first piece is joined to the one before it.

**`static NSArray<SGKaraokeLine *> *fromProtobuf(NSData *body) {`** (was L204)
> Lyrics { 1 data: { 1 time_synchronized, 2 repeated line: { 1 offset_ms, 2 content } }, 2 colors }
> Not time_synchronized, the lines are plain text and their offsets all 0. The flag alone is not
> trusted: Spotify's page body has come without it for lines its JSON calls LINE_SYNCED, so any
> offset past 0 counts as timed too.

**`static NSArray<SGKaraokeLine *> *fromJSON(NSData *body) {`** (was L226)
> { "lyrics": { "syncType": "LINE_SYNCED", "lines": [ { "startTimeMs": "1234", "words": "..." } ] } },
> or "UNSYNCED" with every start 0.

## `Shared/Lyrics/Lyrics.h`

**file overview** (was L1)
> The lyrics engine: timed lines and the player's clock, for the redesign's Apple Music style lyrics
> (Redesigned/Lyrics/SGRKaraokeView.h) and the lock screen (Shared/LockScreenLyrics). Spotify only
> times whole lines, and so do many sources; every line says how finely it was really timed
> (SGKaraokeTiming), so a line timed by the line lights up whole unless the user asks for the words
> inside it to be estimated (KaraokeTiming.m) and swept. The lines are read from the color-lyrics
> response as it arrives, or handed over by Shared/LyricsSources, and the position from the player's
> state (KaraokeSource.x).

**`SGModSection *SGLyricsSourcesSection(BOOL namingSource);`** (was L11)
> LyricsSettings.m: the Lyrics page's parts (App/Pages.m puts the page together): where lyrics come
> from, naming the source (read by the redesign's lyrics view only), the lock screen, which
> language a line's translation is taken in, of those the lyrics come with (the redesign's lyrics
> being where translations show), and whether lines timed only by the line are swept word by word.

**`#define SGKeyLyricsSimulateWords @"spotifyglass.lyricsSimulateWords"`** (was L20)
> Sweeps a line timed only by the line word by word, on the estimate of when each word is sung, as if
> the source had timed them. Off, such a line lights up whole as it starts. Off by default: the
> estimate is a guess dressed up as timing.

**`typedef NS_ENUM(NSUInteger, SGKaraokeTiming) {`** (was L25)
> How finely a line was timed by where it came from. The words of a line timed by the line are still
> there, each with an estimated time, for a page that wants to sweep them anyway; a line with no time
> at all has start and end 0. Ordered finest first, so a line built from timed words is the default.

**`typedef NS_ENUM(NSUInteger, SGKaraokeAlign) {`** (was L34)
> Which edge a line is laid against. Apple Music puts a duet's second voice against the far one, so
> the two sides of the song read apart; a track sung by one voice stays leading throughout.

**`@property (nonatomic) BOOL joined;`** (was L45)
> Set when nothing separates the word from the one before it, as between Japanese, Chinese or Korean
> syllables: the line lays it flush instead of leaving a space for a word break that is not there.

**`@property (nonatomic, copy) NSString *voice;`** (was L53)
> The voice singing the line, named as the source names it ("v1", "v2"), nil when it names none.
> SGKaraokeAlignVoices turns these into alignments; nothing else reads it.

**`@property (nonatomic, strong) SGKaraokeLine *backing;`** (was L59)
> The (oh, aye) sung under the line, smaller and dimmer, nil for nearly every line. Its words are
> timed like any other and it is lit by the same sweep, a beat behind the line it hangs off.

**`@property (nonatomic, strong) SGKaraokeLine *pronunciation;`** (was L62)
> How the line sounds, written in the Latin alphabet (Apple Music's pronunciation): its words sung
> at the times of the line's own, each starting with the word it spells, and the backing's under the
> backing. nil where the source has none, or where it reads the same as the line.

**`NSInteger SGKaraokeLeadLine(NSArray<SGKaraokeLine *> *lines, NSInteger ms);`** (was L74)
> The one line a place with room for one names as the one being sung at `ms`. Two voices can sing
> over each other, and a line another voice comes in over keeps its place until it is sung out, so
> this is the earliest line still being sung; between lines, the last one begun; -1 before the first.
> The lock screen and the Live Activity show this one.

**`BOOL SGKaraokeUnspacedScript(NSString *text);`** (was L79)
> Whether the text is written in a script that does not space its words, so the pieces of a line
> are words in their own right rather than halves of one.

**`void SGKaraokeAlignVoices(NSArray<SGKaraokeLine *> *lines);`** (was L82)
> Gives every line the alignment its voice earns: the voice heard first leads, the next one to be
> named trails, and any after that lead again. A track naming one voice or none is left alone.

**`NSArray<SGKaraokeLine *> *SGKaraokeLinesFromBody(NSData *body);`** (was L86)
> A color-lyrics body, protobuf or JSON, as lines: timed by the line where Spotify synced it, plain
> (SGKaraokeTimingNone) where it did not; nil for a body with no lines.

**`void SGKaraokeRequestLyrics(NSString *trackID);`** (was L100)
> Asks spclient for a track's lyrics once, with the headers of Spotify's own requests, for when no
> page of Spotify's has asked for them, e.g. with the app in the background.

**`void SGKaraokeAskSpotifyForTiming(NSString *trackID);`** (was L103)
> Asks Spotify's JSON lyrics for the track once, and keeps its lines only if they are more finely
> timed than the ones kept: the lyrics view was left with plain text, and Spotify may have it timed.

**`NSString *SGKaraokeSpotifyAuthorization(void);`** (was L106)
> The Authorization header Spotify's own requests carry, "Bearer ..." and the account's own token;
> nil until one has gone out. Only for a source that answers no one who cannot show they are a
> signed-in Spotify client, and only with the mod's user having switched that source on.

## `Shared/LyricsMeanings/Meanings.h`

**file overview** (was L1)
> What the lines mean: Genius's annotations on the song, matched by their text to the lines the
> lyrics view shows, whichever source those came from. Genius's own web endpoints, which take no key.

**`void SGLyricsMeaningsFor(NSString *trackID, NSArray<SGKaraokeLine *> *lines,`** (was L34)
> The meanings of the lines by index into `lines`, on the main queue: empty when Genius has none for
> the song or it could not be told apart, never called while the setting is off. Genius is asked once
> per track; the matching is done again for each set of lines.

## `Shared/LyricsMeanings/Meanings.m`

**`static NSString *folded(NSString *text) {`** (was L30)
> Letters and digits only, lowercase, accents gone and apostrophes closed up, so "Don’t" and "dont"
> read alike across sources.

**`static NSNumber *songIn(NSDictionary *response, NSString *title, NSString *artist) {`** (was L129)
> The hit whose title and artist both agree with the track's; a song only near it would explain
> lines it does not have.

**`static SGLyricsMeaningAuthor authorOf(NSDictionary *annotation) {`** (was L151)
> By the annotation, not the referent: a referent the artist spoke to is "verified" as a whole, the
> editors' annotations under it too.

**`static NSDictionary<NSNumber *, NSArray<SGLyricsMeaning *> *> *matched(NSArray<SGLyricsMeaning *> *meanings,`** (was L246)
> Each meaning goes to every line its fragment's first matchable line matches, so a chorus explained
> once is explained wherever it is sung.

## `Shared/LyricsSources/BiniLyrics.m`

**file overview** (was L1)
> BiniLyrics, the widest of the sources that serve Apple Music's own TTML: over a million recordings,
> word timed, and no key to ask for. Searched by title, artist and length, so it needs a source
> before it in the order — or the player — to have named the track. The search answers with metadata
> and a link; the TTML itself is a second request, to a plain file host.

**`static const NSInteger kLengthSlack = 4;`** (was L9)
> A recording is only taken when its length is this close to the track's, so the words fall on the
> same beat. The search is by name, and a live or sped up cut of the same song is a different take.

## `Shared/LyricsSources/LrcLib.m`

**file overview** (was L1)
> LRCLIB, the floor of the order. It is an open library with no key and no catalogue to license, so
> it holds what the rest cannot: the tracks Apple's word by word programme never reached, and the
> ones Musixmatch may show nobody. It times lines and not words, which is the whole point of putting
> it last — the estimate inside a line is still a sweep, where Spotify's own lyrics only scroll.
>
> Its /api/get wants the length to agree almost exactly and answers 404 otherwise, so a miss falls
> back to /api/search, which answers with whole recordings to pick the closest of. LRCLIB asks that
> clients say who they are, and the mod does.

**`static NSArray<SGKaraokeLine *> *linesFromLRC(NSString *lrc) {`** (was L21)
> [00:34.30] Look — the timestamp in minutes, seconds and hundredths, or thousandths where a line
> carries three digits. A line may be stamped more than once when it is sung more than once, and
> the tags LRC opens with ([ar:…], [length:…]) are not timestamps, so they fall out on their own.

**`static BOOL betterRecord(NSDictionary *record, NSDictionary *best, NSInteger seconds) {`** (was L98)
> How good a recording is for the track: timed beats untimed, then the closest length. With no
> length to go on, the fullest sheet wins — the search will happily rank a seventeen second stub of
> a song above the song, and a stub is the one thing a length would have caught.

## `Shared/LyricsSources/LyricsHook.x`

**file overview** (was L1)
> Puts the sources' lines on Spotify's lyrics page. Spotify's own color-lyrics 200 gets them swapped in;
> a track Spotify has none for is asked for as the donor track and its 200 carries them instead; the card
> list gets a lyrics section, without which the player never asks for lyrics at all.

**`@interface SGLyricsTaskState : NSObject`** (was L30)
> What a task is and where it stands. The first five are set before the state is attached to its task
> and never change; the rest are read and written under @synchronized on the state, from URLSession's
> delegate queue and the main queue both.

**`static NSURLRequest *donorRequestFor(NSURLRequest *request) {`** (was L93)
> Only a real 200 makes the lyrics card show, so a track Spotify has none for is asked for as the
> donor, whose reply then carries the sources' lines. Everything but the id stays as Spotify sent it.

**`static NSData *decide(NSString *track, SGLyricsResult *chain, NSData *spotifyBody, BOOL donor, NSData *colours) {`** (was L152)
> Which lines Spotify's page and the lyrics view get, the view's kept and credited. The body returned
> is the page's when the sources' lines replace Spotify's, nil when they do not.

**`static NSData *lyricsSection(NSString *track) {`** (was L198)
> A lyrics section Spotify sent for another track carries whatever else a section holds; one made from
> nothing has only the track.

**`static NSData *amendedCardList(NSData *body, NSString *track) {`** (was L211)
> The player asks for lyrics only when the list has a lyrics section, which the server sends only
> for tracks Spotify has lyrics for.

**`static void answerAs(NSURLSessionTask *task, NSHTTPURLResponse *response) {`** (was L247)
> Spotify may read the status off the task as well as the delegate argument. The task classes are
> private and differ between OS versions, so the one answering is taken from the first task that needs it.

**`static void give(id delegate, NSURLSession *session, NSURLSessionDataTask *task, SGLyricsTaskState *state, NSData *body) {`** (was L274)
> Received by a normal message send, so every hook on the selector sees it; this file's own lets it
> through by the object, since the server's bytes may be the same.

**`static void answerDonor(NSURLSessionDataTask *task, SGLyricsTaskState *state, SGLyricsResult *chain,`** (was L326)
> A donor 200 goes through only with lines to put in it: once Spotify has seen a 200 it cannot be
> turned into "no lyrics", and the donor's own lines must never show.

**`static void answerMissing(id delegate, NSURLSession *session, NSURLSessionDataTask *task, SGLyricsTaskState *state,`** (was L345)
> URLSession's handler waits until the body is in and Spotify's delegate has chosen, so none of the
> server's own bytes can reach the delegate ahead of it.

**`%hook SPTPlayerTrack`** (was L556)
> Spotify's own verdict is noted before it is overridden, for the donor to go by. The getter runs for
> every track in every list many times a second, so it does a few lookups and nothing more.

**`SEL selector = @selector(dataTaskWithRequest:);`** (was L599)
> The generator gives a class that only inherits the method an override of its own, which would
> put a second hook in front of NSURLSession's.

## `Shared/LyricsSources/LyricsSources.h`

**file overview** (was L1)
> Where lyrics come from. Every source answers the same question — what are this track's lines, and
> how finely are they timed — and the chain asks them in the order the Lyrics page puts them in,
> keeping the best answer rather than the first: a source with only plain text does not shut out a
> later one that times every word.
>
> SGTTML.m reads the TTML that Apple Music's own lyrics are written in, which is what BiniLyrics and
> Unison serve. It and Spicy Lyrics are the only shapes carrying a second voice and the (oh, aye)
> sung under a line; every other source times lines, or the words inside them, and nothing more.

**`#define SGKeyLyricsProviders @"spotifyglass.lyricsProviders"`** (was L14)
> The sources in the order they are asked, as their keys. Unset means the order below, so a source
> added in a later version joins the end of everyone's list instead of shuffling it.

**`#define SGKeyLyricsTranslationLanguage @"spotifyglass.lyricsTranslationLanguage"`** (was L21)
> The language a line's translation is asked for in, as an index into SGLyricsTranslationLanguages;
> unset or 0 takes whatever translation the source has.

**`@property (nonatomic, copy) NSArray<NSNumber *> *starts;`** (was L30)
> Every line as Spotify's lyrics page takes it: ♪ over a break and an empty last line where the
> singing ends. Starts are in milliseconds, all 0 when not synced. nil when a source times words
> but has no text for Spotify's own page.

**`@property (nonatomic, copy) NSString *title, *artist, *album;`** (was L36)
> What the source learned about the track on the way, for the sources asked after it: one that
> matched the track by Spotify's id knows the title and artist the ones searching by name need.

**`@interface SGLyricsQuery : NSObject`** (was L43)
> What is known about the track when a source is asked. Only trackID is always there; the rest is
> filled in by the player, and by whichever source answered before.

**`@property (nonatomic) BOOL needsName;`** (was L61)
> Searches by title and artist, so it has nothing to ask with until someone has named the track.
> Musixmatch and Spicy Lyrics match by Spotify's id and can go without.

**`NSArray<NSString *> *SGLyricsOrder(void);`** (was L70)
> The keys in the user's order, the ones switched off left out. An empty list means the mod leaves
> Spotify's own lyrics alone.

**`void SGLyricsPrefetch(NSString *trackID);`** (was L80)
> Starts the walk for a track before anyone has asked, so the answer is in when Spotify's request
> comes; a walk already run or running is left alone. Safe from any thread.

**`NSInteger SGLyricsSpotifyHas(NSString *trackID);`** (was L83)
> What Spotify's own metadata says of a track: 1 has lyrics, 0 has none, -1 not seen yet. The
> player-track hook notes it; the request hook reads it to send a track Spotify has none for to
> the donor. Safe from any thread.

**`id SGLyricsForcedFlag(NSString *key);`** (was L88)
> The remote-config values the lyrics feature forces while a source is on, nil for any other flag:
> the player gives its cards this long to load before it shows the list without the slow ones, and
> a source of the mod's can take longer than Spotify's default to answer.

**`void SGLyricsPostJSON(NSURL *url, NSDictionary<NSString *, NSString *> *headers, id body, void (^done)(id root));`** (was L104)
> For the one source that is asked a question rather than sent to an address. body is anything
> NSJSONSerialization writes; nothing is sent at all when it is not.

**`void SGLyricsNoteReply(NSURLResponse *response, NSError *error);`** (was L107)
> Every source's reply goes through this, so a walk that lost a request to the network or a busy
> server is not kept as "no lyrics". The two above call it themselves.

**`NSArray<SGKaraokeLine *> *SGTTMLLines(NSString *xml);`** (was L113)
> SGTTML.m. Apple Music's TTML as timed lines, the voices already turned into alignments and each
> line's translation and pronunciation added where the head has them; nil when the document holds no
> line the page could show.

**`NSArray<NSString *> *SGLyricsTranslationLanguages(void);`** (was L118)
> The languages a translation can be asked for in, as language tags ("en", "es"), the first one ""
> for whatever the source has; SGKeyLyricsTranslationLanguage indexes it, so it only ever grows at
> the end. Their names, in English, for the Lyrics page.

## `Shared/LyricsSources/LyricsSources.m`

**file overview** (was L1)
> The chain: every source in the order the Lyrics page puts them in, asked one after another, the
> first with timed lyrics answering for the track.
>
> Stopping at the first answer is what makes the lyrics card under the player appear at all. For a
> track Spotify has no lyrics of its own for, the card is only offered when the answer to Spotify's
> lyrics request arrives within about a second of the player building its list of cards; a walk that
> went on through every source for word timing took three seconds and more, and the card never came.
> So the order is the priority, as it reads on the Lyrics page: a source further down is only asked
> when those above it had nothing timed, and then only for what they lacked.

**`static NSString *const kLegacyMusixmatch = @"spotifyglass.musixmatchLyrics";`** (was L19)
> What the switches were called while Musixmatch was the only source; read once, to carry an
> existing install's settings over to the order.

**`static _Atomic NSUInteger sg_failures;`** (was L36)
> Every request any source has lost to the network or to a server too busy to answer, counted so a
> walk can tell "no source has lyrics" from "a source could not say". Only the first is kept.

**`provider.needsName = ![@[@"musixmatch", @"spicylyrics"] containsObject:key];`** (was L149)
> A source that matches by Spotify's own track id has everything it needs from the
> start; the rest wait for the player to name the track before they can search.

**`static NSArray<NSString *> *fromLegacyKeys(void) {`** (was L174)
> An install from before the order existed keeps what it had: the sources it was using, in the only
> order there was. Nothing is switched on for it that it had not already asked for.

**`static SGLyricsQuery *queryFor(NSString *trackID) {`** (was L208)
> The player knows every track it has played by name, which is what every source but Musixmatch
> searches by. The track is looked up by id rather than compared with the one playing now: a lyrics
> request often lands a beat before the player moves on to its track, and comparing then left the
> query nameless. A track the player has not reported starts with nothing, and the first source
> that matches by id fills the rest in.

**`static NSMutableDictionary<NSString *, NSNumber *> *sg_spotifyHas;`** (was L242)
> Spotify's own has_lyrics per track, as its metadata said. The player's metadata is read many
> times a second while a list scrolls, so a value already noted costs one lookup and no write.

**`static BOOL betterLines(SGLyricsResult *merged, SGLyricsResult *fresh) {`** (was L258)
> Whether the source's lines are better than what the walk already has: any lines beat none, and
> finer timing beats coarser — words timed beat a line's start, which beats plain text. Read off the
> lines themselves, which say how they were really timed, rather than off what the source claimed.

**`static const NSTimeInterval kNameWait = 1.5, kNamePoll = 0.1;`** (was L280)
> How long a lyrics request waits for the player to name its track before the walk starts without a
> name. The request routinely lands a few hundred milliseconds before the player reports the track
> it belongs to, and a walk started in that gap passes over every source that searches by name.

**`static void finish(SGLyricsWalk *walk) {`** (was L304)
> A walk that ends with nothing is only an answer when every source got to search. One that passed a
> source over for want of a name asked it nothing, and keeping that as "no lyrics" would stick to the
> track: every later request would get the kept nil, and the lyrics card would be taken off the track
> for the rest of the session. The same goes for a walk during which a request failed: a busy
> server's 503 read as "no lyrics" hid a track's lyrics until Spotify was restarted.

**`if (walk.passedOver.count && named(query)) {`** (was L345)
> A source that matches by id named the track partway down: the ones passed over ask now,
> in the order they came in. Once, since they cannot be passed over again with a name.

**`static void whenNamed(NSString *trackID, NSTimeInterval waited) {`** (was L400)
> Starts the walk as soon as the player has named the track, or once it has waited long enough
> that it is not going to: a track opened for something other than what is playing is never named.

**`id SGLyricsForcedFlag(NSString *key) {`** (was L468)
> The cards under the player load together, and the list is shown without any card still loading
> once this many milliseconds have passed (NowPlaying_ScrollImpl's scrollCardsAsyncLoadingTimeoutMs,
> 2 s unless the server says otherwise, 1 s at the least). The lyrics card is one of them and waits
> for the color-lyrics reply, which with a source of the mod's on comes after the chain has answered;
> so the wait is set to the most the flag allows.

**`void SGLyricsMigrateLegacyKeys(void) {`** (was L524)
> Once, at launch: the keys Musixmatch owned alone become an order, so the Lyrics page opens on what
> the install was already doing rather than on nothing.

## `Shared/LyricsSources/Musixmatch.m`

**file overview** (was L1)
> Lyrics from Musixmatch. It is the catalogue Spotify licenses, and for part of it Musixmatch also
> has the time of every word (richsync), which Spotify never sends. The token is an anonymous one
> asked for as Musixmatch's iOS app, so Musixmatch learns the track's id and nothing of the Spotify
> account. It is the one source that matches by Spotify's own track id, so it never has to guess at
> a title, and what it learns about the track is passed to the sources asked after it.

**`static SGKaraokeLine *richsyncLine(NSDictionary *entry, NSInteger start, NSInteger end) {`** (was L108)
> [{ "ts": 27.16, "te": 28.25, "x": "I've been tryna call", "l": [{ "c": "I've", "o": 0.03 }, { "c": " ", "o": 0.41 }, …] }]
> o is from the line's start. A space entry ends the word before it; a word can come in more than
> one entry ("Milion", "+", ","), so everything between two spaces is one word.

**`last.end = MAX(at, last.start);`** (was L132)
> A syllable of an unspaced script stands as a word of its own. Musixmatch times each one,
> but sends no space to end it, so running them together is what left a Japanese or Chinese
> line lighting up whole instead of sweeping.

**`static SGLyricsResult *fromSubtitles(id body) {`** (was L182)
> [{ "text": "Yeah, yeah", "time": { "total": 3.32 } }, …, { "text": "", "time": { "total": 241.15 } }]
> An empty text is a break, and the last one marks the end.

**`static SGLyricsResult *withTrack(SGLyricsResult *lyrics, id track) {`** (was L246)
> What the matcher settled on, kept even when Musixmatch may show no lyrics: the sources asked after
> this one search by name, and this is the best name anyone has.

## `Shared/LyricsSources/NetEase.m`

**file overview** (was L1)
> Word timing from NetEase Cloud Music, for the tracks the other sources only line-time, e.g. most
> of Eminem. It has no text of its own to offer Spotify's page, only the time of every word, so it
> earns its place at the end of the order rather than the front. Searched by title, artist and
> length; NetEase censors swear words with asterisks.

**`static const NSInteger kLengthSlack = 3;`** (was L9)
> A NetEase recording is only taken when its length is this close to the track's, so the words fall
> on the same beat.

**`static NSArray<SGKaraokeLine *> *linesFromYrc(NSString *yrc) {`** (was L31)
> [43060,3600](43060,120,0)To (43180,330,0)seize (43510,420,0)everything …
> A line's start and length in ms, then each piece's start and length before its text. A piece not
> ending in a space runs on into the next one ("wanted" "…"), as in richsync.

**`BOOL unspaced = SGKaraokeUnspacedScript(text);`** (was L55)
> yrc times a Chinese or Japanese syllable a piece at a time and never spaces them, so
> each one is a word of its own; only a spaced script runs its pieces together.

**`SGLyricsAsk SGNetEaseAsk = ^(SGLyricsQuery *query, void (^done)(SGLyricsResult *result)) {`** (was L103)
> A recording is only taken when its length is this close to the track's, so the words fall on the
> same beat as the recording Spotify is playing.

## `Shared/LyricsSources/SGTTML.m`

**file overview** (was L1)
> TTML, the shape Apple Music writes its lyrics in and the one BiniLyrics and Unison serve.
>
> <p begin="0:13.148" end="0:15.705" ttm:agent="v1">
> <span begin="0:13.148" end="0:13.385">You</span> <span …>called</span>
> <span ttm:role="x-bg"><span begin="0:15.083" end="0:15.401">(Aye,</span> …</span>
> </p>
>
> Two things here exist in no other source the mod reads. ttm:agent names the voice, which is how a
> duet ends up on two sides of the page; a span with the x-bg role holds the backing vocals sung
> under the line. The third is quieter but matters more: the spans of a Japanese or Chinese line sit
> flush against each other with no whitespace between them, and that is the only way to tell that a
> syllable continues a word rather than starting one.
>
> The head can carry the lines again in two more ways, each keyed to its line by the itunes:key of
> the <p>: Apple's translations, as text, and its pronunciations (transliterations), spelt in the
> Latin alphabet and timed by spans that start with the words of the line they spell out.
>
> <iTunesMetadata><translations><translation xml:lang="en-US"><text for="L1">I'm so drunk …
> <transliterations><transliteration xml:lang="ja-Latn"><text for="L1"><span begin=…>zenbu</span> …

**`static NSInteger msOfClock(NSString *clock) {`** (was L22)
> A begin or end: seconds ("1.241"), minutes ("0:01.241"), hours ("1:02:03.456"), or a clock value
> with a unit after it ("1.5s", "500ms"). Negative on a value that is none of these.

**`if (_word) return;`** (was L155)
> A span nested inside one that is already being read is ruby or a translation: its characters
> belong to the word around it rather than making a word of their own.

**`static NSString *bareText(NSString *text) {`** (was L267)
> The letters and digits alone, lowercased: a pronunciation or a translation that reads the same as its
> line is the line again, as an English line of a Japanese song is spelt out as itself.

**`static NSString *translationLanguage(NSArray<NSString *> *languages) {`** (was L280)
> The translation the Lyrics page asks for: the one in that language, whichever the region ("en"
> takes "en-US"), and none in any other; with no language asked for, the first the document has.

**`parser.shouldProcessNamespaces = NO;`** (was L347)
> The TTML namespaces carry nothing the reader needs, and the prefixes it matches on
> ("ttm:agent") only survive while they are left alone.

## `Shared/LyricsSources/SpicyLyrics.m`

**file overview** (was L1)
> Spicy Lyrics, the source behind the Spicetify extension of the same name (spicylyrics.org). Like
> Musixmatch it is asked by Spotify's own track id rather than by name, so it never answers with a
> live cut of the song by mistake; unlike Musixmatch, what it has is Apple Music's syllable timing,
> down to the backing vocals and the two sides of a duet.
>
> Its Developer Platform API returns the best sync from its catalogue and names the provider it
> chose. The user supplies a publishable client key; it is kept in Keychain, never in preferences.

**`typedef NS_ENUM(NSInteger, SGSpicyOp) {`** (was L86)
> Legacy packed replies use [values, stream]: every distinct string, number, boolean and null in the document, and
> a stream of integers rebuilding it. A number at or above zero is an index into the values; below
> zero it opens a structure. Straight from the extension's own packer, which is the only writer of
> this shape there is.

**`static const NSUInteger kMaxDepth = 64;`** (was L99)
> Deep enough for any lyrics document and shallow enough that a malformed reply cannot run the
> stack out: the shape below nests six levels, not sixty.

**`NSInteger count = op == SGSpicyOpObject || op == SGSpicyOpArray || op == SGSpicyOpRows ? nextNumber(reader) : 0;`** (was L152)
> A count is read before anything is built with it, so a reply claiming a million keys cannot
> have a million slots reserved for it before the stream is found to be shorter than that.

**`if ([packed isKindOfClass:NSDictionary.class]) return packed;`** (was L221)
> Should the server ever answer a caller of ours with the document itself, it is already what
> the rest of this file wants.

**`static NSArray<SGKaraokeWord *> *wordsFrom(NSArray *syllables) {`** (was L255)
> One voice's syllables as words. A syllable is a piece of a word — the API marks the ones that run
> into the next with IsPartOfWord, which is the same thing the mod calls a word being joined to the
> one before it, read from the other end.

**`NSMutableArray<SGKaraokeWord *> *backing = [NSMutableArray array];`** (was L300)
> The (oh, aye) sung under the line. The API keeps it in groups, one per run of it; the page
> has one backing line under each line, so the runs read on as one.

**`if ([vocal[@"OppositeAligned"] boolValue] || [lead[@"OppositeAligned"] boolValue]) {`** (was L308)
> The far side of a duet. The API says outright which lines belong to the second voice, so
> unlike TTML there are no voices here to work an alignment out from.

**`static NSArray<SGKaraokeLine *> *linesFromLines(NSArray *content) {`** (was L318)
> Content: [ { Type: "Vocal", Text, StartTime, EndTime } ] — timed by the line, the words inside it
> left to the mod's own estimate, as Spotify's own lines and LRCLIB's are.

**`static NSString *shapeOf(NSDictionary *document) {`** (was L333)
> What the server actually sent, named rather than quoted: the field names and counts, never the
> words. For telling a document that has no timing from one whose timing we failed to read.

**`if (document[@"source"]) [shape appendFormat:@" source=%@", document[@"source"]];`** (was L349)
> Whose words these are, where the document says so: a static reply is text Spicy is passing on
> from somewhere else, and its name tells us why it came without timing.

**`SGLyricsAsk SGSpicyLyricsAsk = ^(SGLyricsQuery *query, void (^done)(SGLyricsResult *result)) {`** (was L359)
> Uses the official Developer Platform API and a user-supplied publishable key. Secret keys never
> ship in this client; the API's native-client no-Origin option must be enabled for the key.

**`NSMutableArray<NSNumber *> *starts = [NSMutableArray array];`** (was L401)
> The words with nothing to time them by: the page shows them, and a source under this
> one in the order can still time them.

## `Shared/LyricsSources/Unison.m`

**file overview** (was L1)
> Unison, the lyrics people write for Better Lyrics by hand. It is a small corpus next to the rest,
> but what is in it is Apple Music's own TTML at its best, so it earns being asked early: what it
> misses the next source answers, and what it has beats what that source would have given.
>
> Reads need no key. The write half of its API — submitting, voting, reporting — is signed, and the
> mod does none of it: it asks for lyrics and nothing else.

## `Shared/Navigation/Links.h`

**file overview** (was L1)
> Opening a spotify: URI the way the app opens a link of its own, through its link dispatcher: the
> tabs of the mod's own on either look's bar, the redesigned player's lyrics glyph.

**`typedef NS_ENUM(NSInteger, SGLinkRoute) {`** (was L9)
> Whether the dispatcher has somewhere to send a URI, asked the way it asks itself before it opens
> one: every handler in its URI subtype registry is asked -URISubtypeHandlerCanHandleURI:, then the
> same again for the URI its fallback resolver remaps an unhandled one to. None of them saying yes is
> what ends in Spotify's "Couldn't open link" alert.

**`SGLinkRoute SGSpotifyURIRoute(NSURL *uri, NSString **via);`** (was L18)
> `via`, when given, is the class of the handler that said yes, prefixed "remap <uri> " when it took
> the fallback resolver's URI; nil otherwise.

**`NSURL *SGSpotifyURIFromText(NSString *text);`** (was L22)
> What someone typed or pasted as a link, as a spotify: URI: surrounding blanks trimmed, and a share
> link (https://open.spotify.com/[intl-xx/]playlist/<id>?si=…) turned into spotify:playlist:<id>.
> nil when there is nothing a URI can be made of.

## `Shared/Navigation/Links.x`

**file overview** (was L1)
> The dispatcher is a singleton the app builds at startup; -setMainUILoaded: is the last call of its
> setup (objc-methods.txt:38809).

**`static id sg_send(id target, NSString *selector) {`** (was L23)
> The chain a spotify: link takes in 9.1.78, read off the binary: -[SPTLinkDispatcherImplementation
> navigateToURI:…] hands it to the URI scheme dispatcher, whose "spotify" handler is the dispatcher's
> -spotifyLinkHandler (SPTSpotifyLinkHandler). That one passes the cleaned URI to its
> -URISubtypeRegistry (SPTURISubtypeRegistryImplementation), which keeps the handlers of its -handlers
> hash table that answer -URISubtypeHandlerCanHandleURI: YES and opens with the first by priority;
> pages go through Navigation's PageResolverURISubtypeHandler. With no taker, -handleSpotifyURL:
> tries again once with -remapURI: (its fallback resolver's URI), and only then shows the alert.

**`static NSString *takerFor(id<NSFastEnumeration> handlers, NSURL *uri, NSUInteger *asked) {`** (was L42)
> The class of the first handler that takes `uri`, nil for none. A handler whose name says it only
> listens (Jam's SGSNavigationURIHandledEventSource) is not asked, so a question is not taken for a
> navigation.

## `Shared/Navigation/PageTransition.x`

**file overview** (was L1)
> Page transitions: coming back to a page that has no navigation bar of its own — Home, the full
> screen search — the page is laid out 54pt low, and drops into place about half a second later.
>
> Spotify's Liquid Glass path is what does it. -[SPNavigationController
> navigationController:willShowViewController:animated:] settles what the bar is to do, and for a
> page that wants it gone the call that would do it is -[SPNavigationController
> setNavigationBarHidden:]. With +[SPTLiquidGlass isEnabled] answering yes and a transition
> running, that call is not made there: the bar's alpha alone is animated away and the call is left
> to the transition's completion block. So the bar is invisible but still on the controller for the
> whole transition and a while after — measured at 534ms, from willShow to the bar going — and its
> 54pt still count against the page: Home's header lands at y 116 instead of 62 and its list is
> inset 166 instead of 112 (trees/test5.txt against trees/test6.txt, the same screen a moment
> later), until the bar goes and the page jumps up. Liquid Glass is on for iOS 26 unless the app
> opts out in its Info.plist, so this is every build of Spotify on iOS 26, with or without the mod.
>
> So the bar is taken away at the start of the transition instead: the same call Spotify's own
> completion block makes, made 534ms earlier, while the page is still coming in. Animated, so that
> UIKit takes the bar out over the transition the way the alpha used to and the page has its own
> height from the first frame. Compensating the page instead — handing it those 54pt back as a
> negative additionalSafeAreaInsets — is what this hook did first, and it did nothing at all: the
> page's safe area reads 62 with the bar up, so the 54pt reach the page through Spotify's own
> layout guide (SessionContainerServiceImpl.provideMainContentLayoutGuide, whose observers are told
> through layoutGuideChanged), not through UIKit's safe area, and there is nothing to compensate.
>
> The cost is that the page being left behind is measured against the bar too, and reflows by the
> same 54pt as it slides away under the swipe. It is on its way off screen, which is the better
> place for the jump than the page being arrived at. A cancelled swipe puts the bar back on its
> own: Spotify's completion block sees the cancellation and asks for the state again, which for the
> page that stayed is a bar shown.
>
> Tree (trees/test5.txt): UILayoutContainerView holds UINavigationTransitionView and, beside it,
> SPNavigationBar {{0, 62}, {402, 54}} at alpha 0, gone from the tree altogether once the page has
> settled (trees/test6.txt).

**`static BOOL wantsNoBar(UIViewController *page) {`** (was L45)
> The two questions SPNavigationController itself asks the page before it hides the bar: a page
> that asks for the glass bar is given one, however hidden it says it wants the bar to be.

## `Shared/Player/PlayerEvents.h`

**file overview** (was L1)
> The full screen player's open and close, for whatever must stand still while it animates (the
> karaoke card puts its display link down, the redesign holds heavy work back). Both looks' players are
> presented by Spotify's own presentation controller, so one announcement serves both.

**`extern NSString *const SGPlayerTransitionNotification;`** (was L6)
> Posted as the player starts to open or close, before the animation runs, and again once it is
> over; SGPlayerTransitionEnds says when it is expected to be over (as CACurrentMediaTime), 0 when none runs.

## `Shared/Player/PlayerEvents.x`

**file overview** (was L1)
> The player's open and close, told from the appearance callbacks of a controller inside the player,
> which UIKit sends as the presentation or the dismissal begins, whatever animates it; the transition
> coordinator says when it is over, a cancelled swipe included. Spotify 9.1.78 presents the player
> through SPTBarInteractivePresentationController, never through NowPlaying_ViewPageImpl's
> Show/CloseFullscreenAnimatedTransitioning animators, whose hooks never once fired.

## `Shared/Player/PlayerState.h`

**file overview** (was L1)
> What Spotify's player is doing, read through one hook so no feature of the mod hooks the player a
> second time, and under either look: the state is data, not a screen.
>
> -[_TtC23NowPlaying_PlatformImpl28StatefulPlayerImplementation player:stateDidChange:]
> (objc-methods.txt:60654) is the now playing platform's own player observer, and until that has
> reported, an observer of the mod's added to the first SPTEsperantoPlayer the app adds one to
> (-[SPTEsperantoPlayer addPlayerObserver:], :35729).
>
> Threading: the player reports from several threads and everything here is moved onto the main one,
> so observers are called there.

## `Shared/Player/PlayerState.x`

**`%hook SPTEsperantoPlayer`** (was L76)
> Observers are added from several threads as the app starts; the first player seen is the one
> watched, the way KaraokeSource.x takes the first player the app asks.

## `Shared/Player/SGTimePitch.h`

**file overview** (was L1)
> The player menu's Speed and Pitch applied to sound: Apple's own time and pitch unit (AUNewTimePitch,
> the one behind AVAudioUnitTimePitch), which plays its input faster or slower at the same pitch (rate),
> and higher or lower at the same speed (semitones).
>
> It takes its input one of two ways:
>
> - Pulled from a source: the unit asks the source for about rate times the frames it hands back, so a
> rate over 1 consumes the music faster. This is how speed works, the source being Spotify's mixer.
> - In place: the buffer is pushed into a FIFO and the unit pulled for as many frames as came in, rate 1
> only. This is pitch alone on a finished buffer, when there is no source to pull.
>
> Measured on the Mac (harness/pitch): the pitch exact to 0.01% at any rate, the rate exact in frames
> consumed, about 0.2% of a core, and the sound 4096 frames (93 ms at 44.1 kHz) later than it went in.
>
> Made as a varispeed instead (SGTimePitchCreateVarispeed), it is Apple's varispeed unit (AUVarispeed),
> which plays its input faster or slower the way a record does, the pitch going with the speed: it
> resamples rather than stretches, so none of the time and pitch unit's smearing is heard. Pull mode
> only, and its semitones are the rate's (SGTimePitchSetSemitones does nothing to it).
>
> Plain C over audio units: SGTimePitchRender and SGTimePitchProcess run on Core Audio's render
> thread, so they never allocate, lock, log or send a message. The rest is for any other thread.
> Compiles on the Mac as is.

**`SGTimePitch *SGTimePitchCreate(double sampleRate, UInt32 channels, SGTimePitchSource source, void *context);`** (was L33)
> Float, non-interleaved, `channels` of them, at `sampleRate`, in buffers of up to kSGTimePitchMaxFrames
> frames. With a source it pulls from it, without one it works in place. NULL when the unit could not be
> made. Not on the render thread.

**`bool SGTimePitchProcess(SGTimePitch *unit, float *const *channels, UInt32 frames);`** (was L53)
> In place mode: replaces `frames` samples of each channel with the same sound moved in pitch, the unit's
> latency later. Returns false, leaving them as they were, when it cannot (too many frames, the unit failed).

**`UInt32 SGTimePitchUnderruns(const SGTimePitch *unit);`** (was L57)
> Diagnostics, read from any thread: pulls the FIFO could not fully answer, render errors, the unit's own
> delay in seconds, the most frames it asked its input for at once, and the input frames it consumed.

## `Shared/Player/SpeedPitch.h`

**file overview** (was L1)
> Speed, pitch and reverb: sliders in the more button's menu, done to Spotify's sound, under either look.
> Nothing here draws on a Spotify screen of its own: the block goes into Spotify's own context menu
> sheet, and the rest is audio.
>
> SpeedPitchMenu.x   the expandable row and its sliders, put into Spotify's context menu
> SpeedPitch.x       speed and pitch done to Spotify's audio, between its mixer and its speaker unit
> SGTimePitch.m      Apple's time and pitch unit, pulling the mixer or working in place
>
> Speed and pitch last until Spotify quits; neither is stored. Whether pitch follows speed is.
> Threading: main thread only, except what SGTimePitch.h says runs on the render thread.

**`void SGPlayerMenuWatchMoreButton(UIView *button);`** (was L13)
> Marks a menu opened soon after a tap on `button`, the player's more button, as the player's, so it gets
> Speed and pitch (watching it twice does nothing). The redesign's PlayerHeader.x hands its button over;
> a menu presented from a now playing controller is taken for the player's without it, which is how the
> native look's player gets the block.

**`UIView *SGSpeedPitchPanelMake(void);`** (was L18)
> The controls alone, for a menu of a look's own that draws its own row for them (the redesign's
> player menu, Redesigned/Player/PlayerMenu.x): SGSpeedPitchPanelHeight() tall at whatever width it is
> given, showing the player's values as it is made.

**`extern NSNotificationName const SGSpeedPitchChangedNotification;`** (was L25)
> Posted, object nil, whenever the block or the panel shows new values; userInfo's "summary" is
> SGSpeedPitchSummary's text for them, missing while both are normal.

**`#define SGKeyPitchFollowsSpeed @"spotifyglass.speedPitch.follows"`** (was L38)
> Pitch follows speed, as a record played faster: the pitch slider goes and speed is played by resampling
> (SpeedPitch.x). The switch is on until turned off, and stored, but it only applies where speed does, so
> this is NO while SGPlayerSpeedAllowed() is NO. Turning it on puts the pitch back to normal; while it is
> on, SGSetPlayerPitch does nothing.

## `Shared/Player/SpeedPitch.x`

**file overview** (was L1)
> Speed and Pitch (SpeedPitchMenu.x draws them), both done on Spotify's audio, under either look.
>
> Hook ownership is Shared/Audio/SGAudioPipeline.x; this file registers its DSP there.
> Spotify's player takes a speed only for podcasts: for songs its restrictions refuse it (device test,
> 2026-09-18: the slider read "Unavailable here"), its own music speed being a per track setting kept on
> playlist items. So speed, like pitch, is done to the sound, by SGTimePitch between Spotify's mixer and
> its speaker unit.
>
> Spotify's audio (AudioUnitDriver2 in the binary) is a chain of units it wires with MakeConnection:
> converter (fed by its decoder through a render callback), EQ, mixer, RemoteIO. Its import of
> AudioUnitSetProperty is rebound (Core/SGRebind.h), and the one call connecting the mixer to the RemoteIO
> unit's input is answered by the central pipeline's render callback, which pulls the mixer itself. At
> normal speed and pitch the callback passes the mixer's sound straight through. Otherwise it renders the
> time and pitch unit, which pulls the mixer for rate times the frames it hands back, so Spotify's decoder
> is drained that much faster: the song plays faster or slower, at its own pitch unless Pitch moves it.
> Switching the unit in or out skips or repeats its 93 ms, so it stays in for a moment after both return
> to normal, and a finger dragging across normal does not switch it back and forth.
>
> While pitch follows speed (the switch between the sliders), the chain's unit is a varispeed instead
> (SGTimePitchCreateVarispeed): the song resampled, as a record played faster, its pitch going with the
> speed exactly. The time and pitch unit could only get near that, a whole semitone at a time, and even
> exact it smears every attack, keeping about a quarter of a click's energy sharp at 1.25x where the
> varispeed keeps all of it (harness/pitch). The varispeed is 1 ms late rather than 93.
>
> Spotify's clock keeps running at its own speed between the player's reports: -[SPTPlayerState position]
> is positionAsOfTimestamp minus timeIntervalSinceNow times [self playbackSpeed] (disassembly,
> 0x1057735ec), so playbackSpeed is hooked to include this speed, and the scrubber, the lyrics and the lock
> screen move with the sound. That bets the player's reported positions follow what the decoder handed
> over, which is what it counts.
>
> When the connection is never seen, pitch falls back to the way it first shipped: a render notify on the
> RemoteIO unit, registered in the central pipeline before audio effects and Music Haptics, runs each buffer
> through a unit working in place; speed is then unavailable. Those buffers are in the unit's output format,
> the hardware's, not the one Spotify hands the unit (harness/audio-effects/sim), so the fallback's unit is made
> for that one.
>
> Speed and pitch last until Spotify quits; whether pitch follows speed is stored, and on until turned off.
>
> Threading: the render callback and the notify run on the render thread and touch only atomics and the
> units; Spotify sets its properties and starts its unit on its audio thread; everything else is main
> thread.

**`static _Atomic(SGTimePitch *) sg_pull, sg_varispeed, sg_inPlace, sg_chain;`** (was L60)
> The units, each made for the output's format when first needed: the time and pitch unit in the chain
> (pull), the varispeed in the chain while pitch follows speed, and the one in place (pitch only). The
> render thread pulls sg_chain, one of the chain's two, and runs either only while engaged.

**`typedef struct {`** (was L67)
> The formats when Spotify started its output: the one it hands the RemoteIO unit, which the chain's unit
> feeds, and the unit's output side, the hardware's, which the in place fallback's notify gets.

**`atomic_store(&sg_engaged, false);`** (was L225)
> The pipeline has excluded rendering while the graph changes. Do not run the previous
> route's unit while the main queue prepares one for the newly reported format.

**`static SGTimePitch *unitForFormat(void) {`** (was L247)
> The unit for the output's format and the way in use, made when there is none or the format changed. A
> replaced one is never freed: the render thread may still hold it, and a format change is rare.

## `Shared/Player/SpeedPitchMenu.x`

**file overview** (was L1)
> The player's more menu gets Speed, pitch and reverb, under either look: one row in Spotify's own context menu
> sheet that opens, right there in the sheet, onto sliders for playback speed, pitch and reverb amount
> (SpeedPitch.x applies them).
>
> The sheet is Spotify's ContextMenu_InternalImpl.ContextMenuViewController, a table of its rows
> (ContextMenuTableView, sized to its content). Its rows come from Swift item factories with no way in,
> so the block is the table's header view, or its footer when Spotify already uses the header, and is
> laid out by hand at the table's width. Opening and closing it resizes the header inside a table update,
> so the rows under it move with it, and the table's intrinsic size is invalidated for the sheet to
> follow.
>
> Only the menu the player's more button opens gets it: the button (id=Context menu,
> trees/lyrics.txt:183, an Encore Tertiary button) is watched from the redesign's PlayerHeader.x, and a
> menu shown within a few seconds of its tap, or presented from a now playing controller, is the
> player's. Under the native look nothing hands the button over, so the block rides on the second test
> alone, the presenter being Spotify's own now playing controller. The first time, the menu's structure
> is logged, since no recorded tree shows it yet.
>
> The block is drawn from its own measures and type (below), not from the redesign's Kit, so it sits on
> Spotify's sheet under either look.
>
> The block keeps whether it was open for the rest of the session; speed and pitch last until Spotify
> quits.
>
> The redesign's player menu draws a row of its own and takes the controls alone
> (SGSpeedPitchPanelMake): the same view with its row left out and its panel always open.
>
> Pitch can follow speed (issue plus#5), so its slider folds away while speed and reverb stay. The sheet's
> block resizes itself in its table; the redesign's menu reads SGSpeedPitchPanelHeight() through
> SGSpeedPitchChangedNotification.

**`static const CGFloat kSideMargin = 16, kGrid = 8;`** (was L42)
> The block's own measures and type, so it stands on Spotify's sheet under either look rather than on
> the redesign's Kit: the sheet's side margin, the gap everything else is a multiple of, and a spring
> that settles without overshooting.

**`- (UISlider *)slider:(float)min max:(float)max normal:(float)normal minImage:(NSString *)minImage maxImage:(NSString *)maxImage {`** (was L157)
> Both sliders have their normal in the middle of the range rather than at one end, so neither track
> fills: a tick marks where normal is, under the thumb until it moves away.

**`self.tintColor = primary();`** (was L194)
> Nothing here draws in the tint: every colour is set on the view that draws it, and the glyphs have
> theirs painted in rather than tinted. The row came up in the system blue for a moment as the sheet
> appeared on the phone (issue #68), which is the tint a view inherits when nothing up the sheet sets
> one. The block's own tint is white as well, for whatever UIKit draws in it (the sliders' parts).

**`- (void)resize {`** (was L400)
> To its height for sg_open and the switch, in the sheet's table, the rows under it moving with it; the
> redesign's menu sizes the panel itself, on the notification showValues posts.

**`if ([button isKindOfClass:UIControl.class]) {`** (was L554)
> An Encore button may read its touches through a gesture recognizer rather than as a control, so
> both are watched.

**`static BOOL presentedFromPlayer(UIViewController *menu) {`** (was L568)
> The presenter or one of its parents is a now playing controller. Only the chain up is looked at: the
> root's children include the now playing bar's, which every menu would match.

**`static NSInteger rowCount(UITableView *table) {`** (was L616)
> The sheet keeps its spinner up until Spotify's rows are in, and they are in when every item factory
> has answered or run out of time: ContextMenuItemFactory holds a timer, and the timeout is the remote
> config's ios-feature-contextmenu-platform.timeout (SPTContextMenu_InternalImplProperties reads it
> between 1 and 60 s, 10 when the server says nothing). The block takes no part in that: it goes into
> the table's header once and stays, and a sheet that gets its rows seconds later shows them under it
> (harness/menu `loading`). So a menu that waits is timed from here, to tell a wait on Spotify's
> factories from a main thread kept busy: each check says how late it ran.

## `Shared/Privacy/Privacy.h`

**file overview** (was L1)
> Privacy: telemetry blocking (Privacy.x), an NSURLProtocol that answers the analytics endpoints
> itself and counts what it stopped. On unless switched off.

**`NSArray<NSString *> *SGBlockedLabels(void);`** (was L7)
> The destinations it knows in the order it lists them, and how many requests to one of them it
> has answered instead of letting out (nil label for all of them).

## `Shared/Privacy/Privacy.x`

**file overview** (was L1)
> Telemetry blocking: an NSURLProtocol that answers the analytics endpoints itself instead of
> letting them out, and keeps a count of what it stopped for the Privacy page.
>
> The SDKs Spotify ships each send somewhere of their own: Firebase to app-measurement.com, Facebook
> to graph.facebook.com/<id>/activities, then Branch, Comscore, Segment. None of it carries playback,
> search, sign-in or deep links, so a whole host is named where it does nothing else and a path where
> it does. Spotify's own events, sent to spclient's
> /gabo-receiver-service/, are left alone: Recents is built from the plays reported among them.
>
> A protocol handed to +registerClass: is only consulted by NSURLConnection and the shared
> session, so both session configurations are given it as well: that is what the SDKs build their
> sessions from. What the core sends over its own sockets is out of reach either way.

**`static NSMutableDictionary<NSString *, NSNumber *> *countsLocked(void) {`** (was L41)
> The class object stands in for a lock: counting happens on whichever thread the request was made
> on, the Privacy page reads on the main one. A count stored under a label no rule has any more is
> dropped as it loads, so the total adds up to the rows the page shows.

## `Shared/Sing/SGSingAudio.h`

**`SGSingAudio *SGSingAudioCreate(SGAudioStamp origin, uint32_t windowFrames, uint32_t hopFrames, float level);`** (was L5)
> One source generation. Off-render creation, attachment, detachment and destruction. The worker
> retains Stream until it finishes; detach first, then await its completion before Destroy.

**`void SGSingAudioExpectTrack(SGSingAudio *audio, uint64_t track);`** (was L16)
> Main-thread queue intent; no network request or private PCM read. Prepare at most one next
> song from the source's verified continuous prefix, preserving a single inference stream.

## `Shared/Sing/SGSingAudio.m`

**`return SGAudioPipelinePullOriginal(frames, data, time);`** (was L44)
> A seek/skip has invalidated the old stems but main has not detached us yet. Follow
> Spotify's current source during that interval, rather than muting its new audio.

**`uint64_t captured = SGSingStreamCaptured(a->stream);`** (was L51)
> A pinned source uses its verified queue prefix and reserve. Other callbacks use mixer silence as the
> read-ahead boundary; the silence path does not guess a Spotify-private queue layout.

**`atomic_fetch_add(&clockSequence, 1);`** (was L83)
> A natural transition keeps its audio epoch. Publish track and position as one
> snapshot so a concurrent lyrics/lock-screen read cannot mix the two songs.

## `Shared/Sing/SGSingController.h`

**`static inline BOOL SGSingStateIsOn(SGSingState state) {`** (was L11)
> Sing is on: the model is loaded and the song's vocals are turned down, or will be as soon as it
> plays (Ready), or are about to be again (Recovering).

**`void SGSingConfigure(BOOL enabled);`** (was L17)
> Sing's switch (the redesign's Mod Settings > Karaoke), at launch and whenever it is turned. Off, Sing does no
> work and is unavailable; on, it is available once its voice model is on this iPhone (SGSingModel.h).

**`BOOL SGSingAvailable(void);`** (was L21)
> Sing is switched on and has its model: the lyrics show its microphone. SGSingDidChangeNotification says
> when this changes.

## `Shared/Sing/SGSingController.m`

**`@interface SGSingSession : NSObject`** (was L34)
> The callback context owns the session until Finished; the controller owns it while audio is
> attached. Neither endpoint can observe freed storage, including cancellation during model load.

**`if (discard || !session.attached || (_state == SGSingReady && SGSingStreamQueued(stream(session)) == 0)) {`** (was L172)
> A prepared, paused model may be attached to a stopped graph. There is no audio to
> drain, and waiting for a render callback would make Off hang until the user pressed Play.

**`if (state.isLoading) { [self publish:SGSingPreparing explanation:nil]; [self startTimer]; return; }`** (was L189)
> Loading/pausing the player is not a request to turn Sing off. Model preparation is
> independent of the render callback and can complete before the user presses Play.

**`if ((!session.loading && !session.ready) || session.attached || session.retiring || _interrupted) return;`** (was L212)
> Capture while the model loads. The timeline emits original audio until it has a full
> vocal reserve, so compilation/warm-up and read-ahead no longer happen sequentially.

**`CFTimeInterval now = CACurrentMediaTime();`** (was L225)
> Retain the loaded worker while the graph settles; a missing graph on the first poll is
> not a bad format.

**`[self streamStopped:session];`** (was L256)
> A render-side underrun asks the worker to finish normally. Its final callback can
> reach main before the polling timer; don't misreport it as a broken voice model.

**`_blockedTrack = session.track; [self stop:NO unload:NO];`** (was L271)
> Keep a healthy, loaded model warm. Reloading it after a scheduling delay adds GPU work
> and startup latency to a retry; memory/thermal events still purge it immediately.

**`if (!session.retiring && [session.nextTrack isEqualToString:session.track] &&`** (was L309)
> Repeat-one has no URI change to notify observers. Its verified sample boundary
> still resets the audible clock without replacing the running separator.

**`SGLog(@"Sing continuing the prepared next track with %llu queued frames",`** (was L347)
> The source already crossed a verified natural boundary while its previous tail
> was audible. Preserve those samples, the ready stems and the loaded worker.

**`[self reconcile];`** (was L395)
> Spotify owns whether playback resumes. Retain the model and queued audio across a
> temporary interruption; reconcile pauses the worker's source input.
> If Spotify replaces its audio graph, reattach a fresh generation after the interruption.

**`- (void)modelChanged:(NSNotification *)note {`** (was L406)
> The model downloaded or removed from Mod Settings > Karaoke. Going, it takes Sing with it: the original audio
> still retained plays out in order, and the warm model is let go before its files are.

## `Shared/Sing/SGSingDSP.h`

**`void SGSingMixerProcess(SGSingMixer *mixer, const float *original, const float *vocals, float *output, uint32_t frames);`** (was L15)
> Stereo interleaved. Original and vocals must have identical generation, format and source index.
> Instrumental = original - vocals; a unity instrumental gain preserves the original balance.

## `Shared/Sing/SGSingFormat.h`

**file overview** (was L1)
> The one shape of audio Sing works in, for the render side, the controller and their tests. The Swift
> worker has the model's side of it (SGStemShape in SGStemSeparator.swift) and checks the model it loads
> against the window it is given.

**`SGSingReserveFrames = SGSingSampleRate * 120 / 1000,`** (was L10)
> 120 ms: what is left in Spotify's own queue when reading ahead, and the reserve of ready vocals the
> mix keeps so that its ramp back to the original (SGSingMixerBypass) always has vocals to ramp over.

## `Shared/Sing/SGSingLevel.h`

**file overview** (was L1)
> The control's full travel represents 20–100% vocals. Shared by UI, controller and mixer so
> touch, accessibility and programmatic changes all use the same range.

## `Shared/Sing/SGSingModel.h`

**file overview** (was L1)
> Sing's voice model on this iPhone. It is not in the IPA: the app downloads its five files from the model
> host once, each checked against the size and the SHA-256 pinned in SGSingModel.m (nothing the server says
> is trusted), into a staging folder, and moves them into place only when every one of them is right:
> Library/Application Support/spoti.pw/Sing/separator.mlmodelc in Spotify's container, kept out of the
> iCloud backup. The download runs in a background URL session, so it goes on while Spotify is away; a
> launch picks up one left running (SingModel.x), and a stopped one resumes from what already came in.
> Threading: main thread only; SGSingModelDidChangeNotification is posted on it.

**`#define SGKeySingModelDownload @"spotifyglass.sing.modelDownload"`** (was L10)
> Set while a download should be running, to 1 when it keeps off metered networks and 2 when it may use
> them: a launch that finds it picks the download up.

**`void SGSingModelDownload(BOOL metered);`** (was L42)
> Starts the download, or resumes a stopped one. Without `metered` it keeps off cellular and Low Data Mode
> networks and waits for Wi-Fi when that is all there is.

**`BOOL SGSingModelHandlesSession(NSString *identifier, void (^completion)(void));`** (was L48)
> SingModel.x: the app delegate hands over the background session's events, and a launch reconnects to a
> download that was running.

## `Shared/Sing/SGSingModel.m`

**`#ifndef SGSingModelBase`** (was L10)
> The model host: a Hugging Face repository holding the compiled model's files at the paths below. A test
> build serves them itself and keeps them somewhere of its own (harness/sing/model_test.m).

**`static const SGSingModelDescriptor kModels[] = {`**
> Vitrine's full and light compiled exports. Each has its own pinned files, installed path and staging
> directory, so selecting or removing one does not overwrite the other. The full model keeps the
> original `separator.mlmodelc` install path for existing users.

**`static BOOL sg_loaded, sg_installed, sg_want, sg_metered;`** (was L34)
> Main thread. A file is done once it is checked and in the staging folder under its own name, and
> checking while it waits for its hash; bytes are what arrived of one still coming, or a stopped
> download kept for its resume. The epoch goes up on removal, so work begun before it is let go.

**`static void load(void) {`** (was L111)
> What is on the disk, read once: the installed model when every file has its size, else the staged files
> (named only once checked) and what each resume kept.

**`if ([resume[@"data"] isKindOfClass:NSData.class] && [resume[@"metered"] boolValue] == sg_metered && !sg_restarted[i]) {`** (was L185)
> A resume carries its request, and with it the networks it may use: one made for others than the
> ones allowed now starts over, and so does one that has already failed once.

**`static void check(int i) {`** (was L240)
> A file that arrived is hashed off the main thread and named in the staging folder only if it is the
> pinned one; anything else is deleted and stops the download.

**`if (cancelled || (sg_fromResume[i] && !sg_restarted[i])) {`** (was L333)
> Cancelled without being asked (Spotify was quit while it ran): go on from what it kept. A resume
> that failed some other way starts that file over, once.

**`void SGSingModelReconnect(void) {`** (was L475)
> A download that was running when Spotify last quit: the session is made again, which hands back its
> tasks, and whatever is neither there nor already in is started again.

## `Shared/Sing/SGSingStream.h`

**file overview** (was L1)
> One immutable playback generation. Create/retire off the audio thread, after its users stop.
> The render endpoint owns the timeline; the worker only exchanges stamped PCM packets.
> A verified source supplies a spare-frame budget; an unverified source uses the
> `SGSingStreamReadUntilSilence` mode and retains only the sounding prefix of look-ahead reads.

**`void SGSingStreamSetModelReady(SGSingStream *stream, bool ready);`** (was L20)
> Disable before attaching a cold model; enable once Ready. The render owner seeds the worker
> from retained live PCM, so a slow model load cannot fill an unused input queue.

**`bool SGSingStreamReadLiveInput(SGSingStream *stream, SGAudioStamp *stamp, float *stereo);`** (was L37)
> The production worker starts at the first still-audible source frame after model loading.
> Only the initial expired prefix is skipped; subsequent packets must remain consecutive.

## `Shared/Sing/SGSingStream.m`

**`enum { kInputPackets = 1024, kOutputHops = 8 };`** (was L8)
> The worker's input queue holds this many packets, about 24 s of source: a cold model load
> collects its audio in the timeline instead, so the queue only ever holds a backlog of seconds.

**`s->timeline = SGSingTimelineCreate(SGSingTimelineFrames, window);`** (was L38)
> Start with a full window of ready vocals (two completed hops). The first inference
> duration cannot predict the next worker scheduling delay. Less overlap reduces repeated
> inference work; the reserve still covers a full future hop before vocal reduction begins.

**`uint64_t first = SGSingStreamPresented(s);`** (was L92)
> Off-render, bounded by the input queue's capacity. Hashing/compilation may have taken
> seconds; inferring already emitted audio only delays activation and wastes energy.

**`for (unsigned n = 0; n < kForwardPacketsPerRender; n++) {`** (was L158)
> Cold-load catch-up included: the playback ring, not the worker queue, owns the audio
> accumulated while the model loaded.

## `Shared/Sing/SGSingTimeline.h`

**file overview** (was L1)
> Render-thread-owned, preallocated aligned PCM. The worker sends its results through an SPSC
> queue; only the render consumer calls this API. No allocation after Create, no locks or waits.

**`bool SGSingTimelineCapture(SGSingTimeline *timeline, SGAudioStamp stamp, const float *original);`** (was L28)
> Stereo interleaved, 44.1 kHz. Reject mismatch, gap or overflow. During recovery, late output
> still advances the worker cursor, but only its not-yet-audible suffix is retained.

**`uint32_t SGSingTimelineRead(SGSingTimeline *timeline, float *output, uint32_t frames);`** (was L34)
> Preparing emits available original PCM immediately and advances its audible clock.
> Draining can return a prefix: pull the remaining frames directly only AFTER this prefix.
> Active underrun ramps to aligned dry audio and keeps capturing while the worker catches up.
> Recovery never rewinds/rebuffers and requires a full reserve before reducing vocals again.
> Its eight-second budget resets only after eight uninterrupted seconds of active playback.

## `Shared/Sing/SGSingTimeline.m`

**`if (t->state != SGSingTimelinePreparing || t->processed != t->origin.sourceFrame ||`** (was L86)
> Cold preparation may skip an initial prefix already emitted as original audio.
> This exception cannot skip an audible/future hole or conceal a later missing hop.

**`uint64_t expired = t->consumed > stamp.sourceFrame ? t->consumed - stamp.sourceFrame : 0;`** (was L92)
> Never write expired samples back into the circular buffer: their slots may now contain
> future audio. A packet straddling the audible cursor contributes only its live suffix.

**`if (t->state == SGSingTimelineActive && t->recoveryStart != UINT64_MAX &&`** (was L111)
> An isolated late window gets a fresh recovery budget after sustained playback.
> Brief returns to Active must not give an overloaded worker unlimited dry/wet cycles.

**`SGSingMixerSetLevel(&t->mixer, t->level);`** (was L125)
> Rebuild the same reserve required on first activation. Half a reserve let
> a single late result toggle Sing on/off every time the worker fell behind.

**`result[0] = dry[0]; result[1] = dry[1];`** (was L140)
> Bypass completes before the last aligned vocal runs out. Never extrapolate a
> missing stem from its last sample: that would add a DC offset to the original.

**`if (t->mixer.gain != 1 || t->mixer.remaining) SGSingMixerInit(&t->mixer, SGSingSampleRate, 1);`** (was L143)
> A short last vocal packet can exhaust coverage inside a large render quantum.
> Keep the mixer's next recovery ramp anchored to the dry gain actually emitted.

## `Shared/Sing/SGStemSeparator.swift`

**file overview** (was L1)
> Sing's separator: the Mel-Band RoFormer vocal model (harness/sing/model.json has its provenance) run by
> Core ML on this iPhone. The compiled graph is the model's spectral core alone: the worker takes the STFT
> and its inverse with Accelerate (SGStemSpectralDSP.swift), and Core ML turns one two-second spectrum into
> the spectrum of its vocals. The same model is loaded twice, once for the CPU, which is all iOS lets an app
> in the background use, and once for the CPU and the GPU, used while Spotify is the active app. Nothing
> here runs on the render thread or on UIKit's, and no audio leaves the process.

**`enum SGStemShape {`** (was L17)
> The one shape the model has. The C side (Shared/Sing/SGSingFormat.h) names the same window, and
> SGStemWorkerStart checks the loaded model against the window it is given.

**`func warmUp() async throws {`** (was L75)
> Core ML's first prediction allocates and specializes beyond loading, so it is paid here, before the
> worker says Ready, while Spotify still plays its own audio. Both copies are warmed, so going to the
> background or coming back never meets a cold model in the middle of the reduced mix.

**`func vocals(for pcm: [Float]) async throws -> [Float] {`** (was L84)
> One window of stereo interleaved PCM in, its vocals out; the instrumental is the mix less these. The
> streaming worker overlaps consecutive windows itself (SGStemWindowProcessor.swift).

**`await acquire()`** (was L88)
> Asking UIKit whether Spotify is active suspends this actor, and another window may come in
> meanwhile. The two share one input tensor, so they take turns.

**`gpuFailed = true`** (was L134)
> Going to the background can race the foreground check, and iOS then refuses the GPU.
> The same window goes to the warm CPU model with its timestamp kept, and the GPU is not
> asked again until Spotify has been inactive.

## `Shared/Sing/SGStemSpectralDSP.swift`

**file overview** (was L1)
> The STFT around Sing's model, the one PyTorch took when the model was trained: centred, the ends
> reflected, a periodic Hann window, an unscaled forward transform and the inverse divided by N once,
> overlap-added with the window's own weight taken out. The plans and the scratch are made once and reused
> window after window; the separator's actor is the only one to use them.

## `Shared/Sing/SGStemWindowProcessor.swift`

**`actor SGStemWindowProcessor {`** (was L11)
> A serial worker feeds consecutive overlapping model windows. Only a completed hop
> is published; its source index never changes to conceal missing or late inference output.

## `Shared/Sing/SGStemWorker.h`

**`typedef int32_t (*SGStemRead)(void *context, float *pcm, uint64_t *metadata);`** (was L5)
> Read returns a stereo frame count (at most 1024), zero while idle/paused, or -1 when cancelled.
> metadata is generation, track, source frame, format. No PCM is written outside this process.

**`void *SGStemWorkerStart(void *context, const char *modelPath, uint32_t windowFrames, uint32_t hopFrames,`** (was L12)
> Loads the compiled Core ML model at modelPath (or shares the one still warm) and separates windows of
> windowFrames, a hop of hopFrames apart; a model made for another window fails. Returns an owned
> cancellation handle, or NULL below iOS 18. Cancel releases that handle exactly once. Finished is
> called once even when cancellation interrupts load.

## `Shared/Sing/SGStemWorker.swift`

**file overview** (was L1)
> Sing's worker (SGStemWorker.h): a task per playback generation that reads source packets from the C
> stream, runs whole windows through the separator, and hands each finished hop of vocals back. The loaded
> model outlives the task that loaded it by a minute, so a seek or the next song does not load it again.

**`@available(iOS 18.0, macOS 27.0, *)`** (was L16)
> One warm model, shared by the workers that follow each other and kept for a while after the last
> one ends. A load in flight is shared too, and one made stale by a purge never becomes the warm model.

**`@available(iOS 18.0, macOS 27.0, *)`** (was L71)
> The C owner retains context until the final callback. Only this task invokes the endpoints;
> the render endpoint and the worker exchange PCM through the production SPSC queues.

## `Shared/Sing/SingModel.x`

**file overview** (was L1)
> Sing's voice model download going on while Spotify is away (SGSingModel.h). When its background session
> has news for an app that was suspended or quit, iOS wakes Spotify and hands the news to the app delegate.
> Spotify's (MusicApp_ContainerWiring.SpotifyAppDelegate in 9.1.78) has no
> application:handleEventsForBackgroundURLSession:completionHandler: of its own -- its method list in the
> binary has none -- so the mod adds one that takes its own session's events and leaves any other
> session's alone. Firebase's app delegate swizzler (GULAppDelegateSwizzler, in the binary) hands the same
> completion handler to its own interceptors and then to this method, so answering another session's here
> would call a handler its owner calls again later. A launch also reconnects to a download left running.

## `Shared/Sing/SingPlayer.x`

**file overview** (was L1)
> SPTPlayerState.position and SPTEsperantoPlayer's commands are verified in Spotify 9.1.78
> (Headers/SPTPlayer.h). The position hook is the one audible clock used by Spotify's progress UI.

**`- (id)seekTo:(double)seconds {`** (was L22)
> seekTo: answers with an object (@24@0:8d16 in 9.1.78) that its caller may keep, so the hook hands it
> on: declared void, the call after %orig would leave the caller whatever that call left in x0.

**`SPTPlayerState *state = NSThread.isMainThread ? SGPlayerState() : nil;`** (was L52)
> PlayerState is main-thread data. Off-main reports are corrected by the controller's next
> clock publication; never read its Objective-C ownership from an audio/player callback.
