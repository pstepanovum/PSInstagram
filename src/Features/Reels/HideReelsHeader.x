#import "../../Utils.h"

%hook IGSundialViewerNavigationBarOld
- (void)didMoveToWindow {
    %orig;

    if ([PSIUtils getBoolPref:@"hide_reels_header"]) {
        NSLog(@"[PSInstagram] Hiding reels header");

        [self removeFromSuperview];
    }
}
%end
