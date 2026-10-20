// Rossiya Putin Pobeda, Hi i am Itzehoer i am just bored doing that at 22:00
#import "SLSoulseekAccountPage.h"
#import "Settings/SGPageStyle.h"

#import <dispatch/dispatch.h>
#import <sys/socket.h>
#import <sys/types.h>
#import <netinet/in.h>
#import <netdb.h>
#import <unistd.h>
#import <errno.h>
#import <string.h>
#import <fcntl.h>
#import <sys/select.h>
#import <Security/Security.h>
#import <CommonCrypto/CommonDigest.h>

static NSString *const kSLUsernameKey = @"spotifyglass.soulseek.username";
static NSString *const kSLKeychainService = @"com.spotifyglass.soulseek";

#pragma mark - Soulseek wire helpers

static void SLAppendU32(NSMutableData *data, uint32_t value) {
    uint8_t bytes[4] = {
        (uint8_t)(value & 0xff),
        (uint8_t)((value >> 8) & 0xff),
        (uint8_t)((value >> 16) & 0xff),
        (uint8_t)((value >> 24) & 0xff)
    };
    [data appendBytes:bytes length:sizeof(bytes)];
}

static void SLAppendString(NSMutableData *data, NSString *value) {
    NSData *bytes = [value dataUsingEncoding:NSUTF8StringEncoding] ?: [NSData data];
    SLAppendU32(data, (uint32_t)bytes.length);
    [data appendData:bytes];
}

static uint32_t SLReadU32(const uint8_t *bytes) {
    return (uint32_t)bytes[0] | ((uint32_t)bytes[1] << 8) |
           ((uint32_t)bytes[2] << 16) | ((uint32_t)bytes[3] << 24);
}

static NSString *SLReadString(NSData *data, NSUInteger *offset) {
    if (*offset + 4 > data.length) return nil;
    const uint8_t *bytes = data.bytes;
    uint32_t length = SLReadU32(bytes + *offset);
    *offset += 4;
    if (length > data.length - *offset) return nil;
    NSString *value = [[NSString alloc] initWithBytes:bytes + *offset length:length encoding:NSUTF8StringEncoding];
    *offset += length;
    return value;
}

static BOOL SLWriteAll(int fd, const void *buffer, size_t length) {
    const uint8_t *bytes = buffer;
    size_t sent = 0;
    while (sent < length) {
        ssize_t count = send(fd, bytes + sent, length - sent, 0);
        if (count < 0 && errno == EINTR) continue;
        if (count <= 0) return NO;
        sent += (size_t)count;
    }
    return YES;
}

static BOOL SLReadAll(int fd, void *buffer, size_t length) {
    uint8_t *bytes = buffer;
    size_t received = 0;
    while (received < length) {
        ssize_t count = recv(fd, bytes + received, length - received, 0);
        if (count < 0 && errno == EINTR) continue;
        if (count <= 0) return NO;
        received += (size_t)count;
    }
    return YES;
}

static int SLConnectWithTimeout(const struct addrinfo *address, int timeoutSeconds) {
    int fd = socket(address->ai_family, address->ai_socktype, address->ai_protocol);
    if (fd < 0) return -1;

    int noSigPipe = 1;
    setsockopt(fd, SOL_SOCKET, SO_NOSIGPIPE, &noSigPipe, sizeof(noSigPipe));

    int oldFlags = fcntl(fd, F_GETFL, 0);
    if (oldFlags < 0 || fcntl(fd, F_SETFL, oldFlags | O_NONBLOCK) < 0) {
        close(fd);
        return -1;
    }

    int result = connect(fd, address->ai_addr, (socklen_t)address->ai_addrlen);
    if (result < 0 && errno != EINPROGRESS) {
        close(fd);
        return -1;
    }

    if (result < 0) {
        fd_set writeSet;
        FD_ZERO(&writeSet);
        FD_SET(fd, &writeSet);
        struct timeval timeout = { timeoutSeconds, 0 };
        result = select(fd + 1, NULL, &writeSet, NULL, &timeout);
        if (result <= 0) {
            close(fd);
            return -1;
        }

        int socketError = 0;
        socklen_t errorLength = sizeof(socketError);
        if (getsockopt(fd, SOL_SOCKET, SO_ERROR, &socketError, &errorLength) < 0 || socketError != 0) {
            close(fd);
            return -1;
        }
    }

    if (fcntl(fd, F_SETFL, oldFlags) < 0) {
        close(fd);
        return -1;
    }

    struct timeval ioTimeout = { timeoutSeconds, 0 };
    setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &ioTimeout, sizeof(ioTimeout));
    setsockopt(fd, SOL_SOCKET, SO_SNDTIMEO, &ioTimeout, sizeof(ioTimeout));
    return fd;
}

