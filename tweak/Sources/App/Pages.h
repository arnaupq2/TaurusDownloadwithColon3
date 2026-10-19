#import <UIKit/UIKit.h>

// Redesigned UI, the one switch between the two looks, and what its ⓘ reads out.
void SGSetRedesignedUI(BOOL on);
extern NSString *const SGRedesignedUIInfo;

UIViewController *SGAppearanceSettingsPage(void);   // Redesigned UI, the accent, the Home top picks and the font
UIViewController *SGPlayerSettingsPage(void);
UIViewController *SGLyricsSettingsPage(void);  // its sources in either look, and the redesign's display
UIViewController *SGNavbarPage(void);       // the tab editor of whichever look is stored
