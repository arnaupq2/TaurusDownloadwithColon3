#import "SLDownloadsPage.h"
#import "Core/SGCore.h"
#import "Settings/SGPageStyle.h"
#import "Shared/Navigation/Links.h"
#import "Shared/Player/PlayerState.h"
#import "Shared/Player/SGLastTrack.h"
#import "SGLosslessStore.h"
#import "SLLocalPlayer.h"
#import "SLSoulseekAccountPage.h"

static NSString *slSize(unsigned long long bytes) {
    if (bytes >= 1000000000ull) return [NSString stringWithFormat:@"%.2f GB", bytes / 1e9];
    if (bytes >= 1000000ull) return [NSString stringWithFormat:@"%.1f MB", bytes / 1e6];
    return [NSString stringWithFormat:@"%.0f KB", bytes / 1e3];
}

#pragma mark - a row: cover, title, "artist · MB", ⋯

@interface SLSongCell : UITableViewCell
@property (nonatomic, strong) UIImageView *cover;
@property (nonatomic, strong) UILabel *titleLabel, *detailLabel;
@property (nonatomic, strong) UIButton *more;
@property (nonatomic, copy) NSString *coverPath;
@property (nonatomic, copy) void (^onPlay)(void);
@property (nonatomic, copy) void (^onDelete)(void);
@end

@implementation SLSongCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)identifier {
    if (!(self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier])) return nil;
    self.backgroundColor = UIColor.clearColor;
    self.selectionStyle = UITableViewCellSelectionStyleDefault;
    self.selectedBackgroundView = ({ UIView *v = [UIView new]; v.backgroundColor = [UIColor colorWithWhite:1 alpha:0.08]; v; });

    _cover = [UIImageView new];
    _cover.contentMode = UIViewContentModeScaleAspectFill;
    _cover.clipsToBounds = YES;
    _cover.layer.cornerRadius = 8;
    _cover.layer.cornerCurve = kCACornerCurveContinuous;
    _cover.backgroundColor = [UIColor colorWithWhite:1 alpha:0.08];
    _cover.translatesAutoresizingMaskIntoConstraints = NO;

    _titleLabel = [UILabel new];
    _titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightRegular];
    _titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;

    _detailLabel = [UILabel new];
    _detailLabel.font = [UIFont systemFontOfSize:14];
    _detailLabel.textColor = SGGrey();
    _detailLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    _detailLabel.translatesAutoresizingMaskIntoConstraints = NO;

    _more = [UIButton buttonWithType:UIButtonTypeSystem];
    [_more setImage:[UIImage systemImageNamed:@"ellipsis"] forState:UIControlStateNormal];
    _more.tintColor = SGGrey();
    _more.showsMenuAsPrimaryAction = YES;
    _more.translatesAutoresizingMaskIntoConstraints = NO;
    _more.accessibilityLabel = @"More";

    UIView *content = self.contentView;
    for (UIView *view in @[_cover, _titleLabel, _detailLabel, _more]) [content addSubview:view];
    [_titleLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [NSLayoutConstraint activateConstraints:@[
        [_cover.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:20],
        [_cover.centerYAnchor constraintEqualToAnchor:content.centerYAnchor],
        [_cover.widthAnchor constraintEqualToConstant:64],
        [_cover.heightAnchor constraintEqualToConstant:64],
        [_cover.topAnchor constraintGreaterThanOrEqualToAnchor:content.topAnchor constant:10],
        [_more.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-8],
        [_more.centerYAnchor constraintEqualToAnchor:content.centerYAnchor],
        [_more.widthAnchor constraintEqualToConstant:48],
        [_more.heightAnchor constraintEqualToConstant:48],
        [_titleLabel.leadingAnchor constraintEqualToAnchor:_cover.trailingAnchor constant:14],
        [_titleLabel.trailingAnchor constraintEqualToAnchor:_more.leadingAnchor constant:-4],
        [_titleLabel.bottomAnchor constraintEqualToAnchor:content.centerYAnchor constant:-1],
        [_detailLabel.leadingAnchor constraintEqualToAnchor:_titleLabel.leadingAnchor],
        [_detailLabel.trailingAnchor constraintEqualToAnchor:_titleLabel.trailingAnchor],
        [_detailLabel.topAnchor constraintEqualToAnchor:content.centerYAnchor constant:2],
    ]];
    self.separatorInset = UIEdgeInsetsMake(0, 98, 0, 20);
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.coverPath = nil;
    self.cover.image = nil;
}