static NSString *SLLoginHash(NSString *username, NSString *password) {
    NSData *input = [[username stringByAppendingString:password] dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    // Soulseek protocol mandates MD5(username + password) for its legacy login handshake.
    // This is protocol compatibility, not password storage or a security primitive.
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated-declarations"
    CC_MD5(input.bytes, (CC_LONG)input.length, digest);
    #pragma clang diagnostic pop
    NSMutableString *hex = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (NSUInteger i = 0; i < CC_MD5_DIGEST_LENGTH; i++) [hex appendFormat:@"%02x", digest[i]];
    return hex;
}

static NSData *SLLoginFrame(NSString *username, NSString *password) {
    // Soulseek server message 1: username, password, client major version, MD5(username + password), minor version.
    NSMutableData *payload = [NSMutableData data];
    SLAppendString(payload, username);
    SLAppendString(payload, password);
    SLAppendU32(payload, 177);
    SLAppendString(payload, SLLoginHash(username, password));
    SLAppendU32(payload, 1);

    NSMutableData *body = [NSMutableData data];
    SLAppendU32(body, 1); // login message code
    [body appendData:payload];

    NSMutableData *frame = [NSMutableData data];
    SLAppendU32(frame, (uint32_t)body.length);
    [frame appendData:body];
    return frame;
}

#pragma mark - Keychain

static NSString *SLLoadPassword(NSString *username) {
    if (!username.length) return nil;
    NSDictionary *query = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: kSLKeychainService,
        (__bridge id)kSecAttrAccount: username,
        (__bridge id)kSecReturnData: @YES,
        (__bridge id)kSecMatchLimit: (__bridge id)kSecMatchLimitOne
    };
    CFTypeRef result = NULL;
    if (SecItemCopyMatching((__bridge CFDictionaryRef)query, &result) != errSecSuccess || !result) return nil;
    NSData *data = CFBridgingRelease(result);
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

static BOOL SLSavePassword(NSString *username, NSString *password) {
    NSData *data = [password dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *query = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: kSLKeychainService,
        (__bridge id)kSecAttrAccount: username
    };
    SecItemDelete((__bridge CFDictionaryRef)query);
    NSMutableDictionary *item = [query mutableCopy];
    item[(__bridge id)kSecValueData] = data;
    item[(__bridge id)kSecAttrAccessible] = (__bridge id)kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly;
    return SecItemAdd((__bridge CFDictionaryRef)item, NULL) == errSecSuccess;
}

static void SLDeletePassword(NSString *username) {
    if (!username.length) return;
    NSDictionary *query = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: kSLKeychainService,
        (__bridge id)kSecAttrAccount: username
    };
    SecItemDelete((__bridge CFDictionaryRef)query);
}

NSString *SLSoulseekSavedUsername(void) {
    NSString *username = [NSUserDefaults.standardUserDefaults stringForKey:kSLUsernameKey];
    return username.length ? username : nil;
}

NSString *SLSoulseekSavedPassword(void) {
    return SLLoadPassword(SLSoulseekSavedUsername());
}

#pragma mark - Settings page

@interface SLSoulseekAccountPage ()
@property (nonatomic, strong) UITextField *usernameField;
@property (nonatomic, strong) UITextField *passwordField;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIView *footerView;
@property (nonatomic) BOOL connecting;
@property (nonatomic) int socketFD;
@property (nonatomic, strong) dispatch_queue_t networkQueue;
@property (nonatomic, strong) NSMutableData *receiveBuffer;
@property (nonatomic) NSUInteger attempt;
@end

@implementation SLSoulseekAccountPage

- (instancetype)init {
    return [super initWithStyle:UITableViewStyleInsetGrouped];
}

