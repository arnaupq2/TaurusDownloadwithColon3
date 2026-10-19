// Where Lossless's two menu rows live: the footer of Spotify's ⋯ menu table, stacked in one box.
//
// "Download lossless" (LosslessDownload.x, tag 1) sits over "Add lossless file" (LosslessMenu.x, tag 2). Both
// files call SGLosslessFooterPlace on every layout pass, in either order: the first makes the box, the second
// joins it. The header is left to Speed and pitch, which takes it in the player's menu. Rows are SG… controls
// with an accessibility label, so the redesigned sheet (Redesigned/ContextMenu) finds them inside the box.
#import <UIKit/UIKit.h>

static NSString *const kSGLosslessFooterID = @"SGLosslessFooter";

// YES when `row` is in the footer, NO when Spotify's own footer is in the way (the row is left out).
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
    NSArray<UIView *> *rows = [box.subviews sortedArrayUsingComparator:^NSComparisonResult(UIView *a, UIView *b) {
        return a.tag < b.tag ? NSOrderedAscending : (a.tag > b.tag ? NSOrderedDescending : NSOrderedSame);
    }];
    CGFloat y = 0;
    for (UIView *view in rows) {
        view.frame = CGRectMake(0, y, width, rowHeight);
        y += rowHeight;
    }
    BOOL changed = table.tableFooterView != box || fabs(box.frame.size.width - width) > 0.5 || fabs(box.frame.size.height - y) > 0.5;
    box.frame = CGRectMake(0, 0, width, y);
    if (changed) {
        table.tableFooterView = box;
        [table invalidateIntrinsicContentSize];
    }
    return YES;
}