- (void)configureTitle:(NSString *)title detail:(NSString *)detail playing:(BOOL)playing {
    self.titleLabel.text = title;
    self.titleLabel.textColor = playing ? SGGreen() : UIColor.whiteColor;
    self.detailLabel.text = detail;
    __weak SLSongCell *weak = self;
    UIAction *play = [UIAction actionWithTitle:@"Play" image:[UIImage systemImageNamed:@"play.fill"] identifier:nil
        handler:^(UIAction *action) { if (weak.onPlay) weak.onPlay(); }];
    UIAction *remove = [UIAction actionWithTitle:@"Delete" image:[UIImage systemImageNamed:@"trash"] identifier:nil
        handler:^(UIAction *action) { if (weak.onDelete) weak.onDelete(); }];
    remove.attributes = UIMenuElementAttributesDestructive;
    self.more.menu = [UIMenu menuWithChildren:@[play, remove]];
}

@end

@interface SLDownloadsPage () <SGPlayerStateObserver>
@end

#pragma mark - the page

@implementation SLDownloadsPage {
    NSArray<NSDictionary *> *_entries;   // name, path, bytes, title, detail, uri, cover (path or nil)
    UILabel *_total, *_count;
    UIView *_header;
    NSString *_playingURI;
    BOOL _scanning;
}

- (instancetype)init {
    return [super initWithStyle:UITableViewStylePlain];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Downloads";
    self.tableView.separatorColor = [UIColor colorWithWhite:1 alpha:0.1];
    self.tableView.rowHeight = 88;
    self.tableView.tableFooterView = [UIView new];

    _header = [UIView new];
    _total = [UILabel new];
    _total.font = [UIFont systemFontOfSize:30 weight:UIFontWeightBold];
    _total.textColor = UIColor.whiteColor;
    _count = [UILabel new];
    _count.font = [UIFont systemFontOfSize:14];
    _count.textColor = SGGrey();
    [_header addSubview:_total];
    [_header addSubview:_count];
    self.tableView.tableHeaderView = _header;

    UIBarButtonItem *refresh = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
        target:self action:@selector(reloadFiles)];
    UIBarButtonItem *account = [[UIBarButtonItem alloc] initWithTitle:@"Soulseek" style:UIBarButtonItemStylePlain
        target:self action:@selector(openSoulseek)];
    self.navigationItem.rightBarButtonItems = @[refresh, account];
    SGAddPlayerStateObserver(self);
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(localPlayerChanged) name:SLLocalPlayerDidChangeNotification object:nil];
    [self reloadFiles];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    SGInsetForBars(self.tableView);
    CGFloat width = self.tableView.bounds.size.width;
    if (fabs(_header.frame.size.width - width) > 0.5) {
        _header.frame = CGRectMake(0, 0, width, 84);
        _total.frame = CGRectMake(20, 14, width - 40, 36);
        _count.frame = CGRectMake(20, 52, width - 40, 20);
        self.tableView.tableHeaderView = _header;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadFiles];
}

- (void)localPlayerChanged {
    if (self.isViewLoaded && self.view.window) [self.tableView reloadData];
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)openSoulseek {
    [self.navigationController pushViewController:[SLSoulseekAccountPage new] animated:YES];
}

// The song that plays gets a green title, as in Spotify's own lists.
- (void)playerStateDidChange:(SPTPlayerState *)state {
    NSString *uri = SGURIString(state.track.URI);
    if (uri == _playingURI || [uri isEqualToString:_playingURI]) return;
    _playingURI = uri;
    if (self.isViewLoaded && self.view.window) [self.tableView reloadData];
}