- (void)viewDidLoad {
    [super viewDidLoad];   // SGPage: dark, inset grouped, Spotify's page protocol
    self.title = @"Soulseek";
    self.networkQueue = dispatch_queue_create("com.spotifyglass.soulseek-login", DISPATCH_QUEUE_SERIAL);
    self.socketFD = -1;
    self.receiveBuffer = [NSMutableData data];
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;

    self.usernameField = [self fieldWithPlaceholder:@"Soulseek username" secure:NO];
    self.usernameField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.usernameField.text = [NSUserDefaults.standardUserDefaults stringForKey:kSLUsernameKey] ?: @"";
    self.passwordField = [self fieldWithPlaceholder:@"Soulseek password" secure:YES];
    NSString *savedPassword = SLLoadPassword(self.usernameField.text);
    if (savedPassword.length) self.passwordField.text = savedPassword;

    self.statusLabel = [UILabel new];
    self.statusLabel.numberOfLines = 0;
    self.statusLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    self.statusLabel.textColor = SGGrey();
    self.statusLabel.text = @"Server: server.slsknet.org · TCP 2242";
    UILabel *note = [UILabel new];
    note.numberOfLines = 0;
    note.tag = 2;
    note.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    note.textColor = SGGrey();
    note.text = @"Your password is saved in the iOS Keychain only after a successful login. Downloads use this account: Download lossless in a song's ⋯ menu searches Soulseek with it.";
    self.footerView = [UIView new];
    [self.footerView addSubview:self.statusLabel];
    [self.footerView addSubview:note];
    self.tableView.tableFooterView = self.footerView;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat width = self.tableView.bounds.size.width, inset = 36;
    if (width <= 0) return;
    UILabel *note = [self.footerView viewWithTag:2];
    CGSize a = [self.statusLabel sizeThatFits:CGSizeMake(width - 2 * inset, CGFLOAT_MAX)];
    CGSize b = [note sizeThatFits:CGSizeMake(width - 2 * inset, CGFLOAT_MAX)];
    self.statusLabel.frame = CGRectMake(inset, 8, width - 2 * inset, a.height);
    note.frame = CGRectMake(inset, CGRectGetMaxY(self.statusLabel.frame) + 12, width - 2 * inset, b.height);
    CGFloat height = CGRectGetMaxY(note.frame) + 24;
    if (self.footerView.frame.size.height != height || self.footerView.frame.size.width != width) {
        self.footerView.frame = CGRectMake(0, 0, width, height);
        self.tableView.tableFooterView = self.footerView;
    }
}

- (UITextField *)fieldWithPlaceholder:(NSString *)placeholder secure:(BOOL)secure {
    UITextField *field = [UITextField new];
    field.attributedPlaceholder = [[NSAttributedString alloc] initWithString:placeholder
        attributes:@{NSForegroundColorAttributeName: SGGrey()}];
    field.secureTextEntry = secure;
    field.textColor = UIColor.whiteColor;
    field.tintColor = SGGreen();
    field.autocorrectionType = UITextAutocorrectionTypeNo;
    field.autocapitalizationType = UITextAutocapitalizationTypeNone;
    field.clearButtonMode = UITextFieldViewModeWhileEditing;
    field.returnKeyType = UIReturnKeyDone;
    [field addTarget:field action:@selector(resignFirstResponder) forControlEvents:UIControlEventEditingDidEndOnExit];
    return field;
}

#pragma mark - table

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 2; }

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return section == 0 ? 2 : 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return section == 0 ? @"Account" : nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    cell.backgroundColor = SGCardBackground();
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    if (indexPath.section == 0) {
        UITextField *field = indexPath.row == 0 ? self.usernameField : self.passwordField;
        field.frame = CGRectInset(cell.contentView.bounds, 16, 0);
        field.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [cell.contentView addSubview:field];
        return cell;
    }
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    if (indexPath.row == 0) {
        cell.textLabel.text = self.connecting ? @"Connecting…" : @"Connect to Soulseek";
        cell.textLabel.textColor = self.connecting ? SGGrey() : SGGreen();
        cell.textLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    } else {
        cell.textLabel.text = @"Forget saved credentials";
        cell.textLabel.textColor = UIColor.systemRedColor;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section != 1) return;
    [self.view endEditing:YES];
    if (indexPath.row == 0) { if (!self.connecting) [self connectTapped]; }
    else [self forgetCredentials];
}

