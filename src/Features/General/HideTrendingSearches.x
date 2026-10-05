#import "../../Utils.h"
#import "../../InstagramHeaders.h"

%hook IGDSSegmentedPillBarView
- (void)didMoveToWindow {
    %orig;

    if ([[self delegate] isKindOfClass:%c(IGSearchTypeaheadNavigationHeaderView)]) {
        if ([PSIUtils getBoolPref:@"hide_trending_searches"]) {
            NSLog(@"[PSInstagram] Hiding trending searches");

            [self removeFromSuperview];
        }
    }
}
%end