- (void)reloadFiles {
    NSString *directory = SGLosslessStoreDirectory();
    NSArray<NSString *> *all = [NSFileManager.defaultManager contentsOfDirectoryAtPath:directory error:nil] ?: @[];
    NSSet *extensions = [NSSet setWithArray:@[@"flac", @"m4a", @"caf", @"wav", @"aiff", @"alac"]];
    NSMutableArray<NSDictionary *> *entries = [NSMutableArray array];
    unsigned long long total = 0;
    for (NSString *name in all) {
        if (![extensions containsObject:name.pathExtension.lowercaseString] || [name hasPrefix:@"."]) continue;
        NSString *path = [directory stringByAppendingPathComponent:name];
        NSDictionary *attributes = [NSFileManager.defaultManager attributesOfItemAtPath:path error:nil];
        if ([attributes.fileType isEqualToString:NSFileTypeDirectory]) continue;
        unsigned long long bytes = attributes.fileSize;
        total += bytes;
        NSDictionary *info = SGLosslessStoreInfo(name);
        NSString *title = [info[@"title"] length] ? info[@"title"] : name.stringByDeletingPathExtension;
        NSString *artist = info[@"artist"];
        NSString *detail = artist.length ? [NSString stringWithFormat:@"%@ · %@", artist, slSize(bytes)] : slSize(bytes);
        NSString *cover = [info[@"cover"] length] ? [SGLosslessCoversDirectory() stringByAppendingPathComponent:[info[@"cover"] lastPathComponent]] : nil;
        [entries addObject:@{@"name": name, @"path": path, @"title": title, @"artist": artist ?: @"", @"album": info[@"album"] ?: @"", @"detail": detail,
                             @"uri": info[@"uri"] ?: @"", @"cover": cover ?: @"",
                             @"date": attributes.fileModificationDate ?: NSDate.distantPast}];
    }
    [entries sortUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
        return [b[@"date"] compare:a[@"date"]];   // newest first
    }];
    _entries = entries;
    _total.text = slSize(total);
    _count.text = entries.count == 1 ? @"1 song · Lossless" : [NSString stringWithFormat:@"%lu songs · Lossless", (unsigned long)entries.count];
    SPTPlayerState *state = SGPlayerState();
    _playingURI = SGURIString(state.track.URI);
    [self.tableView reloadData];
    [self fillFromTags:entries];
}

// A file with no stored cover or artist (put there by hand, or downloaded before this) tells them itself: a FLAC
// carries its tags and picture, read here once with no network and kept beside the file.
- (void)fillFromTags:(NSArray<NSDictionary *> *)entries {
    if (_scanning) return;
    NSMutableArray<NSDictionary *> *todo = [NSMutableArray array];
    for (NSDictionary *entry in entries) {
        NSDictionary *info = SGLosslessStoreInfo(entry[@"name"]);
        if ([info[@"scanned"] boolValue] || ([info[@"cover"] length] && [info[@"artist"] length])) continue;
        [todo addObject:entry];
    }
    if (!todo.count) return;
    _scanning = YES;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
        BOOL changed = NO;
        for (NSDictionary *entry in todo) {
            NSString *name = entry[@"name"];
            NSData *cover = nil;
            NSDictionary *tags = SGLosslessReadTags(entry[@"path"], &cover);
            NSMutableDictionary *info = [SGLosslessStoreInfo(name) mutableCopy] ?: [NSMutableDictionary dictionary];
            for (NSString *key in @[@"title", @"artist", @"album"]) {
                if (![info[key] length] && [tags[key] length]) { info[key] = tags[key]; changed = YES; }
            }
            if (![info[@"cover"] length] && cover.length) {
                NSString *coverName = [name stringByAppendingPathExtension:@"jpg"];   // the bytes decide JPEG or PNG when it is drawn
                if ([cover writeToFile:[SGLosslessCoversDirectory() stringByAppendingPathComponent:coverName] atomically:YES]) {
                    info[@"cover"] = coverName;
                    changed = YES;
                }
            }
            info[@"scanned"] = @YES;
            SGLosslessStoreSetInfo(name, info);
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            self->_scanning = NO;
            if (changed) [self reloadFiles];
        });
    });
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _entries.count ?: 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!_entries.count) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"lossless-empty"] ?:
            [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"lossless-empty"];
        cell.backgroundColor = UIColor.clearColor;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.text = @"No downloads yet";
        cell.detailTextLabel.text = @"Play a song and tap Download lossless in its ⋯ menu.";
        cell.textLabel.textColor = SGGrey();
        cell.detailTextLabel.textColor = SGGrey();
        return cell;
    }
    SLSongCell *cell = [tableView dequeueReusableCellWithIdentifier:@"lossless-song"] ?: [[SLSongCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"lossless-song"];
    NSDictionary *entry = _entries[(NSUInteger)indexPath.row];
    NSString *uri = entry[@"uri"];
    NSString *localPath = SLLocalPlayer.shared.currentPath;
    BOOL playing = (uri.length && [uri isEqualToString:_playingURI]) || (localPath && [localPath isEqualToString:entry[@"path"]]);
    [cell configureTitle:entry[@"title"] detail:entry[@"detail"] playing:playing];
    __weak SLDownloadsPage *weak = self;
    cell.onPlay = ^{ [weak play:entry]; };
    cell.onDelete = ^{ [weak remove:entry]; };

    // The cover is read off the main thread; the cell shows a grey note until it is there.
    NSString *coverPath = entry[@"cover"];
    cell.cover.image = nil;
    cell.coverPath = coverPath;
    if (coverPath.length) {
        __weak SLSongCell *weakCell = cell;
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
            UIImage *image = [UIImage imageWithContentsOfFile:coverPath];
            image = image.imageByPreparingForDisplay ?: image;
            dispatch_async(dispatch_get_main_queue(), ^{
                if (weakCell && [weakCell.coverPath isEqualToString:coverPath]) weakCell.cover.image = image;
            });
        });
    } else {
        cell.cover.image = SGPlaceholderArtwork(SGGrey());
    }
    return cell;
}