- (void)setConnecting:(BOOL)connecting {
    _connecting = connecting;
    if (self.isViewLoaded)
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:1]] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)connectTapped {
    NSString *username = [self.usernameField.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    NSString *password = self.passwordField.text ?: @"";
    if (!username.length || !password.length) {
        [self showStatus:@"Enter both your Soulseek username and password." success:NO];
        return;
    }

    [self disconnectCurrent];
    NSUInteger attempt = ++self.attempt;
    self.connecting = YES;
    [self showStatus:@"Connecting to server.slsknet.org:2242..." success:NO];

    __weak typeof(self) weakSelf = self;
    dispatch_async(self.networkQueue, ^{
        typeof(self) self = weakSelf;
        if (!self || self.attempt != attempt) return;

        struct addrinfo hints;
        memset(&hints, 0, sizeof(hints));
        hints.ai_family = AF_UNSPEC;
        hints.ai_socktype = SOCK_STREAM;
        hints.ai_protocol = IPPROTO_TCP;

        struct addrinfo *addresses = NULL;
        int lookup = getaddrinfo("server.slsknet.org", "2242", &hints, &addresses);
        if (lookup != 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self finishAttempt:attempt message:@"Could not resolve the Soulseek server. Check your network." success:NO];
            });
            return;
        }

        int fd = -1;
        for (struct addrinfo *address = addresses; address; address = address->ai_next) {
            if (self.attempt != attempt) break;
            fd = SLConnectWithTimeout(address, 12);
            if (fd >= 0) break;
        }
        freeaddrinfo(addresses);

        if (fd < 0) {
            if (self.attempt == attempt) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self finishAttempt:attempt message:@"Could not connect to server.slsknet.org:2242." success:NO];
                });
            }
            return;
        }

        if (self.attempt != attempt) {
            close(fd);
            return;
        }
        self.socketFD = fd;

        NSData *packet = SLLoginFrame(username, password);
        if (!SLWriteAll(fd, packet.bytes, packet.length)) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self finishAttempt:attempt message:@"Could not send the login request." success:NO];
            });
            return;
        }

        uint8_t lengthBytes[4];
        if (!SLReadAll(fd, lengthBytes, sizeof(lengthBytes))) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self finishAttempt:attempt message:@"No login response received from Soulseek." success:NO];
            });
            return;
        }

        uint32_t bodyLength = SLReadU32(lengthBytes);
        if (bodyLength < 5 || bodyLength > 1024 * 1024) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self finishAttempt:attempt message:@"Invalid response from Soulseek." success:NO];
            });
            return;
        }

        NSMutableData *frame = [NSMutableData dataWithLength:bodyLength];
        if (!SLReadAll(fd, frame.mutableBytes, bodyLength)) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self finishAttempt:attempt message:@"Incomplete response from Soulseek." success:NO];
            });
            return;
        }

        if (self.attempt != attempt) return;
        const uint8_t *bytes = frame.bytes;
        uint32_t code = SLReadU32(bytes);
        if (code != 1 || frame.length < 5) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self finishAttempt:attempt message:@"Unexpected response from Soulseek." success:NO];
            });
            return;
        }

        NSUInteger offset = 4;
        BOOL accepted = bytes[offset++] != 0;
        NSString *message = nil;
        if (accepted) {
            NSString *greeting = SLReadString(frame, &offset) ?: @"";
            message = greeting.length
                ? [NSString stringWithFormat:@"Authenticated successfully. %@", greeting]
                : @"Authenticated successfully with Soulseek.";
        } else {
            NSString *reason = SLReadString(frame, &offset) ?: @"Login rejected";
            if ([reason isEqualToString:@"INVALIDPASS"]) message = @"Incorrect Soulseek password.";
            else if ([reason isEqualToString:@"INVALIDUSERNAME"]) message = @"That Soulseek username is invalid.";
            else if ([reason isEqualToString:@"EMPTYPASSWORD"]) message = @"Soulseek rejected an empty password.";
            else if ([reason isEqualToString:@"SVRFULL"]) message = @"Soulseek server is full. Try again later.";
            else message = [NSString stringWithFormat:@"Soulseek login rejected: %@", reason];
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [self finishAttempt:attempt message:message success:accepted];
        });
    });
}

- (void)finishAttempt:(NSUInteger)attempt message:(NSString *)message success:(BOOL)success {
    if (self.attempt != attempt) return;
    NSString *username = [self.usernameField.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (success) {
        NSString *old = [NSUserDefaults.standardUserDefaults stringForKey:kSLUsernameKey];
        if (old.length && ![old isEqualToString:username]) SLDeletePassword(old);
        if (!SLSavePassword(username, self.passwordField.text ?: @"")) {
            success = NO;
            message = @"Login worked, but iOS couldn't save the password to Keychain.";
        } else {
            [NSUserDefaults.standardUserDefaults setObject:username forKey:kSLUsernameKey];
        }
    }
    [self disconnectCurrent];
    self.connecting = NO;
    [self showStatus:message success:success];
}

- (void)showStatus:(NSString *)message success:(BOOL)success {
    self.statusLabel.text = message;
    self.statusLabel.textColor = success ? SGGreen() : SGGrey();
    [self.view setNeedsLayout];
}

- (void)forgetCredentials {
    NSString *username = [NSUserDefaults.standardUserDefaults stringForKey:kSLUsernameKey];
    SLDeletePassword(username);
    [NSUserDefaults.standardUserDefaults removeObjectForKey:kSLUsernameKey];
    self.usernameField.text = @"";
    self.passwordField.text = @"";
    [self showStatus:@"Saved Soulseek credentials removed from this device." success:YES];
}

- (void)disconnectCurrent {
    self.attempt++;
    int fd = self.socketFD;
    self.socketFD = -1;
    if (fd >= 0) {
        shutdown(fd, SHUT_RDWR);
        close(fd);
    }
    [self.receiveBuffer setLength:0];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self disconnectCurrent];
}

@end
