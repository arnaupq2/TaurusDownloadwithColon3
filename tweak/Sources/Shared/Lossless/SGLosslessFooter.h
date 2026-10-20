// A single Lossless download row lives in Spotify's context-menu footer.
#import <UIKit/UIKit.h>

static NSString *const kSGLosslessFooterID = @"SGLosslessFooter";

// Keep one row only. Spotify's own footer, if present, takes precedence.
static inline BOOL SGLosslessFooterPlace(UITableView *table, UIControl *row, CGFloat width, CGFloat rowHeight) {
    UIView *box = row.superview;
    if (![box.accessibilityIdentifier isEqualToString:kSGLosslessFooterID]) {
        UIView *footer = table.tableFooterView;
        if ([footer.accessibilityIdentifier isEqualToString:kSGLosslessFooterID]) {
            box = footer;
        } else if (!footer || footer.bounds.size.height < 1) {
            box = [UIView new];
            box.accessibilityIdentifier = kSGLosslessFooterID;
            box.backgroundColor = UIColor.clearColor;
        } else {
            return NO;
        }
        [box addSubview:row];
    }
    row.frame = CGRectMake(0, 0, width, rowHeight);
    BOOL changed = table.tableFooterView != box ||
        fabs(box.frame.size.width - width) > 0.5 || fabs(box.frame.size.height - rowHeight) > 0.5;
    box.frame = CGRectMake(0, 0, width, rowHeight);
    if (changed) {
        table.tableFooterView = box;
        [table invalidateIntrinsicContentSize];
    }
    return YES;
}