#pragma mark playing

// A tap plays the download in the mod's own player (SLLocalPlayer), which Spotify's native now playing bar and
// player show and control as if the song were theirs (SLNativeBar.x): title, artist and cover, play and pause,
// skip, seek, and the next download once a song ends. It needs no connection and no Spotify track.
- (void)play:(NSDictionary *)entry {
    NSMutableArray<NSDictionary *> *queue = [NSMutableArray array];
    NSUInteger index = 0;
    for (NSDictionary *each in _entries) {
        if (each == entry) index = queue.count;
        [queue addObject:@{@"path": each[@"path"], @"title": each[@"title"], @"artist": each[@"artist"] ?: @"",
                           @"album": each[@"album"] ?: @"", @"cover": each[@"cover"] ?: @"", @"uri": each[@"uri"] ?: @""}];
    }
    [SLLocalPlayer.shared playQueue:queue index:index];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row < (NSInteger)_entries.count) [self play:_entries[(NSUInteger)indexPath.row]];
}

#pragma mark deleting

- (void)remove:(NSDictionary *)entry {
    NSError *error = nil;
    if (![NSFileManager.defaultManager removeItemAtPath:entry[@"path"] error:&error]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Couldn't delete file"
            message:error.localizedDescription ?: @"The file could not be removed." preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    SGLosslessStoreForget(entry[@"name"]);
    [self reloadFiles];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return _entries.count > 0;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)style forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (style != UITableViewCellEditingStyleDelete || indexPath.row >= (NSInteger)_entries.count) return;
    [self remove:_entries[(NSUInteger)indexPath.row]];
}

@end

#pragma mark - opening it from anywhere

// The navigation stack of the selected tab: the tab bar controller holds none itself.
static UINavigationController *navigationIn(UIViewController *controller, int depth) {
    if (!controller || depth > 6) return nil;
    if ([controller isKindOfClass:UINavigationController.class]) return (UINavigationController *)controller;
    if ([controller isKindOfClass:UITabBarController.class]) {
        UINavigationController *selected = navigationIn(((UITabBarController *)controller).selectedViewController, depth + 1);
        if (selected) return selected;
    }
    for (UIViewController *child in controller.childViewControllers) {
        UINavigationController *found = navigationIn(child, depth + 1);
        if (found) return found;
    }
    return controller.navigationController;
}

static void show(UIViewController *page) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *top = SGTopController();
        UINavigationController *navigation = navigationIn(top, 0);
        SGShowPage(navigation.topViewController ?: top, page);
    });
}

void SLOpenDownloads(void) {
    show([SLDownloadsPage new]);
}

void SLOpenSoulseekAccount(void) {
    show([SLSoulseekAccountPage new]);
}
